//
//  ProfilePageViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import PhotosUI
import Combine

// MARK: - Data Models
struct UserProfile {
    let name: String
    let bio: String
    let location: String
    var avatar: String
    let stats: UserStats
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
    
    @Published var currentUser: UserProfile
    @Published var selectedTab: Int = 0
    @Published var showSourceSheet: Bool = false
    @Published var showPhotoPicker: Bool = false
    @Published var showFilesPicker: Bool = false
    @Published var pickedUIImage: UIImage? = nil
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    @Published var recentActivities: [Activity] = []
    
    // MARK: - Private Properties
    
    private let imageService = ProfileImageService()
    private let uploader: ProfileImageUploader
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return currentUser.name
    }
    
    var displayBio: String {
        return currentUser.bio
    }
    
    var displayLocation: String {
        return currentUser.location
    }
    
    var displayAvatar: String {
        return currentUser.avatar
    }
    
    var sessionsJoinedText: String {
        return "\(currentUser.stats.sessionsJoined)"
    }
    
    var sessionsHostedText: String {
        return "\(currentUser.stats.sessionsHosted)"
    }
    
    var ratingText: String {
        return "⭐ \(String(format: "%.1f", currentUser.stats.rating))"
    }
    
    var hasAvatar: Bool {
        return pickedUIImage != nil || !currentUser.avatar.isEmpty
    }
    
    var achievements: [AchievementData] {
        return [
            AchievementData(icon: "🏃", title: "Marathon Runner", description: "Completed 5+ running events", color: "3498DB"),
            AchievementData(icon: "🏊", title: "Water Warrior", description: "Joined 10+ swimming sessions", color: "2ECC71"),
            AchievementData(icon: "👥", title: "Social Butterfly", description: "Connected with 25+ athletes", color: "9B59B6"),
            AchievementData(icon: "⭐", title: "Top Host", description: "Hosted 10+ successful events", color: "F39C12"),
            AchievementData(icon: "💪", title: "Consistency King", description: "30-day activity streak", color: "E74C3C"),
            AchievementData(icon: "🎯", title: "Goal Crusher", description: "Achieved 5 personal goals", color: "1ABC9C")
        ]
    }
    
    var skillLevels: [(sport: String, level: String)] {
        return [
            ("Running", "Intermediate"),
            ("Swimming", "Advanced"),
            ("Hiking", "Intermediate")
        ]
    }
    
    var interests: String {
        return "Outdoor activities • Fitness challenges • Meeting new people • Trail running • Open water swimming"
    }
    
    // MARK: - Initialization
    
    init(uploader: ProfileImageUploader = StubProfileImageUploader()) {
        self.uploader = uploader
        self.currentUser = UserProfile(
            name: "Alex Thompson",
            bio: "Fitness enthusiast | Marathon runner | Yoga lover 🧘‍♀️",
            location: "San Francisco, CA",
            avatar: "https://i.pravatar.cc/150?img=33",
            stats: UserStats(
                sessionsJoined: 42,
                sessionsHosted: 15,
                rating: 4.9,
                favoriteSports: ["Running", "Swimming", "Hiking", "Yoga", "Cycling"]
            )
        )
        
        loadRecentActivities()
    }
    
    // MARK: - Data Loading
    
    private func loadRecentActivities() {
        // Mock data - In production, fetch from API
        recentActivities = Array(mockActivities.prefix(5))
    }
    
    func refreshProfile() {
        // TODO: Reload profile data from backend
        print("Refreshing profile data")
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
        // TODO: Update profile on backend
        print("Updating profile: name=\(name ?? ""), bio=\(bio ?? ""), location=\(location ?? "")")
    }
    
    // MARK: - Helper Methods
    
    func getTabTitle(for index: Int) -> String {
        switch index {
        case 0: return "About"
        case 1: return "Activities"
        case 2: return "Medals"
        default: return ""
        }
    }
    
    func isTabSelected(_ index: Int) -> Bool {
        return selectedTab == index
    }
    
    // MARK: - Analytics
    
    func trackProfileView() {
        // TODO: Implement analytics tracking
        print("Profile page viewed")
    }
    
    func trackTabView(_ index: Int) {
        // TODO: Implement analytics tracking
        let tabName = getTabTitle(for: index)
        print("Viewed tab: \(tabName)")
    }
    
    func trackImageUpload() {
        // TODO: Implement analytics tracking
        print("Profile image uploaded")
    }
    
    func trackImageRemoved() {
        // TODO: Implement analytics tracking
        print("Profile image removed")
    }
    
    func trackSettingsOpened() {
        // TODO: Implement analytics tracking
        print("Settings opened from profile")
    }
    
    func trackAchievementsOpened() {
        // TODO: Implement analytics tracking
        print("Achievements opened from profile")
    }
}
