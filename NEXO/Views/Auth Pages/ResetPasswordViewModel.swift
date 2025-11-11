//
//  ResetPasswordViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

enum ResetPasswordState {
    case input
    case success
}

class ResetPasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var state: ResetPasswordState = .input
    @Published var isLoading: Bool = false
    @Published var apiError: String? = nil
    @Published var emailError: String? = nil
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let authStore: AuthStore
    
    // MARK: - Computed Properties
    
    var isInputState: Bool {
        return state == .input
    }
    
    var isSuccessState: Bool {
        return state == .success
    }
    
    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let regex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: trimmed)
    }
    
    var canSubmit: Bool {
        return isEmailValid && !isLoading
    }
    
    var hasApiError: Bool {
        return apiError != nil
    }
    
    var hasEmailError: Bool {
        return emailError != nil
    }
    
    // MARK: - Initialization
    
    init(authStore: AuthStore) {
        self.authStore = authStore
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Clear errors when typing
        $email
            .sink { [weak self] _ in
                self?.emailError = nil
                self?.apiError = nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    func validateEmail() -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Email address is required"
            return false
        }
        
        if !isEmailValid {
            emailError = "Please enter a valid email address"
            return false
        }
        
        emailError = nil
        return true
    }
    
    // MARK: - Send Reset Email
    
    func sendResetEmail(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        guard validateEmail() else {
            return
        }
        
        apiError = nil
        isLoading = true
        
        Task {
            do {
                try await authStore.forgotPassword(email: email)
                
                await MainActor.run {
                    isLoading = false
                    state = .success
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorMessage = (error as? APIError)?.userMessage ?? "Failed to send reset email. Please try again."
                    apiError = errorMessage
                    onError(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Resend Email
    
    func resendResetEmail(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        sendResetEmail(onSuccess: onSuccess, onError: onError)
    }
    
    // MARK: - Navigation
    
    func resetToInput() {
        state = .input
        email = ""
        clearErrors()
    }
    
    // MARK: - Helper Methods
    
    func clearErrors() {
        emailError = nil
        apiError = nil
    }
    
    func clearForm() {
        email = ""
        state = .input
        clearErrors()
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Reset password screen viewed")
    }
    
    func trackResetEmailSent() {
        // TODO: Implement analytics tracking
        print("Reset email sent to: \(email)")
    }
    
    func trackResetEmailFailed(error: String) {
        // TODO: Implement analytics tracking
        print("Reset email failed: \(error)")
    }
    
    func trackResendClicked() {
        // TODO: Implement analytics tracking
        print("Resend email clicked")
    }
    
    func trackBackToLoginClicked() {
        // TODO: Implement analytics tracking
        print("Back to login clicked")
    }
}
