//
//  ChatConversationView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

// MARK: - Shared Helpers

fileprivate func initials(from name: String?) -> String {
    guard let name = name, !name.isEmpty else { return "U" }
    let comps = name.split(separator: " ")
    let initials = comps.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    return initials.isEmpty ? "U" : initials
}

// MARK: - Message Model

struct Message: Identifiable {
    let id: String
    let text: String
    let sender: MessageSender
    let time: String
    let senderName: String?
    let avatar: String?
}

// MARK: - Group Participants Popup

struct GroupParticipantsPopup: View {
    @EnvironmentObject private var theme: Theme
    let participants: [ChatParticipant]
    var onSelectParticipant: (ChatParticipant) -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack {
                Spacer()
                VStack(spacing: 0) {
                    HStack {
                        Text("Participants")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textSecondary)
                                .padding(8)
                                .background(theme.colors.cardBackground)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(participants) { participant in
                                Button {
                                    onSelectParticipant(participant)
                                } label: {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: participant.profileImageUrl ?? participant.avatar ?? "")) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Text(initials(from: participant.name))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 36, height: 36)
                                        .background(theme.colors.accentPurple)
                                        .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(participant.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(theme.colors.textPrimary)
                                            if let email = participant.email {
                                                Text(email)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(theme.colors.textSecondary)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(theme.colors.textSecondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 260)

                    Button(action: onClose) {
                        Text("Close")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                LinearGradient(
                                    colors: [theme.colors.accentPurple, theme.colors.accentPink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(22)
                            .shadow(color: theme.colors.accentPurple.opacity(0.25), radius: 10, y: 6)
                    }
                    .padding(16)
                }
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                Spacer(minLength: 0)
            }
        }
    }
}

enum MessageSender {
    case me
    case other
}

struct ChatConversationView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel: ChatConversationViewModel
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var lastMessageCount: Int = 0
    
    // Track edge-swipe to go back
    @State private var edgeSwipeStartX: CGFloat? = nil
    @State private var isShowingParticipantProfile: Bool = false
    @State private var isShowingParticipantsList: Bool = false
    @State private var selectedParticipant: ChatParticipant? = nil
    
    // Get safe area bottom inset
    private var safeAreaBottom: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom
        }
        return 0
    }
    
    var onBack: () -> Void
    
    // MARK: - Initialization
    
    init(chatId: String, sessionTitle: String? = nil, isGroup: Bool = false, onBack: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: ChatConversationViewModel(chatId: chatId))
        self.onBack = onBack
        // Setup group chat info if provided
        if let sessionTitle = sessionTitle, isGroup {
            viewModel.setupGroupChat(sessionTitle: sessionTitle, isGroup: isGroup)
        }
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            theme.colors.backgroundGradient
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping empty background
                    isInputFocused = false
                    viewModel.dismissKeyboard()
                }

            VStack(spacing: 0) {
                header
                messagesList
            }
        }
        .alert("Leave Group", isPresented: $viewModel.showLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await viewModel.leaveGroup()
                    onBack()
                }
            }
        } message: {
            Text("Are you sure you want to leave this group chat? You will no longer receive messages from this group.")
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        // Keep VM and local focus state in sync
        .onChange(of: isInputFocused) { _, newValue in
            if viewModel.isInputFocused != newValue {
                viewModel.isInputFocused = newValue
            }
        }
        .onChange(of: viewModel.isInputFocused) { _, newValue in
            if isInputFocused != newValue {
                isInputFocused = newValue
            }
        }
        // Allow interactive left-edge swipe to go back in addition to the back button
        .simultaneousGesture(
            DragGesture(minimumDistance: 15, coordinateSpace: .local)
                .onChanged { value in
                    if edgeSwipeStartX == nil {
                        edgeSwipeStartX = value.startLocation.x
                    }
                }
                .onEnded { value in
                    defer { edgeSwipeStartX = nil }
                    guard let startX = edgeSwipeStartX else { return }
                    let horizontal = value.translation.width
                    let vertical = abs(value.translation.height)
                    // Start near left edge, swipe sufficiently right, not a big vertical drag
                    if startX < 30, horizontal > 80, vertical < 100 {
                        isInputFocused = false
                        viewModel.dismissKeyboard()
                        onBack()
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                keyboardHeight = keyboardFrame.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .overlay {
            if isShowingParticipantsList {
                GroupParticipantsPopup(
                    participants: viewModel.participants,
                    onSelectParticipant: { participant in
                        selectedParticipant = participant
                        isShowingParticipantsList = false
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isShowingParticipantProfile = true
                        }
                    },
                    onClose: {
                        isShowingParticipantsList = false
                    }
                )
                .environmentObject(theme)
                .transition(.opacity.combined(with: .scale))
                .zIndex(15)
            } else if let participant = selectedParticipant, isShowingParticipantProfile {
                ChatParticipantProfilePopup(
                    participant: participant,
                    onClose: { isShowingParticipantProfile = false }
                )
                .environmentObject(theme)
                .transition(.opacity.combined(with: .scale))
                .zIndex(10)
            }
        }
    }

    // MARK: Header with centered title
    private var header: some View {
        ZStack {
            HStack(spacing: 10) {
                Button(action: {
                    isInputFocused = false
                    viewModel.dismissKeyboard()
                    onBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(10)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }
                Spacer()
                if viewModel.isGroup {
                    // Group chat: participants list, creator profile, leave group
                    Menu {
                        Button {
                            isInputFocused = false
                            viewModel.dismissKeyboard()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isShowingParticipantsList = true
                            }
                        } label: {
                            Label("View participants", systemImage: "person.3")
                        }

                        if let creator = viewModel.participants.first {
                            Button {
                                isInputFocused = false
                                viewModel.dismissKeyboard()
                                selectedParticipant = creator
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isShowingParticipantProfile = true
                                }
                            } label: {
                                Label("View creator profile", systemImage: "person.crop.circle")
                            }
                        }

                        Button(role: .destructive, action: {
                            viewModel.showLeaveConfirmation = true
                        }) {
                            Label("Leave Group", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textSecondary)
                            .rotationEffect(.degrees(90))
                            .padding(10)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                    }
                } else if let participant = viewModel.directChatPopupParticipant {
                    // One-to-one chat: show profile option
                    Menu {
                        Button {
                            isInputFocused = false
                            viewModel.dismissKeyboard()
                            selectedParticipant = participant
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isShowingParticipantProfile = true
                            }
                        } label: {
                            Label("Show profile", systemImage: "person.crop.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textSecondary)
                            .rotationEffect(.degrees(90))
                            .padding(10)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                    }
                } else {
                    // Fallback: simple ellipsis button with no menu actions
                    Button(action: {
                        isInputFocused = false
                        viewModel.dismissKeyboard()
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textSecondary)
                            .rotationEffect(.degrees(90))
                            .padding(10)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                let isGroupChat = viewModel.isGroup
                let title: String = {
                    if isGroupChat {
                        return viewModel.sessionTitle.isEmpty ? "Group chat" : viewModel.sessionTitle
                    } else {
                        return viewModel.directChatDisplayName
                    }
                }()
                let subtitle: String? = isGroupChat ? "\(viewModel.participants.count) participants" : nil
                let avatarURL: String = {
                    if isGroupChat {
                        let first = viewModel.participants.first
                        return first?.profileImageUrl ?? first?.avatar ?? ""
                    } else {
                        if let other = viewModel.otherParticipant {
                            return other.profileImageUrl ?? other.avatar ?? ""
                        }
                        return viewModel.messages.first(where: { $0.sender == .other })?.avatar ?? ""
                    }
                }()

                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text(initials(from: title))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                .background(theme.colors.accentPurple)
                .clipShape(Circle())

                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.textSecondary)
                    }
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
                // Extra bottom padding so the last bubble stays above the input bar
                .padding(.bottom, 80)
            }
            // Dismiss keyboard when scrolling the list
            .scrollDismissesKeyboard(.immediately)
            // Make the whole scroll area tappable to dismiss keyboard
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
                viewModel.dismissKeyboard()
            }
            .onAppear {
                if let lastMessageId = viewModel.getLastMessageId() {
                    proxy.scrollTo(lastMessageId, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.count) { _, newCount in
                // Only scroll if a new message was added (not just a refresh)
                if newCount > lastMessageCount {
                    if let lastMessageId = viewModel.getLastMessageId() {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
                lastMessageCount = newCount
            }
            .onChange(of: keyboardHeight) { _, newHeight in
                // When keyboard opens, keep the latest message visible above the input bar
                if newHeight > 0, let lastMessageId = viewModel.getLastMessageId() {
                    withAnimation(.easeOut(duration: 0.25)) {
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

// MARK: - Chat Participant Profile Popup

struct ChatParticipantProfilePopup: View {
    @EnvironmentObject private var theme: Theme
    let participant: ChatParticipant
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack {
                Spacer()
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        // Avatar + name + email
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: participant.profileImageUrl ?? participant.avatar ?? "")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Text(initials(from: participant.name))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 64, height: 64)
                            .background(theme.colors.accentPurple)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(participant.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(theme.colors.textPrimary)

                                if let email = participant.email {
                                    Text(email)
                                        .font(.system(size: 13))
                                        .foregroundColor(theme.colors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)

                            Text(participant.about?.isEmpty == false ? participant.about! : "No public description available yet.")
                                .font(.system(size: 13))
                                .foregroundColor(theme.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Favorite Sports")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)

                            if let sports = participant.sportsInterests, !sports.isEmpty {
                                // Render each interest as horizontal pills
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(sports, id: \.self) { sport in
                                            sportChip(sport, symbol: "sportscourt")
                                        }
                                    }
                                }
                            } else {
                                Text("No favorite sports added yet.")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }

                        Button(action: onClose) {
                            Text("Close")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [theme.colors.accentPurple, theme.colors.accentPink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(22)
                                .shadow(color: theme.colors.accentPurple.opacity(0.25), radius: 10, y: 6)
                        }
                    }
                    .padding(16)
                }
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                Spacer(minLength: 0)
            }
        }
    }

    private func sportChip(_ title: String, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 13))
            Text(title)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.colors.cardBackground, in: Capsule())
        .background(theme.colors.barMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .foregroundColor(theme.colors.textPrimary)
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

