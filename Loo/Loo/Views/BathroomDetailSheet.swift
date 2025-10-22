//
//  BathroomDetailSheet.swift
//  Loo
//
//  Detailed bathroom view with reviews and community reports
//

import SwiftUI
import MapKit

struct BathroomDetailSheet: View {
    let bathroom: Bathroom
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var communityService: CommunityService
    @EnvironmentObject var favoritesManager: FavoritesManager
    @AppStorage("isDarkMode") private var isDarkMode = false

    @State private var showingReportSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with rating
                    BathroomHeader(bathroom: bathroom)
                        .environmentObject(favoritesManager)

                    // Quick actions
                    QuickActionsRow(bathroom: bathroom, showingReportSheet: $showingReportSheet)

                    // Community reports
                    CommunityReportsSection(bathroom: bathroom)
                        .environmentObject(communityService)

                    // Details
                    DetailsSection(bathroom: bathroom)

                    // Accessibility
                    AccessibilitySection(bathroom: bathroom)

                    // Access requirements
                    if bathroom.accessRequirements.hasRestrictions {
                        AccessRequirementsSection(bathroom: bathroom)
                    }
                }
                .padding()
            }
            .background(BackgroundView(isDarkMode: isDarkMode).ignoresSafeArea())
            .navigationTitle(bathroom.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingReportSheet) {
                QuickReportSheet(bathroom: bathroom)
                    .environmentObject(communityService)
            }
        }
    }
}

// MARK: - Bathroom Header
struct BathroomHeader: View {
    let bathroom: Bathroom
    @EnvironmentObject var favoritesManager: FavoritesManager

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(bathroom.name)
                        .font(.system(size: 24, weight: .bold))

                    Text(bathroom.businessType)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    if let rating = bathroom.rating {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: Double(index) < rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 16))
                            }
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 16, weight: .semibold))
                            Text("(\(bathroom.reviewCount))")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button {
                    favoritesManager.toggleFavorite(bathroom)
                } label: {
                    Image(systemName: favoritesManager.isFavorite(bathroom) ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundColor(favoritesManager.isFavorite(bathroom) ? .yellow : .gray)
                }
            }

            if let distance = bathroom.distance {
                Text("\(formatDistance(distance)) away")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func formatDistance(_ distance: Double) -> String {
        let miles = distance / 1609.34
        if miles < 0.1 {
            return String(format: "%.0f ft", distance * 3.28084)
        }
        return String(format: "%.1f mi", miles)
    }
}

// MARK: - Quick Actions
struct QuickActionsRow: View {
    let bathroom: Bathroom
    @Binding var showingReportSheet: Bool

    var body: some View {
        HStack(spacing: 12) {
            ActionButton(icon: "exclamationmark.bubble", title: "Report", color: .orange) {
                showingReportSheet = true
            }

            ActionButton(icon: "arrow.triangle.turn.up.right.diamond", title: "Directions", color: .blue) {
                openInMaps()
            }

            ActionButton(icon: "square.and.arrow.up", title: "Share", color: .green) {
                shareLocation()
            }
        }
    }

    func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: bathroom.coordinate))
        mapItem.name = bathroom.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    func shareLocation() {
        // Share functionality
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Community Reports
struct CommunityReportsSection: View {
    let bathroom: Bathroom
    @EnvironmentObject var communityService: CommunityService

    var activeReports: [CommunityReport] {
        communityService.getActiveReports(for: bathroom.id)
    }

    var body: some View {
        if !activeReports.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Live Community Reports")
                    .font(.system(size: 18, weight: .semibold))

                ForEach(activeReports) { report in
                    CommunityReportCard(report: report)
                        .environmentObject(communityService)
                }
            }
        }
    }
}

struct CommunityReportCard: View {
    let report: CommunityReport
    @EnvironmentObject var communityService: CommunityService

    var body: some View {
        HStack {
            Text(report.type.emoji)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 4) {
                Text(report.type.rawValue)
                    .font(.system(size: 14, weight: .semibold))

                if let message = report.message {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(report.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if report.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    communityService.verifyReport(report.id, isAccurate: true)
                } label: {
                    VStack {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("\(report.verifications)")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }

                Button {
                    communityService.thankUser(for: report.id)
                } label: {
                    VStack {
                        Image(systemName: "heart.fill")
                        Text("\(report.thanksCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Details Section
struct DetailsSection: View {
    let bathroom: Bathroom

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 18, weight: .semibold))

            DetailRow(icon: "clock", title: "Hours", value: bathroom.openingHours ?? "Not available")
            DetailRow(icon: "car", title: "Parking", value: bathroom.parkingEase.rawValue)
            DetailRow(icon: "door.left.hand.open", title: "Type", value: bathroom.details.stallType.rawValue)

            if bathroom.details.stallCount != nil {
                DetailRow(icon: "number", title: "Stalls", value: "\(bathroom.details.stallCount!) available")
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.blue)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Accessibility Section
struct AccessibilitySection: View {
    let bathroom: Bathroom

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accessibility")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 8) {
                AccessibilityRow(
                    icon: "figure.roll",
                    title: "Wheelchair Access",
                    status: bathroom.accessibility.wheelchairAccessible.rawValue
                )

                if bathroom.accessibility.babyChangingStation {
                    AccessibilityRow(icon: "figure.and.child.holdinghands", title: "Baby Changing", status: "Available")
                }

                if bathroom.accessibility.genderNeutral {
                    AccessibilityRow(icon: "person.fill.questionmark", title: "Gender Neutral", status: "Yes")
                }

                if bathroom.accessibility.grabBars {
                    AccessibilityRow(icon: "hand.raised", title: "Grab Bars", status: "Installed")
                }
            }
        }
    }
}

struct AccessibilityRow: View {
    let icon: String
    let title: String
    let status: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.green)

            Text(title)
                .font(.system(size: 14))

            Spacer()

            Text(status)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Access Requirements
struct AccessRequirementsSection: View {
    let bathroom: Bathroom

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Access Requirements")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 8) {
                if bathroom.accessRequirements.requiresKey {
                    RequirementRow(icon: "key.fill", text: "Key required")
                }

                if let code = bathroom.accessRequirements.doorCode {
                    RequirementRow(icon: "number", text: "Door code: \(code)", highlight: true)
                }

                if bathroom.accessRequirements.requiresFee {
                    if let amount = bathroom.accessRequirements.feeAmount {
                        RequirementRow(icon: "dollarsign.circle", text: "Fee: $\(String(format: "%.2f", amount))")
                    } else {
                        RequirementRow(icon: "dollarsign.circle", text: "Fee required")
                    }
                }

                if bathroom.accessRequirements.customerOnly {
                    RequirementRow(icon: "person.badge.key", text: "Customers only")
                }
            }
        }
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(highlight ? .blue : .orange)

            Text(text)
                .font(.system(size: 14, weight: highlight ? .bold : .regular))
                .foregroundColor(highlight ? .blue : .primary)

            Spacer()
        }
        .padding()
        .background(highlight ? Color.blue.opacity(0.1) : Color.clear)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Report Sheet
struct QuickReportSheet: View {
    let bathroom: Bathroom
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var communityService: CommunityService

    let quickReports: [ReportType] = [
        .clean, .dirty, .outOfOrder, .noToiletPaper,
        .noSoap, .longLine, .locked
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(quickReports, id: \.self) { reportType in
                        Button {
                            submitReport(reportType)
                        } label: {
                            VStack(spacing: 12) {
                                Text(reportType.emoji)
                                    .font(.system(size: 40))

                                Text(reportType.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Quick Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    func submitReport(_ type: ReportType) {
        let report = CommunityReport(bathroomId: bathroom.id, type: type)
        communityService.submitReport(report)
        dismiss()
    }
}
