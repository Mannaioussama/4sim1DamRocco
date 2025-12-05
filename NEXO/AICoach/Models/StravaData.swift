import Foundation

struct StravaActivity: Codable {
    let type: String
    let distance: Int
    let duration: Int
    let averageSpeed: Double?
    let elevationGain: Int?
    let date: String
    
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", Double(distance) / 1000.0)
        } else {
            return "\(distance) m"
        }
    }
    
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedSpeed: String {
        guard let speed = averageSpeed else { return "N/A" }
        let kmh = speed * 3.6
        return String(format: "%.1f km/h", kmh)
    }
}

struct StravaWeeklyStats: Codable {
    let totalDistance: Int
    let totalTime: Int
    let activitiesCount: Int
    
    var formattedTotalDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.2f km", Double(totalDistance) / 1000.0)
        } else {
            return "\(totalDistance) m"
        }
    }
    
    var formattedTotalTime: String {
        let hours = totalTime / 3600
        let minutes = (totalTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StravaData: Codable {
    let recentActivities: [StravaActivity]?
    let weeklyStats: StravaWeeklyStats?
    let favoriteSports: [String]?
    let performanceTrend: String?
}

struct AISuggestionsRequest: Codable {
    let workouts: Int
    let calories: Int
    let minutes: Int
    let streak: Int
    let sportPreferences: String?
    let stravaData: StravaData?
    let location: String?
    let preferredTimeOfDay: String?
}

struct PersonalizedTipsRequest: Codable {
    let workouts: Int
    let calories: Int
    let minutes: Int
    let streak: Int
    let sportPreferences: [String]?
    let recentActivities: [String]?
    let stravaData: String?
}
