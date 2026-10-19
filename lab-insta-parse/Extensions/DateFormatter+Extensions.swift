//
//  DateFormatter+Extensions.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/3/22.
//

import Foundation
import CoreLocation
import ParseSwift

extension RelativeDateTimeFormatter {
    static let postRelativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}

extension Post {
    func locationLabelText() async -> String? {
        guard let point = locatedAt else {
            return nil
        }

        let location = CLLocation(
            latitude: point.latitude,
            longitude: point.longitude
        )

        do {
            let placemarks = try await CLGeocoder()
                .reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                return nil
            }

            let city = placemark.locality
            let stateOrTerritory = placemark.administrativeArea
            let country = placemark.country

            let components = [
                city,
                stateOrTerritory,
                country
            ].compactMap { $0 }

            return components.isEmpty
                ? nil
                : components.joined(separator: ", ")
        } catch {
            print("❌ Reverse-geocoding failed: \(error.localizedDescription)")
            return nil
        }
    }
}


