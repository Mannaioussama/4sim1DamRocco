//
//  SignUpViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine

class SignUpViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Form fields
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var location: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    @Published var agreedToTerms: Bool = false
    
    // Validation state
    @Published var attemptedSubmit: Bool = false
    @Published var nameError: String? = nil
    @Published var emailError: String? = nil
    @Published var locationError: String? = nil
    @Published var passwordError: String? = nil
    @Published var confirmPasswordError: String? = nil
    @Published var termsError: String? = nil
    
    // Networking state
    @Published var isLoading: Bool = false
    @Published var apiError: String? = nil
    
    // Location search
    @Published var showSuggestions: Bool = false
    @Published var locationSearcher = AdminAreaSearcher()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let authStore: AuthStore
    
    // MARK: - Computed Properties
    
    var isNameValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let regex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: trimmed)
    }
    
    var isLocationValid: Bool {
        return !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isPasswordValid: Bool {
        return !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isConfirmPasswordValid: Bool {
        return confirmPassword == password && !confirmPassword.isEmpty
    }
    
    var isTermsValid: Bool {
        return agreedToTerms
    }
    
    var canSubmit: Bool {
        return isNameValid && isEmailValid && isLocationValid &&
               isPasswordValid && isConfirmPasswordValid &&
               isTermsValid && !isLoading
    }
    
    var hasNameError: Bool {
        return attemptedSubmit && nameError != nil
    }
    
    var hasEmailError: Bool {
        return attemptedSubmit && emailError != nil
    }
    
    var hasLocationError: Bool {
        return attemptedSubmit && locationError != nil
    }
    
    var hasPasswordError: Bool {
        return attemptedSubmit && passwordError != nil
    }
    
    var hasConfirmPasswordError: Bool {
        return attemptedSubmit && confirmPasswordError != nil
    }
    
    var hasTermsError: Bool {
        return attemptedSubmit && termsError != nil
    }
    
    var hasApiError: Bool {
        return apiError != nil
    }
    
    var hasLocationSuggestions: Bool {
        return !locationSearcher.suggestions.isEmpty
    }
    
    // MARK: - Initialization
    
    init(authStore: AuthStore) {
        self.authStore = authStore
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Clear errors when typing
        $name
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.attemptedSubmit {
                    self.validateName()
                }
                self.apiError = nil
            }
            .store(in: &cancellables)
        
        $email
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.attemptedSubmit {
                    self.validateEmail()
                }
                self.apiError = nil
            }
            .store(in: &cancellables)
        
        $location
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.showSuggestions = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
                self.locationSearcher.search(prefix: newValue)
                if self.attemptedSubmit {
                    self.validateLocation()
                }
                self.apiError = nil
            }
            .store(in: &cancellables)
        
        $password
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.attemptedSubmit {
                    self.validatePassword()
                    self.validateConfirmPassword()
                }
                self.apiError = nil
            }
            .store(in: &cancellables)
        
        $confirmPassword
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.attemptedSubmit {
                    self.validateConfirmPassword()
                }
                self.apiError = nil
            }
            .store(in: &cancellables)
        
        $agreedToTerms
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.attemptedSubmit {
                    self.validateTerms()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    func validateName() -> Bool {
        if !isNameValid {
            nameError = "Please enter your name"
            return false
        }
        nameError = nil
        return true
    }
    
    func validateEmail() -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Email is required"
            return false
        }
        if !isEmailValid {
            emailError = "Please enter a valid email address"
            return false
        }
        emailError = nil
        return true
    }
    
    func validateLocation() -> Bool {
        if !isLocationValid {
            locationError = "Please select your state/province"
            return false
        }
        locationError = nil
        return true
    }
    
    func validatePassword() -> Bool {
        if !isPasswordValid {
            passwordError = "Please enter a password"
            return false
        }
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            return false
        }
        passwordError = nil
        return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
            return false
        }
        if !isConfirmPasswordValid {
            confirmPasswordError = "Passwords do not match"
            return false
        }
        confirmPasswordError = nil
        return true
    }
    
    func validateTerms() -> Bool {
        if !isTermsValid {
            termsError = "Please agree to the Terms of Service"
            return false
        }
        termsError = nil
        return true
    }
    
    func validateAll() {
        validateName()
        validateEmail()
        validateLocation()
        validatePassword()
        validateConfirmPassword()
        validateTerms()
    }
    
    // MARK: - Password Visibility
    
    func togglePasswordVisibility() {
        showPassword.toggle()
    }
    
    func toggleConfirmPasswordVisibility() {
        showConfirmPassword.toggle()
    }
    
    // MARK: - Terms
    
    func toggleTerms() {
        agreedToTerms.toggle()
        if attemptedSubmit {
            validateTerms()
        }
    }
    
    // MARK: - Location Search
    
    func selectLocation(_ suggestion: AdminAreaSuggestion) {
        location = suggestion.displayName
        showSuggestions = false
        locationSearcher.clear()
        if attemptedSubmit {
            validateLocation()
        }
    }
    
    func openLocationSuggestions() {
        if !location.isEmpty {
            showSuggestions = true
        }
    }
    
    func closeLocationSuggestions() {
        showSuggestions = false
    }
    
    // MARK: - Sign Up
    
    func handleSignUp(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        attemptedSubmit = true
        validateAll()
        
        guard canSubmit else {
            return
        }
        
        apiError = nil
        isLoading = true
        
        Task {
            do {
                try await authStore.register(
                    email: email,
                    password: password,
                    name: name,
                    location: location
                )
                
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let errorMessage = (error as? APIError)?.userMessage ?? "Sign up failed. Please try again."
                    apiError = errorMessage
                    onError(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Social Sign Up
    
    func signUpWithGoogle(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        isLoading = true
        
        // TODO: Implement Google Sign-Up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            onError("Google Sign-Up not yet implemented")
        }
    }
    
    func signUpWithFacebook(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        isLoading = true
        
        // TODO: Implement Facebook Sign-Up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            onError("Facebook Sign-Up not yet implemented")
        }
    }
    
    // MARK: - Helper Methods
    
    func clearErrors() {
        nameError = nil
        emailError = nil
        locationError = nil
        passwordError = nil
        confirmPasswordError = nil
        termsError = nil
        apiError = nil
    }
    
    func clearForm() {
        name = ""
        email = ""
        location = ""
        password = ""
        confirmPassword = ""
        showPassword = false
        showConfirmPassword = false
        agreedToTerms = false
        attemptedSubmit = false
        clearErrors()
        locationSearcher.clear()
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Sign up screen viewed")
    }
    
    func trackSignUpAttempt() {
        // TODO: Implement analytics tracking
        print("Sign up attempt for email: \(email)")
    }
    
    func trackSignUpSuccess() {
        // TODO: Implement analytics tracking
        print("Sign up successful for email: \(email)")
    }
    
    func trackSignUpFailed(error: String) {
        // TODO: Implement analytics tracking
        print("Sign up failed: \(error)")
    }
    
    func trackSocialSignUp(provider: String) {
        // TODO: Implement analytics tracking
        print("Social sign up attempt with: \(provider)")
    }
    
    func trackLoginNavigation() {
        // TODO: Implement analytics tracking
        print("Login navigation clicked")
    }
    
    func trackPasswordVisibilityToggled(field: String) {
        // TODO: Implement analytics tracking
        print("\(field) visibility toggled")
    }
    
    func trackLocationSelected(_ location: String) {
        // TODO: Implement analytics tracking
        print("Location selected: \(location)")
    }
    
    func trackTermsToggled(_ agreed: Bool) {
        // TODO: Implement analytics tracking
        print("Terms toggled: \(agreed)")
    }
}
