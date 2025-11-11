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
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
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
    
    var hasActivities: Bool {
        return !activities.isEmpty
    }
    
    var hasFilteredActivities: Bool {
        return !filteredActivities.isEmpty
    }
    
    var isSearching: Bool {
        return !searchQuery.isEmpty
    }
    
    var isFiltering: Bool {
        return filterSport != "all" || filterDistance != 5
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if filterSport != "all" { count += 1 }
        if filterDistance != 5 { count += 1 }
        return count
    }
    
    var savedActivitiesCount: Int {
        return savedActivities.count
    }
    
    var headerTitle: String {
        return "Discover"
    }
    
    var headerSubtitle: String {
        return "Near You"
    }
    
    // MARK: - Initialization
    
    init() {
        loadActivities()
        loadSportCategories()
        loadSavedActivities()
        setupSearchDebounce()
    }
    
    // MARK: - Data Loading
    
    private func loadActivities() {
        isLoading = true
        
        // Mock data - In production, fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.activities = [
                Activity(
                    id: "1",
                    title: "Morning Basketball Game",
                    sportType: "Basketball",
                    sportIcon: "🏀",
                    hostName: "John Doe",
                    hostAvatar: "https://i.pravatar.cc/150?img=12",
                    date: "Today",
                    time: "9:00 AM",
                    location: "Downtown Court",
                    distance: "2.3 mi",
                    spotsTotal: 10,
                    spotsTaken: 7,
                    level: "Intermediate"
                ),
                Activity(
                    id: "2",
                    title: "Evening Yoga Session",
                    sportType: "Yoga",
                    sportIcon: "🧘",
                    hostName: "Sarah Johnson",
                    hostAvatar: "https://i.pravatar.cc/150?img=9",
                    date: "Today",
                    time: "6:00 PM",
                    location: "Zen Studio",
                    distance: "1.5 mi",
                    spotsTotal: 15,
                    spotsTaken: 10,
                    level: "Beginner"
                ),
                Activity(
                    id: "3",
                    title: "Weekend Tennis Match",
                    sportType: "Tennis",
                    sportIcon: "🎾",
                    hostName: "Michael Chen",
                    hostAvatar: "https://i.pravatar.cc/150?img=15",
                    date: "Saturday",
                    time: "10:00 AM",
                    location: "City Tennis Club",
                    distance: "3.8 mi",
                    spotsTotal: 4,
                    spotsTaken: 2,
                    level: "Advanced"
                )
            ]
            self?.isLoading = false
        }
    }
    
    private func loadSportCategories() {
        // Mock data - In production, fetch from API
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
        // Load from persistent storage
        // In production, fetch from UserDefaults or backend
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
        // In production, this could trigger a server-side search
        print("Searching for: \(query)")
    }
    
    func clearSearch() {
        searchQuery = ""
    }
    
    // MARK: - Filters
    
    func toggleFilters() {
        showFilters.toggle()
    }
    
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
            // TODO: Remove from persistent storage
            print("Removed activity from saved: \(activityId)")
        } else {
            savedActivities.insert(activityId)
            // TODO: Save to persistent storage
            print("Added activity to saved: \(activityId)")
        }
    }
    
    func isSaved(_ activityId: String) -> Bool {
        return savedActivities.contains(activityId)
    }
    
    // MARK: - Actions
    
    func refreshActivities() {
        loadActivities()
    }
    
    func joinActivity(_ activity: Activity) {
        // TODO: Implement join logic
        print("Joining activity: \(activity.title)")
    }
    
    // MARK: - Helper Methods
    
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
    
    // MARK: - Analytics
    
    func trackActivityView(_ activity: Activity) {
        // TODO: Implement analytics tracking
        print("Viewed activity: \(activity.title)")
    }
    
    func trackActivityJoin(_ activity: Activity) {
        // TODO: Implement analytics tracking
        print("Joined activity: \(activity.title)")
    }
    
    func trackActivitySave(_ activity: Activity) {
        // TODO: Implement analytics tracking
        print("Saved activity: \(activity.title)")
    }
    
    func trackSearchPerformed(_ query: String) {
        // TODO: Implement analytics tracking
        print("Search performed: \(query)")
    }
    
    func trackFilterApplied() {
        // TODO: Implement analytics tracking
        print("Filters applied - Sport: \(filterSport), Distance: \(filterDistance)")
    }
}
