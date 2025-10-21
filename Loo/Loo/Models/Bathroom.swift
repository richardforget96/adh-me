//
//  Bathroom.swift
//  Loo
//
//  Enhanced model with ratings, reviews, accessibility, and favorites
//

import Foundation
import CoreLocation

struct Bathroom: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let businessType: String
    let amenityType: String
    let openingHours: String?
    let parkingEase: ParkingDifficulty
    let distance: Double?

    // NEW: Ratings & Reviews
    var rating: Double?
    var reviewCount: Int
    var reviews: [Review]
    var cleanlinessScore: Double?

    // NEW: Accessibility Features
    var accessibility: AccessibilityFeatures

    // NEW: Access Requirements
    var accessRequirements: AccessRequirements

    // NEW: Restroom Details
    var details: RestroomDetails

    // NEW: User interaction
    var isFavorite: Bool
    var photos: [String] // URLs to photos

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum ParkingDifficulty: String, Codable {
        case easy = "Easy"
        case moderate = "Moderate"
        case difficult = "Difficult"
        case unknown = "Unknown"
    }

    static func == (lhs: Bathroom, rhs: Bathroom) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Review Model
struct Review: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let rating: Double
    let cleanliness: Double
    let comment: String
    let timestamp: Date
    let photos: [String]
    var helpfulCount: Int
    var verifiedVisit: Bool

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Accessibility Features
struct AccessibilityFeatures: Codable {
    var wheelchairAccessible: AccessibilityLevel
    var babyChangingStation: Bool
    var genderNeutral: Bool
    var serviceAnimalFriendly: Bool
    var brailleSignage: Bool
    var grabBars: Bool
    var automaticDoor: Bool
    var lowSink: Bool

    enum AccessibilityLevel: String, Codable {
        case full = "Full Access"          // Green
        case partial = "Partial Access"    // Orange
        case none = "No Access"           // Red
        case unknown = "Unknown"          // Gray
    }

    var accessibilityScore: Int {
        var score = 0
        if wheelchairAccessible == .full { score += 3 }
        else if wheelchairAccessible == .partial { score += 1 }
        if babyChangingStation { score += 1 }
        if genderNeutral { score += 1 }
        if grabBars { score += 1 }
        if automaticDoor { score += 1 }
        return score
    }
}

// MARK: - Access Requirements
struct AccessRequirements: Codable {
    var requiresKey: Bool
    var doorCode: String?
    var requiresFee: Bool
    var feeAmount: Double?
    var purchaseRequired: Bool
    var customerOnly: Bool

    var hasRestrictions: Bool {
        requiresKey || requiresFee || purchaseRequired || customerOnly
    }
}

// MARK: - Restroom Details
struct RestroomDetails: Codable {
    var stallType: StallType
    var stallCount: Int?
    var hasSink: Bool
    var hasSoap: Bool
    var hasPaperTowels: Bool
    var hasHandDryer: Bool
    var hasBidet: Bool
    var hasToiletPaper: Bool
    var wellLit: Bool
    var securityPresent: Bool

    enum StallType: String, Codable {
        case singleStall = "Single Stall"
        case multipleStalls = "Multiple Stalls"
        case unknown = "Unknown"
    }
}

// MARK: - Filter Options
struct BathroomFilters {
    var showOnlyFavorites: Bool = false
    var showOpenNow: Bool = false
    var showFreeOnly: Bool = false
    var minimumRating: Double = 0.0
    var maxDistance: Double = 5000 // meters
    var requireWheelchairAccess: Bool = false
    var requireBabyChanging: Bool = false
    var requireGenderNeutral: Bool = false
    var requireToiletPaper: Bool = false

    var hasActiveFilters: Bool {
        showOnlyFavorites || showOpenNow || showFreeOnly ||
        minimumRating > 0 || requireWheelchairAccess ||
        requireBabyChanging || requireGenderNeutral || requireToiletPaper
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

// MARK: - Default Values
extension Bathroom {
    static func createSample(from element: OSMElement, userLocation: CLLocation) -> Bathroom? {
        guard let tags = element.tags else { return nil }

        let lat: Double
        let lon: Double

        if let elementLat = element.lat, let elementLon = element.lon {
            lat = elementLat
            lon = elementLon
        } else if let center = element.center {
            lat = center.lat
            lon = center.lon
        } else {
            return nil
        }

        let location = CLLocation(latitude: lat, longitude: lon)
        let distance = userLocation.distance(from: location)

        return Bathroom(
            id: "\(element.id)",
            name: tags["name"] ?? "Public Restroom",
            latitude: lat,
            longitude: lon,
            businessType: tags["amenity"] ?? "Public Facility",
            amenityType: "toilets",
            openingHours: tags["opening_hours"],
            parkingEase: .unknown,
            distance: distance,
            rating: Double.random(in: 3.5...4.9),
            reviewCount: Int.random(in: 5...50),
            reviews: [],
            cleanlinessScore: Double.random(in: 3.0...5.0),
            accessibility: AccessibilityFeatures(
                wheelchairAccessible: .unknown,
                babyChangingStation: false,
                genderNeutral: false,
                serviceAnimalFriendly: true,
                brailleSignage: false,
                grabBars: false,
                automaticDoor: false,
                lowSink: false
            ),
            accessRequirements: AccessRequirements(
                requiresKey: false,
                doorCode: nil,
                requiresFee: false,
                feeAmount: nil,
                purchaseRequired: false,
                customerOnly: false
            ),
            details: RestroomDetails(
                stallType: .unknown,
                stallCount: nil,
                hasSink: true,
                hasSoap: true,
                hasPaperTowels: true,
                hasHandDryer: false,
                hasBidet: false,
                hasToiletPaper: true,
                wellLit: true,
                securityPresent: false
            ),
            isFavorite: false,
            photos: []
        )
    }
}

extension AccessibilityFeatures {
    static var defaultFeatures: AccessibilityFeatures {
        AccessibilityFeatures(
            wheelchairAccessible: .unknown,
            babyChangingStation: false,
            genderNeutral: false,
            serviceAnimalFriendly: true,
            brailleSignage: false,
            grabBars: false,
            automaticDoor: false,
            lowSink: false
        )
    }
}
