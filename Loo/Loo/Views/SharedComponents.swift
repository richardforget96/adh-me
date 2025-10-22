//
//  SharedComponents.swift
//  Loo
//
//  Shared UI components used throughout the app
//

import SwiftUI

// MARK: - Background View
struct BackgroundView: View {
    let isDarkMode: Bool

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: isDarkMode ?
                    [Color(red: 0.05, green: 0.05, blue: 0.08), Color(red: 0.12, green: 0.12, blue: 0.15)] :
                    [Color(red: 0.88, green: 0.92, blue: 0.98), Color(red: 0.78, green: 0.85, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle mesh gradient overlay for depth
            RadialGradient(
                colors: isDarkMode ?
                    [Color.blue.opacity(0.15), Color.clear] :
                    [Color.blue.opacity(0.08), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
    }
}
