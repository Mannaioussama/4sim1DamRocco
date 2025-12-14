//
//  NEXOApp.swift
//  NEXO
//
//  Created by ROCCO m 404
import SwiftUI
import HealthKit

@main
struct NEXOApp: App {
    @StateObject private var theme = Theme()
    @StateObject private var authStore = AuthStore()
    @StateObject private var activityAPIService = ActivityAPIService() // Shared across the app
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(theme)
                .environmentObject(authStore)
                .environmentObject(activityAPIService) // Provide shared ActivityAPIService
                .environmentObject(localizationManager)
                // Switch layout direction for Arabic (RTL) vs others (LTR)
                .environment(\.layoutDirection, localizationManager.isRTL ? .rightToLeft : .leftToRight)
                // Optional: flip system scheme too (status bar/material defaults).
                // You can comment this out if you only want semantic colors to change.
                .preferredColorScheme(theme.isDarkMode ? .dark : .light)
                .onAppear {
                    // Configure Stripe once at app startup
                    StripeConfig.shared.configure()
                }
                .onOpenURL { url in
                    _ = StravaOAuthHandler.shared.handleDeepLink(url)
                }
        }
    }
}

// MARK: - Root View (Router-driven)
struct RootView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var activityAPIService: ActivityAPIService
    @StateObject private var router = AppRouter()
    // Separate path for the auth flow so it never contaminates the app shell
    @State private var authPath: [Route] = []

    var body: some View {
        Group {
            if router.isAuthenticated {
                // After auth, show the main app shell with its own NavigationStack
                AppShellView()
                    .environmentObject(router)
                    .environmentObject(theme) // FIX: forward Theme to AppShellView and all its children
                    .environmentObject(activityAPIService) // Forward ActivityAPIService to MapScreen
                    .onAppear {
                        // Eagerly load activities once the main app shell is visible so
                        // Home and Sessions (map) have data on first open.
                        Task {
                            await activityAPIService.fetchAllActivities()
                            await activityAPIService.fetchMyActivities()
                        }
                    }
            } else {
                // Auth flow stack
                NavigationStack(path: $authPath) {
                    // Decide where to start: direct Login (after logout) or Splash (fresh launch)
                    Group {
                        if router.shouldStartAtLogin {
                            LoginView(
                                authStore: authStore,
                                onLogin: {
                                    router.reset()
                                    router.isAuthenticated = true
                                    router.select(.home)
                                    authPath.removeAll()
                                    router.shouldStartAtLogin = false
                                },
                                onSignUpClick: {
                                    authPath.append(.signUp)
                                },
                                onForgotPasswordClick: {
                                    authPath.append(.resetPassword)
                                }
                            )
                        } else {
                            SplashScreenView {
                                // If we already have a valid session (Remember Me), skip onboarding/login
                                if authStore.isLoggedIn {
                                    router.reset()
                                    router.isAuthenticated = true
                                    router.select(.home)
                                    router.shouldStartAtLogin = false
                                } else {
                                    authPath.removeAll()
                                    authPath.append(.onboarding)
                                }
                            }
                        }
                    }
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .onboarding:
                            OnboardingView(
                                onComplete: {
                                    authPath.append(.login)
                                }
                            )
                        case .login:
                            LoginView(
                                authStore: authStore,
                                onLogin: {
                                    router.reset()
                                    router.isAuthenticated = true
                                    router.select(.home)
                                    authPath.removeAll()
                                },
                                onSignUpClick: {
                                    authPath.append(.signUp)
                                },
                                onForgotPasswordClick: {
                                    authPath.append(.resetPassword)
                                }
                            )
                        case .signUp:
                            SignUpPage(
                                onSignUp: {
                                    router.reset()
                                    router.isAuthenticated = true
                                    router.select(.home)
                                    authPath.removeAll()
                                },
                                onLoginClick: {
                                    if !authPath.isEmpty { authPath.removeLast() }
                                },
                                authStore: authStore
                            )
                        case .resetPassword:
                            ResetPasswordPage(
                                onBackToLogin: {
                                    if !authPath.isEmpty { authPath.removeLast() }
                                },
                                authStore: authStore
                            )
                        default:
                            EmptyView()
                        }
                    }
                }
                .environmentObject(router)
            }
        }
        .environmentObject(router)
        // Optional: also apply at RootView level; App already applies preferredColorScheme.
        .background(theme.colors.backgroundGradient)
        // Keep router auth state in sync if authStore changes elsewhere
        .onChange(of: authStore.isLoggedIn) { _, newValue in
            if newValue {
                router.isAuthenticated = true
            }
        }
    }
}

