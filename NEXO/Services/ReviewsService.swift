import Foundation

final class ReviewsService {
    private let authTokenManager = AuthTokenManager.shared

    // MARK: - Public API

    func createReview(activityId: String, rating: Int, comment: String?) async throws -> CreateReviewResponse {
        guard let token = authTokenManager.getToken() else {
            throw APIError(statusCode: nil, message: "Authentication required")
        }

        let url = APIConfig.endpoint("/reviews")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = CreateReviewRequest(activityId: activityId, rating: rating, comment: comment)
        request.httpBody = try JSONEncoder().encode(body)

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
            return try decoder.decode(CreateReviewResponse.self, from: data)
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to submit review")
        }
    }

    func getActivityReviews(activityId: String) async throws -> ActivityReviewsResponse {
        guard let token = authTokenManager.getToken() else {
            throw APIError(statusCode: nil, message: "Authentication required")
        }

        let url = APIConfig.endpoint("/reviews/activity/\(activityId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
            return try decoder.decode(ActivityReviewsResponse.self, from: data)
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to load activity reviews")
        }
    }

    /// Currently backend returns reviews for the authenticated coach.
    /// Once backend accepts coachId, this can be extended to take a coachId parameter.
    func getCoachReviews(limit: Int = 50) async throws -> CoachReviewsResponse {
        guard let token = authTokenManager.getToken() else {
            throw APIError(statusCode: nil, message: "Authentication required")
        }

        var components = URLComponents(url: APIConfig.endpoint("/reviews/coach"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        let url = components.url ?? APIConfig.endpoint("/reviews/coach")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
            return try decoder.decode(CoachReviewsResponse.self, from: data)
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to load coach reviews")
        }
    }
}
