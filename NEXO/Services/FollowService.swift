import Foundation

struct FollowResponse: Decodable {
    let message: String?
}

struct IsFollowingResponse: Decodable {
    let isFollowing: Bool
}

final class FollowService {
    // MARK: - Endpoints
    private enum Endpoint {
        case follow(userId: String)
        case unfollow(userId: String)
        case isFollowing(userId: String)

        func path() -> String {
            switch self {
            case .follow(let userId):
                return "/users/\(userId)/follow"
            case .unfollow(let userId):
                return "/users/\(userId)/unfollow"
            case .isFollowing(let userId):
                return "/users/\(userId)/is-following"
            }
        }
    }

    // MARK: - Public API

    func followUser(token: String, userId: String) async throws -> FollowResponse {
        try await sendFollowRequest(token: token, endpoint: .follow(userId: userId))
    }

    func unfollowUser(token: String, userId: String) async throws -> FollowResponse {
        try await sendFollowRequest(token: token, endpoint: .unfollow(userId: userId))
    }

    func isFollowing(token: String, userId: String) async throws -> IsFollowingResponse {
        let url = APIConfig.endpoint(Endpoint.isFollowing(userId: userId).path())

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }

        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            print("➡️ GET \(url.absoluteString)")
            print("⬅️ Status: \(httpResponse.statusCode) Body: \(bodyStr)")
        }
        #endif

        if (200..<300).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            return try decoder.decode(IsFollowingResponse.self, from: data)
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to load follow status")
        }
    }

    // MARK: - Private helpers

    private func sendFollowRequest(token: String, endpoint: Endpoint) async throws -> FollowResponse {
        let url = APIConfig.endpoint(endpoint.path())

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }

        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            print("➡️ POST \(url.absoluteString)")
            print("⬅️ Status: \(httpResponse.statusCode) Body: \(bodyStr)")
        }
        #endif

        if (200..<300).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            return (try? decoder.decode(FollowResponse.self, from: data)) ?? FollowResponse(message: nil)
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to update follow status")
        }
    }
}
