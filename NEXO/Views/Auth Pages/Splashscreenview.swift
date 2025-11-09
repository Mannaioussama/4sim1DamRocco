//
//  Splashscreenview.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var theme: Theme

    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.9
    @State private var logoOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0
    @State private var logoYOffset: CGFloat = 0
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Themed background
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            // Floating Orbs - adjust opacities for dark mode similar to other screens
            FloatingOrb(
                size: 128,
                color: LinearGradient(
                    colors: [
                        Color(hex: "8B5CF6").opacity(theme.isDarkMode ? 0.18 : 0.3),
                        Color(hex: "C4B5FD").opacity(theme.isDarkMode ? 0.12 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: -140,
                yOffset: -250,
                delay: 0
            )
            
            FloatingOrb(
                size: 160,
                color: LinearGradient(
                    colors: [
                        Color(hex: "EC4899").opacity(theme.isDarkMode ? 0.22 : 0.35),
                        Color(hex: "F9A8D4").opacity(theme.isDarkMode ? 0.12 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 140,
                yOffset: 150,
                delay: 1
            )
            
            FloatingOrb(
                size: 96,
                color: LinearGradient(
                    colors: [
                        Color(hex: "0066FF").opacity(theme.isDarkMode ? 0.2 : 0.3),
                        Color(hex: "60A5FA").opacity(theme.isDarkMode ? 0.12 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 0,
                yOffset: 0,
                delay: 2
            )
            
            FloatingOrb(
                size: 80,
                color: LinearGradient(
                    colors: [
                        Color(hex: "2ECC71").opacity(theme.isDarkMode ? 0.18 : 0.25),
                        Color(hex: "10B981").opacity(theme.isDarkMode ? 0.1 : 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 100,
                yOffset: -150,
                delay: 3
            )
            
            // Main Content
            VStack(spacing: 0) {
                // Logo with Crystal Glass Effect
                ZStack {
                    // Outer Shimmer Effect
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "8B5CF6").opacity(theme.isDarkMode ? 0.14 : 0.2),
                                    Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4),
                                    Color(hex: "EC4899").opacity(theme.isDarkMode ? 0.14 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 145, height: 145)
                        .blur(radius: 30)
                        .scaleEffect(1.1)
                        .opacity(logoOpacity)
                    
                    // Crystal Glass Container
                    ZStack {
                        // Outer glow
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "8B5CF6").opacity(theme.isDarkMode ? 0.22 : 0.3),
                                        Color(hex: "EC4899").opacity(theme.isDarkMode ? 0.22 : 0.3),
                                        Color(hex: "0066FF").opacity(theme.isDarkMode ? 0.22 : 0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 136, height: 136)
                            .blur(radius: 12)
                            .opacity(theme.isDarkMode ? 0.6 : 0.75)
                        
                        // Main glass container
                        ZStack {
                            // Glass background (theme-aware)
                            RoundedRectangle(cornerRadius: 24)
                                .fill(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                                )
                                .cornerRadius(24)
                            
                            // Top highlight for glass shine effect
                            VStack {
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDarkMode ? 0.18 : 0.6),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 64)
                                .cornerRadius(24, corners: [.topLeft, .topRight])
                                
                                Spacer()
                            }
                            
                            // Inner shadow for depth
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Color.black.opacity(theme.isDarkMode ? 0.15 : 0.05), lineWidth: 1)
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.12 : 0.05), radius: 4, x: 0, y: 2)
                            
                            // Logo Image
                            Image("NEXO LOGO")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                                .offset(y: logoYOffset)
                        }
                        .frame(width: 128, height: 128)
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.15), radius: 30, x: 0, y: 15)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .padding(.bottom, 32)
                
                // App Name
                Text("NEXO")
                    .font(.system(size: 60, weight: .bold))
                    .tracking(3)
                    .foregroundColor(theme.colors.textPrimary)
                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                    .padding(.bottom, 8)
                
                // Tagline
                Text("Connect. Play. Excel.")
                    .font(.system(size: 18))
                    .tracking(1)
                    .foregroundColor(theme.colors.textSecondary)
                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.1 : 0.05), radius: 2, x: 0, y: 1)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                    .padding(.bottom, 48)
                
                // Loading Indicator - Crystal Glass Pills
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        CrystalLoadingDot(delay: Double(index) * 0.1)
                            .offset(y: textOffset)
                            .opacity(textOpacity)
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
            
            // Complete after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
        // Optional: force the chosen scheme here too (App already sets preferredColorScheme)
        .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Logo bounce animation
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            logoYOffset = -10
        }
        
        // Text slide up animation
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            textOffset = 0
            textOpacity = 1.0
        }
    }
}

// MARK: - Floating Orb Component with Gradient

struct FloatingOrb: View {
    let size: CGFloat
    let color: LinearGradient
    let xOffset: CGFloat
    let yOffset: CGFloat
    let delay: Double
    
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.4)
            .offset(x: xOffset, y: yOffset)
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 0.5)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Crystal Loading Dot Component

struct CrystalLoadingDot: View {
    @EnvironmentObject private var theme: Theme
    let delay: Double
    @State private var isBouncing = false
    
    var body: some View {
        ZStack {
            // Glass pill with border (theme-aware)
            Circle()
                .fill(theme.colors.cardBackground)
                .background(theme.colors.barMaterial)
                .overlay(
                    Circle()
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.3), radius: 4, x: 0, y: 2)
        }
        .offset(y: isBouncing ? -8 : 0)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay + 0.4)
            ) {
                isBouncing = true
            }
        }
    }
}

// MARK: - Custom Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView(onComplete: {
        print("Splash screen completed")
    })
    .environmentObject(Theme())
}
