//
//  QuickMatchModels.swift
//  NEXO
//
//  Created by ROCCO 4X on 14/11/2025.
//

import Foundation

// MARK: - Backend Models (decoding-only)

struct Sport: Decodable, Equatable {
    let name: String?
    let icon: String?
    let level: String?
}

struct Profile: Decodable, Identifiable, Equatable {
    let id: String
    let name: String?
    let age: Int?
    let email: String?
    let avatarUrl: String?
    let coverImageUrl: String?
    let location: String?
    let distance: String?
    let bio: String?
    let about: String?
    let sportsInterests: [String]?
    let sports: [Sport]?
    let interests: [String]?
    let rating: Int?
    let activitiesJoined: Int?
    let profileImageUrl: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? c.decodeIfPresent(String.self, forKey: ._id))
            ?? (try? c.decodeIfPresent(String.self, forKey: .id))
        self.id = id ?? UUID().uuidString

        self.name = try? c.decodeIfPresent(String.self, forKey: .name)
        self.age = try? c.decodeIfPresent(Int.self, forKey: .age)
        self.email = try? c.decodeIfPresent(String.self, forKey: .email)
        self.avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        self.coverImageUrl = try? c.decodeIfPresent(String.self, forKey: .coverImageUrl)
        self.location = try? c.decodeIfPresent(String.self, forKey: .location)
        self.distance = try? c.decodeIfPresent(String.self, forKey: .distance)
        self.bio = try? c.decodeIfPresent(String.self, forKey: .bio)
        self.about = try? c.decodeIfPresent(String.self, forKey: .about)
        self.sportsInterests = try? c.decodeIfPresent([String].self, forKey: .sportsInterests)
        self.sports = try? c.decodeIfPresent([Sport].self, forKey: .sports)
        self.interests = try? c.decodeIfPresent([String].self, forKey: .interests)
        self.rating = try? c.decodeIfPresent(Int.self, forKey: .rating)
        self.activitiesJoined = try? c.decodeIfPresent(Int.self, forKey: .activitiesJoined)
        self.profileImageUrl = try? c.decodeIfPresent(String.self, forKey: .profileImageUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, name, age, email, avatarUrl, coverImageUrl, location, distance, bio, about
        case sportsInterests, sports, interests, rating, activitiesJoined, profileImageUrl
    }
}

struct ProfilesResponse: Decodable, Equatable {
    let profiles: [Profile]
    let pagination: Pagination
}

struct Pagination: Decodable, Equatable {
    let total: Int
    let page: Int
    let totalPages: Int
    let limit: Int
}

struct LikeRequest: Encodable {
    let profileId: String
}

struct PassRequest: Encodable {
    let profileId: String
}

struct LikeResponse: Decodable, Equatable {
    let isMatch: Bool
    let matchedProfile: Profile?
}

struct Match: Decodable, Identifiable, Equatable {
    let matchId: String
    let user: MatchUser
    let hasChatted: Bool
    let chatId: String?
    let createdAt: String

    var id: String { matchId }
}

struct MatchUser: Decodable, Equatable {
    let id: String
    let name: String?
    let email: String?
    let profileImageUrl: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? c.decodeIfPresent(String.self, forKey: ._id))
            ?? (try? c.decodeIfPresent(String.self, forKey: .id))
        self.id = id ?? UUID().uuidString
        self.name = try? c.decodeIfPresent(String.self, forKey: .name)
        self.email = try? c.decodeIfPresent(String.self, forKey: .email)
        self.profileImageUrl = try? c.decodeIfPresent(String.self, forKey: .profileImageUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, name, email, profileImageUrl
    }
}

struct LikesReceivedResponse: Decodable, Equatable {
    let likes: [LikeReceived]
}

struct LikeReceived: Decodable, Identifiable, Equatable {
    let likeId: String
    let fromUser: LikeUser
    let isMatch: Bool
    let matchId: String?
    let createdAt: String

    var id: String { likeId }
}

struct LikeUser: Decodable, Equatable {
    let id: String
    let name: String?
    let profileImageUrl: String?
    let avatarUrl: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? c.decodeIfPresent(String.self, forKey: ._id))
            ?? (try? c.decodeIfPresent(String.self, forKey: .id))
        self.id = id ?? UUID().uuidString
        self.name = try? c.decodeIfPresent(String.self, forKey: .name)
        self.profileImageUrl = try? c.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, name, profileImageUrl, avatarUrl
    }
}
