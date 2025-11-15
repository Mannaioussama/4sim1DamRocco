//
//  HomeFeedView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

// MARK: - Main View
struct HomeFeedView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var activityAPIService: ActivityAPIService
    @StateObject private var viewModel = HomeFeedViewModel(activityAPIService: nil)
    
    var onActivityClick: (Activity) -> Void
    var onSearchClick: (() -> Void)?
    var onAISuggestionsClick: (() -> Void)?
    var onQuickMatchClick: (() -> Void)?
    var onAIMatchmakerClick: (() -> Void)?
    var onEventDetailsClick: (() -> Void)?
    var onCreateClick: (() -> Void)?
    var onNotificationsClick: (() -> Void)?
    // New: optional chat action for “Individual” cards
    var onChatClick: (() -> Void)? = nil
    
    // MARK: - Explicit Bindings to avoid dynamicMember issues
    private var searchQueryBinding: Binding<String> {
        Binding(
            get: { viewModel.searchQuery },
            set: { viewModel.searchQuery = $0 }
        )
    }
    private var showFiltersBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showFilters },
            set: { viewModel.showFilters = $0 }
        )
    }
    private var filterSportBinding: Binding<String> {
        Binding(
            get: { viewModel.filterSport },
            set: { viewModel.filterSport = $0 }
        )
    }
    private var filterDistanceBinding: Binding<Double> {
        Binding(
            get: { viewModel.filterDistance },
            set: { viewModel.filterDistance = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            // Floating Orbs
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
                headerSection
                
                // Activity Feed
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasFilteredActivities {
                    activityFeedContent
                } else {
                    emptyStateView
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
        .sheet(isPresented: showFiltersBinding) {
            FilterSheet(
                filterSport: filterSportBinding,
                filterDistance: filterDistanceBinding,
                sportCategories: viewModel.sportCategories
            )
            .environmentObject(theme)
        }
        .onAppear {
            // Inject the shared ActivityAPIService into the ViewModel once
            if viewModel.activityAPIService == nil {
                viewModel.injectService(activityAPIService)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.headerTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(viewModel.headerSubtitle)
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
                    
                    TextField("Search activities...", text: searchQueryBinding)
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textPrimary)
                        .tint(theme.colors.accentPurple)
                        .accentColor(theme.colors.accentPurple)
                    
                    if viewModel.isSearching {
                        Button(action: { viewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
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
                
                Button(action: {
                    viewModel.toggleFilters()
                    viewModel.trackFilterApplied()
                }) {
                    ZStack(alignment: .topTrailing) {
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
                        
                        if viewModel.activeFiltersCount > 0 {
                            Circle()
                                .fill(theme.colors.accentGreen)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(viewModel.activeFiltersCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 4, y: -4)
                        }
                    }
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
    }
    
    // MARK: - Activity Feed Content
    
    private var activityFeedContent: some View {
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
                
                // One static Coach/Group reference card (non-dynamic)
                CoachReferenceCard()
                    .padding(.horizontal, 16)
                
                // Activity Cards (all dynamic activities use the Individual/session design)
                ForEach(viewModel.filteredActivities) { activity in
                    SessionActivityCard(
                        activity: activity,
                        isSaved: viewModel.isSaved(activity.id),
                        onToggleSave: {
                            viewModel.toggleSave(activity.id)
                            viewModel.trackActivitySave(activity)
                        },
                        onChat: {
                            if let onChatClick {
                                onChatClick()
                            } else {
                                print("Chat Now tapped for: \(activity.title)")
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .environmentObject(theme)
                    .onAppear {
                        viewModel.trackActivityView(activity)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .refreshable {
            viewModel.forceRefreshActivities()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text("Loading activities...")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary)
            Text("No activities found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text("Try adjusting your filters or search")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            HStack(spacing: 12) {
                if viewModel.isSearching {
                    Button(action: { viewModel.clearSearch() }) {
                        Text("Clear Search")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(theme.colors.accentPurple)
                            .cornerRadius(20)
                    }
                }
                
                if viewModel.isFiltering {
                    Button(action: { viewModel.clearFilters() }) {
                        Text("Clear Filters")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(theme.colors.accentGreen)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Activity Crystal Card (kept for future Coach design)

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

// MARK: - Session Activity Card (Individual design)

struct SessionActivityCard: View {
    @EnvironmentObject private var theme: Theme
    
    let activity: Activity
    let isSaved: Bool
    let onToggleSave: () -> Void
    let onChat: () -> Void
    
    private var spotsLeft: Int { activity.spotsTotal - activity.spotsTaken }
    
    var body: some View {
        ZStack {
            // Subtle hover glow (hidden by default)
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
                        .background(Color(hex: "60A5FA"))
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
                    
                    HStack(spacing: 8) {
                        // Individual badge (blue)
                        Text("Individual")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "1E40AF"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "DBEAFE"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "BFDBFE"), lineWidth: 1)
                            )
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                        
                        Button(action: onToggleSave) {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(isSaved ? Color(hex: "EF4444") : theme.colors.textSecondary.opacity(0.8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
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
                
                // Bottom: level badge + Chat Now
                HStack {
                    Text(activity.level)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "4A5568"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "F7FAFC"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "E2E8F0"), lineWidth: 1)
                        )
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                    
                    Spacer()
                    
                    Button(action: onChat) {
                        Text("Chat Now")
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

// MARK: - Static Coach/Group Reference Card

struct CoachReferenceCard: View {
    @EnvironmentObject private var theme: Theme
    
    // Static example content
    private let activity = Activity(
        id: "coach_reference",
        title: "Pro Drills & Skills Clinic",
        sportType: "Basketball",
        sportIcon: "🏀",
        hostName: "Coach Alex",
        hostAvatar: "https://i.pravatar.cc/150?img=20",
        date: "Saturday",
        time: "10:00 AM",
        location: "Downtown Court",
        distance: "2.1 mi",
        spotsTotal: 12,
        spotsTaken: 6,
        level: "Intermediate"
    )
    
    private var spotsLeft: Int { activity.spotsTotal - activity.spotsTaken }
    
    var body: some View {
        ZStack {
            // Subtle hover glow (hidden by default)
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
                    
                    HStack(spacing: 8) {
                        // Coach badge (purple)
                        Text("Coach")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "A855F7"))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 4, x: 0, y: theme.isDarkMode ? 6 : 2)
                        
                        // Static heart (non-interactive reference)
                        Image(systemName: "heart")
                            .font(.system(size: 20))
                            .foregroundColor(theme.colors.textSecondary.opacity(0.8))
                    }
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
                
                // Badge and Buttons (static reference)
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
                        Button(action: { print("Coach Details (reference)") }) {
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
                        
                        Button(action: { print("Coach Join (reference)") }) {
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
        .accessibilityLabel("Coach reference card")
        .accessibilityHint("Static example for coach/group design")
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
        onActivityClick: { _ in },
        onSearchClick: {},
        onQuickMatchClick: {},
        onAIMatchmakerClick: {},
        onCreateClick: {},
        onNotificationsClick: {},
        onChatClick: {} // New: wire Chat Now in preview
    )
    .environmentObject(Theme())
    .environmentObject(ActivityAPIService()) // Ensure preview has the shared service
}
