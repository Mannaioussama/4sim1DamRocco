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
    
    // MARK: - Properties
    
    let chatId: String
    
    // MARK: - Initialization
    
    init(chatId: String) {
        self.chatId = chatId
        loadMessages()
    }
    
    // MARK: - Data Loading
    
    private func loadMessages() {
        // Mock messages - In production, this would fetch from your data source
        messages = [
            Message(
                id: "1",
                text: "Hey! Are we still on for swimming tomorrow?",
                sender: .other,
                time: "10:30 AM",
                senderName: "Sarah Mitchell",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah"
            ),
            Message(
                id: "2",
                text: "Yes! 7 AM at City Pool 💪",
                sender: .me,
                time: "10:32 AM",
                senderName: nil,
                avatar: nil
            ),
            Message(
                id: "3",
                text: "Perfect! I'll bring extra goggles in case anyone needs them",
                sender: .other,
                time: "10:33 AM",
                senderName: "Sarah Mitchell",
                avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah"
            ),
            Message(
                id: "4",
                text: "Great idea! See you there 🏊",
                sender: .me,
                time: "10:35 AM",
                senderName: nil,
                avatar: nil
            )
        ]
    }
    
    // MARK: - Actions
    
    func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        
        // Create new message
        let newMessage = Message(
            id: UUID().uuidString,
            text: trimmedText,
            sender: .me,
            time: getCurrentTime(),
            senderName: nil,
            avatar: nil
        )
        
        // Add to messages array
        messages.append(newMessage)
        
        // TODO: Send message to backend/database
        print("Sending message: \(trimmedText)")
        
        // Clear input
        messageText = ""
        isInputFocused = false
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
    
    func getLastMessageId() -> String? {
        return messages.last?.id
    }
}
