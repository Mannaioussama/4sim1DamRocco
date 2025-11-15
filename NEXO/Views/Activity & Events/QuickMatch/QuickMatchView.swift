//
//  QuickMatchView.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI

// MARK: - Main View
struct QuickMatchView: View {
    var onBack: (() -> Void)?

    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = QuickMatchViewModel()

    // MARK: - View
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 16) {
                Spacer(minLength: 0)
                
                if let profile = viewModel.currentProfile {
                    // Responsive card
                    cardStack(profile: profile)
                    
                    // Actions placed below the card (no hard-coded offsets)
                    actionButtons
                        .padding(.top, 4)
                } else {
                    emptyState
                        .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 0)
            }

            if viewModel.showMatch, let matched = viewModel.matchedProfile {
                matchModal(for: matched)
            }
        }
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
                Text("Quick Match")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.accentPurple)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .navigationBarBackButtonHidden(onBack != nil)
    }
}

// MARK: - Background
private extension QuickMatchView {
    var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "E9D5FF").opacity(theme.isDarkMode ? 0.18 : 0.4),
                                              Color(hex: "DDD6FE").opacity(theme.isDarkMode ? 0.12 : 0.3)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 130, height: 130)
                .blur(radius: 50)
                .offset(x: -100, y: -180)
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "FCE7F3").opacity(theme.isDarkMode ? 0.2 : 0.5),
                                              Color(hex: "FBCFE8").opacity(theme.isDarkMode ? 0.12 : 0.3)],
                                     startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 160, height: 160)
                .blur(radius: 60)
                .offset(x: 100, y: 220)
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "E0E7FF").opacity(theme.isDarkMode ? 0.18 : 0.4),
                                              Color(hex: "C7D2FE").opacity(theme.isDarkMode ? 0.12 : 0.3)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 100, height: 100)
                .blur(radius: 40)
                .offset(x: 0, y: 140)
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "FEF3C7").opacity(theme.isDarkMode ? 0.18 : 0.4),
                                              Color(hex: "FDE68A").opacity(theme.isDarkMode ? 0.12 : 0.3)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .blur(radius: 30)
                .offset(x: 120, y: -80)
        }
        .allowsHitTesting(false)
    }
}

private struct LikesBadge: View {
    @EnvironmentObject private var theme: Theme
    let count: Int
    
    var body: some View {
        ZStack {
            // Glow effect
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [theme.colors.accentPink.opacity(0.45), theme.colors.accentPurple.opacity(0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 70, height: 40)
                .blur(radius: 10)
            
            // Main badge
            LinearGradient(
                colors: [theme.colors.accentPink, theme.colors.accentPurple],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 64, height: 40)
            .clipShape(Capsule())
            .overlay(
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
        }
        .accessibilityLabel("Likes \(count)")
    }
}

// MARK: - Card Stack
extension QuickMatchView {
    private func cardStack(profile: MatchProfile) -> some View {
        ZStack {
            GeometryReader { proxy in
                let size = proxy.size
                // Preview stack behind the main card, sized to the same container
                previewStack
                    .frame(width: size.width, height: size.height)
                
                // Base card (level 0)
                SwipeCard(profile: profile) { direction in
                    viewModel.handleSwipe(direction, profile)
                }
                .environmentObject(theme)
                .frame(width: size.width, height: size.height)
                // Likes badge anchored to the card bounds
                .overlay(alignment: .topTrailing) {
                    LikesBadge(count: viewModel.likedCount)
                        .environmentObject(theme)
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                }
            }
        }
        // Maintain the original 340x530 aspect, but make it responsive
        .frame(maxWidth: 380) // cap on large screens
        .aspectRatio(340.0 / 530.0, contentMode: .fit)
        .padding(.horizontal, 16) // breathing room on small screens
    }
    
    private var previewStack: some View {
        ZStack {
            ForEach(Array(viewModel.nextProfiles.enumerated()), id: \.element.id) { index, _ in
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                    .shadow(
                        color: .black.opacity(theme.isDarkMode ? 0.12 : 0.0),
                        radius: theme.isDarkMode ? 10 : 0,
                        y: theme.isDarkMode ? 6 : 0
                    )
                    .scaleEffect(1 - CGFloat(index + 1) * 0.05)
                    .offset(y: -CGFloat(index + 1) * 10)
                    .opacity(theme.isDarkMode ? (1 - Double(index + 1) * 0.15) : 0)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            PassButton(action: { viewModel.handlePass() })
            LikeButton(action: { viewModel.handleLike() })
        }
        .environmentObject(theme)
    }
}

private struct PassButton: View {
    @EnvironmentObject private var theme: Theme
    let action: () -> Void
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(theme.isDarkMode ? 0.25 : 0.3), Color.gray.opacity(theme.isDarkMode ? 0.3 : 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .blur(radius: 8)
            
            Button(action: action) {
                Circle()
                    .fill(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: "#F87171"))
                    )
                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.15), radius: 10, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

private struct LikeButton: View {
    @EnvironmentObject private var theme: Theme
    let action: () -> Void
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.colors.accentGreen.opacity(0.4), theme.colors.accentGreen.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .blur(radius: 8)
            
            Button(action: action) {
                Circle()
                    .fill(theme.colors.accentGreen)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.15), radius: 10, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - SwipeCard
struct SwipeCard: View {
    @EnvironmentObject private var theme: Theme
    let profile: MatchProfile
    var onSwipe: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero
    @GestureState private var isDragging = false

    var body: some View {
        GeometryReader { _ in
            ZStack {
                glowBackground
                cardContent
            }
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .offset(offset)
            .opacity(2 - Double(abs(offset.width) / 100))
            .gesture(dragGesture)
        }
    }
    
    private var glowBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "E9D5FF").opacity(theme.isDarkMode ? 0.18 : 0.12),
                        Color(hex: "FCE7F3").opacity(theme.isDarkMode ? 0.16 : 0.10),
                        Color(hex: "E0E7FF").opacity(theme.isDarkMode ? 0.18 : 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: 12)
            .padding(-4)
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            coverImageSection
            infoSection
        }
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(theme.isDarkMode ? 0.35 : 0.1), radius: theme.isDarkMode ? 18 : 20, y: theme.isDarkMode ? 8 : 10)
    }
    
    private var coverImageSection: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: profile.coverImage)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(theme.isDarkMode ? 0.25 : 0.2)
            }
            .frame(height: 224)
            .clipped()
            
            coverGradients
            swipeIndicators
            nameLocationOverlay
        }
        .frame(height: 224)
    }
    
    private var coverGradients: some View {
        ZStack {
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 224)
            
            LinearGradient(
                colors: [Color.white.opacity(theme.isDarkMode ? 0.16 : 0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 130)
        }
    }
    
    private var swipeIndicators: some View {
        HStack {
            if offset.width > 30 {
                indicator(text: "LIKE", color: theme.colors.accentGreen)
                    .rotationEffect(.degrees(-20))
                    .padding(.leading, 12)
                    .padding(.top, 12)
            }
            
            Spacer()
            
            if offset.width < -30 {
                indicator(text: "NOPE", color: Color(hex: "#F87171"))
                    .rotationEffect(.degrees(20))
                    .padding(.trailing, 12)
                    .padding(.top, 12)
            }
        }
    }
    
    private func indicator(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.9), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
    
    private var nameLocationOverlay: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(profile.name), \(profile.age)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 11))
                Text("\(profile.location) • \(profile.distance)")
                    .font(.system(size: 11))
            }
            .foregroundColor(.white.opacity(0.9))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .padding(.leading, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
    
    private var infoSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                statsRow
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                
                Text(profile.bio)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.textPrimary)
                    .lineSpacing(2)
                    .padding(.horizontal, 10)
                
                favoriteSports
                    .padding(.horizontal, 10)
                
                interestsSection
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        }
        .frame(height: 306)
    }
    
    private var statsRow: some View {
        HStack(spacing: 6) {
            ratingStat
            activitiesStat
        }
    }
    
    private var ratingStat: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", profile.rating))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            Text("Rating")
                .font(.system(size: 10))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(theme.isDarkMode ? 0.2 : 0.05), radius: 4, y: 2)
    }
    
    private var activitiesStat: some View {
        VStack(spacing: 4) {
            Text("\(profile.activitiesJoined)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            
            Text("Activities")
                .font(.system(size: 10))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(theme.isDarkMode ? 0.2 : 0.05), radius: 4, y: 2)
    }
    
    private var favoriteSports: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Favorite Sports")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: 10) {
                ForEach(profile.sports) { sport in
                    sportPill(sport)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func sportPill(_ sport: SportInfo) -> some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                )
                .shadow(color: .black.opacity(theme.isDarkMode ? 0.2 : 0.05), radius: 4, y: 2)
                .overlay(
                    VStack(spacing: 2) {
                        Text(sport.icon)
                            .font(.system(size: 24))
                        Text(sport.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                )
            
            Text(sport.level)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(theme.colors.accentPurple)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .offset(y: 4)
        }
    }
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Interests")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            QuickMatchFlowLayout(spacing: 6) {
                ForEach(profile.interests, id: \.self) { interest in
                    Text(interest)
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(theme.colors.cardStroke, lineWidth: 2)
                        )
                        .cornerRadius(999)
                }
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { gesture in
                offset = gesture.translation
            }
            .onEnded { gesture in
                if gesture.translation.width > 100 {
                    withAnimation(.spring()) {
                        offset = CGSize(width: 500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSwipe(.right)
                        offset = .zero
                    }
                } else if gesture.translation.width < -100 {
                    withAnimation(.spring()) {
                        offset = CGSize(width: -500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSwipe(.left)
                        offset = .zero
                    }
                } else {
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                }
            }
    }
}

// MARK: - Empty State
extension QuickMatchView {
    private var emptyState: some View {
        VStack(spacing: 16) {
            emptyStateIcon
            
            Text("All caught up!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            
            Text("You've seen all available profiles. Check back later for more sport buddies!")
                .font(.system(size: 15))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(3)
            
            backButtonRow
                .padding(.horizontal, 40)
                .padding(.top, 8)
        }
    }
    
    private var emptyStateIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "E9D5FF").opacity(theme.isDarkMode ? 0.18 : 0.4),
                                 Color(hex: "FCE7F3").opacity(theme.isDarkMode ? 0.16 : 0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
                .blur(radius: 20)
            
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.colors.cardBackground)
                .frame(width: 96, height: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                )
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(theme.isDarkMode ? 0.14 : 0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(24)
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(theme.colors.accentPurple)
                )
                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.1), radius: 20, y: 10)
        }
    }
    
    private var backButtonRow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "E9D5FF").opacity(theme.isDarkMode ? 0.18 : 0.3),
                            Color(hex: "FCE7F3").opacity(theme.isDarkMode ? 0.16 : 0.3),
                            Color(hex: "E0E7FF").opacity(theme.isDarkMode ? 0.18 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 12)
                .frame(height: 52)
                .padding(.horizontal, -4)
            
            Button(action: { onBack?() }) {
                Text("Back to Home")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(theme.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(theme.isDarkMode ? 0.14 : 0.5), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .cornerRadius(24)
                    )
                    .cornerRadius(24)
                    .shadow(color: theme.colors.accentPurple.opacity(0.2), radius: 15, y: 8)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Match Modal
extension QuickMatchView {
    private func matchModal(for profile: MatchProfile) -> some View {
        ZStack {
            LinearGradient(
                colors: [theme.colors.accentPink, theme.colors.accentPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(0.95)

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                Text("It's a Match!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("You and \(profile.name) both like each other")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                AsyncImage(url: URL(string: profile.avatar)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.2))
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                .padding(.top, 16)
                
                Text("Starting a conversation...")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 8)
            }
            .transition(.scale .combined(with: .opacity))
        }
    }
}

// MARK: - Simple Horizontal Layout used in Interests
struct QuickMatchFlowLayout<Content: View>: View {
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

#if DEBUG
struct QuickMatchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuickMatchView()
                .environmentObject(Theme())
        }
    }
}
#endif
