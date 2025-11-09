//
//  AuthAPI.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import Foundation

enum AuthAPI {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Endpoints
    static func login(_ body: LoginRequest) async throws -> AuthResponse {
        try await request(path: "/auth/login", method: "POST", body: body)
    }

    // Custom parser for register to handle multiple backend shapes without breaking other calls
    static func register(_ body: RegisterRequest) async throws -> AuthResponse {
        let url = APIConfig.endpoint("/auth/register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }

        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8),
           let payloadStr = req.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
            print("➡️ POST \(url.absoluteString)")
            print("Request JSON: \(payloadStr)")
            print("⬅️ Status: \(http.statusCode) Body: \(bodyStr)")
        }
        #endif

        if (200..<300).contains(http.statusCode) {
            // 1) Try the normal AuthResponse
            if let auth = try? decoder.decode(AuthResponse.self, from: data) {
                return auth
            }
            // 2) Try a message + user object
            struct MessageUserEnvelope: Decodable {
                let message: String?
                let user: User?
                // sometimes wrapped under "data"
                let data: Inner?
                struct Inner: Decodable { let message: String?; let user: User?; let accessToken: String?; let access_token: String?; let token: String? }
            }
            if let env = try? decoder.decode(MessageUserEnvelope.self, from: data) {
                // Prefer nested data token if present
                if let d = env.data {
                    let token = d.accessToken ?? d.access_token ?? d.token ?? ""
                    if let u = d.user {
                        return AuthResponse(accessToken: token, user: u)
                    }
                }
                if let u = env.user {
                    return AuthResponse(accessToken: "", user: u)
                }
            }
            // 3) Try message-only (no user/token)
            if (try? decoder.decode(MessageResponse.self, from: data)) != nil {
                // Synthesize minimal user from submitted data so UI can proceed; token empty means AuthStore will auto-login
                let u = User(id: nil, email: body.email, name: body.name, location: body.location)
                return AuthResponse(accessToken: "", user: u)
            }
            // 4) Try decoding a bare User at root
            if let u = try? decoder.decode(User.self, from: data) {
                return AuthResponse(accessToken: "", user: u)
            }

            throw APIError(statusCode: http.statusCode, message: "Unexpected response format. Please update client models.")
        } else {
            if let apiErr = try? decoder.decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: http.statusCode, message: "Request failed (\(http.statusCode)).")
        }
    }

    static func forgotPassword(_ body: ForgotPasswordRequest) async throws -> MessageResponse {
        try await request(path: "/auth/forgot-password", method: "POST", body: body)
    }

    static func validateResetToken(_ token: String) async throws -> ValidateTokenResponse {
        var comps = URLComponents(url: APIConfig.endpoint("/auth/reset-password"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "token", value: token)]
        return try await request(url: comps.url!, method: "GET") as ValidateTokenResponse
    }

    static func resetPassword(_ body: ResetPasswordRequest) async throws -> MessageResponse {
        try await request(path: "/auth/reset-password", method: "POST", body: body)
    }

    // MARK: - Core request helpers
    private static func request<T: Decodable, B: Encodable>(path: String, method: String, body: B) async throws -> T {
        let url = APIConfig.endpoint(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        return try await send(req)
    }

    private static func request<T: Decodable>(url: URL, method: String) async throws -> T {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await send(req)
    }

    private static func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }
        if (200..<300).contains(http.statusCode) {
            return try decoder.decode(T.self, from: data)
        } else {
            if let apiErr = try? decoder.decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: http.statusCode, message: "Request failed (\(http.statusCode)).")
        }
    }
}
