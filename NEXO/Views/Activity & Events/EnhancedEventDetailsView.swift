//
//  EnhancedEventDetailsView.swift
//  NEXO
//
//  Created by ROCCO 4X on 5/11/2025.
//

import SwiftUI

// MARK: - Data Models
struct Coach {
    let name: String
    let avatar: String
    let isVerified: Bool
    let rating: Double
    let totalReviews: Int
    let bio: String
    let certifications: [String]
}

struct EventParticipant: Identifiable {
    let id: String
    let name: String
    let avatar: String
}

struct Review: Identifiable {
    let id: String
    let userName: String
    let userAvatar: String
    let rating: Int
    let comment: String
    let date: String
}

struct EnhancedEvent {
    let id: String
    let title: String
    let sportIcon: String
    let sportType: String
    let date: String
    let time: String
    let duration: String
    let location: String
    let distance: String
    let price: Double
    let type: String
    let level: String
    let maxParticipants: Int
    let currentParticipants: Int
    let description: String
    let requirements: [String]
    let coach: Coach
}

// MARK: - Main View
struct EnhancedEventDetailsView: View {
    @EnvironmentObject private var theme: Theme

    var onBack: () -> Void
    var onJoin: () -> Void
    var onViewCoach: () -> Void
    var onMessage: () -> Void
    var isCoachView: Bool = false

    @State private var isSaved = false
    @State private var selectedTab = "details"

    private let event = EnhancedEvent(
        id: "1",
        title: "Morning HIIT Bootcamp",
        sportIcon: "🏃",
        sportType: "HIIT Training",
        date: "Nov 5, 2025",
        time: "7:00 AM",
        duration: "60 min",
        location: "Central Park - Main Field",
        distance: "2.1 mi away",
        price: 25,
        type: "paid",
        level: "Intermediate",
        maxParticipants: 12,
        currentParticipants: 8,
        description: "High-intensity interval training session focused on building strength and endurance. Perfect for all fitness levels with modifications available. Bring water and a workout mat!",
        requirements: ["Yoga mat", "Water bottle", "Athletic shoes"],
        coach: Coach(
            name: "Alex Thompson",
            avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex",
            isVerified: true,
            rating: 4.8,
            totalReviews: 124,
            bio: "Certified personal trainer with 8+ years of experience",
            certifications: ["NASM-CPT", "ACE"]
        )
    )

    private let participants = [
        EventParticipant(id: "1", name: "Sarah M.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah"),
        EventParticipant(id: "2", name: "Mike R.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Mike"),
        EventParticipant(id: "3", name: "Emma L.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma"),
        EventParticipant(id: "4", name: "John D.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=John"),
        EventParticipant(id: "5", name: "Lisa K.", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Lisa")
    ]

    private let reviews = [
        Review(id: "1", userName: "Sarah M.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah", rating: 5, comment: "Excellent workout! Alex is very motivating and adjusts exercises for different levels.", date: "Oct 28, 2025"),
        Review(id: "2", userName: "Mike R.", userAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Mike", rating: 5, comment: "Great session, challenging but fun. Highly recommend!", date: "Oct 25, 2025")
    ]

    var body: some View {
        ZStack {
            // Use the same background reference as SettingsView/Profile
            theme.colors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        eventHeader
                        coachCard
                        tabBar
                        tabContent
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 120) // leave space for bottom bar
                }
            }
        }
        // Toolbar styled with Theme references
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
                    Text("Event Details")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(event.sportType)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button(action: { isSaved.toggle() }) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSaved ? Color(hex: "#EF4444") : theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                    }
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        // Bottom booking bar pinned
        .safeAreaInset(edge: .bottom) { bottomBar }
    }
}

// MARK: - Subviews themed with Theme
private extension EnhancedEventDetailsView {

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(event.sportIcon)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(theme.colors.cardBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                    )
                    .cornerRadius(14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(event.sportType)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.95))
                }
                Spacer()
            }

            if event.coach.isVerified {
                Text("✓ Hosted by Verified Coach")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    infoBox(icon: "calendar", label: "Date", value: event.date)
                    infoBox(icon: "clock", label: "Time", value: event.time)
                }
                HStack(spacing: 8) {
                    infoBox(icon: "mappin.and.ellipse", label: "Distance", value: event.distance)
                    infoBox(icon: "dollarsign", label: "Price", value: "$\(Int(event.price))")
                }
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }

    private func infoBox(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11))
                    .opacity(0.9)
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: event.coach.avatar)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 2))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.coach.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(String(format: "%.1f", event.coach.rating)) (\(event.coach.totalReviews) reviews)")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                Spacer()
            }

            Text(event.coach.bio)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)

            HStack(spacing: 6) {
                ForEach(event.coach.certifications, id: \.self) { cert in
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#A855F7"))
                        Text(cert)
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.colors.cardBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }

            HStack(spacing: 8) {
                Button("View Profile") { onViewCoach() }
                    .buttonStyle(BrandButtonStyle(variant: .outline))
                Button(action: onMessage) {
                    Label("Message", systemImage: "message")
                }
                .buttonStyle(BrandButtonStyle(variant: .outline))
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal, 16)
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(["details", "participants", "reviews"], id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.capitalized)
                        .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(selectedTab == tab ? Color(hex: "#A855F7") : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedTab == tab ? Color(hex: "#A855F7") : theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }

    private var tabContent: some View {
        VStack(spacing: 10) {
            if selectedTab == "details" {
                availabilityCard
                aboutCard
                whatToBringCard
                locationCard
            } else if selectedTab == "participants" {
                participantsList
            } else {
                reviewsList
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut, value: selectedTab)
    }

    private var availabilityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Availability")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            let spotsLeft = event.maxParticipants - event.currentParticipants
            let fillPercentage = Double(event.currentParticipants) / Double(event.maxParticipants)
            VStack(spacing: 6) {
                HStack {
                    Text("\(event.currentParticipants)/\(event.maxParticipants) joined")
                    Spacer()
                    Text("\(spotsLeft) spots left")
                }
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#A855F7"))
                            .frame(width: geo.size.width * fillPercentage, height: 8)
                    }
                }
                .frame(height: 8)

                if spotsLeft <= 3 {
                    Text("⚠️ Almost full - book now!")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EA580C"))
                }
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var aboutCard: some View {
        infoCard(title: "About this session", content: event.description)
    }

    private var whatToBringCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What to bring")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            ForEach(event.requirements, id: \.self) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#A855F7"))
                        .frame(width: 6, height: 6)
                    Text(item)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(event.location)
            }
            .font(.system(size: 12))
            .foregroundColor(theme.colors.textSecondary)

            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .frame(height: 130)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .overlay(
                    Text("Map view")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                )
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var participantsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(event.currentParticipants) people are joining this session")
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
            ForEach(participants) { p in
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: p.avatar)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color(hex: "#A855F7"))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 2))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                        Text("Joined this event")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    Spacer()
                    Button("View") {}
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.colors.cardBackground)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(14)
                }
                .padding(12)
                .background(theme.colors.cardBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }

    private var reviewsList: some View {
        VStack(spacing: 10) {
            ForEach(reviews) { r in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: r.userAvatar)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.userName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            Text(r.date)
                                .font(.system(size: 11))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                            Text("\(r.rating)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                    Text(r.comment)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(12)
                .background(theme.colors.cardBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if isCoachView {
                    Button("Edit Event") {}
                        .buttonStyle(BrandButtonStyle(variant: .outline))
                    Button("Manage Participants") {}
                        .buttonStyle(BrandButtonStyle(variant: .default))
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.textSecondary)
                        Text("$\(Int(event.price))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#A855F7"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Book Now", action: onJoin)
                        .buttonStyle(BrandButtonStyle(variant: .default))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.colors.cardBackground.opacity(0.7))
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(theme.colors.cardStroke).frame(height: 1), alignment: .top)
        }
    }

    private func infoCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text(content)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Preview
struct EnhancedEventDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EnhancedEventDetailsView(
                onBack: {},
                onJoin: {},
                onViewCoach: {},
                onMessage: {},
                isCoachView: false
            )
            .environmentObject(Theme())
        }
    }
}
