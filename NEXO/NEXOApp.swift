//
//  NEXOApp.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

@main
struct NEXOApp: App {
    @StateObject private var theme = Theme()
    @StateObject private var authStore = AuthStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(theme)
                .environmentObject(authStore)
                // Optional: flip system scheme too (status bar/material defaults).
                // You can comment this out if you only want semantic colors to change.
                .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - Root View (Router-driven)
struct RootView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var authStore: AuthStore
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
                                authPath.removeAll()
                                authPath.append(.onboarding)
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
