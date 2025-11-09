//
//  SearchDiscoveryView.swift
//  NEXO
//
//  Created by ROCCO 4X on 6/11/2025.
//

import SwiftUI

// MARK: - Data Models
struct DiscoverySportCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct DiscoveryActivity: Identifiable {
    let id = UUID()
    let title: String
    let sportIcon: String
    let hostName: String
    let hostAvatar: String
    let distance: String
    let date: String
    let spotsTotal: Int
    let spotsTaken: Int
}

struct DiscoveryUser: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let sport: String
    let distance: String
}

// MARK: - Main View
struct SearchDiscoveryView: View {
    var onBack: (() -> Void)?
    var onCoachClick: (() -> Void)?

    @EnvironmentObject private var theme: Theme

    // MARK: - Mock Data
    private let sportCategories: [DiscoverySportCategory] = [
        .init(name: "Running", icon: "🏃", color: .green),
        .init(name: "Yoga", icon: "🧘‍♀️", color: .purple),
        .init(name: "Cycling", icon: "🚴‍♀️", color: .blue),
        .init(name: "Basketball", icon: "🏀", color: .orange),
        .init(name: "Tennis", icon: "🎾", color: .mint),
        .init(name: "Football", icon: "⚽️", color: .gray)
    ]

    private let mockActivities: [DiscoveryActivity] = [
        .init(title: "Morning Run", sportIcon: "🏃", hostName: "Alex", hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex", distance: "0.5 mi", date: "Nov 4", spotsTotal: 10, spotsTaken: 6),
        .init(title: "Yoga Flow", sportIcon: "🧘‍♀️", hostName: "Emma", hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma", distance: "1.2 mi", date: "Nov 5", spotsTotal: 8, spotsTaken: 5),
        .init(title: "Evening Ride", sportIcon: "🚴‍♀️", hostName: "Tom", hostAvatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Tom", distance: "2.1 mi", date: "Nov 6", spotsTotal: 12, spotsTaken: 7)
    ]

    private let activeUsers: [DiscoveryUser] = [
        .init(name: "Jessica Lee", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Jessica", sport: "Running", distance: "0.3 mi"),
        .init(name: "Tom Harris", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Tom", sport: "Cycling", distance: "0.7 mi"),
        .init(name: "Nina Patel", avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Nina", sport: "Yoga", distance: "1.2 mi")
    ]

    @State private var searchText: String = ""

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
                    activeNowSection
                }
                .padding(.bottom, 120)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Explore More")
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
                TextField("Search sports, people, or places...", text: $searchText)
                    .font(.system(size: 15))
                    .disableAutocorrection(true)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(10)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 10 : 5, x: 0, y: theme.isDarkMode ? 6 : 2)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Sections
extension SearchDiscoveryView {
    private var coachSection: some View {
        Group {
            if let onCoachClick = onCoachClick {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Verified Coaches")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)

                    Button(action: onCoachClick) {
                        HStack(spacing: 10) {
                            AsyncImage(url: URL(string: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alex")) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Text("Alex Thompson")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(theme.colors.textPrimary)
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#A855F7"))
                                        .font(.system(size: 11))
                                }
                                Text("Certified HIIT & Strength Trainer")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.colors.textSecondary)
                                Text("⭐ 4.8 (124 reviews) • 450+ sessions")
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.colors.cardStroke, lineWidth: 2))
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 12 : 5)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Browse by Sport")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                ForEach(sportCategories) { category in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.colors.cardStroke, lineWidth: 2))
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
            }
        }
        .padding(.horizontal)
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trending Near You")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 10) {
                ForEach(mockActivities.prefix(3)) { activity in
                    RoundedRectangle(cornerRadius: 28)
                        .fill(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
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
                                        Text(activity.distance)
                                        Text("•")
                                        Text(activity.date)
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
                                Text("\(activity.spotsTotal - activity.spotsTaken) spots")
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
            }
        }
        .padding(.horizontal)
    }

    private var activeNowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Now")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 10) {
                ForEach(activeUsers) { user in
                    RoundedRectangle(cornerRadius: 28)
                        .fill(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(theme.colors.cardStroke, lineWidth: 2))
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: theme.isDarkMode ? 12 : 8)
                        .overlay(
                            HStack(spacing: 10) {
                                ZStack(alignment: .bottomTrailing) {
                                    AsyncImage(url: URL(string: user.avatar)) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle().fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())

                                    Circle()
                                        .fill(Color(hex: "#A855F7"))
                                        .frame(width: 10, height: 10)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.colors.textPrimary)
                                    Text("\(user.sport) • \(user.distance) away")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                Spacer()
                                HStack(spacing: 6) {
                                    Button("Follow") {}
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(theme.colors.cardBackground)
                                        .cornerRadius(16)
                                    Button("Chat") {}
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "#A855F7"))
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                            }
                            .padding()
                        )
                        .frame(height: 80)
                }
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
