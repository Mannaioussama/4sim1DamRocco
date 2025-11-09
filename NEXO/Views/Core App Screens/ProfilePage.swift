// Functional old ProfilePage with working pencil (gallery/files) and upload hook, trimmed per your request.
// CoachDashboardButton removed. Missing subviews (StatPill, AchievementsButton, ProfileCrystalTabs, etc.) are included here.

import SwiftUI
import PhotosUI

// MARK: - User Model

struct UserProfile {
    let name: String
    let bio: String
    let location: String
    var avatar: String
    let stats: UserStats
}

struct UserStats {
    let sessionsJoined: Int
    let sessionsHosted: Int
    let rating: Double
    let favoriteSports: [String]
}

struct ProfilePage: View {
    @EnvironmentObject private var theme: Theme
    @State private var selectedTab = 0

    // Picker + upload state
    @State private var showSourceSheet = false
    @State private var showPhotoPicker = false
    @State private var showFilesPicker = false
    @State private var pickedUIImage: UIImage? = nil
    @State private var isUploading = false
    @State private var uploadError: String?

    // Services (stub uploader for now)
    private let imageService = ProfileImageService()
    private let uploader: ProfileImageUploader = StubProfileImageUploader()

    var onSettingsClick: () -> Void
    var onAchievementsClick: (() -> Void)?

    // Mock user data
    @State private var currentUser = UserProfile(
        name: "Alex Thompson",
        bio: "Fitness enthusiast | Marathon runner | Yoga lover 🧘‍♀️",
        location: "San Francisco, CA",
        avatar: "https://i.pravatar.cc/150?img=33",
        stats: UserStats(
            sessionsJoined: 42,
            sessionsHosted: 15,
            rating: 4.9,
            favoriteSports: ["Running", "Swimming", "Hiking", "Yoga", "Cycling"]
        )
    )

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

                        Button(action: onSettingsClick) {
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
                        user: currentUser,
                        pickedUIImage: pickedUIImage,
                        onPencilTap: { showSourceSheet = true }
                    )
                    .environmentObject(theme)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Quick Actions (coach dashboard removed)
                    VStack(spacing: 12) {
                        if let achievements = onAchievementsClick {
                            AchievementsButton(action: achievements)
                                .environmentObject(theme)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Tabs
                    ProfileCrystalTabs(
                        user: currentUser,
                        selectedTab: $selectedTab
                    )
                    .environmentObject(theme)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        // Sheet pickers
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker(onPick: handlePickedImage(_:), onCancel: {})
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilesPicker) {
            FilesImagePicker(onPick: handlePickedImage(_:), onCancel: {})
                .ignoresSafeArea()
        }
        // Centered source picker popup
        .overlay(sourcePickerPopup)
        // Upload overlay + error
        .overlay(uploadOverlay)
        .alert("Upload Error", isPresented: .constant(uploadError != nil), actions: {
            Button("OK") { uploadError = nil }
        }, message: {
            Text(uploadError ?? "")
        })
    }

    // MARK: - Handlers

    private func handlePickedImage(_ picked: PickedImage) {
        pickedUIImage = picked.uiImage // show immediately

        Task {
            do {
                isUploading = true
                let processed = try imageService.processForUpload(picked.uiImage)
                // Stub upload (replace with your NestJS call later)
                let newURL = try await uploader.uploadProfileImage(
                    data: processed,
                    fileName: picked.fileName,
                    mimeType: picked.mimeType
                )
                currentUser.avatar = newURL.absoluteString
            } catch {
                uploadError = error.localizedDescription
            }
            isUploading = false
        }
    }

    private func removeAvatar() {
        pickedUIImage = nil
        currentUser.avatar = ""
    }

    // MARK: - Centered source picker popup
    private var sourcePickerPopup: some View {
        Group {
            if showSourceSheet {
                ZStack {
                    // Dim background tap to dismiss
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring(response: 0.25)) { showSourceSheet = false } }

                    VStack(spacing: 12) {
                        Text("Change profile photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.top, 12)

                        VStack(spacing: 8) {
                            PopupActionButton(
                                title: "Choose from Library",
                                systemImage: "photo.on.rectangle",
                                action: {
                                    showSourceSheet = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        showPhotoPicker = true
                                    }
                                }
                            )
                            PopupActionButton(
                                title: "Choose from Files",
                                systemImage: "folder",
                                action: {
                                    showSourceSheet = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        showFilesPicker = true
                                    }
                                }
                            )
                            if pickedUIImage != nil || !currentUser.avatar.isEmpty {
                                PopupActionButton(
                                    title: "Remove Photo",
                                    systemImage: "trash",
                                    roleDestructive: true,
                                    action: {
                                        removeAvatar()
                                        withAnimation(.spring(response: 0.25)) { showSourceSheet = false }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)

                        Button(action: { withAnimation(.spring(response: 0.25)) { showSourceSheet = false } }) {
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
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: showSourceSheet)
    }

    // MARK: - Upload overlay
    private var uploadOverlay: some View {
        Group {
            if isUploading {
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
        .animation(.easeInOut, value: isUploading)
    }
}

// MARK: - PopupActionButton (local helper)
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

// MARK: - Profile Glass Card (pencil wired)
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

// MARK: - Stat Pill (included)
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

// MARK: - Achievements Button (included)
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

// MARK: - Tabs (included)
private struct ProfileCrystalTabs: View {
    @EnvironmentObject private var theme: Theme
    let user: UserProfile
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.2),
                                Color(hex: "EC4899").opacity(0.2),
                                Color(hex: "0066FF").opacity(0.2)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 12)
                    .opacity(0.5)
                    .padding(-4)

                HStack(spacing: 6) {
                    CrystalTabButton(title: "About", isSelected: selectedTab == 0) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = 0 }
                    }
                    CrystalTabButton(title: "Activities", isSelected: selectedTab == 1) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = 1 }
                    }
                    CrystalTabButton(title: "Medals", isSelected: selectedTab == 2) {
                        withAnimation(.spring(response: 0.3)) { selectedTab = 2 }
                    }
                }
                .padding(6)
            }
            .background(theme.colors.cardBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)

            Group {
                if selectedTab == 0 {
                    AboutTabContent(user: user)
                        .environmentObject(theme)
                } else if selectedTab == 1 {
                    ActivitiesTabContentUsingMock()
                        .environmentObject(theme)
                } else {
                    MedalsTabContent()
                        .environmentObject(theme)
                }
            }
        }
    }
}

private struct CrystalTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Color.black.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .cornerRadius(16)
                .shadow(color: isSelected ? Color(hex: "8B5CF6").opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - About Tab (included)
private struct AboutTabContent: View {
    @EnvironmentObject private var theme: Theme
    let user: UserProfile

    var body: some View {
        VStack(spacing: 12) {
            CrystalInfoCard(title: "Favorite Sports") {
                FlowLayout(spacing: 8) {
                    ForEach(user.stats.favoriteSports, id: \.self) { sport in
                        Text(sport)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textPrimary)
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
                }
            }
            .environmentObject(theme)

            CrystalInfoCard(title: "Interests") {
                Text("Outdoor activities • Fitness challenges • Meeting new people • Trail running • Open water swimming")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .environmentObject(theme)

            CrystalInfoCard(title: "Skill Levels") {
                VStack(spacing: 12) {
                    SkillRow(sport: "Running", level: "Intermediate")
                    SkillRow(sport: "Swimming", level: "Advanced")
                    SkillRow(sport: "Hiking", level: "Intermediate")
                }
            }
            .environmentObject(theme)
        }
    }
}

// MARK: - Activities Tab (included, uses mockActivities)
private struct ActivitiesTabContentUsingMock: View {
    @EnvironmentObject private var theme: Theme
    private let activities = Array(mockActivities.prefix(5))

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activities")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 4)

            ForEach(activities) { activity in
                ActivityRowCard(
                    icon: activity.sportIcon,
                    title: activity.title,
                    date: activity.date,
                    time: activity.time
                )
                .environmentObject(theme)
            }
        }
    }
}

private struct ActivityRowCard: View {
    @EnvironmentObject private var theme: Theme
    let icon: String
    let title: String
    let date: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(theme.colors.cardBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(date)
                        .font(.system(size: 12))
                    Text("•")
                        .font(.system(size: 12))
                    Text(time)
                        .font(.system(size: 12))
                }
                .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Medals Tab (included)
private struct MedalsTabContent: View {
    @EnvironmentObject private var theme: Theme
    let achievements = [
        ("🏃", "Marathon Runner", "Completed 5+ running events", "3498DB"),
        ("🏊", "Water Warrior", "Joined 10+ swimming sessions", "2ECC71"),
        ("👥", "Social Butterfly", "Connected with 25+ athletes", "9B59B6"),
        ("⭐", "Top Host", "Hosted 10+ successful events", "F39C12"),
        ("💪", "Consistency King", "30-day activity streak", "E74C3C"),
        ("🎯", "Goal Crusher", "Achieved 5 personal goals", "1ABC9C")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medals")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 4)

            ForEach(achievements.indices, id: \.self) { index in
                AchievementRow(
                    icon: achievements[index].0,
                    title: achievements[index].1,
                    description: achievements[index].2,
                    color: achievements[index].3
                )
                .environmentObject(theme)
            }
        }
    }
}

// MARK: - Shared subviews (included)
private struct CrystalInfoCard<Content: View>: View {
    @EnvironmentObject private var theme: Theme
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

private struct SkillRow: View {
    @EnvironmentObject private var theme: Theme
    let sport: String
    let level: String

    var body: some View {
        HStack {
            Text(sport)
                .font(.system(size: 13))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Text(level)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(theme.colors.cardBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                )
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
    }
}

private struct AchievementRow: View {
    @EnvironmentObject private var theme: Theme
    let icon: String
    let title: String
    let description: String
    let color: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(Color(hex: color).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "FBBF24"))
                .shadow(color: Color(hex: "FBBF24").opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(16)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Flow Layout (updated)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var fallbackWidth: CGFloat = 360

    init(spacing: CGFloat = 8, fallbackWidth: CGFloat = 360) {
        self.spacing = spacing
        self.fallbackWidth = fallbackWidth
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposedMaxWidth(from: proposal)
        let rows = arrangeSubviews(maxWidth: maxWidth, subviews: subviews)

        // Sum row heights + inter-row spacing
        let contentHeight = rows.reduce(0) { $0 + $1.height }
        let totalSpacing = rows.isEmpty ? 0 : spacing * CGFloat(rows.count - 1)
        let height = contentHeight + totalSpacing

        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for element in row.elements {
                subviews[element.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: element.size.width, height: element.size.height)
                )
                x += element.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func arrangeSubviews(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(height: 0, elements: [])
        var x: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            // Measure with a width-aware proposal to get stable chip sizes
            let measured = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            var size = measured

            // Defensive fallback if a subview reports an unhelpful size
            if size.width.isNaN || size.width <= 0 {
                size.width = maxWidth
            }
            if size.height.isNaN || size.height <= 0 {
                size.height = 0
            }

            if x > 0, x + size.width > maxWidth {
                rows.append(currentRow)
                currentRow = Row(height: 0, elements: [])
                x = 0
            }

            currentRow.elements.append(Element(index: index, size: size))
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }

        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private func proposedMaxWidth(from proposal: ProposedViewSize) -> CGFloat {
        // Use proposed width if finite; otherwise fall back to a conservative, parameterized constant.
        if let w = proposal.width, w > 0, w.isFinite {
            return w
        } else {
            // Avoid UIScreen.main (deprecated in iOS 26). Choose a safe default width.
            return fallbackWidth
        }
    }

    struct Row {
        var height: CGFloat
        var elements: [Element]
    }

    struct Element {
        let index: Int
        let size: CGSize
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
