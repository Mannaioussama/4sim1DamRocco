//
//  CoachProfileView.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI

struct CoachProfileView: View {
    @EnvironmentObject private var theme: Theme

    @State private var isFollowing = false
    @State private var selectedTab = "about"

    var onBack: (() -> Void)?
    var onBookSession: (() -> Void)?
    var onMessage: (() -> Void)?

    // Mock Coach Data
    private let coach = CoachProfileData(
        name: "Alex Thompson",
        avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
        isVerified: true,
        bio: "Certified personal trainer with 8+ years of experience. Specialized in HIIT, strength training, and functional fitness.",
        rating: 4.8,
        totalReviews: 124,
        location: "Los Angeles, CA",
        specializations: ["HIIT", "Strength Training", "Yoga", "Running"],
        certifications: ["NASM-CPT", "ACE", "Yoga Alliance RYT-200"],
        experience: "8 years",
        totalSessions: 450,
        followers: 1234
    )

    private let upcomingSessions = [
        CoachSession(id: "1", title: "Morning HIIT Bootcamp", date: "Nov 5, 2025", time: "7:00 AM", location: "Central Park", price: 25, spotsLeft: 4, sportIcon: "🏃"),
        CoachSession(id: "2", title: "Yoga & Meditation", date: "Nov 6, 2025", time: "6:00 PM", location: "Zen Studio", price: 20, spotsLeft: 5, sportIcon: "🧘"),
        CoachSession(id: "3", title: "Strength & Conditioning", date: "Nov 7, 2025", time: "5:30 PM", location: "FitHub Gym", price: 30, spotsLeft: 2, sportIcon: "💪")
    ]

    private let reviews = [
        CoachReview(id: "1", userName: "Sarah M.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah", rating: 5, comment: "Alex is an amazing coach! Motivating, knowledgeable, and really cares about your progress.", date: "Oct 28, 2025"),
        CoachReview(id: "2", userName: "Mike R.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Mike", rating: 5, comment: "Best trainer I've worked with. Great at explaining proper form and technique.", date: "Oct 25, 2025"),
        CoachReview(id: "3", userName: "Emma L.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma", rating: 4, comment: "Really enjoyed the HIIT sessions. Challenging but fun!", date: "Oct 22, 2025")
    ]

    var body: some View {
        ZStack {
            // Themed background with subtle orbs
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.bottom, 12)
                    statsRow
                        .offset(y: -28)
                    tabsControl
                        .padding(.top, -4)
                    tabContent
                        .padding(.top, 12)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Coach Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.cardBackground, in: Circle())
                            .background(theme.colors.barMaterial, in: Circle())
                            .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.cardBackground, in: Circle())
                        .background(theme.colors.barMaterial, in: Circle())
                        .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationBarBackButtonHidden(onBack != nil)
    }

    // MARK: - Themed Background Orbs
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.22 : 0.4),
                             theme.colors.accentPink.opacity(theme.isDarkMode ? 0.18 : 0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 288, height: 288)
                .blur(radius: 120)
                .offset(x: -100, y: -200)

            Circle()
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(theme.isDarkMode ? 0.18 : 0.3),
                             theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.16 : 0.3)],
                    startPoint: .bottomLeading, endPoint: .topTrailing
                ))
                .frame(width: 384, height: 384)
                .blur(radius: 120)
                .offset(x: 150, y: 500)

            Circle()
                .fill(LinearGradient(
                    colors: [theme.colors.accentPink.opacity(theme.isDarkMode ? 0.16 : 0.25),
                             theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.12 : 0.2)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: 150, y: -100)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Gradient Header (Hero)
    private var profileHeader: some View {
        ZStack {
            LinearGradient(
                colors: [theme.colors.accentPurple, theme.colors.accentPink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                // Avatar with verification badge
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: coach.avatar)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.white.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 4)

                    if coach.isVerified {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.colors.accentGreenFill)
                        }
                        .offset(x: 4, y: 4)
                    }
                }
                .padding(.top, 24)

                // Name
                Text(coach.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                // Verified badge
                if coach.isVerified {
                    Text("✓ Verified Coach")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }

                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Text(String(format: "%.1f", coach.rating))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("(\(coach.totalReviews) reviews)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.95))
                }

                // Location
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                    Text(coach.location)
                        .font(.system(size: 13))
                }
                .foregroundColor(.white.opacity(0.95))
                .padding(.bottom, 16)

                // Action Buttons
                HStack(spacing: 8) {
                    Button {
                        isFollowing.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isFollowing ? "heart.fill" : "heart")
                                .font(.system(size: 14))
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            isFollowing
                                ? Color.white.opacity(0.2)
                                : Color.white
                        )
                        .foregroundColor(
                            isFollowing
                                ? .white
                                : theme.colors.accentPurple
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    isFollowing
                                        ? Color.white.opacity(0.3)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .cornerRadius(18)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        onMessage?()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "message")
                                .font(.system(size: 14))
                            Text("Message")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white)
                        .foregroundColor(theme.colors.accentPurple)
                        .cornerRadius(18)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(height: 350)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 8) {
            statTile(value: "\(coach.totalSessions)", label: "Sessions")
            statTile(value: "\(coach.followers)", label: "Followers")
            statTile(value: coach.experience, label: "Experience")
        }
        .padding(.horizontal, 16)
        .zIndex(2)
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 72)
        .padding(.vertical, 14)
        .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }

    // MARK: - Tabs
    private var tabsControl: some View {
        ZStack {
            // Background rail
            HStack(spacing: 0) {
                ForEach(["about", "sessions", "reviews"], id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
            .frame(height: 40)
            .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 10))
            .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )

            // Sliding indicator
            GeometryReader { geometry in
                let tabWidth = geometry.size.width / 3
                let index = ["about", "sessions", "reviews"].firstIndex(of: selectedTab) ?? 0

                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.colors.accentPurple)
                    .frame(width: tabWidth - 10, height: 34)
                    .offset(x: CGFloat(index) * tabWidth + 5, y: 3)
                    .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }

            // Buttons
            HStack(spacing: 0) {
                ForEach(["about", "sessions", "reviews"], id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.capitalized)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : theme.colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 16)
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        VStack(spacing: 12) {
            switch selectedTab {
            case "about": aboutTab
            case "sessions": sessionsTab
            case "reviews": reviewsTab
            default: aboutTab
            }
        }
        .padding(.horizontal, 16)
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            // About Card
            themedCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(coach.bio)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(3)
                }
            }

            // Specializations Card
            themedCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Specializations")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)

                    WrapHStack(items: coach.specializations) { item in
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.colors.cardBackground, in: Capsule())
                            .background(theme.colors.barMaterial, in: Capsule())
                            .foregroundColor(theme.colors.textPrimary)
                            .overlay(
                                Capsule().stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                    }
                }
            }

            // Certifications Card
            themedCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Certifications")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(coach.certifications, id: \.self) { cert in
                            HStack(spacing: 8) {
                                Image(systemName: "rosette")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.colors.accentPurple)
                                Text(cert)
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var sessionsTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Sessions")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)

            ForEach(upcomingSessions) { session in
                themedCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            // Sport icon tile
                            Text(session.sportIcon)
                                .font(.system(size: 20))
                                .frame(width: 40, height: 40)
                                .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                                .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )

                            // Title + meta
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.colors.textPrimary)
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 12))
                                    Text("\(session.date) • \(session.time)")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(theme.colors.textSecondary)

                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 12))
                                    Text(session.location)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(theme.colors.textSecondary)
                            }

                            Spacer()

                            // Price + spots
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("$\(Int(session.price))")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(theme.colors.accentPurple)
                                Text("\(session.spotsLeft) spots")
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }

                        Button {
                            onBookSession?()
                        } label: {
                            Text("Book Session")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    LinearGradient(
                                        colors: [theme.colors.accentPurple, theme.colors.accentPink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: theme.colors.accentPurple.opacity(0.25), radius: 8, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
    }

    private var reviewsTab: some View {
        VStack(spacing: 10) {
            ForEach(reviews) { review in
                themedCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            AsyncImage(url: URL(string: review.userAvatar)) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(review.userName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.colors.textPrimary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 14))
                                        Text("\(review.rating)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(theme.colors.textPrimary)
                                    }
                                }
                                Text(review.date)
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }

                        Text(review.comment)
                            .font(.system(size: 13))
                            .foregroundColor(theme.colors.textSecondary)
                            .lineSpacing(3)
                    }
                }
            }
        }
    }

    // MARK: - Themed Card Helper
    private func themedCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

// MARK: - Models
struct CoachProfileData {
    let name: String
    let avatar: String
    let isVerified: Bool
    let bio: String
    let rating: Double
    let totalReviews: Int
    let location: String
    let specializations: [String]
    let certifications: [String]
    let experience: String
    let totalSessions: Int
    let followers: Int
}

struct CoachSession: Identifiable {
    let id: String
    let title: String
    let date: String
    let time: String
    let location: String
    let price: Double
    let spotsLeft: Int
    let sportIcon: String
}

struct CoachReview: Identifiable {
    let id: String
    let userName: String
    let userAvatar: String
    let rating: Int
    let comment: String
    let date: String
}

// MARK: - WrapHStack
struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    @State private var totalHeight = CGFloat.zero
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in height })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geo.size.height
            }
            return Color.clear
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CoachProfileView(
            onBack: {},
            onBookSession: {},
            onMessage: {}
        )
        .environmentObject(Theme())
    }
}
