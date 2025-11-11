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
            level: 12,
            xp: 2350,
            nextLevelXp: 3000,
            totalBadges: 18,
            currentStreak: 7,
            longestStreak: 21
        )
        
        loadAchievementsData()
    }
    
    // MARK: - Data Loading
    
    private func loadAchievementsData() {
        isLoading = true
        
        // Mock data - In production, fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.badges = [
                BadgeItem(
                    id: "1",
                    icon: "🏃",
                    title: "Marathon Runner",
                    description: "Completed 5+ running events",
                    category: "Running",
                    unlocked: true,
                    unlockedDate: "Oct 28, 2025",
                    rarity: "rare"
                ),
                BadgeItem(
                    id: "2",
                    icon: "🏊",
                    title: "Water Warrior",
                    description: "Joined 10+ swimming sessions",
                    category: "Swimming",
                    unlocked: true,
                    unlockedDate: "Oct 15, 2025",
                    rarity: "common"
                ),
                BadgeItem(
                    id: "3",
                    icon: "👥",
                    title: "Social Butterfly",
                    description: "Connected with 25+ athletes",
                    category: "Social",
                    unlocked: true,
                    unlockedDate: "Oct 10, 2025",
                    rarity: "uncommon"
                ),
                BadgeItem(
                    id: "4",
                    icon: "⭐",
                    title: "Top Host",
                    description: "Hosted 10+ successful events",
                    category: "Hosting",
                    unlocked: true,
                    unlockedDate: "Oct 5, 2025",
                    rarity: "rare"
                ),
                BadgeItem(
                    id: "5",
                    icon: "🔥",
                    title: "Consistency King",
                    description: "Maintain a 30-day streak",
                    category: "Consistency",
                    unlocked: false,
                    progress: 7,
                    total: 30,
                    rarity: "epic"
                ),
                BadgeItem(
                    id: "6",
                    icon: "🌟",
                    title: "Early Bird",
                    description: "Join 20 morning sessions",
                    category: "Participation",
                    unlocked: false,
                    progress: 12,
                    total: 20,
                    rarity: "uncommon"
                )
            ]
            
            self?.challenges = [
                ChallengeItem(
                    id: "1",
                    title: "Weekend Warrior",
                    description: "Complete 4 activities this weekend",
                    progress: 2,
                    total: 4,
                    reward: "100 XP + Weekend Badge",
                    deadline: "2 days left"
                ),
                ChallengeItem(
                    id: "2",
                    title: "Variety Seeker",
                    description: "Try 3 different sports this week",
                    progress: 1,
                    total: 3,
                    reward: "150 XP + Explorer Badge",
                    deadline: "5 days left"
                ),
                ChallengeItem(
                    id: "3",
                    title: "Social Sprint",
                    description: "Connect with 5 new sport buddies",
                    progress: 3,
                    total: 5,
                    reward: "75 XP",
                    deadline: "7 days left"
                )
            ]
            
            self?.leaderboard = [
                LeaderboardEntry(rank: 1, name: "You", points: 2350, badge: "🥇"),
                LeaderboardEntry(rank: 2, name: "Sarah M.", points: 2280, badge: "🥈"),
                LeaderboardEntry(rank: 3, name: "Mike R.", points: 2150, badge: "🥉"),
                LeaderboardEntry(rank: 4, name: "Emma L.", points: 2020, badge: ""),
                LeaderboardEntry(rank: 5, name: "Alex T.", points: 1980, badge: "")
            ]
            
            self?.isLoading = false
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
