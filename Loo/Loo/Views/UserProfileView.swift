//
//  UserProfileView.swift
//  Loo
//
//  User stats, badges, and privacy-first profile
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var communityService: CommunityService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Level & Trust Score
                    LevelCard()
                        .environmentObject(communityService)

                    // Stats Grid
                    StatsGrid()
                        .environmentObject(communityService)

                    // Badges
                    BadgesSection()
                        .environmentObject(communityService)

                    // Privacy Info
                    PrivacySection()
                        .environmentObject(communityService)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(BackgroundView(isDarkMode: isDarkMode).ignoresSafeArea())
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Level Card
struct LevelCard: View {
    @EnvironmentObject var communityService: CommunityService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        VStack(spacing: 16) {
            // Level badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                levelColor.opacity(0.8),
                                levelColor.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: levelColor.opacity(0.4), radius: 20)

                Text(communityService.currentLevel.emoji)
                    .font(.system(size: 50))
            }

            Text(communityService.currentLevel.rawValue)
                .font(.system(size: 24, weight: .bold))

            // Points
            Text("\(communityService.userStats.points) points")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            // Progress to next level
            if let nextLevel = nextLevelInfo {
                VStack(spacing: 8) {
                    ProgressView(value: Double(communityService.userStats.points),
                                total: Double(nextLevel.required))
                        .tint(levelColor)

                    Text("\(nextLevel.remaining) points to \(nextLevel.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            // Trust Score
            HStack(spacing: 20) {
                VStack {
                    Text("\(communityService.trustScore)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(trustScoreColor)
                    Text("Trust Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(communityService.userStats.totalReports)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }

    var levelColor: Color {
        switch communityService.currentLevel {
        case .newbie: return .blue
        case .scout: return .cyan
        case .ranger: return .purple
        case .titan: return .indigo
        case .royalty: return .yellow
        }
    }

    var trustScoreColor: Color {
        let score = communityService.trustScore
        if score >= 80 { return .green }
        if score >= 60 { return .blue }
        if score >= 40 { return .orange }
        return .red
    }

    var nextLevelInfo: (name: String, required: Int, remaining: Int)? {
        let points = communityService.userStats.points
        switch communityService.currentLevel {
        case .newbie:
            return ("Bathroom Scout", 100, 100 - points)
        case .scout:
            return ("Restroom Ranger", 500, 500 - points)
        case .ranger:
            return ("Toilet Titan", 1500, 1500 - points)
        case .titan:
            return ("Loo Royalty", 5000, 5000 - points)
        case .royalty:
            return nil
        }
    }
}

// MARK: - Stats Grid
struct StatsGrid: View {
    @EnvironmentObject var communityService: CommunityService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Contributions")
                .font(.system(size: 20, weight: .semibold))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "🆕",
                    title: "Bathrooms Added",
                    value: "\(communityService.userStats.bathroomsAdded)"
                )

                StatCard(
                    icon: "🔑",
                    title: "Codes Shared",
                    value: "\(communityService.userStats.codesShared)"
                )

                StatCard(
                    icon: "📸",
                    title: "Photos",
                    value: "\(communityService.userStats.photosUploaded)"
                )

                StatCard(
                    icon: "⭐",
                    title: "Reviews",
                    value: "\(communityService.userStats.reviewsWritten)"
                )

                StatCard(
                    icon: "✅",
                    title: "Verifications",
                    value: "\(communityService.userStats.verificationsGiven)"
                )

                StatCard(
                    icon: "🙏",
                    title: "Thanks Received",
                    value: "\(communityService.userStats.thanksReceived)"
                )
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 32))

            Text(value)
                .font(.system(size: 24, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Badges Section
struct BadgesSection: View {
    @EnvironmentObject var communityService: CommunityService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges Earned")
                .font(.system(size: 20, weight: .semibold))

            if communityService.userStats.badges.isEmpty {
                Text("Complete challenges to earn badges!")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(communityService.userStats.badges, id: \.self) { badge in
                        BadgeCard(badge: badge)
                    }
                }
            }

            // Available badges
            if communityService.userStats.badges.count < Badge.allCases.count {
                Text("Available Badges")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Badge.allCases.filter { !communityService.userStats.badges.contains($0) }, id: \.self) { badge in
                        BadgeCard(badge: badge, locked: true)
                    }
                }
            }
        }
    }
}

struct BadgeCard: View {
    let badge: Badge
    var locked: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(locked ? Color.gray.opacity(0.3) : Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)

                Text(badge.emoji)
                    .font(.system(size: 30))
                    .opacity(locked ? 0.4 : 1.0)

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .offset(x: 15, y: 15)
                }
            }

            Text(badge.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(locked ? .secondary : .primary)

            Text(badge.description)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Privacy Section
struct PrivacySection: View {
    @EnvironmentObject var communityService: CommunityService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("Privacy First")
                    .font(.system(size: 20, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 12) {
                PrivacyItem(
                    icon: "checkmark.shield.fill",
                    text: "No account required - fully anonymous"
                )

                PrivacyItem(
                    icon: "iphone",
                    text: "All data stored locally on your device"
                )

                PrivacyItem(
                    icon: "eye.slash.fill",
                    text: "Zero tracking or analytics"
                )

                PrivacyItem(
                    icon: "hand.raised.fill",
                    text: "You control your data"
                )
            }

            // Data controls
            VStack(spacing: 12) {
                Button(action: {
                    communityService.regenerateAnonymousId()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Generate New Anonymous ID")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    communityService.clearAllData()
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Clear All Local Data")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct PrivacyItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}
