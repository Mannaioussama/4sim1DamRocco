//
//  CoachProfileViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct CoachProfileData {
    let name: String
    let avatar: String
    let isVerified: Bool
    let bio: String
    let rating: Double
    let totalReviews: Int
    let location: String
    let specializations: [String]
    let certifications: [String]
    let experience: String
    let totalSessions: Int
    let followers: Int
}

struct CoachSession: Identifiable {
    let id: String
    let title: String
    let date: String
    let time: String
    let location: String
    let price: Double
    let spotsLeft: Int
    let sportIcon: String
}

struct CoachReview: Identifiable {
    let id: String
    let userName: String
    let userAvatar: String
    let rating: Int
    let comment: String
    let date: String
}

class CoachProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var coach: CoachProfileData?
    @Published var upcomingSessions: [CoachSession] = []
    @Published var reviews: [CoachReview] = []
    @Published var isFollowing: Bool = false
    @Published var selectedTab: String = "about"
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    
    let coachId: String
    
    // MARK: - Computed Properties
    
    var verifiedBadgeText: String {
        return "✓ Verified Coach"
    }
    
    var ratingText: String {
        guard let coach = coach else { return "" }
        return String(format: "%.1f", coach.rating)
    }
    
    var reviewsCountText: String {
        guard let coach = coach else { return "" }
        return "(\(coach.totalReviews) reviews)"
    }
    
    var followersText: String {
        guard let coach = coach else { return "" }
        return "\(coach.followers)"
    }
    
    var totalSessionsText: String {
        guard let coach = coach else { return "" }
        return "\(coach.totalSessions)"
    }
    
    var experienceText: String {
        return coach?.experience ?? ""
    }
    
    var followButtonText: String {
        return isFollowing ? "Following" : "Follow"
    }
    
    var hasUpcomingSessions: Bool {
        return !upcomingSessions.isEmpty
    }
    
    var hasReviews: Bool {
        return !reviews.isEmpty
    }
    
    var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        let sum = reviews.reduce(0) { $0 + Double($1.rating) }
        return sum / Double(reviews.count)
    }
    
    // MARK: - Initialization
    
    init(coachId: String) {
        self.coachId = coachId
        loadCoachProfile()
        loadUpcomingSessions()
        loadReviews()
        checkFollowingStatus()
    }
    
    // MARK: - Data Loading
    
    private func loadCoachProfile() {
        isLoading = true
        
        // Mock data - In production, fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.coach = CoachProfileData(
                name: "Alex Thompson",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
                isVerified: true,
                bio: "Certified personal trainer with 8+ years of experience. Specialized in HIIT, strength training, and functional fitness.",
                rating: 4.8,
                totalReviews: 124,
                location: "Los Angeles, CA",
                specializations: ["HIIT", "Strength Training", "Yoga", "Running"],
                certifications: ["NASM-CPT", "ACE", "Yoga Alliance RYT-200"],
                experience: "8 years",
                totalSessions: 450,
                followers: 1234
            )
            self?.isLoading = false
        }
    }
    
    private func loadUpcomingSessions() {
        // Mock data - In production, fetch from API
        upcomingSessions = [
            CoachSession(id: "1", title: "Morning HIIT Bootcamp", date: "Nov 5, 2025", time: "7:00 AM", location: "Central Park", price: 25, spotsLeft: 4, sportIcon: "🏃"),
            CoachSession(id: "2", title: "Yoga & Meditation", date: "Nov 6, 2025", time: "6:00 PM", location: "Zen Studio", price: 20, spotsLeft: 5, sportIcon: "🧘"),
            CoachSession(id: "3", title: "Strength & Conditioning", date: "Nov 7, 2025", time: "5:30 PM", location: "FitHub Gym", price: 30, spotsLeft: 2, sportIcon: "💪")
        ]
    }
    
    private func loadReviews() {
        // Mock data - In production, fetch from API
        reviews = [
            CoachReview(id: "1", userName: "Sarah M.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah", rating: 5, comment: "Alex is an amazing coach! Motivating, knowledgeable, and really cares about your progress.", date: "Oct 28, 2025"),
            CoachReview(id: "2", userName: "Mike R.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Mike", rating: 5, comment: "Best trainer I've worked with. Great at explaining proper form and technique.", date: "Oct 25, 2025"),
            CoachReview(id: "3", userName: "Emma L.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma", rating: 4, comment: "Really enjoyed the HIIT sessions. Challenging but fun!", date: "Oct 22, 2025")
        ]
    }
    
    private func checkFollowingStatus() {
        // Check if user is already following this coach
        // In production, fetch from API or local storage
        isFollowing = false
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ tab: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedTab = tab
        }
    }
    
    // MARK: - Actions
    
    func toggleFollow() {
        isFollowing.toggle()
        
        // TODO: Persist to backend
        if isFollowing {
            print("Following coach: \(coachId)")
        } else {
            print("Unfollowed coach: \(coachId)")
        }
    }
    
    func bookSession(_ session: CoachSession) {
        // TODO: Implement booking logic
        print("Booking session: \(session.title)")
    }
    
    func shareProfile() {
        // TODO: Implement share functionality
        print("Sharing coach profile: \(coachId)")
    }
    
    func sendMessage() {
        // TODO: Navigate to messaging
        print("Opening message to coach: \(coachId)")
    }
    
    func refreshData() {
        loadCoachProfile()
        loadUpcomingSessions()
        loadReviews()
    }
    
    // MARK: - Helper Methods
    
    func getSessionPriceText(_ session: CoachSession) -> String {
        return "$\(Int(session.price))"
    }
    
    func getSessionSpotsText(_ session: CoachSession) -> String {
        return "\(session.spotsLeft) spots"
    }
    
    func getSessionDateTimeText(_ session: CoachSession) -> String {
        return "\(session.date) • \(session.time)"
    }
    
    func getReviewStarsText(_ review: CoachReview) -> String {
        return String(repeating: "⭐", count: review.rating)
    }
    
    func getTabIndex(_ tab: String) -> Int {
        let tabs = ["about", "sessions", "reviews"]
        return tabs.firstIndex(of: tab) ?? 0
    }
    
    // MARK: - Analytics
    
    func trackProfileView() {
        // TODO: Implement analytics tracking
        print("Viewed coach profile: \(coachId)")
    }
    
    func trackSessionClick(_ session: CoachSession) {
        // TODO: Implement analytics tracking
        print("Clicked session: \(session.title)")
    }
    
    func trackFollowAction() {
        // TODO: Implement analytics tracking
        print("Follow action: \(isFollowing ? "followed" : "unfollowed")")
    }
    
    func trackTabView(_ tab: String) {
        // TODO: Implement analytics tracking
        print("Viewed tab: \(tab)")
    }
}
