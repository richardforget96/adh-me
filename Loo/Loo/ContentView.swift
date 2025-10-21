//
//  ContentView.swift
//  Loo
//
//  Main view with Liquid Glass + Skeuomorphic hybrid design
//  Combining iOS 26 Liquid Glass with tactile skeuomorphism
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
            // Dynamic gradient background
            BackgroundView(isDarkMode: isDarkMode)

            VStack(spacing: 0) {
                // Liquid Glass header
                HeaderView(isDarkMode: $isDarkMode)

                // Map or List View
                if showingList {
                    BathroomListView()
                } else {
                    MapView(region: $region)
                }

                // Liquid Glass control panel
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

// MARK: - Header View with Liquid Glass
struct HeaderView: View {
    @Binding var isDarkMode: Bool

    var body: some View {
        ZStack {
            // Translucent frosted glass background
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color.white.opacity(0.05), Color.white.opacity(0.01)] :
                            [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Top highlight (liquid glass reflection)
                    LinearGradient(
                        colors: [Color.white.opacity(isDarkMode ? 0.15 : 0.6), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: 2)
                    .blur(radius: 1),
                    alignment: .top
                )

            HStack {
                // Title with liquid effect
                HStack(spacing: 8) {
                    Text("💧")
                        .font(.system(size: 28))

                    Text("Loo")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isDarkMode ?
                                    [.white, Color(red: 0.8, green: 0.9, blue: 1.0)] :
                                    [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.4, blue: 0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: isDarkMode ?
                            Color.white.opacity(0.2) :
                            Color.white.opacity(0.8),
                            radius: 2, x: 0, y: 1
                        )
                }
                .padding(.leading, 20)

                Spacer()

                // Liquid Glass dark mode toggle
                LiquidGlassButton(
                    icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                    isDarkMode: isDarkMode,
                    accentColor: isDarkMode ? .purple : .orange
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
            }

            // Label with frosted glass
            Text(bathroom.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isDarkMode ? .white : .black)
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

// MARK: - Bathroom List View
struct BathroomListView: View {
    @EnvironmentObject var bathroomService: BathroomService

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(bathroomService.bathrooms) { bathroom in
                    LiquidGlassCard(bathroom: bathroom)
                }
            }
            .padding()
        }
    }
}

// MARK: - Liquid Glass Card
struct LiquidGlassCard: View {
    let bathroom: Bathroom
    @AppStorage("isDarkMode") private var isDarkMode = false

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
                        .overlay(
                            // Liquid reflection
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.7), Color.clear],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 28
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .offset(x: -10, y: -10)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "drop.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(bathroom.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDarkMode ? .white : Color(red: 0.15, green: 0.15, blue: 0.25))

                    Text(bathroom.businessType)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDarkMode ? Color.gray : Color(red: 0.45, green: 0.45, blue: 0.55))
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

            // Frosted divider
            Rectangle()
                .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.3))
                .frame(height: 1)

            // Details
            HStack(spacing: 24) {
                LiquidDetailItem(icon: "clock.fill", text: bathroom.openingHours ?? "Hours N/A")
                LiquidDetailItem(icon: "car.fill", text: bathroom.parkingEase.rawValue)
            }
        }
        .padding(18)
        .background(
            // Liquid Glass card background
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

// MARK: - Liquid Detail Item
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

// MARK: - Control Panel with Liquid Glass
struct ControlPanelView: View {
    @Binding var showingList: Bool
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bathroomService: BathroomService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        HStack(spacing: 16) {
            // Refresh
            LiquidGlassButton(icon: "arrow.clockwise", isDarkMode: isDarkMode, accentColor: .blue) {
                if let location = locationManager.location {
                    Task {
                        await bathroomService.fetchBathrooms(near: location)
                    }
                }
            }

            // Toggle view (wider)
            LiquidGlassButton(
                icon: showingList ? "map.fill" : "list.bullet",
                isDarkMode: isDarkMode,
                accentColor: .cyan,
                isWide: true
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showingList.toggle()
                }
            }

            // Location
            LiquidGlassButton(icon: "location.fill", isDarkMode: isDarkMode, accentColor: .green) {
                locationManager.startUpdating()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            // Frosted glass panel
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: isDarkMode ?
                            [Color.white.opacity(0.08), Color.white.opacity(0.02)] :
                            [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Top reflection line
                    Rectangle()
                        .fill(Color.white.opacity(isDarkMode ? 0.2 : 0.6))
                        .frame(height: 1)
                        .blur(radius: 0.5),
                    alignment: .top
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
        )
    }
}

// MARK: - Liquid Glass Button
struct LiquidGlassButton: View {
    let icon: String
    let isDarkMode: Bool
    var accentColor: Color = .blue
    var isWide: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Liquid Glass button
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: isPressed ?
                                        [accentColor.opacity(0.3), accentColor.opacity(0.1)] :
                                        (isDarkMode ?
                                            [Color.white.opacity(0.12), Color.white.opacity(0.05)] :
                                            [Color.white.opacity(0.7), Color.white.opacity(0.4)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        // Specular highlight
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: 20)
                            .blur(radius: 2),
                        alignment: .top
                    )
                    .shadow(color: isPressed ? Color.black.opacity(0.2) : accentColor.opacity(0.3),
                            radius: isPressed ? 5 : 10,
                            x: 0,
                            y: isPressed ? 2 : 5)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isDarkMode ?
                                [.white, Color(red: 0.9, green: 0.95, blue: 1.0)] :
                                [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: isWide ? 140 : 60, height: 60)
            .scaleEffect(isPressed ? 0.94 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: isDarkMode ?
                                    [Color.white.opacity(0.1), Color.white.opacity(0.02)] :
                                    [Color.white.opacity(0.6), Color.white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                )
                .frame(width: 140, height: 140)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(.blue)

                Text("Searching...")
                    .font(.system(size: 15, weight: .semibold))
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
