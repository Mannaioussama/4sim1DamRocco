//
//  ActivityAPIService.swift
//  NEXO
//
//  Created by ROCCO 4X on 13/11/2025.
//

import Foundation
import Combine

// MARK: - API Models (matching your backend schema)
struct APIActivity: Codable, Identifiable {
    let _id: String
    let creator: APICreator
    let sportType: String
    let title: String
    let description: String?
    let location: String
    let latitude: Double?
    let longitude: Double?
    let date: String
    let time: String
    let participants: Int
    let level: String
    let visibility: String
    let createdAt: String?
    let updatedAt: String?
    
    var id: String { _id }
}

struct APICreator: Codable {
    let _id: String
    let name: String?
    let email: String?
    let profileImageUrl: String?
}

struct CreateActivityRequest: Codable {
    let sportType: String
    let title: String
    let description: String?
    let location: String
    let latitude: Double?
    let longitude: Double?
    let date: String
    let time: String
    let participants: Int
    let level: String
    let visibility: String
}

struct APIResponse<T: Codable>: Codable {
    let data: T?
    let message: String?
    let error: String?
}

class ActivityAPIService: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var userActivities: [Activity] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task { await loadFallbackData() }
    }
    
    // MARK: - API Endpoints
    private var baseURL: URL { APIConfig.baseURL }
    private func activitiesEndpoint() -> URL { APIConfig.endpoint("activities") }
    private func myActivitiesEndpoint() -> URL { APIConfig.endpoint("activities/my-activities") }
    private func activityEndpoint(id: String) -> URL { APIConfig.endpoint("activities/\(id)") }
    
    // MARK: - Authentication
    // IMPORTANT: We read the token from AuthTokenManager, which AuthStore now mirrors into on login/register.
    private func getAuthToken() -> String? { AuthTokenManager.shared.getToken() }
    
    private func createAuthHeaders() -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        if let token = getAuthToken() {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    // MARK: - Public Methods
    
    func fetchAllActivities() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            var request = URLRequest(url: activitiesEndpoint())
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            if http.statusCode == 200 {
                let apiActivities = try JSONDecoder().decode([APIActivity].self, from: data)
                let converted = apiActivities.map { convertToActivity($0) }
                await MainActor.run {
                    self.activities = converted
                    self.isLoading = false
                }
            } else {
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch activities: \(error.localizedDescription)"
                self.isLoading = false
            }
            await loadFallbackData()
        }
    }
    
    func fetchMyActivities() async {
        guard getAuthToken() != nil else { return }
        await MainActor.run { self.isLoading = true }
        
        do {
            var request = URLRequest(url: myActivitiesEndpoint())
            request.httpMethod = "GET"
            createAuthHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            if http.statusCode == 200 {
                let apiActivities = try JSONDecoder().decode([APIActivity].self, from: data)
                let converted = apiActivities.map { convertToActivity($0) }
                await MainActor.run {
                    self.userActivities = converted
                    self.isLoading = false
                }
            } else {
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
                throw APIError(statusCode: http.statusCode, message: "Failed to fetch user activities")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch user activities: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func createActivity(
        title: String,
        sportType: String,
        description: String?,
        location: String,
        date: String,
        time: String,
        participants: Int,
        level: String,
        visibility: String = "public",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async -> Bool {
        guard getAuthToken() != nil else {
            await MainActor.run { self.error = "Authentication required to create activities" }
            return false
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Normalize sport type to backend-accepted set if needed
            let validSportTypes = ["Football", "Basketball", "Running", "Cycling"]
            let backendSportType = validSportTypes.contains(sportType) ? sportType : "Football"
            
            // Convert both date and time to ISO strings (backend returns both as ISO)
            let isoDate = convertToISODateOnly(date: date)           // yyyy-MM-dd -> yyyy-MM-dd'T'00:00:00.000Z
            let isoTime = convertToISODateTime(date: date, time: time) // date+time -> yyyy-MM-dd'T'HH:mm:ss.SSS'Z'
            
            let createRequest = CreateActivityRequest(
                sportType: backendSportType,
                title: title,
                description: description,
                location: location,
                latitude: latitude,
                longitude: longitude,
                date: isoDate,
                time: isoTime,
                participants: participants,
                level: level,
                visibility: visibility
            )
            
            var request = URLRequest(url: activitiesEndpoint())
            request.httpMethod = "POST"
            createAuthHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            let body = try JSONEncoder().encode(createRequest)
            request.httpBody = body
            
            // Debug: print outgoing JSON
            if let json = String(data: body, encoding: .utf8) {
                print("📤 Create Activity Request JSON: \(json)")
            }
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            
            if http.statusCode == 201 {
                await MainActor.run { self.isLoading = false }
                // Refresh after creation so Home updates
                await fetchAllActivities()
                await fetchMyActivities()
                return true
            } else {
                // Debug: print server response
                let responseString = String(data: data, encoding: .utf8) ?? "<no body>"
                print("❌ Create Activity failed: status=\(http.statusCode), body=\(responseString)")
                
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError(statusCode: http.statusCode, message: msg)
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.error = error.localizedDescription
            }
            return false
        }
    }
    
    func deleteActivity(id: String) async -> Bool {
        guard getAuthToken() != nil else {
            await MainActor.run { self.error = "Authentication required to delete activities" }
            return false
        }
        
        do {
            var request = URLRequest(url: activityEndpoint(id: id))
            request.httpMethod = "DELETE"
            createAuthHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            
            if http.statusCode == 200 {
                await fetchAllActivities()
                await fetchMyActivities()
                return true
            } else {
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
                throw APIError(statusCode: http.statusCode, message: "Failed to delete activity")
            }
        } catch {
            await MainActor.run { self.error = "Failed to delete activity: \(error.localizedDescription)" }
            return false
        }
    }
    
    // MARK: - AI Coach Integration (unchanged)
    func getActivitiesForAIRecommendation(
        userSportPreferences: [String] = [],
        userLevel: String = "Intermediate"
    ) -> [Activity] {
        var recommendedActivities = activities
        if !userSportPreferences.isEmpty {
            recommendedActivities = recommendedActivities.filter { userSportPreferences.contains($0.sportType) }
        }
        let compatibleLevels: [String]
        switch userLevel {
        case "Beginner": compatibleLevels = ["Beginner", "Intermediate"]
        case "Intermediate": compatibleLevels = ["Beginner", "Intermediate", "Advanced"]
        case "Advanced": compatibleLevels = ["Intermediate", "Advanced"]
        default: compatibleLevels = ["Beginner", "Intermediate", "Advanced"]
        }
        recommendedActivities = recommendedActivities.filter { compatibleLevels.contains($0.level) }
        return Array(recommendedActivities.prefix(10))
    }
    
    func getActivitySummaryForAI() -> String {
        let total = activities.count
        let sportTypes = Set(activities.map { $0.sportType })
        let todays = activities.filter { $0.date == "Today" }
        return """
        Available Activities Summary:
        - Total activities: \(total)
        - Sport types: \(sportTypes.joined(separator: ", "))
        - Today's activities: \(todays.count)
        - Most popular: \(getMostPopularSport())
        """
    }
    
    // MARK: - Helpers
    private func convertToActivity(_ api: APIActivity) -> Activity {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        let displayDate: String
        let displayTime: String
        
        if let date = df.date(from: api.date) {
            let out = DateFormatter()
            out.dateFormat = "MMM dd"
            displayDate = out.string(from: date)
        } else {
            displayDate = "TBD"
        }
        
        if let t = df.date(from: api.time) {
            let out = DateFormatter()
            out.dateFormat = "h:mm a"
            displayTime = out.string(from: t)
        } else {
            displayTime = "TBD"
        }
        
        let icon: String
        switch api.sportType {
        case "Football": icon = "⚽"
        case "Basketball": icon = "🏀"
        case "Running": icon = "🏃"
        case "Cycling": icon = "🚴"
        default: icon = "🏃"
        }
        
        let hostName = api.creator.name ?? "Unknown User"
        let hostAvatar = api.creator.profileImageUrl ?? "https://api.dicebear.com/7.x/avataaars/svg?seed=\(hostName)"
        
        return Activity(
            id: api._id,
            title: api.title,
            sportType: api.sportType,
            sportIcon: icon,
            hostName: hostName,
            hostAvatar: hostAvatar,
            date: displayDate,
            time: displayTime,
            location: api.location,
            distance: "0.0 mi",
            spotsTotal: api.participants,
            spotsTaken: 1,
            level: api.level
        )
    }
    
    private func convertToISODateOnly(date: String) -> String {
        // Expecting input like "yyyy-MM-dd" from the form; fallback to a safe ISO with midnight if unknown
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        iso.timeZone = TimeZone(abbreviation: "UTC")
        
        if let d = df.date(from: date) {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: d)
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            let final = Calendar.current.date(from: comps) ?? d
            return iso.string(from: final)
        } else {
            return "2000-01-01T00:00:00.000Z"
        }
    }
    
    private func convertToISODateTime(date: String, time: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        iso.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let d = df.date(from: date) else { return "2000-01-01T12:00:00.000Z" }
        var t: Date? = tf.date(from: time)
        if t == nil {
            tf.dateFormat = "HH:mm"
            t = tf.date(from: time)
        }
        guard let tt = t else { return "2000-01-01T12:00:00.000Z" }
        
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: d)
        let tcomp = Calendar.current.dateComponents([.hour, .minute], from: tt)
        comp.hour = tcomp.hour
        comp.minute = tcomp.minute
        comp.second = 0
        let final = Calendar.current.date(from: comp) ?? d
        return iso.string(from: final)
    }
    
    private func getMostPopularSport() -> String {
        let counts = Dictionary(grouping: activities, by: { $0.sportType }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "Football"
    }
    
    private func loadFallbackData() async {
        let mock = [
            createMockActivity(
                id: "mock1",
                title: "Morning Basketball Game",
                sportType: "Basketball",
                hostName: "John Doe",
                date: "Today",
                time: "9:00 AM",
                location: "Downtown Court",
                participants: 10,
                level: "Intermediate"
            ),
            createMockActivity(
                id: "mock2",
                title: "Evening Yoga Session",
                sportType: "Yoga",
                hostName: "Sarah Johnson",
                date: "Today",
                time: "6:00 PM",
                location: "Zen Studio",
                participants: 15,
                level: "Beginner"
            ),
            createMockActivity(
                id: "mock3",
                title: "Weekend Tennis Match",
                sportType: "Tennis",
                hostName: "Michael Chen",
                date: "Saturday",
                time: "10:00 AM",
                location: "City Tennis Club",
                participants: 4,
                level: "Advanced"
            )
        ]
        await MainActor.run { self.activities = mock }
    }
    
    private func createMockActivity(
        id: String,
        title: String,
        sportType: String,
        hostName: String,
        date: String,
        time: String,
        location: String,
        participants: Int,
        level: String
    ) -> Activity {
        let icon: String
        switch sportType {
        case "Basketball": icon = "🏀"
        case "Football": icon = "⚽"
        case "Running": icon = "🏃"
        case "Cycling": icon = "🚴"
        default: icon = "🏃"
        }
        return Activity(
            id: id,
            title: title,
            sportType: sportType,
            sportIcon: icon,
            hostName: hostName,
            hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=\(hostName)",
            date: date,
            time: time,
            location: location,
            distance: "2.3 mi",
            spotsTotal: participants,
            spotsTaken: Int.random(in: 1...max(1, participants - 1)),
            level: level
        )
    }
}

// MARK: - Custom Error Types
enum ActivityAPIError: Error, LocalizedError {
    case invalidResponse
    case noData
    case decodingError
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .noData: return "No data received"
        case .decodingError: return "Failed to decode response"
        case .authenticationRequired: return "Authentication required"
        }
    }
}
