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

    @State private var messages: [AIMatchMessage] = [
        AIMatchMessage(
            id: "1",
            type: .ai,
            text: "Hi! I'm your AI matchmaker. I can help you find the perfect sport partners or activities. What would you like to do today?",
            options: ["Find a running partner", "Join a group activity", "Discover new sports"]
        )
    ]

    @State private var inputText = ""

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(messages) { message in
                                AIMatchMessageBubble(
                                    message: message,
                                    onOptionSelect: handleOption,
                                    onJoinActivity: onJoinActivity,
                                    onViewProfile: onViewProfile
                                )
                                .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
                                .environmentObject(theme)
                            }
                        }
                        .padding(.vertical)
                        .padding(.horizontal)
                        .id("bottom")
                    }
                    .onChange(of: messages.count) {
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
                }
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("AI Matchmaker")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(theme.colors.accentPurple)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("AI Matchmaker")
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .navigationBarBackButtonHidden(onBack != nil)
    }

    // MARK: - Handlers
    private func handleOption(_ option: String) {
        addUserMessage(option)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if option.contains("running") {
                addAIMessage("Great! I found 3 runners near you who are free this evening.")
            } else if option.contains("group") {
                addAIMessage("Here are some group activities near you this week.")
            } else {
                addAIMessage(
                    "Based on your profile, you might enjoy these sports:",
                    options: ["Swimming", "Tennis", "Cycling", "Yoga"]
                )
            }
        }
    }

    private func handleSend() {
        guard !inputText.isEmpty else { return }
        addUserMessage(inputText)
        inputText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            addAIMessage(
                "Let me find the best matches for you...",
                options: ["Show me runners nearby", "Find group activities", "Something else"]
            )
        }
    }

    private func addUserMessage(_ text: String) {
        messages.append(AIMatchMessage(id: UUID().uuidString, type: .user, text: text))
    }

    private func addAIMessage(_ text: String, options: [String]? = nil) {
        messages.append(AIMatchMessage(id: UUID().uuidString, type: .ai, text: text, options: options))
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask me anything...", text: $inputText)
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

            Button(action: handleSend) {
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

//
// MARK: - Message Models
//
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

//
// MARK: - Message Bubble
//
struct AIMatchMessageBubble: View {
    @EnvironmentObject private var theme: Theme
    let message: AIMatchMessage
    var onOptionSelect: (String) -> Void
    var onJoinActivity: ((String) -> Void)?
    var onViewProfile: ((String) -> Void)?

    var body: some View {
        if message.type == .ai {
            VStack(alignment: .leading, spacing: 6) {
                if let text = message.text {
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding()
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                }

                if let options = message.options {
                    AIFlowLayout(spacing: 8) {
                        ForEach(options, id: \.self) { option in
                            Button(option) {
                                onOptionSelect(option)
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
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
                        LinearGradient(colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .frame(maxWidth: 260, alignment: .trailing)
            }
        }
    }
}

//
// MARK: - Simple Horizontal Layout
//
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

//
// MARK: - Preview
//
#Preview {
    NavigationStack {
        AIMatchmakerView(onBack: {})
            .environmentObject(Theme())
    }
}
