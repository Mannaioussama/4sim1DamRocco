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
    var onOpenPremium: (() -> Void)?

    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLanguagePicker = false

    // MARK: - Local Palette
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

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    verificationCard
                    settingsSections
                    logoutButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(theme.colors.backgroundGradient.ignoresSafeArea())
            .overlay(backgroundOrbs)
            
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationTitle(viewModel.localized("settings.title.dashboard"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(viewModel.localized("settings.alert.logout.title"), isPresented: $viewModel.showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelLogout()
            }
            Button("Logout", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text(viewModel.localized("settings.alert.logout.message"))
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguageSheetView(
                selectedLanguage: viewModel.selectedLanguage,
                onSelect: { language in
                    viewModel.setLanguage(language)
                    showingLanguagePicker = false
                },
                onCancel: {
                    showingLanguagePicker = false
                }
            )
            .environmentObject(theme)
        }
        .onAppear {
            viewModel.trackScreenView()
            viewModel.loadSettings()
            Task { await viewModel.loadVerificationStatus() }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text(viewModel.localized("settings.loading_message"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }

    // MARK: - Verification Card
    
    private var verificationCard: some View {
        let data = viewModel.verificationCardData
        return InfoCardView(
            color: data.color,
            title: data.title,
            description: data.description,
            buttonTitle: data.buttonTitle,
            buttonAction: handleVerificationAction,
            badgeText: data.badgeText,
            badgeColor: data.badgeColor
        )
        .padding(.top, 10)
    }

    // MARK: - Settings Sections
    
    private var settingsSections: some View {
        VStack(spacing: 20) {
            SettingsSectionView(title: viewModel.premiumSectionTitle, items: [
                .navigate(viewModel.localized("settings.row.premium_subscription"), systemIcon: "star.fill", extra: nil, action: {
                    viewModel.openPremiumSubscription()
                    onOpenPremium?()
                })
            ])

            SettingsSectionView(title: viewModel.appearanceSectionTitle, items: [
                .toggle(viewModel.localized("settings.row.night_mode"), Binding(
                    get: { theme.isDarkMode },
                    set: { theme.isDarkMode = $0 }
                ), systemIcon: "moon.fill")
            ])

            SettingsSectionView(title: viewModel.languageSectionTitle, items: [
                .navigate(viewModel.localized("settings.row.language"), systemIcon: "globe", extra: viewModel.currentLanguageLabel, action: {
                    showingLanguagePicker = true
                    viewModel.trackNavigationTo("Language")
                })
            ])

            SettingsSectionView(title: viewModel.accountSectionTitle, items: [
                .destination(
                    viewModel.localized("settings.row.edit_profile"),
                    systemIcon: "person",
                    extra: viewModel.hasUnverifiedEmail ? "__unverified__" : nil,
                    destination: AnyView(
                        EditProfileView()
                            .environmentObject(theme)
                            .toolbar(.hidden, for: .tabBar)
                    )
                ),
                .destination(
                    viewModel.localized("settings.row.change_password"),
                    systemIcon: "lock",
                    extra: nil,
                    destination: AnyView(
                        ChangePasswordView()
                            .environmentObject(theme)
                            .toolbar(.hidden, for: .tabBar)
                    )
                )
            ])

            SettingsSectionView(title: viewModel.aiPreferencesSectionTitle, items: [
                .toggle(viewModel.localized("settings.row.ai_suggestions"), $viewModel.aiSuggestions, systemIcon: "sparkles"),
                .toggle(viewModel.localized("settings.row.motivation_tips"), $viewModel.motivationTips, systemIcon: "sparkles"),
                .toggle(viewModel.localized("settings.row.coach_recommendations"), $viewModel.coachRecs, systemIcon: "sparkles"),
                .toggle(viewModel.localized("settings.row.smart_notifications"), $viewModel.smartNotifs, systemIcon: "sparkles")
            ])

            SettingsSectionView(title: viewModel.privacySectionTitle, items: [
                .toggle(viewModel.localized("settings.row.public_profile"), $viewModel.publicProfile, systemIcon: "shield"),
                .toggle(viewModel.localized("settings.row.show_location"), $viewModel.showLocation, systemIcon: "shield"),
                .navigate(viewModel.localized("settings.row.blocked_users"), systemIcon: "person.fill.xmark", action: {
                    viewModel.openBlockedUsers()
                    viewModel.trackNavigationTo("Blocked Users")
                })
            ])

            SettingsSectionView(title: viewModel.notificationsSectionTitle, items: [
                .toggle(viewModel.localized("settings.row.push_notifications"), $viewModel.pushNotifs, systemIcon: "bell.fill"),
                .toggle(viewModel.localized("settings.row.email_notifications"), $viewModel.emailNotifs, systemIcon: "envelope"),
                .toggle(viewModel.localized("settings.row.sound"), $viewModel.sound, systemIcon: "speaker.wave.2.fill")
            ])

            SettingsSectionView(title: viewModel.appInfoSectionTitle, items: [
                .navigate(viewModel.localized("settings.row.terms"), systemIcon: "info.circle", action: {
                    viewModel.openTermsOfService()
                    viewModel.trackNavigationTo("Terms of Service")
                }),
                .navigate(viewModel.localized("settings.row.privacy_policy"), systemIcon: "info.circle", action: {
                    viewModel.openPrivacyPolicy()
                    viewModel.trackNavigationTo("Privacy Policy")
                }),
                .navigate(viewModel.localized("settings.row.contact_support"), systemIcon: "info.circle", action: {
                    viewModel.openContactSupport()
                    viewModel.trackNavigationTo("Contact Support")
                }),
                .navigate(viewModel.localized("settings.row.about"), systemIcon: "info.circle", extra: viewModel.appVersion, action: {
                    viewModel.openAbout()
                    viewModel.trackNavigationTo("About")
                })
            ])
        }
    }

    // MARK: - Logout Button
    
    private var logoutButton: some View {
        Button(action: {
            viewModel.showLogoutDialog()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                Text(viewModel.localized("settings.button.logout"))
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
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
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
    
    // MARK: - Actions
    
    private func handleVerificationAction() {
        viewModel.applyForVerification(
            onSuccess: {
                viewModel.trackVerificationApplied()
                onApplyVerification?()
            },
            onError: { _ in }
        )
    }
    
    private func handleLogout() {
        viewModel.confirmLogout(
            onSuccess: {
                viewModel.trackLogout()
                onLogout?()
            },
            onError: { _ in }
        )
    }
}

// MARK: - Language Sheet
private struct LanguageSheetView: View {
    @EnvironmentObject private var theme: Theme
    let selectedLanguage: AppLanguage
    let onSelect: (AppLanguage) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("Language")
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.top, 4)

            VStack(spacing: 10) {
                languageButton(title: "English", language: .english)
                languageButton(title: "Français", language: .french)
                languageButton(title: "العربية", language: .arabic)
            }
            .padding(.vertical, 8)

            Button(role: .cancel) {
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.gray.opacity(0.3))
            .foregroundColor(theme.colors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(theme.colors.backgroundGradient.ignoresSafeArea())
    }

    private func languageButton(title: String, language: AppLanguage) -> some View {
        Button {
            onSelect(language)
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                if language == selectedLanguage {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "8B5CF6"))
                }
            }
            .padding()
            .background(theme.colors.cardBackground)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
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
    case destination(String, systemIcon: String, extra: String? = nil, destination: AnyView)

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
                            if extra == "__unverified__" {
                                PulsingDot(color: Color(hex: "F39C12"))
                            } else {
                                Text(extra)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
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

        case .destination(let label, let icon, let extra, let destinationView):
            NavigationLink {
                destinationView
            } label: {
                Row(icon: icon) {
                    HStack {
                        Text(label)
                            .font(.subheadline)
                        Spacer()
                        if let extra = extra {
                            if extra == "__unverified__" {
                                PulsingDot(color: Color(hex: "F39C12"))
                            } else {
                                Text(extra)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityAddTraits(.isButton)
            }
            .buttonStyle(.plain)
        }
    }

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

// MARK: - Pulsing Dot
private struct PulsingDot: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 10, height: 10)
                .scaleEffect(animate ? 1.6 : 1.0)
                .opacity(animate ? 0.0 : 0.7)

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
        .accessibilityLabel("Email not verified")
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            onBack: {},
            onApplyVerification: {},
            onLogout: {},
            onOpenPremium: {}
        )
        .environmentObject(Theme())
    }
}
