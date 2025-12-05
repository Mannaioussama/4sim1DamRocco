import Foundation
import Combine

// MARK: - Real-time Chat Service (HTTP Polling)
class RealtimeChatService: ObservableObject {
    static let shared = RealtimeChatService()
    
    @Published var isConnected = false
    @Published var connectionError: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var activePollers: [String: Timer] = [:]
    private var lastMessageTimestamps: [String: Date] = [:]
    private let pollingInterval: TimeInterval = 3.0 // Poll every 3 seconds
    
    private init() {}
    
    // MARK: - Polling Management
    
    func connect() {
        // For HTTP polling, "connection" just means we're ready to poll
        isConnected = true
        connectionError = nil
    }
    
    func disconnect() {
        // Stop all active pollers
        activePollers.values.forEach { $0.invalidate() }
        activePollers.removeAll()
        lastMessageTimestamps.removeAll()
        isConnected = false
    }
    
    // MARK: - Subscription Management
    
    func subscribeToChat(chatId: String) -> AnyPublisher<ChatMessageDTO, Never> {
        print("🔥 Realtime: Subscribing to chat \(chatId)")
        let subject = PassthroughSubject<ChatMessageDTO, Never>()
        
        // Start polling for this chat
        startPolling(for: chatId, subject: subject)
        
        return subject.eraseToAnyPublisher()
    }
    
    func unsubscribeFromChat(chatId: String) {
        // Stop polling for this chat
        stopPolling(for: chatId)
    }
    
    // MARK: - HTTP Polling Logic
    
    private func startPolling(for chatId: String, subject: PassthroughSubject<ChatMessageDTO, Never>) {
        print("🔥 Realtime: Starting polling for chat \(chatId)")
        
        // Initial fetch
        fetchNewMessages(for: chatId, subject: subject)
        
        // Set up timer for periodic polling
        let timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            print("🔥 Realtime: Polling timer fired for chat \(chatId)")
            self?.fetchNewMessages(for: chatId, subject: subject)
        }
        
        activePollers[chatId] = timer
        print("🔥 Realtime: Timer started for chat \(chatId)")
    }
    
    private func stopPolling(for chatId: String) {
        activePollers[chatId]?.invalidate()
        activePollers.removeValue(forKey: chatId)
        lastMessageTimestamps.removeValue(forKey: chatId)
    }
    
    private func fetchNewMessages(for chatId: String, subject: PassthroughSubject<ChatMessageDTO, Never>) {
        print("🔥 Realtime: Fetching messages for chat \(chatId)")
        Task { @MainActor in
            do {
                let messages = try await ChatAPI.fetchMessages(chatId: chatId)
                print("🔥 Realtime: Fetched \(messages.count) messages total")
                
                // Get the timestamp of the last known message for this chat
                let lastTimestamp = lastMessageTimestamps[chatId] ?? Date.distantPast
                print("🔥 Realtime: Last timestamp: \(lastTimestamp)")
                
                // Filter messages that are newer than our last timestamp
                let newMessages = messages.filter { message in
                    // Parse the message creation time (you might need to adjust this based on your API)
                    let messageDate = parseMessageDate(from: message)
                    return messageDate > lastTimestamp
                }
                print("🔥 Realtime: Found \(newMessages.count) new messages")
                
                // Update the last timestamp to the newest message
                if let newestMessage = newMessages.max(by: { 
                    parseMessageDate(from: $0) < parseMessageDate(from: $1) 
                }) {
                    lastMessageTimestamps[chatId] = parseMessageDate(from: newestMessage)
                    print("🔥 Realtime: Updated timestamp to: \(parseMessageDate(from: newestMessage))")
                }
                
                // Send new messages to subscribers
                newMessages.forEach { message in
                    print("🔥 Realtime: Sending message: \(message.text)")
                    subject.send(message)
                }
                
            } catch {
                // Handle polling errors gracefully
                if let apiError = error as? APIError {
                    connectionError = apiError.userMessage
                } else {
                    connectionError = error.localizedDescription
                }
                
                // Don't stop polling on error, just log it
                print("🔥 Realtime: Polling error for chat \(chatId): \(error)")
            }
        }
    }
    
    private func parseMessageDate(from message: ChatMessageDTO) -> Date {
        // Try to parse date from message properties
        // This might need adjustment based on your actual API response format
        
        // Option 1: If you have a createdAt field
        if let createdAt = message.createdAt {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let altFormatter = ISO8601DateFormatter()
            altFormatter.formatOptions = [.withInternetDateTime]
            let date = isoFormatter.date(from: createdAt) ?? altFormatter.date(from: createdAt) ?? Date.distantPast
            return date
        }
        
        // Option 2: Parse from the time field (less reliable)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        // Try to parse today's time
        if let time = formatter.date(from: message.time) {
            let calendar = Calendar.current
            let now = Date()
            let date = calendar.date(bySettingHour: calendar.component(.hour, from: time),
                                minute: calendar.component(.minute, from: time),
                                second: 0,
                                of: now) ?? Date.distantPast
            return date
        }
        
        // Fallback to current time
        return Date()
    }
    
    // MARK: - Cleanup
    
    deinit {
        disconnect()
    }
}
