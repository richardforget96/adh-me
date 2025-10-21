//
//  FilterSheet.swift
//  Loo
//
//  Advanced filtering options
//

import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bathroomService: BathroomService
    @EnvironmentObject var favoritesManager: FavoritesManager
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick filters
                    FilterSection(title: "Quick Filters", icon: "bolt.fill") {
                        ToggleFilter(
                            title: "Favorites Only",
                            icon: "star.fill",
                            isOn: $bathroomService.filters.showOnlyFavorites
                        )

                        ToggleFilter(
                            title: "Free Only",
                            icon: "dollarsign.circle",
                            isOn: $bathroomService.filters.showFreeOnly
                        )

                        ToggleFilter(
                            title: "Open Now",
                            icon: "clock.fill",
                            isOn: $bathroomService.filters.showOpenNow
                        )
                    }

                    // Accessibility
                    FilterSection(title: "Accessibility", icon: "figure.roll") {
                        ToggleFilter(
                            title: "Wheelchair Accessible",
                            icon: "figure.roll",
                            isOn: $bathroomService.filters.requireWheelchairAccess
                        )

                        ToggleFilter(
                            title: "Baby Changing Station",
                            icon: "figure.and.child.holdinghands",
                            isOn: $bathroomService.filters.requireBabyChanging
                        )

                        ToggleFilter(
                            title: "Gender Neutral",
                            icon: "person.fill.questionmark",
                            isOn: $bathroomService.filters.requireGenderNeutral
                        )
                    }

                    // Essentials
                    FilterSection(title: "Essentials", icon: "checkmark.seal.fill") {
                        ToggleFilter(
                            title: "Has Toilet Paper",
                            icon: "chart.bar.doc.horizontal",
                            isOn: $bathroomService.filters.requireToiletPaper
                        )
                    }

                    // Rating
                    FilterSection(title: "Minimum Rating", icon: "star.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ForEach(1...5, id: \.self) { rating in
                                    Button {
                                        bathroomService.filters.minimumRating = Double(rating)
                                    } label: {
                                        Image(systemName: Double(rating) <= bathroomService.filters.minimumRating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 28))
                                    }
                                }
                                Spacer()
                                if bathroomService.filters.minimumRating > 0 {
                                    Button("Clear") {
                                        bathroomService.filters.minimumRating = 0
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Distance
                    FilterSection(title: "Maximum Distance", icon: "location.circle.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(formatDistance(bathroomService.filters.maxDistance))")
                                .font(.system(size: 20, weight: .semibold))

                            Slider(
                                value: $bathroomService.filters.maxDistance,
                                in: 100...5000,
                                step: 100
                            )
                            .tint(.blue)

                            HStack {
                                Text("0.1 mi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("3.1 mi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(BackgroundView(isDarkMode: isDarkMode).ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        bathroomService.resetFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        bathroomService.applyFilters(favoritesManager: favoritesManager)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.34
        return String(format: "%.1f mi", miles)
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }

            content
        }
    }
}

struct ToggleFilter: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32)

            Text(title)
                .font(.system(size: 16))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
