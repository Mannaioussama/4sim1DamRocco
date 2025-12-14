//
//  ChangePasswordViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import Combine

class ChangePasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Form fields
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    // Visibility toggles
    @Published var showCurrent: Bool = false
    @Published var showNew: Bool = false
    @Published var showConfirm: Bool = false
    
    // Errors
    @Published var currentError: String = ""
    @Published var newError: String = ""
    @Published var confirmError: String = ""
    
    // States
    @Published var isLoading: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var alertMessage: String = ""
    
    // MARK: - Dependencies
    
    private let profileAPI = ProfileAPI.shared
    private let tokenStore = KeychainTokenStore.shared
    private let authStore = AuthStore.shared
    
    // Cache user id for this screen (helps after app relaunch)
    private var cachedUserId: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let localizationManager = LocalizationManager.shared
    
    // MARK: - Computed Properties
    
    var hasCurrentPassword: Bool {
        return !currentPassword.isEmpty
    }
    
    var hasNewPassword: Bool {
        return !newPassword.isEmpty
    }
    
    var hasConfirmPassword: Bool {
        return !confirmPassword.isEmpty
    }
    
    var passwordsMatch: Bool {
        return newPassword == confirmPassword && !newPassword.isEmpty
    }
    
    var isNewPasswordValid: Bool {
        return validatePasswordStrength(newPassword)
    }
    
    var hasAnyError: Bool {
        return !currentError.isEmpty || !newError.isEmpty || !confirmError.isEmpty
    }
    
    var canSave: Bool {
        return hasCurrentPassword && hasNewPassword && hasConfirmPassword && !hasAnyError
    }
    
    // Password requirements status
    var meetsLengthRequirement: Bool {
        return newPassword.count >= 8
    }
    
    var meetsUppercaseRequirement: Bool {
        return newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    var meetsLowercaseRequirement: Bool {
        return newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil
    }
    
    var meetsNumberRequirement: Bool {
        return newPassword.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    var meetsSpecialCharacterRequirement: Bool {
        let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        return newPassword.rangeOfCharacter(from: specialCharacterSet) != nil
    }
    
    var allRequirementsMet: Bool {
        return meetsLengthRequirement &&
               meetsUppercaseRequirement &&
               meetsLowercaseRequirement &&
               meetsNumberRequirement &&
               meetsSpecialCharacterRequirement
    }
    
    var passwordStrengthScore: Int {
        var score = 0
        if meetsLengthRequirement { score += 1 }
        if meetsUppercaseRequirement { score += 1 }
        if meetsLowercaseRequirement { score += 1 }
        if meetsNumberRequirement { score += 1 }
        if meetsSpecialCharacterRequirement { score += 1 }
        return score
    }
    
    var passwordStrengthText: String {
        switch passwordStrengthScore {
        case 0...1: return localizationManager.localized("password.strength.weak")
        case 2...3: return localizationManager.localized("password.strength.fair")
        case 4: return localizationManager.localized("password.strength.good")
        case 5: return localizationManager.localized("password.strength.strong")
        default: return localizationManager.localized("password.strength.weak")
        }
    }
    
    var passwordStrengthColor: String {
        switch passwordStrengthScore {
        case 0...1: return "EF4444" // Red
        case 2...3: return "F59E0B" // Orange
        case 4: return "10B981" // Green
        case 5: return "059669" // Dark Green
        default: return "EF4444"
        }
    }
    
    // Security tip
    var securityTipTitle: String {
        return localizationManager.localized("password.security.tipTitle")
    }
    
    var securityTipMessage: String {
        return localizationManager.localized("password.security.tipMessage")
    }
    
    // Requirements list
    var requirements: [(text: String, isMet: Bool)] {
        return [
            (localizationManager.localized("password.requirements.length"), meetsLengthRequirement),
            (localizationManager.localized("password.requirements.letters"), meetsUppercaseRequirement && meetsLowercaseRequirement),
            (localizationManager.localized("password.requirements.number"), meetsNumberRequirement),
            (localizationManager.localized("password.requirements.special"), meetsSpecialCharacterRequirement)
        ]
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        // Try to cache user id early (works after relaunch too)
        Task { @MainActor in
            await bootstrapUserId()
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Clear errors when typing
        $currentPassword
            .sink { [weak self] _ in
                self?.currentError = ""
            }
            .store(in: &cancellables)
        
        $newPassword
            .sink { [weak self] _ in
                self?.newError = ""
            }
            .store(in: &cancellables)
        
        $confirmPassword
            .sink { [weak self] _ in
                self?.confirmError = ""
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Visibility Toggle
    
    func toggleCurrentPasswordVisibility() {
        showCurrent.toggle()
    }
    
    func toggleNewPasswordVisibility() {
        showNew.toggle()
    }
    
    func toggleConfirmPasswordVisibility() {
        showConfirm.toggle()
    }
    
    // MARK: - Validation
    
    func clearError(for field: String) {
        switch field {
        case localizationManager.localized("password.field.current"):
            currentError = ""
        case localizationManager.localized("password.field.new"):
            newError = ""
        case localizationManager.localized("password.field.confirm"):
            confirmError = ""
        default:
            break
        }
    }
    
    func validateCurrentPassword() -> Bool {
        if currentPassword.isEmpty {
            currentError = localizationManager.localized("password.error.currentRequired")
            return false
        }
        return true
    }
    
    func validateNewPassword() -> Bool {
        if newPassword.isEmpty {
            newError = localizationManager.localized("password.error.newRequired")
            return false
        }
        
        if newPassword.count < 8 {
            newError = localizationManager.localized("password.error.minLength")
            return false
        }
        
        if !validatePasswordStrength(newPassword) {
            newError = localizationManager.localized("password.error.notStrongEnough")
            return false
        }
        
        if currentPassword == newPassword {
            newError = localizationManager.localized("password.error.sameAsCurrent")
            return false
        }
        
        return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPassword.isEmpty {
            confirmError = localizationManager.localized("password.error.confirmRequired")
            return false
        }
        
        if newPassword != confirmPassword {
            confirmError = localizationManager.localized("password.error.mismatch")
            return false
        }
        
        return true
    }
    
    func validateAll() -> Bool {
        let isCurrentValid = validateCurrentPassword()
        let isNewValid = validateNewPassword()
        let isConfirmValid = validateConfirmPassword()
        
        return isCurrentValid && isNewValid && isConfirmValid
    }
    
    private func validatePasswordStrength(_ password: String) -> Bool {
        return allRequirementsMet
    }
    
    // MARK: - Save Action
    
    func savePassword(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        guard validateAll() else { return }
        
        guard let token = tokenStore.getAccessToken() else {
            alertMessage = localizationManager.localized("password.error.notAuthenticated")
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                let userId = try await getUserId(using: token)
                
                let req = ChangePasswordRequest(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                let message = try await profileAPI.changePassword(
                    userId: userId,
                    token: token,
                    request: req
                )
                
                self.alertMessage = message
                self.showSuccessAlert = true
                self.isLoading = false
                
                // Clear fields
                self.clearAllFields()
                
                onSuccess()
            } catch let apiErr as APIError {
                let msg = apiErr.userMessage
                self.alertMessage = msg
                if msg.localizedCaseInsensitiveContains("current password") ||
                    msg.localizedCaseInsensitiveContains("incorrect") {
                    self.currentError = msg
                } else if msg.localizedCaseInsensitiveContains("password") {
                    self.newError = msg
                }
                self.showErrorAlert = true
                self.isLoading = false
                onError(msg)
            } catch {
                self.alertMessage = error.localizedDescription
                self.showErrorAlert = true
                self.isLoading = false
                onError(self.alertMessage)
            }
        }
    }
    
    // MARK: - User ID bootstrap / fetch
    
    @MainActor
    private func bootstrapUserId() async {
        if let id = authStore.currentUser?.id, !id.isEmpty {
            cachedUserId = id
            return
        }
        guard let token = tokenStore.getAccessToken() else { return }
        do {
            let profile = try await profileAPI.getProfile(token: token)
            cachedUserId = profile.id
        } catch {
            // Don’t show an alert here; we’ll handle it on save if needed.
            print("ChangePassword: failed to prefetch user id: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func getUserId(using token: String) async throws -> String {
        if let id = cachedUserId, !id.isEmpty { return id }
        if let id = authStore.currentUser?.id, !id.isEmpty {
            cachedUserId = id
            return id
        }
        // Fallback: fetch /users/profile
        let profile = try await profileAPI.getProfile(token: token)
        cachedUserId = profile.id
        return profile.id
    }
    
    // MARK: - Helper Methods
    
    func clearAllFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        currentError = ""
        newError = ""
        confirmError = ""
        showCurrent = false
        showNew = false
        showConfirm = false
    }
    
    func clearAllErrors() {
        currentError = ""
        newError = ""
        confirmError = ""
    }
    
    func getFieldTitle(for field: String) -> String {
        return field
    }
    
    func getFieldPlaceholder(for field: String) -> String {
        return "••••••••"
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Change password screen viewed")
    }
    
    func trackPasswordChanged() {
        // TODO: Implement analytics tracking
        print("Password changed successfully")
    }
    
    func trackPasswordChangeFailed(error: String) {
        // TODO: Implement analytics tracking
        print("Password change failed: \(error)")
    }
    
    func trackFieldFocused(_ field: String) {
        // TODO: Implement analytics tracking
        print("Field focused: \(field)")
    }
    
    func trackVisibilityToggled(_ field: String, visible: Bool) {
        // TODO: Implement analytics tracking
        print("Visibility toggled for \(field): \(visible)")
    }
}

