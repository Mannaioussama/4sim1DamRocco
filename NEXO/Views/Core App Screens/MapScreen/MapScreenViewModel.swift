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

class MapScreenViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Configuration
    private let config = MapScreenConfiguration()
    
    // MARK: - Published Properties
    
    @Published var aiSuggestions: [Activity] = []
    @Published var selectedActivity: Activity? = nil
    @Published var viewMode: ViewMode = .map
    @Published var savedActivities: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var isSearching = false
    @Published var searchText = ""
    @Published var selectedRadius: Double = 5000
    @Published var showingFilters = false
    @Published var selectedSportType: String? = nil
    @Published var selectedLevel: String? = nil
    @Published var showingDirectionsAlert = false
    @Published var selectedActivityForDirections: Activity? = nil
    
    // Expose the user's current coordinate so the map can filter by distance
    @Published var userCoordinate: CLLocationCoordinate2D? = nil
    
    // Map properties
    @Published var position: MapCameraPosition
    @Published var currentRegion: MKCoordinateRegion
    @Published var mapReloadToken = UUID()
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var hasCenteredOnUser = false
    @Published private var filters = MapFilters()
    
    // MARK: - Computed Properties
    
    var hasSuggestions: Bool { !aiSuggestions.isEmpty }
    var hasSelectedActivity: Bool { selectedActivity != nil }
    var isMapMode: Bool { viewMode == .map }
    var isListMode: Bool { viewMode == .list }
    var savedActivitiesCount: Int { savedActivities.count }
    
    // UI Configuration - moved from ViewModel to computed properties
    var headerTitle: String { config.headerTitle }
    var headerSubtitle: String { config.headerSubtitle }
    var personalizedTitle: String { config.personalizedTitle }
    var personalizedDescription: String { config.personalizedDescription }
    var whyTheseTitle: String { config.whyTheseTitle }
    var whyTheseDescription: String { config.whyTheseDescription }
    
    // Business logic computed properties
    var activitiesWithCoordinates: [Activity] {
        // This will be populated by ActivityAPIService
        aiSuggestions.filter { $0.hasCoordinates }
    }
    
    var filteredActivities: [Activity] {
        let activities = activitiesWithCoordinates
        
        guard let userCoord = userCoordinate else { return activities }
        
        return activities.filter { activity in
            filters.matches(activity) && activity.isWithinRadius(filters.radius, from: userCoord)
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        // Initialize map properties first
        self.position = .region(
            MKCoordinateRegion(
                center: config.defaultLocation,
                span: config.defaultSpan
            )
        )
        self.currentRegion = MKCoordinateRegion(
            center: config.defaultLocation,
            span: config.defaultSpan
        )
        
        super.init()
        
        setupLocationManager()
        loadSavedActivities()
    }

    // MARK: - Radius Management
    
    /// Updates the search radius (in kilometers) used to filter activities around the user.
    /// Keeps the published `selectedRadius` (meters) and the internal `filters.radius` in sync.
    func setRadiusInKilometers(_ kilometers: Double) {
        let meters = max(kilometers, 0) * 1000
        selectedRadius = meters
        filters.radius = meters
    }
    
    // MARK: - Location Management
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = config.desiredAccuracy
        locationManager.distanceFilter = config.distanceFilter
        
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            let coord = locationManager.location?.coordinate
            userCoordinate = coord
            centerOnUserOnceIfNeeded(using: coord)
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }
    
    // Called by the View onAppear to try centering immediately if possible.
    func handleViewAppeared() {
        if [.authorizedAlways, .authorizedWhenInUse].contains(locationManager.authorizationStatus) {
            let coord = locationManager.location?.coordinate
            userCoordinate = coord
            centerOnUserOnceIfNeeded(using: coord)
        } else if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
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
            return
        }
        
        if (status == .authorizedAlways || status == .authorizedWhenInUse),
           let coord = locationManager.location?.coordinate {
            userCoordinate = coord
            currentRegion = MKCoordinateRegion(center: coord, span: config.defaultSpan)
            position = .region(currentRegion)
        } else {
            position = .userLocation(fallback: .automatic)
        }
    }
    
    func updateRegion(_ region: MKCoordinateRegion) {
        currentRegion = region
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            let coord = manager.location?.coordinate
            userCoordinate = coord
            centerOnUserOnceIfNeeded(using: coord)
        case .restricted, .denied:
            break
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    // For completeness with older delegate signature
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            let coord = manager.location?.coordinate
            userCoordinate = coord
            centerOnUserOnceIfNeeded(using: coord)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            userCoordinate = last.coordinate
        }
        centerOnUserOnceIfNeeded(using: locations.last?.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    private func centerOnUserOnceIfNeeded(using coordinate: CLLocationCoordinate2D?) {
        guard !hasCenteredOnUser, let coord = coordinate else { return }
        hasCenteredOnUser = true
        userCoordinate = coord
        currentRegion = MKCoordinateRegion(center: coord, span: config.defaultSpan)
        position = .region(currentRegion)
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
                    level: "Intermediate",
                    visibility: "public"
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
                    level: "All Levels",
                    visibility: "public"
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
                    level: "Beginner",
                    visibility: "public"
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
                    level: "Intermediate",
                    visibility: "public"
                )
            ]
            self?.isLoading = false
        }
    }
    
    private func loadSavedActivities() {
        // Load from persistent storage
        savedActivities = []
    }
    
    // MARK: - View Mode Management
    
    func switchToMapMode() { viewMode = .map }
    func switchToListMode() { viewMode = .list }
    
    // MARK: - Activity Management
    
    func updateActivities(_ activities: [Activity]) {
        aiSuggestions = activities
        // Bump reload token so the Map view rebuilds its annotations when data changes
        mapReloadToken = UUID()
        let withCoords = activities.filter { $0.hasCoordinates }.count
        print("🗺️ [MapScreen] updateActivities: total=\(activities.count), withCoordinates=\(withCoords)")
    }
    
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
            print("Removed activity from saved: \(activityId)")
        } else {
            savedActivities.insert(activityId)
            print("Added activity to saved: \(activityId)")
        }
    }
    
    func isSaved(_ activityId: String) -> Bool {
        savedActivities.contains(activityId)
    }
    
    // MARK: - Actions
    
    func joinActivity(_ activity: Activity) {
        print("Joining activity: \(activity.title)")
    }
    
    func getDirections(to activity: Activity) {
        if let coord = activity.coordinate {
            let placemark = MKPlacemark(coordinate: coord)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = activity.title
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(activity.location) { placemarks, error in
            if let loc = placemarks?.first?.location {
                let placemark = MKPlacemark(coordinate: loc.coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = activity.title
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            } else {
                print("Unable to geocode address for directions: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func refreshSuggestions() {
        loadAISuggestions()
    }
    
    // MARK: - Helper Methods
    
    func getActivity(by id: String) -> Activity? {
        aiSuggestions.first { $0.id == id }
    }
    
    func getSpotsRemaining(for activity: Activity) -> Int {
        activity.spotsTotal - activity.spotsTaken
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
        "\(activity.date) • \(activity.time)"
    }
    
    func getLocationDistanceText(for activity: Activity) -> String {
        "\(activity.location) • \(activity.distance)"
    }
    
    func getDateTimeDistanceText(for activity: Activity) -> String {
        "\(activity.date) • \(activity.time) • \(activity.distance)"
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
        selectedActivity?.id == activity.id
    }
    
    // MARK: - Analytics
    
    func trackViewModeChanged(_ mode: ViewMode) {
        let modeString = mode == .map ? "map" : "list"
        print("View mode changed to: \(modeString)")
    }
    
    func trackActivityView(_ activity: Activity) {
        print("Viewed activity: \(activity.title)")
    }
    
    func trackActivitySelected(_ activity: Activity) {
        print("Selected activity on map: \(activity.title)")
    }
    
    func trackActivityJoin(_ activity: Activity) {
        print("Joined activity: \(activity.title)")
    }
    
    func trackActivitySave(_ activity: Activity) {
        print("Saved activity: \(activity.title)")
    }
    
    func requestDirections(for activity: Activity) {
        selectedActivityForDirections = activity
        showingDirectionsAlert = true
        trackDirectionsRequested(activity)
    }
    
    func openInAppleMaps() {
        guard let activity = selectedActivityForDirections,
              let coordinate = activity.coordinate else { return }
        
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = activity.location
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    func openInGoogleMaps() {
        guard let activity = selectedActivityForDirections,
              let coordinate = activity.coordinate else { return }
        
        let url = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")!
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to web Google Maps
            let webURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)&travelmode=driving")!
            UIApplication.shared.open(webURL)
        }
    }
    
    func trackDirectionsRequested(_ activity: Activity) {
        print("Directions requested for activity: \(activity.title)")
    }
    
    func trackChatRequested(_ activity: Activity) {
        print("Chat requested for activity: \(activity.title)")
    }
    
    func trackZoomIn() { print("Map zoomed in") }
    func trackZoomOut() { print("Map zoomed out") }
    func trackCenterOnUser() { print("Map centered on user") }
}
