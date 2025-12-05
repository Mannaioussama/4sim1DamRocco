import Foundation

// MARK: - Subscription Models

struct SubscriptionResponse: Codable {
    let id: String
    let userId: String
    let type: String
    let status: String
    let startDate: String
    let endDate: String?
    let nextBillingDate: String?
    let activitiesUsedThisMonth: Int
    let activitiesLimit: Int
    let activitiesRemaining: Int
    let freeActivitiesRemaining: Int
    let isCoachVerified: Bool
    let monthlyPrice: Double
    let currency: String
    let features: SubscriptionFeatures
}

struct SubscriptionFeatures: Codable {
    let maxActivitiesPerMonth: Int
    let unlimitedActivities: Bool
    let prioritySupport: Bool
    let advancedAnalytics: Bool
    let customBranding: Bool
    let apiAccess: Bool
    let featuredListing: Bool?
}

struct SubscriptionPlan: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let price: Double
    let currency: String
    let interval: String
    let activitiesLimit: Int
    let features: SubscriptionFeatures
    let popular: Bool?
    let stripePriceId: String
    
    var displayPrice: String {
        if price == 0 {
            return "FREE"
        }
        return "\(Int(price))€/month"
    }
    
    var activitiesLimitText: String {
        if activitiesLimit == -1 {
            return "Unlimited activities"
        } else if activitiesLimit == 1 {
            return "1 free activity"
        } else {
            return "\(activitiesLimit) activities/month"
        }
    }
}

struct SubscriptionPlansResponse: Codable {
    let plans: [SubscriptionPlan]
    let currentPlan: SubscriptionResponse?
}

struct CheckLimitResponse: Codable {
    let canCreate: Bool
    let activitiesUsed: Int
    let activitiesLimit: Int
    let activitiesRemaining: Int
    let subscriptionType: String
    let freeActivitiesRemaining: Int
    let message: String?
}

struct InitializePaymentRequest: Codable {
    let planType: String
}

struct InitializePaymentResponse: Codable {
    let clientSecret: String
    let setupIntentId: String
}

struct CreateSubscriptionRequest: Codable {
    let type: String
    let paymentMethodId: String?
    let setupIntentId: String?
}

// MARK: - Subscription API

enum SubscriptionAPI {
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()
    
    private static func authorizedRequest(path: String, method: String, body: Data? = nil) throws -> URLRequest {
        let url = APIConfig.endpoint(path)
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
            if T.self == EmptyDecodable.self, data.isEmpty {
                return EmptyDecodable() as! T
            }
            return try decoder.decode(T.self, from: data)
        } else {
            if let apiErr = try? decoder.decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: http.statusCode, message: "Request failed (\(http.statusCode)).")
        }
    }
    
    // MARK: - Endpoints
    
    static func getAvailablePlans() async throws -> SubscriptionPlansResponse {
        let req = try authorizedRequest(path: "/subscriptions/plans", method: "GET")
        return try await send(req)
    }
    
    static func getCurrentSubscription() async throws -> SubscriptionResponse {
        let req = try authorizedRequest(path: "/subscriptions/me", method: "GET")
        return try await send(req)
    }
    
    static func checkActivityLimit() async throws -> CheckLimitResponse {
        let req = try authorizedRequest(path: "/subscriptions/check-limit", method: "GET")
        return try await send(req)
    }
    
    static func initializePayment(planType: String) async throws -> InitializePaymentResponse {
        let body = try encoder.encode(InitializePaymentRequest(planType: planType))
        let req = try authorizedRequest(path: "/subscriptions/initialize-payment", method: "POST", body: body)
        return try await send(req)
    }
    
    static func createSubscription(type: String, paymentMethodId: String? = nil, setupIntentId: String? = nil) async throws -> SubscriptionResponse {
        let body = try encoder.encode(CreateSubscriptionRequest(type: type, paymentMethodId: paymentMethodId, setupIntentId: setupIntentId))
        let req = try authorizedRequest(path: "/subscriptions", method: "POST", body: body)
        return try await send(req)
    }
}

// Helper for empty responses
private struct EmptyDecodable: Decodable {}
