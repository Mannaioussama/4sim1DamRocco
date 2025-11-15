//
//  AICoachService.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation
import Combine
import SwiftUI
import WeatherKit

class AICoachService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var lastAnalysis: AICoachResponse?
    @Published var error: String?
    
    private let healthKitManager: HealthKitManager
    private let geminiService: GeminiAIService
    private let activityAPIService: ActivityAPIService
    private var cancellables = Set<AnyCancellable>()
    
    // Weather service
    @available(iOS 16.0, *)
    private lazy var weatherService = WeatherKitService()
    private let legacyWeatherService = LegacyWeatherService()
    
    // User session tracking
    @Published var recentSessions: [UserSession] = []
    @Published var userPreferences: [String] = []
    
    init(healthKitManager: HealthKitManager = HealthKitManager(), geminiService: GeminiAIService = GeminiAIService(), activityAPIService: ActivityAPIService = ActivityAPIService()) {
        self.healthKitManager = healthKitManager
        self.geminiService = geminiService
        self.activityAPIService = activityAPIService
        
        setupBindings()
        loadUserPreferences()
        
        // Start weather data loading
        Task {
            await loadWeatherData()
        }
    }
    
    private func setupBindings() {
        // Bind Gemini service state
        geminiService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAnalyzing, on: self)
            .store(in: &cancellables)
        
        geminiService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        geminiService.$lastResponse
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastAnalysis, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Main Analysis Function
    func performFullAnalysis() async {
        await MainActor.run {
            self.isAnalyzing = true
            self.error = nil
        }
        
        // Request HealthKit authorization if needed
        if !healthKitManager.isAuthorized {
            await healthKitManager.requestAuthorization()
        }
        
        // Refresh health data and weather
        await healthKitManager.refreshData()
        await loadWeatherData()
        
        // Get current health metrics
        guard let healthMetrics = healthKitManager.currentMetrics else {
            await MainActor.run {
                self.error = "Unable to load health data"
                self.isAnalyzing = false
            }
            return
        }
        
        // Get available activities for recommendations
        let availableActivities = activityAPIService.getActivitiesForAIRecommendation(
            userSportPreferences: userPreferences,
            userLevel: "Intermediate" // TODO: Get from user profile
        )
        
        let activitySummary = activityAPIService.getActivitySummaryForAI()
        
        // Perform AI analysis with weather data and real activities
        let weatherAnalysis = getWeatherAnalysisForAI()
        let response = await geminiService.analyzeHealthDataAndGenerateRecommendations(
            healthMetrics: healthMetrics,
            recentWorkouts: healthKitManager.recentWorkouts,
            weeklyTrends: healthKitManager.weeklyTrends,
            userPreferences: userPreferences,
            weatherAnalysis: weatherAnalysis,
            availableActivities: availableActivities,
            activitySummary: activitySummary
        )
        
        if let response = response {
            await MainActor.run {
                self.lastAnalysis = response
                self.saveAnalysisToCache(response)
            }
        }
        
        await MainActor.run {
            self.isAnalyzing = false
        }
    }
    
    // MARK: - Session Tracking
    func addUserSession(_ session: UserSession) {
        recentSessions.append(session)
        
        // Keep only last 10 sessions
        if recentSessions.count > 10 {
            recentSessions.removeFirst()
        }
        
        saveUserSessions()
    }
    
    func getRecentSessionsSummary() -> String {
        if recentSessions.isEmpty {
            return "No recent sessions recorded"
        }
        
        let sessionSummary = recentSessions.suffix(5).map { session in
            let date = DateFormatter.shortDate.string(from: session.date)
            return "- \(date): \(session.activityType) with \(session.participants) people, \(session.duration) min"
        }.joined(separator: "\n")
        
        return "Recent Social Sessions:\n\(sessionSummary)"
    }
    
    // MARK: - User Preferences
    func updateUserPreferences(_ preferences: [String]) {
        userPreferences = preferences
        saveUserPreferences()
    }
    
    func addUserPreference(_ preference: String) {
        if !userPreferences.contains(preference) {
            userPreferences.append(preference)
            saveUserPreferences()
        }
    }
    
    // MARK: - Quick Analysis
    func getQuickRecommendations() -> [String] {
        guard let analysis = lastAnalysis else {
            return [
                "Start with a 20-minute walk today",
                "Try a new sport this week",
                "Connect with friends for a workout"
            ]
        }
        
        return analysis.recommendations
    }
    
    func getMotivationalMessage() -> String {
        return lastAnalysis?.motivationalMessage ?? "Every step counts! 🚀"
    }
    
    // MARK: - Data Persistence
    private func saveAnalysisToCache(_ analysis: AICoachResponse) {
        // Save to UserDefaults or Core Data
        // For now, just keep in memory
    }
    
    private func saveUserSessions() {
        if let encoded = try? JSONEncoder().encode(recentSessions) {
            UserDefaults.standard.set(encoded, forKey: "RecentSessions")
        }
    }
    
    private func loadUserSessions() {
        if let data = UserDefaults.standard.data(forKey: "RecentSessions"),
           let sessions = try? JSONDecoder().decode([UserSession].self, from: data) {
            recentSessions = sessions
        }
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(userPreferences, forKey: "UserPreferences")
    }
    
    private func loadUserPreferences() {
        userPreferences = UserDefaults.standard.stringArray(forKey: "UserPreferences") ?? []
        loadUserSessions()
    }
    
    // MARK: - Health Data Access
    func getCurrentHealthMetrics() -> HealthMetrics? {
        return healthKitManager.currentMetrics
    }
    
    func getRecentWorkouts() -> [WorkoutSession] {
        return healthKitManager.recentWorkouts
    }
    
    func getWeeklyTrends() -> [HealthMetrics] {
        return healthKitManager.weeklyTrends
    }
    
    // MARK: - Convenience Methods
    func refreshAllData() async {
        await performFullAnalysis()
    }
    
    // MARK: - Weather Integration
    
    private func loadWeatherData() async {
        if #available(iOS 16.0, *) {
            await weatherService.requestLocationAndWeather()
        }
        // Legacy weather service is already initialized with default data
    }
    
    func getCurrentWeatherInfo() -> WeatherInfo? {
        if #available(iOS 16.0, *) {
            return weatherService.getWeatherInfo()
        } else {
            return legacyWeatherService.weatherInfo
        }
    }
    
    private func getWeatherAnalysisForAI() -> String {
        if #available(iOS 16.0, *) {
            return weatherService.getWeatherAnalysisForAI()
        } else {
            return legacyWeatherService.getWeatherAnalysisForAI()
        }
    }
    
    func isHealthKitAuthorized() -> Bool {
        return healthKitManager.isAuthorized
    }
    
    func requestHealthKitPermission() async {
        await healthKitManager.requestAuthorization()
    }
}

// MARK: - User Session Model
struct UserSession: Codable, Identifiable {
    let id = UUID()
    let activityType: String
    let duration: Int // minutes
    let participants: Int
    let location: String?
    let date: Date
    let notes: String?
    
    init(activityType: String, duration: Int, participants: Int, location: String? = nil, notes: String? = nil) {
        self.activityType = activityType
        self.duration = duration
        self.participants = participants
        self.location = location
        self.date = Date()
        self.notes = notes
    }
}

// MARK: - Extensions for AI Coach Integration
extension AICoachService {
    func convertAISuggestionsToViewModels() -> [Suggestion] {
        guard let analysis = lastAnalysis else { return [] }
        
        return analysis.suggestions.map { aiSuggestion in
            Suggestion(
                title: aiSuggestion.title,
                description: aiSuggestion.description,
                icon: aiSuggestion.icon,
                time: aiSuggestion.time,
                participants: aiSuggestion.participants,
                matchScore: aiSuggestion.matchScore
            )
        }
    }
    
    func convertAITipsToViewModels() -> [Tip] {
        guard let analysis = lastAnalysis else { return [] }
        
        return analysis.tips.map { aiTip in
            Tip(
                title: aiTip.title,
                description: aiTip.description,
                icon: aiTip.icon,
                category: aiTip.category
            )
        }
    }
}

// MARK: - Mock Data for Development
extension AICoachService {
    static func createMockService() -> AICoachService {
        let service = AICoachService()
        
        // Add some mock sessions
        service.recentSessions = [
            UserSession(activityType: "Cycling", duration: 45, participants: 3, location: "Central Park"),
            UserSession(activityType: "Running", duration: 30, participants: 1, location: "Local Track"),
            UserSession(activityType: "Basketball", duration: 60, participants: 8, location: "Community Center")
        ]
        
        // Add mock preferences
        service.userPreferences = ["Outdoor Activities", "Group Sports", "Morning Workouts"]
        
        return service
    }
}
