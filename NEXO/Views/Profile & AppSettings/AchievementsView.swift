//
//  AchievementsView.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var theme: Theme
    @State private var selectedTab: String = "badges"

    // MARK: - Mock Data
    let userStats = AchievementsUserStats(
        level: 12, xp: 2350, nextLevelXp: 3000,
        totalBadges: 18, currentStreak: 7, longestStreak: 21
    )

    let badges: [BadgeItem] = [
        .init(id: "1", icon: "🏃", title: "Marathon Runner", description: "Completed 5+ running events", category: "Running", unlocked: true, unlockedDate: "Oct 28, 2025", rarity: "rare"),
        .init(id: "2", icon: "🏊", title: "Water Warrior", description: "Joined 10+ swimming sessions", category: "Swimming", unlocked: true, unlockedDate: "Oct 15, 2025", rarity: "common"),
        .init(id: "3", icon: "👥", title: "Social Butterfly", description: "Connected with 25+ athletes", category: "Social", unlocked: true, unlockedDate: "Oct 10, 2025", rarity: "uncommon"),
        .init(id: "4", icon: "⭐", title: "Top Host", description: "Hosted 10+ successful events", category: "Hosting", unlocked: true, unlockedDate: "Oct 5, 2025", rarity: "rare"),
        .init(id: "5", icon: "🔥", title: "Consistency King", description: "Maintain a 30-day streak", category: "Consistency", unlocked: false, progress: 7, total: 30, rarity: "epic"),
        .init(id: "6", icon: "🌟", title: "Early Bird", description: "Join 20 morning sessions", category: "Participation", unlocked: false, progress: 12, total: 20, rarity: "uncommon")
    ]

    let challenges: [ChallengeItem] = [
        .init(id: "1", title: "Weekend Warrior", description: "Complete 4 activities this weekend", progress: 2, total: 4, reward: "100 XP + Weekend Badge", deadline: "2 days left"),
        .init(id: "2", title: "Variety Seeker", description: "Try 3 different sports this week", progress: 1, total: 3, reward: "150 XP + Explorer Badge", deadline: "5 days left"),
        .init(id: "3", title: "Social Sprint", description: "Connect with 5 new sport buddies", progress: 3, total: 5, reward: "75 XP", deadline: "7 days left")
    ]

    let leaderboard: [LeaderboardEntry] = [
        .init(rank: 1, name: "You", points: 2350, badge: "🥇"),
        .init(rank: 2, name: "Sarah M.", points: 2280, badge: "🥈"),
        .init(rank: 3, name: "Mike R.", points: 2150, badge: "🥉"),
        .init(rank: 4, name: "Emma L.", points: 2020, badge: ""),
        .init(rank: 5, name: "Alex T.", points: 1980, badge: "")
    ]

    // MARK: - Body
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs
            ScrollView {
                VStack(spacing: 16) {
                    statsCard
                    tabSwitcher
                    tabContent
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats
    private var statsCard: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Your Level")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        Text("Level \(userStats.level)")
                            .font(.title3.bold())
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("XP Progress")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        Text("\(userStats.xp) / \(userStats.nextLevelXp)")
                            .font(.subheadline.bold())
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                ProgressView(value: Double(userStats.xp) / Double(userStats.nextLevelXp))
                    .tint(.yellow)
            }
            .padding()
            .background(
                LinearGradient(colors: [
                    Color.yellow.opacity(theme.isDarkMode ? 0.22 : 0.3),
                    Color.orange.opacity(theme.isDarkMode ? 0.18 : 0.2)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)

            HStack(spacing: 8) {
                quickStat(icon: "rosette", value: "\(userStats.totalBadges)", label: "Badges")
                quickStat(icon: "bolt.fill", value: "\(userStats.currentStreak)", label: "Streak")
                quickStat(icon: "chart.line.uptrend.xyaxis", value: "\(userStats.longestStreak)", label: "Best Streak")
            }
        }
    }

    private func quickStat(icon: String, value: String, label: String) -> some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(.yellow)
            Text(value)
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // MARK: - Tabs
    private var tabSwitcher: some View {
        HStack {
            ForEach(["badges", "challenges", "leaderboard"], id: \.self) { tab in
                AchievementsTabButton(
                    title: tab.capitalized,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
                .environmentObject(theme)
            }
        }
        .padding(6)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case "badges": badgesGrid
        case "challenges": challengesList
        case "leaderboard": leaderboardList
        default: EmptyView()
        }
    }

    // MARK: - Badges
    private var badgesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(badges) { badge in
                BadgeCard(badge: badge)
                    .environmentObject(theme)
            }
        }
    }

    // MARK: - Challenges
    private var challengesList: some View {
        VStack(spacing: 10) {
            ForEach(challenges) { challenge in
                ChallengeCard(challenge: challenge)
                    .environmentObject(theme)
            }
        }
    }

    // MARK: - Leaderboard
    private var leaderboardList: some View {
        VStack(spacing: 8) {
            ForEach(leaderboard) { entry in
                LeaderboardRow(entry: entry)
                    .environmentObject(theme)
            }
        }
    }

    // MARK: - Background Orbs
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [
                    Color.purple.opacity(theme.isDarkMode ? 0.22 : 0.3),
                    Color.pink.opacity(theme.isDarkMode ? 0.16 : 0.2)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: -120, y: -150)
            Circle()
                .fill(LinearGradient(colors: [
                    Color.blue.opacity(theme.isDarkMode ? 0.16 : 0.2),
                    Color.purple.opacity(theme.isDarkMode ? 0.2 : 0.3)
                ], startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 150, y: 250)
        }
        .allowsHitTesting(false)
    }
}

#if DEBUG
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AchievementsView()
                .environmentObject(Theme())
        }
    }
}
#endif

// MARK: - Subviews

private struct AchievementsTabButton: View {
    @EnvironmentObject private var theme: Theme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                    ? AnyShapeStyle(
                        LinearGradient(colors: [
                            Color(hexValue: "#A855F7"),
                            Color(hexValue: "#EC4899")
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                      )
                    : AnyShapeStyle(theme.colors.cardBackground)
                )
                .foregroundColor(isSelected ? .white : theme.colors.textSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 3, y: 2)
        }
    }
}

private struct LeaderboardRow: View {
    @EnvironmentObject private var theme: Theme
    let entry: LeaderboardEntry
    var body: some View {
        HStack {
            Text(entry.badge.isEmpty ? "\(entry.rank)" : entry.badge)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(entry.name == "You" ? Color.yellow.opacity(0.3) : theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(14)
            VStack(alignment: .leading) {
                Text(entry.name).font(.subheadline.bold()).foregroundColor(theme.colors.textPrimary)
                Text("\(entry.points) XP").font(.caption).foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
            if entry.name == "You" {
                Text("You")
                    .font(.caption2.bold())
                    .padding(4)
                    .background(Color.yellow)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(
            entry.name == "You"
            ? AnyShapeStyle(
                LinearGradient(colors: [
                    Color(hexValue: "#FEF3C7"),
                    Color(hexValue: "#FDE68A")
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
              )
            : AnyShapeStyle(theme.colors.cardBackground)
        )
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

private struct BadgeCard: View {
    @EnvironmentObject private var theme: Theme
    let badge: BadgeItem
    var body: some View {
        VStack(spacing: 6) {
            Text(badge.icon).font(.largeTitle)
            Text(badge.title).font(.subheadline.bold()).foregroundColor(theme.colors.textPrimary)
            Text(badge.description).font(.caption).foregroundColor(theme.colors.textSecondary)
            if badge.unlocked {
                Text(badge.rarity.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        LinearGradient(colors: [
                            Color(hexValue: "#A855F7"),
                            Color(hexValue: "#EC4899")
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                ProgressView(value: Double(badge.progress ?? 0) / Double(badge.total ?? 1))
                    .tint(.yellow)
                Text("\(badge.progress ?? 0)/\(badge.total ?? 0)").font(.caption2).foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }
}

private struct ChallengeCard: View {
    @EnvironmentObject private var theme: Theme
    let challenge: ChallengeItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(challenge.title).font(.headline).foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text(challenge.deadline)
                    .font(.caption2)
                    .padding(4)
                    .background(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(6)
            }
            Text(challenge.description).font(.caption).foregroundColor(theme.colors.textSecondary)
            ProgressView(value: Double(challenge.progress) / Double(challenge.total))
                .tint(.yellow)
            Text("Reward: \(challenge.reward)")
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding()
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Models
struct AchievementsUserStats {
    let level: Int
    let xp: Int
    let nextLevelXp: Int
    let totalBadges: Int
    let currentStreak: Int
    let longestStreak: Int
}

struct BadgeItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let category: String
    let unlocked: Bool
    var unlockedDate: String? = nil
    var progress: Int? = nil
    var total: Int? = nil
    let rarity: String
}

struct ChallengeItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let progress: Int
    let total: Int
    let reward: String
    let deadline: String
}

struct LeaderboardEntry: Identifiable {
    let rank: Int
    let name: String
    let points: Int
    let badge: String
    var id: Int { rank }
}

// MARK: - Color Helper
extension Color {
    init(hexValue: String) {
        let hex = hexValue.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
