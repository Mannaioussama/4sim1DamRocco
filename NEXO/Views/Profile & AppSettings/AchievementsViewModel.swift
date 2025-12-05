//
//  AchievementsViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
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

class AchievementsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedTab: String = "badges"
    @Published var userStats: AchievementsUserStats
    @Published var badges: [BadgeItem] = []
    @Published var challenges: [ChallengeItem] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading: Bool = false
    @Published var selectedBadge: BadgeItem?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var levelText: String {
        return "Level \(userStats.level)"
    }
    
    var xpProgressText: String {
        return "\(userStats.xp) / \(userStats.nextLevelXp)"
    }
    
    var xpProgress: Double {
        guard userStats.nextLevelXp > 0 else { return 0 }
        return Double(userStats.xp) / Double(userStats.nextLevelXp)
    }
    
    var totalBadgesText: String {
        return "\(userStats.totalBadges)"
    }
    
    var currentStreakText: String {
        return "\(userStats.currentStreak)"
    }
    
    var longestStreakText: String {
        return "\(userStats.longestStreak)"
    }
    
    var unlockedBadges: [BadgeItem] {
        return badges.filter { $0.unlocked }
    }
    
    var lockedBadges: [BadgeItem] {
        return badges.filter { !$0.unlocked }
    }
    
    var activeChallenges: [ChallengeItem] {
        return challenges.filter { $0.progress < $0.total }
    }
    
    var completedChallenges: [ChallengeItem] {
        return challenges.filter { $0.progress >= $0.total }
    }
    
    var userRank: Int? {
        return leaderboard.first { $0.name == "You" }?.rank
    }
    
    var userPoints: Int? {
        return leaderboard.first { $0.name == "You" }?.points
    }
    
    var isBadgesTab: Bool {
        return selectedTab == "badges"
    }
    
    var isChallengesTab: Bool {
        return selectedTab == "challenges"
    }
    
    var isLeaderboardTab: Bool {
        return selectedTab == "leaderboard"
    }
    
    // MARK: - Initialization
    
    init() {
        self.userStats = AchievementsUserStats(
            level: 0,
            xp: 0,
            nextLevelXp: 1,
            totalBadges: 0,
            currentStreak: 0,
            longestStreak: 0
        )
        
        loadAchievementsData()
    }
    
    // MARK: - Data Loading
    
    private func loadAchievementsData() {
        isLoading = true
        
        Task {
            await fetchAchievementsFromBackend()
        }
    }
    
    @MainActor
    private func fetchAchievementsFromBackend() async {
        do {
            let summary = try await AchievementsAPI.getSummary()
            let badgesResponse = try await AchievementsAPI.getBadges()
            let challengesResponse = try await AchievementsAPI.getChallenges()
            let leaderboardResponse = try await AchievementsAPI.getLeaderboard()
            
            let stats = AchievementsUserStats(
                level: summary.level.currentLevel,
                xp: summary.level.currentLevelXp,
                nextLevelXp: summary.level.xpForNextLevel,
                totalBadges: summary.stats.totalBadges,
                currentStreak: summary.stats.currentStreak,
                longestStreak: summary.stats.bestStreak
            )
            
            let mappedBadges = mapBadges(from: badgesResponse)
            let mappedChallenges = mapChallenges(from: challengesResponse)
            let mappedLeaderboard = mapLeaderboard(from: leaderboardResponse)
            
            self.userStats = stats
            self.badges = mappedBadges
            self.challenges = mappedChallenges
            self.leaderboard = mappedLeaderboard
            self.isLoading = false
        } catch {
            print("Failed to load achievements: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
    
    func refreshData() {
        loadAchievementsData()
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ tab: String) {
        withAnimation(.spring(response: 0.3)) {
            selectedTab = tab
        }
    }
    
    func getTabTitle(_ tab: String) -> String {
        return tab.capitalized
    }
    
    func isTabSelected(_ tab: String) -> Bool {
        return selectedTab == tab
    }
    
    // MARK: - Badge Actions
    
    func selectBadge(_ badge: BadgeItem) {
        selectedBadge = badge
    }
    
    func deselectBadge() {
        selectedBadge = nil
    }
    
    func getBadgeProgress(_ badge: BadgeItem) -> Double? {
        guard let progress = badge.progress, let total = badge.total else { return nil }
        return Double(progress) / Double(total)
    }
    
    func getBadgeProgressText(_ badge: BadgeItem) -> String? {
        guard let progress = badge.progress, let total = badge.total else { return nil }
        return "\(progress)/\(total)"
    }
    
    func getBadgesByCategory(_ category: String) -> [BadgeItem] {
        return badges.filter { $0.category == category }
    }
    
    func getBadgesByRarity(_ rarity: String) -> [BadgeItem] {
        return badges.filter { $0.rarity == rarity }
    }
    
    // MARK: - Challenge Actions
    
    func getChallengeProgress(_ challenge: ChallengeItem) -> Double {
        return Double(challenge.progress) / Double(challenge.total)
    }
    
    func getChallengeProgressText(_ challenge: ChallengeItem) -> String {
        return "\(challenge.progress)/\(challenge.total)"
    }
    
    func isChallengeComplete(_ challenge: ChallengeItem) -> Bool {
        return challenge.progress >= challenge.total
    }
    
    func claimChallengeReward(_ challengeId: String) {
        // TODO: Claim reward on backend
        print("Claiming reward for challenge: \(challengeId)")
    }
    
    // MARK: - Leaderboard Actions
    
    func isUserEntry(_ entry: LeaderboardEntry) -> Bool {
        return entry.name == "You"
    }
    
    func getLeaderboardRankText(_ entry: LeaderboardEntry) -> String {
        if !entry.badge.isEmpty {
            return entry.badge
        }
        return "\(entry.rank)"
    }
    
    func getLeaderboardPointsText(_ entry: LeaderboardEntry) -> String {
        return "\(entry.points) XP"
    }
    
    // MARK: - XP and Level Management
    
    func addXP(_ amount: Int) {
        // TODO: Update XP on backend
        print("Adding \(amount) XP")
    }
    
    func getLevelProgressPercentage() -> Double {
        return xpProgress * 100
    }
    
    func getXPToNextLevel() -> Int {
        return userStats.nextLevelXp - userStats.xp
    }
    
    func getXPToNextLevelText() -> String {
        let remaining = getXPToNextLevel()
        return "\(remaining) XP to level \(userStats.level + 1)"
    }
    
    // MARK: - Streak Management
    
    func getStreakMessage() -> String {
        if userStats.currentStreak >= 7 {
            return "🔥 Amazing streak! Keep it up!"
        } else if userStats.currentStreak >= 3 {
            return "💪 Great consistency!"
        } else {
            return "🎯 Build your streak!"
        }
    }
    
    func isStreakRecord() -> Bool {
        return userStats.currentStreak == userStats.longestStreak
    }
    
    // MARK: - Helper Methods
    
    private func mapBadges(from response: AchievementsAPI.BadgesResponse) -> [BadgeItem] {
        var items: [BadgeItem] = []
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        
        for badge in response.earnedBadges {
            let dateString = badge.earnedAt.map { df.string(from: $0) }
            let item = BadgeItem(
                id: badge.id,
                icon: emoji(for: badge.category),
                title: badge.name,
                description: badge.description,
                category: badge.category.rawValue,
                unlocked: true,
                unlockedDate: dateString,
                progress: nil,
                total: nil,
                rarity: badge.rarity.rawValue
            )
            items.append(item)
        }
        
        for progress in response.inProgress {
            let b = progress.badge
            let safeTarget = max(progress.target, 1)
            let safeProgress = min(progress.currentProgress, safeTarget)
            let item = BadgeItem(
                id: progress.id,
                icon: b.iconUrl ?? emoji(for: b.category),
                title: b.name,
                description: b.description,
                category: b.category.rawValue,
                unlocked: false,
                unlockedDate: nil,
                progress: safeProgress,
                total: safeTarget,
                rarity: b.rarity.rawValue
            )
            items.append(item)
        }
        
        return items.sorted { lhs, rhs in
            if lhs.unlocked != rhs.unlocked {
                return lhs.unlocked && !rhs.unlocked
            }
            return lhs.title < rhs.title
        }
    }
    
    private func mapChallenges(from response: AchievementsAPI.ChallengesResponse) -> [ChallengeItem] {
        return response.activeChallenges.map { challenge in
            ChallengeItem(
                id: challenge.id,
                title: challenge.name,
                description: challenge.description,
                progress: challenge.currentProgress,
                total: challenge.target,
                reward: "\(challenge.xpReward) XP",
                deadline: "\(challenge.daysLeft) days left"
            )
        }
    }
    
    private func mapLeaderboard(from response: AchievementsAPI.LeaderboardResponse) -> [LeaderboardEntry] {
        let currentUsername = response.currentUser?.username
        let currentRank = response.currentUser?.rank
        var seenRanks = Set<Int>()
        var result: [LeaderboardEntry] = []

        let sorted = response.leaderboard.sorted { $0.rank < $1.rank }
        for entry in sorted {
            // Avoid duplicate rows with the same rank (backend can sometimes repeat entries)
            if seenRanks.contains(entry.rank) {
                continue
            }
            seenRanks.insert(entry.rank)

            let isCurrentUser = (currentUsername != nil && entry.username == currentUsername) ||
                (currentRank != nil && entry.rank == currentRank)
            let displayName = isCurrentUser ? "You" : entry.username

            let badgeSymbol: String
            if let medal = entry.medal, !medal.isEmpty {
                badgeSymbol = medal
            } else {
                badgeSymbol = rankBadge(for: entry.rank)
            }

            let uiEntry = LeaderboardEntry(
                rank: entry.rank,
                name: displayName,
                points: entry.totalXp,
                badge: badgeSymbol
            )
            result.append(uiEntry)
        }

        return result
    }
    
    private func emoji(for category: AchievementsAPI.Badge.BadgeCategory) -> String {
        switch category {
        case .streak: return "🔥"
        case .distance: return "🏃"
        case .duration: return "⏱"
        case .sport: return "⚽️"
        case .creation: return "🎯"
        case .completion: return "✅"
        }
    }
    
    private func rankBadge(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    func getBadge(by id: String) -> BadgeItem? {
        return badges.first { $0.id == id }
    }
    
    func getChallenge(by id: String) -> ChallengeItem? {
        return challenges.first { $0.id == id }
    }
    
    func getLeaderboardEntry(by rank: Int) -> LeaderboardEntry? {
        return leaderboard.first { $0.rank == rank }
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Achievements screen viewed")
    }
    
    func trackTabView(_ tab: String) {
        // TODO: Implement analytics tracking
        print("Viewed achievements tab: \(tab)")
    }
    
    func trackBadgeView(_ badge: BadgeItem) {
        // TODO: Implement analytics tracking
        print("Viewed badge: \(badge.title)")
    }
    
    func trackChallengeView(_ challenge: ChallengeItem) {
        // TODO: Implement analytics tracking
        print("Viewed challenge: \(challenge.title)")
    }
    
    func trackLeaderboardView() {
        // TODO: Implement analytics tracking
        print("Viewed leaderboard")
    }
    
    func trackRewardClaimed(_ challengeId: String) {
        // TODO: Implement analytics tracking
        print("Claimed reward for challenge: \(challengeId)")
    }
}
