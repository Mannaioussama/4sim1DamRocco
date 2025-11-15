//
//  ActivityRoomViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import Combine

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
        switch self {
        case .chat: return "Chat"
        case .participants: return "People"
        case .ai: return "AI Tips"
        case .info: return "Info"
        }
    }
}

class ActivityRoomViewModel: ObservableObject {
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
    
    // States
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var spotsLeft: Int {
        return activity.spotsTotal - activity.spotsTaken
    }
    
    var navigationTitle: String {
        return "\(activity.sportType) Session"
    }
    
    var navigationSubtitle: String {
        return "Hosted by \(activity.hostName)"
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
        return "Starts in 2 hours" // TODO: Calculate actual time difference
    }
    
    var spotsLeftMessage: String {
        return "\(spotsLeft) spots left"
    }
    
    // MARK: - Initialization
    
    init(activity: RoomActivity) {
        self.activity = activity
        setupInitialData()
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupInitialData() {
        // Load initial messages
        messages = [
            ChatMessage(
                id: "1",
                sender: "Host",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Host",
                text: "Hey everyone! Looking forward to this session. Please arrive 5 minutes early.",
                time: "10:30 AM"
            ),
            ChatMessage(
                id: "2",
                sender: "Alex Thompson",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
                text: "Sounds great! What should I bring?",
                time: "10:45 AM"
            )
        ]
        
        // Load participants
        participants = [
            Participant(
                id: "1",
                name: activity.hostName,
                avatar: activity.hostAvatar,
                status: "Host"
            ),
            Participant(
                id: "2",
                name: "Alex Thompson",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
                status: "Joined"
            ),
            Participant(
                id: "3",
                name: "Emma Davis",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma",
                status: "Joined"
            ),
            Participant(
                id: "4",
                name: "Mike Johnson",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Mike",
                status: "Joined"
            )
        ]
    }
    
    private func setupObservers() {
        // Clear message errors when typing
        $message
            .sink { _ in
                // Could add validation here
            }
            .store(in: &cancellables)
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
        
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            sender: "You",
            avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=You",
            text: trimmedMessage,
            time: currentTime
        )
        
        messages.append(newMessage)
        message = ""
        
        // Dismiss keyboard after sending
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        // TODO: Send to backend
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
        // TODO: Open maps app
        trackDirectionsOpened()
        print("Opening directions to: \(activity.location)")
    }
    
    // MARK: - Refresh Functions
    
    @MainActor
    func refreshMessages() async {
        print("🔄 Refreshing chat messages...")
        isRefreshing = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Add a new mock message to show refresh worked
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            sender: "System",
            avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=System",
            text: "Messages refreshed at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short))",
            time: DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
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
    
    func trackActivityCompleted() {
        // TODO: Implement analytics tracking
        print("Activity completed: \(activity.id)")
    }
    
    func trackActivityShared() {
        // TODO: Implement analytics tracking
        print("Activity shared: \(activity.id)")
    }
    
    func trackDirectionsOpened() {
        // TODO: Implement analytics tracking
        print("Directions opened for: \(activity.location)")
    }
}
