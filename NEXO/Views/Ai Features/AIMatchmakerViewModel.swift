//
//  AIMatchmakerViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct AIMatchMessage: Identifiable {
    let id: String
    let type: AIMatchMessageType
    let text: String?
    let options: [String]?

    init(id: String, type: AIMatchMessageType, text: String?, options: [String]? = nil) {
        self.id = id
        self.type = type
        self.text = text
        self.options = options
    }
}

enum AIMatchMessageType {
    case ai
    case user
}

class AIMatchmakerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var messages: [AIMatchMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    
    // MARK: - Private Properties
    
    private var conversationContext: [String: Any] = [:]
    
    // MARK: - Computed Properties
    
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var lastMessageId: String? {
        return messages.last?.id
    }
    
    // MARK: - Initialization
    
    init() {
        loadInitialMessage()
    }
    
    // MARK: - Data Loading
    
    private func loadInitialMessage() {
        messages = [
            AIMatchMessage(
                id: "1",
                type: .ai,
                text: "Hi! I'm your AI matchmaker. I can help you find the perfect sport partners or activities. What would you like to do today?",
                options: ["Find a running partner", "Join a group activity", "Discover new sports"]
            )
        ]
    }
    
    // MARK: - Message Handling
    
    func handleOptionSelect(_ option: String) {
        addUserMessage(option)
        
        // Simulate AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.generateAIResponse(for: option)
        }
    }
    
    func handleSend() {
        guard canSend else { return }
        
        let userInput = inputText.trimmingCharacters(in: .whitespaces)
        addUserMessage(userInput)
        inputText = ""
        
        // Simulate AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.generateAIResponse(for: userInput)
        }
    }
    
    private func generateAIResponse(for input: String) {
        isTyping = true
        
        // Simulate typing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.isTyping = false
            
            // Generate contextual response based on input
            if input.lowercased().contains("running") || input.lowercased().contains("runner") {
                self.addAIMessage(
                    "Great! I found 3 runners near you who are free this evening.",
                    options: ["View profiles", "Schedule a run", "Find more runners"]
                )
            } else if input.lowercased().contains("group") || input.lowercased().contains("activity") {
                self.addAIMessage(
                    "Here are some group activities near you this week.",
                    options: ["Yoga class (Tomorrow)", "Basketball game (Friday)", "Cycling tour (Weekend)"]
                )
            } else if input.lowercased().contains("discover") || input.lowercased().contains("new") {
                self.addAIMessage(
                    "Based on your profile, you might enjoy these sports:",
                    options: ["Swimming", "Tennis", "Cycling", "Yoga"]
                )
            } else {
                // Default response
                self.addAIMessage(
                    "Let me find the best matches for you...",
                    options: ["Show me runners nearby", "Find group activities", "Something else"]
                )
            }
        }
    }
    
    private func addUserMessage(_ text: String) {
        let message = AIMatchMessage(
            id: UUID().uuidString,
            type: .user,
            text: text
        )
        messages.append(message)
        
        // Store in conversation context for future responses
        conversationContext["lastUserMessage"] = text
    }
    
    private func addAIMessage(_ text: String, options: [String]? = nil) {
        let message = AIMatchMessage(
            id: UUID().uuidString,
            type: .ai,
            text: text,
            options: options
        )
        messages.append(message)
    }
    
    // MARK: - Actions
    
    func joinActivity(_ activityId: String) {
        // TODO: Implement join activity logic
        print("Joining activity: \(activityId)")
        addAIMessage("Great! I've added you to the activity. You'll receive a confirmation shortly.")
    }
    
    func viewProfile(_ profileId: String) {
        // TODO: Navigate to profile view
        print("Viewing profile: \(profileId)")
    }
    
    func clearChat() {
        messages.removeAll()
        loadInitialMessage()
        conversationContext.removeAll()
    }
    
    func restartConversation() {
        clearChat()
    }
    
    // MARK: - Helper Methods
    
    func getMessageCount() -> Int {
        return messages.count
    }
    
    func getUserMessageCount() -> Int {
        return messages.filter { $0.type == .user }.count
    }
    
    func getAIMessageCount() -> Int {
        return messages.filter { $0.type == .ai }.count
    }
    
    // MARK: - Analytics
    
    func trackMessageSent(_ message: String) {
        // TODO: Implement analytics tracking
        print("User sent message: \(message)")
    }
    
    func trackOptionSelected(_ option: String) {
        // TODO: Implement analytics tracking
        print("User selected option: \(option)")
    }
}
