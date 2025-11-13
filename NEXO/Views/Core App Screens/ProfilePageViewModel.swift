//
//  ProfilePageViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import PhotosUI
import Combine

// MARK: - Data Models (UI-only models for the Profile page)
struct ProfileViewData {
    let name: String
    let bio: String
    let location: String
    var avatar: String
    var sportsInterests: [String]
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
    
    @Published var currentUser: ProfileViewData
    @Published var selectedTab: Int = 0
    @Published var showSourceSheet: Bool = false
    @Published var showPhotoPicker: Bool = false
    @Published var showFilesPicker: Bool = false
    @Published var pickedUIImage: UIImage? = nil
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    @Published var recentActivities: [Activity] = []
    
    // MARK: - Dependencies
    
    private let imageService = ProfileImageService()
    private let uploader: ProfileImageUploader
    private let profileAPI = ProfileAPI.shared
    private let tokenStore = KeychainTokenStore.shared
    
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
        [
            AchievementData(icon: "🏃", title: "Marathon Runner", description: "Completed 5+ running events", color: "3498DB"),
            AchievementData(icon: "🏊", title: "Water Warrior", description: "Joined 10+ swimming sessions", color: "2ECC71"),
            AchievementData(icon: "👥", title: "Social Butterfly", description: "Connected with 25+ athletes", color: "9B59B6"),
            AchievementData(icon: "⭐", title: "Top Host", description: "Hosted 10+ successful events", color: "F39C12"),
            AchievementData(icon: "💪", title: "Consistency King", description: "30-day activity streak", color: "E74C3C"),
            AchievementData(icon: "🎯", title: "Goal Crusher", description: "Achieved 5 personal goals", color: "1ABC9C")
        ]
    }
    
    var skillLevels: [(sport: String, level: String)] {
        [
            ("Running", "Intermediate"),
            ("Swimming", "Advanced"),
            ("Hiking", "Intermediate")
        ]
    }
    
    // MARK: - Initialization
    
    init(uploader: ProfileImageUploader = StubProfileImageUploader()) {
        self.uploader = uploader
        self.currentUser = ProfileViewData(
            name: "Alex Thompson",
            bio: "Fitness enthusiast | Marathon runner | Yoga lover 🧘‍♀️",
            location: "San Francisco, CA",
            avatar: "https://i.pravatar.cc/150?img=33",
            sportsInterests: ["Running", "Swimming", "Hiking", "Yoga", "Cycling"],
            stats: UserStats(
                sessionsJoined: 42,
                sessionsHosted: 15,
                rating: 4.9,
                favoriteSports: ["Running", "Swimming", "Hiking", "Yoga", "Cycling"]
            )
        )
        
        setupObservers()
        loadRecentActivities()
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
    
    func loadUserProfile() {
        Task { @MainActor in
            guard let token = tokenStore.getAccessToken() else {
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
    
    private func apply(user: UserProfile) {
        currentUser = ProfileViewData(
            name: user.name,
            bio: user.about ?? "",
            location: user.location,
            avatar: user.profileImageUrl ?? "",
            sportsInterests: user.sportsInterests ?? [],
            stats: UserStats(
                sessionsJoined: 0,
                sessionsHosted: 0,
                rating: 0,
                favoriteSports: user.sportsInterests ?? []
            )
        )
    }
    
    private func loadRecentActivities() {
        // Mock data - In production, fetch from API
        recentActivities = Array(mockActivities.prefix(5))
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

