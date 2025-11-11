//
//  AchievementsView.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = AchievementsViewModel()

    // MARK: - Body
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs
            
            if viewModel.isLoading {
                loadingView
            } else {
                mainContent
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.trackScreenView()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text("Loading achievements...")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
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

    // MARK: - Stats
    
    private var statsCard: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Your Level")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        Text(viewModel.levelText)
                            .font(.title3.bold())
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("XP Progress")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        Text(viewModel.xpProgressText)
                            .font(.subheadline.bold())
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                ProgressView(value: viewModel.xpProgress)
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
                quickStat(
                    icon: "rosette",
                    value: viewModel.totalBadgesText,
                    label: "Badges"
                )
                quickStat(
                    icon: "bolt.fill",
                    value: viewModel.currentStreakText,
                    label: "Streak"
                )
                quickStat(
                    icon: "chart.line.uptrend.xyaxis",
                    value: viewModel.longestStreakText,
                    label: "Best Streak"
                )
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
                    title: viewModel.getTabTitle(tab),
                    isSelected: viewModel.isTabSelected(tab)
                ) {
                    viewModel.selectTab(tab)
                    viewModel.trackTabView(tab)
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
        if viewModel.isBadgesTab {
            badgesGrid
        } else if viewModel.isChallengesTab {
            challengesList
        } else if viewModel.isLeaderboardTab {
            leaderboardList
        }
    }

    // MARK: - Badges
    
    private var badgesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(viewModel.badges) { badge in
                BadgeCard(badge: badge)
                    .environmentObject(theme)
                    .onTapGesture {
                        viewModel.selectBadge(badge)
                        viewModel.trackBadgeView(badge)
                    }
            }
        }
    }

    // MARK: - Challenges
    
    private var challengesList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.challenges) { challenge in
                ChallengeCard(challenge: challenge)
                    .environmentObject(theme)
                    .onAppear {
                        viewModel.trackChallengeView(challenge)
                    }
            }
        }
    }

    // MARK: - Leaderboard
    
    private var leaderboardList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.leaderboard) { entry in
                LeaderboardRow(
                    entry: entry,
                    isUser: viewModel.isUserEntry(entry)
                )
                .environmentObject(theme)
            }
        }
        .onAppear {
            viewModel.trackLeaderboardView()
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
    let isUser: Bool
    
    var body: some View {
        HStack {
            Text(entry.badge.isEmpty ? "\(entry.rank)" : entry.badge)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(isUser ? Color.yellow.opacity(0.3) : theme.colors.cardBackground)
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
            if isUser {
                Text("You")
                    .font(.caption2.bold())
                    .padding(4)
                    .background(Color.yellow)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(
            isUser
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
                if let progress = badge.progress, let total = badge.total {
                    ProgressView(value: Double(progress) / Double(total))
                        .tint(.yellow)
                    Text("\(progress)/\(total)").font(.caption2).foregroundColor(theme.colors.textSecondary)
                }
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
        .opacity(badge.unlocked ? 1.0 : 0.7)
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
            HStack {
                Text("Reward: \(challenge.reward)")
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text("\(challenge.progress)/\(challenge.total)")
                    .font(.caption2.bold())
                    .foregroundColor(theme.colors.textPrimary)
            }
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

// MARK: - Preview

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
