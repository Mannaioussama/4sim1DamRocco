// Services & Auth/ChatAPI.swift
import Foundation

enum ChatAPI {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Core request

    private static func authorizedRequest(url: URL, method: String, body: Data? = nil) throws -> URLRequest {
        guard let token = AuthStore.shared.accessToken(), !token.isEmpty else {
            throw APIError(statusCode: 401, message: "Not authenticated. Please log in.")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body { req.httpBody = body }
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

    static func fetchChats(search: String?) async throws -> [ChatListItemDTO] {
        var comps = URLComponents(url: APIConfig.endpoint("/chats"), resolvingAgainstBaseURL: false)!
        if let q = search, !q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            comps.queryItems = [URLQueryItem(name: "search", value: q)]
        }
        let req = try authorizedRequest(url: comps.url!, method: "GET")
        return try await send(req)
    }

    static func fetchMessages(chatId: String) async throws -> [ChatMessageDTO] {
        let url = APIConfig.endpoint("/chats/\(chatId)/messages")
        let req = try authorizedRequest(url: url, method: "GET")
        return try await send(req)
    }

    static func sendMessage(chatId: String, text: String) async throws -> ChatMessageDTO {
        let url = APIConfig.endpoint("/chats/\(chatId)/messages")
        let body = try encoder.encode(SendMessageRequest(text: text))
        let req = try authorizedRequest(url: url, method: "POST", body: body)
        return try await send(req)
    }

    static func markChatAsRead(chatId: String) async throws {
        let url = APIConfig.endpoint("/chats/\(chatId)/read")
        let req = try authorizedRequest(url: url, method: "PATCH")
        // Ignore response body; treat 2xx as success
        let _: MessageResponse = try await send(req)
    }

    static func createChat(_ body: CreateChatRequest) async throws -> ChatDetailDTO {
        let url = APIConfig.endpoint("/chats")
        let req = try authorizedRequest(url: url, method: "POST", body: try encoder.encode(body))
        return try await send(req)
    }

    static func deleteChat(chatId: String) async throws -> MessageResponse {
        let url = APIConfig.endpoint("/chats/\(chatId)")
        let req = try authorizedRequest(url: url, method: "DELETE")
        return try await send(req)
    }

    static func deleteMessage(messageId: String) async throws -> MessageResponse {
        let url = APIConfig.endpoint("/chats/messages/\(messageId)")
        let req = try authorizedRequest(url: url, method: "DELETE")
        return try await send(req)
    }

    // New: search users by name (tolerant to backend key names)
    static func searchUsers(query: String) async throws -> [UserSearchDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        var comps = URLComponents(url: APIConfig.endpoint("/users/search"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "search", value: trimmed)]
        let req = try authorizedRequest(url: comps.url!, method: "GET")
        return try await send(req)
    }
}

// MARK: - DTOs

// Use this if an endpoint returns 204/empty body but we still need to decode generically
private struct EmptyDecodable: Decodable {}

// Request to send a message
struct SendMessageRequest: Encodable {
    let text: String
}

struct ChatListItemDTO: Decodable, Identifiable {
    let id: String
    let participantNames: String
    let participantAvatars: [String]
    let lastMessage: String
    let lastMessageTime: String
    let unreadCount: Int
    let isGroup: Bool

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? c.decodeIfPresent(String.self, forKey: .id))
            ?? (try? c.decodeIfPresent(String.self, forKey: ._id))
        self.id = id ?? ""
        self.participantNames = (try? c.decode(String.self, forKey: .participantNames)) ?? ""
        self.participantAvatars = (try? c.decode([String].self, forKey: .participantAvatars)) ?? []
        self.lastMessage = (try? c.decode(String.self, forKey: .lastMessage)) ?? ""
        self.lastMessageTime = (try? c.decode(String.self, forKey: .lastMessageTime)) ?? ""
        self.unreadCount = (try? c.decode(Int.self, forKey: .unreadCount)) ?? 0
        self.isGroup = (try? c.decode(Bool.self, forKey: .isGroup)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, participantNames, participantAvatars, lastMessage, lastMessageTime, unreadCount, isGroup
    }
}

struct ChatMessageDTO: Decodable, Identifiable {
    let id: String
    let text: String
    let sender: String       // "me" or "other"
    let time: String         // already formatted or derived from createdAt
    let senderName: String?
    let avatar: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Try UI shape first (sender as string)
        if let senderStr = try? c.decode(String.self, forKey: .sender) {
            let id = (try? c.decodeIfPresent(String.self, forKey: .id))
                ?? (try? c.decodeIfPresent(String.self, forKey: ._id))
            self.id = id ?? ""
            self.text = (try? c.decode(String.self, forKey: .text)) ?? ""
            self.sender = senderStr
            self.time = (try? c.decode(String.self, forKey: .time)) ?? ""
            self.senderName = try? c.decodeIfPresent(String.self, forKey: .senderName)
            self.avatar = try? c.decodeIfPresent(String.self, forKey: .avatar)
            return
        }

        // Fallback to DB shape (sender object + createdAt)
        let id = (try? c.decodeIfPresent(String.self, forKey: .id))
            ?? (try? c.decodeIfPresent(String.self, forKey: ._id))
        self.id = id ?? ""
        self.text = (try? c.decode(String.self, forKey: .text)) ?? ""

        if let senderObj = try? c.decodeIfPresent(SenderObj.self, forKey: .sender) {
            self.senderName = senderObj.name
            self.avatar = senderObj.profileImageUrl
        } else {
            self.senderName = nil
            self.avatar = nil
        }

        let createdAtOpt: String? = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        self.time = createdAtOpt.map { ChatMessageDTO.formatTime($0) } ?? ""

        // For send responses, assume the current user
        self.sender = "me"
    }

    private struct SenderObj: Decodable {
        let id: String?
        let _id: String?
        let name: String?
        let email: String?
        let profileImageUrl: String?
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, text, sender, time, senderName, avatar, createdAt
    }

    private static func formatTime(_ iso: String) -> String {
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let altIsoFmt = ISO8601DateFormatter()
        altIsoFmt.formatOptions = [.withInternetDateTime]
        let date = isoFmt.date(from: iso) ?? altIsoFmt.date(from: iso)
        guard let d = date else { return iso }
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "h:mm a"
        return out.string(from: d)
    }
}

// Create chat
struct CreateChatRequest: Encodable {
    let participantIds: [String]
    let groupName: String?
    let groupAvatar: String?
}

// Minimal detail (expand later if needed)
struct ChatDetailDTO: Decodable {
    let id: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? c.decodeIfPresent(String.self, forKey: .id))
            ?? (try? c.decodeIfPresent(String.self, forKey: ._id))
        self.id = id ?? ""
    }

    private enum CodingKeys: String, CodingKey { case id, _id }
}

// User search result (tolerant keys)
struct UserSearchDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let avatar: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? c.decodeIfPresent(String.self, forKey: .id))
            ?? (try? c.decodeIfPresent(String.self, forKey: ._id))
        self.id = id ?? ""

        // Accept name or username
        let name = (try? c.decodeIfPresent(String.self, forKey: .name))
            ?? (try? c.decodeIfPresent(String.self, forKey: .username))
        self.name = name ?? "Unknown"

        // Accept multiple avatar keys
        self.avatar =
            (try? c.decodeIfPresent(String.self, forKey: .profileImageUrl)) ??
            (try? c.decodeIfPresent(String.self, forKey: .avatar)) ??
            (try? c.decodeIfPresent(String.self, forKey: .profileImageThumbnailUrl))
    }

    private enum CodingKeys: String, CodingKey {
        case id, _id, name, username, profileImageUrl, profileImageThumbnailUrl, avatar
    }
}

// Reuse your existing MessageResponse in AuthModels.swift for { message } envelopes
// struct MessageResponse: Decodable { ... } already exists
