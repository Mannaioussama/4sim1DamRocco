//
//  AppShellView.swift
//  NEXO
//
//  Created by ROCCO 4X on 11/4/2025.
//

import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var router: AppRouter

    // Sample RoomActivity (matches correct parameter order)
    private let sampleRoomActivity = RoomActivity(
        id: "1",
        sportType: "Basketball",
        title: "Morning Basketball Game",
        description: "Friendly morning basketball session at the local court.",
        location: "Downtown Court",
        date: "Today",
        time: "9:00 AM",
        hostName: "John Doe",
        hostAvatar: "",
        spotsTotal: 10,
        spotsTaken: 7,
        level: "Intermediate"
    )

    // Decide when the floating AI Coach button should be visible
    private var shouldShowFloatingCoach: Bool {
        // Only consider the current top of the active tab navigation stack.
        guard let topRoute = router.activeTopRoute else { return true }
        switch topRoute {
        case .activityRoom,
             .chatConversation(_),   // match and ignore associated value
             .enhancedEventDetails,
             .aiCoach,
             .settings,
             .notifications,
             .achievements,
             .aiMatchmaker,
             .quickMatch,
             .searchDiscovery,
             .coachOnboarding,
             .coachProfile(_),       // match and ignore associated value
             .createActivity:
            return false
        default:
            return true
        }
    }

    var body: some View {
        ZStack {
            // MARK: - Native TabView (system UITabBar)
            TabView(selection: $router.tab) {

                // Left 1: Home
                NavigationStack(path: $router.homePath) {
                    HomeFeedView(
                        onActivityClick: { _ in router.push(.activityRoom) },
                        onSearchClick: { router.push(.searchDiscovery) },
                        onAISuggestionsClick: { router.push(.aiSuggestions) },
                        onQuickMatchClick: { router.push(.quickMatch) },
                        onAIMatchmakerClick: { router.push(.aiMatchmaker) },
                        onEventDetailsClick: { router.push(.enhancedEventDetails) },
                        onCreateClick: { router.push(.createActivity) },
                        onNotificationsClick: { router.push(.notifications) }
                    )
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(AppTab.home)

                // Left 2: Sessions (Map)
                NavigationStack(path: $router.mapPath) {
                    MapScreen(onActivityClick: { _ in router.push(.activityRoom) })
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Sessions")
                }
                .tag(AppTab.map)

                // Center spacer: non-selectable item to keep spacing symmetrical
                Color.clear
                    .tabItem {
                        VStack(spacing: 2) {
                            Image(systemName: "circle").opacity(0.001)
                            Text(" ").opacity(0.001)
                        }
                    }
                    .tag(AppTab.create)

                // Right 1: Chat
                NavigationStack(path: $router.chatPath) {
                    ChatListView(onChatSelect: { chatId in
                        router.push(.chatConversation(chatId: chatId)) // pass the selected id
                    })
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
                }
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(AppTab.chat)

                // Right 2: Dashboard (Profile)
                NavigationStack(path: $router.profilePath) {
                    ProfilePage(
                        onSettingsClick: { router.push(.settings) },
                        onAchievementsClick: { router.push(.achievements) }
                    )
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
                }
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2.fill")
                    Text("Dashboard")
                }
                .tag(AppTab.profile)
            }
            // Keep selection off the center spacer tab by redirecting create -> map
            .onChange(of: router.tab) { _, newValue in
                if newValue == .create {
                    DispatchQueue.main.async {
                        router.select(.map)
                    }
                }
            }
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarColorScheme(.light, for: .tabBar)
            .safeAreaInset(edge: .bottom) {
                if shouldShowFloatingCoach {
                    Color.clear.frame(height: 44)
                }
            }

            // MARK: - Floating Center AI Coach Button (hovering above tab bar)
            if shouldShowFloatingCoach {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        aiCoachButton
                            .offset(x: 2)
                        Spacer()
                    }
                    .padding(.bottom, 28)
                }
                .allowsHitTesting(true)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    // MARK: - Floating AI Coach Button
    private var aiCoachButton: some View {
        Button {
            router.push(.aiCoach)
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: "#8B5CF6").opacity(0.25))
                    .frame(width: 92, height: 30)
                    .blur(radius: 12)
                    .offset(y: 30)

                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "#8B5CF6"),
                            Color(hex: "#C4B5FD")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 64, height: 64)
                    .cornerRadius(20)
                    .shadow(color: Color(hex: "#8B5CF6").opacity(0.35), radius: 14, y: 8)

                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.6), radius: 2, y: 1)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .accessibilityLabel("AI Coach")
    }

    // MARK: - Route-to-View Mapping
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .aiCoach:
            AICoachView()
                .navigationTitle("AI Coach")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.visible, for: .navigationBar)
                .toolbar(.hidden, for: .tabBar)
                .navigationBarBackButtonHidden(false)

        case .settings:
            SettingsView(
                onBack: { router.pop() },
                onApplyVerification: { router.push(.coachOnboarding) },
                onLogout: {
                    router.reset()
                    router.shouldStartAtLogin = true
                    router.isAuthenticated = false
                }
            )
            .toolbar(.hidden, for: .tabBar)

        case .notifications:
            NotificationsScreen(onBack: { router.pop() })
                .toolbar(.hidden, for: .tabBar)
                .navigationBarBackButtonHidden(true)

        case .achievements:
            AchievementsView()
                .toolbar(.hidden, for: .tabBar)

        case .aiMatchmaker:
            AIMatchmakerView()
                .toolbar(.hidden, for: .tabBar)

        case .aiSuggestions:
            AISuggestionsView()
                .toolbar(.hidden, for: .tabBar)

        case .activityRoom:
            ActivityRoomView(
                activity: sampleRoomActivity,
                onBack: { router.pop() }
            )
            .toolbar(.hidden, for: .tabBar)

        case .enhancedEventDetails:
            EnhancedEventDetailsView(
                eventId: sampleRoomActivity.id,
                onBack: { router.pop() },
                onJoin: { router.push(.activityRoom) },
                onViewCoach: { coachId in router.push(.coachProfile(coachId: coachId)) },
                onMessage: { router.push(.chatConversation(chatId: "sampleChat123")) } // supply a real id when available
            )
            .toolbar(.hidden, for: .tabBar)

        case .chatConversation(let chatId):
            ChatConversationView(
                chatId: chatId,
                onBack: { router.pop() }
            )
            .toolbar(.hidden, for: .tabBar)

        case .coachProfile(let coachId):
            CoachProfileView(
                coachId: coachId,
                onBack: { router.pop() }
            )
            .toolbar(.hidden, for: .tabBar)

        case .quickMatch:
            QuickMatchView()
                .toolbar(.hidden, for: .tabBar)

        case .searchDiscovery:
            SearchDiscoveryView()
                .toolbar(.hidden, for: .tabBar)

        case .coachOnboarding:
            CoachOnboardingView()
                .toolbar(.hidden, for: .tabBar)

        case .createActivity:
            CreateActivityView()
                .toolbar(.hidden, for: .tabBar)

        case .splash, .onboarding, .login, .signUp, .resetPassword:
            EmptyView()
        }
    }
}

#if DEBUG
struct AppShellView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(Theme())
            .environmentObject(AuthStore(tokenStore: KeychainTokenStore.shared))
    }
}
#endif

