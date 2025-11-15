//
//  MapLocationPickerViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import Foundation
import CoreLocation
import Combine
import MapKit

class MapLocationPickerViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties (expose Model to View)
    @Published var selectedLocation: MapLocationModel?
    @Published var isLoadingAddress = false
    @Published var mapRegion: MapRegion
    @Published var recentLocations: [RecentLocation] = []
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let defaultLocation = MapLocationModel.tunisDefault
    private let defaultSpan = MapSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    
    // MARK: - Computed Properties
    
    /// Check if location can be confirmed
    var canConfirmLocation: Bool {
        guard let location = selectedLocation else { return false }
        return location.coordinate.isValid && !isLoadingAddress
    }
    
    /// Get selected coordinate for MapKit
    var selectedCoordinate: CLLocationCoordinate2D? {
        return selectedLocation?.clCoordinate
    }
    
    /// Get location display name
    var locationDisplayName: String? {
        return selectedLocation?.displayName
    }
    
    // MARK: - Initialization
    override init() {
        self.mapRegion = MapRegion(
            center: defaultLocation.coordinate,
            span: defaultSpan
        )
        
        super.init()
        setupLocationManager()
        loadRecentLocations()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        // Try to get user location if available
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Public Methods
    
    /// Select a location on the map
    func selectLocation(at coordinate: CLLocationCoordinate2D) {
        // Create temporary location model while geocoding
        let tempLocation = MapLocationModel(
            coordinate: Coordinate(from: coordinate),
            name: "Loading...",
            address: nil
        )
        
        selectedLocation = tempLocation
        updateMapRegion(center: Coordinate(from: coordinate))
        
        // Start reverse geocoding to get full details
        reverseGeocodeLocation(coordinate)
    }
    
    /// Reset map to user's current location
    func resetToUserLocation() {
        if let userLocation = locationManager.location?.coordinate {
            selectLocation(at: userLocation)
        } else {
            // Request location if not available
            locationManager.requestLocation()
        }
    }
    
    /// Zoom in on the map
    func zoomIn() {
        mapRegion = MapRegion(
            center: mapRegion.center,
            span: mapRegion.span.zoomedIn()
        )
    }
    
    /// Zoom out on the map
    func zoomOut() {
        mapRegion = MapRegion(
            center: mapRegion.center,
            span: mapRegion.span.zoomedOut()
        )
    }
    
    /// Save location to recent locations
    func saveToRecent(_ location: MapLocationModel) {
        // Check if location already exists (by exact id)
        if let index = recentLocations.firstIndex(where: { $0.location.id == location.id }) {
            recentLocations[index] = recentLocations[index].withIncrementedUsage()
        } else {
            let recent = RecentLocation(location: location)
            recentLocations.insert(recent, at: 0)
            if recentLocations.count > 10 {
                recentLocations = Array(recentLocations.prefix(10))
            }
        }
        persistRecentLocations()
    }
    
    /// Select from recent locations
    func selectRecentLocation(_ recent: RecentLocation) {
        selectedLocation = recent.location
        updateMapRegion(center: recent.location.coordinate)
    }
    
    // MARK: - Private Methods
    
    private func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D) {
        isLoadingAddress = true
        
        // First try MKLocalSearch for nearest POI/address
        let smallSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: coordinate, span: smallSpan)
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = nil
        request.resultTypes = [.address, .pointOfInterest]
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            if let items = response?.mapItems, !items.isEmpty {
                // Choose the nearest item
                let nearest = items.min { lhs, rhs in
                    let l = lhs.placemark.coordinate
                    let r = rhs.placemark.coordinate
                    let dl = hypot(l.latitude - coordinate.latitude, l.longitude - coordinate.longitude)
                    let dr = hypot(r.latitude - coordinate.latitude, r.longitude - coordinate.longitude)
                    return dl < dr
                }
                if let placemark = nearest?.placemark {
                    DispatchQueue.main.async {
                        self.createLocationModel(from: placemark, coordinate: coordinate)
                        self.isLoadingAddress = false
                    }
                    return
                }
            }
            
            // Fallback: CLGeocoder reverse geocode
            self.reverseGeocodeWithCLGeocoder(coordinate)
        }
    }
    
    private func reverseGeocodeWithCLGeocoder(_ coordinate: CLLocationCoordinate2D) {
        geocoder.cancelGeocode()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoadingAddress = false
                if let placemark = placemarks?.first {
                    self.createLocationModel(from: placemark, coordinate: coordinate)
                } else {
                    // Last-resort: still allow confirming with a readable name
                    self.setDroppedPinName(for: coordinate)
                }
            }
        }
    }
    
    private func createLocationModel(from placemark: CLPlacemark, coordinate: CLLocationCoordinate2D) {
        let name = extractLocationName(from: placemark)
        let address = Address(from: placemark)
        
        let location = MapLocationModel(
            coordinate: Coordinate(from: coordinate),
            name: name,
            address: address
        )
        selectedLocation = location
    }
    
    private func extractLocationName(from placemark: CLPlacemark) -> String {
        // Priority: name > street + number > locality > administrativeArea > country
        if let name = placemark.name, !name.isEmpty { return name }
        if let street = placemark.thoroughfare {
            if let number = placemark.subThoroughfare, !number.isEmpty {
                return "\(number) \(street)"
            }
            return street
        }
        if let city = placemark.locality { return city }
        if let admin = placemark.administrativeArea { return admin }
        if let country = placemark.country { return country }
        return "Dropped Pin"
    }
    
    private func setDroppedPinName(for coordinate: CLLocationCoordinate2D) {
        // Ensure we never block confirmation just because we couldn't resolve a name
        let pretty = String(format: "Dropped Pin (%.4f, %.4f)", coordinate.latitude, coordinate.longitude)
        let location = MapLocationModel(
            coordinate: Coordinate(from: coordinate),
            name: pretty,
            address: nil
        )
        selectedLocation = location
    }
    
    private func updateMapRegion(center: Coordinate) {
        mapRegion = MapRegion(
            center: center,
            span: mapRegion.span
        )
    }
    
    // MARK: - Persistence
    
    private func loadRecentLocations() {
        if let data = UserDefaults.standard.data(forKey: "RecentLocations"),
           let locations = try? JSONDecoder().decode([RecentLocation].self, from: data) {
            recentLocations = locations
        }
    }
    
    private func persistRecentLocations() {
        if let data = try? JSONEncoder().encode(recentLocations) {
            UserDefaults.standard.set(data, forKey: "RecentLocations")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapLocationPickerViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        if selectedLocation == nil {
            updateMapRegion(center: Coordinate(from: location.coordinate))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if CLLocationManager.locationServicesEnabled() {
                manager.requestLocation()
            }
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

