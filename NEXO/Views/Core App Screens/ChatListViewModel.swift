//
//  ChatListViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct Chat: Identifiable {
    let id: String
    let participantNames: String
    let participantAvatars: [String]
    let lastMessage: String
    let lastMessageTime: String
    let unreadCount: Int
    let isGroup: Bool
}

class ChatListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var chats: [Chat] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedChatId: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredChats: [Chat] {
        if searchQuery.isEmpty {
            return chats
        }
        return chats.filter { chat in
            chat.participantNames.localizedCaseInsensitiveContains(searchQuery) ||
            chat.lastMessage.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var hasChats: Bool {
        return !chats.isEmpty
    }
    
    var hasUnreadChats: Bool {
        return chats.contains { $0.unreadCount > 0 }
    }
    
    var totalUnreadCount: Int {
        return chats.reduce(0) { $0 + $1.unreadCount }
    }
    
    var hasSearchResults: Bool {
        return !filteredChats.isEmpty
    }
    
    var isSearching: Bool {
        return !searchQuery.isEmpty
    }
    
    // MARK: - Initialization
    
    init() {
        loadChats()
        setupSearchDebounce()
    }
    
    // MARK: - Data Loading
    
    private func loadChats() {
        isLoading = true
        
        // Mock data - In production, fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.chats = [
                Chat(
                    id: "1",
                    participantNames: "Sarah Johnson",
                    participantAvatars: ["https://i.pravatar.cc/150?img=9"],
                    lastMessage: "See you at the yoga session tomorrow!",
                    lastMessageTime: "2m",
                    unreadCount: 2,
                    isGroup: false
                ),
                Chat(
                    id: "2",
                    participantNames: "Basketball Squad",
                    participantAvatars: ["https://i.pravatar.cc/150?img=15", "https://i.pravatar.cc/150?img=12"],
                    lastMessage: "Who's bringing the ball?",
                    lastMessageTime: "15m",
                    unreadCount: 5,
                    isGroup: true
                ),
                Chat(
                    id: "3",
                    participantNames: "Michael Chen",
                    participantAvatars: ["https://i.pravatar.cc/150?img=12"],
                    lastMessage: "Great run today! Same time next week?",
                    lastMessageTime: "1h",
                    unreadCount: 0,
                    isGroup: false
                ),
                Chat(
                    id: "4",
                    participantNames: "Tennis Partners",
                    participantAvatars: ["https://i.pravatar.cc/150?img=5", "https://i.pravatar.cc/150?img=9"],
                    lastMessage: "Court is booked for Saturday",
                    lastMessageTime: "3h",
                    unreadCount: 1,
                    isGroup: true
                ),
                Chat(
                    id: "5",
                    participantNames: "Emma Wilson",
                    participantAvatars: ["https://i.pravatar.cc/150?img=5"],
                    lastMessage: "Thanks for the volleyball tips!",
                    lastMessageTime: "Yesterday",
                    unreadCount: 0,
                    isGroup: false
                ),
                Chat(
                    id: "6",
                    participantNames: "James Rodriguez",
                    participantAvatars: ["https://i.pravatar.cc/150?img=15"],
                    lastMessage: "Let's do another pickup game soon",
                    lastMessageTime: "Yesterday",
                    unreadCount: 0,
                    isGroup: false
                )
            ]
            self?.isLoading = false
        }
    }
    
    // MARK: - Search
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ query: String) {
        // In production, this could trigger a server-side search
        print("Searching for: \(query)")
    }
    
    func clearSearch() {
        searchQuery = ""
    }
    
    // MARK: - Actions
    
    func selectChat(_ chatId: String) {
        selectedChatId = chatId
        markChatAsRead(chatId)
    }
    
    func markChatAsRead(_ chatId: String) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            // In production, update on backend
            print("Marking chat as read: \(chatId)")
            
            // Update local state
            chats[index] = Chat(
                id: chats[index].id,
                participantNames: chats[index].participantNames,
                participantAvatars: chats[index].participantAvatars,
                lastMessage: chats[index].lastMessage,
                lastMessageTime: chats[index].lastMessageTime,
                unreadCount: 0,
                isGroup: chats[index].isGroup
            )
        }
    }
    
    func deleteChat(_ chatId: String) {
        chats.removeAll { $0.id == chatId }
        // TODO: Delete from backend
        print("Deleted chat: \(chatId)")
    }
    
    func refreshChats() {
        loadChats()
    }
    
    // MARK: - Helper Methods
    
    func getChat(by id: String) -> Chat? {
        return chats.first { $0.id == id }
    }
    
    func getChatsByType(isGroup: Bool) -> [Chat] {
        return chats.filter { $0.isGroup == isGroup }
    }
    
    func getUnreadChats() -> [Chat] {
        return chats.filter { $0.unreadCount > 0 }
    }
    
    func getChatParticipantInitials(_ chat: Chat) -> String {
        let names = chat.participantNames.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1)) + String(names[1].prefix(1))
        } else if let first = names.first {
            return String(first.prefix(1))
        }
        return "U"
    }
    
    func sortChatsByRecent() {
        // In production, implement actual sorting logic
        print("Sorting chats by recent activity")
    }
    
    // MARK: - Analytics
    
    func trackChatOpened(_ chatId: String) {
        // TODO: Implement analytics tracking
        print("Opened chat: \(chatId)")
    }
    
    func trackSearchPerformed(_ query: String) {
        // TODO: Implement analytics tracking
        print("Search performed: \(query)")
    }
}
