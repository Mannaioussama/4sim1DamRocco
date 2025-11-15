//
//  ActivityService.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation
import Combine

class ActivityService: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var userCreatedActivities: [Activity] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockActivities()
    }
    
    // MARK: - Public Methods
    
    func getAllActivities() -> [Activity] {
        return activities
    }
    
    func getUserCreatedActivities() -> [Activity] {
        return userCreatedActivities
    }
    
    func createActivity(
        title: String,
        sportType: String,
        sportIcon: String,
        date: String,
        time: String,
        location: String,
        spotsTotal: Int,
        level: String,
        hostName: String = "You"
    ) async -> Bool {
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let newActivity = Activity(
            id: UUID().uuidString,
            title: title,
            sportType: sportType,
            sportIcon: sportIcon,
            hostName: hostName,
            hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=\(hostName)",
            date: date,
            time: time,
            location: location,
            distance: "0.0 mi", // User's own activity
            spotsTotal: spotsTotal,
            spotsTaken: 1, // Host takes one spot
            level: level
        )
        
        await MainActor.run {
            self.activities.insert(newActivity, at: 0) // Add to beginning
            self.userCreatedActivities.insert(newActivity, at: 0)
            self.isLoading = false
        }
        
        print("✅ Created new activity: \(title)")
        return true
    }
    
    func joinActivity(_ activityId: String) async -> Bool {
        await MainActor.run {
            self.isLoading = true
        }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await MainActor.run {
            if let index = self.activities.firstIndex(where: { $0.id == activityId }) {
                var activity = self.activities[index]
                if activity.spotsTaken < activity.spotsTotal {
                    // Create updated activity with more spots taken
                    let updatedActivity = Activity(
                        id: activity.id,
                        title: activity.title,
                        sportType: activity.sportType,
                        sportIcon: activity.sportIcon,
                        hostName: activity.hostName,
                        hostAvatar: activity.hostAvatar,
                        date: activity.date,
                        time: activity.time,
                        location: activity.location,
                        distance: activity.distance,
                        spotsTotal: activity.spotsTotal,
                        spotsTaken: activity.spotsTaken + 1,
                        level: activity.level
                    )
                    self.activities[index] = updatedActivity
                    self.isLoading = false
                    print("✅ Joined activity: \(activity.title)")
                    return
                }
            }
            self.isLoading = false
        }
        
        return true
    }
    
    func refreshActivities() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        // Simulate API refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // Add some new mock activities
            self.addRandomActivity()
            self.isLoading = false
        }
    }
    
    // MARK: - AI Coach Integration
    
    func getActivitiesForAIRecommendation(
        userSportPreferences: [String] = [],
        userLocation: String = "",
        userLevel: String = "Intermediate"
    ) -> [Activity] {
        
        var recommendedActivities = activities
        
        // Filter by user preferences if available
        if !userSportPreferences.isEmpty {
            recommendedActivities = recommendedActivities.filter { activity in
                userSportPreferences.contains(activity.sportType)
            }
        }
        
        // Filter by user level (similar or one level different)
        let compatibleLevels: [String]
        switch userLevel {
        case "Beginner":
            compatibleLevels = ["Beginner", "Intermediate"]
        case "Intermediate":
            compatibleLevels = ["Beginner", "Intermediate", "Advanced"]
        case "Advanced":
            compatibleLevels = ["Intermediate", "Advanced"]
        default:
            compatibleLevels = ["Beginner", "Intermediate", "Advanced"]
        }
        
        recommendedActivities = recommendedActivities.filter { activity in
            compatibleLevels.contains(activity.level)
        }
        
        // Filter out full activities
        recommendedActivities = recommendedActivities.filter { activity in
            activity.spotsTaken < activity.spotsTotal
        }
        
        // Sort by spots available and recency
        recommendedActivities.sort { activity1, activity2 in
            let spots1 = activity1.spotsTotal - activity1.spotsTaken
            let spots2 = activity2.spotsTotal - activity2.spotsTaken
            return spots1 > spots2
        }
        
        return Array(recommendedActivities.prefix(10)) // Return top 10
    }
    
    func getActivitySummaryForAI() -> String {
        let totalActivities = activities.count
        let availableActivities = activities.filter { $0.spotsTaken < $0.spotsTotal }.count
        let sportTypes = Set(activities.map { $0.sportType })
        
        return """
        Available Activities Summary:
        - Total activities: \(totalActivities)
        - Available to join: \(availableActivities)
        - Sport types: \(sportTypes.joined(separator: ", "))
        - Most popular: \(getMostPopularSport())
        - Today's activities: \(getTodaysActivities().count)
        """
    }
    
    // MARK: - Private Methods
    
    private func loadMockActivities() {
        activities = [
            Activity(
                id: "1",
                title: "Morning Basketball Game",
                sportType: "Basketball",
                sportIcon: "🏀",
                hostName: "John Doe",
                hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=John",
                date: "Today",
                time: "9:00 AM",
                location: "Downtown Court",
                distance: "2.3 mi",
                spotsTotal: 10,
                spotsTaken: 7,
                level: "Intermediate"
            ),
            Activity(
                id: "2",
                title: "Evening Yoga Session",
                sportType: "Yoga",
                sportIcon: "🧘",
                hostName: "Sarah Johnson",
                hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah",
                date: "Today",
                time: "6:00 PM",
                location: "Zen Studio",
                distance: "1.5 mi",
                spotsTotal: 15,
                spotsTaken: 10,
                level: "Beginner"
            ),
            Activity(
                id: "3",
                title: "Weekend Tennis Match",
                sportType: "Tennis",
                sportIcon: "🎾",
                hostName: "Michael Chen",
                hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Michael",
                date: "Saturday",
                time: "10:00 AM",
                location: "City Tennis Club",
                distance: "3.8 mi",
                spotsTotal: 4,
                spotsTaken: 2,
                level: "Advanced"
            ),
            Activity(
                id: "4",
                title: "Morning Running Group",
                sportType: "Running",
                sportIcon: "🏃",
                hostName: "Emma Davis",
                hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma",
                date: "Tomorrow",
                time: "7:00 AM",
                location: "Central Park",
                distance: "1.2 mi",
                spotsTotal: 8,
                spotsTaken: 3,
                level: "Intermediate"
            ),
            Activity(
                id: "5",
                title: "Cycling Adventure",
                sportType: "Cycling",
                sportIcon: "🚴",
                hostName: "Alex Rodriguez",
                hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
                date: "Sunday",
                time: "8:00 AM",
                location: "Riverside Trail",
                distance: "4.1 mi",
                spotsTotal: 6,
                spotsTaken: 2,
                level: "Advanced"
            )
        ]
        
        print("📱 Loaded \(activities.count) mock activities")
    }
    
    private func addRandomActivity() {
        let sports = [
            ("Swimming", "🏊", "Pool Complex"),
            ("Boxing", "🥊", "Fight Club Gym"),
            ("Soccer", "⚽", "Community Field"),
            ("Volleyball", "🏐", "Beach Courts")
        ]
        
        let levels = ["Beginner", "Intermediate", "Advanced"]
        let times = ["6:00 AM", "7:00 AM", "8:00 AM", "6:00 PM", "7:00 PM"]
        
        let randomSport = sports.randomElement()!
        let randomLevel = levels.randomElement()!
        let randomTime = times.randomElement()!
        
        let newActivity = Activity(
            id: UUID().uuidString,
            title: "\(randomSport.0) Session",
            sportType: randomSport.0,
            sportIcon: randomSport.1,
            hostName: "New User",
            hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=NewUser",
            date: "Tomorrow",
            time: randomTime,
            location: randomSport.2,
            distance: "\(Double.random(in: 1.0...5.0).rounded(toPlaces: 1)) mi",
            spotsTotal: Int.random(in: 4...12),
            spotsTaken: Int.random(in: 1...3),
            level: randomLevel
        )
        
        activities.insert(newActivity, at: 0)
    }
    
    private func getMostPopularSport() -> String {
        let sportCounts = Dictionary(grouping: activities, by: { $0.sportType })
            .mapValues { $0.count }
        return sportCounts.max(by: { $0.value < $1.value })?.key ?? "Basketball"
    }
    
    private func getTodaysActivities() -> [Activity] {
        return activities.filter { $0.date == "Today" }
    }
}

// MARK: - Extensions
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
