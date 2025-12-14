//
//  AICoachViewModel.swift
//  NEXO
//
//  Backend-driven AI Coach using /ai-coach/* endpoints.

import SwiftUI
import Combine

@MainActor
class AICoachViewModel: ObservableObject {
    // MARK: - Published Output
    @Published var suggestions: [AISuggestion] = []
    @Published var tips: [PersonalizedTip] = []
    @Published var youtubeVideos: [YouTubeVideo] = []
    @Published var isLoading = false
    @Published var isLoadingTips = false
    @Published var isLoadingVideos = false
    @Published var errorMessage: String?
    @Published var selectedTab: AICoachTab = .suggestions

    // Weekly/user stats (can be fed from Strava or app stats)
    @Published var weeklyWorkouts: Int = 0
    @Published var weeklyCalories: Int = 0
    @Published var weeklyMinutes: Int = 0
    @Published var currentStreak: Int = 0
    @Published var sportPreferences: String = ""
    @Published var location: String = ""
    @Published var preferredTimeOfDay: String = "any" // "morning", "afternoon", "evening", "any"

    // Level / XP (from achievements summary)
    @Published var currentLevel: Int = 0
    @Published var currentLevelXp: Int = 0
    @Published var xpForNextLevel: Int = 0
    @Published var totalXp: Int = 0
    @Published var bestStreak: Int = 0

    // Optional Strava data
    @Published var stravaData: StravaData?
    @Published var isStravaConnected: Bool

    // MARK: - Internal
    private let dataSource: AICoachRemoteDataSourceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var didBootstrap = false
    private var trackedSuggestionIds = Set<String>()
    private var trackedTipIds = Set<String>()

    enum AICoachTab: String, CaseIterable {
        case suggestions = "Suggestions"
        case tips = "Tips"
        case videos = "Videos"
    }

    // MARK: - Init
    init(dataSource: AICoachRemoteDataSourceProtocol = AICoachRemoteDataSource()) {
        self.dataSource = dataSource
        self.isStravaConnected = UserDefaults.standard.bool(forKey: "strava_is_connected")
    }

    // MARK: - Bootstrap / Stats from backend

    func bootstrapIfNeeded(activityAPIService: ActivityAPIService) {
        guard !didBootstrap else { return }
        didBootstrap = true

        Task { @MainActor in
            await refreshStatsAndSuggestions(activityAPIService: activityAPIService)
        }
    }

    @MainActor
    private func refreshStatsAndSuggestions(activityAPIService: ActivityAPIService) async {
        var summary: AchievementsAPI.AchievementSummary?

        do {
            summary = try await AchievementsAPI.getSummary()
        } catch {
            #if DEBUG
            print("❌ [AICoach] Failed to load achievements summary: \(error)")
            #endif
        }

        if activityAPIService.userActivities.isEmpty {
            await activityAPIService.fetchMyActivities()
        }

        if let summary = summary {
            currentLevel = summary.level.currentLevel
            totalXp = summary.level.totalXp
            currentLevelXp = summary.level.currentLevelXp
            xpForNextLevel = summary.level.xpForNextLevel
            bestStreak = summary.stats.bestStreak
        }

        let activities = activityAPIService.userActivities
        computeStats(from: summary, activities: activities)
        loadSuggestions()
    }

    private func computeStats(from summary: AchievementsAPI.AchievementSummary?, activities: [Activity]) {
        let workouts = activities.count

        var totalMinutes = 0
        var totalCalories = 0

        for activity in activities {
            let sport = activity.sportType.lowercased()

            let durationMinutes: Int
            let caloriesPerMinute: Int

            switch sport {
            case "running":
                durationMinutes = 60
                caloriesPerMinute = 12
            case "cycling":
                durationMinutes = 90
                caloriesPerMinute = 10
            case "basketball":
                durationMinutes = 75
                caloriesPerMinute = 9
            case "football":
                durationMinutes = 90
                caloriesPerMinute = 11
            default:
                durationMinutes = 60
                caloriesPerMinute = 8
            }

            totalMinutes += durationMinutes
            totalCalories += durationMinutes * caloriesPerMinute
        }

        let minutes = totalMinutes
        let calories = totalCalories
        let streak = summary?.stats.currentStreak ?? currentStreak

        updateStats(workouts: workouts, calories: calories, minutes: minutes, streak: streak)

        let sports = Array(Set(activities.map { $0.sportType })).sorted()
        if !sports.isEmpty {
            sportPreferences = sports.joined(separator: ", ")
        }
    }

    // MARK: - Suggestions
    func loadSuggestions() {
        isLoading = true
        errorMessage = nil

        let request = AISuggestionsRequest(
            workouts: weeklyWorkouts,
            calories: weeklyCalories,
            minutes: weeklyMinutes,
            streak: currentStreak,
            sportPreferences: sportPreferences.isEmpty ? nil : sportPreferences,
            stravaData: stravaData,
            location: location.isEmpty ? nil : location,
            preferredTimeOfDay: preferredTimeOfDay == "any" ? nil : preferredTimeOfDay
        )

        dataSource.getSuggestions(request: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [AICoach] Failed to load suggestions: \(error)")
                    #endif
                    self.errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                self.suggestions = response.suggestions
                if let tips = response.personalizedTips {
                    self.tips = tips
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Tips
    func loadTips() {
        isLoadingTips = true
        errorMessage = nil

        let sportPrefs = sportPreferences.isEmpty ? nil : sportPreferences.split(separator: ",").map(String.init)

        let request = PersonalizedTipsRequest(
            workouts: weeklyWorkouts,
            calories: weeklyCalories,
            minutes: weeklyMinutes,
            streak: currentStreak,
            sportPreferences: sportPrefs,
            recentActivities: nil,
            stravaData: stravaData != nil ? encodeStravaData() : nil
        )

        dataSource.getPersonalizedTips(request: request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingTips = false
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [AICoach] Failed to load tips: \(error)")
                    #endif
                    self.errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.tips = response.tips
            }
            .store(in: &cancellables)
    }

    // MARK: - YouTube Videos
    func loadYouTubeVideos() {
        isLoadingVideos = true
        errorMessage = nil

        let sportPrefs = sportPreferences.isEmpty ? nil : sportPreferences.split(separator: ",").map(String.init)

        dataSource.getYouTubeVideos(sportPreferences: sportPrefs, maxResults: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingVideos = false
                if case .failure(let error) = completion {
                    #if DEBUG
                    print("❌ [AICoach] Failed to load videos: \(error)")
                    #endif
                    self.errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.youtubeVideos = response.videos
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers
    private func encodeStravaData() -> String? {
        guard let data = stravaData else { return nil }
        do {
            let json = try JSONEncoder().encode(data)
            return String(data: json, encoding: .utf8)
        } catch {
            return nil
        }
    }

    func markStravaConnected() {
        isStravaConnected = true
        UserDefaults.standard.set(true, forKey: "strava_is_connected")
    }

    func disconnectStrava() {
        isStravaConnected = false
        stravaData = nil
        UserDefaults.standard.set(false, forKey: "strava_is_connected")
        // TODO: Call backend to revoke Strava tokens when endpoint is available.
    }

    // Update stats from outside (e.g. profile, Strava, or your own stats view)
    func updateStats(workouts: Int, calories: Int, minutes: Int, streak: Int) {
        weeklyWorkouts = workouts
        weeklyCalories = calories
        weeklyMinutes = minutes
        currentStreak = streak
    }

    func updateStravaData(_ data: StravaData) {
        stravaData = data
        if let weekly = data.weeklyStats {
            weeklyWorkouts = data.recentActivities?.count ?? 0
            weeklyCalories = 0
            weeklyMinutes = weekly.totalTime / 60
        }
    }

    // MARK: - Derived Header Info

    var levelDisplayText: String {
        guard currentLevel > 0 else { return "Level -" }
        return "Level \(currentLevel)"
    }

    var xpProgressText: String {
        guard xpForNextLevel > 0 else { return "" }
        return "\(currentLevelXp)/\(xpForNextLevel) XP"
    }

    var streakMessage: String {
        if currentStreak >= 7 {
            return "🔥 Amazing streak! Keep it up!"
        } else if currentStreak >= 3 {
            return "💪 Great consistency!"
        } else if currentStreak > 0 {
            return "🎯 Build your streak!"
        } else {
            return "Start building your streak!"
        }
    }

    // MARK: - Analytics / Tracking

    func trackScreenView() {
        print("📊 [Analytics] AI Coach screen viewed")
    }

    func trackTabChange(_ tab: AICoachTab) {
        print("📊 [Analytics] Switched to AI Coach tab: \(tab.rawValue)")
    }

    func trackSuggestionImpression(_ suggestion: AISuggestion) {
        if trackedSuggestionIds.contains(suggestion.id) { return }
        trackedSuggestionIds.insert(suggestion.id)
        print("📊 [Analytics] Suggestion shown: \(suggestion.id) - \(suggestion.title)")
    }

    func trackTipImpression(_ tip: PersonalizedTip) {
        let key = "\(tip.id)"
        if trackedTipIds.contains(key) { return }
        trackedTipIds.insert(key)
        print("📊 [Analytics] Tip shown: \(key) - \(tip.title)")
    }
}
