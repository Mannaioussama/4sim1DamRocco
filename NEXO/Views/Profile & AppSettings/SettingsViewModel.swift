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
    @Published var selectedLanguage: AppLanguage = .english
    
    // States
    @Published var isLoading: Bool = false
    @Published var showLogoutConfirmation: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let profileAPI = ProfileAPI.shared
    private let tokenManager = AuthTokenManager.shared
    private let translations: [AppLanguage: [String: String]] = [
        .english: [
            "settings.title.dashboard": "Dashboard",
            "settings.loading_message": "Please wait...",
            "settings.alert.logout.title": "Logout",
            "settings.alert.logout.message": "Are you sure you want to log out?",
            "settings.section.premium": "Premium",
            "settings.section.appearance": "Appearance",
            "settings.section.language": "Language",
            "settings.section.account": "Account",
            "settings.section.ai": "AI Preferences",
            "settings.section.privacy": "Privacy",
            "settings.section.notifications": "Notifications",
            "settings.section.appinfo": "App Info",
            "settings.row.premium_subscription": "Premium Subscription",
            "settings.row.night_mode": "Night Mode",
            "settings.row.language": "Language",
            "settings.row.edit_profile": "Edit Profile",
            "settings.row.change_password": "Change Password",
            "settings.row.ai_suggestions": "AI Suggestions",
            "settings.row.motivation_tips": "Motivation Tips",
            "settings.row.coach_recommendations": "Coach Recommendations",
            "settings.row.smart_notifications": "Smart Notifications",
            "settings.row.public_profile": "Public Profile",
            "settings.row.show_location": "Show Location",
            "settings.row.blocked_users": "Blocked Users",
            "settings.row.push_notifications": "Push Notifications",
            "settings.row.email_notifications": "Email Notifications",
            "settings.row.sound": "Sound",
            "settings.row.terms": "Terms of Service",
            "settings.row.privacy_policy": "Privacy Policy",
            "settings.row.contact_support": "Contact Support",
            "settings.row.about": "About",
            "settings.button.logout": "Log Out"
        ],
        .french: [
            "settings.title.dashboard": "Tableau de bord",
            "settings.loading_message": "Veuillez patienter...",
            "settings.alert.logout.title": "Déconnexion",
            "settings.alert.logout.message": "Voulez-vous vraiment vous déconnecter ?",
            "settings.section.premium": "Premium",
            "settings.section.appearance": "Apparence",
            "settings.section.language": "Langue",
            "settings.section.account": "Compte",
            "settings.section.ai": "Préférences IA",
            "settings.section.privacy": "Confidentialité",
            "settings.section.notifications": "Notifications",
            "settings.section.appinfo": "Infos sur l'app",
            "settings.row.premium_subscription": "Abonnement Premium",
            "settings.row.night_mode": "Mode nuit",
            "settings.row.language": "Langue",
            "settings.row.edit_profile": "Modifier le profil",
            "settings.row.change_password": "Changer le mot de passe",
            "settings.row.ai_suggestions": "Suggestions IA",
            "settings.row.motivation_tips": "Conseils de motivation",
            "settings.row.coach_recommendations": "Recommandations du coach",
            "settings.row.smart_notifications": "Notifications intelligentes",
            "settings.row.public_profile": "Profil public",
            "settings.row.show_location": "Afficher la position",
            "settings.row.blocked_users": "Utilisateurs bloqués",
            "settings.row.push_notifications": "Notifications push",
            "settings.row.email_notifications": "Notifications e-mail",
            "settings.row.sound": "Son",
            "settings.row.terms": "Conditions d'utilisation",
            "settings.row.privacy_policy": "Politique de confidentialité",
            "settings.row.contact_support": "Contacter le support",
            "settings.row.about": "À propos",
            "settings.button.logout": "Se déconnecter"
        ],
        .arabic: [
            "settings.title.dashboard": "لوحة التحكم",
            "settings.loading_message": "الرجاء الانتظار...",
            "settings.alert.logout.title": "تسجيل الخروج",
            "settings.alert.logout.message": "هل أنت متأكد أنك تريد تسجيل الخروج؟",
            "settings.section.premium": "بريميوم",
            "settings.section.appearance": "المظهر",
            "settings.section.language": "اللغة",
            "settings.section.account": "الحساب",
            "settings.section.ai": "تفضيلات الذكاء الاصطناعي",
            "settings.section.privacy": "الخصوصية",
            "settings.section.notifications": "الإشعارات",
            "settings.section.appinfo": "معلومات التطبيق",
            "settings.row.premium_subscription": "اشتراك بريميوم",
            "settings.row.night_mode": "الوضع الليلي",
            "settings.row.language": "اللغة",
            "settings.row.edit_profile": "تعديل الملف الشخصي",
            "settings.row.change_password": "تغيير كلمة المرور",
            "settings.row.ai_suggestions": "اقتراحات الذكاء الاصطناعي",
            "settings.row.motivation_tips": "نصائح تحفيزية",
            "settings.row.coach_recommendations": "توصيات المدرب",
            "settings.row.smart_notifications": "إشعارات ذكية",
            "settings.row.public_profile": "الملف الشخصي العام",
            "settings.row.show_location": "إظهار الموقع",
            "settings.row.blocked_users": "المستخدمون المحظورون",
            "settings.row.push_notifications": "إشعارات الدفع",
            "settings.row.email_notifications": "إشعارات البريد الإلكتروني",
            "settings.row.sound": "الصوت",
            "settings.row.terms": "شروط الخدمة",
            "settings.row.privacy_policy": "سياسة الخصوصية",
            "settings.row.contact_support": "اتصل بالدعم",
            "settings.row.about": "حول",
            "settings.button.logout": "تسجيل الخروج"
        ]
    ]
    
    // MARK: - Computed Properties
    
    func localized(_ key: String) -> String {
        translations[selectedLanguage]?[key]
        ?? translations[.english]?[key]
        ?? key
    }
    
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
                buttonTitle: "Check Status",
                buttonAction: nil,
                badgeText: "✓ Verified",
                badgeColor: Color(hex: "2ECC71")
            )
        }
    }
    
    // MARK: - Section Headers
    
    var premiumSectionTitle: String { localized("settings.section.premium") }
    var appearanceSectionTitle: String { localized("settings.section.appearance") }
    var languageSectionTitle: String { localized("settings.section.language") }
    var accountSectionTitle: String { localized("settings.section.account") }
    var aiPreferencesSectionTitle: String { localized("settings.section.ai") }
    var privacySectionTitle: String { localized("settings.section.privacy") }
    var notificationsSectionTitle: String { localized("settings.section.notifications") }
    var appInfoSectionTitle: String { localized("settings.section.appinfo") }
    var currentLanguageLabel: String {
        switch selectedLanguage {
        case .english:
            return "English"
        case .french:
            return "Français"
        case .arabic:
            return "العربية"
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        loadSavedLanguage()
        Task { await loadVerificationStatus() }
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
        // This method now just triggers navigation to the coach onboarding screen.
        // The real status is driven by the backend isCoachVerified flag.
        trackVerificationApplied()
        onSuccess()
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
    
    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        LocalizationManager.shared.setLanguage(language)
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
    }
    
    private func loadSavedLanguage() {
        if let stored = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: stored) {
            selectedLanguage = language
        } else {
            selectedLanguage = LocalizationManager.shared.language
        }
    }
    
    // MARK: - Verification Status (Backend)
    
    @MainActor
    func loadVerificationStatus() async {
        guard let token = tokenManager.getToken() else { return }
        do {
            let profile = try await profileAPI.getProfile(token: token)
            verificationStatus = (profile.isCoachVerified ?? false) ? .approved : .none
            // Keep the Edit Profile orange dot in sync with real email verification state.
            // When the backend marks isEmailVerified = true, this will flip emailVerified
            // and SettingsView will stop showing the pulsing dot.
            emailVerified = profile.isEmailVerified
        } catch {
            print("Failed to load verification status: \(error)")
        }
    }
    
    // MARK: - Navigation Actions
    
    func openPremiumSubscription() {
        // TODO: Navigate to premium subscription screen
        print("Opening premium subscription")
        trackNavigationTo("Premium Subscription")
    }
    
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
