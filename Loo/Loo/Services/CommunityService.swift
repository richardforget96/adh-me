//
//  CommunityService.swift
//  Loo
//
//  Privacy-first community reporting system
//  No tracking, no servers, all anonymous
//

import Foundation
import Combine

/// Privacy-first community service
/// - No user accounts required
/// - All contributions anonymous
/// - Data stored locally
/// - Can optionally sync via CloudKit (privacy-respecting)
class CommunityService: ObservableObject {
    @Published var communityReports: [CommunityReport] = []
    @Published var userStats: UserStats

    private let reportsKey = "loo_community_reports"
    private let statsKey = "loo_user_stats"
    private let userDefaults = UserDefaults.standard

    // Anonymous user ID (generated once, stored locally)
    private let anonymousUserId: String

    init() {
        // Generate or retrieve anonymous ID
        if let existingId = userDefaults.string(forKey: "loo_anonymous_id") {
            anonymousUserId = existingId
        } else {
            anonymousUserId = UUID().uuidString
            userDefaults.set(anonymousUserId, forKey: "loo_anonymous_id")
        }

        // Load user stats
        if let data = userDefaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            userStats = decoded
        } else {
            userStats = UserStats()
        }

        loadReports()
    }

    // MARK: - Community Reports

    func submitReport(_ report: CommunityReport) {
        communityReports.append(report)
        saveReports()

        // Award points
        awardPoints(for: report.type)
    }

    func verifyReport(_ reportId: String, isAccurate: Bool) {
        guard let index = communityReports.firstIndex(where: { $0.id == reportId }) else { return }

        if isAccurate {
            communityReports[index].verifications += 1
        } else {
            communityReports[index].flags += 1
        }

        saveReports()

        // Award verification points
        userStats.points += 3
        userStats.verificationsGiven += 1
        saveStats()
    }

    func thankUser(for reportId: String) {
        guard let index = communityReports.firstIndex(where: { $0.id == reportId }) else { return }
        communityReports[index].thanksCount += 1
        saveReports()
    }

    // MARK: - Gamification

    private func awardPoints(for reportType: ReportType) {
        let points = reportType.points
        userStats.points += points
        userStats.totalReports += 1

        // Track specific report types
        switch reportType {
        case .newBathroom:
            userStats.bathroomsAdded += 1
        case .doorCode:
            userStats.codesShared += 1
        case .photo:
            userStats.photosUploaded += 1
        case .review:
            userStats.reviewsWritten += 1
        default:
            break
        }

        checkForBadges()
        saveStats()
    }

    private func checkForBadges() {
        var newBadges: [Badge] = []

        // Code Master badge
        if userStats.codesShared >= 25 && !userStats.badges.contains(.codeMaster) {
            newBadges.append(.codeMaster)
        }

        // Photo Pro badge
        if userStats.photosUploaded >= 50 && !userStats.badges.contains(.photoPro) {
            newBadges.append(.photoPro)
        }

        // Accessibility Advocate badge
        if userStats.accessibilityReports >= 20 && !userStats.badges.contains(.accessibilityAdvocate) {
            newBadges.append(.accessibilityAdvocate)
        }

        // Accuracy Expert badge
        let accuracy = userStats.verificationsReceived > 0 ?
            Double(userStats.verificationsReceived) / Double(userStats.totalReports) : 0
        if accuracy >= 0.9 && userStats.totalReports >= 10 && !userStats.badges.contains(.accuracyExpert) {
            newBadges.append(.accuracyExpert)
        }

        userStats.badges.append(contentsOf: newBadges)
    }

    var currentLevel: UserLevel {
        switch userStats.points {
        case 0..<100: return .newbie
        case 100..<500: return .scout
        case 500..<1500: return .ranger
        case 1500..<5000: return .titan
        default: return .royalty
        }
    }

    var trustScore: Int {
        // Calculate trust score (0-100) based on:
        // - Verifications received
        // - Flags received
        // - Total contributions
        let baseScore = 50
        let verificationBonus = min(userStats.verificationsReceived * 2, 40)
        let flagPenalty = min(userStats.flagsReceived * 5, 30)
        let activityBonus = min(userStats.totalReports / 10, 10)

        return max(0, min(100, baseScore + verificationBonus - flagPenalty + activityBonus))
    }

    // MARK: - Report Filtering

    func getRecentReports(for bathroomId: String, maxAge: TimeInterval = 86400) -> [CommunityReport] {
        let cutoffDate = Date().addingTimeInterval(-maxAge)
        return communityReports.filter {
            $0.bathroomId == bathroomId &&
            $0.timestamp > cutoffDate
        }.sorted { $0.timestamp > $1.timestamp }
    }

    func getActiveReports(for bathroomId: String) -> [CommunityReport] {
        getRecentReports(for: bathroomId, maxAge: 3600) // Last hour
    }

    // MARK: - Persistence

    private func saveReports() {
        if let encoded = try? JSONEncoder().encode(communityReports) {
            userDefaults.set(encoded, forKey: reportsKey)
        }
    }

    private func loadReports() {
        if let data = userDefaults.data(forKey: reportsKey),
           let decoded = try? JSONDecoder().decode([CommunityReport].self, from: data) {
            communityReports = decoded
        }
    }

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(userStats) {
            userDefaults.set(encoded, forKey: statsKey)
        }
    }

    // MARK: - Privacy

    /// Reset all local data (for privacy)
    func clearAllData() {
        communityReports = []
        userStats = UserStats()
        userDefaults.removeObject(forKey: reportsKey)
        userDefaults.removeObject(forKey: statsKey)
        // Keep anonymous ID unless user wants fresh start
    }

    /// Generate new anonymous ID (fresh start)
    func regenerateAnonymousId() {
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: "loo_anonymous_id")
    }
}

// MARK: - Models

struct CommunityReport: Identifiable, Codable {
    let id: String
    let bathroomId: String
    let type: ReportType
    let timestamp: Date
    let message: String?
    var verifications: Int
    var flags: Int
    var thanksCount: Int

    init(bathroomId: String, type: ReportType, message: String? = nil) {
        self.id = UUID().uuidString
        self.bathroomId = bathroomId
        self.type = type
        self.timestamp = Date()
        self.message = message
        self.verifications = 0
        self.flags = 0
        self.thanksCount = 0
    }

    var isVerified: Bool {
        verifications >= 3 && flags == 0
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum ReportType: String, Codable {
    case clean = "Clean"
    case dirty = "Dirty"
    case outOfOrder = "Out of Order"
    case noToiletPaper = "No Toilet Paper"
    case noSoap = "No Soap"
    case longLine = "Long Line"
    case doorCode = "Door Code"
    case locked = "Locked"
    case newBathroom = "New Bathroom"
    case photo = "Photo"
    case review = "Review"
    case hoursUpdate = "Hours Update"
    case accessibilityUpdate = "Accessibility Update"

    var emoji: String {
        switch self {
        case .clean: return "✨"
        case .dirty: return "⚠️"
        case .outOfOrder: return "🚫"
        case .noToiletPaper: return "🧻"
        case .noSoap: return "🧼"
        case .longLine: return "⏰"
        case .doorCode: return "🔢"
        case .locked: return "🔒"
        case .newBathroom: return "🆕"
        case .photo: return "📸"
        case .review: return "⭐"
        case .hoursUpdate: return "🕐"
        case .accessibilityUpdate: return "♿"
        }
    }

    var points: Int {
        switch self {
        case .newBathroom: return 15
        case .doorCode: return 20
        case .photo: return 8
        case .review: return 12
        case .hoursUpdate: return 5
        case .accessibilityUpdate: return 10
        case .outOfOrder: return 10
        default: return 3
        }
    }
}

struct UserStats: Codable {
    var points: Int
    var totalReports: Int
    var bathroomsAdded: Int
    var codesShared: Int
    var photosUploaded: Int
    var reviewsWritten: Int
    var verificationsGiven: Int
    var verificationsReceived: Int
    var flagsReceived: Int
    var thanksReceived: Int
    var accessibilityReports: Int
    var badges: [Badge]

    init() {
        self.points = 0
        self.totalReports = 0
        self.bathroomsAdded = 0
        self.codesShared = 0
        self.photosUploaded = 0
        self.reviewsWritten = 0
        self.verificationsGiven = 0
        self.verificationsReceived = 0
        self.flagsReceived = 0
        self.thanksReceived = 0
        self.accessibilityReports = 0
        self.badges = []
    }
}

enum UserLevel: String, Codable {
    case newbie = "Loo Newbie"
    case scout = "Bathroom Scout"
    case ranger = "Restroom Ranger"
    case titan = "Toilet Titan"
    case royalty = "Loo Royalty"

    var emoji: String {
        switch self {
        case .newbie: return "💧"
        case .scout: return "🚽"
        case .ranger: return "🏆"
        case .titan: return "👑"
        case .royalty: return "⭐"
        }
    }

    var color: String {
        switch self {
        case .newbie: return "#94C5FF"
        case .scout: return "#5EA3FF"
        case .ranger: return "#2E7FFF"
        case .titan: return "#9F5FFF"
        case .royalty: return "#FFD700"
        }
    }
}

enum Badge: String, Codable, CaseIterable {
    case codeMaster = "Code Master"
    case photoPro = "Photo Pro"
    case accessibilityAdvocate = "Accessibility Advocate"
    case accuracyExpert = "Accuracy Expert"
    case worldTraveler = "World Traveler"
    case nightOwl = "Night Owl"
    case quickResponder = "Quick Responder"

    var emoji: String {
        switch self {
        case .codeMaster: return "🔑"
        case .photoPro: return "📸"
        case .accessibilityAdvocate: return "♿"
        case .accuracyExpert: return "🎯"
        case .worldTraveler: return "🌍"
        case .nightOwl: return "🌙"
        case .quickResponder: return "⚡"
        }
    }

    var description: String {
        switch self {
        case .codeMaster: return "Shared 25+ door codes"
        case .photoPro: return "Uploaded 50+ photos"
        case .accessibilityAdvocate: return "Reported 20+ accessible bathrooms"
        case .accuracyExpert: return "90%+ verified reports"
        case .worldTraveler: return "Used bathrooms in 10+ cities"
        case .nightOwl: return "Used 10+ 24-hour bathrooms"
        case .quickResponder: return "Reported within 1 min of arrival"
        }
    }
}
