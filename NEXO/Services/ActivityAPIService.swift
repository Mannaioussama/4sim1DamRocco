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
    let creator: APICreator?        // Backend sometimes returns null
    let sportType: String
    let title: String
    let description: String?
    let location: String
    let latitude: Double?
    let longitude: Double?
    let date: String
    let time: String
    let participants: Int
    let participantIds: [String]?   // Optional list of participant IDs
    let level: String
    let visibility: String
    let price: Double?              // Optional, only for coach sessions
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
    let price: Double?
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
    private let fallbackEnabled: Bool
    private var activitiesCacheURL: URL {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("activities_cache.json")
    }
    
    // Backend-only by default. Previews/tests can pass fallbackEnabled: true to see mock items.
    init(fallbackEnabled: Bool = false) {
        self.fallbackEnabled = fallbackEnabled
        if fallbackEnabled {
            Task { await loadFallbackData() }
        } else {
            Task { await loadCachedActivities() }
        }
    }
    
    // MARK: - API Endpoints
    private var baseURL: URL { APIConfig.baseURL }
    private func activitiesEndpoint() -> URL { APIConfig.endpoint("activities") }
    private func myActivitiesEndpoint() -> URL { APIConfig.endpoint("activities/my-activities") }
    private func activityEndpoint(id: String) -> URL { APIConfig.endpoint("activities/\(id)") }
    
    // MARK: - Authentication
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
    
    // MARK: - Logging
    private func log(_ message: String) {
        print("🌐 [ActivityAPI] \(message)")
    }
    
    // MARK: - Public Methods
    
    func fetchAllActivities() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            var components = URLComponents(url: activitiesEndpoint(), resolvingAgainstBaseURL: false)!
            // Uncomment if you want to restrict to public
            // components.queryItems = [URLQueryItem(name: "visibility", value: "public")]
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            createAuthHeaders().forEach { header, value in
                request.setValue(value, forHTTPHeaderField: header)
            }
            
            log("GET \(request.url?.absoluteString ?? "")")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            log("Status \(http.statusCode) for /activities")
            
            if http.statusCode == 200 {
                let decoder = JSONDecoder()
                let apiActivities: [APIActivity]
                if let direct = try? decoder.decode([APIActivity].self, from: data) {
                    apiActivities = direct
                } else if
                    let wrapped = try? decoder.decode(APIResponse<[APIActivity]>.self, from: data),
                    let wrappedData = wrapped.data {
                    apiActivities = wrappedData
                } else {
                    if let raw = String(data: data, encoding: .utf8) {
                        log("Decoding failed. Raw response:\n\(raw)")
                    }
                    throw ActivityAPIError.decodingError
                }
                let converted = apiActivities.map { convertToActivity($0) }
                saveActivitiesToCache(converted)
                await MainActor.run {
                    self.activities = converted
                    self.isLoading = false
                }
            } else {
                if let raw = String(data: data, encoding: .utf8) {
                    log("Non-200 response body:\n\(raw)")
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
                throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch activities: \(error.localizedDescription)"
                self.isLoading = false
            }
            if fallbackEnabled {
                await loadFallbackData()
            }
        }
    }
    
    func fetchMyActivities() async {
        guard let token = getAuthToken() else {
            print("❌ No auth token found")
            return 
        }
        
        print("🔑 Using auth token: \(token.prefix(10))...")
        
        await MainActor.run { self.isLoading = true }
        
        do {
            let url = myActivitiesEndpoint()
            print("🌐 Fetching activities from: \(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let headers = createAuthHeaders()
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            log("GET \(url.absoluteString)")
            print("Headers: \(headers)")
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { 
                print("❌ Invalid response type")
                throw ActivityAPIError.invalidResponse 
            }
            
            log("Status \(http.statusCode) for /activities/my-activities")
            print("Response status code: \(http.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Raw response: \(responseString.prefix(1000))...") // Print first 1000 chars
            }
            
            if http.statusCode == 200 {
                let decoder = JSONDecoder()
                let apiActivities: [APIActivity]
                
                // First try direct array decode
                if let direct = try? decoder.decode([APIActivity].self, from: data) {
                    apiActivities = direct
                    print("✅ Successfully decoded \(direct.count) user activities directly")
                } 
                // Then try wrapped in APIResponse
                else if let wrapped = try? decoder.decode(APIResponse<[APIActivity]>.self, from: data),
                          let wrappedData = wrapped.data {
                    apiActivities = wrappedData
                    print("✅ Successfully decoded \(wrappedData.count) user activities from wrapped response")
                } 
                // If both fail, log the error
                else {
                    if let raw = String(data: data, encoding: .utf8) {
                        log("❌ Decoding failed for my-activities. Raw response:\n\(raw)")
                        print("❌ Failed to decode user activities. Raw response: \(raw.prefix(500))...")
                    }
                    throw ActivityAPIError.decodingError
                }
                
                let converted = apiActivities.map { convertToActivity($0) }
                print("🔄 Converted \(converted.count) user activities to local model")
                
                await MainActor.run {
                    self.userActivities = converted
                    self.isLoading = false
                }
            } else {
                if let raw = String(data: data, encoding: .utf8) {
                    log("Non-200 response body:\n\(raw)")
                }
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
    
    // Backend search: fetch all, then filter locally by query/sport (compatible with your guide)
    func searchActivities(query: String, sport: String? = nil, distanceMiles: Double? = nil) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await fetchAllActivities()
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            var components = URLComponents(url: activitiesEndpoint(), resolvingAgainstBaseURL: false)!
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            createAuthHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            log("GET \(request.url?.absoluteString ?? "") [search locally]")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            log("Status \(http.statusCode) for /activities (search)")
            
            if http.statusCode == 200 {
                let decoder = JSONDecoder()
                let apiActivities: [APIActivity]
                if let direct = try? decoder.decode([APIActivity].self, from: data) {
                    apiActivities = direct
                } else if let wrapped = try? decoder.decode(APIResponse<[APIActivity]>.self, from: data),
                          let wrappedData = wrapped.data {
                    apiActivities = wrappedData
                } else {
                    if let raw = String(data: data, encoding: .utf8) {
                        log("Decoding failed. Raw response:\n\(raw)")
                    }
                    throw ActivityAPIError.decodingError
                }
                
                // Convert then filter locally
                let allConverted = apiActivities.map { convertToActivity($0) }
                let q = trimmed.lowercased()
                let filtered = allConverted.filter { a in
                    let matchesQuery =
                        a.title.lowercased().contains(q) ||
                        a.sportType.lowercased().contains(q) ||
                        a.location.lowercased().contains(q) ||
                        a.hostName.lowercased().contains(q)
                    let matchesSport = (sport == nil || sport == "all") ? true : (a.sportType == sport)
                    return matchesQuery && matchesSport
                }
                
                await MainActor.run {
                    self.activities = filtered
                    self.isLoading = false
                }
            } else {
                if let raw = String(data: data, encoding: .utf8) {
                    log("Non-200 response body:\n\(raw)")
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError(statusCode: http.statusCode, message: msg)
            }
        } catch {
            await MainActor.run {
                self.error = "Search failed: \(error.localizedDescription)"
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
        longitude: Double? = nil,
        price: Double? = nil
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
            
            // Convert both date and time to ISO strings (backend expects: date yyyy-MM-dd, time ISO 8601)
            let isoDate = convertToISODateOnly(date: date)
            let isoTime = convertToISODateTime(date: date, time: time)
            
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
                visibility: visibility,
                price: price
            )
            
            var request = URLRequest(url: activitiesEndpoint())
            request.httpMethod = "POST"
            createAuthHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            let body = try JSONEncoder().encode(createRequest)
            request.httpBody = body
            
            if let json = String(data: body, encoding: .utf8) {
                log("📤 Create Activity Request JSON: \(json)")
            }
            
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            
            log("Status \(http.statusCode) for POST /activities")
            if http.statusCode == 201 {
                await MainActor.run { self.isLoading = false }
                await fetchAllActivities()
                await fetchMyActivities()
                return true
            } else if http.statusCode == 401 {
                let responseString = String(data: data, encoding: .utf8) ?? "<no body>"
                log("❌ Create Activity unauthorized: \(responseString)")
                
                await MainActor.run {
                    self.isLoading = false
                    self.error = "Your session has expired. Please log in again to create activities."
                    AuthStore.shared.logout()
                }
                
                return false
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "<no body>"
                log("❌ Create Activity failed: status=\(http.statusCode), body=\(responseString)")
                
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
    
    // MARK: - Activity Lookup Helpers
    
    /// Returns an activity from the in-memory caches if present.
    func findActivity(id: String) -> Activity? {
        if let fromAll = activities.first(where: { $0.id == id }) {
            return fromAll
        }
        if let fromUser = userActivities.first(where: { $0.id == id }) {
            return fromUser
        }
        return nil
    }

    /// Ensures we have a full Activity for a given id, fetching it from the backend if needed.
    func getActivityOrFetch(id: String) async -> Activity? {
        if let cached = findActivity(id: id) {
            return cached
        }
        
        do {
            var request = URLRequest(url: activityEndpoint(id: id))
            request.httpMethod = "GET"
            createAuthHeaders().forEach { header, value in
                request.setValue(value, forHTTPHeaderField: header)
            }
            
            log("GET \(request.url?.absoluteString ?? "") [single activity]")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            log("Status \(http.statusCode) for /activities/\(id)")
            
            guard http.statusCode == 200 else {
                if let raw = String(data: data, encoding: .utf8) {
                    log("Non-200 body for /activities/\(id):\n\(raw)")
                }
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw apiError
                }
                return nil
            }
            
            let decoder = JSONDecoder()
            let apiActivity: APIActivity
            if let direct = try? decoder.decode(APIActivity.self, from: data) {
                apiActivity = direct
            } else if let wrapped = try? decoder.decode(APIResponse<APIActivity>.self, from: data),
                      let wrappedData = wrapped.data {
                apiActivity = wrappedData
            } else {
                if let raw = String(data: data, encoding: .utf8) {
                    log("Decoding failed for /activities/\(id). Raw:\n\(raw)")
                }
                return nil
            }
            
            let converted = convertToActivity(apiActivity)
            await MainActor.run {
                if let idx = self.activities.firstIndex(where: { $0.id == converted.id }) {
                    self.activities[idx] = converted
                } else {
                    self.activities.append(converted)
                }
                
                if let idx = self.userActivities.firstIndex(where: { $0.id == converted.id }) {
                    self.userActivities[idx] = converted
                }
            }
            return converted
        } catch {
            log("Failed to fetch activity \(id): \(error)")
            return nil
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
            
            log("DELETE \(request.url?.absoluteString ?? "")")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ActivityAPIError.invalidResponse }
            
            log("Status \(http.statusCode) for DELETE /activities/:id")
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
    
    // Robust ISO8601 parsing (with and without fractional seconds)
    private func parseISO8601(_ string: String) -> Date? {
        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFrac.date(from: string) { return d }
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: string) { return d }
        // Fallback DateFormatters (some servers omit 'Z' or use milliseconds inconsistently)
        let fmts = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        for f in fmts {
            df.dateFormat = f
            if let d = df.date(from: string) { return d }
        }
        return nil
    }
    
    private func convertToActivity(_ apiActivity: APIActivity) -> Activity {
        let dateObj = parseISO8601(apiActivity.date)
        let timeObj = parseISO8601(apiActivity.time)
        
        let dateText: String = {
            if let d = dateObj {
                let out = DateFormatter()
                out.dateStyle = .medium
                out.timeStyle = .none
                return out.string(from: d)
            } else {
                return "TBD"
            }
        }()
        
        let timeText: String = {
            if let t = timeObj {
                let out = DateFormatter()
                out.dateStyle = .none
                out.timeStyle = .short
                return out.string(from: t)
            } else {
                return "TBD"
            }
        }()
        
        // Create creator object if available
        let creator: Activity.ActivityCreator?
        if let apiCreator = apiActivity.creator {
            creator = Activity.ActivityCreator(
                id: apiCreator._id,
                name: apiCreator.name ?? "Unknown",
                email: apiCreator.email,
                profileImageUrl: apiCreator.profileImageUrl
            )
        } else {
            creator = nil
        }
        
        // Get host name and avatar
        let hostName = apiActivity.creator?.name ?? "Unknown"
        let hostAvatar = apiActivity.creator?.profileImageUrl ?? "https://api.dicebear.com/7.x/avataaars/svg?seed=\(hostName)"
        
        // A paid session is any activity with a non-nil price (only coaches can set this)
        let isPaidSession = apiActivity.price != nil
        
        // Emoji icon per sport type (matches previous design: 🏀, ⚽, etc.)
        let sportIcon: String
        switch apiActivity.sportType.lowercased() {
        case "basketball":
            sportIcon = "🏀"
        case "football":
            sportIcon = "⚽"
        case "running":
            sportIcon = "🏃"
        case "cycling":
            sportIcon = "🚴"
        default:
            sportIcon = "🏃"
        }
        
        return Activity(
            id: apiActivity._id,
            title: apiActivity.title,
            sportType: apiActivity.sportType,
            sportIcon: sportIcon,
            hostName: hostName,
            hostAvatar: hostAvatar,
            date: dateText,
            time: timeText,
            location: apiActivity.location,
            distance: "1.2 mi", // This would come from location services
            spotsTotal: apiActivity.participants,
            spotsTaken: apiActivity.participantIds?.count ?? 0,
            level: apiActivity.level,
            visibility: apiActivity.visibility,
            latitude: apiActivity.latitude,
            longitude: apiActivity.longitude,
            creator: creator,
            participantIds: apiActivity.participantIds,
            isPaidSession: isPaidSession,
            price: apiActivity.price,
            description: apiActivity.description
        )
    }
    
    private func saveActivitiesToCache(_ activities: [Activity]) {
        do {
            let data = try JSONEncoder().encode(activities)
            try data.write(to: activitiesCacheURL, options: .atomic)
        } catch {
            log("Failed to cache activities: \(error)")
        }
    }
    
    private func loadCachedActivities() async {
        let url = activitiesCacheURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let cached = try JSONDecoder().decode([Activity].self, from: data)
            await MainActor.run {
                if self.activities.isEmpty {
                    self.activities = cached
                }
            }
        } catch {
            log("Failed to load cached activities: \(error)")
        }
    }
    
    private func convertToISODateOnly(date: String) -> String {
        // Input like "yyyy-MM-dd"; output ISO at midnight UTC
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        iso.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let d = df.date(from: date) {
            var comps = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: d)
            comps.hour = 0; comps.minute = 0; comps.second = 0
            let final = Calendar.current.date(from: comps) ?? d
            return iso.string(from: final)
        } else {
            return "2000-01-01T00:00:00.000Z"
        }
    }
    
    private func convertToISODateTime(date: String, time: String) -> String {
        // date: "yyyy-MM-dd", time: either "h:mm a" or "HH:mm"
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        
        let tf = DateFormatter()
        tf.locale = Locale(identifier: "en_US_POSIX")
        tf.timeZone = TimeZone(secondsFromGMT: 0)
        tf.dateFormat = "h:mm a"
        
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        iso.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let d = df.date(from: date) else { return "2000-01-01T12:00:00.000Z" }
        var t: Date? = tf.date(from: time)
        if t == nil {
            tf.dateFormat = "HH:mm"
            t = tf.date(from: time)
        }
        guard let tt = t else { return "2000-01-01T12:00:00.000Z" }
        
        var comp = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: d)
        let tcomp = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: tt)
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
            level: level,
            visibility: "public",
            isPaidSession: false,
            price: nil,
            description: nil
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

