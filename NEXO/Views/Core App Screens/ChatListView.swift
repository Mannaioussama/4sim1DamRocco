//
//  ChatListView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = ChatListViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var onChatSelect: (String) -> Void
    
    var body: some View {
        ZStack {
            // Background uses Theme
            theme.colors.backgroundGradient
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping empty background
                    isSearchFocused = false
                    viewModel.dismissSearchKeyboard()
                }
            
            // Floating Orbs
            FloatingOrb(
                size: 288,
                color: LinearGradient(
                    colors: [
                        Color(hex: "C4B5FD").opacity(0.4),
                        Color(hex: "F9A8D4").opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: -100,
                yOffset: -200,
                delay: 0
            )
            
            FloatingOrb(
                size: 384,
                color: LinearGradient(
                    colors: [
                        Color(hex: "93C5FD").opacity(0.3),
                        Color(hex: "C4B5FD").opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 150,
                yOffset: 500,
                delay: 1
            )
            
            FloatingOrb(
                size: 256,
                color: LinearGradient(
                    colors: [
                        Color(hex: "FBC4E4").opacity(0.3),
                        Color(hex: "DDD6FE").opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 150,
                yOffset: -100,
                delay: 2
            )
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isSearching {
                    searchResultsContent
                } else {
                    chatListContent
                }
            }
        }
        // Keep VM and local search focus in sync
        .onChange(of: isSearchFocused) { _, newValue in
            if viewModel.isSearchFocused != newValue {
                viewModel.isSearchFocused = newValue
            }
        }
        .onChange(of: viewModel.isSearchFocused) { _, newValue in
            if isSearchFocused != newValue {
                isSearchFocused = newValue
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Messages")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .tracking(-0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if viewModel.totalUnreadCount > 0 {
                    HStack(spacing: 4) {
                        Text("\(viewModel.totalUnreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.colors.accentGreen)
                    .cornerRadius(10)
                }
            }
            .padding(.bottom, 10)
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(theme.colors.textSecondary)
                
                TextField("Search people or conversations...", text: $viewModel.searchQuery)
                    .font(.system(size: 15))
                    .foregroundColor(theme.colors.textPrimary)
                    .tint(theme.colors.accentPurple)
                    .accentColor(theme.colors.accentPurple)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                
                if viewModel.isSearching {
                    Button(action: { viewModel.clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .padding(16)
        .background(theme.colors.surfaceSecondary)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Search Results Content (People + Conversations)
    
    private var searchResultsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isSearchingUsers && !viewModel.hasUserResults {
                    // Searching state
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Searching people…")
                            .font(.system(size: 13))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                if viewModel.hasUserResults {
                    // People section
                    VStack(spacing: 8) {
                        HStack {
                            Text("People")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            Spacer()
                        }
                        ForEach(viewModel.userResults) { user in
                            SearchUserRow(
                                user: user,
                                onTap: {
                                    viewModel.startDirectChat(with: user.id) { chatId in
                                        viewModel.selectChat(chatId)
                                        onChatSelect(chatId)
                                    }
                                }
                            )
                            .environmentObject(theme)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Conversations section (still filtered by query)
                if viewModel.hasSearchResults {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Conversations")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            Spacer()
                        }
                        ForEach(viewModel.filteredChats) { chat in
                            ChatRow(
                                chat: chat,
                                onTap: {
                                    viewModel.selectChat(chat.id)
                                    viewModel.trackChatOpened(chat.id)
                                    onChatSelect(chat.id)
                                }
                            )
                            .environmentObject(theme)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                
                if !viewModel.hasUserResults && !viewModel.hasSearchResults && !viewModel.isSearchingUsers {
                    emptySearchView
                        .padding(.top, 24)
                }
            }
        }
        // Dismiss keyboard on scroll or tap anywhere in the list
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
            viewModel.dismissSearchKeyboard()
        }
    }
    
    // MARK: - Chat List Content
    
    private var chatListContent: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(viewModel.filteredChats) { chat in
                    ChatRow(
                        chat: chat,
                        onTap: {
                            viewModel.selectChat(chat.id)
                            viewModel.trackChatOpened(chat.id)
                            onChatSelect(chat.id)
                        }
                    )
                    .environmentObject(theme)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        // Dismiss keyboard on scroll or tap anywhere in the list
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
            viewModel.dismissSearchKeyboard()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text("Loading conversations...")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty Search View
    
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary)
            Text("No results")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text("Try a different name or keyword")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { viewModel.clearSearch() }) {
                Text("Clear Search")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.colors.accentPurple)
                    .cornerRadius(20)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Chat Row (unchanged)

struct ChatRow: View {
    @EnvironmentObject private var theme: Theme
    let chat: Chat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                if chat.isGroup && chat.participantAvatars.count > 1 {
                    // Group avatar
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: chat.participantAvatars[0])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text("U")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                        .background(theme.colors.accentPurple)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -8, y: -8)
                        
                        AsyncImage(url: URL(string: chat.participantAvatars[1])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text("U")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "EC4899"))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 8, y: 8)
                    }
                    .frame(width: 48, height: 48)
                } else {
                    // Single avatar
                    AsyncImage(url: URL(string: chat.participantAvatars.first ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text("U")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 48, height: 48)
                    .background(theme.colors.accentPurple)
                    .clipShape(Circle())
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(chat.participantNames)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(chat.lastMessageTime)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Text(chat.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                
                // Trailing icons
                HStack(spacing: 8) {
                    if chat.unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(theme.colors.accentGreen)
                            
                            Text("\(chat.unreadCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 24, height: 24)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Search User Row

struct SearchUserRow: View {
    @EnvironmentObject private var theme: Theme
    let user: UserSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text(initials(from: user.name))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 48, height: 48)
                .background(theme.colors.accentPurple)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Tap to chat")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func initials(from name: String) -> String {
        let comps = name.split(separator: " ")
        let letters = comps.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "U" : letters
    }
}

// MARK: - Preview

#Preview {
    ChatListView(onChatSelect: { chatId in
        print("Selected chat: \(chatId)")
    })
    .environmentObject(Theme())
}

