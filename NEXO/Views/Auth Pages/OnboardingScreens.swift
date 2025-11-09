//
//  OnboardingScreens.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct OnboardingScreenData {
    let title: String
    let subtitle: String
    let imageURL: URL
    let iconName: String
    let accentColor: Color
}

struct OnboardingScreensView: View {
    @EnvironmentObject private var theme: Theme
    @State private var currentStep: Int = 0
    let steps: [OnboardingScreenData]
    let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        self.steps = [
            OnboardingScreenData(
                title: "Welcome to NEXO",
                subtitle: "Connect with people who love sports as much as you do",
                imageURL: URL(string: "https://images.unsplash.com/photo-1760879946121-893199733851?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080")!,
                iconName: "waveform.path.ecg",
                accentColor: Color(hex: "8B5CF6")
            ),
            OnboardingScreenData(
                title: "Find Your Sport Partners",
                subtitle: "Discover nearby activities and join sessions with like-minded people",
                imageURL: URL(string: "https://images.unsplash.com/photo-1758684051112-3df152ce3256?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080")!,
                iconName: "person.3.fill",
                accentColor: Color(hex: "EC4899")
            ),
            OnboardingScreenData(
                title: "Stay Active Together",
                subtitle: "Create your own activities or join existing ones near you",
                imageURL: URL(string: "https://images.unsplash.com/photo-1760879946121-893199733851?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080")!,
                iconName: "mappin.circle.fill",
                accentColor: Color(hex: "10B981")
            )
        ]
    }

    var body: some View {
        ZStack {
            // Fullscreen background image
            imageBackground
            
            // Floating orbs
            floatingOrbs
            
            // Center glass icon
            centerIcon
            
            // Bottom floating card
            VStack {
                Spacer()
                bottomCard
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if currentStep < steps.count - 1 {
                    skipButton
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        // Force the app’s chosen appearance here as well
        .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
    }
    
    // MARK: - Fullscreen Image Background
    
    private var imageBackground: some View {
        let step = steps[currentStep]
        
        return GeometryReader { proxy in
            ZStack {
                AsyncImage(url: step.imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } placeholder: {
                    ZStack {
                        theme.colors.backgroundGradient
                        ProgressView()
                            .tint(step.accentColor)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
                
                // Gradient overlay for better readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(theme.isDarkMode ? 0.55 : 0.25),
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(theme.isDarkMode ? 0.65 : 0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.5), value: currentStep)
        }
    }
    
    // MARK: - Floating Orbs
    
    private var floatingOrbs: some View {
        ZStack {
            // Purple orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "8B5CF6").opacity(theme.isDarkMode ? 0.28 : 0.35),
                            Color(hex: "C4B5FD").opacity(theme.isDarkMode ? 0.16 : 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 100)
                .offset(x: -120, y: -280)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: currentStep)
            
            // Pink orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "EC4899").opacity(theme.isDarkMode ? 0.32 : 0.4),
                            Color(hex: "F9A8D4").opacity(theme.isDarkMode ? 0.18 : 0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 100)
                .offset(x: 140, y: 400)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(1), value: currentStep)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Center Glass Icon
    
    private var centerIcon: some View {
        let step = steps[currentStep]
        
        return ZStack {
            // Pulsating glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            step.accentColor.opacity(theme.isDarkMode ? 0.45 : 0.6),
                            Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .scaleEffect(currentStep % 2 == 0 ? 1.0 : 1.2)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: currentStep)
            
            // Glass circle with crystal effect (theme glass)
            ZStack {
                Circle()
                    .fill(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(
                        Circle()
                            .stroke(theme.colors.cardStroke, lineWidth: 4)
                    )
                
                // Crystal top shine
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDarkMode ? 0.25 : 0.95),
                                Color.white.opacity(theme.isDarkMode ? 0.12 : 0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(12)
                    .mask(
                        VStack {
                            Rectangle()
                                .frame(height: 50)
                            Spacer()
                        }
                    )
                
                // Icon
                Image(systemName: step.iconName)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                step.accentColor,
                                step.accentColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: step.accentColor.opacity(0.6), radius: 18, x: 0, y: 10)
            }
            .frame(width: 150, height: 150)
            .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.35 : 0.3), radius: 40, x: 0, y: 25)
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentStep)
    }
    
    // MARK: - Bottom Floating Card (Compact Crystal Glass)
    
    private var bottomCard: some View {
        let step = steps[currentStep]
        
        return VStack(spacing: 20) {
            // Title and subtitle
            VStack(spacing: 10) {
                Text(step.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .id("title-\(currentStep)")
                
                Text(step.subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)
                    .id("subtitle-\(currentStep)")
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
            
            // Progress indicators
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == currentStep
                                ? LinearGradient(
                                    colors: [
                                        step.accentColor,
                                        step.accentColor.opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4),
                                        Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    index == currentStep
                                        ? theme.colors.cardStroke.opacity(0.0)
                                        : theme.colors.cardStroke,
                                    lineWidth: index == currentStep ? 0 : 1.5
                                )
                        )
                        .frame(width: index == currentStep ? 36 : 10, height: 10)
                        .shadow(
                            color: index == currentStep ? step.accentColor.opacity(0.5) : .clear,
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentStep)
                }
            }
            
            // Action button
            actionButton
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 36)
        .background(
            ZStack {
                // Main crystal glass background
                RoundedRectangle(cornerRadius: 35)
                    .fill(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                
                // Top crystal shine
                RoundedRectangle(cornerRadius: 35)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDarkMode ? 0.18 : 0.9),
                                Color.white.opacity(0.0),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .mask(
                        VStack {
                            Rectangle()
                                .frame(height: 80)
                            Spacer()
                        }
                    )
                
                // Bottom subtle gradient
                RoundedRectangle(cornerRadius: 35)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                step.accentColor.opacity(theme.isDarkMode ? 0.05 : 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 35)
                    .stroke(theme.colors.cardStroke, lineWidth: 2.5)
            )
            .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.35 : 0.2), radius: 45, x: 0, y: 25)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Action Button (Crystal Glass)
    
    private var actionButton: some View {
        let step = steps[currentStep]
        
        return ZStack {
            // Button glow
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    RadialGradient(
                        colors: [
                            step.accentColor.opacity(theme.isDarkMode ? 0.35 : 0.5),
                            step.accentColor.opacity(theme.isDarkMode ? 0.22 : 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .blur(radius: 30)
                .frame(height: 70)
            
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if currentStep < steps.count - 1 {
                        currentStep += 1
                    } else {
                        onComplete()
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Text(currentStep < steps.count - 1 ? "Next" : "Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Image(systemName: currentStep < steps.count - 1 ? "arrow.right" : "arrow.right.circle.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(currentStep < steps.count - 1 ? theme.colors.textPrimary : step.accentColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    ZStack {
                        // Crystal glass background
                        RoundedRectangle(cornerRadius: 28)
                            .fill(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                        
                        // Top shine
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDarkMode ? 0.18 : 0.9),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .mask(
                                VStack {
                                    Rectangle()
                                        .frame(height: 25)
                                    Spacer()
                                }
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(theme.colors.cardStroke, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.3 : 0.15), radius: 25, x: 0, y: 15)
            }
            .buttonStyle(PremiumButtonStyle())
        }
    }
    
    // MARK: - Skip Button
    
    private var skipButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                onComplete()
            }
        }) {
            Text("Skip")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(
                    ZStack {
                        theme.colors.cardBackground
                            .background(theme.colors.barMaterial)
                        
                        // Top shine
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDarkMode ? 0.14 : 0.8),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.colors.cardStroke, lineWidth: 2)
                )
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.25 : 0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Premium Button Style

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OnboardingScreensView {
            print("Onboarding completed")
        }
        .environmentObject(Theme())
    }
}
