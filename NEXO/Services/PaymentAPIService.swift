import Foundation

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
}

struct ConfirmPaymentRequest: Codable {
    let paymentIntentId: String
    let activityId: String
}

struct ConfirmPaymentResponse: Codable {
    let success: Bool
    let message: String
    let activityId: String
}

struct PaymentStatusResponse: Codable {
    let hasPaid: Bool
    let isParticipant: Bool
    let activityPrice: Double
}

// MARK: - Coach Earnings
struct CoachEarningsResponse: Codable {
    let totalEarnings: Double
    let earnings: [EarningEntry]
}

struct EarningEntry: Codable, Identifiable {
    let date: String
    let amount: Double
    let activityId: String
    let activityTitle: String

    var id: String { activityId + "_" + date }
}

final class PaymentAPIService {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private func authHeaders() -> [String: String] {
        var headers: [String: String] = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        if let token = AuthTokenManager.shared.getToken() {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    func createPaymentIntent(activityId: String, amount: Double, currency: String = "eur") async throws -> PaymentIntentResponse {
        let url = APIConfig.endpoint("payments/create-intent")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        authHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        let body: [String: Any] = [
            "activityId": activityId,
            "amount": amount,
            "currency": currency
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(statusCode: nil, message: "Invalid response") }
        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
            throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        return try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
    }
    
    func confirmPayment(activityId: String, paymentIntentId: String) async throws -> ConfirmPaymentResponse {
        let url = APIConfig.endpoint("payments/confirm")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        authHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        let body = ConfirmPaymentRequest(paymentIntentId: paymentIntentId, activityId: activityId)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(statusCode: nil, message: "Invalid response") }
        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
            throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        return try JSONDecoder().decode(ConfirmPaymentResponse.self, from: data)
    }
    
    func checkPaymentStatus(activityId: String) async throws -> PaymentStatusResponse {
        let url = APIConfig.endpoint("payments/check-payment/\(activityId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(statusCode: nil, message: "Invalid response") }
        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
            throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        return try JSONDecoder().decode(PaymentStatusResponse.self, from: data)
    }

    /// Get coach earnings for an optional year and month.
    /// If year/month are nil, backend will return aggregate earnings.
    func getCoachEarnings(year: Int? = nil, month: Int? = nil) async throws -> CoachEarningsResponse {
        var components = URLComponents(url: APIConfig.endpoint("payments/coach/earnings"), resolvingAgainstBaseURL: false)

        var queryItems: [URLQueryItem] = []
        if let year = year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }
        if let month = month {
            queryItems.append(URLQueryItem(name: "month", value: String(month)))
        }
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIError(statusCode: nil, message: "Invalid earnings URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(statusCode: nil, message: "Invalid response") }
        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) { throw apiError }
            throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
        }

        return try JSONDecoder().decode(CoachEarningsResponse.self, from: data)
    }
}
