//
//  APIError.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import Foundation

// Decodes NestJS error envelope and exposes a user-friendly message
struct APIError: LocalizedError, Decodable {
    let statusCode: Int?
    let messages: [String]
    let errorType: String?

    var errorDescription: String? { userMessage }
    var userMessage: String { messages.first ?? "Something went wrong. Please try again." }

    // Decode { statusCode, message: string | string[], error }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        statusCode = try? c.decodeIfPresent(Int.self, forKey: .statusCode)
        errorType = try? c.decodeIfPresent(String.self, forKey: .error)
        if let single = try? c.decodeIfPresent(String.self, forKey: .message) {
            messages = [single]
        } else if let arr = try? c.decodeIfPresent([String].self, forKey: .message) {
            messages = arr
        } else {
            messages = []
        }
    }

    init(statusCode: Int?, message: String) {
        self.statusCode = statusCode
        self.messages = [message]
        self.errorType = nil
    }

    private enum CodingKeys: String, CodingKey { case statusCode, message, error }
}
