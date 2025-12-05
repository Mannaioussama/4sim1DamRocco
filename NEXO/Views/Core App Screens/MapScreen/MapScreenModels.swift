import Foundation
import SwiftUI
import MapKit
import CoreLocation

// MARK: - Activity Model
struct Activity: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let sportType: String
    let sportIcon: String
    let hostName: String
    let hostAvatar: String
    let creator: ActivityCreator?
    let participantIds: [String]?
    let description: String?
    let date: String
    let time: String
    let location: String
    let distance: String
    let spotsTotal: Int
    let spotsTaken: Int
    let level: String
    let visibility: String
    let latitude: Double?
    let longitude: Double?
    let isPaidSession: Bool
    let price: Double?
    
    // Computed properties
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var spotsLeft: Int {
        spotsTotal - spotsTaken
    }
    
    var hasCoordinates: Bool {
        coordinate != nil
    }
    
    // MARK: - Nested Types
    
    struct ActivityCreator: Codable, Equatable {
        let id: String
        let name: String
        let email: String?
        let profileImageUrl: String?
    }
    
    // MARK: - Initialization
    
    // Custom initializer
    init(
        id: String,
        title: String,
        sportType: String,
        sportIcon: String,
        hostName: String,
        hostAvatar: String,
        date: String,
        time: String,
        location: String,
        distance: String,
        spotsTotal: Int,
        spotsTaken: Int,
        level: String,
        visibility: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        creator: ActivityCreator? = nil,
        participantIds: [String]? = nil,
        isPaidSession: Bool = false,
        price: Double? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.title = title
        self.sportType = sportType
        self.sportIcon = sportIcon
        self.hostName = hostName
        self.hostAvatar = hostAvatar
        self.date = date
        self.time = time
        self.location = location
        self.distance = distance
        self.spotsTotal = spotsTotal
        self.spotsTaken = spotsTaken
        self.level = level
        self.visibility = visibility
        self.latitude = latitude
        self.longitude = longitude
        self.creator = creator
        self.participantIds = participantIds
        self.isPaidSession = isPaidSession
        self.price = price
        self.description = description
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, title, sportType, sportIcon, hostName, hostAvatar
        case date, time, location, distance, spotsTotal, spotsTaken, level, visibility
        case latitude, longitude, creator, participantIds, isPaidSession, price, description
    }
}

// MARK: - Activity Extensions for Business Logic
extension Activity {
    func isWithinRadius(_ radius: Double, from userLocation: CLLocationCoordinate2D) -> Bool {
        guard let coordinate = self.coordinate else { return false }
        
        let userLocationCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let activityLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let distanceInMeters = userLocationCLLocation.distance(from: activityLocation)
        return distanceInMeters <= radius
    }
    
    func distanceFromUser(_ userLocation: CLLocationCoordinate2D) -> Double? {
        guard let coordinate = self.coordinate else { return nil }
        
        let userLocationCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let activityLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return userLocationCLLocation.distance(from: activityLocation)
    }
}

// MARK: - View Mode Enum
enum ViewMode: String, CaseIterable {
    case map = "map"
    case list = "list"
    
    var displayName: String {
        switch self {
        case .map: return "Map"
        case .list: return "List"
        }
    }
}

// MARK: - Map Screen Configuration Model
struct MapScreenConfiguration {
    // UI Text Configuration
    let headerTitle = "Sessions"
    let headerSubtitle = "AI-powered recommendations"
    let personalizedTitle = "Personalized For You"
    let personalizedDescription = "Based on your activity & preferences"
    let whyTheseTitle = "Why these activities?"
    let whyTheseDescription = "We've selected activities matching your skill level, preferred sports, and typical schedule. These are nearby and have availability."
    
    // Map Configuration
    let defaultLocation = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
    let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    let initialSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    let distanceFilter: Double = 10 // meters
    
    // Search Configuration
    let defaultSearchRadius: Double = 5000 // meters
    
    // Location Configuration
    let desiredAccuracy = kCLLocationAccuracyBest
}

// MARK: - Map Filter Model
struct MapFilters {
    var sportType: String?
    var level: String?
    var radius: Double
    
    init(sportType: String? = nil, level: String? = nil, radius: Double = 5000) {
        self.sportType = sportType
        self.level = level
        self.radius = radius
    }
    
    func matches(_ activity: Activity) -> Bool {
        var matches = true
        
        if let sportType = sportType, !sportType.isEmpty {
            matches = matches && activity.sportType.lowercased() == sportType.lowercased()
        }
        
        if let level = level, !level.isEmpty {
            matches = matches && activity.level.lowercased() == level.lowercased()
        }
        
        return matches
    }
}

// MARK: - Directions Request Model
struct DirectionsRequest {
    let activity: Activity
    let userLocation: CLLocationCoordinate2D?
    
    var destinationName: String {
        activity.title
    }
    
    var destinationCoordinate: CLLocationCoordinate2D? {
        activity.coordinate
    }
}
