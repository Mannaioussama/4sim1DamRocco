//
//  ChatConversationView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

// MARK: - Message Model

struct Message: Identifiable {
    let id: String
    let text: String
    let sender: MessageSender
    let time: String
    let senderName: String?
    let avatar: String?
}

enum MessageSender {
    case me
    case other
}

struct ChatConversationView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel: ChatConversationViewModel
    @FocusState private var isInputFocused: Bool
    
    var onBack: () -> Void
    
    // MARK: - Initialization
    
    init(chatId: String, onBack: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: ChatConversationViewModel(chatId: chatId))
        self.onBack = onBack
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            theme.colors.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                messagesList
                inputBar
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        // Keep VM and local focus state in sync (optional)
        .onChange(of: isInputFocused) { newValue in
            if viewModel.isInputFocused != newValue {
                viewModel.isInputFocused = newValue
            }
        }
        .onChange(of: viewModel.isInputFocused) { newValue in
            if isInputFocused != newValue {
                isInputFocused = newValue
            }
        }
    }

    // MARK: Header with centered title
    private var header: some View {
        ZStack {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(10)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                        .rotationEffect(.degrees(90))
                        .padding(10)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                AsyncImage(url: URL(string: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text("SM")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                .background(theme.colors.accentPurple)
                .clipShape(Circle())

                VStack(spacing: 0) {
                    Text("Swimming Group")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text("3 members")
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .frame(height: 56)
        .background(theme.colors.surfaceSecondary)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(theme.colors.cardStroke, lineWidth: 0)
        )
        .overlay(Divider().background(theme.colors.divider), alignment: .bottom)
    }

    // MARK: Messages
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .environmentObject(theme)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onAppear {
                if let lastMessageId = viewModel.getLastMessageId() {
                    proxy.scrollTo(lastMessageId, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessageId = viewModel.getLastMessageId() {
                    withAnimation {
                        proxy.scrollTo(lastMessageId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: Input Bar
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type a message...", text: $viewModel.messageText)
                .font(.system(size: 15))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(24)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    viewModel.sendMessage()
                }
            
            Button(action: {
                viewModel.sendMessage()
            }) {
                Text("Send")
            }
            .buttonStyle(BrandButtonStyle(variant: .default))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.colors.surfaceSecondary)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(theme.colors.cardStroke, lineWidth: 0)
        )
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    @EnvironmentObject private var theme: Theme
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .other {
                avatarView
            }
            
            if message.sender == .me {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.sender == .me ? .trailing : .leading, spacing: 4) {
                if message.sender == .other, let senderName = message.senderName {
                    Text(senderName)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(.leading, 4)
                }
                
                bubbleText
                    .frame(maxWidth: 300, alignment: message.sender == .me ? .trailing : .leading)
                
                Text(message.time)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, alignment: message.sender == .me ? .trailing : .leading)
            
            if message.sender == .other {
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Subviews / Pieces
    
    private var avatarView: some View {
        AsyncImage(url: URL(string: message.avatar ?? "")) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Text(initials(from: message.senderName))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
        .background(theme.colors.accentPurple)
        .clipShape(Circle())
    }
    
    private var bubbleText: some View {
        // Compute colors/materials explicitly to avoid nested Group inference
        let isMe = message.sender == .me
        let foreground: Color = isMe ? .white : theme.colors.textPrimary
        let fillColor: Color = isMe ? theme.colors.accentGreen : theme.colors.cardBackground
        let shape = MessageBubbleShape(
            isFromMe: isMe,
            corners: [.topLeft, .topRight, isMe ? .bottomLeft : .bottomRight]
        )
        
        // Build the base text content first (keeps type simple)
        let content = Text(message.text)
            .font(.system(size: 15))
            .foregroundColor(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        
        // Apply background layers separately and conditionally
        return content
            .background(fillColor)
            .background(isMe ? nil : AnyView(MaterialBackground(material: theme.colors.barMaterial)))
            .overlay(isMe ? nil : AnyView(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            ))
            .clipShape(shape)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func initials(from name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "U" }
        let comps = name.split(separator: " ")
        let initials = comps.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "U" : initials
    }
}

// Helper view to host Material in a background where a View is required
private struct MaterialBackground: View {
    let material: Material
    var body: some View {
        Rectangle().fill(material)
    }
}

// MARK: - Message Bubble Shape

struct MessageBubbleShape: Shape {
    let isFromMe: Bool
    let corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 24
        let smallRadius: CGFloat = 4
        
        var path = Path()
        
        // Start from top-left
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        
        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Right edge
        if isFromMe {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - smallRadius))
            path.addArc(
                center: CGPoint(x: rect.maxX - smallRadius, y: rect.maxY - smallRadius),
                radius: smallRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }
        
        // Bottom edge and bottom-left corner
        if !isFromMe {
            path.addLine(to: CGPoint(x: rect.minX + smallRadius, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: rect.minX + smallRadius, y: rect.maxY - smallRadius),
                radius: smallRadius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }
        
        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ChatConversationView(
        chatId: "1",
        onBack: {
            print("Back tapped")
        }
    )
    .environmentObject(Theme())
}
