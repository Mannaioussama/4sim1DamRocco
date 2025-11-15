//
//  NotificationsViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct AppNotification: Identifiable {
    let id: String
    let icon: String
    let message: String
    let time: String
    let actionText: String?
}

@MainActor
class NotificationsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var notifications: [AppNotification] = []
    @Published var isLoading: Bool = false
    @Published var selectedNotificationId: String?
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let service: QuickMatchServicing
    
    // MARK: - Initialization
    
    init(service: QuickMatchServicing = QuickMatchService.shared) {
        self.service = service
        Task { await refreshNotifications() }
    }
    
    // MARK: - Computed Properties
    
    var hasNotifications: Bool {
        return !notifications.isEmpty
    }
    
    var notificationCount: Int {
        return notifications.count
    }
    
    var recentNotifications: [AppNotification] {
        return notifications.filter { notification in
            notification.time.contains("ago")
        }
    }
    
    var olderNotifications: [AppNotification] {
        return notifications.filter { notification in
            !notification.time.contains("ago")
        }
    }
    
    var emptyStateTitle: String {
        return "No notifications"
    }
    
    var emptyStateDescription: String {
        return "We'll notify you when something happens"
    }
    
    var emptyStateIcon: String {
        return "🔔"
    }

    // MARK: - Data Loading
    
    func refreshNotifications() async {
        isLoading = true
        errorMessage = nil
        do {
            async let likesResp = service.getLikesReceived()
            async let matchesList = service.getMatches()
            let (likesReceived, matches) = try await (likesResp, matchesList)
            
            let likeCards: [AppNotification] = likesReceived.likes
                .filter { !$0.isMatch }
                .map { like in
                    AppNotification(
                        id: "like-\(like.likeId)",
                        icon: "❤️",
                        message: "\(like.fromUser.name ?? "Someone") liked your profile",
                        time: relativeTime(from: like.createdAt),
                        actionText: "View"
                    )
                }
            
            let matchCards: [AppNotification] = matches.map { match in
                AppNotification(
                    id: "match-\(match.matchId)",
                    icon: "✨",
                    message: "It's a match with \(match.user.name ?? "someone")!",
                    time: relativeTime(from: match.createdAt),
                    actionText: "Chat"
                )
            }
            
            // Combine and sort newest first (by parsed date)
            let combined = (likeCards + matchCards)
                .sorted { lhs, rhs in
                    parsedDate(from: lhs.time) > parsedDate(from: rhs.time)
                }
            
            notifications = combined
        } catch let api as APIError {
            errorMessage = api.userMessage
            notifications = []
        } catch {
            errorMessage = error.localizedDescription
            notifications = []
        }
        isLoading = false
    }
    
    // MARK: - Actions
    
    func dismissNotification(_ notificationId: String) {
        withAnimation(.spring(response: 0.3)) {
            notifications.removeAll { $0.id == notificationId }
        }
        print("Dismissed notification: \(notificationId)")
    }
    
    func handleNotificationAction(_ notification: AppNotification) {
        selectedNotificationId = notification.id
        // TODO: Navigate to appropriate screen (e.g., open chat on match)
        print("Handling action for notification: \(notification.id)")
    }
    
    func markAsRead(_ notificationId: String) {
        // TODO: Mark notification as read on backend (if supported)
        print("Marked notification as read: \(notificationId)")
    }
    
    func markAllAsRead() {
        // TODO: Mark all notifications as read on backend (if supported)
        print("Marked all notifications as read")
    }
    
    func clearAll() {
        withAnimation(.spring(response: 0.3)) {
            notifications.removeAll()
        }
        print("Cleared all notifications")
    }
    
    // MARK: - Helper Methods
    
    func getNotification(by id: String) -> AppNotification? {
        return notifications.first { $0.id == id }
    }
    
    func getNotificationsByType(containing keyword: String) -> [AppNotification] {
        return notifications.filter { notification in
            notification.message.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    func hasActionButton(_ notification: AppNotification) -> Bool {
        return notification.actionText != nil
    }
    
    func getActionButtonText(_ notification: AppNotification) -> String {
        return notification.actionText ?? ""
    }
    
    func isRecentNotification(_ notification: AppNotification) -> Bool {
        return notification.time.contains("ago")
    }
    
    func getNotificationTimeCategory(_ notification: AppNotification) -> String {
        if notification.time.contains("m ago") || notification.time.contains("h ago") {
            return "Today"
        } else if notification.time.contains("Yesterday") {
            return "Yesterday"
        } else {
            return "Older"
        }
    }
    
    // MARK: - Time Formatting
    
    private func relativeTime(from iso: String) -> String {
        // Try ISO8601 with and without fractional seconds
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let altIsoFmt = ISO8601DateFormatter()
        altIsoFmt.formatOptions = [.withInternetDateTime]
        let date = isoFmt.date(from: iso) ?? altIsoFmt.date(from: iso) ?? Date()
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        if days == 1 { return "Yesterday" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }

    // Used only for sorting newest first; interpret "Just now"/"Xm ago" quickly.
    private func parsedDate(from display: String) -> Date {
        if display == "Just now" { return Date() }
        if display.hasSuffix("m ago"), let m = Int(display.replacingOccurrences(of: "m ago", with: "")) {
            return Date().addingTimeInterval(TimeInterval(-m * 60))
        }
        if display.hasSuffix("h ago"), let h = Int(display.replacingOccurrences(of: "h ago", with: "")) {
            return Date().addingTimeInterval(TimeInterval(-h * 3600))
        }
        if display == "Yesterday" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.date(from: display) ?? Date.distantPast
    }
    
    // MARK: - Analytics
    
    func trackNotificationView(_ notification: AppNotification) {
        // TODO: Implement analytics tracking
        print("Viewed notification: \(notification.id)")
    }
    
    func trackNotificationDismissed(_ notification: AppNotification) {
        // TODO: Implement analytics tracking
        print("Dismissed notification: \(notification.id)")
    }
    
    func trackNotificationAction(_ notification: AppNotification) {
        // TODO: Implement analytics tracking
        print("Acted on notification: \(notification.id)")
    }
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Notifications screen viewed")
    }
}
