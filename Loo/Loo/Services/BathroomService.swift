//
//  BathroomService.swift
//  Loo
//
//  Service for fetching bathroom data from OpenStreetMap
//

import Foundation
import CoreLocation

class BathroomService: ObservableObject {
    @Published var bathrooms: [Bathroom] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let overpassURL = "https://overpass-api.de/api/interpreter"
    private let searchRadiusMeters = 5000 // 5km radius

    func fetchBathrooms(near location: CLLocation) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        let query = buildOverpassQuery(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: searchRadiusMeters
        )

        guard let url = URL(string: overpassURL),
              let queryData = query.data(using: .utf8) else {
            await MainActor.run {
                errorMessage = "Invalid URL or query"
                isLoading = false
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = queryData
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OSMResponse.self, from: data)

            let parsedBathrooms = response.elements.compactMap { element in
                parseBathroom(from: element, userLocation: location)
            }

            await MainActor.run {
                bathrooms = parsedBathrooms.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch bathrooms: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func buildOverpassQuery(latitude: Double, longitude: Double, radius: Int) -> String {
        """
        [out:json][timeout:25];
        (
          node["amenity"="toilets"](around:\(radius),\(latitude),\(longitude));
          way["amenity"="toilets"](around:\(radius),\(latitude),\(longitude));
          node["toilets"="yes"](around:\(radius),\(latitude),\(longitude));
          way["toilets"="yes"](around:\(radius),\(latitude),\(longitude));
        );
        out center tags;
        """
    }

    private func parseBathroom(from element: OSMElement, userLocation: CLLocation) -> Bathroom? {
        guard let tags = element.tags else { return nil }

        // Get coordinates
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

        // Extract information
        let name = tags["name"] ?? extractBusinessName(from: tags)
        let businessType = extractBusinessType(from: tags)
        let amenityType = tags["amenity"] ?? "toilets"
        let openingHours = tags["opening_hours"]
        let parkingEase = determineParkingEase(from: tags)

        return Bathroom(
            id: "\(element.id)",
            name: name,
            latitude: lat,
            longitude: lon,
            businessType: businessType,
            amenityType: amenityType,
            openingHours: openingHours,
            parkingEase: parkingEase,
            distance: distance
        )
    }

    private func extractBusinessName(from tags: [String: String]) -> String {
        // Try to get business name from various tags
        if let name = tags["operator"] { return name }
        if let name = tags["brand"] { return name }
        if let amenity = tags["amenity"], amenity != "toilets" {
            return amenity.capitalized
        }
        return "Public Restroom"
    }

    private func extractBusinessType(from tags: [String: String]) -> String {
        // Determine business type
        if let amenity = tags["amenity"], amenity != "toilets" {
            return amenity.capitalized.replacingOccurrences(of: "_", with: " ")
        }
        if let shop = tags["shop"] {
            return shop.capitalized.replacingOccurrences(of: "_", with: " ")
        }
        if let tourism = tags["tourism"] {
            return tourism.capitalized.replacingOccurrences(of: "_", with: " ")
        }
        if let leisure = tags["leisure"] {
            return leisure.capitalized.replacingOccurrences(of: "_", with: " ")
        }
        return "Public Facility"
    }

    private func determineParkingEase(from tags: [String: String]) -> Bathroom.ParkingDifficulty {
        // Check for parking tags
        if let parking = tags["parking"] {
            switch parking {
            case "yes", "surface", "multi-storey":
                return .easy
            case "street_side", "lane":
                return .moderate
            default:
                return .difficult
            }
        }

        // Check nearby parking
        if tags["parking:lane"] != nil {
            return .moderate
        }

        // Check if in city center or high density area
        if tags["population_density"] == "high" {
            return .difficult
        }

        return .unknown
    }
}
