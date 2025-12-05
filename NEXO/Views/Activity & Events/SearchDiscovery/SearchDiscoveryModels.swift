//
//  SearchDiscoveryModels.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI

// MARK: - View Models Data Models

struct DiscoverySportCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct DiscoveryActivity: Identifiable {
    let id = UUID()
    let title: String
    let sportIcon: String
    let hostName: String
    let hostAvatar: String
    let distance: String
    let date: String
    let spotsTotal: Int
    let spotsTaken: Int
}

struct DiscoveryUser: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let sport: String
    let distance: String
}

struct FeaturedCoach {
    let name: String
    let avatar: String
    let title: String
    let rating: Double
    let reviewCount: Int
    let sessionCount: Int
    let isVerified: Bool
}

// MARK: - Business Logic Models

struct DiscoverOverview {
    let categories: [DiscoverySportCategory]
    let trendingActivities: [ExploreActivity]
}

struct ExploreActivity: Identifiable {
    let id: String
    let title: String
    let sportIcon: String
    let location: String
    let date: String
    let time: String
    let hostName: String
    let hostAvatar: String
    let participants: Int
    let maxParticipants: Int
}
