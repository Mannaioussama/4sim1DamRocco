//
//  FloatingCreateButton.swift
//  NEXO
//
//  Created by ChatGPT on 11/4/2025.
//

import SwiftUI

struct FloatingCreateButtonView: View {
    var onClick: () -> Void

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            Button(action: onClick) {
                ZStack {
                    // MARK: - Floating Shadow
                    Circle()
                        .fill(Color(hex: "#8B5CF6").opacity(0.2))
                        .frame(width: 48, height: 12)
                        .blur(radius: 6)
                        .offset(y: 28)

                    // MARK: - Outer Glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#8B5CF6").opacity(0.4),
                                    Color(hex: "#C4B5FD").opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .blur(radius: 10)
                        .opacity(0.75)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .scaleEffect(1.05)
                        .animation(.easeInOut(duration: 0.3), value: UUID())

                    // MARK: - Main Button
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#8B5CF6"),
                                        Color(hex: "#C4B5FD")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: Color(hex: "#8B5CF6").opacity(0.4), radius: 12, y: 6)
                            .overlay(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        // MARK: - Icon
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)

                        // MARK: - Pulse Ring
                        Circle()
                            .fill(Color(hex: "#8B5CF6").opacity(0.3))
                            .frame(width: 56, height: 56)
                            .scaleEffect(1.4)
                            .opacity(0)
                            .animation(
                                Animation.easeOut(duration: 2)
                                    .repeatForever(autoreverses: false),
                                value: UUID()
                            )
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .frame(width: 70, height: 70)
            .shadow(color: Color(hex: "#8B5CF6").opacity(0.2), radius: 8, y: 3)
            // Position relative to the available geometry instead of UIScreen.main
            .position(
                x: geometry.size.width - 60,
                y: geometry.size.height - 160
            )
            .zIndex(40)
        }
        // Ensure the GeometryReader doesn’t expand infinitely in some containers
        .ignoresSafeArea(edges: .all)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.purple.opacity(0.1), .pink.opacity(0.1)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        FloatingCreateButtonView {
            print("Button tapped")
        }
    }
}
