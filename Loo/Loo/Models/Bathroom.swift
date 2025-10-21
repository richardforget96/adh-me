//
//  Bathroom.swift
//  Loo
//
//  Model for bathroom locations
//

import Foundation
import CoreLocation

struct Bathroom: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let businessType: String
    let amenityType: String
    let openingHours: String?
    let parkingEase: ParkingDifficulty
    let distance: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum ParkingDifficulty: String, Codable {
        case easy = "Easy"
        case moderate = "Moderate"
        case difficult = "Difficult"
        case unknown = "Unknown"
    }
}

// MARK: - OSM Response Models
struct OSMResponse: Codable {
    let elements: [OSMElement]
}

struct OSMElement: Codable {
    let type: String
    let id: Int64
    let lat: Double?
    let lon: Double?
    let tags: [String: String]?
    let center: OSMCenter?
}

struct OSMCenter: Codable {
    let lat: Double
    let lon: Double
}
