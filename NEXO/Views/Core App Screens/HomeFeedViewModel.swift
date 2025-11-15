//
//  HomeFeedViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

class HomeFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var activities: [Activity] = []
    @Published var sportCategories: [SportCategory] = []
    @Published var searchQuery: String = ""
    @Published var savedActivities: Set<String> = []
    @Published var filterSport: String = "all"
    @Published var filterDistance: Double = 5
    @Published var showFilters: Bool = false
    @Published var isLoading: Bool = false
    @Published var isUserAuthenticated: Bool = false
    @Published var authenticationError: String?
    
    // MARK: - Dependencies
    
    var activityAPIService: ActivityAPIService?
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    private var didBindService = false
    
    // MARK: - Computed Properties
    
    var filteredActivities: [Activity] {
        activities.filter { activity in
            let matchesSearch = searchQuery.isEmpty ||
                activity.title.localizedCaseInsensitiveContains(searchQuery) ||
                activity.sportType.localizedCaseInsensitiveContains(searchQuery)
            let matchesSport = filterSport == "all" || activity.sportType == filterSport
            return matchesSearch && matchesSport
        }
    }
    
    var hasActivities: Bool { !activities.isEmpty }
    var hasFilteredActivities: Bool { !filteredActivities.isEmpty }
    var isSearching: Bool { !searchQuery.isEmpty }
    var isFiltering: Bool { filterSport != "all" || filterDistance != 5 }
    
    var activeFiltersCount: Int {
        var count = 0
        if filterSport != "all" { count += 1 }
        if filterDistance != 5 { count += 1 }
        return count
    }
    
    var savedActivitiesCount: Int { savedActivities.count }
    var headerTitle: String { "Discover" }
    var headerSubtitle: String { "Near You" }
    
    // MARK: - Initialization
    
    init(activityAPIService: ActivityAPIService? = nil) {
        print("🏠 HomeFeedViewModel initializing with API service: \(activityAPIService != nil)")
        self.activityAPIService = activityAPIService
        // Do NOT force a blocking spinner on first load
        self.isLoading = false
        
        // Check user authentication status
        checkAuthenticationStatus()
        
        if let apiService = activityAPIService {
            setupBindings(with: apiService)
        }
        loadSportCategories()
        loadSavedActivities()
        setupSearchDebounce()
        
        // If a service is present, start a fetch in background without forcing full-screen spinner
        if let apiService = activityAPIService {
            Task {
                print("🔄 Fetching public activities from database (non-blocking)…")
                await apiService.fetchAllActivities()
            }
        }
    }
    
    // Inject the shared service after init
    func injectService(_ service: ActivityAPIService) {
        guard activityAPIService !== service else { return }
        self.activityAPIService = service
        if !didBindService {
            setupBindings(with: service)
        }
        Task {
            print("🔄 Injected shared service, refreshing activities (non-blocking)…")
            await service.fetchAllActivities()
            await service.fetchMyActivities()
        }
    }
    
    private func checkAuthenticationStatus() {
        isUserAuthenticated = AuthTokenManager.shared.isAuthenticated()
        if !isUserAuthenticated {
            authenticationError = "Please login to create and sync activities"
            print("⚠️ User not authenticated - limited functionality")
        } else {
            let _ = AuthTokenManager.shared.getCurrentUserInfo()
            print("✅ User authenticated - full functionality available")
            authenticationError = nil
        }
    }
    
    private func setupBindings(with activityAPIService: ActivityAPIService) {
        guard !didBindService else { return }
        didBindService = true
        
        // Activities stream — update list; do NOT force spinner here
        activityAPIService.$activities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] apiActivities in
                guard let self = self else { return }
                self.activities = apiActivities
                // Once we have data, ensure spinner is off
                self.isLoading = false
                print("✅ Updated with \(apiActivities.count) activities from service")
            }
            .store(in: &cancellables)
        
        // Mirror loading state, but only show spinner if we currently have no content
        activityAPIService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self = self else { return }
                if self.activities.isEmpty {
                    // Only show spinner when we have zero items; otherwise keep rendering content
                    self.isLoading = loading
                } else {
                    // Keep showing content; optionally you could add a small inline refresh indicator elsewhere
                    self.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        activityAPIService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    print("❌ Activity API Error: \(error)")
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    private func loadSportCategories() {
        sportCategories = [
            SportCategory(name: "Basketball", icon: "🏀"),
            SportCategory(name: "Tennis", icon: "🎾"),
            SportCategory(name: "Yoga", icon: "🧘"),
            SportCategory(name: "Running", icon: "🏃"),
            SportCategory(name: "Swimming", icon: "🏊"),
            SportCategory(name: "Cycling", icon: "🚴")
        ]
    }
    
    private func loadSavedActivities() {
        savedActivities = []
    }
    
    // MARK: - Search
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ query: String) {
        print("Searching for: \(query)")
    }
    
    func clearSearch() { searchQuery = "" }
    
    // MARK: - Filters
    
    func toggleFilters() { showFilters.toggle() }
    
    func clearFilters() {
        filterSport = "all"
        filterDistance = 5
    }
    
    func applyFilters(sport: String, distance: Double) {
        filterSport = sport
        filterDistance = distance
        showFilters = false
    }
    
    // MARK: - Save/Unsave Activities
    
    func toggleSave(_ activityId: String) {
        if savedActivities.contains(activityId) {
            savedActivities.remove(activityId)
            print("Removed activity from saved: \(activityId)")
        } else {
            savedActivities.insert(activityId)
            print("Added activity to saved: \(activityId)")
        }
    }
    
    func isSaved(_ activityId: String) -> Bool {
        return savedActivities.contains(activityId)
    }
    
    // MARK: - Actions
    
    func refreshActivities() {
        guard let activityAPIService = activityAPIService else {
            print("ℹ️ No API service bound; refresh skipped")
            return
        }
        Task { await activityAPIService.fetchAllActivities() }
    }
    
    func joinActivity(_ activity: Activity) {
        print("✅ Joining activity: \(activity.title)")
    }
    
    func createActivity(
        title: String,
        sportType: String,
        sportIcon: String,
        date: String,
        time: String,
        location: String,
        spotsTotal: Int,
        level: String
    ) async -> Bool {
        print("🏀 Creating activity: \(title)")
        checkAuthenticationStatus()
        
        if let activityAPIService = activityAPIService, isUserAuthenticated {
            let success = await activityAPIService.createActivity(
                title: title,
                sportType: sportType,
                description: nil,
                location: location,
                date: date,
                time: time,
                participants: spotsTotal,
                level: level
            )
            return success
        } else {
            let newActivity = Activity(
                id: UUID().uuidString,
                title: title,
                sportType: sportType,
                sportIcon: sportIcon,
                hostName: "You",
                hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=You",
                date: date,
                time: time,
                location: location,
                distance: "0.0 mi",
                spotsTotal: spotsTotal,
                spotsTaken: 1,
                level: level
            )
            activities.insert(newActivity, at: 0)
            return true
        }
    }
    
    func getUserCreatedActivities() -> [Activity] {
        return activityAPIService?.userActivities ?? []
    }
    
    func loadUserActivities() {
        if let activityAPIService = activityAPIService {
            Task { await activityAPIService.fetchMyActivities() }
        }
    }
    
    func forceRefreshActivities() {
        if let activityAPIService = activityAPIService {
            Task {
                print("🔄 Force refreshing activities…")
                await activityAPIService.fetchAllActivities()
                await activityAPIService.fetchMyActivities()
            }
        } else {
            print("ℹ️ No API service bound; force refresh skipped")
        }
    }
    
    // MARK: - Helpers / Analytics (unchanged)
    
    func getActivity(by id: String) -> Activity? {
        return activities.first { $0.id == id }
    }
    
    func getActivitiesBySport(_ sportType: String) -> [Activity] {
        return activities.filter { $0.sportType == sportType }
    }
    
    func getSavedActivities() -> [Activity] {
        return activities.filter { savedActivities.contains($0.id) }
    }
    
    func getSpotsRemaining(for activity: Activity) -> Int {
        return activity.spotsTotal - activity.spotsTaken
    }
    
    func getSpotsRemainingText(for activity: Activity) -> String {
        let remaining = getSpotsRemaining(for: activity)
        return "\(remaining) of \(activity.spotsTotal) spots remaining"
    }
    
    func getDateTimeText(for activity: Activity) -> String {
        return "\(activity.date) • \(activity.time)"
    }
    
    func getLocationDistanceText(for activity: Activity) -> String {
        return "\(activity.location) • \(activity.distance)"
    }
    
    func getFilterDistanceText() -> String {
        return "\(Int(filterDistance)) miles"
    }
    
    func getFilterSportText() -> String {
        return filterSport == "all" ? "All Sports" : filterSport
    }
    
    func trackActivityView(_ activity: Activity) {
        print("Viewed activity: \(activity.title)")
    }
    
    func trackActivityJoin(_ activity: Activity) {
        print("Joined activity: \(activity.title)")
    }
    
    func trackActivitySave(_ activity: Activity) {
        print("Saved activity: \(activity.title)")
    }
    
    func trackSearchPerformed(_ query: String) {
        print("Search performed: \(query)")
    }
    
    func trackFilterApplied() {
        print("Filters applied - Sport: \(filterSport), Distance: \(filterDistance)")
    }
}

