//
//  AIMatchmakerViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import SwiftUI
import Combine

// MARK: - AI Match Message Data Model
struct AIMatchMessage: Identifiable {
    let id: String
    let type: AIMatchMessageType
    let text: String?
    let options: [String]?
    let suggestedActivities: [SuggestedActivity]?
    let suggestedUsers: [SuggestedUser]?
    let suggestedSports: [String]?

    init(id: String, type: AIMatchMessageType, text: String?, options: [String]? = nil, suggestedActivities: [SuggestedActivity]? = nil, suggestedUsers: [SuggestedUser]? = nil, suggestedSports: [String]? = nil) {
        self.id = id
        self.type = type
        self.text = text
        self.options = options
        self.suggestedActivities = suggestedActivities
        self.suggestedUsers = suggestedUsers
        self.suggestedSports = suggestedSports
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
        trackOptionSelected(option)
        sendToBackend(option)
    }
    
    func handleSend() {
        guard canSend else { return }
        
        let userInput = inputText.trimmingCharacters(in: .whitespaces)
        addUserMessage(userInput)
        trackMessageSent(userInput)
        inputText = ""
        
        sendToBackend(userInput)
    }
    
    // MARK: - Backend Call
    
    private func sendToBackend(_ text: String) {
        isTyping = true
        
        let history = messagesToChatHistory(messages)
        
        Task {
            // Can't 'await' in defer; hop to MainActor via Task instead
            defer { Task { @MainActor in self.isTyping = false } }
            do {
                let response = try await AIMatchmakerAPI.chat(
                    message: text,
                    conversationHistory: history
                )
                
                let aiMessage = AIMatchMessage(
                    id: UUID().uuidString,
                    type: .ai,
                    text: response.message,
                    options: response.options,
                    suggestedActivities: response.suggestedActivities,
                    suggestedUsers: response.suggestedUsers,
                    suggestedSports: response.suggestedActivities?.map { $0.sportType } ?? []
                )
                
                await MainActor.run {
                    self.messages.append(aiMessage)
                }
            } catch {
                let fallback = AIMatchMessage(
                    id: UUID().uuidString,
                    type: .ai,
                    text: "Sorry, something went wrong. Please try again.",
                    options: ["Try again", "Find group activities", "Find partners nearby"]
                )
                await MainActor.run {
                    self.messages.append(fallback)
                }
                print("AIMatchmaker error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func composeAIText(from response: ChatResponse) -> String {
        var text = response.message
        
        if let users = response.suggestedUsers, !users.isEmpty {
            text += "\n\nSuggested partners:"
            for (idx, u) in users.enumerated() {
                let score = u.matchScore.map { " • \($0)%" } ?? ""
                let dist = u.distance.map { " • \($0)" } ?? ""
                text += "\n\(idx + 1). \(u.name) • \(u.sport)\(dist)\(score)"
            }
        }
        
        if let activities = response.suggestedActivities, !activities.isEmpty {
            text += "\n\nSuggested activities:"
            for (idx, a) in activities.enumerated() {
                let score = a.matchScore.map { " • \($0)%" } ?? ""
                text += "\n\(idx + 1). \(a.title) • \(a.sportType) • \(a.date) \(a.time) @ \(a.location) • \(a.participants)/\(a.maxParticipants)\(score)"
            }
        }
        
        return text
    }
    
    private func messagesToChatHistory(_ messages: [AIMatchMessage]) -> [AIMatchmakerChatMessage] {
        messages.compactMap { msg in
            guard let text = msg.text, !text.isEmpty else { return nil }
            let role = (msg.type == .user) ? "user" : "assistant"
            return AIMatchmakerChatMessage(role: role, content: text)
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

