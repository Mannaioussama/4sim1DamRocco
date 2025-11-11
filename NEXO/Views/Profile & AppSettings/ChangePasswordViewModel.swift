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
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
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
        case 0...1: return "Weak"
        case 2...3: return "Fair"
        case 4: return "Good"
        case 5: return "Strong"
        default: return "Weak"
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
        return "Security Tip"
    }
    
    var securityTipMessage: String {
        return "Use a strong password with at least 8 characters, including letters, numbers, and symbols."
    }
    
    // Requirements list
    var requirements: [(text: String, isMet: Bool)] {
        return [
            ("At least 8 characters long", meetsLengthRequirement),
            ("Include uppercase and lowercase letters", meetsUppercaseRequirement && meetsLowercaseRequirement),
            ("Include at least one number", meetsNumberRequirement),
            ("Include at least one special character", meetsSpecialCharacterRequirement)
        ]
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
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
        case "Current Password":
            currentError = ""
        case "New Password":
            newError = ""
        case "Confirm New Password":
            confirmError = ""
        default:
            break
        }
    }
    
    func validateCurrentPassword() -> Bool {
        if currentPassword.isEmpty {
            currentError = "Current password is required"
            return false
        }
        return true
    }
    
    func validateNewPassword() -> Bool {
        if newPassword.isEmpty {
            newError = "New password is required"
            return false
        }
        
        if newPassword.count < 8 {
            newError = "Password must be at least 8 characters"
            return false
        }
        
        if !validatePasswordStrength(newPassword) {
            newError = "Password does not meet requirements"
            return false
        }
        
        if currentPassword == newPassword {
            newError = "New password must be different from current password"
            return false
        }
        
        return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPassword.isEmpty {
            confirmError = "Please confirm your password"
            return false
        }
        
        if newPassword != confirmPassword {
            confirmError = "Passwords do not match"
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
        guard validateAll() else {
            return
        }
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Simulate success (replace with actual API call)
            let success = true
            
            if success {
                self.alertMessage = "Password changed successfully!"
                self.showSuccessAlert = true
                self.isLoading = false
                
                // Clear fields
                self.clearAllFields()
                
                onSuccess()
            } else {
                self.alertMessage = "Failed to change password. Please try again."
                self.showErrorAlert = true
                self.isLoading = false
                
                onError(self.alertMessage)
            }
        }
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
