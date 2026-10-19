//
//  PostCell.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import Alamofire
import AlamofireImage
import Foundation
import ParseSwift

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    private var imageDataRequest: DataRequest?
    private var locationTask: Task<Void, Never>?
    private var representedPostID: String?

    /// A user can view posts only if their most recent post was within 24 hours.
    static var currentUserCanViewPosts: Bool {
        guard let lastPostedDate = User.current?.lastPostedDate else {
            return false
        }

        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return lastPostedDate >= twentyFourHoursAgo
    }

    func configure(with post: Post) {
        imageDataRequest?.cancel()
        locationTask?.cancel()

        representedPostID = post.objectId
        usernameLabel.text = nil
        postImageView.image = nil
        captionLabel.text = nil
        dateLabel.text = nil

        // Hides this cell's content when the current user has not posted recently.
        // The table view data source should also return zero rows to avoid blank rows.
        guard Self.currentUserCanViewPosts else {
            contentView.isHidden = true
            selectionStyle = .none
            return
        }

        contentView.isHidden = false
        selectionStyle = .default

        usernameLabel.text = post.authorUsername
            ?? post.user?.username
            ?? "Unknown user"

        if let imageFile = post.imageFile,
           let imageURL = imageFile.url {
            let postID = post.objectId

            imageDataRequest = AF.request(imageURL).responseImage { [weak self] response in
                guard self?.representedPostID == postID else {
                    return
                }

                switch response.result {
                case .success(let image):
                    self?.postImageView.image = image

                case .failure(let error):
                    print("❌ Error fetching image: \(error.localizedDescription)")
                }
            }
        }

        captionLabel.text = post.caption

        if let date = post.createdAt {
            let dateLabelInfo =
                RelativeDateTimeFormatter.postRelativeFormatter.localizedString(
                    for: date,
                    relativeTo: Date()
                )

            dateLabel.text = "\(dateLabelInfo) / No Location Provided"

            let postID = post.objectId

            locationTask = Task { [weak self] in
                guard let locationText = await post.locationLabelText(),
                      !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    guard self?.representedPostID == postID else {
                        return
                    }

                    self?.dateLabel.text = "\(dateLabelInfo) / \(locationText)"
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        representedPostID = nil
        contentView.isHidden = false
        usernameLabel.text = nil
        postImageView.image = nil
        captionLabel.text = nil
        dateLabel.text = nil

        imageDataRequest?.cancel()
        imageDataRequest = nil

        locationTask?.cancel()
        locationTask = nil
    }
}
