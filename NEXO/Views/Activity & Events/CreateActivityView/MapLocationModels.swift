//
//  MapLocationModels.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Location Model
/// Represents a selected location with all its details
struct MapLocationModel: Identifiable, Codable, Equatable {
    let id: UUID
    let coordinate: Coordinate
    let name: String
    let address: Address?
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        coordinate: Coordinate,
        name: String,
        address: Address? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.address = address
        self.timestamp = timestamp
    }
    
    /// Full display name including address components
    var displayName: String {
        var components = [name]
        
        if let address = address {
            if let street = address.street {
                components.append(street)
            }
            if let city = address.city {
                components.append(city)
            }
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Short display name (just the primary name)
    var shortName: String {
        return name
    }
    
    /// Returns CLLocationCoordinate2D for MapKit usage
    var clCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}

// MARK: - Coordinate Model
/// Codable wrapper for CLLocationCoordinate2D
struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from clCoordinate: CLLocationCoordinate2D) {
        self.latitude = clCoordinate.latitude
        self.longitude = clCoordinate.longitude
    }
    
    /// Convert to CLLocationCoordinate2D
    var clCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Format coordinates for display
    var formatted: String {
        return String(format: "%.4f, %.4f", latitude, longitude)
    }
    
    /// Validate coordinate values
    var isValid: Bool {
        return latitude >= -90 && latitude <= 90 &&
               longitude >= -180 && longitude <= 180
    }
}

// MARK: - Address Model
/// Detailed address components from reverse geocoding
struct Address: Codable, Equatable {
    let street: String?
    let city: String?
    let state: String?
    let country: String?
    let postalCode: String?
    
    init(
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        postalCode: String? = nil
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
    }
    
    /// Create from CLPlacemark
    init?(from placemark: CLPlacemark) {
        let street = placemark.thoroughfare
        let city = placemark.locality
        let state = placemark.administrativeArea
        let country = placemark.country
        let postalCode = placemark.postalCode
        
        // Return nil if no address components available
        guard street != nil || city != nil || state != nil else {
            return nil
        }
        
        self.street = street
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
    }
    
    /// Full address as single string
    var fullAddress: String {
        var components: [String] = []
        
        if let street = street { components.append(street) }
        if let city = city { components.append(city) }
        if let state = state { components.append(state) }
        if let postalCode = postalCode { components.append(postalCode) }
        if let country = country { components.append(country) }
        
        return components.joined(separator: ", ")
    }
    
    /// Short address (street and city only)
    var shortAddress: String {
        var components: [String] = []
        
        if let street = street { components.append(street) }
        if let city = city { components.append(city) }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Recent Location Model
/// Model for storing and managing recent location history
struct RecentLocation: Identifiable, Codable, Equatable {
    let id: UUID
    let location: MapLocationModel
    let usageCount: Int
    let lastUsed: Date
    
    init(
        id: UUID = UUID(),
        location: MapLocationModel,
        usageCount: Int = 1,
        lastUsed: Date = Date()
    ) {
        self.id = id
        self.location = location
        self.usageCount = usageCount
        self.lastUsed = lastUsed
    }
    
    /// Create updated version with incremented usage
    func withIncrementedUsage() -> RecentLocation {
        return RecentLocation(
            id: id,
            location: location,
            usageCount: usageCount + 1,
            lastUsed: Date()
        )
    }
}

// MARK: - Map Region Model
/// Model for map region/viewport
struct MapRegion: Equatable {
    let center: Coordinate
    let span: MapSpan
    
    init(center: Coordinate, span: MapSpan) {
        self.center = center
        self.span = span
    }
    
    init(from mkRegion: MKCoordinateRegion) {
        self.center = Coordinate(from: mkRegion.center)
        self.span = MapSpan(
            latitudeDelta: mkRegion.span.latitudeDelta,
            longitudeDelta: mkRegion.span.longitudeDelta
        )
    }
    
    /// Convert to MKCoordinateRegion
    var mkRegion: MKCoordinateRegion {
        return MKCoordinateRegion(
            center: center.clCoordinate,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta,
                longitudeDelta: span.longitudeDelta
            )
        )
    }
}

// MARK: - Map Span Model
/// Model for map zoom level
struct MapSpan: Equatable {
    let latitudeDelta: Double
    let longitudeDelta: Double
    
    /// Zoom in by halving the span
    func zoomedIn() -> MapSpan {
        return MapSpan(
            latitudeDelta: max(latitudeDelta * 0.5, 0.001),
            longitudeDelta: max(longitudeDelta * 0.5, 0.001)
        )
    }
    
    /// Zoom out by doubling the span
    func zoomedOut() -> MapSpan {
        return MapSpan(
            latitudeDelta: min(latitudeDelta * 2.0, 180.0),
            longitudeDelta: min(longitudeDelta * 2.0, 180.0)
        )
    }
}

// MARK: - Location Validation
extension MapLocationModel {
    /// Validate if location is complete and valid
    var isValid: Bool {
        return coordinate.isValid &&
               !name.isEmpty &&
               name != "Unknown Location"
    }
    
    /// Check if location is within a specific region (e.g., Tunisia)
    func isWithinRegion(center: Coordinate, radiusInKm: Double) -> Bool {
        let location1 = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let location2 = CLLocation(
            latitude: center.latitude,
            longitude: center.longitude
        )
        
        let distanceInMeters = location1.distance(from: location2)
        let distanceInKm = distanceInMeters / 1000.0
        
        return distanceInKm <= radiusInKm
    }
}

// MARK: - Default Locations
extension MapLocationModel {
    /// Default location for Tunisia
    static var tunisDefault: MapLocationModel {
        return MapLocationModel(
            coordinate: Coordinate(latitude: 36.8065, longitude: 10.1815),
            name: "Tunis",
            address: Address(
                city: "Tunis",
                state: "Tunis Governorate",
                country: "Tunisia"
            )
        )
    }
    
    /// Unknown/placeholder location
    static var unknown: MapLocationModel {
        return MapLocationModel(
            coordinate: Coordinate(latitude: 0, longitude: 0),
            name: "Unknown Location"
        )
    }
}
