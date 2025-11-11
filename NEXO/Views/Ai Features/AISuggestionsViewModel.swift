//
//  AISuggestionsViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Model
struct ActivitySuggestion: Identifiable {
    let id: String
    let title: String
    let sportType: String
    let sportIcon: String
    let level: String
    let hostName: String
    let hostAvatar: String
    let date: String
    let time: String
    let location: String
    let distance: String
    let spotsTotal: Int
    let spotsTaken: Int
    let description: String
}

class AISuggestionsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var aiSuggestions: [ActivitySuggestion] = []
    @Published var savedActivities: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var hasSuggestions: Bool {
        return !aiSuggestions.isEmpty
    }
    
    var savedCount: Int {
        return savedActivities.count
    }
    
    var headerTitle: String {
        return "For You"
    }
    
    var headerSubtitle: String {
        return "AI-powered recommendations"
    }
    
    var personalizationTitle: String {
        return "Personalized Picks"
    }
    
    var personalizationDescription: String {
        return "Based on your activity & preferences"
    }
    
    var whyTheseTitle: String {
        return "Why these activities?"
    }
    
    var whyTheseDescription: String {
        return "We've selected activities matching your skill level, preferred sports, and schedule. These are nearby and have availability."
    }
    
    var moreComingTitle: String {
        return "More suggestions coming"
    }
    
    var moreComingDescription: String {
        return "As you join more activities, our AI will get better at recommending perfect matches."
    }
    
    // MARK: - Initialization
    
    init() {
        loadSuggestions()
        loadSavedActivities()
    }
    
    // MARK: - Data Loading
    
    private func loadSuggestions() {
        isLoading = true
        
        // Simulate AI processing - In production, this would call an AI/ML service
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.aiSuggestions = [
                .init(id: "ai-1",
                      title: "Morning Beach Volleyball Match",
                      sportType: "Volleyball",
                      sportIcon: "🏐",
                      level: "Intermediate",
                      hostName: "Emma Wilson",
                      hostAvatar: "https://i.pravatar.cc/150?img=5",
                      date: "Today",
                      time: "8:00 AM",
                      location: "Santa Monica Beach",
                      distance: "1.2 mi",
                      spotsTotal: 12,
                      spotsTaken: 8,
                      description: "Join us for a fun morning volleyball session!"),
                .init(id: "ai-2",
                      title: "Evening Running Group",
                      sportType: "Running",
                      sportIcon: "🏃",
                      level: "All Levels",
                      hostName: "Michael Chen",
                      hostAvatar: "https://i.pravatar.cc/150?img=12",
                      date: "Today",
                      time: "6:30 PM",
                      location: "Central Park",
                      distance: "0.8 mi",
                      spotsTotal: 15,
                      spotsTaken: 10,
                      description: "Easy-paced group run for all fitness levels"),
                .init(id: "ai-3",
                      title: "Yoga & Meditation Session",
                      sportType: "Yoga",
                      sportIcon: "🧘",
                      level: "Beginner",
                      hostName: "Sarah Johnson",
                      hostAvatar: "https://i.pravatar.cc/150?img=9",
                      date: "Tomorrow",
                      time: "7:00 AM",
                      location: "Zen Studio",
                      distance: "1.5 mi",
                      spotsTotal: 20,
                      spotsTaken: 15,
                      description: "Start your day with mindful movement"),
                .init(id: "ai-4",
                      title: "Pickup Basketball Game",
                      sportType: "Basketball",
                      sportIcon: "🏀",
                      level: "Intermediate",
                      hostName: "James Rodriguez",
                      hostAvatar: "https://i.pravatar.cc/150?img=15",
                      date: "Tomorrow",
                      time: "5:00 PM",
                      location: "Downtown Court",
                      distance: "2.1 mi",
                      spotsTotal: 10,
                      spotsTaken: 7,
                      description: "Competitive but friendly basketball match")
            ]
            
            self?.isLoading = false
        }
    }
    
    private func loadSavedActivities() {
        // Load saved activities from persistent storage
        // In production, this would load from UserDefaults or a database
        savedActivities = []
    }
    
    // MARK: - Actions
    
    func toggleSave(_ activityId: String) {
        if savedActivities.contains(activityId) {
            savedActivities.remove(activityId)
            // TODO: Remove from persistent storage
            print("Removed activity from saved: \(activityId)")
        } else {
            savedActivities.insert(activityId)
            // TODO: Save to persistent storage
            print("Added activity to saved: \(activityId)")
        }
    }
    
    func isSaved(_ activityId: String) -> Bool {
        return savedActivities.contains(activityId)
    }
    
    func joinActivity(_ activity: ActivitySuggestion) {
        // TODO: Implement join logic
        print("Joining activity: \(activity.title)")
        
        // Track AI suggestion success
        trackSuggestionJoined(activity)
    }
    
    func refreshSuggestions() {
        loadSuggestions()
    }
    
    // MARK: - Helper Methods
    
    func getSpotsRemaining(for activity: ActivitySuggestion) -> Int {
        return activity.spotsTotal - activity.spotsTaken
    }
    
    func getSpotsRemainingText(for activity: ActivitySuggestion) -> String {
        let remaining = getSpotsRemaining(for: activity)
        return "\(remaining) of \(activity.spotsTotal) spots remaining"
    }
    
    func getDateTimeText(for activity: ActivitySuggestion) -> String {
        return "\(activity.date) • \(activity.time)"
    }
    
    func getLocationDistanceText(for activity: ActivitySuggestion) -> String {
        return "\(activity.location) • \(activity.distance)"
    }
    
    func getFilteredSuggestions(by sportType: String? = nil) -> [ActivitySuggestion] {
        guard let sportType = sportType else { return aiSuggestions }
        return aiSuggestions.filter { $0.sportType == sportType }
    }
    
    func getSuggestionsBySport() -> [String: [ActivitySuggestion]] {
        return Dictionary(grouping: aiSuggestions) { $0.sportType }
    }
    
    // MARK: - Analytics
    
    func trackSuggestionViewed(_ activity: ActivitySuggestion) {
        // TODO: Implement analytics tracking
        print("User viewed suggestion: \(activity.title)")
    }
    
    func trackSuggestionJoined(_ activity: ActivitySuggestion) {
        // TODO: Implement analytics tracking
        print("User joined AI suggestion: \(activity.title)")
    }
    
    func trackSuggestionSaved(_ activity: ActivitySuggestion) {
        // TODO: Implement analytics tracking
        print("User saved suggestion: \(activity.title)")
    }
}
