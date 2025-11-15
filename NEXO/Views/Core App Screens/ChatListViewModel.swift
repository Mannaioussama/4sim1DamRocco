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

struct UserSearchResult: Identifiable, Equatable {
    let id: String
    let name: String
    let avatar: String?
}

class ChatListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var chats: [Chat] = []
    @Published var userResults: [UserSearchResult] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var isSearchingUsers: Bool = false
    @Published var selectedChatId: String?
    // New: control focus of the search field from VM (to dismiss on background tap)
    @Published var isSearchFocused: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var fetchTask: Task<Void, Never>?
    private var userSearchTask: Task<Void, Never>?
    
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
    
    var hasChats: Bool { !chats.isEmpty }
    var hasUnreadChats: Bool { chats.contains { $0.unreadCount > 0 } }
    var totalUnreadCount: Int { chats.reduce(0) { $0 + $1.unreadCount } }
    var hasSearchResults: Bool { !filteredChats.isEmpty }
    var isSearching: Bool { !searchQuery.isEmpty }
    var hasUserResults: Bool { !userResults.isEmpty }
    
    // MARK: - Initialization
    
    init() {
        loadChats()
        setupSearchDebounce()
    }
    
    // MARK: - Data Loading
    
    private func loadChats() {
        fetchTask?.cancel()
        isLoading = true
        
        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let dtos = try await ChatAPI.fetchChats(search: self.searchQuery)
                let mapped = dtos.map {
                    Chat(
                        id: $0.id,
                        participantNames: $0.participantNames,
                        participantAvatars: $0.participantAvatars,
                        lastMessage: $0.lastMessage,
                        lastMessageTime: $0.lastMessageTime,
                        unreadCount: $0.unreadCount,
                        isGroup: $0.isGroup
                    )
                }
                await MainActor.run {
                    self.chats = mapped
                    self.isLoading = false
                }
            } catch let api as APIError {
                await MainActor.run {
                    self.isLoading = false
                    print("Chat list error: \(api.userMessage)")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Chat list error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - User Search
    
    private func searchUsers(_ query: String) {
        userSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 2 {
            userResults = []
            isSearchingUsers = false
            return
        }
        isSearchingUsers = true
        
        userSearchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let dtos = try await ChatAPI.searchUsers(query: trimmed)
                let mapped = dtos.map { UserSearchResult(id: $0.id, name: $0.name, avatar: $0.avatar) }
                await MainActor.run {
                    self.userResults = mapped
                    self.isSearchingUsers = false
                }
            } catch let api as APIError {
                await MainActor.run {
                    self.userResults = []
                    self.isSearchingUsers = false
                    print("User search error: \(api.userMessage)")
                }
            } catch {
                await MainActor.run {
                    self.userResults = []
                    self.isSearchingUsers = false
                    print("User search error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Search
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                self.loadChats()          // server-side chat search
                self.searchUsers(query)   // people search
            }
            .store(in: &cancellables)
    }
    
    func clearSearch() {
        searchQuery = ""
        userResults = []
    }
    
    // MARK: - Actions
    
    func selectChat(_ chatId: String) {
        selectedChatId = chatId
        markChatAsRead(chatId)
    }
    
    func startDirectChat(with userId: String, onOpen: @escaping (String) -> Void) {
        Task {
            do {
                let detail = try await ChatAPI.createChat(
                    CreateChatRequest(participantIds: [userId], groupName: nil, groupAvatar: nil)
                )
                await MainActor.run {
                    self.selectedChatId = detail.id
                    onOpen(detail.id)
                }
            } catch let api as APIError {
                print("Create chat failed: \(api.userMessage)")
            } catch {
                print("Create chat failed: \(error.localizedDescription)")
            }
        }
    }
    
    func markChatAsRead(_ chatId: String) {
        Task {
            do {
                try await ChatAPI.markChatAsRead(chatId: chatId)
                await MainActor.run {
                    if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                        let c = self.chats[index]
                        self.chats[index] = Chat(
                            id: c.id,
                            participantNames: c.participantNames,
                            participantAvatars: c.participantAvatars,
                            lastMessage: c.lastMessage,
                            lastMessageTime: c.lastMessageTime,
                            unreadCount: 0,
                            isGroup: c.isGroup
                        )
                    }
                }
            } catch {
                print("markChatAsRead failed: \(error)")
            }
        }
    }
    
    func deleteChat(_ chatId: String) {
        Task {
            do {
                _ = try await ChatAPI.deleteChat(chatId: chatId)
                await MainActor.run {
                    self.chats.removeAll { $0.id == chatId }
                }
            } catch {
                print("deleteChat failed: \(error)")
            }
        }
    }
    
    func refreshChats() { loadChats() }
    
    // MARK: - Helper Methods
    
    func getChat(by id: String) -> Chat? { chats.first { $0.id == id } }
    func getChatsByType(isGroup: Bool) -> [Chat] { chats.filter { $0.isGroup == isGroup } }
    func getUnreadChats() -> [Chat] { chats.filter { $0.unreadCount > 0 } }
    
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
        // Sorting handled by backend; add client-side sort if needed
        print("Sorting chats by recent activity")
    }
    
    // MARK: - Analytics
    
    func trackChatOpened(_ chatId: String) { print("Opened chat: \(chatId)") }
    func trackSearchPerformed(_ query: String) { print("Search performed: \(query)") }
    
    // MARK: - Keyboard
    
    func dismissSearchKeyboard() {
        isSearchFocused = false
    }
}

