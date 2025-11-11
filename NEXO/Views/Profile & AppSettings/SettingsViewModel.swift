//
//  SettingsViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import Combine

// MARK: - Enums
enum VerificationStatus {
    case none, pending, approved
}

struct VerificationCardData {
    let color: Color
    let title: String
    let description: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let badgeText: String?
    let badgeColor: Color?
}

class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Verification
    @Published var verificationStatus: VerificationStatus = .none
    @Published var emailVerified: Bool = false
    
    // AI Preferences
    @Published var aiSuggestions: Bool = true
    @Published var motivationTips: Bool = true
    @Published var coachRecs: Bool = true
    @Published var smartNotifs: Bool = false
    
    // Privacy
    @Published var publicProfile: Bool = true
    @Published var showLocation: Bool = true
    
    // Notifications
    @Published var pushNotifs: Bool = true
    @Published var emailNotifs: Bool = false
    @Published var sound: Bool = true
    
    // States
    @Published var isLoading: Bool = false
    @Published var showLogoutConfirmation: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasUnverifiedEmail: Bool {
        return !emailVerified
    }
    
    var appVersion: String {
        return "v1.0.0"
    }
    
    var verificationCardData: VerificationCardData {
        switch verificationStatus {
        case .none:
            return VerificationCardData(
                color: Color(hex: "3498DB"),
                title: "Become a Verified Coach",
                description: "Get verified to host paid sessions and build trust",
                buttonTitle: "Apply Now",
                buttonAction: nil,
                badgeText: nil,
                badgeColor: nil
            )
        case .pending:
            return VerificationCardData(
                color: .yellow,
                title: "Verification Pending",
                description: "We're reviewing your application. This typically takes 2–3 business days.",
                buttonTitle: nil,
                buttonAction: nil,
                badgeText: "Under Review",
                badgeColor: .yellow.opacity(0.8)
            )
        case .approved:
            return VerificationCardData(
                color: Color(hex: "2ECC71"),
                title: "Verified Coach",
                description: "You can now create paid sessions and access coach features",
                buttonTitle: nil,
                buttonAction: nil,
                badgeText: "✓ Verified",
                badgeColor: Color(hex: "2ECC71")
            )
        }
    }
    
    // MARK: - Section Headers
    
    var appearanceSectionTitle: String { "Appearance" }
    var accountSectionTitle: String { "Account" }
    var aiPreferencesSectionTitle: String { "AI Preferences" }
    var privacySectionTitle: String { "Privacy" }
    var notificationsSectionTitle: String { "Notifications" }
    var appInfoSectionTitle: String { "App Info" }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Sync settings changes to backend
        $aiSuggestions
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("aiSuggestions", value: newValue)
            }
            .store(in: &cancellables)
        
        $motivationTips
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("motivationTips", value: newValue)
            }
            .store(in: &cancellables)
        
        $coachRecs
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("coachRecs", value: newValue)
            }
            .store(in: &cancellables)
        
        $smartNotifs
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("smartNotifs", value: newValue)
            }
            .store(in: &cancellables)
        
        $publicProfile
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("publicProfile", value: newValue)
            }
            .store(in: &cancellables)
        
        $showLocation
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("showLocation", value: newValue)
            }
            .store(in: &cancellables)
        
        $pushNotifs
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("pushNotifs", value: newValue)
            }
            .store(in: &cancellables)
        
        $emailNotifs
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("emailNotifs", value: newValue)
            }
            .store(in: &cancellables)
        
        $sound
            .dropFirst()
            .sink { [weak self] newValue in
                self?.syncSetting("sound", value: newValue)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Settings Sync
    
    private func syncSetting(_ key: String, value: Bool) {
        // TODO: Sync to backend
        print("Syncing setting: \(key) = \(value)")
    }
    
    // MARK: - AI Preferences
    
    func toggleAISuggestions() {
        aiSuggestions.toggle()
    }
    
    func toggleMotivationTips() {
        motivationTips.toggle()
    }
    
    func toggleCoachRecs() {
        coachRecs.toggle()
    }
    
    func toggleSmartNotifs() {
        smartNotifs.toggle()
    }
    
    func enableAllAIFeatures() {
        aiSuggestions = true
        motivationTips = true
        coachRecs = true
        smartNotifs = true
    }
    
    func disableAllAIFeatures() {
        aiSuggestions = false
        motivationTips = false
        coachRecs = false
        smartNotifs = false
    }
    
    // MARK: - Privacy
    
    func togglePublicProfile() {
        publicProfile.toggle()
    }
    
    func toggleShowLocation() {
        showLocation.toggle()
    }
    
    // MARK: - Notifications
    
    func togglePushNotifs() {
        pushNotifs.toggle()
    }
    
    func toggleEmailNotifs() {
        emailNotifs.toggle()
    }
    
    func toggleSound() {
        sound.toggle()
    }
    
    func enableAllNotifications() {
        pushNotifs = true
        emailNotifs = true
        sound = true
    }
    
    func disableAllNotifications() {
        pushNotifs = false
        emailNotifs = false
        sound = false
    }
    
    // MARK: - Verification
    
    func applyForVerification(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Simulate success
            self.verificationStatus = .pending
            self.isLoading = false
            onSuccess()
        }
    }
    
    // MARK: - Logout
    
    func showLogoutDialog() {
        showLogoutConfirmation = true
    }
    
    func confirmLogout(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        isLoading = true
        
        // Simulate logout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.resetSettings()
            onSuccess()
        }
    }
    
    func cancelLogout() {
        showLogoutConfirmation = false
    }
    
    // MARK: - Helper Methods
    
    func resetSettings() {
        // Reset to defaults
        aiSuggestions = true
        motivationTips = true
        coachRecs = true
        smartNotifs = false
        publicProfile = true
        showLocation = true
        pushNotifs = true
        emailNotifs = false
        sound = true
        verificationStatus = .none
        emailVerified = false
    }
    
    func loadSettings() {
        // TODO: Load from persistent storage or backend
        print("Loading user settings")
    }
    
    // MARK: - Navigation Actions
    
    func openBlockedUsers() {
        // TODO: Navigate to blocked users screen
        print("Opening blocked users")
    }
    
    func openTermsOfService() {
        // TODO: Navigate to terms screen
        print("Opening terms of service")
    }
    
    func openPrivacyPolicy() {
        // TODO: Navigate to privacy policy
        print("Opening privacy policy")
    }
    
    func openContactSupport() {
        // TODO: Navigate to contact support
        print("Opening contact support")
    }
    
    func openAbout() {
        // TODO: Navigate to about screen
        print("Opening about")
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Settings screen viewed")
    }
    
    func trackSettingChanged(_ setting: String, value: Bool) {
        // TODO: Implement analytics tracking
        print("Setting changed: \(setting) = \(value)")
    }
    
    func trackVerificationApplied() {
        // TODO: Implement analytics tracking
        print("User applied for verification")
    }
    
    func trackLogout() {
        // TODO: Implement analytics tracking
        print("User logged out")
    }
    
    func trackNavigationTo(_ screen: String) {
        // TODO: Implement analytics tracking
        print("Navigated to: \(screen)")
    }
}
