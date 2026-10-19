//
//  PostViewController.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/1/22.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import ParseSwift

class PostViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!

    private var pickedImage: UIImage?

    // The location embedded in the selected image, if one is available.
    private var pickedLocation: ParseGeoPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        var config = PHPickerConfiguration()
        config.filter = .images

        // Request the original representation to preserve metadata when possible.
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func onShareTapped(_ sender: Any) {
        view.endEditing(true)

        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }

        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        guard let currentUser = User.current,
              let authorUsername = currentUser.username,
              !authorUsername.isEmpty else {
            showAlert(description: "Unable to identify the current user. Please log in again.")
            return
        }

        var post = Post()
        post.imageFile = imageFile
        post.caption = captionTextField.text
        post.user = currentUser
        post.authorUsername = authorUsername

        // Save the photo's embedded GPS position to Parse.
        // This is nil when the selected image has no GPS metadata.
        post.locatedAt = pickedLocation

        post.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    print("✅ Post Saved! \(post)")

                    guard var currentUser = User.current else {
                        self?.showAlert(description: "Unable to update the current user.")
                        return
                    }

                    currentUser.lastPostedDate = Date()
                    currentUser.save { [weak self] result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let user):
                                print("✅ User Saved! \(user)")
                                self?.navigationController?.popViewController(animated: true)

                            case .failure(let error):
                                self?.showAlert(description: error.localizedDescription)
                            }
                        }
                    }

                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func onViewTapped(_ sender: Any) {
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: description ?? "Please try again...",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    /// Reads EXIF GPS metadata and converts it to a Parse GeoPoint.
    private static func parseGeoPoint(from imageData: Data) -> ParseGeoPoint? {
        guard
            let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
                as? [String: Any],
            let gps = properties[kCGImagePropertyGPSDictionary as String]
                as? [String: Any],
            let latitude = (gps[kCGImagePropertyGPSLatitude as String] as? NSNumber)?
                .doubleValue,
            let longitude = (gps[kCGImagePropertyGPSLongitude as String] as? NSNumber)?
                .doubleValue
        else {
            return nil
        }

        let latitudeReference = gps[kCGImagePropertyGPSLatitudeRef as String]
            as? String
        let longitudeReference = gps[kCGImagePropertyGPSLongitudeRef as String]
            as? String

        let signedLatitude: Double
        if let latitudeReference {
            signedLatitude = latitudeReference.uppercased() == "S"
                ? -abs(latitude)
                : abs(latitude)
        } else {
            signedLatitude = latitude
        }

        let signedLongitude: Double
        if let longitudeReference {
            signedLongitude = longitudeReference.uppercased() == "W"
                ? -abs(longitude)
                : abs(longitude)
        } else {
            signedLongitude = longitude
        }

        return try? ParseGeoPoint(
            latitude: signedLatitude,
            longitude: signedLongitude
        )
    }
}

extension PostViewController: PHPickerViewControllerDelegate {
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard
            let provider = results.first?.itemProvider,
            provider.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        else {
            return
        }

        // Load the image data instead of only loading a UIImage. UIImage does not
        // expose the selected file's EXIF GPS dictionary.
        provider.loadDataRepresentation(
            forTypeIdentifier: UTType.image.identifier
        ) { [weak self] data, error in
            if let error {
                DispatchQueue.main.async {
                    self?.showAlert(description: error.localizedDescription)
                }
                return
            }

            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.showAlert()
                }
                return
            }

            let location = Self.parseGeoPoint(from: data)

            DispatchQueue.main.async {
                self?.previewImageView.image = image
                self?.pickedImage = image
                self?.pickedLocation = location

                if let location {
                    print(
                        "📍 Image location: \(location.latitude), " +
                        "\(location.longitude)"
                    )
                } else {
                    print("ℹ️ Selected image has no GPS metadata.")
                }
            }
        }
    }
}
