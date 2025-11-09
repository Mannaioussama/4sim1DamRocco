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

    @State private var selectedTab: String = "overview"
    @State private var navigateToAchievements: Bool = false
    @State private var navigateToMatchmaker: Bool = false

    private let weeklyStats = (workouts: 3, goal: 5, calories: 1200, minutes: 180, streak: 7)

    private let suggestions: [Suggestion] = [
        .init(title: "Try a morning swim", description: "4 swimmers nearby are free tomorrow 7AM", icon: "🏊", time: "Tomorrow 7AM", participants: 4, matchScore: 95),
        .init(title: "Join evening yoga session", description: "Perfect for recovery after your runs", icon: "🧘", time: "Today 6PM", participants: 8, matchScore: 88),
        .init(title: "Weekend cycling group", description: "Explore new routes with local cyclists", icon: "🚴", time: "Saturday 8AM", participants: 12, matchScore: 82)
    ]

    private let workoutTips: [Tip] = [
        .init(title: "Warm-up is essential", description: "Spend 5-10 minutes warming up to prevent injuries and improve performance.", icon: "🔥", category: "Basics"),
        .init(title: "Stay hydrated", description: "Drink water before, during, and after your workout for optimal performance.", icon: "💧", category: "Health"),
        .init(title: "Progressive overload", description: "Gradually increase intensity to continue seeing improvements.", icon: "📈", category: "Training")
    ]

    private let challenges: [Challenge] = [
        .init(title: "30-Day Running Streak", description: "Run at least 1 mile every day for 30 days", progress: 7, total: 30, reward: "🏆 Marathon Badge"),
        .init(title: "Weekly Variety Challenge", description: "Try 3 different sports this week", progress: 1, total: 3, reward: "⭐ Explorer Badge")
    ]

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            backgroundOrbs
            
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 8)
                
                tabSelector
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if selectedTab == "overview" { overviewTab }
                        if selectedTab == "suggestions" { suggestionsTab }
                        if selectedTab == "tips" { tipsTab }
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
        .navigationDestination(isPresented: $navigateToAchievements) {
            AchievementsView()
        }
        .navigationDestination(isPresented: $navigateToMatchmaker) {
            AIMatchmakerView()
        }
    }
}

// MARK: - Models
struct Suggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let time: String
    let participants: Int
    let matchScore: Int
}

struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: String
}

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let progress: Int
    let total: Int
    let reward: String
}

// MARK: - UI Sections
extension AICoachView {
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Progress starts with small steps")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Text("Keep going! You're doing great 💪")
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 12) {
                        Text(tab == "overview" ? "Overview" : tab == "suggestions" ? "Suggestions" : "Tips")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == tab ? theme.colors.accentPurple : theme.colors.textSecondary)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? theme.colors.accentPurple : .clear)
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
                    Text("\(weeklyStats.streak) day streak")
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
                statColumn(title: "Workouts", value: "\(weeklyStats.workouts)", color: theme.colors.accentPurple)
                statColumn(title: "Calories", value: "\(weeklyStats.calories)", color: theme.colors.accentOrange)
                statColumn(title: "Minutes", value: "\(weeklyStats.minutes)", color: Color.blue)
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Weekly goal")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                    Text("\(weeklyStats.workouts)/\(weeklyStats.goal)")
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
                            .frame(width: geometry.size.width * CGFloat(weeklyStats.workouts) / CGFloat(weeklyStats.goal), height: 8)
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
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Perfect weather today!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Text("72°F, sunny — ideal for outdoor training")
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
            
            ForEach(challenges) { challenge in
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
                            Text("\(challenge.progress)/\(challenge.total)")
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
                                    .frame(width: geometry.size.width * CGFloat(challenge.progress) / CGFloat(challenge.total), height: 8)
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
                navigateToAchievements = true
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
                navigateToMatchmaker = true
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
            
            ForEach(suggestions) { suggestion in
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
                                
                                Text("\(suggestion.matchScore)% match")
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
                                    Text("\(suggestion.participants) interested")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(theme.colors.textSecondary)
                        }
                        Spacer()
                    }
                    
                    Button(action: {}) {
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
                
                Button(action: {}) {
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

            ForEach(workoutTips) { tip in
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
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AICoachView()
            .environmentObject(Theme())
    }
}
