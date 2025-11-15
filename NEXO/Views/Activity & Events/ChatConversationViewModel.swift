//
//  ChatConversationViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

class ChatConversationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var isInputFocused: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    
    let chatId: String
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(chatId: String) {
        self.chatId = chatId
        loadMessages()
        markAsRead()
    }
    
    deinit {
        loadTask?.cancel()
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
    
    private func markAsRead() {
        Task {
            do {
                try await ChatAPI.markChatAsRead(chatId: chatId)
            } catch {
                print("markAsRead failed: \(error)")
            }
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
    
    func dismissKeyboard() {
        isInputFocused = false
    }
}

