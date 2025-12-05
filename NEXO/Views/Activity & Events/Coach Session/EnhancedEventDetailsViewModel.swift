//
//  EnhancedEventDetailsViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 5/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct Coach {
    let id: String
    let name: String
    let avatar: String
    let isVerified: Bool
    let rating: Double
    let totalReviews: Int
    let bio: String
    let certifications: [String]
}

struct EventParticipant: Identifiable {
    let id: String
    let name: String
    let avatar: String
}

struct Review: Identifiable {
    let id: String
    let userName: String
    let userAvatar: String
    let rating: Int
    let comment: String
    let date: String
}

struct EnhancedEvent {
    let id: String
    let title: String
    let sportIcon: String
    let sportType: String
    let date: String
    let time: String
    let duration: String
    let location: String
    let distance: String
    let price: Double
    let type: String
    let level: String
    let maxParticipants: Int
    let currentParticipants: Int
    let description: String
    let requirements: [String]
    let coach: Coach
    let latitude: Double?
    let longitude: Double?
}

class EnhancedEventDetailsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isSaved = false
    @Published var selectedTab = "details"
    @Published var event: EnhancedEvent
    @Published var participants: [EventParticipant] = []
    @Published var reviews: [Review] = []
    
    // MARK: - Properties
    
    let eventId: String
    let isCoachView: Bool
    
    // MARK: - Computed Properties
    
    var spotsLeft: Int {
        return event.maxParticipants - event.currentParticipants
    }
    
    var fillPercentage: Double {
        return Double(event.currentParticipants) / Double(event.maxParticipants)
    }
    
    var isAlmostFull: Bool {
        return spotsLeft <= 3
    }
    
    var priceDisplay: String {
        if event.price <= 0 {
            return "Free"
        }
        return String(format: "$%.2f", event.price)
    }
    
    var availabilityText: String {
        return "\(event.currentParticipants)/\(event.maxParticipants) joined"
    }
    
    var spotsLeftText: String {
        return "\(spotsLeft) spots left"
    }
    
    var participantsCountText: String {
        let count = participants.count > 0 ? participants.count : event.currentParticipants
        return "\(count) people are joining this session"
    }
    
    var coachRatingText: String {
        return "\(String(format: "%.1f", event.coach.rating)) (\(event.coach.totalReviews) reviews)"
    }

    var endTimeText: String {
        // Try to interpret event.time as a time and add 1 hour as a simple duration.
        let fmts = ["h:mm a", "HH:mm"]
        for fmt in fmts {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = fmt
            if let date = df.date(from: event.time) {
                if let end = Calendar.current.date(byAdding: .hour, value: 1, to: date) {
                    df.dateFormat = fmt
                    return df.string(from: end)
                }
            }
        }
        return event.time
    }
    
    // MARK: - Initialization
    
    /// Initializes the view model with mock data (legacy/demo mode).
    init(eventId: String, isCoachView: Bool = false) {
        self.eventId = eventId
        self.isCoachView = isCoachView
        
        // Initialize with mock data - In production, this would fetch from API
        self.event = EnhancedEvent(
            id: eventId,
            title: "Morning HIIT Bootcamp",
            sportIcon: "🏃",
            sportType: "HIIT Training",
            date: "Nov 5, 2025",
            time: "7:00 AM",
            duration: "60 min",
            location: "Central Park - Main Field",
            distance: "2.1 mi away",
            price: 25,
            type: "paid",
            level: "Intermediate",
            maxParticipants: 12,
            currentParticipants: 8,
            description: "High-intensity interval training session focused on building strength and endurance. Perfect for all fitness levels with modifications available. Bring water and a workout mat!",
            requirements: ["Yoga mat", "Water bottle", "Athletic shoes"],
            coach: Coach(
                id: "coach_1",
                name: "Alex Thompson",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
                isVerified: true,
                rating: 4.8,
                totalReviews: 124,
                bio: "Certified personal trainer with 8+ years of experience",
                certifications: ["NASM-CPT", "ACE"]
            ),
            latitude: nil,
            longitude: nil
        )
        
        loadParticipants()
        loadReviews()
    }

    /// Initializes the view model from a concrete Activity coming from the backend.
    convenience init(activity: Activity, isCoachView: Bool = false) {
        self.init(eventId: activity.id, isCoachView: isCoachView)
        
        // Map Activity into the richer EnhancedEvent model.
        let priceValue: Double = activity.price ?? (activity.isPaidSession ? 25 : 0)
        let typeValue: String = activity.isPaidSession ? "paid" : "free"
        let participantCount: Int = activity.participantIds?.count ?? activity.spotsTaken
        
        self.event = EnhancedEvent(
            id: activity.id,
            title: activity.title,
            sportIcon: activity.sportIcon,
            sportType: activity.sportType,
            date: activity.date,
            time: activity.time,
            duration: "60 min",
            location: activity.location,
            distance: activity.distance,
            price: priceValue,
            type: typeValue,
            level: activity.level,
            maxParticipants: activity.spotsTotal,
            currentParticipants: participantCount,
            description: activity.description ?? "",
            requirements: [],
            coach: Coach(
                id: activity.creator?.id ?? "coach_unknown",
                name: activity.hostName,
                avatar: activity.hostAvatar,
                isVerified: false,
                rating: 4.8,
                totalReviews: 124,
                bio: "",
                certifications: []
            ),
            latitude: activity.latitude,
            longitude: activity.longitude
        )

        // Populate participants list from the activity's participant IDs when available.
        loadParticipants(from: activity)
    }
    
    // MARK: - Data Loading
    
    private func loadParticipants() {
        // Mock data - In production, fetch from API
        participants = [
            EventParticipant(id: "1", name: "Sarah M.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah"),
            EventParticipant(id: "2", name: "Mike R.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Mike"),
            EventParticipant(id: "3", name: "Emma L.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma"),
            EventParticipant(id: "4", name: "John D.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=John"),
            EventParticipant(id: "5", name: "Lisa K.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Lisa")
        ]
    }

    /// Uses participantIds from a concrete Activity to populate the participants list.
    /// This makes the Participants tab reflect the real users who joined/paid for the session.
    private func loadParticipants(from activity: Activity) {
        guard let ids = activity.participantIds, !ids.isEmpty else {
            // If backend doesn't provide participant IDs yet, fall back to mock data.
            return
        }

        participants = ids.enumerated().map { index, id in
            EventParticipant(
                id: id,
                name: "Participant \(index + 1)",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=\(id)"
            )
        }
    }
    
    private func loadReviews() {
        // Mock data - In production, fetch from API
        reviews = [
            Review(id: "1", userName: "Sarah M.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah", rating: 5, comment: "Excellent workout! Alex is very motivating and adjusts exercises for different levels.", date: "Oct 28, 2025"),
            Review(id: "2", userName: "Mike R.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Mike", rating: 5, comment: "Great session, challenging but fun. Highly recommend!", date: "Oct 25, 2025")
        ]
    }
    
    // MARK: - Actions
    
    func toggleSaved() {
        isSaved.toggle()
        // TODO: Persist save state to backend
        print("Event \(isSaved ? "saved" : "unsaved")")
    }
    
    func selectTab(_ tab: String) {
        selectedTab = tab
    }
    
    func bookEvent() {
        // TODO: Implement booking logic
        print("Booking event: \(event.title)")
    }
    
    func shareEvent() {
        // TODO: Implement share functionality
        print("Sharing event: \(event.title)")
    }
    
    func editEvent() {
        // TODO: Navigate to edit screen
        print("Editing event: \(event.id)")
    }
    
    func manageParticipants() {
        // TODO: Navigate to participant management
        print("Managing participants for event: \(event.id)")
    }
    
    func viewParticipant(_ participantId: String) {
        // TODO: Navigate to participant profile
        print("Viewing participant: \(participantId)")
    }
    
    // MARK: - Helper Methods
    
    func getAvailabilityWarning() -> String? {
        if isAlmostFull {
            return "⚠️ Almost full - book now!"
        }
        return nil
    }
}

