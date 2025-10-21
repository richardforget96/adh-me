//
//  ContentView.swift
//  Loo
//
//  Main view with skeuomorphic design
//

import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bathroomService: BathroomService
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showingList = false

    var body: some View {
        ZStack {
            // Background with texture
            BackgroundView(isDarkMode: isDarkMode)

            VStack(spacing: 0) {
                // Header with skeuomorphic design
                HeaderView(isDarkMode: $isDarkMode)

                // Map or List View
                if showingList {
                    BathroomListView()
                } else {
                    MapView(region: $region)
                }

                // Bottom control panel
                ControlPanelView(showingList: $showingList)
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                region.center = location.coordinate
                Task {
                    await bathroomService.fetchBathrooms(near: location)
                }
            }
        }
    }
}

// MARK: - Background View
struct BackgroundView: View {
    let isDarkMode: Bool

    var body: some View {
        LinearGradient(
            colors: isDarkMode ?
                [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.15, green: 0.15, blue: 0.17)] :
                [Color(red: 0.9, green: 0.92, blue: 0.95), Color(red: 0.85, green: 0.87, blue: 0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var isDarkMode: Bool

    var body: some View {
        ZStack {
            // Skeuomorphic header background
            LinearGradient(
                colors: isDarkMode ?
                    [Color(red: 0.2, green: 0.2, blue: 0.22), Color(red: 0.15, green: 0.15, blue: 0.17)] :
                    [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.88, green: 0.88, blue: 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

            HStack {
                // Title with embossed effect
                Text("Loo")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.3))
                    .shadow(color: isDarkMode ?
                        Color.white.opacity(0.1) :
                        Color.white.opacity(0.8),
                        radius: 1, x: 0, y: 1
                    )
                    .padding(.leading, 20)

                Spacer()

                // Dark mode toggle button
                SkeuomorphicButton(
                    icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                    isDarkMode: isDarkMode
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isDarkMode.toggle()
                    }
                }
                .padding(.trailing, 20)
            }
        }
        .frame(height: 80)
    }
}

// MARK: - Map View
struct MapView: View {
    @Binding var region: MKCoordinateRegion
    @EnvironmentObject var bathroomService: BathroomService

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: bathroomService.bathrooms) { bathroom in
                MapAnnotation(coordinate: bathroom.coordinate) {
                    BathroomMapMarker(bathroom: bathroom)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            .padding()

            if bathroomService.isLoading {
                LoadingView()
            }
        }
    }
}

// MARK: - Bathroom Map Marker
struct BathroomMapMarker: View {
    let bathroom: Bathroom
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)

                Image(systemName: "drop.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            }

            Text(bathroom.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isDarkMode ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                        .shadow(radius: 2)
                )
        }
    }
}

// MARK: - Bathroom List View
struct BathroomListView: View {
    @EnvironmentObject var bathroomService: BathroomService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(bathroomService.bathrooms) { bathroom in
                    BathroomCard(bathroom: bathroom)
                }
            }
            .padding()
        }
    }
}

// MARK: - Bathroom Card
struct BathroomCard: View {
    let bathroom: Bathroom
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                    Image(systemName: "drop.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(bathroom.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.3))

                    Text(bathroom.businessType)
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? Color.gray : Color(red: 0.4, green: 0.4, blue: 0.5))
                }

                Spacer()

                if let distance = bathroom.distance {
                    Text(formatDistance(distance))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
            }

            Divider()
                .background(isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))

            // Details
            HStack(spacing: 20) {
                DetailItem(
                    icon: "clock.fill",
                    text: bathroom.openingHours ?? "Hours N/A",
                    isDarkMode: isDarkMode
                )

                DetailItem(
                    icon: "car.fill",
                    text: bathroom.parkingEase.rawValue,
                    isDarkMode: isDarkMode
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.2, green: 0.2, blue: 0.22), Color(red: 0.18, green: 0.18, blue: 0.2)] :
                            [Color.white, Color(red: 0.97, green: 0.97, blue: 0.98)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(isDarkMode ? 0.5 : 0.15), radius: 5, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color.white.opacity(0.1), Color.clear] :
                            [Color.white, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
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

// MARK: - Detail Item
struct DetailItem: View {
    let icon: String
    let text: String
    let isDarkMode: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isDarkMode ? Color.gray : Color(red: 0.5, green: 0.5, blue: 0.6))

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(isDarkMode ? Color.gray : Color(red: 0.5, green: 0.5, blue: 0.6))
        }
    }
}

// MARK: - Control Panel
struct ControlPanelView: View {
    @Binding var showingList: Bool
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bathroomService: BathroomService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        HStack(spacing: 20) {
            // Refresh button
            SkeuomorphicButton(icon: "arrow.clockwise", isDarkMode: isDarkMode) {
                if let location = locationManager.location {
                    Task {
                        await bathroomService.fetchBathrooms(near: location)
                    }
                }
            }

            // Toggle view button
            SkeuomorphicButton(
                icon: showingList ? "map.fill" : "list.bullet",
                isDarkMode: isDarkMode,
                isWide: true
            ) {
                withAnimation {
                    showingList.toggle()
                }
            }

            // Location button
            SkeuomorphicButton(icon: "location.fill", isDarkMode: isDarkMode) {
                locationManager.startUpdating()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color(red: 0.2, green: 0.2, blue: 0.22), Color(red: 0.15, green: 0.15, blue: 0.17)] :
                            [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.88, green: 0.88, blue: 0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: -2)
        )
        .padding()
    }
}

// MARK: - Skeuomorphic Button
struct SkeuomorphicButton: View {
    let icon: String
    let isDarkMode: Bool
    var isWide: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Button background with depth
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: isPressed ?
                                (isDarkMode ?
                                    [Color(red: 0.15, green: 0.15, blue: 0.17), Color(red: 0.2, green: 0.2, blue: 0.22)] :
                                    [Color(red: 0.82, green: 0.82, blue: 0.84), Color(red: 0.88, green: 0.88, blue: 0.9)]) :
                                (isDarkMode ?
                                    [Color(red: 0.25, green: 0.25, blue: 0.27), Color(red: 0.2, green: 0.2, blue: 0.22)] :
                                    [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.88, green: 0.88, blue: 0.9)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isDarkMode ?
                                        [Color.white.opacity(0.15), Color.clear] :
                                        [Color.white, Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: .black.opacity(isPressed ? 0.2 : 0.4),
                        radius: isPressed ? 2 : 4,
                        x: 0,
                        y: isPressed ? 1 : 3
                    )

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.3, green: 0.3, blue: 0.4))
            }
            .frame(width: isWide ? 120 : 55, height: 55)
        }
        .buttonStyle(PressButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Press Button Style
struct PressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(isDarkMode ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                .frame(width: 120, height: 120)
                .shadow(radius: 10)

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.blue)

                Text("Searching...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(BathroomService())
}
