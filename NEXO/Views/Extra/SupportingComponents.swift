//
//  SupportingComponents.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//  All reusable components, models, and extensions
//

import SwiftUI
import CoreLocation

// MARK: - Models

struct SportCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Floating Orb
// Note: FloatingOrb is defined in Splashscreenview.swift to avoid duplication

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Floating Create Button (glass/crystal FAB)

struct FloatingCreateButton: View {
    @EnvironmentObject private var theme: Theme
    let icon: String
    let action: () -> Void

    // Size constants to ensure perfect centering and consistent visuals
    private let buttonSize: CGFloat = 56
    private let strokeWidth: CGFloat = 2

    var body: some View {
        Button(action: action) {
            ZStack {
                // Subtle outer glow (kept outside the fixed frame so it doesn't shift content)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.colors.accentPurpleGlow.opacity(0.45),
                                theme.colors.accentPink.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .blur(radius: 12)

                // Glass button with fixed frame to guarantee icon centering
                ZStack {
                    Circle()
                        .fill(theme.colors.cardBackground)
                        .background(
                            Circle()
                                .fill(theme.colors.barMaterial)
                        )
                        .overlay(
                            Circle()
                                .stroke(theme.colors.cardStroke, lineWidth: strokeWidth)
                        )

                    // Centered icon (default: plus)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: buttonSize, height: buttonSize, alignment: .center)
                        .contentShape(Rectangle())
                }
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
            }
            .contentShape(Circle())
            .accessibilityLabel("Create")
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Corner Radius Extension
// Note: cornerRadius and RoundedCorner are defined in Splashscreenview.swift to avoid duplication

// MARK: - Mock Data

let mockActivities: [Activity] = [
    Activity(
        id: "1",
        title: "Morning Basketball Game",
        sportType: "Basketball",
        sportIcon: "🏀",
        hostName: "John Doe",
        hostAvatar: "https://i.pravatar.cc/150?img=33",
        date: "Today",
        time: "9:00 AM",
        location: "Downtown Court",
        distance: "2.3 mi",
        spotsTotal: 10,
        spotsTaken: 7,
        level: "Intermediate",
        visibility: "public"
    ),
    Activity(
        id: "2",
        title: "Evening Yoga Session",
        sportType: "Yoga",
        sportIcon: "🧘",
        hostName: "Sarah Johnson",
        hostAvatar: "https://i.pravatar.cc/150?img=9",
        date: "Today",
        time: "6:00 PM",
        location: "Zen Studio",
        distance: "1.5 mi",
        spotsTotal: 15,
        spotsTaken: 10,
        level: "All Levels",
        visibility: "public"
    ),
    Activity(
        id: "3",
        title: "Weekend Tennis Match",
        sportType: "Tennis",
        sportIcon: "🎾",
        hostName: "Mike Chen",
        hostAvatar: "https://i.pravatar.cc/150?img=12",
        date: "Tomorrow",
        time: "10:00 AM",
        location: "City Tennis Club",
        distance: "3.1 mi",
        spotsTotal: 4,
        spotsTaken: 2,
        level: "Advanced",
        visibility: "public"
    ),
    Activity(
        id: "4",
        title: "Beach Volleyball Tournament",
        sportType: "Volleyball",
        sportIcon: "🏐",
        hostName: "Emma Wilson",
        hostAvatar: "https://i.pravatar.cc/150?img=5",
        date: "Saturday",
        time: "2:00 PM",
        location: "Santa Monica Beach",
        distance: "5.2 mi",
        spotsTotal: 12,
        spotsTaken: 8,
        level: "Intermediate",
        visibility: "public"
    ),
    Activity(
        id: "5",
        title: "Morning Run Club",
        sportType: "Running",
        sportIcon: "🏃",
        hostName: "David Lee",
        hostAvatar: "https://i.pravatar.cc/150?img=15",
        date: "Tomorrow",
        time: "7:00 AM",
        location: "Central Park",
        distance: "0.8 mi",
        spotsTotal: 20,
        spotsTaken: 15,
        level: "All Levels",
        visibility: "public"
    ),
    Activity(
        id: "6",
        title: "Sunset Hiking Trail",
        sportType: "Hiking",
        sportIcon: "🥾",
        hostName: "Lisa Martinez",
        hostAvatar: "https://i.pravatar.cc/150?img=25",
        date: "Sunday",
        time: "5:00 PM",
        location: "Mountain Vista Trail",
        distance: "7.5 mi",
        spotsTotal: 8,
        spotsTaken: 5,
        level: "Intermediate",
        visibility: "public"
    )
]

let sportCategories: [SportCategory] = [
    SportCategory(name: "Basketball", icon: "🏀"),
    SportCategory(name: "Tennis", icon: "🎾"),
    SportCategory(name: "Volleyball", icon: "🏐"),
    SportCategory(name: "Running", icon: "🏃"),
    SportCategory(name: "Swimming", icon: "🏊"),
    SportCategory(name: "Cycling", icon: "🚴"),
    SportCategory(name: "Yoga", icon: "🧘"),
    SportCategory(name: "Hiking", icon: "🥾"),
    SportCategory(name: "Soccer", icon: "⚽"),
    SportCategory(name: "Golf", icon: "⛳")
]

#if DEBUG
struct SupportingComponents_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeedView(
            onActivityClick: { _ in },
            onSearchClick: {},
            onAISuggestionsClick: {},
            onQuickMatchClick: {},
            onAIMatchmakerClick: {},
            onEventDetailsClick: {},
            onCreateClick: {},
            onNotificationsClick: {},
            onCreateSessionClick: {},
            onChatClick: { _ in }
        )
        .environmentObject(Theme())
        .environmentObject(ActivityAPIService(fallbackEnabled: true)) // Preview uses mock data
    }
}
#endif

