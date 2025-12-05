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
    private let activityService = ActivityAPIService()
    private let authTokenManager = AuthTokenManager.shared
    private let followService = FollowService()
    private let reviewsService = ReviewsService()
    
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
    
    /// Whether the follow button should be visible.
    /// Hidden when the current user is the same as the coach.
    var shouldShowFollowButton: Bool {
        guard let currentUserId = authTokenManager.getUserId() else { return true }
        return currentUserId != coachId
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
        loadDataFromAPI()
        loadReviews()
        checkFollowingStatus()
    }
    
    // MARK: - Data Loading
    
    /// Loads coach header info and upcoming sessions by filtering activities for this coach.
    private func loadDataFromAPI() {
        isLoading = true
        
        Task {
            await activityService.fetchAllActivities()
            await MainActor.run { [weak self] in
                guard let self else { return }
                let all = self.activityService.activities
                let coachActivities = all.filter { $0.creator?.id == self.coachId }
                
                // Build coach profile header from the first activity, if available.
                if let first = coachActivities.first {
                    self.coach = CoachProfileData(
                        name: first.hostName,
                        avatar: first.hostAvatar,
                        isVerified: true,
                        bio: first.description ?? "", // fallback: description of one of the sessions
                        rating: 4.8,
                        totalReviews: 124,
                        location: first.location,
                        specializations: [],
                        certifications: [],
                        experience: "",
                        totalSessions: coachActivities.count,
                        followers: 0
                    )
                }
                
                // Sessions tab: show coach activities that still have available spots.
                let availableSessions = coachActivities.filter { $0.spotsTaken < $0.spotsTotal }
                self.upcomingSessions = availableSessions.map { activity in
                    CoachSession(
                        id: activity.id,
                        title: activity.title,
                        date: activity.date,
                        time: activity.time,
                        location: activity.location,
                        price: activity.price ?? 0,
                        spotsLeft: activity.spotsTotal - activity.spotsTaken,
                        sportIcon: activity.sportIcon
                    )
                }
                
                self.isLoading = false
            }
        }
    }
    
    private func loadReviews() {
        // For now, backend returns reviews for the authenticated coach.
        // Only load when viewing own coach profile.
        guard let currentUserId = authTokenManager.getUserId(), currentUserId == coachId else {
            return
        }

        Task {
            do {
                let response = try await reviewsService.getCoachReviews(limit: 50)

                let mapped: [CoachReview] = response.reviews.map { review in
                    CoachReview(
                        id: review.id,
                        userName: review.userName,
                        userAvatar: review.userAvatar ?? "",
                        rating: review.rating,
                        comment: review.comment ?? "",
                        date: review.createdAt
                    )
                }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.reviews = mapped

                    // Update coach header rating/totalReviews if we already have a coach loaded
                    if let existingCoach = self.coach {
                        self.coach = CoachProfileData(
                            name: existingCoach.name,
                            avatar: existingCoach.avatar,
                            isVerified: existingCoach.isVerified,
                            bio: existingCoach.bio,
                            rating: response.averageRating,
                            totalReviews: response.totalReviews,
                            location: existingCoach.location,
                            specializations: existingCoach.specializations,
                            certifications: existingCoach.certifications,
                            experience: existingCoach.experience,
                            totalSessions: existingCoach.totalSessions,
                            followers: existingCoach.followers
                        )
                    }
                }
            } catch {
                #if DEBUG
                print("⚠️ Failed to load coach reviews: \(error)")
                #endif
            }
        }
    }
    
    private func checkFollowingStatus() {
        guard let token = authTokenManager.getToken() else { return }
        
        Task {
            do {
                let response = try await followService.isFollowing(token: token, userId: coachId)
                await MainActor.run {
                    self.isFollowing = response.isFollowing
                }
            } catch {
                #if DEBUG
                print("⚠️ Failed to load follow status: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ tab: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedTab = tab
        }
    }
    
    // MARK: - Actions
    
    func toggleFollow() {
        Task {
            await toggleFollowInternal()
        }
    }
    
    private func toggleFollowInternal() async {
        guard let token = authTokenManager.getToken() else { return }
        
        let currentlyFollowing = isFollowing
        do {
            if currentlyFollowing {
                _ = try await followService.unfollowUser(token: token, userId: coachId)
                await MainActor.run { self.isFollowing = false }
            } else {
                _ = try await followService.followUser(token: token, userId: coachId)
                await MainActor.run { self.isFollowing = true }
            }
        } catch {
            #if DEBUG
            print("⚠️ Follow/unfollow failed: \(error)")
            #endif
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
        loadDataFromAPI()
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
