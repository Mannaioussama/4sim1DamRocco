//
//  AICoachViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import SwiftUI
import Combine
import HealthKit

// MARK: - Data Models
struct Suggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let time: String
    let participants: Int
    let matchScore: Int
}

struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: String
}

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let progress: Int
    let total: Int
    let reward: String
}

struct WeeklyStats {
    let workouts: Int
    let goal: Int
    let calories: Int
    let minutes: Int
    let streak: Int
}

struct WeatherInfo {
    let temperature: Int
    let condition: String
    let description: String
    let icon: String
}

class AICoachViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedTab: String = "overview"
    @Published var navigateToAchievements: Bool = false
    @Published var navigateToMatchmaker: Bool = false
    @Published var weeklyStats: WeeklyStats
    @Published var suggestions: [Suggestion] = []
    @Published var workoutTips: [Tip] = []
    @Published var challenges: [Challenge] = []
    @Published var weatherInfo: WeatherInfo?
    
    // AI Coach Integration
    @Published var isLoadingAIAnalysis = false
    @Published var aiAnalysisError: String?
    @Published var lastAIUpdate: Date?
    
    // Services
    private let aiCoachService: AICoachService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var motivationalMessage: String {
        return aiCoachService.getMotivationalMessage()
    }
    
    var motivationalSubtext: String {
        if let lastUpdate = lastAIUpdate {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Last updated: \(formatter.string(from: lastUpdate))"
        }
        return "Keep going! You're doing great 💪"
    }
    
    var weeklyGoalProgress: Double {
        return Double(weeklyStats.workouts) / Double(weeklyStats.goal)
    }
    
    var weeklyGoalText: String {
        return "\(weeklyStats.workouts)/\(weeklyStats.goal)"
    }
    
    var streakBadgeText: String {
        return "\(weeklyStats.streak) day streak"
    }
    
    var weatherDisplayText: String {
        guard let weather = weatherInfo else { return "" }
        return "\(weather.temperature)°F, \(weather.condition) — \(weather.description)"
    }
    
    var weatherTitle: String {
        guard let weather = weatherInfo else { return "Loading weather..." }
        return weather.condition == "sunny" ? "Perfect weather today!" : "Weather update"
    }
    
    // MARK: - Initialization
    
    init(aiCoachService: AICoachService = AICoachService()) {
        self.aiCoachService = aiCoachService
        
        // Initialize with default stats
        self.weeklyStats = WeeklyStats(
            workouts: 3,
            goal: 5,
            calories: 1200,
            minutes: 180,
            streak: 7
        )
        
        setupBindings()
        loadData()
        
        // Load AI analysis if available
        Task {
            await loadAIAnalysis()
        }
    }
    
    private func setupBindings() {
        // Bind AI Coach service state
        aiCoachService.$isAnalyzing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingAIAnalysis, on: self)
            .store(in: &cancellables)
        
        aiCoachService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.aiAnalysisError, on: self)
            .store(in: &cancellables)
        
        // Update suggestions and tips when AI analysis completes
        aiCoachService.$lastAnalysis
            .receive(on: DispatchQueue.main)
            .sink { [weak self] analysis in
                self?.updateWithAIAnalysis(analysis)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        loadSuggestions()
        loadWorkoutTips()
        loadChallenges()
        loadWeather()
        updateHealthStats()
    }
    
    private func updateHealthStats() {
        print("📊 Updating health stats...")
        
        // Update stats from HealthKit if available
        if let healthMetrics = aiCoachService.getCurrentHealthMetrics() {
            print("📊 Got health metrics: \(healthMetrics.steps) steps, \(healthMetrics.activeCalories) calories")
            
            let workouts = aiCoachService.getRecentWorkouts()
            let weeklyWorkoutCount = workouts.filter { workout in
                Calendar.current.isDate(workout.startDate, equalTo: Date(), toGranularity: .weekOfYear)
            }.count
            
            weeklyStats = WeeklyStats(
                workouts: weeklyWorkoutCount,
                goal: weeklyStats.goal,
                calories: healthMetrics.activeCalories,
                minutes: healthMetrics.workoutMinutes,
                streak: weeklyStats.streak // Keep existing streak logic
            )
            
            print("📊 Updated stats: \(weeklyWorkoutCount) workouts, \(healthMetrics.activeCalories) calories")
        } else {
            print("📊 No health metrics available yet")
        }
    }
    
    private func loadSuggestions() {
        // Load AI-generated suggestions if available, otherwise use defaults
        let aiSuggestions = aiCoachService.convertAISuggestionsToViewModels()
        if !aiSuggestions.isEmpty {
            suggestions = aiSuggestions
        } else {
            // Fallback to default suggestions
            suggestions = [
                .init(title: "Try a morning swim", description: "4 swimmers nearby are free tomorrow 7AM", icon: "🏊", time: "Tomorrow 7AM", participants: 4, matchScore: 95),
                .init(title: "Join evening yoga session", description: "Perfect for recovery after your runs", icon: "🧘", time: "Today 6PM", participants: 8, matchScore: 88),
                .init(title: "Weekend cycling group", description: "Explore new routes with local cyclists", icon: "🚴", time: "Saturday 8AM", participants: 12, matchScore: 82)
            ]
        }
    }
    
    private func loadWorkoutTips() {
        // Load AI-generated tips if available, otherwise use defaults
        let aiTips = aiCoachService.convertAITipsToViewModels()
        if !aiTips.isEmpty {
            workoutTips = aiTips
        } else {
            // Fallback to default tips
            workoutTips = [
                .init(title: "Warm-up is essential", description: "Spend 5-10 minutes warming up to prevent injuries and improve performance.", icon: "🔥", category: "Basics"),
                .init(title: "Stay hydrated", description: "Drink water before, during, and after your workout for optimal performance.", icon: "💧", category: "Health"),
                .init(title: "Progressive overload", description: "Gradually increase intensity to continue seeing improvements.", icon: "📈", category: "Training")
            ]
        }
    }
    
    private func loadChallenges() {
        // Mock data - In production, fetch from API
        challenges = [
            .init(title: "30-Day Running Streak", description: "Run at least 1 mile every day for 30 days", progress: 7, total: 30, reward: "🏆 Marathon Badge"),
            .init(title: "Weekly Variety Challenge", description: "Try 3 different sports this week", progress: 1, total: 3, reward: "⭐ Explorer Badge")
        ]
    }
    
    private func loadWeather() {
        // Load real weather data from AI Coach service
        if let realWeather = aiCoachService.getCurrentWeatherInfo() {
            weatherInfo = realWeather
        } else {
            // Fallback to default weather
            weatherInfo = WeatherInfo(
                temperature: 72,
                condition: "sunny",
                description: "ideal for outdoor training",
                icon: "sun.max.fill"
            )
        }
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ tab: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
        }
    }
    
    // MARK: - Actions
    
    func joinSuggestion(_ suggestion: Suggestion) {
        // TODO: Implement join logic
        print("Joining suggestion: \(suggestion.title)")
    }
    
    func startChallenge() {
        // TODO: Navigate to challenges/achievements
        navigateToAchievements = true
    }
    
    func findPartner() {
        // TODO: Navigate to matchmaker
        navigateToMatchmaker = true
    }
    
    func browseVideos() {
        // TODO: Navigate to video library
        print("Browsing workout videos")
    }
    
    func refreshData() {
        loadData()
        
        // Refresh AI analysis
        Task {
            await refreshAIAnalysis()
        }
    }
    
    // MARK: - AI Analysis Methods
    
    @MainActor
    func loadAIAnalysis() async {
        // Check if we need to request HealthKit permission
        if !aiCoachService.isHealthKitAuthorized() {
            await aiCoachService.requestHealthKitPermission()
        }
        
        // Load existing analysis or perform new one if needed
        if aiCoachService.lastAnalysis == nil {
            await aiCoachService.performFullAnalysis()
        }
        
        lastAIUpdate = Date()
    }
    
    @MainActor
    func refreshAIAnalysis() async {
        await aiCoachService.refreshAllData()
        lastAIUpdate = Date()
    }
    
    private func updateWithAIAnalysis(_ analysis: AICoachResponse?) {
        guard analysis != nil else { return }
        
        // Update suggestions and tips with AI data
        loadSuggestions()
        loadWorkoutTips()
        
        lastAIUpdate = Date()
    }
    
    // MARK: - Session Tracking
    
    func recordUserSession(activityType: String, duration: Int, participants: Int, location: String? = nil) {
        let session = UserSession(
            activityType: activityType,
            duration: duration,
            participants: participants,
            location: location
        )
        
        aiCoachService.addUserSession(session)
        
        // Trigger a refresh of AI analysis after adding session
        Task {
            await refreshAIAnalysis()
        }
    }
    
    func addUserPreference(_ preference: String) {
        aiCoachService.addUserPreference(preference)
    }
    
    @MainActor
    func requestHealthKitPermissionsIfNeeded() async {
        print("🏥 Requesting HealthKit permissions...")
        
        // Always request permission (will use mock data for free accounts)
        await aiCoachService.requestHealthKitPermission()
        
        // Wait a moment for data to be processed
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Force refresh all data
        print("🏥 Force refreshing all data...")
        updateHealthStats()
        loadWeather()
        
        // Trigger AI analysis with the new data
        await refreshAIAnalysis()
    }
    
    // MARK: - Helper Methods
    
    func getChallengeProgress(_ challenge: Challenge) -> Double {
        return Double(challenge.progress) / Double(challenge.total)
    }
    
    func getChallengeProgressText(_ challenge: Challenge) -> String {
        return "\(challenge.progress)/\(challenge.total)"
    }
    
    func getMatchScoreText(_ suggestion: Suggestion) -> String {
        return "\(suggestion.matchScore)% match"
    }
    
    func getParticipantsText(_ suggestion: Suggestion) -> String {
        return "\(suggestion.participants) interested"
    }
    
    func getStatValue(for stat: String) -> String {
        switch stat {
        case "workouts":
            return "\(weeklyStats.workouts)"
        case "calories":
            return "\(weeklyStats.calories)"
        case "minutes":
            return "\(weeklyStats.minutes)"
        default:
            return "0"
        }
    }
    
    // MARK: - Analytics
    
    func trackTabView(_ tab: String) {
        // TODO: Implement analytics tracking
        print("Viewed tab: \(tab)")
    }
    
    func trackSuggestionInteraction(_ suggestion: Suggestion) {
        // TODO: Implement analytics tracking
        print("Interacted with suggestion: \(suggestion.title)")
    }
}
