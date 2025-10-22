//
//  FavoritesManager.swift
//  Loo
//
//  Manages favorites and offline storage
//

import Foundation
import Combine

class FavoritesManager: ObservableObject {
    @Published var favorites: [Bathroom] = []
    @Published var offlineBathrooms: [Bathroom] = []

    private let favoritesKey = "loo_favorites"
    private let offlineKey = "loo_offline_bathrooms"
    private let userDefaults = UserDefaults.standard

    init() {
        loadFavorites()
        loadOfflineBathrooms()
    }

    // MARK: - Favorites Management

    func toggleFavorite(_ bathroom: Bathroom) {
        if isFavorite(bathroom) {
            removeFavorite(bathroom)
        } else {
            addFavorite(bathroom)
        }
    }

    func addFavorite(_ bathroom: Bathroom) {
        var updatedBathroom = bathroom
        updatedBathroom.isFavorite = true

        if !favorites.contains(where: { $0.id == bathroom.id }) {
            favorites.append(updatedBathroom)
            saveFavorites()
        }
    }

    func removeFavorite(_ bathroom: Bathroom) {
        favorites.removeAll { $0.id == bathroom.id }
        saveFavorites()
    }

    func isFavorite(_ bathroom: Bathroom) -> Bool {
        favorites.contains(where: { $0.id == bathroom.id })
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            userDefaults.set(encoded, forKey: favoritesKey)
        }
    }

    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([Bathroom].self, from: data) {
            favorites = decoded
        }
    }

    // MARK: - Offline Storage

    func saveForOffline(_ bathrooms: [Bathroom]) {
        offlineBathrooms = bathrooms
        if let encoded = try? JSONEncoder().encode(bathrooms) {
            userDefaults.set(encoded, forKey: offlineKey)
        }
    }

    func loadOfflineBathrooms() {
        if let data = userDefaults.data(forKey: offlineKey),
           let decoded = try? JSONDecoder().decode([Bathroom].self, from: data) {
            offlineBathrooms = decoded
        }
    }

    func clearOfflineData() {
        offlineBathrooms = []
        userDefaults.removeObject(forKey: offlineKey)
    }

    // MARK: - Statistics

    var favoriteCount: Int {
        favorites.count
    }

    var offlineCount: Int {
        offlineBathrooms.count
    }

    var mostVisitedBusinessType: String? {
        let types = favorites.map { $0.businessType }
        let counts = Dictionary(grouping: types, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
