//
//  LooApp.swift
//  Loo
//
//  A bathroom finder app with skeuomorphic design
//

import SwiftUI

@main
struct LooApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var bathroomService = BathroomService()
    @StateObject private var favoritesManager = FavoritesManager()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(bathroomService)
                .environmentObject(favoritesManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
