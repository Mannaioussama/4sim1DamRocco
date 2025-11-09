//
//  AppRouter.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import Combine
import SwiftUI

// MARK: - Navigation Routes
enum Route: Hashable {
    case splash
    case onboarding
    case login
    case signUp
    case resetPassword
    case aiCoach
    case settings
    case notifications
    case achievements
    case aiMatchmaker
    case aiSuggestions
    case activityRoom
    case enhancedEventDetails
    case chatConversation
    case coachProfile
    case quickMatch
    case searchDiscovery
    case coachOnboarding
    case createActivity
}

// MARK: - Tabs (declared elsewhere in your project)
// enum AppTab: Hashable { case home, map, create, chat, profile }

// MARK: - Router Class
final class AppRouter: ObservableObject {
    @Published var tab: AppTab = .home

    // Each tab keeps its own NavigationPath
    @Published var homePath: [Route] = []
    @Published var mapPath: [Route] = []
    @Published var chatPath: [Route] = []
    @Published var profilePath: [Route] = []

    @Published var lastRoute: Route? = nil

    // Auth state drives RootView’s initial content
    @Published var isAuthenticated: Bool = false

    // When logging out, set this true to land directly on Login (skip splash/onboarding)
    @Published var shouldStartAtLogin: Bool = false

    // MARK: - Active path helper without unsafe pointers
    var activePath: [Route] {
        get {
            switch tab {
            case .home:    return homePath
            case .map:     return mapPath
            case .chat:    return chatPath
            case .profile: return profilePath
            case .create:  return homePath // create is a spacer; default to home
            }
        }
        set {
            switch tab {
            case .home:    homePath = newValue
            case .map:     mapPath = newValue
            case .chat:    chatPath = newValue
            case .profile: profilePath = newValue
            case .create:  homePath = newValue
            }
        }
    }

    var activeTopRoute: Route? {
        switch tab {
        case .home:    return homePath.last
        case .map:     return mapPath.last
        case .chat:    return chatPath.last
        case .profile: return profilePath.last
        case .create:  return homePath.last
        }
    }

    // MARK: - Tab selection
    func select(_ tab: AppTab) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.tab = tab
        }
    }

    // MARK: - Navigation operations (act on the active tab’s path)
    func push(_ route: Route) {
        withAnimation(.easeInOut(duration: 0.25)) {
            switch tab {
            case .home:    homePath.append(route)
            case .map:     mapPath.append(route)
            case .chat:    chatPath.append(route)
            case .profile: profilePath.append(route)
            case .create:  homePath.append(route)
            }
            lastRoute = route
        }
    }

    func pop() {
        switch tab {
        case .home:
            if !homePath.isEmpty { homePath.removeLast() }
        case .map:
            if !mapPath.isEmpty { mapPath.removeLast() }
        case .chat:
            if !chatPath.isEmpty { chatPath.removeLast() }
        case .profile:
            if !profilePath.isEmpty { profilePath.removeLast() }
        case .create:
            if !homePath.isEmpty { homePath.removeLast() }
        }
    }

    func reset() {
        // Clear all navigation paths and ensure we start from the home tab
        homePath.removeAll()
        mapPath.removeAll()
        chatPath.removeAll()
        profilePath.removeAll()
        lastRoute = nil
        tab = .home
    }
}
