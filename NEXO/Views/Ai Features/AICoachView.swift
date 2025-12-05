//
//  AICoachView.swift
//  NEXO
//
//  New backend-driven AI Coach UI (suggestions, tips, videos).

import SwiftUI

struct AICoachView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = AICoachViewModel()

    var body: some View {
        VStack(spacing: 0) {
            StatsHeaderView(viewModel: viewModel)

            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(AICoachViewModel.AICoachTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch viewModel.selectedTab {
                case .suggestions:
                    SuggestionsTabView(viewModel: viewModel)
                case .tips:
                    TipsTabView(viewModel: viewModel)
                case .videos:
                    YouTubeVideosTabView(viewModel: viewModel)
                }
            }
        }
        .navigationTitle("AI Coach")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if viewModel.suggestions.isEmpty {
                viewModel.loadSuggestions()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Stats Header

struct StatsHeaderView: View {
    @ObservedObject var viewModel: AICoachViewModel
    @State private var isPresentingStrava = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatCard(title: "Workouts", value: "\(viewModel.weeklyWorkouts)", icon: "figure.run", color: .blue)
                StatCard(title: "Calories", value: "\(viewModel.weeklyCalories)", icon: "flame.fill", color: .orange)
                StatCard(title: "Minutes", value: "\(viewModel.weeklyMinutes)", icon: "clock.fill", color: .green)
                StatCard(title: "Streak", value: "\(viewModel.currentStreak)", icon: "flame.fill", color: .red)
            }
            .padding(.horizontal)

            if viewModel.stravaData == nil {
                Button {
                    isPresentingStrava = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("Connect Strava for better suggestions")
                    }
                    .font(.system(size: 13, weight: .semibold))
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .sheet(isPresented: $isPresentingStrava) {
            if let url = stravaConnectURL {
                SafariView(url: url)
            }
        }
    }

    private var stravaConnectURL: URL? {
        var components = URLComponents(string: "https://www.strava.com/oauth/mobile/authorize")
        let clientId = StravaConfig.clientId
        let redirectUri = StravaConfig.redirectURI
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "read,activity:read_all"),
            URLQueryItem(name: "state", value: "nexo_ai_coach")
        ]
        return components?.url
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Suggestions Tab

struct SuggestionsTabView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var router: AppRouter
    @ObservedObject var viewModel: AICoachViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("Personalized suggestions")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("Based on your stats and preferences")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [theme.colors.accentPurple, theme.colors.accentPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                if viewModel.isLoading {
                    ProgressView("Loading suggestions...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.vertical, 32)
                } else if viewModel.suggestions.isEmpty {
                    Text("No suggestions yet. Update your stats and preferences to get personalized ideas.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 32)
                } else {
                    ForEach(viewModel.suggestions) { suggestion in
                        SuggestionCard(suggestion: suggestion) {
                            startGroupChat(for: suggestion)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private func startGroupChat(for suggestion: AISuggestion) {
        Task {
            do {
                let response = try await ChatAPI.createActivityGroupChat(activityId: suggestion.id)
                await MainActor.run {
                    router.select(.chat)
                    router.push(.chatConversation(chatId: response.chat.id))
                }
            } catch {
                print("Failed to create activity group chat: \(error)")
            }
        }
    }
}

struct SuggestionCard: View {
    @EnvironmentObject private var theme: Theme
    let suggestion: AISuggestion
    let onPrimaryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text(suggestion.sportType.prefix(1))
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(theme.colors.accentGreen.opacity(0.15))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(suggestion.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)

                        Text(suggestion.matchScoreText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(suggestion.matchScoreColor)
                            .cornerRadius(10)
                    }

                    if let reason = suggestion.reason, !reason.isEmpty {
                        Text(reason)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Label("\(suggestion.formattedDate) • \(suggestion.formattedTime)", systemImage: "calendar")
                        Label("\(suggestion.location)", systemImage: "mappin.and.ellipse")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textSecondary)

                    HStack(spacing: 8) {
                        Label("Level: \(suggestion.level)", systemImage: "line.3.horizontal.decrease.circle")
                        Label("\(suggestion.participants)/\(suggestion.maxParticipants) joined", systemImage: "person.3")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textSecondary)
                }
            }

            HStack {
                Text(suggestion.isAvailable ? "Spots available" : "Full")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(suggestion.isAvailable ? theme.colors.accentGreen : .red)

                Spacer()

                Button {
                    onPrimaryAction()
                } label: {
                    Text("Chat now")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.colors.accentPurple)
                        .cornerRadius(16)
                }
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

// MARK: - Tips Tab

struct TipsTabView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: AICoachViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.isLoadingTips {
                    ProgressView("Loading tips...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.vertical, 32)
                } else if viewModel.tips.isEmpty {
                    Text("No tips yet. Try refreshing suggestions or updating your stats.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 32)
                } else {
                    ForEach(viewModel.tips) { tip in
                        TipCard(tip: tip)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .onAppear {
                if viewModel.tips.isEmpty && !viewModel.isLoadingTips {
                    viewModel.loadTips()
                }
            }
        }
    }
}

struct TipCard: View {
    @EnvironmentObject private var theme: Theme
    let tip: PersonalizedTip

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tip.categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: tip.categoryIcon)
                    .foregroundColor(tip.categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(tip.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)

                    Text(tip.category)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(tip.categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(tip.categoryColor.opacity(0.08))
                        .cornerRadius(8)

                    if let priority = tip.priority, !priority.isEmpty {
                        Text(priority.capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(tip.priorityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(tip.priorityColor.opacity(0.08))
                            .cornerRadius(8)
                    }
                }

                Text(tip.description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - YouTube Videos Tab

struct YouTubeVideosTabView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: AICoachViewModel
    @State private var selectedVideo: YouTubeVideo?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.isLoadingVideos {
                    ProgressView("Loading videos...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.vertical, 32)
                } else if viewModel.youtubeVideos.isEmpty {
                    Text("No videos yet. Try adjusting your sport preferences.")
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 32)
                } else {
                    ForEach(viewModel.youtubeVideos) { video in
                        Button {
                            selectedVideo = video
                        } label: {
                            YouTubeVideoCard(video: video)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .onAppear {
                if viewModel.youtubeVideos.isEmpty && !viewModel.isLoadingVideos {
                    viewModel.loadYouTubeVideos()
                }
            }
        }
        .sheet(item: $selectedVideo) { video in
            if let url = video.youtubeURL {
                SafariView(url: url)
            }
        }
    }
}

struct YouTubeVideoCard: View {
    @EnvironmentObject private var theme: Theme
    let video: YouTubeVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: video.thumbnailUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(height: 180)
                .clipped()

                Text(video.formattedDuration)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)

                Text(video.channelTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    if !video.formattedViewCount.isEmpty {
                        Text(video.formattedViewCount)
                    }
                    if !video.formattedPublishedDate.isEmpty {
                        Text(video.formattedPublishedDate)
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AICoachView()
            .environmentObject(Theme())
    }
}
