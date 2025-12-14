import Foundation

// MARK: - Core Review Models

/// Backend review payload used for coach-wide reviews.
/// Named BackendReview to avoid conflicts with UI-level Review models.
struct BackendReview: Codable, Identifiable {
    let id: String
    let activityId: String
    let userId: String
    let userName: String
    let userAvatar: String?
    let rating: Int
    let comment: String?
    let createdAt: String
    let activityTitle: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case activityId
        case userId
        case userName
        case userAvatar
        case rating
        case comment
        case createdAt
        case activityTitle
    }
}

struct ActivityReview: Codable, Identifiable {
    let id: String
    let activityId: String
    let userId: UserInfo
    let rating: Int
    let comment: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case activityId
        case userId
        case rating
        case comment
        case createdAt
    }
}

struct UserInfo: Codable {
    let id: String
    let name: String
    let profileImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case profileImageUrl
    }
}

struct ActivityReviewsResponse: Codable {
    let reviews: [ActivityReview]
    let averageRating: Double
    let totalReviews: Int
}

struct CoachReviewsResponse: Codable {
    let reviews: [BackendReview]
    let averageRating: Double
    let totalReviews: Int
}

struct CreateReviewRequest: Codable {
    let activityId: String
    let rating: Int
    let comment: String?
}

struct CreateReviewResponse: Codable {
    let success: Bool
    let message: String
    let review: BackendReview
}
