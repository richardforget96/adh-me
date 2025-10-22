//
//  EnhancedContentView.swift
//  Loo
//
//  Full-featured UI with emergency mode, filters, reviews, community
//

import SwiftUI
import MapKit

struct EnhancedContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bathroomService: BathroomService
    @EnvironmentObject var favoritesManager: FavoritesManager
    @StateObject private var communityService = CommunityService()

    @AppStorage("isDarkMode") private var isDarkMode = false

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var showingList = false
    @State private var showingFilters = false
    @State private var showingProfile = false
    @State private var selectedBathroom: Bathroom?
    @State private var emergencyMode = false

    var displayedBathrooms: [Bathroom] {
        bathroomService.filters.hasActiveFilters ?
            bathroomService.filteredBathrooms :
            bathroomService.bathrooms
    }

    var body: some View {
        ZStack {
            // Background
            BackgroundView(isDarkMode: isDarkMode)

            VStack(spacing: 0) {
                // Header
                EnhancedHeaderView(
                    isDarkMode: $isDarkMode,
                    showingProfile: $showingProfile,
                    emergencyMode: $emergencyMode
                )
                .environmentObject(communityService)

                // Emergency Mode Banner
                if emergencyMode {
                    EmergencyModeBanner()
                }

                // Filter chips (if active)
                if bathroomService.filters.hasActiveFilters {
                    ActiveFiltersView()
                        .environmentObject(bathroomService)
                }

                // Main content
                if showingList {
                    EnhancedBathroomListView(
                        bathrooms: displayedBathrooms,
                        selectedBathroom: $selectedBathroom
                    )
                    .environmentObject(communityService)
                    .environmentObject(favoritesManager)
                } else {
                    EnhancedMapView(
                        region: $region,
                        bathrooms: displayedBathrooms,
                        selectedBathroom: $selectedBathroom
                    )
                    .environmentObject(communityService)
                }

                // Control panel
                EnhancedControlPanelView(
                    showingList: $showingList,
                    showingFilters: $showingFilters,
                    emergencyMode: $emergencyMode
                )
            }

            // Sheets
            .sheet(isPresented: $showingFilters) {
                FilterSheet()
                    .environmentObject(bathroomService)
                    .environmentObject(favoritesManager)
            }
            .sheet(isPresented: $showingProfile) {
                UserProfileView()
                    .environmentObject(communityService)
            }
            .sheet(item: $selectedBathroom) { bathroom in
                BathroomDetailSheet(bathroom: bathroom)
                    .environmentObject(communityService)
                    .environmentObject(favoritesManager)
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
                    bathroomService.applyFilters(favoritesManager: favoritesManager)
                }
            }
        }
        .onChange(of: emergencyMode) { _, isEmergency in
            if isEmergency {
                // Emergency mode: clear filters, show closest
                bathroomService.resetFilters()
            }
        }
    }
}

// MARK: - Enhanced Header
struct EnhancedHeaderView: View {
    @Binding var isDarkMode: Bool
    @Binding var showingProfile: Bool
    @Binding var emergencyMode: Bool
    @EnvironmentObject var communityService: CommunityService

    var body: some View {
        ZStack {
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

            HStack {
                // Title
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
                }
                .padding(.leading, 20)

                Spacer()

                // User level badge
                Button {
                    showingProfile = true
                } label: {
                    HStack(spacing: 6) {
                        Text(communityService.currentLevel.emoji)
                            .font(.system(size: 18))
                        Text("\(communityService.userStats.points)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isDarkMode ? .white : .primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }

                // Dark mode toggle
                LiquidGlassButton(
                    icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                    isDarkMode: isDarkMode,
                    accentColor: isDarkMode ? .purple : .orange,
                    size: .small
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

// MARK: - Emergency Banner
struct EmergencyModeBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text("EMERGENCY MODE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.red)
            Spacer()
            Text("Showing closest bathrooms")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }
}

// MARK: - Active Filters
struct ActiveFiltersView: View {
    @EnvironmentObject var bathroomService: BathroomService

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activeFilterChips, id: \.0) { filter in
                    FilterChip(text: filter.0, icon: filter.1) {
                        clearFilter(filter.0)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
    }

    var activeFilterChips: [(String, String)] {
        var chips: [(String, String)] = []
        if bathroomService.filters.showOnlyFavorites {
            chips.append(("Favorites", "star.fill"))
        }
        if bathroomService.filters.requireWheelchairAccess {
            chips.append(("Wheelchair", "figure.roll"))
        }
        if bathroomService.filters.requireBabyChanging {
            chips.append(("Baby Changing", "figure.and.child.holdinghands"))
        }
        if bathroomService.filters.showFreeOnly {
            chips.append(("Free Only", "dollarsign.circle"))
        }
        if bathroomService.filters.minimumRating > 0 {
            chips.append(("\(Int(bathroomService.filters.minimumRating))+ Stars", "star.fill"))
        }
        return chips
    }

    func clearFilter(_ name: String) {
        switch name {
        case "Favorites":
            bathroomService.filters.showOnlyFavorites = false
        case "Wheelchair":
            bathroomService.filters.requireWheelchairAccess = false
        case "Baby Changing":
            bathroomService.filters.requireBabyChanging = false
        case "Free Only":
            bathroomService.filters.showFreeOnly = false
        default:
            if name.contains("Stars") {
                bathroomService.filters.minimumRating = 0
            }
        }
    }
}

struct FilterChip: View {
    let text: String
    let icon: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Enhanced Control Panel
struct EnhancedControlPanelView: View {
    @Binding var showingList: Bool
    @Binding var showingFilters: Bool
    @Binding var emergencyMode: Bool

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bathroomService: BathroomService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        HStack(spacing: 12) {
            // Emergency button
            LiquidGlassButton(
                icon: emergencyMode ? "exclamationmark.triangle.fill" : "bolt.fill",
                isDarkMode: isDarkMode,
                accentColor: emergencyMode ? .red : .orange,
                size: .regular,
                pulseAnimation: emergencyMode
            ) {
                withAnimation {
                    emergencyMode.toggle()
                }
            }

            // Filter button
            LiquidGlassButton(
                icon: "slider.horizontal.3",
                isDarkMode: isDarkMode,
                accentColor: .blue,
                size: .regular,
                showBadge: bathroomService.filters.hasActiveFilters
            ) {
                showingFilters = true
            }

            // Toggle view
            LiquidGlassButton(
                icon: showingList ? "map.fill" : "list.bullet",
                isDarkMode: isDarkMode,
                accentColor: .cyan,
                size: .wide
            ) {
                withAnimation {
                    showingList.toggle()
                }
            }

            // Refresh
            LiquidGlassButton(
                icon: "arrow.clockwise",
                isDarkMode: isDarkMode,
                accentColor: .green,
                size: .regular
            ) {
                if let location = locationManager.location {
                    Task {
                        await bathroomService.fetchBathrooms(near: location)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
        )
    }
}

// Button size variants
extension LiquidGlassButton {
    enum ButtonSize {
        case small, regular, wide

        var width: CGFloat {
            switch self {
            case .small: return 50
            case .regular: return 56
            case .wide: return 120
            }
        }

        var height: CGFloat {
            switch self {
            case .small: return 50
            case .regular: return 56
            case .wide: return 56
            }
        }
    }
}

// Updated LiquidGlassButton with more options
struct LiquidGlassButton: View {
    let icon: String
    let isDarkMode: Bool
    var accentColor: Color = .blue
    var size: ButtonSize = .regular
    var showBadge: Bool = false
    var pulseAnimation: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Main button
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
                    .shadow(color: isPressed ? Color.black.opacity(0.2) : accentColor.opacity(0.3),
                            radius: isPressed ? 5 : 10,
                            y: isPressed ? 2 : 5)
                    .scaleEffect(pulseAnimation && !isPressed ? 1.05 : 1.0)
                    .animation(pulseAnimation ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: pulseAnimation)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isDarkMode ?
                                [.white, Color(red: 0.9, green: 0.95, blue: 1.0)] :
                                [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Badge indicator
                if showBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 4, y: -4)
                }
            }
            .frame(width: size.width, height: size.height)
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

#Preview {
    EnhancedContentView()
        .environmentObject(LocationManager())
        .environmentObject(BathroomService())
        .environmentObject(FavoritesManager())
}
