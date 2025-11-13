//
//  ProfileModels.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import Foundation

// MARK: - User Model (matches backend User schema)
struct UserProfile: Codable {
    let id: String
    let email: String
    let name: String
    let location: String
    let isEmailVerified: Bool
    let phone: String?
    let dateOfBirth: String?
    let about: String?
    let sportsInterests: [String]?
    let profileImageUrl: String?
    let profileImageThumbnailUrl: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case name
        case location
        case isEmailVerified
        case phone
        case dateOfBirth
        case about
        case sportsInterests
        case profileImageUrl
        case profileImageThumbnailUrl
        case createdAt
        case updatedAt
    }
}

// MARK: - Update Profile Request (matches UpdateProfileDto)
struct UpdateProfileRequest: Codable {
    let name: String?
    let email: String?
    let phone: String?
    let dateOfBirth: String?  // Format: "DD/MM/YYYY"
    let location: String?
    let about: String?
    let sportsInterests: [String]?
    
    init(
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        dateOfBirth: String? = nil,
        location: String? = nil,
        about: String? = nil,
        sportsInterests: [String]? = nil
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.location = location
        self.about = about
        self.sportsInterests = sportsInterests
    }
}

// MARK: - Update Profile Response
struct UpdateProfileResponse: Codable {
    let user: UserProfile
    let message: String?
}

// MARK: - Send Verification Email Request (matches SendVerificationEmailDto)
struct SendVerificationEmailRequest: Codable {
    let email: String
}

// MARK: - Send Verification Email Response
struct SendVerificationEmailResponse: Codable {
    let message: String
}

// MARK: - Profile Image Upload Response
struct ProfileImageUploadResponse: Codable {
    let user: UserProfile
    let message: String?
}

// MARK: - API Error Response
struct APIErrorResponse: Codable {
    let statusCode: Int?
    let message: String
    let error: String?
}

// MARK: - Helper Extensions
extension UserProfile {
    /// Get display initials from name
    var initials: String {
        let components = name.split(separator: " ")
        let initials = components.compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "?" : initials.uppercased()
    }
    
    /// Get display name (first name only)
    var firstName: String {
        return name.split(separator: " ").first.map(String.init) ?? name
    }
    
    /// Check if profile is complete
    var isComplete: Bool {
        return !name.isEmpty &&
               !email.isEmpty &&
               !location.isEmpty &&
               phone != nil &&
               dateOfBirth != nil &&
               about != nil &&
               !(sportsInterests?.isEmpty ?? true)
    }
}

// MARK: - Date Formatting Helper
extension Date {
    /// Convert Date to backend format (DD/MM/YYYY)
    func toBackendDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
    
    /// Convert backend date string (DD/MM/YYYY) to Date
    static func fromBackendDateString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
}

// MARK: - Cross-screen notifications
extension Notification.Name {
    static let profileDidUpdate = Notification.Name("ProfileDidUpdate")
}

// MARK: - Change Password Request (matches ChangePasswordDto)
struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}

