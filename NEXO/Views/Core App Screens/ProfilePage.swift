//
//  ProfilePage.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import PhotosUI

struct ProfilePage: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = ProfilePageViewModel()

    var onSettingsClick: () -> Void
    var onAchievementsClick: (() -> Void)?

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()

            FloatingOrb(
                size: 128,
                color: LinearGradient(
                    colors: [Color(hex: "8B5CF6").opacity(0.35), Color(hex: "EC4899").opacity(0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                xOffset: -140, yOffset: -250, delay: 0
            )
            FloatingOrb(
                size: 160,
                color: LinearGradient(
                    colors: [Color(hex: "93C5FD").opacity(0.25), Color(hex: "8B5CF6").opacity(0.25)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                xOffset: 140, yOffset: 300, delay: 1
            )

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(theme.colors.textPrimary)
                            .tracking(-0.5)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                        Spacer()

                        Button(action: {
                            viewModel.trackSettingsOpened()
                            onSettingsClick()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "person").font(.system(size: 18))
                                Text("Profile").font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(theme.colors.cardBackground)
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.colors.cardStroke, lineWidth: 2)
                            )
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                    // Profile Card
                    ProfileGlassCard(
                        user: viewModel.currentUser,
                        pickedUIImage: viewModel.pickedUIImage,
                        onPencilTap: { viewModel.openSourcePicker() }
                    )
                    .environmentObject(theme)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Quick Actions
                    VStack(spacing: 12) {
                        if let achievements = onAchievementsClick {
                            AchievementsButton(action: {
                                viewModel.trackAchievementsOpened()
                                achievements()
                            })
                            .environmentObject(theme)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Tabs
                    ProfileCrystalTabs(
                        user: viewModel.currentUser,
                        selectedTab: $viewModel.selectedTab,
                        recentActivities: viewModel.recentActivities,
                        achievements: viewModel.achievements,
                        skillLevels: viewModel.skillLevels,
                        interests: viewModel.interests,
                        onTabChange: { index in
                            viewModel.selectTab(index)
                            viewModel.trackTabView(index)
                        }
                    )
                    .environmentObject(theme)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        // Sheet pickers
        .sheet(isPresented: $viewModel.showPhotoPicker) {
            PhotoLibraryPicker(
                onPick: { viewModel.handlePickedImage($0) },
                onCancel: {}
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showFilesPicker) {
            FilesImagePicker(
                onPick: { viewModel.handlePickedImage($0) },
                onCancel: {}
            )
            .ignoresSafeArea()
        }
        // Centered source picker popup
        .overlay(sourcePickerPopup)
        // Upload overlay + error
        .overlay(uploadOverlay)
        .alert("Upload Error", isPresented: .constant(viewModel.uploadError != nil), actions: {
            Button("OK") { viewModel.uploadError = nil }
        }, message: {
            Text(viewModel.uploadError ?? "")
        })
        .onAppear {
            viewModel.trackProfileView()
        }
    }

    // MARK: - Centered source picker popup
    private var sourcePickerPopup: some View {
        Group {
            if viewModel.showSourceSheet {
                ZStack {
                    // Dim background tap to dismiss
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { viewModel.closeSourcePicker() }

                    VStack(spacing: 12) {
                        Text("Change profile photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.top, 12)

                        VStack(spacing: 8) {
                            PopupActionButton(
                                title: "Choose from Library",
                                systemImage: "photo.on.rectangle",
                                action: { viewModel.openPhotoPicker() }
                            )
                            PopupActionButton(
                                title: "Choose from Files",
                                systemImage: "folder",
                                action: { viewModel.openFilesPicker() }
                            )
                            if viewModel.hasAvatar {
                                PopupActionButton(
                                    title: "Remove Photo",
                                    systemImage: "trash",
                                    roleDestructive: true,
                                    action: {
                                        viewModel.removeAvatar()
                                        viewModel.trackImageRemoved()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)

                        Button(action: { viewModel.closeSourcePicker() }) {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(theme.colors.cardBackground)
                                .background(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                                )
                                .cornerRadius(16)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    }
                    .frame(maxWidth: 360)
                    .background(theme.colors.cardBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                    )
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: viewModel.showSourceSheet)
    }

    // MARK: - Upload overlay
    private var uploadOverlay: some View {
        Group {
            if viewModel.isUploading {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Saving photo…")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(14)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.isUploading)
    }
}

// MARK: - PopupActionButton
private struct PopupActionButton: View {
    @EnvironmentObject private var theme: Theme
    let title: String
    let systemImage: String
    var roleDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(roleDestructive ? .red : theme.colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.colors.cardBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Profile Glass Card
private struct ProfileGlassCard: View {
    @EnvironmentObject private var theme: Theme
    let user: UserProfile
    let pickedUIImage: UIImage?
    var onPencilTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "8B5CF6").opacity(0.2),
                            Color(hex: "EC4899").opacity(0.2),
                            Color(hex: "0066FF").opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 12)
                .opacity(0.6)
                .padding(-4)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "8B5CF6").opacity(0.2),
                                        Color.white.opacity(0.35),
                                        Color(hex: "EC4899").opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .blur(radius: 12)

                        avatarView
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

                        Button(action: onPencilTap) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(color: Color(hex: "8B5CF6").opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    Text(user.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .padding(.bottom, 8)

                    Text(user.bio)
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle").font(.system(size: 14))
                        Text(user.location).font(.system(size: 14))
                    }
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.colors.cardBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                    )
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                }

                HStack(spacing: 8) {
                    StatPill(value: "\(user.stats.sessionsJoined)", label: "Joined")
                    StatPill(value: "\(user.stats.sessionsHosted)", label: "Hosted")
                    StatPill(value: "⭐ \(String(format: "%.1f", user.stats.rating))", label: "Rating")
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                .environmentObject(theme)
            }
            .padding(.horizontal, 20)
        }
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let ui = pickedUIImage {
            Image(uiImage: ui).resizable().scaledToFill()
        } else if let url = URL(string: user.avatar) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Text("AT")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 96, height: 96)
                    .background(Color(hex: "A855F7"))
            }
        } else {
            Text("AT")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 96, height: 96)
                .background(Color(hex: "A855F7"))
        }
    }
}

// MARK: - Stat Pill
private struct StatPill: View {
    @EnvironmentObject private var theme: Theme
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Achievements Button (missing helper restored)
struct AchievementsButton: View {
    @EnvironmentObject private var theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FBBF24").opacity(0.3), Color(hex: "F97316").opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 12)
                    .opacity(0.75)
                    .padding(-4)

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FBBF24"), Color(hex: "F97316")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            )
                        Image(systemName: "trophy")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievements")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        Text("View badges & rewards")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(16)
            }
            .background(theme.colors.cardBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Tabs (Implemented)
private struct ProfileCrystalTabs: View {
    @EnvironmentObject private var theme: Theme
    let user: UserProfile
    @Binding var selectedTab: Int
    let recentActivities: [Activity]
    let achievements: [AchievementData]
    let skillLevels: [(sport: String, level: String)]
    let interests: String
    var onTabChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 12) {
            tabSelector

            Group {
                switch selectedTab {
                case 0: aboutTab
                case 1: activitiesTab
                case 2: medalsTab
                default: aboutTab
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 6) {
            tabButton(title: "About", index: 0)
            tabButton(title: "Activities", index: 1)
            tabButton(title: "Medals", index: 2)
        }
        .padding(6)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button {
            selectedTab = index
            onTabChange(index)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selectedTab == index ? .white : theme.colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if selectedTab == index {
                            LinearGradient(
                                colors: [Color(hex: "A855F7"), Color(hex: "EC4899")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        } else {
                            theme.colors.cardBackground
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(12)
                .shadow(color: selectedTab == index ? .black.opacity(0.08) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - About
    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Skill levels
            VStack(alignment: .leading, spacing: 8) {
                Text("Skill Levels")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                ForEach(skillLevels.indices, id: \.self) { idx in
                    HStack {
                        Text(skillLevels[idx].sport)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        Text(skillLevels[idx].level)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "A855F7"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }
                    .padding(10)
                    .background(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(14)
                }
            }
            .padding(12)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)

            // Interests
            VStack(alignment: .leading, spacing: 8) {
                Text("Interests")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Text(interests)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.textSecondary)
                    .lineSpacing(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }

    // MARK: - Activities
    private var activitiesTab: some View {
        VStack(spacing: 10) {
            ForEach(recentActivities) { activity in
                ActivityRow(activity: activity)
                    .environmentObject(theme)
            }
        }
    }

    // MARK: - Medals
    private var medalsTab: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(achievements.indices, id: \.self) { idx in
                AchievementTile(item: achievements[idx])
                    .environmentObject(theme)
            }
        }
    }
}

// MARK: - Activity Row (lightweight)
private struct ActivityRow: View {
    @EnvironmentObject private var theme: Theme
    let activity: Activity

    var body: some View {
        HStack(spacing: 10) {
            Text(activity.sportIcon)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "calendar").font(.system(size: 11))
                    Text("\(activity.date) • \(activity.time)")
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 11))
                    Text(activity.location)
                }
                .font(.system(size: 11))
                .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(activity.spotsTaken)/\(activity.spotsTotal)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "A855F7"))
                Text(activity.level)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Achievement Tile (compact)
private struct AchievementTile: View {
    @EnvironmentObject private var theme: Theme
    let item: AchievementData

    var body: some View {
        VStack(spacing: 6) {
            Text(item.icon).font(.system(size: 28))
            Text(item.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text(item.description)
                .font(.system(size: 11))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }
}

// MARK: - Preview
#Preview {
    ProfilePage(
        onSettingsClick: {},
        onAchievementsClick: {}
    )
    .environmentObject(Theme())
}
