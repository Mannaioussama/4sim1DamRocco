//
//  AISuggestionsView.swift
//  NEXO
//
//  Created by ROCCO 4X on 11/2025.
//

import SwiftUI

// MARK: - Data Model
struct ActivitySuggestion: Identifiable {
    let id: String
    let title: String
    let sportType: String
    let sportIcon: String
    let level: String
    let hostName: String
    let hostAvatar: String
    let date: String
    let time: String
    let location: String
    let distance: String
    let spotsTotal: Int
    let spotsTaken: Int
    let description: String
}

// MARK: - Main View
struct AISuggestionsView: View {
    var onBack: (() -> Void)?
    var onJoinActivity: ((ActivitySuggestion) -> Void)?

    @EnvironmentObject private var theme: Theme
    @State private var savedActivities: Set<String> = []

    // MARK: - Mock AI suggestions
    private let aiSuggestions: [ActivitySuggestion] = [
        .init(id: "ai-1",
              title: "Morning Beach Volleyball Match",
              sportType: "Volleyball",
              sportIcon: "🏐",
              level: "Intermediate",
              hostName: "Emma Wilson",
              hostAvatar: "https://i.pravatar.cc/150?img=5",
              date: "Today",
              time: "8:00 AM",
              location: "Santa Monica Beach",
              distance: "1.2 mi",
              spotsTotal: 12,
              spotsTaken: 8,
              description: "Join us for a fun morning volleyball session!"),
        .init(id: "ai-2",
              title: "Evening Running Group",
              sportType: "Running",
              sportIcon: "🏃",
              level: "All Levels",
              hostName: "Michael Chen",
              hostAvatar: "https://i.pravatar.cc/150?img=12",
              date: "Today",
              time: "6:30 PM",
              location: "Central Park",
              distance: "0.8 mi",
              spotsTotal: 15,
              spotsTaken: 10,
              description: "Easy-paced group run for all fitness levels"),
        .init(id: "ai-3",
              title: "Yoga & Meditation Session",
              sportType: "Yoga",
              sportIcon: "🧘",
              level: "Beginner",
              hostName: "Sarah Johnson",
              hostAvatar: "https://i.pravatar.cc/150?img=9",
              date: "Tomorrow",
              time: "7:00 AM",
              location: "Zen Studio",
              distance: "1.5 mi",
              spotsTotal: 20,
              spotsTaken: 15,
              description: "Start your day with mindful movement"),
        .init(id: "ai-4",
              title: "Pickup Basketball Game",
              sportType: "Basketball",
              sportIcon: "🏀",
              level: "Intermediate",
              hostName: "James Rodriguez",
              hostAvatar: "https://i.pravatar.cc/150?img=15",
              date: "Tomorrow",
              time: "5:00 PM",
              location: "Downtown Court",
              distance: "2.1 mi",
              spotsTotal: 10,
              spotsTaken: 7,
              description: "Competitive but friendly basketball match")
    ]

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 14) {
                        whyTheseSection

                        ForEach(aiSuggestions) { activity in
                            ActivityCard(
                                activity: activity,
                                isSaved: savedActivities.contains(activity.id),
                                onSaveToggle: toggleSave,
                                onJoin: onJoinActivity
                            )
                            .environmentObject(theme)
                        }

                        moreComingCard
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Actions
    private func toggleSave(_ id: String) {
        if savedActivities.contains(id) {
            savedActivities.remove(id)
        } else {
            savedActivities.insert(id)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { onBack?() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(8)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("For You")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text("AI-powered recommendations")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal)

            HStack {
                ZStack {
                    LinearGradient(colors: [.purple, .pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                        .cornerRadius(20)
                        .frame(height: 72)
                        .shadow(radius: 5, y: 3)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 40, height: 40)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Personalized Picks")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Based on your activity & preferences")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(theme.colors.barMaterial)
    }

    // MARK: - Why these section
    private var whyTheseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
                    .frame(width: 24, height: 24)
                    .overlay(Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white))
                Text("Why these activities?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            Text("We've selected activities matching your skill level, preferred sports, and schedule. These are nearby and have availability.")
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.leading, 30)
        }
        .padding()
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
    }

    // MARK: - More coming section
    private var moreComingCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple.opacity(0.15), .pink.opacity(0.15)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
            }

            Text("More suggestions coming")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text("As you join more activities, our AI will get better at recommending perfect matches.")
                .font(.system(size: 13))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
    }

    // MARK: - Background Orbs
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -120, y: -150)

            Circle()
                .fill(LinearGradient(colors: [.blue.opacity(0.25), .cyan.opacity(0.2)],
                                     startPoint: .bottomLeading,
                                     endPoint: .topTrailing))
                .frame(width: 350, height: 350)
                .blur(radius: 60)
                .offset(x: 160, y: 300)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    @EnvironmentObject private var theme: Theme
    let activity: ActivitySuggestion
    let isSaved: Bool
    var onSaveToggle: (String) -> Void
    var onJoin: ((ActivitySuggestion) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                AsyncImage(url: URL(string: activity.hostAvatar)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.hostName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                    HStack(spacing: 4) {
                        Text(activity.sportIcon)
                        Text(activity.sportType)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                Button(action: { onSaveToggle(activity.id) }) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .foregroundColor(isSaved ? Color(hex: "#EF4444") : theme.colors.textSecondary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            Text(activity.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)

            Group {
                Label("\(activity.date) • \(activity.time)", systemImage: "clock")
                Label("\(activity.location) • \(activity.distance)", systemImage: "mappin.and.ellipse")
                Label("\(activity.spotsTotal - activity.spotsTaken) of \(activity.spotsTotal) spots remaining", systemImage: "person.3")
            }
            .font(.system(size: 12))
            .foregroundColor(theme.colors.textSecondary)

            HStack {
                Text(activity.level)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(LinearGradient(colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .clipShape(Capsule())

                Spacer()

                Button(action: { onJoin?(activity) }) {
                    Text("Join")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(theme.colors.accentGreen)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .overlay(
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                Text("AI Pick")
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(6)
            .background(LinearGradient(colors: [.purple, .pink],
                                       startPoint: .leading,
                                       endPoint: .trailing))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .offset(x: 0, y: -10),
            alignment: .topTrailing
        )
    }
}

// MARK: - Preview
#Preview {
    AISuggestionsView()
        .environmentObject(Theme())
}
