//
//  CreateActivityViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine
import CoreLocation

class CreateActivityViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var showSuccess = false
    @Published var showMapPicker = false
    @Published var sportType = ""
    @Published var title = ""
    @Published var description = ""
    @Published var location = ""
    @Published var locationCoordinate: CLLocationCoordinate2D?
    @Published var date = Date()
    @Published var time = Date()
    @Published var participants = 5.0
    @Published var level = ""
    @Published var visibility = "public"
    
    // MARK: - Constants
    
    let sportCategories = [
        ("⚽️", "Football"),
        ("🏀", "Basketball"),
        ("🏃‍♂️", "Running"),
        ("🚴‍♀️", "Cycling")
    ]
    
    let skillLevels = ["Beginner", "Intermediate", "Advanced"]
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        return !sportType.isEmpty &&
               !title.isEmpty &&
               !location.isEmpty &&
               !level.isEmpty
    }
    
    var participantsCount: Int {
        return Int(participants)
    }
    
    var visibilityDisplayText: String {
        return visibility == "public" ? "Public - Anyone can join" : "Friends Only"
    }
    
    var selectedSportEmoji: String? {
        return sportCategories.first(where: { $0.1 == sportType })?.0
    }
    
    // MARK: - Initialization
    
    init() {
        // Set default values if needed
        self.participants = 5.0
        self.visibility = "public"
    }
    
    // MARK: - Actions
    
    func selectSport(_ sportName: String) {
        self.sportType = sportName
    }
    
    func selectLevel(_ levelName: String) {
        self.level = levelName
    }
    
    func setVisibility(_ type: String) {
        self.visibility = type
    }
    
    func setLocation(name: String, coordinate: CLLocationCoordinate2D) {
        self.location = name
        self.locationCoordinate = coordinate
    }
    
    func createActivity() {
        guard isFormValid else {
            print("Form validation failed")
            return
        }
        
        // TODO: Send data to backend/database
        var activityData: [String: Any] = [
            "sportType": sportType,
            "title": title,
            "description": description,
            "location": location,
            "date": date,
            "time": time,
            "participants": participantsCount,
            "level": level,
            "visibility": visibility
        ]
        
        // Add coordinates if available
        if let coordinate = locationCoordinate {
            activityData["latitude"] = coordinate.latitude
            activityData["longitude"] = coordinate.longitude
        }
        
        print("Creating activity with data: \(activityData)")
        
        // Show success dialog
        showSuccess = true
    }
    
    func resetForm() {
        sportType = ""
        title = ""
        description = ""
        location = ""
        locationCoordinate = nil
        date = Date()
        time = Date()
        participants = 5.0
        level = ""
        visibility = "public"
        showSuccess = false
        showMapPicker = false
    }
    
    // MARK: - Helper Methods
    
    func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func getFormattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
