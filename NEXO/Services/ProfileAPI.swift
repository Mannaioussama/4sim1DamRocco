//
//  ProfileAPI.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import Foundation
import UIKit

class ProfileAPI {
    // MARK: - Singleton
    static let shared = ProfileAPI()
    
    private init() {}
    
    // MARK: - Endpoints
    private enum Endpoint {
        case getProfile
        case updateProfile(userId: String)
        case uploadProfileImage(userId: String)
        case sendVerificationEmail
        case changePassword(userId: String)
        
        func path() -> String {
            switch self {
            case .getProfile:
                return "/users/profile"
            case .updateProfile(let userId):
                return "/users/\(userId)"
            case .uploadProfileImage(let userId):
                return "/users/\(userId)/profile-image"
            case .sendVerificationEmail:
                return "/auth/send-verification-email"
            case .changePassword(let userId):
                return "/users/\(userId)/change-password"
            }
        }
    }
    
    // MARK: - Get User Profile
    func getProfile(token: String) async throws -> UserProfile {
        let url = APIConfig.endpoint(Endpoint.getProfile.path())
        
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
            return try decoder.decode(UserProfile.self, from: data)
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to get profile")
        }
    }
    
    // MARK: - Update Profile
    func updateProfile(
        userId: String,
        token: String,
        request: UpdateProfileRequest
    ) async throws -> UserProfile {
        let url = APIConfig.endpoint(Endpoint.updateProfile(userId: userId).path())
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }
        
        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8),
           let payloadStr = urlRequest.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
            print("➡️ PATCH \(url.absoluteString)")
            print("Request JSON: \(payloadStr)")
            print("⬅️ Status: \(httpResponse.statusCode) Body: \(bodyStr)")
        }
        #endif
        
        if (200..<300).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            // Backend might return wrapped response or direct user
            if let wrapped = try? decoder.decode(UpdateProfileResponse.self, from: data) {
                return wrapped.user
            } else {
                return try decoder.decode(UserProfile.self, from: data)
            }
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to update profile")
        }
    }
    
    // MARK: - Upload Profile Image
    func uploadProfileImage(
        userId: String,
        token: String,
        imageData: Data
    ) async throws -> UserProfile {
        let url = APIConfig.endpoint(Endpoint.uploadProfileImage(userId: userId).path())
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }
        
        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8) {
            print("➡️ PATCH \(url.absoluteString)")
            print("⬅️ Status: \(httpResponse.statusCode) Body: \(bodyStr)")
        }
        #endif
        
        if (200..<300).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            // Backend might return wrapped response or direct user
            if let wrapped = try? decoder.decode(ProfileImageUploadResponse.self, from: data) {
                return wrapped.user
            } else {
                return try decoder.decode(UserProfile.self, from: data)
            }
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to upload image")
        }
    }
    
    // MARK: - Send Verification Emailk
    func sendVerificationEmail(
        email: String,
        token: String?
    ) async throws -> String {
        let url = APIConfig.endpoint(Endpoint.sendVerificationEmail.path())
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if provided (for authenticated requests)
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode request body
        let requestBody = SendVerificationEmailRequest(email: email)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }
        
        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8),
           let payloadStr = request.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
            print("➡️ POST \(url.absoluteString)")
            print("Request JSON: \(payloadStr)")
            print("⬅️ Status: \(httpResponse.statusCode) Body: \(bodyStr)")
        }
        #endif
        
        if (200..<300).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            // Try to decode structured response first
            if let responseData = try? decoder.decode(SendVerificationEmailResponse.self, from: data) {
                return responseData.message
            }
            // Fall back to MessageResponse
            if let messageResp = try? decoder.decode(MessageResponse.self, from: data) {
                return messageResp.message
            }
            return "Verification email sent successfully"
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to send verification email")
        }
    }
    
    // MARK: - Change Password
    func changePassword(
        userId: String,
        token: String,
        request: ChangePasswordRequest
    ) async throws -> String {
        let url = APIConfig.endpoint(Endpoint.changePassword(userId: userId).path())
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(statusCode: nil, message: "Invalid server response.")
        }
        
        #if DEBUG
        if let bodyStr = String(data: data, encoding: .utf8),
           let payloadStr = urlRequest.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
            print("➡️ PATCH \(url.absoluteString)")
            print("Request JSON: \(payloadStr)")
            print("⬅️ Status: \(httpResponse.statusCode) Body: \(bodyStr)")
        }
        #endif
        
        if (200..<300).contains(httpResponse.statusCode) {
            // Some backends return { message }, others 204 No Content.
            if data.isEmpty { return "Password changed successfully" }
            if let message = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                return message.message
            }
            return "Password changed successfully"
        } else {
            if let apiErr = try? JSONDecoder().decode(APIError.self, from: data) {
                throw apiErr
            }
            throw APIError(statusCode: httpResponse.statusCode, message: "Failed to change password")
        }
    }
}

// MARK: - Data Extension Helper
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

