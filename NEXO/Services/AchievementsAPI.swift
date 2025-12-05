import Foundation

enum AchievementsAPI {
    struct AchievementSummary: Codable {
        struct LevelInfo: Codable {
            let currentLevel: Int
            let totalXp: Int
            let xpForNextLevel: Int
            let currentLevelXp: Int
            let progressPercentage: Double
        }

        struct StatsInfo: Codable {
            let totalBadges: Int
            let currentStreak: Int
            let bestStreak: Int
        }

        let level: LevelInfo
        let stats: StatsInfo
    }

    struct Badge: Codable, Identifiable {
        enum BadgeRarity: String, Codable {
            case common
            case uncommon
            case rare
            case epic
            case legendary
        }

        enum BadgeCategory: String, Codable {
            case creation
            case completion
            case distance
            case duration
            case streak
            case sport

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = BadgeCategory(rawValue: rawValue) ?? .sport
            }
        }

        let id: String
        let name: String
        let description: String
        let iconUrl: String?
        let rarity: BadgeRarity
        let category: BadgeCategory
        let earnedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case name
            case description
            case iconUrl
            case rarity
            case category
            case earnedAt
        }
    }

    struct BadgeProgress: Codable, Identifiable {
        var id: String { badge.id }
        let badge: Badge
        let currentProgress: Int
        let target: Int
        let percentage: Double

        enum CodingKeys: String, CodingKey {
            case badge
            case currentProgress
            case target
            case percentage
        }
    }

    struct BadgesResponse: Codable {
        let earnedBadges: [Badge]
        let inProgress: [BadgeProgress]
    }

    struct Challenge: Codable, Identifiable {
        enum ChallengeType: String, Codable {
            case daily
            case weekly
            case monthly
            case distance
            case duration
        }

        let id: String
        let name: String
        let description: String
        let challengeType: ChallengeType
        let xpReward: Int
        let currentProgress: Int
        let target: Int
        let daysLeft: Int
        let expiresAt: Date

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case name
            case description
            case challengeType
            case xpReward
            case currentProgress
            case target
            case daysLeft
            case expiresAt
        }
    }

    struct ChallengesResponse: Codable {
        let activeChallenges: [Challenge]
    }

    struct LeaderboardEntry: Codable, Identifiable {
        let rank: Int
        let username: String
        let totalXp: Int
        let medal: String?

        var id: Int { rank }

        enum CodingKeys: String, CodingKey {
            case rank
            case username
            case totalXp
            case medal
        }
    }

    struct LeaderboardResponse: Codable {
        struct CurrentUserInfo: Codable {
            let rank: Int
            let username: String
            let totalXp: Int
            let isCurrentUser: Bool
        }

        let currentUser: CurrentUserInfo?
        let leaderboard: [LeaderboardEntry]
        let page: Int
        let totalPages: Int
    }

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601WithoutFractional = ISO8601DateFormatter()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = iso8601WithFractional.date(from: dateString) {
                return date
            }
            if let date = iso8601WithoutFractional.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        return d
    }()

    private static let encoder = JSONEncoder()

    private static func authorizedRequest(url: URL, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = AuthTokenManager.shared.getToken(), !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body
        return req
    }

    private static func authorizedRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        let url = APIConfig.endpoint(path)
        return try authorizedRequest(url: url, method: method, body: body)
    }

    private static func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }

        #if DEBUG
        if let url = req.url?.absoluteString {
            print("➡️ \(req.httpMethod ?? "REQ") \(url)")
            if let body = req.httpBody, let s = String(data: body, encoding: .utf8), !s.isEmpty {
                print("Request JSON: \(s)")
            }
            if let text = String(data: data, encoding: .utf8) {
                print("⬅️ Status: \(http.statusCode) Body: \(text)")
            }
        }
        #endif

        if (200..<300).contains(http.statusCode) {
            return try decoder.decode(T.self, from: data)
        } else {
            if let apiErr = try? decoder.decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: http.statusCode, message: "Request failed (\(http.statusCode)).")
        }
    }

    static func getSummary() async throws -> AchievementSummary {
        let req = try authorizedRequest(path: "/achievements/summary")
        return try await send(req)
    }

    static func getBadges() async throws -> BadgesResponse {
        let req = try authorizedRequest(path: "/achievements/badges")
        return try await send(req)
    }

    static func getChallenges() async throws -> ChallengesResponse {
        let req = try authorizedRequest(path: "/achievements/challenges")
        return try await send(req)
    }

    static func getLeaderboard(page: Int = 1, limit: Int = 20) async throws -> LeaderboardResponse {
        let base = APIConfig.endpoint("/achievements/leaderboard")
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let req = try authorizedRequest(url: comps.url!)
        return try await send(req)
    }
}
