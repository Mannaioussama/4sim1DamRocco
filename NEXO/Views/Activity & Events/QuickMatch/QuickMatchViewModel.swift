//
//  QuickMatchViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models used by the UI (kept to avoid view changes)
struct MatchProfile: Identifiable, Equatable {
    // Use backend id so we can call like/pass
    let id: String
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

@MainActor
class QuickMatchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentIndex: Int = 0
    @Published var matchedProfile: MatchProfile?
    @Published var showMatch = false
    @Published var likedCount: Int = 0
    @Published var profiles: [MatchProfile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Pagination
    private var currentPage: Int = 1
    private let limit: Int = 20
    private var hasMorePages: Bool = true

    // MARK: - Dependencies
    private let service: QuickMatchServicing

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
        return currentIndex >= profiles.count && !isLoading && !hasMorePages
    }
    
    // MARK: - Initialization
    
    init(service: QuickMatchServicing = QuickMatchService.shared) {
        self.service = service
        Task { await loadInitial() }
    }

    private func loadInitial() async {
        reset()
        await loadProfiles()
    }
    
    // MARK: - Data Loading
    
    func loadProfiles() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.getProfiles(page: currentPage, limit: limit)
            let mapped = response.profiles.map { self.mapProfile($0) }
            if currentPage == 1 {
                profiles = mapped
                currentIndex = 0
            } else {
                profiles.append(contentsOf: mapped)
            }
            hasMorePages = response.pagination.page < response.pagination.totalPages
            currentPage = response.pagination.page + 1
        } catch let api as APIError {
            errorMessage = api.userMessage
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreProfilesIfNeeded() async {
        guard hasMorePages, !isLoading else { return }
        await loadProfiles()
    }
    
    // MARK: - Actions
    
    func handleSwipe(_ direction: SwipeDirection, _ profile: MatchProfile) {
        switch direction {
        case .right:
            likedCount += 1
            Task { await like(profile) }
        case .left:
            Task { await pass(profile) }
        }
        
        // Move to next profile with a slight delay to allow swipe animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3)) {
                self.currentIndex += 1
            }
            if self.currentIndex >= self.profiles.count - 2 {
                Task { await self.loadMoreProfilesIfNeeded() }
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
    
    func reset() {
        currentIndex = 0
        likedCount = 0
        matchedProfile = nil
        showMatch = false
        profiles = []
        currentPage = 1
        hasMorePages = true
        errorMessage = nil
    }
    
    // MARK: - Private Helpers
    
    private func like(_ profile: MatchProfile) async {
        do {
            let resp = try await service.likeProfile(profileId: profile.id)
            // Remove liked profile from the stack
            profiles.removeAll { $0.id == profile.id }
            
            if resp.isMatch, let p = resp.matchedProfile {
                let mapped = mapProfile(p)
                showMatchAnimation(with: mapped)
            }
        } catch let api as APIError {
            errorMessage = api.userMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func pass(_ profile: MatchProfile) async {
        do {
            try await service.passProfile(profileId: profile.id)
            profiles.removeAll { $0.id == profile.id }
        } catch let api as APIError {
            errorMessage = api.userMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func shouldMatch() -> Bool { Bool.random() } // kept for potential A/B logic
    
    private func showMatchAnimation(with profile: MatchProfile) {
        matchedProfile = profile
        withAnimation(.spring()) {
            showMatch = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { self.showMatch = false }
        }
    }
    
    private func mapProfile(_ p: Profile) -> MatchProfile {
        let avatar = p.avatarUrl ?? p.profileImageUrl ?? "https://i.pravatar.cc/400?u=\(p.id)"
        let cover = p.coverImageUrl ?? p.profileImageUrl ?? p.avatarUrl ?? "https://images.unsplash.com/photo-1546483875-ad9014c88eba?w=800&h=600&fit=crop"
        let sportsInfo: [SportInfo] = {
            if let sports = p.sports, !sports.isEmpty {
                return sports.map {
                    SportInfo(
                        name: $0.name ?? "Sport",
                        icon: $0.icon ?? "🏃",
                        level: $0.level ?? "Intermediate"
                    )
                }
            } else if let interests = p.sportsInterests {
                return interests.prefix(3).map { SportInfo(name: $0, icon: "🏃", level: "Intermediate") }
            } else {
                return []
            }
        }()
        let interests = p.interests ?? p.sportsInterests ?? []
        return MatchProfile(
            id: p.id,
            name: p.name ?? "Unknown",
            age: p.age ?? 25,
            avatar: avatar,
            coverImage: cover,
            location: p.location ?? "Unknown",
            distance: p.distance ?? "—",
            bio: (p.bio ?? p.about) ?? "",
            sports: sportsInfo,
            interests: interests,
            rating: Double(p.rating ?? 0),
            activitiesJoined: p.activitiesJoined ?? 0
        )
    }
}
