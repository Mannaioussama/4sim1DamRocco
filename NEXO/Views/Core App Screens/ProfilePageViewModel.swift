//
//  ProfilePageViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import PhotosUI
import Combine
import Foundation
import CoreLocation

// MARK: - Data Models (UI-only models for the Profile page)
struct ProfileViewData {
    let name: String
    let bio: String
    let location: String
    var avatar: String
    var sportsInterests: [String]
    let stats: UserStats
    let isCoachVerified: Bool
}

struct UserStats {
    let sessionsJoined: Int
    let sessionsHosted: Int
    let rating: Double
    let favoriteSports: [String]
}

struct AchievementData {
    let icon: String
    let title: String
    let description: String
    let color: String
}

class ProfilePageViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentUser: ProfileViewData
    @Published var selectedTab: Int = 0
    @Published var showSourceSheet: Bool = false
    @Published var showPhotoPicker: Bool = false
    @Published var showFilesPicker: Bool = false
    @Published var pickedUIImage: UIImage? = nil
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    @Published var recentActivities: [Activity] = []
    @Published private var realAchievements: [AchievementData] = []
    
    // MARK: - Dependencies
    
    private let imageService = ProfileImageService()
    private let uploader: ProfileImageUploader
    private let profileAPI = ProfileAPI.shared
    private let tokenStore = AuthTokenManager.shared
    private let activityAPI = ActivityAPIService()
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasAvatar: Bool {
        pickedUIImage != nil || !currentUser.avatar.isEmpty
    }
    
    var interests: String {
        let tags = currentUser.sportsInterests
        return tags.isEmpty ? "No interests added yet" : tags.joined(separator: " • ")
    }
    
    var achievements: [AchievementData] {
        realAchievements
    }
    
    // MARK: - Initialization
    
    init(uploader: ProfileImageUploader = StubProfileImageUploader()) {
        self.uploader = uploader
        self.currentUser = ProfileViewData(
            name: "",
            bio: "",
            location: "",
            avatar: "",
            sportsInterests: [],
            stats: UserStats(
                sessionsJoined: 0,
                sessionsHosted: 0,
                rating: 0,
                favoriteSports: []
            ),
            isCoachVerified: false
        )
        
        // Fetch user activities when the view model is initialized
        Task {
            await fetchUserActivities()
        }
        
        setupObservers()
        loadAchievements()
    }
    
    // MARK: - Activity Fetching
    
    @MainActor
    private func fetchUserActivities() async {
        print(" Fetching user activities...")
        // Fetch all activities
        await activityAPI.fetchMyActivities()
        
        // Get the current user ID
        guard let userId = tokenStore.getUserId() else {
            print(" User ID not found in token store")
            return
        }
        
        print(" Current user ID: \(userId)")
        print(" Total activities fetched: \(activityAPI.activities.count)")
        
        // Debug: Print all activities and their participant IDs
        for (index, activity) in activityAPI.activities.enumerated() {
            print("\nActivity #\(index + 1):")
            print("  Title: \(activity.title)")
            print("  Creator ID: \(activity.creator?.id ?? "nil")")
            print("  Host Name: \(activity.hostName)")
            print("  Participant IDs: \(activity.participantIds ?? [])")
        }
        
        // Get hosted activities (created by the user)
        let hostedActivities = activityAPI.userActivities.filter { activity in
            let isCreator = activity.creator?.id == userId
            let isHost = activity.hostName.lowercased() == currentUser.name.lowercased()
            return isCreator || isHost
        }
        let hostedCount = hostedActivities.count
        
        // Get joined activities (user is a participant)
        let joinedActivities = activityAPI.userActivities.filter { activity in
            activity.participantIds?.contains(userId) ?? false
        }
        let joinedCount = joinedActivities.count
        
        print(" Hosted activities count: \(hostedCount)")
        print(" Joined activities count: \(joinedCount)")
        
        // Update the current user's stats
        currentUser = ProfileViewData(
            name: currentUser.name,
            bio: currentUser.bio,
            location: currentUser.location,
            avatar: currentUser.avatar,
            sportsInterests: currentUser.sportsInterests,
            stats: UserStats(
                sessionsJoined: joinedCount,
                sessionsHosted: hostedCount,
                rating: currentUser.stats.rating,
                favoriteSports: currentUser.stats.favoriteSports
            ),
            isCoachVerified: currentUser.isCoachVerified
        )
        
        let upcomingHosted = hostedActivities.filter { isOnOrAfterToday($0) }
        recentActivities = upcomingHosted
        
        print(" Updated profile stats - Hosted: \(hostedCount), Joined: \(joinedCount)")
    }
    
    private func setupObservers() {
        // Refresh when edit profile broadcasts an update
        NotificationCenter.default.publisher(for: .profileDidUpdate)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let updated = notification.object as? UserProfile {
                    self.apply(user: updated)
                } else {
                    self.loadUserProfile()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    private func loadUserProfile() {
        Task { @MainActor in
            guard let token = tokenStore.getToken() else {
                print("No access token available")
                return
            }
            do {
                let user = try await profileAPI.getProfile(token: token)
                apply(user: user)
            } catch {
                print("Failed to load profile: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Achievements Loading
    
    private func loadAchievements() {
        Task { @MainActor in
            do {
                let badgesResponse = try await AchievementsAPI.getBadges()
                let earnedBadges = badgesResponse.earnedBadges
                let mapped: [AchievementData] = earnedBadges.map { badge in
                    AchievementData(
                        icon: emoji(for: badge.category),
                        title: badge.name,
                        description: badge.description,
                        color: colorHex(for: badge.rarity)
                    )
                }
                self.realAchievements = mapped
            } catch {
                print("Failed to load profile achievements: \(error.localizedDescription)")
            }
        }
    }
    
    private func emoji(for category: AchievementsAPI.Badge.BadgeCategory) -> String {
        switch category {
        case .streak: return "🔥"
        case .distance: return "🏃"
        case .duration: return "⏱"
        case .sport: return "⚽️"
        case .creation: return "🎯"
        case .completion: return "✅"
        }
    }
    
    private func colorHex(for rarity: AchievementsAPI.Badge.BadgeRarity) -> String {
        switch rarity {
        case .common: return "3498DB"      // blue
        case .uncommon: return "2ECC71"   // green
        case .rare: return "9B59B6"       // purple
        case .epic: return "F39C12"       // orange
        case .legendary: return "E74C3C"  // red
        }
    }
    
    private func isOnOrAfterToday(_ activity: Activity) -> Bool {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        df.locale = Locale.current

        guard let date = df.date(from: activity.date) else {
            return true
        }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        return date >= startOfToday
    }
    
    private func apply(user: UserProfile) {
        // Preserve activity-based stats (joined/hosted/rating) that were computed
        // from the user's activities, and only refresh profile fields from backend.
        let existingStats = currentUser.stats
        currentUser = ProfileViewData(
            name: user.name,
            bio: user.about ?? "",
            location: user.location,
            avatar: user.profileImageUrl ?? "",
            sportsInterests: user.sportsInterests ?? [],
            stats: UserStats(
                sessionsJoined: existingStats.sessionsJoined,
                sessionsHosted: existingStats.sessionsHosted,
                rating: existingStats.rating,
                favoriteSports: user.sportsInterests ?? existingStats.favoriteSports
            ),
            isCoachVerified: user.isCoachVerified ?? currentUser.isCoachVerified
        )
    }
    
    func refreshProfile() {
        loadUserProfile()
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ index: Int) {
        withAnimation(.spring(response: 0.3)) {
            selectedTab = index
        }
    }
    
    // MARK: - Image Picker Management
    
    func openSourcePicker() {
        showSourceSheet = true
    }
    
    func closeSourcePicker() {
        withAnimation(.spring(response: 0.25)) {
            showSourceSheet = false
        }
    }
    
    func openPhotoPicker() {
        showSourceSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.showPhotoPicker = true
        }
    }
    
    func openFilesPicker() {
        showSourceSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.showFilesPicker = true
        }
    }
    
    func removeAvatar() {
        pickedUIImage = nil
        currentUser.avatar = ""
        closeSourcePicker()
    }
    
    // MARK: - Image Upload
    
    func handlePickedImage(_ picked: PickedImage) {
        pickedUIImage = picked.uiImage // show immediately
        
        Task {
            do {
                isUploading = true
                uploadError = nil
                
                let processed = try imageService.processForUpload(picked.uiImage)
                
                // Upload to backend (stub for now)
                let newURL = try await uploader.uploadProfileImage(
                    data: processed,
                    fileName: picked.fileName,
                    mimeType: picked.mimeType
                )
                
                await MainActor.run {
                    currentUser.avatar = newURL.absoluteString
                    isUploading = false
                }
                
                print("Successfully uploaded profile image: \(newURL)")
            } catch {
                await MainActor.run {
                    uploadError = error.localizedDescription
                    isUploading = false
                }
                print("Upload error: \(error)")
            }
        }
    }
    
    // MARK: - Profile Updates
    
    func updateProfile(name: String?, bio: String?, location: String?) {
        // Future: call backend if you allow quick inline edits here.
        print("Updating profile: name=\(name ?? ""), bio=\(bio ?? ""), location=\(location ?? "")")
    }
    
    // MARK: - Analytics
    
    func trackProfileView() {
        print("Profile page viewed")
    }
    
    func trackTabView(_ index: Int) {
        let tabName = ["About", "Activities", "Medals"][min(index, 2)]
        print("Viewed tab: \(tabName)")
    }
    
    func trackImageUpload() {
        print("Profile image uploaded")
    }
    
    func trackImageRemoved() {
        print("Profile image removed")
    }
    
    func trackSettingsOpened() {
        print("Settings opened from profile")
    }
    
    func trackAchievementsOpened() {
        print("Achievements opened from profile")
    }
}

