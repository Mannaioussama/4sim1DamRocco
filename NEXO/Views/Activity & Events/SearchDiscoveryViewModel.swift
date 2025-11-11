//
//  SearchDiscoveryViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct DiscoverySportCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct DiscoveryActivity: Identifiable {
    let id = UUID()
    let title: String
    let sportIcon: String
    let hostName: String
    let hostAvatar: String
    let distance: String
    let date: String
    let spotsTotal: Int
    let spotsTaken: Int
}

struct DiscoveryUser: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let sport: String
    let distance: String
}

struct FeaturedCoach {
    let name: String
    let avatar: String
    let title: String
    let rating: Double
    let reviewCount: Int
    let sessionCount: Int
    let isVerified: Bool
}

class SearchDiscoveryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var searchText: String = ""
    @Published var sportCategories: [DiscoverySportCategory] = []
    @Published var trendingActivities: [DiscoveryActivity] = []
    @Published var activeUsers: [DiscoveryUser] = []
    @Published var featuredCoach: FeaturedCoach?
    @Published var isSearching: Bool = false
    @Published var searchResults: [DiscoveryActivity] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasSearchText: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var displayedActivities: [DiscoveryActivity] {
        return hasSearchText ? searchResults : Array(trendingActivities.prefix(3))
    }
    
    var coachRatingText: String {
        guard let coach = featuredCoach else { return "" }
        return "⭐ \(String(format: "%.1f", coach.rating)) (\(coach.reviewCount) reviews) • \(coach.sessionCount)+ sessions"
    }
    
    // MARK: - Initialization
    
    init() {
        loadData()
        setupSearchDebounce()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        loadSportCategories()
        loadTrendingActivities()
        loadActiveUsers()
        loadFeaturedCoach()
    }
    
    private func loadSportCategories() {
        // Mock data - In production, fetch from API
        sportCategories = [
            .init(name: "Running", icon: "🏃", color: .green),
            .init(name: "Yoga", icon: "🧘‍♀️", color: .purple),
            .init(name: "Cycling", icon: "🚴‍♀️", color: .blue),
            .init(name: "Basketball", icon: "🏀", color: .orange),
            .init(name: "Tennis", icon: "🎾", color: .mint),
            .init(name: "Football", icon: "⚽️", color: .gray)
        ]
    }
    
    private func loadTrendingActivities() {
        // Mock data - In production, fetch from API
        trendingActivities = [
            .init(title: "Morning Run", sportIcon: "🏃", hostName: "Alex", hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex", distance: "0.5 mi", date: "Nov 4", spotsTotal: 10, spotsTaken: 6),
            .init(title: "Yoga Flow", sportIcon: "🧘‍♀️", hostName: "Emma", hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma", distance: "1.2 mi", date: "Nov 5", spotsTotal: 8, spotsTaken: 5),
            .init(title: "Evening Ride", sportIcon: "🚴‍♀️", hostName: "Tom", hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Tom", distance: "2.1 mi", date: "Nov 6", spotsTotal: 12, spotsTaken: 7)
        ]
    }
    
    private func loadActiveUsers() {
        // Mock data - In production, fetch from API
        activeUsers = [
            .init(name: "Jessica Lee", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Jessica", sport: "Running", distance: "0.3 mi"),
            .init(name: "Tom Harris", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Tom", sport: "Cycling", distance: "0.7 mi"),
            .init(name: "Nina Patel", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Nina", sport: "Yoga", distance: "1.2 mi")
        ]
    }
    
    private func loadFeaturedCoach() {
        // Mock data - In production, fetch from API
        featuredCoach = FeaturedCoach(
            name: "Alex Thompson",
            avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
            title: "Certified HIIT & Strength Trainer",
            rating: 4.8,
            reviewCount: 124,
            sessionCount: 450,
            isVerified: true
        )
    }
    
    // MARK: - Search
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedQuery.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Simulate search - In production, this would be an API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.searchResults = self.trendingActivities.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedQuery) ||
                $0.hostName.localizedCaseInsensitiveContains(trimmedQuery)
            }
            
            self.isSearching = false
        }
    }
    
    // MARK: - Actions
    
    func selectCategory(_ category: DiscoverySportCategory) {
        // TODO: Navigate to category-specific view or filter activities
        print("Selected category: \(category.name)")
    }
    
    func selectActivity(_ activity: DiscoveryActivity) {
        // TODO: Navigate to activity details
        print("Selected activity: \(activity.title)")
    }
    
    func followUser(_ user: DiscoveryUser) {
        // TODO: Implement follow logic
        print("Following user: \(user.name)")
    }
    
    func chatWithUser(_ user: DiscoveryUser) {
        // TODO: Navigate to chat with user
        print("Chatting with user: \(user.name)")
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
    }
    
    func refreshData() {
        loadData()
    }
    
    // MARK: - Helper Methods
    
    func getSpotsRemaining(for activity: DiscoveryActivity) -> Int {
        return activity.spotsTotal - activity.spotsTaken
    }
    
    func getSpotsText(for activity: DiscoveryActivity) -> String {
        let remaining = getSpotsRemaining(for: activity)
        return "\(remaining) spot\(remaining == 1 ? "" : "s")"
    }
    
    func getUserActivityText(for user: DiscoveryUser) -> String {
        return "\(user.sport) • \(user.distance) away"
    }
}
