//
//  LoginViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var showPassword: Bool = false
    @Published var rememberMe: Bool = true
    
    // Validation state
    @Published var emailError: String? = nil
    @Published var passwordError: String? = nil
    @Published var attemptedSubmit: Bool = false
    
    // Networking state
    @Published var isLoading: Bool = false
    @Published var apiError: String? = nil
    
    // MARK: - Dependencies
    private let authStore: AuthStore
    
    // MARK: - Computed Properties
    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let regex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: trimmed)
    }
    
    var isPasswordValid: Bool {
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canSubmit: Bool {
        isEmailValid && isPasswordValid && !isLoading
    }
    
    // MARK: - Initialization
    init(authStore: AuthStore) {
        self.authStore = authStore
    }
    
    // MARK: - Methods
    func validateFields() {
        emailError = isEmailValid ? nil : "Please enter a valid email address"
        passwordError = isPasswordValid ? nil : "Password is required"
    }
    
    func submit(onSuccess: @escaping () -> Void) {
        attemptedSubmit = true
        validateFields()
        
        guard canSubmit else { return }
        
        apiError = nil
        isLoading = true
        
        Task {
            do {
                try await authStore.login(email: email, password: password, rememberMe: rememberMe)
                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                apiError = (error as? APIError)?.userMessage ?? "Login failed. Please try again."
            }
        }
    }
    
    // MARK: - Social Login Methods
    
    func loginWithGmail() {
        apiError = nil
        isLoading = true
        
        // TODO: Implement Gmail login
        // This requires backend configuration for OAuth with Google
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isLoading = false
                apiError = "Gmail login not yet implemented"
            }
        }
    }
    
    func loginWithApple() {
        apiError = nil
        isLoading = true
        
        // TODO: Implement Apple Sign In
        // This requires importing AuthenticationServices and implementing ASAuthorizationControllerDelegate
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isLoading = false
                apiError = "Apple login not yet implemented"
            }
        }
    }
}
