//
//  AICoachView.swift
//  NEXO
//
//  Created by ROCCO 4X on 7/11/2025.
//

import SwiftUI

struct AICoachView: View {
    var onBack: (() -> Void)?
    var onStartChallenge: (() -> Void)?
    var onFindPartner: (() -> Void)?

    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = AICoachViewModel()

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            backgroundOrbs
            
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 8)
                
                if viewModel.isLoadingAIAnalysis {
                    aiAnalysisLoadingView
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                // Debug info for development
                if viewModel.aiAnalysisError != nil {
                    errorView
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                tabSelector
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if viewModel.selectedTab == "overview" { overviewTab }
                        if viewModel.selectedTab == "suggestions" { suggestionsTab }
                        if viewModel.selectedTab == "tips" { tipsTab }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("AI Coach")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(theme.colors.accentPurple)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.colors.accentPurple)
                }
                .disabled(viewModel.isLoadingAIAnalysis)
            }
            
            // User profile or settings could go here
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Navigate to user profile or settings
                    print("👤 User profile tapped")
                } label: {
                    Image(systemName: "person.circle")
                        .font(.system(size: 20))
                        .foregroundColor(theme.colors.textPrimary)
                }
            }
        }
        .navigationDestination(isPresented: $viewModel.navigateToAchievements) {
            AchievementsView()
        }
        .navigationDestination(isPresented: $viewModel.navigateToMatchmaker) {
            AIMatchmakerView()
        }
        .onAppear {
            print("🚀 AI Coach view appeared")
            Task {
                await viewModel.requestHealthKitPermissionsIfNeeded()
            }
        }
        .refreshable {
            print("🔄 Manual refresh triggered")
            await viewModel.refreshAIAnalysis()
        }
    }
}

// MARK: - UI Sections
extension AICoachView {
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.motivationalMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Text(viewModel.motivationalSubtext)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [theme.colors.accentPurple, theme.colors.accentPink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["overview", "suggestions", "tips"], id: \.self) { tab in
                Button(action: {
                    viewModel.selectTab(tab)
                    viewModel.trackTabView(tab)
                }) {
                    VStack(spacing: 12) {
                        Text(tab == "overview" ? "Overview" : tab == "suggestions" ? "Suggestions" : "Tips")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.selectedTab == tab ? theme.colors.accentPurple : theme.colors.textSecondary)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(viewModel.selectedTab == tab ? theme.colors.accentPurple : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Tabs
    private var overviewTab: some View {
        VStack(spacing: 12) {
            weeklyStatsCard
            weatherCard
            challengesList
            quickActions
        }
    }

    private var weeklyStatsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Text(viewModel.streakBadgeText)
                        .font(.system(size: 11, weight: .medium))
                    Text("🔥")
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.colors.accentGreen)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            HStack(spacing: 12) {
                statColumn(title: "Workouts", value: viewModel.getStatValue(for: "workouts"), color: theme.colors.accentPurple)
                statColumn(title: "Calories", value: viewModel.getStatValue(for: "calories"), color: theme.colors.accentOrange)
                statColumn(title: "Minutes", value: viewModel.getStatValue(for: "minutes"), color: Color.blue)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Weekly goal")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                    Text(viewModel.weeklyGoalText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.divider)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.accentPurple)
                            .frame(width: geometry.size.width * viewModel.weeklyGoalProgress, height: 8)
                    }
                }
                .frame(height: 8)
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
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func statColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var weatherCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .frame(width: 44, height: 44)
                
                if let weather = viewModel.weatherInfo {
                    Image(systemName: weather.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.weatherTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Text(viewModel.weatherDisplayText)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.cyan.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(theme.colors.barMaterial.opacity(theme.isDarkMode ? 0.2 : 0))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var challengesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Challenges")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            ForEach(viewModel.challenges) { challenge in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.colors.accentPurple, theme.colors.accentPink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "target")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(challenge.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            Text(challenge.description)
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 6) {
                        HStack {
                            Text("Progress")
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textSecondary)
                            Spacer()
                            Text(viewModel.getChallengeProgressText(challenge))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.colors.divider)
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.colors.accentPurple)
                                    .frame(width: geometry.size.width * viewModel.getChallengeProgress(challenge), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    
                    Text("Reward: \(challenge.reward)")
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(12)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button(action: {
                onStartChallenge?()
                viewModel.startChallenge()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "rosette")
                        .font(.system(size: 20))
                    Text("Start Challenge")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [theme.colors.accentPurple, theme.colors.accentPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
            }
            .buttonStyle(ScaleButtonStyle())

            Button(action: {
                onFindPartner?()
                viewModel.findPartner()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                    Text("Find Partner")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.colors.accentGreen)
                .cornerRadius(18)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var suggestionsTab: some View {
        VStack(spacing: 10) {
            // Personalized header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Personalized for you")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text("Based on your activity history and preferences")
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
            
            ForEach(viewModel.suggestions) { suggestion in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text(suggestion.icon)
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(theme.colors.accentGreen.opacity(0.2))
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(suggestion.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.colors.textPrimary)
                                
                                Text(viewModel.getMatchScoreText(suggestion))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        LinearGradient(
                                            colors: [theme.colors.accentPurple, theme.colors.accentPink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                            
                            Text(suggestion.description)
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textSecondary)
                            
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 12))
                                    Text(suggestion.time)
                                        .font(.system(size: 12))
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 12))
                                    Text(viewModel.getParticipantsText(suggestion))
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(theme.colors.textSecondary)
                        }
                        Spacer()
                    }
                    
                    Button(action: {
                        viewModel.joinSuggestion(suggestion)
                        viewModel.trackSuggestionInteraction(suggestion)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                            Text("Join Now")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(theme.colors.accentGreen)
                        .cornerRadius(999)
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
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }

    private var tipsTab: some View {
        VStack(spacing: 10) {
            // Video library card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    Text("Workout Video Library")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Text("Watch expert-led tutorials and form guides")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                
                Button(action: { viewModel.browseVideos() }) {
                    Text("Browse Videos")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(theme.colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(999)
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(theme.colors.barMaterial.opacity(theme.isDarkMode ? 0.2 : 0))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

            ForEach(viewModel.workoutTips) { tip in
                HStack(spacing: 10) {
                    Text(tip.icon)
                        .font(.system(size: 22))
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(tip.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Text(tip.category)
                                .font(.system(size: 10))
                                .foregroundColor(theme.colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(theme.colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                        
                        Text(tip.description)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }

    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color.pink.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 180, y: 300)
        }
        .allowsHitTesting(false)
    }
    
    private var aiAnalysisLoadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(theme.colors.accentPurple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Analyzing your health data...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("Getting personalized recommendations from AI")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.accentPurple.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var errorView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Debug Info")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(viewModel.aiAnalysisError ?? "Unknown error")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            Button("Retry") {
                Task {
                    await viewModel.refreshAIAnalysis()
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(theme.colors.accentPurple)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AICoachView()
            .environmentObject(Theme())
    }
}
