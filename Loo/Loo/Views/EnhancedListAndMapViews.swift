//
//  EnhancedListAndMapViews.swift
//  Loo
//
//  Enhanced bathroom list and map views with community features
//

import SwiftUI
import MapKit

// MARK: - Enhanced List View
struct EnhancedBathroomListView: View {
    let bathrooms: [Bathroom]
    @Binding var selectedBathroom: Bathroom?
    @EnvironmentObject var communityService: CommunityService
    @EnvironmentObject var favoritesManager: FavoritesManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(bathrooms) { bathroom in
                    EnhancedBathroomCard(bathroom: bathroom)
                        .environmentObject(communityService)
                        .environmentObject(favoritesManager)
                        .onTapGesture {
                            selectedBathroom = bathroom
                        }
                }
            }
            .padding()
        }
    }
}

struct EnhancedBathroomCard: View {
    let bathroom: Bathroom
    @EnvironmentObject var communityService: CommunityService
    @EnvironmentObject var favoritesManager: FavoritesManager
    @AppStorage("isDarkMode") private var isDarkMode = false

    var activeReports: [CommunityReport] {
        communityService.getActiveReports(for: bathroom.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                // Icon with liquid glass effect
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.8),
                                    Color.blue.opacity(0.5),
                                    Color.cyan.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "drop.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 26))

                    // Favorite indicator
                    if favoritesManager.isFavorite(bathroom) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                            .offset(x: 18, y: -18)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(bathroom.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.15, green: 0.15, blue: 0.25))

                    Text(bathroom.businessType)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDarkMode ? Color.gray : Color(red: 0.45, green: 0.45, blue: 0.55))

                    // Rating
                    if let rating = bathroom.rating {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: Double(index) < rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12))
                        }
                    }
                }

                Spacer()

                if let distance = bathroom.distance {
                    Text(formatDistance(distance))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }

            // Live reports indicator
            if !activeReports.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))

                    Text("\(activeReports.count) live report\(activeReports.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)

                    Spacer()

                    // Show first report
                    if let firstReport = activeReports.first {
                        HStack(spacing: 4) {
                            Text(firstReport.type.emoji)
                                .font(.system(size: 14))
                            Text(firstReport.type.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Frosted divider
            Rectangle()
                .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.3))
                .frame(height: 1)

            // Details
            HStack(spacing: 24) {
                LiquidDetailItem(icon: "clock.fill", text: bathroom.openingHours ?? "Hours N/A")

                LiquidDetailItem(icon: "car.fill", text: bathroom.parkingEase.rawValue)

                // Accessibility indicators
                if bathroom.accessibility.wheelchairAccessible == .full {
                    LiquidDetailItem(icon: "figure.roll", text: "Accessible")
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: isDarkMode ?
                                    [Color.white.opacity(0.08), Color.white.opacity(0.02)] :
                                    [Color.white.opacity(0.6), Color.white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: isDarkMode ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }

    private func formatDistance(_ distance: Double) -> String {
        let miles = distance / 1609.34
        if miles < 0.1 {
            return String(format: "%.0f ft", distance * 3.28084)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
}

struct LiquidDetailItem: View {
    let icon: String
    let text: String
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isDarkMode ? Color(red: 0.7, green: 0.8, blue: 1.0) : Color(red: 0.3, green: 0.5, blue: 0.7))

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isDarkMode ? Color.gray : Color(red: 0.4, green: 0.4, blue: 0.5))
        }
    }
}

// MARK: - Enhanced Map View
struct EnhancedMapView: View {
    @Binding var region: MKCoordinateRegion
    let bathrooms: [Bathroom]
    @Binding var selectedBathroom: Bathroom?
    @EnvironmentObject var communityService: CommunityService

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: bathrooms) { bathroom in
                MapAnnotation(coordinate: bathroom.coordinate) {
                    EnhancedMapMarker(bathroom: bathroom)
                        .environmentObject(communityService)
                        .onTapGesture {
                            selectedBathroom = bathroom
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding()
        }
    }
}

struct EnhancedMapMarker: View {
    let bathroom: Bathroom
    @EnvironmentObject var communityService: CommunityService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var hasActiveReports: Bool {
        !communityService.getActiveReports(for: bathroom.id).isEmpty
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Liquid glass droplet
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.9),
                                Color.blue.opacity(0.6),
                                Color.cyan.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .overlay(
                        // Specular highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.8), Color.clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 20, height: 20)
                            .offset(x: -8, y: -8)
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "drop.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))

                // Active report indicator
                if hasActiveReports {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 14, y: -14)
                }
            }

            // Label with frosted glass
            VStack(spacing: 2) {
                Text(bathroom.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white : .black)

                if let rating = bathroom.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 8))
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(radius: 3)
        }
    }
}
