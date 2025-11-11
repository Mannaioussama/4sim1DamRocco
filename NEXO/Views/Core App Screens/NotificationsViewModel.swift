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

class NotificationsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var notifications: [AppNotification] = []
    @Published var isLoading: Bool = false
    @Published var selectedNotificationId: String?
    
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
    
    // MARK: - Initialization
    
    init() {
        loadNotifications()
    }
    
    // MARK: - Data Loading
    
    private func loadNotifications() {
        isLoading = true
        
        // Mock data - In production, fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.notifications = [
                AppNotification(
                    id: "1",
                    icon: "👥",
                    message: "Sarah Johnson joined your swimming session",
                    time: "2m ago",
                    actionText: nil
                ),
                AppNotification(
                    id: "2",
                    icon: "🏀",
                    message: "New basketball match near you - Downtown Court",
                    time: "15m ago",
                    actionText: "View"
                ),
                AppNotification(
                    id: "3",
                    icon: "💬",
                    message: "Michael Chen sent you a message",
                    time: "1h ago",
                    actionText: nil
                ),
                AppNotification(
                    id: "4",
                    icon: "⭐",
                    message: "You received a 5-star rating from Emma Wilson!",
                    time: "2h ago",
                    actionText: nil
                ),
                AppNotification(
                    id: "5",
                    icon: "🎯",
                    message: "Achievement unlocked: Marathon Runner 🏃",
                    time: "3h ago",
                    actionText: "View"
                ),
                AppNotification(
                    id: "6",
                    icon: "📅",
                    message: "Reminder: Yoga session starts in 1 hour",
                    time: "Yesterday",
                    actionText: "Details"
                ),
                AppNotification(
                    id: "7",
                    icon: "👋",
                    message: "3 new connection requests",
                    time: "Yesterday",
                    actionText: "View"
                )
            ]
            self?.isLoading = false
        }
    }
    
    // MARK: - Actions
    
    func dismissNotification(_ notificationId: String) {
        withAnimation(.spring(response: 0.3)) {
            notifications.removeAll { $0.id == notificationId }
        }
        
        // TODO: Mark as read on backend
        print("Dismissed notification: \(notificationId)")
    }
    
    func handleNotificationAction(_ notification: AppNotification) {
        selectedNotificationId = notification.id
        
        // TODO: Navigate to appropriate screen based on notification type
        print("Handling action for notification: \(notification.id)")
    }
    
    func markAsRead(_ notificationId: String) {
        // TODO: Mark notification as read on backend
        print("Marked notification as read: \(notificationId)")
    }
    
    func markAllAsRead() {
        // TODO: Mark all notifications as read on backend
        print("Marked all notifications as read")
    }
    
    func clearAll() {
        withAnimation(.spring(response: 0.3)) {
            notifications.removeAll()
        }
        
        // TODO: Clear all notifications on backend
        print("Cleared all notifications")
    }
    
    func refreshNotifications() {
        loadNotifications()
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
