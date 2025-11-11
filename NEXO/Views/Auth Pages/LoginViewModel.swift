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
                try await authStore.login(email: email, password: password)
                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                apiError = (error as? APIError)?.userMessage ?? "Login failed. Please try again."
            }
        }
    }
}
