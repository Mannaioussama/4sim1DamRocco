//
//  AIMatchmakerView.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import SwiftUI

struct AIMatchmakerView: View {
    var onBack: (() -> Void)?
    var onJoinActivity: ((String) -> Void)?
    var onViewProfile: ((String) -> Void)?

    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel = AIMatchmakerViewModel()

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                AIMatchMessageBubble(
                                    message: message,
                                    onOptionSelect: { option in
                                        viewModel.handleOptionSelect(option)
                                        viewModel.trackOptionSelected(option)
                                    },
                                    onJoinActivity: { activityId in
                                        viewModel.joinActivity(activityId)
                                        onJoinActivity?(activityId)
                                    },
                                    onViewProfile: { profileId in
                                        viewModel.viewProfile(profileId)
                                        onViewProfile?(profileId)
                                    }
                                )
                                .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
                                .environmentObject(theme)
                                .environmentObject(localizationManager)
                            }
                            
                            // Typing indicator
                            if viewModel.isTyping {
                                HStack {
                                    TypingIndicator()
                                        .environmentObject(theme)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical)
                        .padding(.horizontal)
                        .id("bottom")
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                inputBar
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onBack {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(8)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(localizationManager.localized("common.back"))
                }
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text(localizationManager.localized("aiMatchmaker.nav.title"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(theme.colors.accentPurple)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(localizationManager.localized("aiMatchmaker.nav.title"))
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .navigationBarBackButtonHidden(onBack != nil)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField(localizationManager.localized("aiMatchmaker.input.placeholder"), text: $viewModel.inputText)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(20)
                .submitLabel(.send)
                .onSubmit {
                    viewModel.handleSend()
                    viewModel.trackMessageSent(viewModel.inputText)
                }

            Button(action: {
                viewModel.trackMessageSent(viewModel.inputText)
                viewModel.handleSend()
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        LinearGradient(colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
            }
            .disabled(!viewModel.canSend)
            .opacity(viewModel.canSend ? 1.0 : 0.6)
        }
        .padding()
        .background(theme.colors.cardBackground.opacity(0.7))
        .background(theme.colors.barMaterial)
        .overlay(Rectangle().fill(theme.colors.cardStroke).frame(height: 1), alignment: .top)
    }

    // MARK: - Background Blobs
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: -120, y: -150)

            Circle()
                .fill(LinearGradient(colors: [.green.opacity(0.25), .cyan.opacity(0.2)],
                                     startPoint: .bottomLeading,
                                     endPoint: .topTrailing))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 150, y: 250)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @EnvironmentObject private var theme: Theme
    @State private var animatingDot1 = false
    @State private var animatingDot2 = false
    @State private var animatingDot3 = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(theme.colors.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(getScale(for: index))
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: getScale(for: index)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .onAppear {
            animatingDot1 = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animatingDot2 = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animatingDot3 = true
            }
        }
    }
    
    private func getScale(for index: Int) -> CGFloat {
        switch index {
        case 0: return animatingDot1 ? 1.2 : 1.0
        case 1: return animatingDot2 ? 1.2 : 1.0
        case 2: return animatingDot3 ? 1.2 : 1.0
        default: return 1.0
        }
    }
}

// MARK: - Message Bubble
struct AIMatchMessageBubble: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    let message: AIMatchMessage
    var onOptionSelect: (String) -> Void
    var onJoinActivity: ((String) -> Void)?
    var onViewProfile: ((String) -> Void)?

    var body: some View {
        if message.type == .ai {
            HStack(alignment: .top, spacing: 10) {
                // AI Avatar
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            )
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#8B5CF6"))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if let text = message.text {
                        Text(text)
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.7))
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                    )
                                    .background(.ultraThinMaterial)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(colors: [
                                            Color(hex: "#8B5CF6").opacity(0.1),
                                            Color(hex: "#EC4899").opacity(0.1),
                                            Color(hex: "#0066FF").opacity(0.1)
                                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .blur(radius: 8)
                            )
                    }

                    // Activity Cards
                    if let activities = message.suggestedActivities, !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.localized("aiMatchmaker.section.suggestedActivities"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                            
                            ForEach(activities) { activity in
                                ActivitySuggestionCard(activity: activity, onJoin: onJoinActivity)
                            }
                        }
                    }

                    // User Cards
                    if let users = message.suggestedUsers, !users.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.localized("aiMatchmaker.section.suggestedPartners"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                            
                            ForEach(users) { user in
                                UserSuggestionCard(user: user, onViewProfile: onViewProfile)
                            }
                        }
                    }

                    // Sport Cards
                    if let sports = message.suggestedSports, !sports.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.localized("aiMatchmaker.section.tryTheseSports"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                // Use stable, index-based IDs to avoid duplicate-ID runtime warnings
                                ForEach(Array(sports.enumerated()), id: \.offset) { _, sport in
                                    SportSuggestionCard(sport: sport, onOptionSelect: onOptionSelect)
                                }
                            }
                        }
                    }

                    if let options = message.options {
                        AIFlowLayout(spacing: 8) {
                            ForEach(options, id: \.self) { option in
                                Button(action: {
                                    onOptionSelect(option)
                                }) {
                                    Text(option)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(theme.isDarkMode ? .white : .black)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .fill(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.7))
                                                .background(
                                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                        .stroke(
                                                            LinearGradient(colors: [
                                                                Color(hex: "#8B5CF6").opacity(0.9),
                                                                Color(hex: "#EC4899").opacity(0.9)
                                                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                            lineWidth: 1.5
                                                        )
                                                )
                                                .background(.ultraThinMaterial)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
                                }
                                .buttonStyle(.plain)
                                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .allowsHitTesting(true)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                Spacer()
                Text(message.text ?? "")
                    .font(.system(size: 14))
                    .padding()
                    .background(
                        LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(24)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Activity Suggestion Card
struct ActivitySuggestionCard: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    let activity: SuggestedActivity
    let onJoin: ((String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(activity.sportType)
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.7))
                }
                
                Spacer()
                
                if let score = activity.matchScore {
                    Text(String(format: localizationManager.localized("aiMatchmaker.match.scoreFormat"), score))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .cornerRadius(10)
                }
            }
            
            HStack {
                Label("\(activity.date) • \(activity.time)", systemImage: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            HStack {
                Label(
                    "\(activity.location) • " +
                    String(
                        format: localizationManager.localized("aiMatchmaker.activity.participantsFormat"),
                        activity.participants,
                        activity.maxParticipants
                    ),
                    systemImage: "location"
                )
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Button(localizationManager.localized("aiMatchmaker.activity.joinButton")) {
                onJoin?(activity.id)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(hex: "#2ECC71"))
            .cornerRadius(20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(colors: [
                        Color(hex: "#8B5CF6").opacity(0.1),
                        Color(hex: "#EC4899").opacity(0.1),
                        Color(hex: "#0066FF").opacity(0.1)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .blur(radius: 8)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - User Suggestion Card
struct UserSuggestionCard: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    let user: SuggestedUser
    let onViewProfile: ((String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        if let score = user.matchScore {
                            Text(String(format: localizationManager.localized("aiMatchmaker.match.scoreFormat"), score))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                                )
                                .cornerRadius(10)
                        }
                    }
                    
                    Text(user.sport)
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.7))
                    
                    if let bio = user.bio {
                        Text(bio)
                            .font(.system(size: 12))
                            .foregroundColor(.black.opacity(0.6))
                            .lineLimit(2)
                    }
                }
            }
            
            HStack {
                if let distance = user.distance {
                    Label(distance, systemImage: "location")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()
                
                if let availability = user.availability {
                    // Use a widely supported symbol to avoid runtime warnings
                    Label(availability, systemImage: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#2ECC71"))
                }
            }
            
            HStack(spacing: 8) {
                Button(localizationManager.localized("aiMatchmaker.user.viewProfileButton")) {
                    onViewProfile?(user.id)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                
                Button(localizationManager.localized("aiMatchmaker.user.connectButton")) {
                    // Connect action
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .cornerRadius(20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(colors: [
                        Color(hex: "#8B5CF6").opacity(0.1),
                        Color(hex: "#EC4899").opacity(0.1),
                        Color(hex: "#0066FF").opacity(0.1)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .blur(radius: 8)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Sport Suggestion Card
struct SportSuggestionCard: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    let sport: String
    let onOptionSelect: (String) -> Void
    
    var body: some View {
        Button(sport) {
            let prompt = String(format: localizationManager.localized("aiMatchmaker.sport.tellMeMoreFormat"), sport)
            onOptionSelect(prompt)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(colors: [
                        Color(hex: "#8B5CF6").opacity(0.2),
                        Color(hex: "#EC4899").opacity(0.2),
                        Color(hex: "#0066FF").opacity(0.2)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .blur(radius: 4)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Simple Horizontal Layout
struct AIFlowLayout<Content: View>: View {
    var spacing: CGFloat
    var content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        HStack(spacing: spacing) {
            content()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AIMatchmakerView(onBack: {})
            .environmentObject(Theme())
    }
}
