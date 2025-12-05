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

    // Optional Strava data
    @Published var stravaData: StravaData?

    // MARK: - Internal
    private let dataSource: AICoachRemoteDataSourceProtocol
    private var cancellables = Set<AnyCancellable>()

    enum AICoachTab: String, CaseIterable {
        case suggestions = "Suggestions"
        case tips = "Tips"
        case videos = "Videos"
    }

    // MARK: - Init
    init(dataSource: AICoachRemoteDataSourceProtocol = AICoachRemoteDataSource()) {
        self.dataSource = dataSource
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
}
