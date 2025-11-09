//
//  HomeFeedView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var theme: Theme

    @State private var searchQuery = ""
    @State private var savedActivities = Set<String>()
    @State private var filterSport = "all"
    @State private var filterDistance: Double = 5
    @State private var showFilters = false
    
    let activities: [Activity]
    let sportCategories: [SportCategory]
    
    var onActivityClick: (Activity) -> Void
    var onSearchClick: (() -> Void)?
    var onAISuggestionsClick: (() -> Void)?
    var onQuickMatchClick: (() -> Void)?
    var onAIMatchmakerClick: (() -> Void)?
    var onEventDetailsClick: (() -> Void)?
    var onCreateClick: (() -> Void)?
    var onNotificationsClick: (() -> Void)?
    
    var filteredActivities: [Activity] {
        activities.filter { activity in
            let matchesSearch = searchQuery.isEmpty ||
                activity.title.localizedCaseInsensitiveContains(searchQuery) ||
                activity.sportType.localizedCaseInsensitiveContains(searchQuery)
            let matchesSport = filterSport == "all" || activity.sportType == filterSport
            return matchesSearch && matchesSport
        }
    }
    
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            // Orbs left as-is; they blend with both modes
            FloatingOrb(
                size: 128,
                color: LinearGradient(
                    colors: [
                        Color(hex: "E9D5FF").opacity(theme.isDarkMode ? 0.18 : 0.4),
                        Color(hex: "DDD6FE").opacity(theme.isDarkMode ? 0.12 : 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: -140,
                yOffset: -250,
                delay: 0
            )
            
            FloatingOrb(
                size: 160,
                color: LinearGradient(
                    colors: [
                        Color(hex: "FCE7F3").opacity(theme.isDarkMode ? 0.2 : 0.5),
                        Color(hex: "FBCFE8").opacity(theme.isDarkMode ? 0.12 : 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 140,
                yOffset: 150,
                delay: 1
            )
            
            FloatingOrb(
                size: 96,
                color: LinearGradient(
                    colors: [
                        Color(hex: "E0E7FF").opacity(theme.isDarkMode ? 0.18 : 0.4),
                        Color(hex: "C7D2FE").opacity(theme.isDarkMode ? 0.12 : 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 0,
                yOffset: 0,
                delay: 2
            )
            
            FloatingOrb(
                size: 80,
                color: LinearGradient(
                    colors: [
                        Color(hex: "FEF3C7").opacity(theme.isDarkMode ? 0.18 : 0.4),
                        Color(hex: "FDE68A").opacity(theme.isDarkMode ? 0.12 : 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 100,
                yOffset: -150,
                delay: 3
            )
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Discover")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("Near You")
                            .font(.system(size: 15))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    
                    // Search and Filter
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(theme.colors.textSecondary)
                            
                            TextField("Search activities...", text: $searchQuery)
                                .font(.system(size: 15))
                                .foregroundColor(theme.colors.textPrimary)
                                .tint(theme.colors.accentPurple)
                                .accentColor(theme.colors.accentPurple)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .background(theme.colors.cardBackground.opacity(theme.isDarkMode ? 0.7 : 1))
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                        
                        Button(action: { showFilters = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18))
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(theme.colors.cardBackground.opacity(theme.isDarkMode ? 0.7 : 1))
                                .background(theme.colors.barMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .overlay(alignment: .topTrailing) {
                    if let onNotificationsClick {
                        Button(action: onNotificationsClick) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                theme.colors.cardBackground,
                                                theme.colors.cardBackground.opacity(theme.isDarkMode ? 0.6 : 0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .background(theme.colors.barMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                                    )
                                Image(systemName: "bell")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.colors.textPrimary)
                            }
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(theme.isDarkMode ? 0.35 : 0.06), radius: theme.isDarkMode ? 12 : 6, x: 0, y: theme.isDarkMode ? 6 : 3)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                        .accessibilityLabel("Notifications")
                    }
                }
                
                // Activity Feed
                ScrollView {
                    VStack(spacing: 10) {
                        // Featured Cards Grid
                        HStack(spacing: 10) {
                            if let quickMatch = onQuickMatchClick {
                                CrystalFeatureCard(
                                    title: "Quick Match",
                                    subtitle: "Swipe to connect",
                                    icon: "bolt.fill",
                                    iconColor: theme.isDarkMode ? theme.colors.accentOrange : Color(hex: "EC4899"),
                                    gradientColors: theme.isDarkMode
                                        ? [Color.black.opacity(0.35), Color.black.opacity(0.25)]
                                        : [Color(hex: "FCE7F3").opacity(0.7), Color(hex: "FBCFE8").opacity(0.6)],
                                    glowColors: theme.isDarkMode
                                        ? [theme.colors.accentOrangeGlow.opacity(0.25), theme.colors.accentPurpleGlow.opacity(0.18)]
                                        : [Color(hex: "FCE7F3").opacity(0.6), Color(hex: "FBCFE8").opacity(0.5)],
                                    action: quickMatch
                                )
                            }
                            
                            if let aiMatchmaker = onAIMatchmakerClick {
                                CrystalFeatureCard(
                                    title: "AI Matchmaker",
                                    subtitle: "Find partners",
                                    icon: "sparkles",
                                    iconColor: theme.colors.accentPurple,
                                    gradientColors: theme.isDarkMode
                                        ? [Color.black.opacity(0.35), Color.black.opacity(0.25)]
                                        : [Color(hex: "E9D5FF").opacity(0.7), Color(hex: "DDD6FE").opacity(0.6)],
                                    glowColors: theme.isDarkMode
                                        ? [theme.colors.accentPurpleGlow.opacity(0.25), theme.colors.accentGreenGlow.opacity(0.18)]
                                        : [Color(hex: "E9D5FF").opacity(0.6), Color(hex: "DDD6FE").opacity(0.5)],
                                    action: aiMatchmaker
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Explore More Card
                        if let searchClick = onSearchClick {
                            CrystalExploreCard(action: searchClick)
                                .padding(.horizontal, 16)
                        }
                        
                        // Activity Cards
                        ForEach(filteredActivities) { activity in
                            ActivityCrystalCard(
                                activity: activity,
                                isSaved: savedActivities.contains(activity.id),
                                onToggleSave: { toggleSave(activity.id) },
                                onJoin: { onActivityClick(activity) },
                                onDetails: onEventDetailsClick
                            )
                            .padding(.horizontal, 16)
                            .environmentObject(theme)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
            
            // Floating Create Button
            if let onCreate = onCreateClick {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingCreateButton(action: onCreate)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(
                filterSport: $filterSport,
                filterDistance: $filterDistance,
                sportCategories: sportCategories
            )
            .environmentObject(theme)
        }
    }
    
    private func toggleSave(_ id: String) {
        if savedActivities.contains(id) {
            savedActivities.remove(id)
        } else {
            savedActivities.insert(id)
        }
    }
}

// MARK: - Crystal Feature Card

struct CrystalFeatureCard: View {
    @EnvironmentObject private var theme: Theme

    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let gradientColors: [Color]
    let glowColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: glowColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: theme.isDarkMode ? 16 : 12)
                    .padding(-4)
                    .opacity(theme.isDarkMode ? 0.9 : 1)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Top highlight
                    LinearGradient(
                        colors: [
                            Color.white.opacity(theme.isDarkMode ? 0.18 : 0.6),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 48)
                    .cornerRadius(14, corners: [.topLeft, .topRight])
                    
                    Spacer()
                }
                
                // Inner glow
                LinearGradient(
                    colors: [
                        Color.white.opacity(theme.isDarkMode ? 0.16 : 0.5),
                        Color.white.opacity(0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(14)
                .padding(2)
                
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.colors.cardStroke, lineWidth: 2)
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(iconColor)
                    }
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.35 : 0.1), radius: theme.isDarkMode ? 12 : 10, x: 0, y: theme.isDarkMode ? 6 : 4)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(theme.colors.barMaterial.opacity(theme.isDarkMode ? 0.15 : 0))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.2 : 0.8), lineWidth: 2)
            )
            .cornerRadius(14)
            .shadow(color: .black.opacity(theme.isDarkMode ? 0.45 : 0.1), radius: theme.isDarkMode ? 24 : 20, x: 0, y: theme.isDarkMode ? 12 : 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Crystal Explore Card

struct CrystalExploreCard: View {
    @EnvironmentObject private var theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: theme.isDarkMode
                                ? [Color.white.opacity(0.08), Color.white.opacity(0.06)]
                                : [Color(hex: "F3F4F6").opacity(0.6), Color(hex: "E5E7EB").opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: theme.isDarkMode ? 14 : 12)
                    .padding(-4)
                
                VStack(alignment: .leading, spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(theme.isDarkMode ? 0.16 : 0.6),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 48)
                    .cornerRadius(14, corners: [.topLeft, .topRight])
                    
                    Spacer()
                }
                
                LinearGradient(
                    colors: [
                        Color.white.opacity(theme.isDarkMode ? 0.14 : 0.5),
                        Color.white.opacity(0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(14)
                .padding(2)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Explore More")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("Browse sports & discover new people")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.colors.cardStroke, lineWidth: 2)
                            )
                        
                        Image(systemName: "safari")
                            .font(.system(size: 20))
                            .foregroundColor(theme.isDarkMode ? theme.colors.textPrimary : Color(hex: "6B7280"))
                    }
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.35 : 0.1), radius: theme.isDarkMode ? 12 : 10, x: 0, y: theme.isDarkMode ? 6 : 4)
                }
                .padding(16)
            }
            .frame(height: 80)
            .background(
                LinearGradient(
                    colors: theme.isDarkMode
                        ? [Color.black.opacity(0.35), Color.black.opacity(0.25)]
                        : [Color(hex: "F3F4F6").opacity(0.7), Color(hex: "E5E7EB").opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(theme.colors.barMaterial.opacity(theme.isDarkMode ? 0.15 : 0))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.2 : 0.8), lineWidth: 2)
            )
            .cornerRadius(14)
            .shadow(color: .black.opacity(theme.isDarkMode ? 0.45 : 0.1), radius: theme.isDarkMode ? 24 : 20, x: 0, y: theme.isDarkMode ? 12 : 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Activity Crystal Card

struct ActivityCrystalCard: View {
    @EnvironmentObject private var theme: Theme

    let activity: Activity
    let isSaved: Bool
    let onToggleSave: () -> Void
    let onJoin: () -> Void
    let onDetails: (() -> Void)?
    
    var spotsLeft: Int {
        activity.spotsTotal - activity.spotsTaken
    }
    
    var body: some View {
        ZStack {
            // Hover glow effect (kept off by default)
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "E9D5FF").opacity(theme.isDarkMode ? 0.18 : 0.4),
                            Color(hex: "FCE7F3").opacity(theme.isDarkMode ? 0.16 : 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 8)
                .padding(-2)
                .opacity(0)
            
            VStack(alignment: .leading, spacing: 0) {
                // Top highlight
                LinearGradient(
                    colors: [
                        Color.white.opacity(theme.isDarkMode ? 0.16 : 0.6),
                        Color.white.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)
                .cornerRadius(14, corners: [.topLeft, .topRight])
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .top, spacing: 0) {
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: activity.hostAvatar)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(String(activity.hostName.prefix(1)))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                        .background(Color(hex: "A855F7"))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(theme.isDarkMode ? 0.6 : 1), lineWidth: 2))
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.3 : 0.05), radius: theme.isDarkMode ? 8 : 4, x: 0, y: theme.isDarkMode ? 4 : 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.hostName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            HStack(spacing: 6) {
                                Text(activity.sportIcon)
                                    .font(.system(size: 12))
                                
                                Text(activity.sportType)
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onToggleSave) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isSaved ? Color(hex: "EF4444") : theme.colors.textSecondary.opacity(0.8))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.bottom, 10)
                
                // Title
                Text(activity.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .lineSpacing(2)
                    .padding(.bottom, 10)
                
                // Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("\(activity.date) • \(activity.time)")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("\(activity.location) • \(activity.distance)")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("\(spotsLeft) of \(activity.spotsTotal) spots remaining")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .padding(.bottom, 10)
                
                // Badge and Buttons
                HStack {
                    Text(activity.level)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(theme.colors.cardBackground.opacity(theme.isDarkMode ? 0.7 : 1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if let details = onDetails {
                            Button(action: details) {
                                Text("Details")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.colors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(theme.colors.cardBackground.opacity(theme.isDarkMode ? 0.7 : 1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                                    )
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        Button(action: onJoin) {
                            Text("Join")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(theme.colors.accentGreen)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .padding(16)
        }
        .background(theme.colors.cardBackground.opacity(theme.isDarkMode ? 0.85 : 0.95))
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(14)
        .shadow(color: .black.opacity(theme.isDarkMode ? 0.4 : 0.05), radius: theme.isDarkMode ? 16 : 8, x: 0, y: theme.isDarkMode ? 8 : 4)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.dismiss) var dismiss
    @Binding var filterSport: String
    @Binding var filterDistance: Double
    let sportCategories: [SportCategory]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sport Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Menu {
                        Button("All Sports") {
                            filterSport = "all"
                        }
                        
                        ForEach(sportCategories) { sport in
                            Button("\(sport.icon) \(sport.name)") {
                                filterSport = sport.name
                            }
                        }
                    } label: {
                        HStack {
                            Text(filterSport == "all" ? "All Sports" : filterSport)
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(theme.colors.cardBackground.opacity(theme.isDarkMode ? 0.7 : 1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(16)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distance: \(Int(filterDistance)) miles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Slider(value: $filterDistance, in: 1...20, step: 1)
                        .tint(theme.colors.accentPurple)
                }
                
                Spacer()
            }
            .padding(20)
            .background(theme.colors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.accentPurple)
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    HomeFeedView(
        activities: [
            Activity(
                id: "1",
                title: "Morning Basketball Game",
                sportType: "Basketball",
                sportIcon: "🏀",
                hostName: "John Doe",
                hostAvatar: "",
                date: "Today",
                time: "9:00 AM",
                location: "Downtown Court",
                distance: "2.3 mi",
                spotsTotal: 10,
                spotsTaken: 7,
                level: "Intermediate"
            )
        ],
        sportCategories: [
            SportCategory(name: "Basketball", icon: "🏀"),
            SportCategory(name: "Tennis", icon: "🎾")
        ],
        onActivityClick: { _ in },
        onSearchClick: {},
        onQuickMatchClick: {},
        onAIMatchmakerClick: {},
        onCreateClick: {},
        onNotificationsClick: {} // preview hook
    )
    .environmentObject(Theme())
}
