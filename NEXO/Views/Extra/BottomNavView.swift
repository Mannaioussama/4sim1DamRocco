//
//  BottomNavView.swift
//  NEXO
//
//  Created by ChatGPT on 4/11/2025.
//

import SwiftUI

// MARK: - Bottom Navigation Bar
struct BottomNavView: View {
    @Binding var activeTab: AppTab
    var onTabChange: (AppTab) -> Void
    var onAICoachClick: (() -> Void)?

    // Drive long-running pulse animation safely
    @State private var pulse = false

    // MARK: - Tabs
    // Revert: remove .create from visible tabs
    private let leftTabs: [NavTab] = [
        .init(id: .home, icon: "house.fill", label: "Home"),
        .init(id: .map, icon: "calendar", label: "Sessions")
    ]

    private let rightTabs: [NavTab] = [
        .init(id: .chat, icon: "message.fill", label: "Chat"),
        .init(id: .profile, icon: "rectangle.grid.2x2.fill", label: "Dashboard")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            ZStack {
                // Glass background with blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .background(Color.white.opacity(0.7))
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.purple.opacity(0.15), radius: 20, y: -4)
                    .ignoresSafeArea(edges: .bottom)

                HStack(spacing: 0) {
                    // Left Tabs
                    HStack(spacing: 0) {
                        ForEach(leftTabs) { tab in
                            navButton(tab: tab)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Center Floating AI Coach Button
                    aiCoachButton

                    // Right Tabs
                    HStack(spacing: 0) {
                        ForEach(rightTabs) { tab in
                            navButton(tab: tab)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .padding(.top, 5)
            }
            .frame(height: 95)
        }
        // Stable identity across hide/show
        .id("BottomNav")
        // Start pulse once, independent of show/hide
        .task {
            // keep toggling pulse gently
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }

    // MARK: - Navigation Tab Button
    private func navButton(tab: NavTab) -> some View {
        let isActive = (activeTab == tab.id)
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                activeTab = tab.id
                onTabChange(tab.id)
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .renderingMode(.original) // avoid template/material blending
                    .foregroundStyle(isActive ? Color(hexValue: "#8B5CF6") : Color.black.opacity(0.85))
                    .font(.system(size: 22, weight: .semibold))
                    .scaleEffect(isActive ? 1.15 : 1.0)

                Text(tab.label)
                    .font(.system(size: 10, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? Color(hexValue: "#8B5CF6") : Color.black.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        // Prevent color animation states sticking at 0 alpha
        .animation(nil, value: activeTab)
    }

    // MARK: - AI Coach Floating Button
    private var aiCoachButton: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                onAICoachClick?()
            }
        } label: {
            ZStack {
                // Glow shadow
                Circle()
                    .fill(Color(hexValue: "#8B5CF6").opacity(0.2))
                    .frame(width: 80, height: 25)
                    .blur(radius: 12)
                    .offset(y: 30)

                // Pulse animation (driven by @State 'pulse')
                Circle()
                    .strokeBorder(Color(hexValue: "#8B5CF6").opacity(0.3), lineWidth: 6)
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(0.5)
                    .blur(radius: 3)

                // Main Button
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hexValue: "#8B5CF6"),
                            Color(hexValue: "#C4B5FD")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 70, height: 70)
                    .cornerRadius(20)
                    .shadow(color: Color(hexValue: "#8B5CF6").opacity(0.4), radius: 15, y: 8)

                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.6), radius: 3, y: 1)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .frame(width: 70, height: 90)
        .offset(y: -28)
        .overlay(
            Text("AI Coach")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.black)
                .offset(y: -18),
            alignment: .bottom
        )
    }
}

// MARK: - Model
struct NavTab: Identifiable {
    let id: AppTab
    let icon: String
    let label: String
}

// NOTE: AppTab is defined centrally in AppTab.swift

// MARK: - Preview
#Preview {
    BottomNavView(activeTab: .constant(.home)) { _ in } onAICoachClick: {
        print("AI Coach tapped")
    }
}
