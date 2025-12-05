//
//  AIMatchmakerAPI.swift
//  NEXO
//
//  Created by ROCCO 4X on 15/11/2025.
//

import Foundation

// MARK: - Request/Response Models (namespaced to avoid conflicts)

struct AIMatchmakerChatRequest: Encodable {
    let message: String
    let conversationHistory: [AIMatchmakerChatMessage]?
}

struct AIMatchmakerChatMessage: Codable {
    let role: String   // "user" or "assistant"
    let content: String
}

struct ChatResponse: Decodable {
    let message: String
    let suggestedActivities: [SuggestedActivity]?
    let suggestedUsers: [SuggestedUser]?
    let options: [String]?
}

struct SuggestedActivity: Codable, Identifiable {
    let id: String
    let title: String
    let sportType: String
    let location: String
    let date: String
    let time: String
    let participants: Int
    let maxParticipants: Int
    let level: String
    let matchScore: Int?
}

struct SuggestedUser: Codable, Identifiable {
    let id: String
    let name: String
    let profileImageUrl: String?
    let sport: String
    let distance: String?
    let matchScore: Int?
    let bio: String?
    let availability: String?
}

// MARK: - Service

enum AIMatchmakerAPI {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    /// Sends a chat message to the AI Matchmaker backend.
    static func chat(
        message: String,
        conversationHistory: [AIMatchmakerChatMessage]?
    ) async throws -> ChatResponse {
        guard let token = KeychainTokenStore.shared.getAccessToken(), !token.isEmpty else {
            throw APIError(statusCode: 401, message: "Unauthorized. Please login again.")
        }

        let url = APIConfig.endpoint("/ai-matchmaker/chat")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = AIMatchmakerChatRequest(message: message, conversationHistory: conversationHistory)
        req.httpBody = try encoder.encode(body)

        #if DEBUG
        if let payload = req.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
            print("➡️ POST \(url.absoluteString)")
            print("Headers: \(req.allHTTPHeaderFields ?? [:])")
            print("Request JSON: \(payload)")
        }
        #endif

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }

        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            print("⬅️ Status: \(http.statusCode) Body: \(bodyStr)")
        }
        #endif

        if (200..<300).contains(http.statusCode) {
            return try decoder.decode(ChatResponse.self, from: data)
        } else {
            // If backend returns a fallback payload with 5xx, try to decode it first
            if (500...599).contains(http.statusCode),
               let fallback = try? decoder.decode(ChatResponse.self, from: data) {
                return fallback
            }
            // Try to decode server error envelope
            if let apiErr = try? decoder.decode(APIError.self, from: data) {
                throw apiErr
            }
            // Generic error
            throw APIError(statusCode: http.statusCode, message: "Request failed (\(http.statusCode)).")
        }
    }
}

