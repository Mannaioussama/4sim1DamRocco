//
//  ChatConversationViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Foundation
import Combine

class ChatConversationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var isInputFocused: Bool = false
    @Published var isLoading: Bool = false
    @Published var participants: [ChatParticipant] = []
    @Published var isGroup: Bool = false
    @Published var sessionTitle: String = ""
    @Published var showLeaveConfirmation: Bool = false
    
    // MARK: - Properties
    
    let chatId: String
    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let realtimeService = RealtimeChatService.shared
    
    // MARK: - Initialization
    
    init(chatId: String) {
        self.chatId = chatId
        setupRealtimeSubscription()
        loadMessages()
        markAsRead()
        
        // Check if this is a group chat and load info
        Task {
            await loadGroupChatInfo()
        }
    }
    
    private func loadGroupChatInfo() async {
        do {
            let chats = try await ChatAPI.fetchChats(search: nil)
            if let dto = chats.first(where: { $0.id == chatId }) {
                await MainActor.run {
                    self.isGroup = dto.isGroup
                    // Use participantNames as the display title for the chat (activity or user name)
                    self.sessionTitle = dto.participantNames
                }
                // Always load participants so 1-to-1 chats can resolve the other user
                await loadParticipants()
            } else {
                await MainActor.run {
                    self.isGroup = false
                    self.sessionTitle = ""
                }
            }
        } catch {
            print("loadGroupChatInfo failed: \(error)")
        }
    }
    
    deinit {
        loadTask?.cancel()
        realtimeService.unsubscribeFromChat(chatId: chatId)
    }
    
    // MARK: - Data Loading
    
    private func loadMessages() {
        loadTask?.cancel()
        isLoading = true
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let dtos = try await ChatAPI.fetchMessages(chatId: self.chatId)
                let mapped: [Message] = dtos.map { dto in
                    Message(
                        id: dto.id,
                        text: dto.text,
                        sender: dto.sender.lowercased() == "me" ? .me : .other,
                        time: dto.time,
                        senderName: dto.senderName,
                        avatar: dto.avatar
                    )
                }
                await MainActor.run {
                    self.messages = mapped
                    self.isLoading = false
                }
            } catch let api as APIError {
                await MainActor.run {
                    self.isLoading = false
                    print("Load messages failed: \(api.userMessage)")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Load messages failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func dismissKeyboard() {
        isInputFocused = false
    }
    
    func markAsRead() {
        Task {
            do {
                try await ChatAPI.markChatAsRead(chatId: chatId)
            } catch {
                print("markAsRead failed: \(error)")
            }
        }
    }
    
    // MARK: - Group Chat Methods
    
    func loadParticipants() async {
        do {
            participants = try await ChatAPI.getChatParticipants(chatId: chatId)
        } catch {
            print("loadParticipants failed: \(error)")
        }
    }
    
    func leaveGroup() async {
        guard isGroup else { return }
        
        do {
            _ = try await ChatAPI.leaveGroupChat(chatId: chatId)
            // Navigate back or update UI will be handled by the view
        } catch {
            print("leaveGroup failed: \(error)")
        }
    }
    
    func setupGroupChat(sessionTitle: String, isGroup: Bool) {
        self.sessionTitle = sessionTitle
        self.isGroup = isGroup
        
        Task {
            await loadParticipants()
        }
    }
    
    // MARK: - Real-time Subscription (HTTP Polling)
    
    private func setupRealtimeSubscription() {
        print("🔥 ViewModel: Setting up realtime subscription for chat \(chatId)")
        
        // Connect to polling service
        realtimeService.connect()
        print("🔥 ViewModel: Connected to polling service")
        
        // Subscribe to new messages for this chat
        realtimeService.subscribeToChat(chatId: chatId)
            .sink { [weak self] newMessageDTO in
                print("🔥 ViewModel: Received message in sink: \(newMessageDTO.text)")
                self?.handleNewMessage(newMessageDTO)
            }
            .store(in: &cancellables)
        
        print("🔥 ViewModel: Subscription setup complete")
    }
    
    private func handleNewMessage(_ dto: ChatMessageDTO) {
        print("🔥 ViewModel: Handling message: \(dto.text)")
        
        // Check if this message already exists (avoid duplicates)
        if messages.contains(where: { $0.id == dto.id }) {
            print("🔥 ViewModel: Message already exists, skipping")
            return
        }
        
        let newMessage = Message(
            id: dto.id,
            text: dto.text,
            sender: dto.sender.lowercased() == "me" ? .me : .other,
            time: dto.time,
            senderName: dto.senderName,
            avatar: dto.avatar
        )
        
        DispatchQueue.main.async { [weak self] in
            print("🔥 ViewModel: Adding message to UI: \(newMessage.text)")
            self?.messages.append(newMessage)
            print("🔥 ViewModel: Total messages: \(self?.messages.count ?? 0)")
        }
    }
    
    // MARK: - Actions
    
    func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // 1) Optimistically append a local message so the UI updates immediately.
        let tempId = "local-\(UUID().uuidString)"
        let now = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        let optimistic = Message(
            id: tempId,
            text: trimmedText,
            sender: .me,
            time: now,
            senderName: nil,
            avatar: nil
        )
        messages.append(optimistic)
        
        // Clear the input and dismiss keyboard right away
        messageText = ""
        isInputFocused = false
        
        // 2) Send to server; replace the optimistic item with the confirmed one.
        Task { [weak self] in
            guard let self else { return }
            do {
                let dto = try await ChatAPI.sendMessage(chatId: self.chatId, text: trimmedText)
                let confirmed = Message(
                    id: dto.id,
                    text: dto.text,
                    sender: .me, // our own message
                    time: dto.time,
                    senderName: nil,
                    avatar: nil
                )
                await MainActor.run {
                    if let idx = self.messages.firstIndex(where: { $0.id == tempId }) {
                        self.messages[idx] = confirmed
                    } else {
                        // Fallback: if the optimistic one isn't found, just append
                        self.messages.append(confirmed)
                    }
                }
            } catch let api as APIError {
                await MainActor.run {
                    print("Send message failed: \(api.userMessage)")
                    // Keep the optimistic bubble so UI doesn't feel broken.
                    // Optionally: mark as failed or show a retry UI.
                }
            } catch {
                await MainActor.run {
                    print("Send message failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func getLastMessageId() -> String? {
        return messages.last?.id
    }

    var otherParticipant: ChatParticipant? {
        // Only show a profile when we can reliably identify "me" and "the other".
        guard !participants.isEmpty else { return nil }
        guard let currentId = AuthTokenManager.shared.getUserId() else { return nil }
        // For 1:1 chats there should be exactly one participant whose id != current user id.
        return participants.first(where: { $0.id != currentId })
    }

    /// Display name for the other side of the conversation in direct chats.
    /// Prefers the resolved participant name, then the chat title from the list,
    /// then the first other sender name from messages.
    var directChatDisplayName: String {
        if let other = otherParticipant { return other.name }
        if !sessionTitle.isEmpty { return sessionTitle }
        if let msg = messages.first(where: { $0.sender == .other }), let name = msg.senderName, !name.isEmpty {
            return name
        }
        return "Conversation"
    }

    /// Fallback participant used for the profile popup in direct chats.
    /// If we cannot resolve a real ChatParticipant from the participants API,
    /// we synthesize one from the display name and the first other-message avatar.
    var directChatPopupParticipant: ChatParticipant? {
        if let other = otherParticipant { return other }
        let name = directChatDisplayName
        guard name != "Conversation" else { return nil }
        let avatar = messages.first(where: { $0.sender == .other })?.avatar
        return ChatParticipant(
            id: "",
            name: name,
            email: nil,
            profileImageUrl: avatar,
            avatar: avatar,
            about: nil,
            sportsInterests: nil
        )
    }
}
