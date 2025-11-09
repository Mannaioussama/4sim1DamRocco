//
//  NotificationsScreen.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

// MARK: - Notification Model

struct AppNotification: Identifiable {
    let id: String
    let icon: String
    let message: String
    let time: String
    let actionText: String?
}

struct NotificationsScreen: View {
    var onBack: () -> Void

    @EnvironmentObject private var theme: Theme
    
    // Make notifications mutable so dismiss can work
    @State private var notifications: [AppNotification] = [
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
    
    var body: some View {
        ZStack {
            // Use app-wide themed background
            theme.colors.backgroundGradient.ignoresSafeArea()
            // Optional floating orbs to match other pages
            backgroundOrbs.ignoresSafeArea()

            VStack(spacing: 0) {
                if notifications.isEmpty {
                    emptyState
                        .padding(.top, 8)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(notifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onPrimaryAction: {
                                        // Placeholder: route to details if needed
                                    },
                                    onDismiss: {
                                        withAnimation(.spring(response: 0.3)) {
                                            notifications.removeAll { $0.id == notification.id }
                                        }
                                    }
                                )
                                .environmentObject(theme)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, 100)
                        // Reduce the default gap under the nav bar (iOS 15-safe)
                        .padding(.top, -6)
                    }
                }
            }
        }
        // System navigation bar with themed back button/title
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true) // Hide the system back button to avoid duplicates
    }
    
    // MARK: - Optional Themed Orbs (matches other screens vibe)
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [
                        theme.colors.accentPurpleFill.opacity(theme.isDarkMode ? 0.25 : 0.35),
                        theme.colors.accentPink.opacity(theme.isDarkMode ? 0.20 : 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 288, height: 288)
                .blur(radius: 120)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(LinearGradient(
                    colors: [
                        Color.blue.opacity(theme.isDarkMode ? 0.18 : 0.28),
                        theme.colors.accentPurpleFill.opacity(theme.isDarkMode ? 0.2 : 0.3)
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ))
                .frame(width: 384, height: 384)
                .blur(radius: 120)
                .offset(x: 150, y: 500)
            
            Circle()
                .fill(LinearGradient(
                    colors: [
                        theme.colors.accentPink.opacity(theme.isDarkMode ? 0.18 : 0.28),
                        theme.colors.accentPurpleGlow.opacity(theme.isDarkMode ? 0.14 : 0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: 150, y: -100)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Empty State (use themed colors)
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.colors.accentPurpleFill.opacity(0.22),
                                theme.colors.accentPink.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .blur(radius: 12)
                
                ZStack {
                    Circle()
                        .fill(theme.colors.cardBackground)
                        .overlay(theme.colors.barMaterial)
                        .overlay(
                            Circle()
                                .stroke(theme.colors.cardStroke, lineWidth: 2)
                        )
                    
                    Text("🔔")
                        .font(.system(size: 64))
                }
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(theme.isDarkMode ? 0.35 : 0.15), radius: 20, x: 0, y: 10)
            }
            
            Text("No notifications")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            Text("We'll notify you when something happens")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// MARK: - Notification Card

struct NotificationCard: View {
    @EnvironmentObject private var theme: Theme

    let notification: AppNotification
    let onPrimaryAction: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Icon
            Text(notification.icon)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)
                .background(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.1), radius: 10, x: 0, y: 4)
                .accessibilityHidden(true)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.message)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(notification.time)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer(minLength: 0)
            
            // Actions
            HStack(spacing: 6) {
                if let actionText = notification.actionText {
                    Button(action: onPrimaryAction) {
                        Text(actionText)
                    }
                    .buttonStyle(BrandButtonStyle(variant: .outline))
                    .accessibilityLabel("\(actionText) notification")
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Dismiss notification")
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.08), radius: 12, x: 0, y: 6)
    }
}

// NOTE: Reusable components defined in other files:
// - BrandButtonStyle, ScaleButtonStyle, Color.init(hex:)

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationsScreen(onBack: {
            print("Back tapped")
        })
        .environmentObject(Theme())
    }
}
