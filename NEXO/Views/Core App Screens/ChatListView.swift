//
//  ChatListView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

// MARK: - Chat Model

struct Chat: Identifiable {
    let id: String
    let participantNames: String
    let participantAvatars: [String]
    let lastMessage: String
    let lastMessageTime: String
    let unreadCount: Int
    let isGroup: Bool
}

struct ChatListView: View {
    @EnvironmentObject private var theme: Theme
    @State private var searchQuery = ""
    
    var onChatSelect: (String) -> Void
    
    // Mock chats data
    let mockChats: [Chat] = [
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
    
    var filteredChats: [Chat] {
        if searchQuery.isEmpty {
            return mockChats
        }
        return mockChats.filter { chat in
            chat.participantNames.localizedCaseInsensitiveContains(searchQuery) ||
            chat.lastMessage.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        ZStack {
            // Background uses Theme
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            // Floating Orbs (kept; they blend in both modes)
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
                VStack(spacing: 0) {
                    Text("Messages")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .tracking(-0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        TextField("Search conversations...", text: $searchQuery)
                            .font(.system(size: 15))
                            .foregroundColor(theme.colors.textPrimary)
                            .tint(theme.colors.accentPurple)
                            .accentColor(theme.colors.accentPurple)
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
                
                // Chat List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredChats) { chat in
                            ChatRow(chat: chat, onTap: { onChatSelect(chat.id) })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Chat Row

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
                    AsyncImage(url: URL(string: chat.participantAvatars[0])) { image in
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

// NOTE: Reusable components defined in other files:
// - FloatingOrb, ScaleButtonStyle, Color.init(hex:)

// MARK: - Preview

#Preview {
    ChatListView(onChatSelect: { chatId in
        print("Selected chat: \(chatId)")
    })
    .environmentObject(Theme())
}
