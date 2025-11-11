//
//  AISuggestionsView.swift
//  NEXO
//
//  Created by ROCCO 4X on 11/2025.
//

import SwiftUI

// MARK: - Main View
struct AISuggestionsView: View {
    var onBack: (() -> Void)?
    var onJoinActivity: ((ActivitySuggestion) -> Void)?

    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = AISuggestionsViewModel()

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 0) {
                header

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasSuggestions {
                    ScrollView {
                        VStack(spacing: 14) {
                            whyTheseSection

                            ForEach(viewModel.aiSuggestions) { activity in
                                ActivityCard(
                                    activity: activity,
                                    isSaved: viewModel.isSaved(activity.id),
                                    onSaveToggle: { id in
                                        viewModel.toggleSave(id)
                                        viewModel.trackSuggestionSaved(activity)
                                    },
                                    onJoin: { activity in
                                        viewModel.joinActivity(activity)
                                        onJoinActivity?(activity)
                                    }
                                )
                                .environmentObject(theme)
                                .onAppear {
                                    viewModel.trackSuggestionViewed(activity)
                                }
                            }

                            moreComingCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                } else {
                    emptyStateView
                }
            }
        }
        .ignoresSafeArea()
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
                    Text(viewModel.headerTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(viewModel.headerSubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()
                
                if viewModel.savedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#EF4444"))
                        Text("\(viewModel.savedCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.colors.cardBackground)
                    .cornerRadius(12)
                }
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
                            Text(viewModel.personalizationTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text(viewModel.personalizationDescription)
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
                Text(viewModel.whyTheseTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            Text(viewModel.whyTheseDescription)
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

            Text(viewModel.moreComingTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text(viewModel.moreComingDescription)
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text("Loading AI suggestions...")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            Text("No suggestions yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text("Complete your profile to get personalized activity recommendations")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { viewModel.refreshSuggestions() }) {
                Text("Refresh")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
