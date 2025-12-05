//
//  SearchDiscoveryViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI
import Combine

// MARK: - View Model
class SearchDiscoveryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var searchQuery: String = ""
    @Published var overview: DiscoverOverview?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var selectedCategory: String? = nil
    @Published var featuredCoach: FeaturedCoach?
    
    // MARK: - Private Properties
    
    private var activityService: ActivityAPIService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasSearchText: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Initialization
    
    init(activityService: ActivityAPIService = ActivityAPIService()) {
        self.activityService = activityService
        setupSearchDebounce()
        loadData()
    }
    
    // MARK: - Public Methods
    
    func onCategorySelected(categoryName: String) {
        if selectedCategory == categoryName {
            selectedCategory = nil
        } else {
            selectedCategory = categoryName
        }
        applyFilters()
    }
    
    func onSearchQueryChange(query: String) {
        searchQuery = query
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    private func loadData() {
        isLoading = true
        error = nil
        
        Task { @MainActor in
            do {
                let activities = try await self.fetchActivities()
                let categories = self.createCategories(from: activities)
                let trendingActivities = self.createTrendingActivities(from: activities)
                
                overview = DiscoverOverview(
                    categories: categories,
                    trendingActivities: trendingActivities
                )
                
                // Load static featured coach data
                self.loadFeaturedCoach()
                
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    private func applyFilters() {
        guard let overview = overview else { return }
        
        isLoading = true
        error = nil
        
        Task { @MainActor in
            do {
                // Always fetch fresh activities from database
                let allActivities = try await fetchActivities()
                let filteredActivities = filterActivities(allActivities)
                
                self.overview = DiscoverOverview(
                    categories: overview.categories,
                    trendingActivities: filteredActivities
                )
                
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    private func fetchActivities() async throws -> [Activity] {
        // ActivityAPIService stores activities in a published property
        // We need to fetch them and then access the activities property
        await activityService.fetchAllActivities()
        return activityService.activities
    }
    
    private func filterActivities(_ activities: [Activity]) -> [ExploreActivity] {
        let filtered = activities.filter { activity in
            // Filter by category if selected
            if let category = selectedCategory {
                return activity.sportType.lowercased() == category.lowercased()
            }
            return true
        }
        
        // Also apply search query filter if present
        let searchFiltered = filtered.filter { activity in
            if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                return activity.title.localizedCaseInsensitiveContains(searchQuery) ||
                       activity.sportType.localizedCaseInsensitiveContains(searchQuery) ||
                       activity.location.localizedCaseInsensitiveContains(searchQuery)
            }
            return true
        }
        
        return createTrendingActivities(from: searchFiltered)
    }
    
    private func createCategories(from activities: [Activity]) -> [DiscoverySportCategory] {
        let sportTypes = Set(activities.map { $0.sportType })
        
        return sportTypes.map { sport in
            DiscoverySportCategory(
                name: sport,
                icon: getSportIcon(for: sport),
                color: getSportColor(for: sport)
            )
        }.sorted { $0.name < $1.name }
    }
    
    private func createTrendingActivities(from activities: [Activity]) -> [ExploreActivity] {
        return activities.prefix(10).map { activity in
            ExploreActivity(
                id: activity.id,
                title: activity.title,
                sportIcon: getSportIcon(for: activity.sportType),
                location: activity.location,
                date: activity.date,
                time: activity.time,
                hostName: activity.hostName,
                hostAvatar: activity.hostAvatar,
                participants: activity.spotsTaken,
                maxParticipants: activity.spotsTotal
            )
        }
    }
    
    private func getSportIcon(for sport: String) -> String {
        switch sport.lowercased() {
        case "running": return "🏃"
        case "yoga": return "🧘‍♀️"
        case "cycling": return "🚴‍♀️"
        case "basketball": return "🏀"
        case "tennis": return "🎾"
        case "football": return "⚽️"
        case "swimming": return "🏊‍♀️"
        case "gym": return "💪"
        default: return "🏅"
        }
    }
    
    private func getSportColor(for sport: String) -> Color {
        switch sport.lowercased() {
        case "running": return .green
        case "yoga": return .purple
        case "cycling": return .blue
        case "basketball": return .orange
        case "tennis": return .mint
        case "football": return .gray
        case "swimming": return .cyan
        case "gym": return .red
        default: return .indigo
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func loadFeaturedCoach() {
        // Static featured coach data - for reference when implementing coach features
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
}
