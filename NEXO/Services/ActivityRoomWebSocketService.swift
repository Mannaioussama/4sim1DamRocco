import Foundation
import SocketIO

protocol ActivityRoomWebSocketDelegate: AnyObject {
    func activityRoomDidReceiveMessage(_ message: ActivityRoomIncomingMessage)
    func activityRoomDidUpdateConnectionState(_ isConnected: Bool)
    func activityRoomDidUpdateTyping(userId: String, isTyping: Bool)
    func activityRoomDidReceiveUserJoined(userId: String)
    func activityRoomDidReceiveUserLeft(userId: String)
}

struct ActivityRoomIncomingMessage: Codable, Identifiable {
    let id: String
    let _id: String?
    let activity: String
    let sender: ActivityRoomMessageSender?
    let content: String
    let createdAt: String

    var identifier: String { id }

    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case activity
        case sender
        case content
        case createdAt
    }

    var displayId: String { id.isEmpty ? (_id ?? UUID().uuidString) : id }
}

struct ActivityRoomMessageSender: Codable {
    let id: String
    let _id: String?
    let name: String
    let profileImageUrl: String?
}

struct ActivityRoomJoinRequest: Codable {
    let activityId: String
}

struct ActivityRoomSendMessageRequest: Codable {
    let activityId: String
    let content: String
}

struct ActivityRoomTypingRequest: Codable {
    let activityId: String
    let isTyping: Bool
}

struct ActivityRoomUserTypingEvent: Codable {
    let userId: String
    let isTyping: Bool
}

struct ActivityRoomUserJoinedEvent: Codable {
    let userId: String
    let activityId: String
}

struct ActivityRoomUserLeftEvent: Codable {
    let userId: String
    let activityId: String
}

final class ActivityRoomWebSocketService {
    static let shared = ActivityRoomWebSocketService()

    private var socket: SocketIOClient?
    private var manager: SocketManager?
    private weak var delegate: ActivityRoomWebSocketDelegate?

    private var currentActivityId: String?
    private var isConnected: Bool = false {
        didSet { delegate?.activityRoomDidUpdateConnectionState(isConnected) }
    }

    private init() {}

    func setDelegate(_ delegate: ActivityRoomWebSocketDelegate?) {
        self.delegate = delegate
    }

    func connect(activityId: String) {
        if socket?.status == .connected, currentActivityId == activityId {
            return
        }

        if currentActivityId != activityId {
            disconnect()
        }

        let url = APIConfig.baseURL

        guard let token = AuthStore.shared.accessToken(), !token.isEmpty else {
            print("❌ ActivityRoom WS: missing auth token")
            return
        }

        let config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .forceWebsockets(true),
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(1_000),
            .connectParams(["token": token]),
            .extraHeaders(["Authorization": "Bearer \(token)"])
        ]

        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.socket(forNamespace: "/activity-room")
        currentActivityId = activityId

        setupEventHandlers()
        socket?.connect()
    }

    func disconnect() {
        if let activityId = currentActivityId {
            leaveActivity(activityId: activityId)
        }
        socket?.disconnect()
        socket = nil
        manager = nil
        currentActivityId = nil
        isConnected = false
    }

    private func setupEventHandlers() {
        guard let socket else { return }

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self else { return }
            print("✅ ActivityRoom WS: connected")
            self.isConnected = true
            if let activityId = self.currentActivityId {
                self.joinActivity(activityId: activityId)
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            print("❌ ActivityRoom WS: disconnected \(data)")
            self?.isConnected = false
        }

        socket.on(clientEvent: .error) { [weak self] data, _ in
            print("❌ ActivityRoom WS: error \(data)")
            self?.isConnected = false
        }

        socket.on("new-message") { [weak self] data, _ in
            guard let self else { return }
            guard let dict = (data.first as? [String: Any]) else { return }
            do {
                let json = try JSONSerialization.data(withJSONObject: dict)
                let message = try JSONDecoder().decode(ActivityRoomIncomingMessage.self, from: json)
                self.delegate?.activityRoomDidReceiveMessage(message)
            } catch {
                print("❌ ActivityRoom WS: failed to decode new-message: \(error)")
            }
        }

        socket.on("user-typing") { [weak self] data, _ in
            guard let self else { return }
            guard let dict = (data.first as? [String: Any]) else { return }
            do {
                let json = try JSONSerialization.data(withJSONObject: dict)
                let evt = try JSONDecoder().decode(ActivityRoomUserTypingEvent.self, from: json)
                self.delegate?.activityRoomDidUpdateTyping(userId: evt.userId, isTyping: evt.isTyping)
            } catch {
                print("❌ ActivityRoom WS: failed to decode user-typing: \(error)")
            }
        }

        socket.on("user-joined") { [weak self] data, _ in
            guard let self else { return }
            guard let dict = (data.first as? [String: Any]) else { return }
            do {
                let json = try JSONSerialization.data(withJSONObject: dict)
                let evt = try JSONDecoder().decode(ActivityRoomUserJoinedEvent.self, from: json)
                self.delegate?.activityRoomDidReceiveUserJoined(userId: evt.userId)
            } catch {
                print("❌ ActivityRoom WS: failed to decode user-joined: \(error)")
            }
        }

        socket.on("user-left") { [weak self] data, _ in
            guard let self else { return }
            guard let dict = (data.first as? [String: Any]) else { return }
            do {
                let json = try JSONSerialization.data(withJSONObject: dict)
                let evt = try JSONDecoder().decode(ActivityRoomUserLeftEvent.self, from: json)
                self.delegate?.activityRoomDidReceiveUserLeft(userId: evt.userId)
            } catch {
                print("❌ ActivityRoom WS: failed to decode user-left: \(error)")
            }
        }
    }

    private func joinActivity(activityId: String) {
        let req = ActivityRoomJoinRequest(activityId: activityId)
        emit(event: "join-activity", payload: req)
    }

    private func leaveActivity(activityId: String) {
        let req = ActivityRoomJoinRequest(activityId: activityId)
        emit(event: "leave-activity", payload: req)
    }

    func sendMessage(activityId: String, content: String) {
        guard socket?.status == .connected else {
            print("⚠️ ActivityRoom WS: cannot send message, not connected")
            return
        }
        let req = ActivityRoomSendMessageRequest(activityId: activityId, content: content)
        emit(event: "send-message", payload: req)
    }

    func setTyping(activityId: String, isTyping: Bool) {
        guard socket?.status == .connected else { return }
        let req = ActivityRoomTypingRequest(activityId: activityId, isTyping: isTyping)
        emit(event: "typing", payload: req)
    }

    private func emit<T: Encodable>(event: String, payload: T) {
        guard let socket else { return }
        do {
            let data = try JSONEncoder().encode(payload)
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            socket.emit(event, obj ?? [:])
        } catch {
            print("❌ ActivityRoom WS: failed to encode payload for \(event): \(error)")
        }
    }

    func connectionStatus() -> Bool {
        return isConnected && socket?.status == .connected
    }
}
