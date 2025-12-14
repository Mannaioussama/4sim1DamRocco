//
//  ActivityRoomViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import Combine
import Foundation
import MapKit
import CoreLocation

// MARK: - Data Models
struct RoomActivity: Identifiable, Equatable {
    let id: String
    let sportType: String
    let title: String
    let description: String
    let location: String
    let date: String
    let time: String
    let hostName: String
    let hostAvatar: String
    let spotsTotal: Int
    let spotsTaken: Int
    let level: String
    let latitude: Double?
    let longitude: Double?
}

// MARK: - Backend Models (REST)

struct ActivityRoomHistoryMessage: Codable {
    let id: String
    let activity: String
    let sender: ActivityRoomMessageSender?
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case activity
        case sender
        case content
        case createdAt
    }
}

struct ActivityRoomMessagesResponse: Codable {
    let messages: [ActivityRoomHistoryMessage]
}

struct ActivityRoomParticipantDTO: Codable {
    let id: String
    let name: String?
    let profileImageUrl: String?
    let isHost: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case profileImageUrl
        case isHost
    }
}

struct ActivityRoomParticipantsResponse: Codable {
    let participants: [ActivityRoomParticipantDTO]
}

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let sender: String
    let avatar: String
    let text: String
    let time: String
}

struct Participant: Identifiable, Equatable {
    let id: String
    let name: String
    let avatar: String
    let status: String
}

enum ActivityTab: String, CaseIterable {
    case chat = "chat"
    case participants = "participants"
    case ai = "ai"
    case info = "info"
    
    var label: String {
        let l = LocalizationManager.shared
        switch self {
        case .chat:
            return l.localized("activityRoom.tab.chat")
        case .participants:
            return l.localized("activityRoom.tab.participants")
        case .ai:
            return l.localized("activityRoom.tab.ai")
        case .info:
            return l.localized("activityRoom.tab.info")
        }
    }
}

class ActivityRoomViewModel: ObservableObject, ActivityRoomWebSocketDelegate {
    // MARK: - Published Properties
    
    let activity: RoomActivity
    
    @Published var selectedTab: ActivityTab = .chat
    @Published var message: String = ""
    @Published var messages: [ChatMessage] = []
    @Published var participants: [Participant] = []
    @Published var aiTips: [String] = []
    @Published var isRefreshing: Bool = false
    @Published var isLoading: Bool = false
    @Published var showLeaveConfirmation: Bool = false
    @Published var showCompleteConfirmation: Bool = false
    @Published var showingDirectionsAlert: Bool = false
    
    // States
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let websocketService = ActivityRoomWebSocketService.shared
    private let localization = LocalizationManager.shared
    
    // MARK: - Computed Properties
    
    var spotsLeft: Int {
        return activity.spotsTotal - activity.spotsTaken
    }
    
    var navigationTitle: String {
        let format = localization.localized("activityRoom.nav.title.format")
        return String(format: format, activity.sportType)
    }
    
    var navigationSubtitle: String {
        let format = localization.localized("activityRoom.nav.subtitle.format")
        return String(format: format, activity.hostName)
    }
    
    var canSendMessage: Bool {
        return !message.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
    
    var hasMessages: Bool {
        return !messages.isEmpty
    }
    
    var hasParticipants: Bool {
        return !participants.isEmpty
    }
    
    var participantCount: Int {
        return participants.count
    }
    
    var isChatTab: Bool {
        return selectedTab == .chat
    }
    
    var isParticipantsTab: Bool {
        return selectedTab == .participants
    }
    
    var isAITab: Bool {
        return selectedTab == .ai
    }
    
    var isInfoTab: Bool {
        return selectedTab == .info
    }
    
    var startTimeMessage: String {
        // TODO: Calculate actual time difference
        return localization.localized("activityRoom.info.startsInPlaceholder")
    }
    
    var spotsLeftMessage: String {
        let suffix = localization.localized("activityRoom.info.spotsLeftSuffix")
        return "\(spotsLeft) \(suffix)"
    }
    
    // MARK: - Initialization
    
    init(activity: RoomActivity) {
        self.activity = activity
        setupInitialData()
        setupObservers()
        websocketService.setDelegate(self)
        websocketService.connect(activityId: activity.id)
        
        // Load history messages from backend
        Task { [weak self] in
            await self?.loadHistoryMessages()
            await self?.loadParticipants()
        }
    }
    
    deinit {
        websocketService.setDelegate(nil)
        websocketService.disconnect()
    }
    
    // MARK: - Setup
    
    private func setupInitialData() {
        participants = []
    }
    
    private func setupObservers() {
        // Clear message errors when typing
        $message
            .sink { _ in
                // Could add validation here
            }
            .store(in: &cancellables)
    }

    // MARK: - History Loading (REST)
    
    private func loadHistoryMessages() async {
        guard let token = AuthStore.shared.accessToken(), !token.isEmpty else {
            print("❌ ActivityRoom: missing auth token for history fetch")
            return
        }
        
        let url = APIConfig.endpoint("activities/\(activity.id)/messages")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                if let raw = String(data: data, encoding: .utf8) {
                    print("❌ ActivityRoom: history non-200 response: \(raw)")
                }
                return
            }
            let decoder = JSONDecoder()
            let history = try decoder.decode(ActivityRoomMessagesResponse.self, from: data)
            let converted = history.messages.map { msg -> ChatMessage in
                let senderName = msg.sender?.name
                    ?? localization.localized("activityRoom.participant.genericName")
                let avatar = msg.sender?.profileImageUrl ?? "https://api.dicebear.com/7.x/avataaars/svg?seed=Participant"
                
                let timeString: String
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: msg.createdAt) {
                    timeString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
                } else {
                    timeString = msg.createdAt
                }
                
                return ChatMessage(
                    id: msg.id,
                    sender: senderName,
                    avatar: avatar,
                    text: msg.content,
                    time: timeString
                )
            }
            await MainActor.run {
                self.messages = converted
            }
        } catch {
            print("❌ ActivityRoom: failed to load history messages: \(error)")
        }
    }

    // MARK: - Participants Loading (REST)
    
    private func loadParticipants() async {
        guard let token = AuthStore.shared.accessToken(), !token.isEmpty else {
            print("❌ ActivityRoom: missing auth token for participants fetch")
            return
        }
        
        let url = APIConfig.endpoint("activities/\(activity.id)/participants")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                if let raw = String(data: data, encoding: .utf8) {
                    print("❌ ActivityRoom: participants non-200 response: \(raw)")
                }
                return
            }
            let decoder = JSONDecoder()
            let result = try decoder.decode(ActivityRoomParticipantsResponse.self, from: data)
            let mapped = result.participants.map { dto -> Participant in
                let name = dto.name ?? localization.localized("activityRoom.participant.genericName")
                let avatar = dto.profileImageUrl ?? "https://api.dicebear.com/7.x/avataaars/svg?seed=\(name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "Participant")"
                let status = dto.isHost
                    ? localization.localized("activityRoom.participants.status.host")
                    : localization.localized("activityRoom.participants.status.joined")
                return Participant(
                    id: dto.id,
                    name: name,
                    avatar: avatar,
                    status: status
                )
            }
            await MainActor.run {
                self.participants = mapped
            }
        } catch {
            print("❌ ActivityRoom: failed to load participants: \(error)")
        }
    }
    
    // MARK: - Tab Management
    
    func selectTab(_ tab: ActivityTab) {
        selectedTab = tab
    }
    
    func isTabSelected(_ tab: ActivityTab) -> Bool {
        return selectedTab == tab
    }
    
    // MARK: - Chat Management
    
    func sendMessage() {
        guard canSendMessage else { return }
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespaces)
        let currentTime = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        let youLabel = localization.localized("chat.sender.you")
        
        // Optimistically append a local message
        let optimistic = ChatMessage(
            id: UUID().uuidString,
            sender: youLabel,
            avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=You",
            text: trimmedMessage,
            time: currentTime
        )
        
        messages.append(optimistic)
        message = ""
        
        // Dismiss keyboard after sending
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        // Send to backend via WebSocket
        websocketService.sendMessage(activityId: activity.id, content: trimmedMessage)
        trackMessageSent()
    }
    
    func clearMessage() {
        message = ""
    }
    
    // MARK: - Participant Actions
    
    func messageParticipant(_ participant: Participant) {
        // TODO: Open chat with participant
        print("Opening chat with: \(participant.name)")
        trackParticipantMessaged(participant)
    }
    
    func getParticipantInitial(_ participant: Participant) -> String {
        return String(participant.name.prefix(1))
    }
    
    func isHost(_ participant: Participant) -> Bool {
        return participant.status == "Host"
    }
    
    // MARK: - Activity Actions
    
    func showLeaveDialog() {
        showLeaveConfirmation = true
    }
    
    func leaveActivity(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.showLeaveConfirmation = false
            trackActivityLeft()
            onSuccess()
        }
    }
    
    func cancelLeave() {
        showLeaveConfirmation = false
    }
    
    func showCompleteDialog() {
        showCompleteConfirmation = true
    }
    
    func markComplete(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.showCompleteConfirmation = false
            trackActivityCompleted()
            onSuccess()
        }
    }
    
    func cancelComplete() {
        showCompleteConfirmation = false
    }
    
    func shareActivity() {
        // TODO: Implement share functionality
        trackActivityShared()
        print("Sharing activity: \(activity.title)")
    }
    
    func getDirections() {
        showingDirectionsAlert = true
        trackDirectionsOpened()
        print("Directions requested for: \(activity.location)")
    }

    func openInAppleMaps() {
        if let lat = activity.latitude, let lon = activity.longitude {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let placemark = MKPlacemark(coordinate: coord)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = activity.location
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
            return
        }

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(activity.location) { placemarks, error in
            if let coord = placemarks?.first?.location?.coordinate {
                let placemark = MKPlacemark(coordinate: coord)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = self.activity.location
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            } else {
                let message = error?.localizedDescription ?? "Unknown error"
                print("Unable to geocode address for directions: \(message)")
            }
        }
    }
    
    func openInGoogleMaps() {
        func open(for coordinate: CLLocationCoordinate2D) {
            let url = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")!
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                let webUrl = URL(string: "https://maps.google.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")!
                UIApplication.shared.open(webUrl)
            }
        }

        if let lat = activity.latitude, let lon = activity.longitude {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            open(for: coord)
            return
        }

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(activity.location) { placemarks, error in
            if let coord = placemarks?.first?.location?.coordinate {
                open(for: coord)
            } else {
                let message = error?.localizedDescription ?? "Unknown error"
                print("Unable to geocode address for Google Maps directions: \(message)")
            }
        }
    }
    
    // MARK: - Refresh Functions
    
    @MainActor
    func refreshMessages() async {
        print("🔄 Refreshing chat messages...")
        isRefreshing = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Add a new mock message to show refresh worked
        let timeString = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        let systemLabel = localization.localized("chat.sender.system")
        let textFormat = localization.localized("chat.system.refreshMessage")
        let bodyText = String(format: textFormat, timeString)
        
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            sender: systemLabel,
            avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=System",
            text: bodyText,
            time: timeString
        )
        
        messages.append(newMessage)
        isRefreshing = false
        print("✅ Messages refreshed successfully")
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Activity room viewed: \(activity.id)")
    }
    
    func trackTabChanged(_ tab: ActivityTab) {
        // TODO: Implement analytics tracking
        print("Tab changed to: \(tab.rawValue)")
    }
    
    func trackMessageSent() {
        // TODO: Implement analytics tracking
        print("Message sent in activity: \(activity.id)")
    }
    
    func trackParticipantMessaged(_ participant: Participant) {
        // TODO: Implement analytics tracking
        print("Participant messaged: \(participant.name)")
    }
    
    func trackActivityLeft() {
        // TODO: Implement analytics tracking
        print("Activity left: \(activity.id)")
    }
    
    func trackActivityShared() {
        // TODO: Implement analytics tracking
        print("Activity shared: \(activity.id)")
    }
    
    func trackDirectionsOpened() {
        // TODO: Implement analytics tracking
        print("Directions opened for: \(activity.location)")
    }
    
    func trackActivityCompleted() {
        // TODO: Implement analytics tracking
        print("Activity completed: \(activity.id)")
    }

// ... (rest of the code remains the same)
    
    // MARK: - ActivityRoomWebSocketDelegate
    
    func activityRoomDidReceiveMessage(_ message: ActivityRoomIncomingMessage) {
        let senderName = message.sender?.name ?? "Participant"
        let avatar = message.sender?.profileImageUrl ?? "https://api.dicebear.com/7.x/avataaars/svg?seed=Participant"
        
        let timeString: String
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: message.createdAt) {
            timeString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        } else {
            timeString = message.createdAt
        }
        
        let chatMessage = ChatMessage(
            id: message.displayId,
            sender: senderName,
            avatar: avatar,
            text: message.content,
            time: timeString
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.messages.contains(where: { $0.id == chatMessage.id }) {
                self.messages.append(chatMessage)
            }
        }
    }
    
    func activityRoomDidUpdateConnectionState(_ isConnected: Bool) {
        // Could be used later to reflect connection state in the UI.
        print("ActivityRoom connection state: \(isConnected)")
    }
    
    func activityRoomDidUpdateTyping(userId: String, isTyping: Bool) {
        // Typing indicators can be added later if needed.
        print("User \(userId) typing: \(isTyping)")
    }
    
    func activityRoomDidReceiveUserJoined(userId: String) {
        print("User joined activity room: \(userId)")
    }
    
    func activityRoomDidReceiveUserLeft(userId: String) {
        print("User left activity room: \(userId)")
    }
}
