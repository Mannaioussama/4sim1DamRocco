//
//  ActivityRoomView.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI

struct ActivityRoomView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel: ActivityRoomViewModel

    let onBack: () -> Void
    
    init(activity: RoomActivity, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ActivityRoomViewModel(activity: activity))
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        activityInfoBanner
                        tabBar

                        Group {
                            if viewModel.isChatTab {
                                chatMessagesList
                            } else if viewModel.isParticipantsTab {
                                participantsTab
                            } else if viewModel.isAITab {
                                aiTipsTab
                            } else if viewModel.isInfoTab {
                                infoTab
                            }
                        }
                    }
                    .padding(.bottom, viewModel.isChatTab ? 180 : 100)
                }

                if viewModel.isChatTab {
                    messageInputBar
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }

                bottomBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.navigationTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(viewModel.navigationSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.shareActivity()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Share")
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .alert("Leave Activity", isPresented: $viewModel.showLeaveConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelLeave()
            }
            Button("Leave", role: .destructive) {
                handleLeave()
            }
        } message: {
            Text("Are you sure you want to leave this activity?")
        }
        .alert("Complete Activity", isPresented: $viewModel.showCompleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelComplete()
            }
            Button("Complete") {
                handleComplete()
            }
        } message: {
            Text("Mark this activity as complete?")
        }
        .onAppear {
            viewModel.trackScreenView()
        }
    }
    
    // MARK: - Background Orbs
    
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.14 : 0.3),
                            theme.colors.accentPink.opacity(theme.isDarkMode ? 0.11 : 0.2)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 288, height: 288)
                .blur(radius: 120)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.08 : 0.18),
                            theme.colors.accentPurpleLight.opacity(theme.isDarkMode ? 0.08 : 0.15)
                        ],
                        startPoint: .bottomLeading, endPoint: .topTrailing
                    )
                )
                .frame(width: 384, height: 384)
                .blur(radius: 120)
                .offset(x: 150, y: 500)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.accentPink.opacity(theme.isDarkMode ? 0.10 : 0.17),
                            theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.06 : 0.1)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: 150, y: -100)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Activity Info Banner
    
    private var activityInfoBanner: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                        Text(viewModel.startTimeMessage)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(viewModel.spotsLeftMessage)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.23), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                .padding(.bottom, 8)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.activity.location)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.95))
                        Button(action: {
                            viewModel.getDirections()
                        }) {
                            Text("Get Directions")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .underline()
                        }
                    }
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [theme.colors.accentPurple, theme.colors.accentPink],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.13), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .padding(.top, 12)
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ActivityTab.allCases, id: \.self) { tab in
                    Button(action: {
                        viewModel.selectTab(tab)
                        viewModel.trackTabChanged(tab)
                    }) {
                        Text(tab.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.isTabSelected(tab) ? theme.colors.accentPurple : theme.colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 12)
                            .overlay(
                                Rectangle()
                                    .fill(viewModel.isTabSelected(tab) ? theme.colors.accentPurple : Color.clear)
                                    .frame(height: 2),
                                alignment: .bottom
                            )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // Continuing in next part...
    // MARK: - Chat Messages List
    
    private var chatMessagesList: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.messages) { msg in
                        HStack(alignment: .top, spacing: 12) {
                            AsyncImage(url: URL(string: msg.avatar)) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(theme.colors.accentPurple)
                                    .overlay(
                                        Text(String(msg.sender.prefix(1)))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 2))
                            .shadow(color: .black.opacity(0.09), radius: 2, x: 0, y: 1)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(msg.sender)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(theme.colors.textPrimary)
                                    Text(msg.time)
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                
                                Text(msg.text)
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textPrimary)
                                    .padding(12)
                                    .background(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                                    )
                                    .cornerRadius(16)
                                    .cornerRadius(4, corners: [.topLeft])
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - Message Input Bar
    
    private var messageInputBar: some View {
        HStack(spacing: 8) {
            TextField("Type a message...", text: $viewModel.message)
                .font(.system(size: 13))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(24)
            
            Button(action: {
                viewModel.sendMessage()
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [theme.colors.accentOrange, theme.colors.accentOrangeFill],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
            }
            .disabled(!viewModel.canSendMessage)
            .opacity(viewModel.canSendMessage ? 1.0 : 0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            Rectangle()
                .fill(theme.colors.cardStroke)
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Participants Tab
    
    private var participantsTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(viewModel.participants) { person in
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: person.avatar)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(theme.colors.accentPurple)
                                .overlay(
                                    Text(viewModel.getParticipantInitial(person))
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 2))
                        .shadow(color: .black.opacity(0.09), radius: 2, x: 0, y: 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.colors.textPrimary)
                            Text(person.status)
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.isHost(person) {
                            Text("Host")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        colors: [theme.colors.accentGreen, theme.colors.accentGreenFill],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                        } else {
                            Button(action: {
                                viewModel.messageParticipant(person)
                            }) {
                                Text("Message")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.colors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(16)
                    .background(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    // MARK: - AI Tips Tab
    
    private var aiTipsTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                AITipCard(
                    icon: "sparkles",
                    iconColor: theme.colors.accentPurple,
                    iconBackground: .gradient(
                        LinearGradient(
                            colors: [
                                theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.16 : 0.20),
                                theme.colors.accentPink.opacity(theme.isDarkMode ? 0.14 : 0.18)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    ),
                    title: "\"Progress starts with small steps\"",
                    description: "Stay consistent and you'll reach your goals! 💪",
                    backgroundColor: .color(theme.colors.cardBackground)
                )
                
                AITipCard(
                    icon: "sun.max.fill",
                    iconColor: theme.colors.accentOrange,
                    iconBackground: .color(theme.colors.accentOrangeGlow.opacity(theme.isDarkMode ? 0.12 : 0.18)),
                    title: "Perfect weather conditions",
                    description: "72°F, sunny — ideal for outdoor activity",
                    extraInfo: "💡 Great conditions for \(viewModel.activity.sportType). Remember to bring sunscreen!",
                    extraInfoBackground: theme.colors.accentOrangeGlow.opacity(theme.isDarkMode ? 0.10 : 0.16),
                    backgroundColor: .color(theme.colors.cardBackground)
                )
                
                AITipCard(
                    icon: "person.3.fill",
                    iconColor: theme.colors.accentGreen,
                    iconBackground: .color(theme.colors.accentGreenGlow.opacity(theme.isDarkMode ? 0.12 : 0.18)),
                    title: "Optimal group size",
                    description: "\(viewModel.activity.spotsTaken) participants — perfect for engagement",
                    extraInfo: "✓ Not too crowded — you'll get personalized attention",
                    extraInfoBackground: theme.colors.accentGreenGlow.opacity(theme.isDarkMode ? 0.10 : 0.14),
                    backgroundColor: .color(theme.colors.cardBackground)
                )
                
                AITipCard(
                    icon: "clock",
                    iconColor: theme.colors.accentOrange,
                    iconBackground: .color(theme.colors.accentOrangeGlow.opacity(theme.isDarkMode ? 0.12 : 0.18)),
                    title: "Timing suggestion",
                    description: "Arrive 10 minutes early for warm-up",
                    backgroundColor: .color(theme.colors.cardBackground)
                )
                
                AITipCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Color(hex: "#CA8A04"),
                    iconBackground: .color(Color(hex: "#FEF3C7").opacity(theme.isDarkMode ? 0.10 : 0.24)),
                    title: "Safety reminders",
                    bulletPoints: [
                        "Stay hydrated throughout the session",
                        "Listen to your body and take breaks when needed",
                        "Inform the host of any health concerns"
                    ],
                    backgroundColor: .color(theme.colors.cardBackground)
                )
                
                AITipCard(
                    icon: "hand.thumbsup.fill",
                    iconColor: .white,
                    iconBackground: .gradient(
                        LinearGradient(
                            colors: [theme.colors.accentPurple, theme.colors.accentPink],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    ),
                    title: "AI says this is a great match!",
                    description: "Based on your profile, this activity matches your skill level and interests. Enjoy!",
                    backgroundColor: .color(theme.colors.cardBackground)
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
    
    // MARK: - Info Tab
    
    private var infoTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(viewModel.activity.description.isEmpty ? viewModel.activity.title : viewModel.activity.description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 12) {
                        InfoDetailRow(
                            icon: "clock",
                            iconColor: theme.colors.accentPurple,
                            iconBackground: theme.colors.accentPurpleGlow.opacity(0.18),
                            label: "Date & Time",
                            value: "\(viewModel.activity.date) at \(viewModel.activity.time)"
                        )
                        InfoDetailRow(
                            icon: "mappin",
                            iconColor: theme.colors.accentPink,
                            iconBackground: theme.colors.accentPink.opacity(0.13),
                            label: "Location",
                            value: viewModel.activity.location
                        )
                        InfoDetailRow(
                            icon: "person.2",
                            iconColor: theme.colors.accentPurple,
                            iconBackground: theme.colors.accentPurpleGlow.opacity(0.17),
                            label: "Participants",
                            value: "\(viewModel.activity.spotsTaken) / \(viewModel.activity.spotsTotal)"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Level")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(viewModel.activity.level)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [theme.colors.accentPurple, theme.colors.accentPink],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.showLeaveDialog()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                        Text("Leave")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(24)
                }
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    viewModel.showCompleteDialog()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Mark Complete")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [theme.colors.accentOrange, theme.colors.accentOrangeFill],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: theme.colors.accentOrange.opacity(0.23), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                Rectangle()
                    .fill(theme.colors.cardStroke)
                    .frame(height: 1),
                alignment: .top
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleLeave() {
        viewModel.leaveActivity(
            onSuccess: {
                onBack()
            },
            onError: { _ in }
        )
    }
    
    private func handleComplete() {
        viewModel.markComplete(
            onSuccess: {
                // Show success message
            },
            onError: { _ in }
        )
    }
}

// MARK: - AITipCard Fill Style
enum AIFillStyle {
    case color(Color)
    case gradient(LinearGradient)
}

// MARK: - Reusable Components
struct AITipCard: View {
    @EnvironmentObject private var theme: Theme
    
    let icon: String
    var iconColor: Color = .purple
    var iconBackground: AIFillStyle = .color(Color.purple.opacity(0.1))
    let title: String
    var description: String = ""
    var bulletPoints: [String] = []
    var extraInfo: String?
    var extraInfoBackground: Color?
    var backgroundColor: AIFillStyle = .color(Color.white.opacity(0.6))
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    switch iconBackground {
                    case .color(let c): Circle().fill(c)
                    case .gradient(let g): Circle().fill(g)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if !bulletPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(bulletPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(theme.colors.accentOrange)
                                    Text(point)
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.colors.textSecondary)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if let extraInfo = extraInfo {
                Text(extraInfo)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(extraInfoBackground ?? theme.colors.cardBackground.opacity(0.8))
                    .cornerRadius(12)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            Group {
                switch backgroundColor {
                case .color(let c): AnyView(c)
                case .gradient(let g): AnyView(g)
                }
            }
        )
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .clipped()
    }
}

struct InfoDetailRow: View {
    @EnvironmentObject private var theme: Theme
    
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBackground)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textSecondary)
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
    }
}

// MARK: - Preview
struct ActivityRoomView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRoomView(
            activity: RoomActivity(
                id: "1",
                sportType: "Running",
                title: "Morning Park Run",
                description: "Join us for a relaxed 5K run at the park.",
                location: "Central Park",
                date: "04/11/2025",
                time: "10:00 AM",
                hostName: "Oussama Mannai",
                hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Oussama",
                spotsTotal: 10,
                spotsTaken: 6,
                level: "Intermediate"
            ),
            onBack: {}
        )
        .environmentObject(Theme())
        .preferredColorScheme(.dark)
    }
}
