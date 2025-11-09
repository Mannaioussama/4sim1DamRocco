//
//  AuthModels.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import Foundation

// MARK: - Requests (match your NestJS DTOs)
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
    let location: String
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let password: String
}

// MARK: - User with tolerant decoding for id/_id
struct User: Codable, Equatable {
    let id: String?
    let email: String
    let name: String?
    let location: String?

    init(id: String?, email: String, name: String?, location: String?) {
        self.id = id
        self.email = email
        self.name = name
        self.location = location
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? c.decodeIfPresent(String.self, forKey: .id))
            ?? (try? c.decodeIfPresent(String.self, forKey: ._id))
        let email = (try? c.decodeIfPresent(String.self, forKey: .email))
            ?? (try? c.decodeIfPresent(String.self, forKey: .username))
        guard let emailUnwrapped = email else {
            throw DecodingError.keyNotFound(CodingKeys.email, .init(codingPath: c.codingPath, debugDescription: "email not found"))
        }
        let name = try? c.decodeIfPresent(String.self, forKey: .name)
        let location = try? c.decodeIfPresent(String.self, forKey: .location)
        self.init(id: id, email: emailUnwrapped, name: name ?? nil, location: location ?? nil)
    }

    // Custom encoder so Encodable remains valid despite extra decoding keys
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(location, forKey: .location)
    }

    private enum CodingKeys: String, CodingKey {
        // Includes alternate keys we accept while decoding
        case id, _id, email, username, name, location
    }
}

// MARK: - Flexible AuthResponse
// Accepts token in several key names and optional wrapping with "data"
struct AuthResponse: Decodable {
    let accessToken: String
    let user: User

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // token could be any of these
        let token =
            (try? c.decodeIfPresent(String.self, forKey: .accessToken)) ??
            (try? c.decodeIfPresent(String.self, forKey: .access_token)) ??
            (try? c.decodeIfPresent(String.self, forKey: .token))

        // user may be direct
        let userDirect = try? c.decodeIfPresent(User.self, forKey: .user)

        if let token, let user = userDirect {
            self.accessToken = token
            self.user = user
            return
        }

        // or nested under data
        if let nested = try? c.nestedContainer(keyedBy: DataKeys.self, forKey: .data) {
            let token2 =
                (try? nested.decodeIfPresent(String.self, forKey: .accessToken)) ??
                (try? nested.decodeIfPresent(String.self, forKey: .access_token)) ??
                (try? nested.decodeIfPresent(String.self, forKey: .token))
            let user2 = try? nested.decodeIfPresent(User.self, forKey: .user)
            if let token2, let user2 {
                self.accessToken = token2
                self.user = user2
                return
            }
        }

        // sometimes register returns only { user, message }
        if let userOnly = userDirect {
            self.accessToken = ""
            self.user = userOnly
            return
        }

        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "AuthResponse: unexpected JSON format"))
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case access_token
        case token
        case user
        case message
        case data
    }

    private enum DataKeys: String, CodingKey {
        case accessToken
        case access_token
        case token
        case user
    }
}

// Simple message responses (support message/msg/status)
struct MessageResponse: Decodable {
    let message: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let m = try? c.decodeIfPresent(String.self, forKey: .message) {
            message = m
        } else if let m = try? c.decodeIfPresent(String.self, forKey: .msg) {
            message = m
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .status) {
            message = s
        } else {
            message = "OK"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case message, msg, status
    }
}

struct ValidateTokenResponse: Decodable {
    let valid: Bool
    let message: String?
}

// Convenience initializer so we can construct AuthResponse when register
// returns message/user or user-only (no token).
extension AuthResponse {
    init(accessToken: String, user: User) {
        self.accessToken = accessToken
        self.user = user
    }
}
