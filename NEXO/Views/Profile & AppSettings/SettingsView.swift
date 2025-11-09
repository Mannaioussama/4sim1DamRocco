//
//  SettingsView.swift
//  NEXO
//
//  Created by ChatGPT on 11/4/2025.
//

import SwiftUI

struct SettingsView: View {
    var onBack: (() -> Void)?
    var onApplyVerification: (() -> Void)?
    var onLogout: (() -> Void)?

    @EnvironmentObject private var theme: Theme

    // MARK: - Local Palette for SettingsView (only static accents)
    struct Palette {
        static let iconPurple = Color(hex: "#A855F7")
        static let iconTileGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.6),
                Color.white.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Mock verification status
    @State private var verificationStatus: VerificationStatus = .none

    // MARK: - User toggles
    @State private var aiSuggestions = true
    @State private var motivationTips = true
    @State private var coachRecs = true
    @State private var smartNotifs = false

    @State private var publicProfile = true
    @State private var showLocation = true
    @State private var pushNotifs = true
    @State private var emailNotifs = false
    @State private var sound = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                verificationCard
                settingsSections
                logoutButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(
            theme.colors.backgroundGradient.ignoresSafeArea()
        )
        .overlay(backgroundOrbs)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        // iOS 16+ typed navigation destinations
        .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
            case .editProfile:
                EditProfileView()
                    .environmentObject(theme)
                    .toolbar(.hidden, for: .tabBar)
            case .changePassword:
                ChangePasswordView()
                    .environmentObject(theme)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
    }

    // MARK: - Verification Card
    private var verificationCard: some View {
        Group {
            switch verificationStatus {
            case .none:
                InfoCardView(
                    color: Color(hex: "3498DB"),
                    title: "Become a Verified Coach",
                    description: "Get verified to host paid sessions and build trust",
                    buttonTitle: "Apply Now",
                    buttonAction: onApplyVerification
                )
            case .pending:
                InfoCardView(
                    color: .yellow,
                    title: "Verification Pending",
                    description: "We're reviewing your application. This typically takes 2–3 business days.",
                    badgeText: "Under Review",
                    badgeColor: .yellow.opacity(0.8)
                )
            case .approved:
                InfoCardView(
                    color: Color(hex: "2ECC71"),
                    title: "Verified Coach",
                    description: "You can now create paid sessions and access coach features",
                    badgeText: "✓ Verified",
                    badgeColor: Color(hex: "2ECC71")
                )
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Settings Sections
    private var settingsSections: some View {
        VStack(spacing: 20) {
            SettingsSectionView(title: "Appearance", items: [
                .toggle("Night Mode", Binding(
                    get: { theme.isDarkMode },
                    set: { theme.isDarkMode = $0 }
                ), systemIcon: "moon.fill")
            ])

            SettingsSectionView(title: "Account", items: [
                .routeNavigate("Edit Profile", systemIcon: "person", extra: nil, route: .editProfile),
                .routeNavigate("Change Password", systemIcon: "lock", extra: nil, route: .changePassword)
            ])

            SettingsSectionView(title: "AI Preferences", items: [
                .toggle("AI Suggestions", $aiSuggestions, systemIcon: "sparkles"),
                .toggle("Motivation Tips", $motivationTips, systemIcon: "sparkles"),
                .toggle("Coach Recommendations", $coachRecs, systemIcon: "sparkles"),
                .toggle("Smart Notifications", $smartNotifs, systemIcon: "sparkles")
            ])

            SettingsSectionView(title: "Privacy", items: [
                .toggle("Public Profile", $publicProfile, systemIcon: "shield"),
                .toggle("Show Location", $showLocation, systemIcon: "shield"),
                .navigate("Blocked Users", systemIcon: "person.fill.xmark")
            ])

            SettingsSectionView(title: "Notifications", items: [
                .toggle("Push Notifications", $pushNotifs, systemIcon: "bell.fill"),
                .toggle("Email Notifications", $emailNotifs, systemIcon: "envelope"),
                .toggle("Sound", $sound, systemIcon: "speaker.wave.2.fill")
            ])

            SettingsSectionView(title: "App Info", items: [
                .navigate("Terms of Service", systemIcon: "info.circle"),
                .navigate("Privacy Policy", systemIcon: "info.circle"),
                .navigate("Contact Support", systemIcon: "info.circle"),
                .navigate("About", systemIcon: "info.circle", extra: "v1.0.0")
            ])
        }
    }

    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: { onLogout?() }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                Text("Log Out")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                LinearGradient(colors: [
                    Color.red, Color.pink
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(30)
            .shadow(color: .pink.opacity(0.4), radius: 10, y: 4)
        }
        .padding(.top, 10)
    }

    // MARK: - Background Gradient (kept for reference)
    private var backgroundGradient: LinearGradient {
        theme.colors.backgroundGradient
    }

    // MARK: - Floating Orbs
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 160, height: 160)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
                .opacity(0.8)
            Circle()
                .fill(LinearGradient(colors: [.blue.opacity(0.25), .purple.opacity(0.3)],
                                     startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 220, height: 220)
                .blur(radius: 80)
                .offset(x: 100, y: 300)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            onBack: {},
            onApplyVerification: {},
            onLogout: {}
        )
        .environmentObject(Theme())
    }
}

// MARK: - VerificationStatus Enum
enum VerificationStatus {
    case none, pending, approved
}

// MARK: - Routing for SettingsView
enum SettingsRoute: Hashable {
    case editProfile
    case changePassword
}

// MARK: - Info Card
private struct InfoCardView: View {
    @EnvironmentObject private var theme: Theme

    var color: Color
    var title: String
    var description: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    var badgeText: String? = nil
    var badgeColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "rosette")
                            .font(.system(size: 22))
                            .foregroundColor(color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        if let badgeText = badgeText {
                            Text(badgeText)
                                .font(.caption2)
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badgeColor ?? .gray.opacity(0.3))
                                .cornerRadius(6)
                        }
                    }
                    Text(description)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    if let buttonTitle = buttonTitle {
                        Button(action: { buttonAction?() }) {
                            Text(buttonTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 20)
                                .background(
                                    LinearGradient(colors: [color, color.opacity(0.8)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(color: color.opacity(0.4), radius: 5, y: 2)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(10)
        }
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

// MARK: - Settings Section
private struct SettingsSectionView: View {
    @EnvironmentObject private var theme: Theme

    let title: String
    let items: [SettingsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { i in
                    items[i]
                    if i != items.count - 1 {
                        Divider().background(theme.colors.divider)
                    }
                }
            }
            .background(theme.colors.cardBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - Item Types
enum SettingsItem: View {
    case navigate(String, systemIcon: String, extra: String? = nil, action: (() -> Void)? = nil)
    case toggle(String, Binding<Bool>, systemIcon: String)
    case routeNavigate(String, systemIcon: String, extra: String? = nil, route: SettingsRoute)

    var body: some View {
        switch self {
        case .navigate(let label, let icon, let extra, let action):
            Button(action: { action?() }) {
                Row(icon: icon) {
                    HStack {
                        Text(label)
                            .font(.subheadline)
                        Spacer()
                        if let extra = extra {
                            Text(extra)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle()) // whole row tappable
                .accessibilityAddTraits(.isButton)
            }
            .buttonStyle(.plain)

        case .toggle(let label, let binding, let icon):
            Row(icon: icon) {
                HStack {
                    Text(label)
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: binding)
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                        .labelsHidden()
                }
            }
            .padding(10)

        case .routeNavigate(let label, let icon, let extra, let route):
            NavigationLink(value: route) {
                Row(icon: icon) {
                    HStack {
                        Text(label)
                            .font(.subheadline)
                        Spacer()
                        if let extra = extra {
                            Text(extra)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
            }
            .buttonStyle(.plain)
        }
    }

    // Shared row with themed colors
    private struct Row<Content: View>: View {
        @EnvironmentObject private var theme: Theme
        let icon: String
        let content: () -> Content

        var body: some View {
            HStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(SettingsView.Palette.iconTileGradient)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(SettingsView.Palette.iconPurple)
                    )
                content()
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
    }
}
