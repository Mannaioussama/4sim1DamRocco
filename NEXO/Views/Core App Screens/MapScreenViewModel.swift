//
//  MapScreenViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import MapKit
import Combine
import CoreLocation

// MARK: - Enums
enum ViewMode {
    case map
    case list
}

class MapScreenViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var aiSuggestions: [Activity] = []
    @Published var selectedActivity: Activity? = nil
    @Published var viewMode: ViewMode = .map
    @Published var savedActivities: Set<String> = []
    @Published var isLoading: Bool = false
    
    // Map properties
    @Published var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @Published var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasSuggestions: Bool {
        return !aiSuggestions.isEmpty
    }
    
    var hasSelectedActivity: Bool {
        return selectedActivity != nil
    }
    
    var isMapMode: Bool {
        return viewMode == .map
    }
    
    var isListMode: Bool {
        return viewMode == .list
    }
    
    var savedActivitiesCount: Int {
        return savedActivities.count
    }
    
    var headerTitle: String {
        return "Sessions"
    }
    
    var headerSubtitle: String {
        return "AI-powered recommendations"
    }
    
    var personalizedTitle: String {
        return "Personalized For You"
    }
    
    var personalizedDescription: String {
        return "Based on your activity & preferences"
    }
    
    var whyTheseTitle: String {
        return "Why these activities?"
    }
    
    var whyTheseDescription: String {
        return "We've selected activities matching your skill level, preferred sports, and typical schedule. These are nearby and have availability."
    }
    
    // MARK: - Initialization
    
    init() {
        setupLocationManager()
        loadAISuggestions()
        loadSavedActivities()
    }
    
    // MARK: - Location Management
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func zoomIn() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(currentRegion.span.latitudeDelta * 0.5, 0.001),
            longitudeDelta: max(currentRegion.span.longitudeDelta * 0.5, 0.001)
        )
        currentRegion.span = newSpan
        position = .region(currentRegion)
    }
    
    func zoomOut() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentRegion.span.latitudeDelta * 2.0, 180),
            longitudeDelta: min(currentRegion.span.longitudeDelta * 2.0, 180)
        )
        currentRegion.span = newSpan
        position = .region(currentRegion)
    }
    
    func centerOnUser() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        position = .userLocation(fallback: .automatic)
    }
    
    func updateRegion(_ region: MKCoordinateRegion) {
        currentRegion = region
    }
    
    // MARK: - Data Loading
    
    private func loadAISuggestions() {
        isLoading = true
        
        // Mock data - In production, fetch from AI/API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.aiSuggestions = [
                Activity(
                    id: "ai-1",
                    title: "Morning Beach Volleyball Match",
                    sportType: "Volleyball",
                    sportIcon: "🏐",
                    hostName: "Emma Wilson",
                    hostAvatar: "https://i.pravatar.cc/150?img=5",
                    date: "Today",
                    time: "8:00 AM",
                    location: "Santa Monica Beach",
                    distance: "1.2 mi",
                    spotsTotal: 12,
                    spotsTaken: 8,
                    level: "Intermediate"
                ),
                Activity(
                    id: "ai-2",
                    title: "Evening Running Group",
                    sportType: "Running",
                    sportIcon: "🏃",
                    hostName: "Michael Chen",
                    hostAvatar: "https://i.pravatar.cc/150?img=12",
                    date: "Today",
                    time: "6:30 PM",
                    location: "Central Park",
                    distance: "0.8 mi",
                    spotsTotal: 15,
                    spotsTaken: 10,
                    level: "All Levels"
                ),
                Activity(
                    id: "ai-3",
                    title: "Yoga & Meditation Session",
                    sportType: "Yoga",
                    sportIcon: "🧘",
                    hostName: "Sarah Johnson",
                    hostAvatar: "https://i.pravatar.cc/150?img=9",
                    date: "Tomorrow",
                    time: "7:00 AM",
                    location: "Zen Studio",
                    distance: "1.5 mi",
                    spotsTotal: 20,
                    spotsTaken: 15,
                    level: "Beginner"
                ),
                Activity(
                    id: "ai-4",
                    title: "Pickup Basketball Game",
                    sportType: "Basketball",
                    sportIcon: "🏀",
                    hostName: "James Rodriguez",
                    hostAvatar: "https://i.pravatar.cc/150?img=15",
                    date: "Tomorrow",
                    time: "5:00 PM",
                    location: "Downtown Court",
                    distance: "2.1 mi",
                    spotsTotal: 10,
                    spotsTaken: 7,
                    level: "Intermediate"
                )
            ]
            self?.isLoading = false
        }
    }
    
    private func loadSavedActivities() {
        // Load from persistent storage
        // In production, fetch from UserDefaults or backend
        savedActivities = []
    }
    
    // MARK: - View Mode Management
    
    func switchToMapMode() {
        viewMode = .map
    }
    
    func switchToListMode() {
        viewMode = .list
    }
    
    // MARK: - Activity Selection
    
    func selectActivity(_ activity: Activity) {
        withAnimation(.spring(response: 0.3)) {
            selectedActivity = activity
        }
    }
    
    func deselectActivity() {
        withAnimation(.spring(response: 0.3)) {
            selectedActivity = nil
        }
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
    
    func joinActivity(_ activity: Activity) {
        // TODO: Implement join logic
        print("Joining activity: \(activity.title)")
    }
    
    func getDirections(to activity: Activity) {
        // TODO: Implement directions logic
        print("Getting directions to: \(activity.location)")
    }
    
    func refreshSuggestions() {
        loadAISuggestions()
    }
    
    // MARK: - Helper Methods
    
    func getActivity(by id: String) -> Activity? {
        return aiSuggestions.first { $0.id == id }
    }
    
    func getSpotsRemaining(for activity: Activity) -> Int {
        return activity.spotsTotal - activity.spotsTaken
    }
    
    func getSpotsRemainingText(for activity: Activity) -> String {
        let remaining = getSpotsRemaining(for: activity)
        return "\(remaining) of \(activity.spotsTotal) spots remaining"
    }
    
    func getSpotsLeftText(for activity: Activity) -> String {
        let remaining = getSpotsRemaining(for: activity)
        return "\(remaining) spots left"
    }
    
    func getDateTimeText(for activity: Activity) -> String {
        return "\(activity.date) • \(activity.time)"
    }
    
    func getLocationDistanceText(for activity: Activity) -> String {
        return "\(activity.location) • \(activity.distance)"
    }
    
    func getDateTimeDistanceText(for activity: Activity) -> String {
        return "\(activity.date) • \(activity.time) • \(activity.distance)"
    }
    
    func getPinPosition(for index: Int) -> CGPoint {
        let positions: [(CGFloat, CGFloat)] = [
            (0.32, 0.22),
            (0.62, 0.38),
            (0.28, 0.52),
            (0.72, 0.68)
        ]
        let position = positions[index % positions.count]
        return CGPoint(x: position.0, y: position.1)
    }
    
    func isActivitySelected(_ activity: Activity) -> Bool {
        return selectedActivity?.id == activity.id
    }
    
    // MARK: - Analytics
    
    func trackViewModeChanged(_ mode: ViewMode) {
        // TODO: Implement analytics tracking
        let modeString = mode == .map ? "map" : "list"
        print("View mode changed to: \(modeString)")
    }
    
    func trackActivityView(_ activity: Activity) {
        // TODO: Implement analytics tracking
        print("Viewed activity: \(activity.title)")
    }
    
    func trackActivitySelected(_ activity: Activity) {
        // TODO: Implement analytics tracking
        print("Selected activity on map: \(activity.title)")
    }
    
    func trackActivityJoin(_ activity: Activity) {
        // TODO: Implement analytics tracking
        print("Joined activity: \(activity.title)")
    }
    
    func trackActivitySave(_ activity: Activity) {
        // TODO: Implement analytics tracking
        print("Saved activity: \(activity.title)")
    }
    
    func trackZoomIn() {
        // TODO: Implement analytics tracking
        print("Map zoomed in")
    }
    
    func trackZoomOut() {
        // TODO: Implement analytics tracking
        print("Map zoomed out")
    }
    
    func trackCenterOnUser() {
        // TODO: Implement analytics tracking
        print("Map centered on user")
    }
}
