//
//  QuickMatchViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct MatchProfile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let age: Int
    let avatar: String
    let coverImage: String
    let location: String
    let distance: String
    let bio: String
    let sports: [SportInfo]
    let interests: [String]
    let rating: Double
    let activitiesJoined: Int
}

struct SportInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let level: String
}

enum SwipeDirection {
    case left
    case right
}

class QuickMatchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentIndex: Int = 0
    @Published var matchedProfile: MatchProfile?
    @Published var showMatch = false
    @Published var likedCount: Int = 0
    @Published var profiles: [MatchProfile] = []
    
    // MARK: - Computed Properties
    
    var currentProfile: MatchProfile? {
        guard currentIndex < profiles.count else { return nil }
        return profiles[currentIndex]
    }
    
    var nextProfiles: [MatchProfile] {
        let start = currentIndex + 1
        let end = min(start + 2, profiles.count)
        if start >= end { return [] }
        return Array(profiles[start..<end])
    }
    
    var hasMoreProfiles: Bool {
        return currentIndex < profiles.count
    }
    
    var isComplete: Bool {
        return currentIndex >= profiles.count
    }
    
    // MARK: - Initialization
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Data Loading
    
    private func loadProfiles() {
        // Mock data - In production, fetch from API
        profiles = [
            .init(
                name: "Jessica", age: 26,
                avatar: "https://i.pravatar.cc/400?img=45",
                coverImage: "https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800&h=600&fit=crop",
                location: "Downtown", distance: "2.3 mi",
                bio: "Love staying active and meeting new people! Always up for a challenge 🏃‍♀️",
                sports: [
                    .init(name: "Running", icon: "🏃", level: "Intermediate"),
                    .init(name: "Yoga", icon: "🧘", level: "Advanced"),
                    .init(name: "Tennis", icon: "🎾", level: "Beginner")
                ],
                interests: ["Morning workouts", "Trail running", "Wellness"],
                rating: 4.8, activitiesJoined: 34
            ),
            .init(
                name: "Marcus", age: 29,
                avatar: "https://i.pravatar.cc/400?img=12",
                coverImage: "https://images.unsplash.com/photo-1546483875-ad9014c88eba?w=800&h=600&fit=crop",
                location: "West Side", distance: "1.8 mi",
                bio: "Basketball enthusiast and fitness lover. Let's ball! 🏀",
                sports: [
                    .init(name: "Basketball", icon: "🏀", level: "Advanced"),
                    .init(name: "Swimming", icon: "🏊", level: "Intermediate"),
                    .init(name: "Cycling", icon: "🚴", level: "Intermediate")
                ],
                interests: ["Team sports", "Competitive", "Weekend warrior"],
                rating: 4.9, activitiesJoined: 52
            ),
            .init(
                name: "Olivia", age: 24,
                avatar: "https://i.pravatar.cc/400?img=32",
                coverImage: "https://images.unsplash.com/photo-1552196563-55cd4e45efb3?w=800&h=600&fit=crop",
                location: "North Beach", distance: "3.1 mi",
                bio: "Beach volleyball and ocean lover 🌊 Looking for active friends!",
                sports: [
                    .init(name: "Volleyball", icon: "🏐", level: "Advanced"),
                    .init(name: "Surfing", icon: "🏄", level: "Intermediate"),
                    .init(name: "Beach Sports", icon: "⛱️", level: "Intermediate")
                ],
                interests: ["Beach activities", "Social sports", "Outdoor fun"],
                rating: 4.7, activitiesJoined: 28
            ),
            .init(
                name: "David", age: 31,
                avatar: "https://i.pravatar.cc/400?img=15",
                coverImage: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&h=600&fit=crop",
                location: "Central Park", distance: "1.2 mi",
                bio: "Gym rat turned outdoor enthusiast. Always exploring new activities!",
                sports: [
                    .init(name: "Hiking", icon: "🥾", level: "Advanced"),
                    .init(name: "Rock Climbing", icon: "🧗", level: "Intermediate"),
                    .init(name: "CrossFit", icon: "💪", level: "Advanced")
                ],
                interests: ["Adventure", "Strength training", "Nature"],
                rating: 4.9, activitiesJoined: 67
            )
        ]
    }
    
    // MARK: - Actions
    
    func handleSwipe(_ direction: SwipeDirection, _ profile: MatchProfile) {
        if direction == .right {
            likedCount += 1
            
            // Simulate match logic - In production, this would check server response
            if shouldMatch() {
                matchedProfile = profile
                showMatchAnimation()
            }
        }
        
        // Move to next profile
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3)) {
                self.currentIndex += 1
            }
        }
    }
    
    func handleLike() {
        guard let profile = currentProfile else { return }
        handleSwipe(.right, profile)
    }
    
    func handlePass() {
        guard let profile = currentProfile else { return }
        handleSwipe(.left, profile)
    }
    
    func resetMatching() {
        currentIndex = 0
        likedCount = 0
        matchedProfile = nil
        showMatch = false
        loadProfiles()
    }
    
    // MARK: - Private Helpers
    
    private func shouldMatch() -> Bool {
        // Simulate random matching - In production, this would be server logic
        return Bool.random()
    }
    
    private func showMatchAnimation() {
        withAnimation(.spring()) {
            showMatch = true
        }
        
        // Auto-hide match modal after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                self.showMatch = false
            }
        }
    }
    
    // MARK: - Stats & Analytics
    
    func getMatchRate() -> Double {
        guard currentIndex > 0 else { return 0 }
        return Double(likedCount) / Double(currentIndex) * 100
    }
    
    func getProfilesRemaining() -> Int {
        return max(0, profiles.count - currentIndex)
    }
}
