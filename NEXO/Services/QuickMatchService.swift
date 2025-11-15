//
//  QuickMatchService.swift
//  NEXO
//
//  Created by ROCCO 4X on 14/11/2025.
//

import Foundation

// MARK: - Protocol (DI-friendly, easy to mock/cache later)
protocol QuickMatchServicing {
    func getProfiles(page: Int, limit: Int) async throws -> ProfilesResponse
    func likeProfile(profileId: String) async throws -> LikeResponse
    func passProfile(profileId: String) async throws
    func getMatches() async throws -> [Match]
    func getLikesReceived() async throws -> LikesReceivedResponse
}

// MARK: - Concrete Service (actor = safe for future caching/mutation)
actor QuickMatchService: QuickMatchServicing {
    static let shared = QuickMatchService()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Token

    private func getAuthToken() async throws -> String {
        // Prefer AuthStore (main-actor), fallback to AuthTokenManager (non-isolated)
        let storeToken = await MainActor.run { AuthStore.shared.accessToken() }
        if let t = storeToken, !t.isEmpty { return t }
        if let t2 = AuthTokenManager.shared.getToken(), !t2.isEmpty { return t2 }
        throw APIError(statusCode: 401, message: "Not authenticated. Please log in.")
    }

    // MARK: - Core request helpers

    private func authorizedRequest(url: URL, method: String, body: Data? = nil) async throws -> URLRequest {
        let token = try await getAuthToken()
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body { req.httpBody = body }
        return req
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }

        #if DEBUG
        if let url = req.url?.absoluteString {
            print("➡️ \(req.httpMethod ?? "REQ") \(url)")
            if let b = req.httpBody, let s = String(data: b, encoding: .utf8), !s.isEmpty {
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

    // Some endpoints may return 204 or arbitrary JSON we don't care to decode
    private func sendNoBody(_ req: URLRequest) async throws {
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }

        #if DEBUG
        if let url = req.url?.absoluteString {
            print("➡️ \(req.httpMethod ?? "REQ") \(url)")
            if let b = req.httpBody, let s = String(data: b, encoding: .utf8), !s.isEmpty {
                print("Request JSON: \(s)")
            }
            if let text = String(data: data, encoding: .utf8) {
                print("⬅️ Status: \(http.statusCode) Body: \(text)")
            }
        }
        #endif

        if !(200..<300).contains(http.statusCode) {
            if let apiErr = try? decoder.decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: http.statusCode, message: "Request failed (\(http.statusCode)).")
        }
    }

    // MARK: - Endpoints

    func getProfiles(page: Int = 1, limit: Int = 20) async throws -> ProfilesResponse {
        var comps = URLComponents(url: APIConfig.endpoint("/quick-match/profiles"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try await authorizedRequest(url: comps.url!, method: "GET")
        return try await send(req)
    }

    func likeProfile(profileId: String) async throws -> LikeResponse {
        let url = APIConfig.endpoint("/quick-match/like")
        let body = try encoder.encode(LikeRequest(profileId: profileId))
        let req = try await authorizedRequest(url: url, method: "POST", body: body)
        return try await send(req)
    }

    func passProfile(profileId: String) async throws {
        let url = APIConfig.endpoint("/quick-match/pass")
        let body = try encoder.encode(PassRequest(profileId: profileId))
        let req = try await authorizedRequest(url: url, method: "POST", body: body)
        // Accept 2xx regardless of body shape
        try await sendNoBody(req)
    }

    func getMatches() async throws -> [Match] {
        let url = APIConfig.endpoint("/quick-match/matches")
        let req = try await authorizedRequest(url: url, method: "GET")
        return try await send(req)
    }

    func getLikesReceived() async throws -> LikesReceivedResponse {
        let url = APIConfig.endpoint("/quick-match/likes-received")
        let req = try await authorizedRequest(url: url, method: "GET")
        return try await send(req)
    }
}
