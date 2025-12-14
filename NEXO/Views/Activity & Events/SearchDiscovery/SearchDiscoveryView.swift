//
//  SearchDiscoveryView.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI

// MARK: - Main View
struct SearchDiscoveryView: View {
    var onBack: (() -> Void)?
    var onCoachClick: (() -> Void)?

    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel = SearchDiscoveryViewModel()

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            floatingBlobs

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    coachSection
                    categoriesSection
                    trendingSection
                }
                .padding(.bottom, 120)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(localizationManager.localized("explore.nav.title"))
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
                    .accessibilityLabel(localizationManager.localized("common.back"))
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .navigationBarBackButtonHidden(onBack != nil)
    }
}

// MARK: - Floating Blobs
extension SearchDiscoveryView {
    private var floatingBlobs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color.purple.opacity(theme.isDarkMode ? 0.18 : 0.3), Color.purple.opacity(theme.isDarkMode ? 0.12 : 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 150, height: 150)
                .blur(radius: 50)
                .offset(x: -100, y: -250)
                .opacity(0.6)
            Circle()
                .fill(LinearGradient(colors: [Color.pink.opacity(theme.isDarkMode ? 0.2 : 0.35), Color.pink.opacity(theme.isDarkMode ? 0.12 : 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: 100, y: 250)
            Circle()
                .fill(LinearGradient(colors: [Color.blue.opacity(theme.isDarkMode ? 0.18 : 0.3), Color.blue.opacity(theme.isDarkMode ? 0.12 : 0.2)], startPoint: .top, endPoint: .bottom))
                .frame(width: 120, height: 120)
                .blur(radius: 40)
                .offset(x: 0, y: 100)
            Circle()
                .fill(LinearGradient(colors: [Color.green.opacity(theme.isDarkMode ? 0.16 : 0.25), Color.green.opacity(theme.isDarkMode ? 0.1 : 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .offset(x: 80, y: -150)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Header Section
extension SearchDiscoveryView {
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) { }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.colors.textSecondary)
                TextField(localizationManager.localized("explore.search.placeholder"), text: $viewModel.searchQuery)
                    .font(.system(size: 15))
                    .disableAutocorrection(true)
                    .foregroundColor(theme.colors.textPrimary)
                
                if !viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: { viewModel.onSearchQueryChange(query: "") }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(10)
            .background(theme.colors.cardBackground)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.colors.barMaterial)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 5, x: 0, y: theme.isDarkMode ? 6 : 2)
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text(localizationManager.localized("explore.loading"))
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.leading, 10)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Coach Section
extension SearchDiscoveryView {
    private var coachSection: some View {
        Group {
            if let coach = viewModel.featuredCoach {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(localizationManager.localized("explore.featuredCoach.title"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Spacer()
                        
                        if let onCoachClick {
                            Button(localizationManager.localized("explore.featuredCoach.seeAll")) {
                                onCoachClick()
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#A855F7"))
                        }
                    }
                    
                    Button(action: { 
                        if let onCoachClick {
                            onCoachClick()
                        }
                    }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: coach.avatar)) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "#A855F7"), lineWidth: 2)
                            )
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(coach.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(theme.colors.textPrimary)
                                    if coach.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#A855F7"))
                                    }
                                }
                                
                                Text(coach.title)
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textSecondary)
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "#FFB800"))
                                        Text(String(format: "%.1f", coach.rating))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(theme.colors.textSecondary)
                                    }
                                    
                                    Text("•")
                                        .font(.system(size: 10))
                                        .foregroundColor(theme.colors.textSecondary)
                                    
                                    Text("\(coach.reviewCount) " + localizationManager.localized("explore.featuredCoach.reviewsLabel"))
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.colors.textSecondary)
                                    
                                    Text("•")
                                        .font(.system(size: 10))
                                        .foregroundColor(theme.colors.textSecondary)
                                    
                                    Text("\(coach.sessionCount)+ " + localizationManager.localized("explore.featuredCoach.sessionsLabel"))
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .padding()
                        .background(theme.colors.cardBackground)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(theme.colors.cardBackground)
                .cornerRadius(16)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Sections
extension SearchDiscoveryView {
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizationManager.localized("explore.categories.title"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                ForEach(viewModel.overview?.categories ?? []) { category in
                    Button(action: { 
                        viewModel.onCategorySelected(categoryName: category.name)
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(theme.colors.cardBackground)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(theme.colors.barMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                viewModel.selectedCategory == category.name ? 
                                                category.color : theme.colors.cardStroke, 
                                                lineWidth: viewModel.selectedCategory == category.name ? 3 : 2
                                            )
                                    )
                                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 6)
                                VStack(spacing: 6) {
                                    Text(category.icon)
                                        .font(.system(size: 22))
                                        .frame(width: 44, height: 44)
                                        .background(category.color.opacity(theme.isDarkMode ? 0.18 : 0.2))
                                        .cornerRadius(16)
                                    Text(category.name)
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.colors.textPrimary)
                                }
                                .padding(8)
                            }
                            .frame(height: 90)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
                ? localizationManager.localized("explore.trending.title.nearYou")
                : localizationManager.localized("explore.trending.title.searchResults")
            )
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)

            if let overview = viewModel.overview {
                if overview.trendingActivities.isEmpty && !viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.isLoading {
                    Text(
                        String(
                            format: localizationManager.localized("explore.trending.noResultsFormat"),
                            viewModel.searchQuery
                        )
                    )
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)
                        .padding()
                } else {
                    VStack(spacing: 10) {
                    ForEach(overview.trendingActivities) { activity in
                        Button(action: { 
                            // TODO: Navigate to activity details
                        }) {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(theme.colors.cardBackground)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(theme.colors.barMaterial)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 28).stroke(theme.colors.cardStroke, lineWidth: 2))
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 12 : 8)
                                .overlay(
                                    HStack(spacing: 10) {
                                        Text(activity.sportIcon)
                                            .font(.system(size: 20))
                                            .frame(width: 44, height: 44)
                                            .background(theme.colors.cardBackground)
                                            .cornerRadius(16)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(activity.title)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(theme.colors.textPrimary)
                                            HStack(spacing: 6) {
                                                Image(systemName: "mappin.and.ellipse")
                                                Text(activity.location)
                                                Text("•")
                                                Text(activity.date)
                                                Text("•")
                                                Text(activity.time)
                                            }
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.colors.textSecondary)
                                            HStack(spacing: 6) {
                                                AsyncImage(url: URL(string: activity.hostAvatar)) { img in
                                                    img.resizable().scaledToFill()
                                                } placeholder: {
                                                    Circle().fill(Color.gray.opacity(0.3))
                                                }
                                                .frame(width: 20, height: 20)
                                                .clipShape(Circle())
                                                Text(activity.hostName)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(theme.colors.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        Text("\(activity.participants)/\(activity.maxParticipants) spots")
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(theme.colors.cardBackground)
                                            .cornerRadius(12)
                                            .foregroundColor(Color(hex: "#A855F7"))
                                    }
                                    .padding()
                                )
                                .frame(height: 90)
                        }
                        .buttonStyle(.plain)
                    }
                    }
                }
            } else if viewModel.error != nil {
                Text(localizationManager.localized("explore.trending.error"))
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding()
            } else if !viewModel.isLoading {
                Text(localizationManager.localized("explore.trending.empty"))
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textSecondary)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct SearchDiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SearchDiscoveryView()
                .environmentObject(Theme())
        }
    }
}
