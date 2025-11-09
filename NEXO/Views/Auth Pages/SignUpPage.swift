//
//  SignUpPage.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import MapKit
import Combine
import Foundation
import CoreLocation

struct SignUpPage: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var authStore: AuthStore

    @State private var name = ""
    @State private var email = ""
    @State private var location = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false

    // Validation state
    @State private var attemptedSubmit = false
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    @State private var locationError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    @State private var termsError: String? = nil

    // Networking state
    @State private var isLoading = false
    @State private var apiError: String? = nil

    // Location search
    @StateObject private var locationSearcher = AdminAreaSearcher()
    @State private var showSuggestions = false

    var onSignUp: () -> Void
    var onLoginClick: () -> Void

    // MARK: - Validation
    private var isNameValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let regex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: trimmed)
    }

    private var isLocationValid: Bool { !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var isPasswordValid: Bool {
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isConfirmPasswordValid: Bool { confirmPassword == password && !confirmPassword.isEmpty }

    private var isTermsValid: Bool { agreedToTerms }

    private var canSubmit: Bool {
        isNameValid && isEmailValid && isLocationValid && isPasswordValid && isConfirmPasswordValid && isTermsValid && !isLoading
    }

    private func validateAll() {
        nameError = isNameValid ? nil : "Please enter your name"
        emailError = isEmailValid ? nil : "Please enter a valid email address"
        locationError = isLocationValid ? nil : "Please select your state/province"
        passwordError = isPasswordValid ? nil : "Please enter a password"
        confirmPasswordError = isConfirmPasswordValid ? nil : "Passwords do not match"
        termsError = isTermsValid ? nil : "Please agree to the Terms of Service"
    }

    private func handleSignUp() {
        attemptedSubmit = true
        validateAll()
        guard canSubmit else { return }
        apiError = nil
        isLoading = true
        Task {
            do {
                try await authStore.register(email: email, password: password, name: name, location: location)
                isLoading = false
                onSignUp()
            } catch {
                isLoading = false
                apiError = (error as? APIError)?.userMessage ?? "Sign up failed. Please try again."
            }
        }
    }

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()

            FloatingOrb(size: 128,
                        color: LinearGradient(colors: [Color(hex: "8B5CF6").opacity(0.3),
                                                       Color(hex: "C4B5FD").opacity(0.2)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing),
                        xOffset: -140, yOffset: -250, delay: 0)

            FloatingOrb(size: 160,
                        color: LinearGradient(colors: [Color(hex: "EC4899").opacity(0.35),
                                                       Color(hex: "F9A8D4").opacity(0.2)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing),
                        xOffset: 140, yOffset: 150, delay: 1)

            FloatingOrb(size: 96,
                        color: LinearGradient(colors: [Color(hex: "0066FF").opacity(0.3),
                                                       Color(hex: "60A5FA").opacity(0.2)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing),
                        xOffset: 0, yOffset: 0, delay: 2)

            FloatingOrb(size: 80,
                        color: LinearGradient(colors: [Color(hex: "2ECC71").opacity(0.25),
                                                       Color(hex: "10B981").opacity(0.15)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing),
                        xOffset: 100, yOffset: -150, delay: 3)

            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(colors: [Color(hex: "8B5CF6").opacity(0.2),
                                                            Color.white.opacity(theme.isDarkMode ? 0.25 : 0.4),
                                                            Color(hex: "EC4899").opacity(0.2)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 90, height: 90)
                                .blur(radius: 12)

                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 24)
                                        .stroke(theme.colors.cardStroke, lineWidth: 2))
                                    .cornerRadius(24)

                                LinearGradient(colors: [Color.white.opacity(theme.isDarkMode ? 0.18 : 0.5),
                                                        Color.white.opacity(0)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .cornerRadius(24)
                                    .padding(2)

                                Image("NEXO LOGO")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            }
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: "8B5CF6").opacity(0.2), radius: 30, x: 0, y: 10)
                        }

                        VStack(spacing: 8) {
                            Text("Join NEXO")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            Text("Create your account and start connecting")
                                .font(.system(size: 14))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    .padding(.bottom, 24)

                    VStack(spacing: 0) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(LinearGradient(colors: [Color(hex: "8B5CF6").opacity(0.2),
                                                              Color(hex: "EC4899").opacity(0.2),
                                                              Color(hex: "0066FF").opacity(0.2)],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing))
                                .blur(radius: 12)
                                .opacity(0.75)
                                .padding(-4)

                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .overlay(RoundedRectangle(cornerRadius: 24)
                                        .stroke(theme.colors.cardStroke, lineWidth: 2))
                                    .cornerRadius(24)

                                VStack {
                                    LinearGradient(colors: [Color.white.opacity(theme.isDarkMode ? 0.18 : 0.6),
                                                            Color.white.opacity(0)],
                                                   startPoint: .top, endPoint: .bottom)
                                    .frame(height: 80)
                                    .cornerRadius(24, corners: [.topLeft, .topRight])
                                    Spacer()
                                }

                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Color.black.opacity(theme.isDarkMode ? 0.15 : 0.05), lineWidth: 1)

                                VStack(spacing: 12) {
                                    ValidatingInputField(label: "Full Name",
                                                         placeholder: "Your name",
                                                         text: $name,
                                                         icon: "person",
                                                         keyboardType: .default,
                                                         attemptedSubmit: $attemptedSubmit,
                                                         error: $nameError)
                                        .onChange(of: name) { _, _ in if attemptedSubmit { validateAll() } }

                                    ValidatingInputField(label: "Email",
                                                         placeholder: "your@email.com",
                                                         text: $email,
                                                         icon: "envelope",
                                                         keyboardType: .emailAddress,
                                                         attemptedSubmit: $attemptedSubmit,
                                                         error: $emailError)
                                        .onChange(of: email) { _, _ in if attemptedSubmit { validateAll() } }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Location (State/Province)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(theme.colors.textPrimary)

                                        ZStack(alignment: .top) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "mappin")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(theme.colors.textSecondary)
                                                TextField("Enter your (State/Province)", text: $location)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(theme.colors.textPrimary)
                                                    .tint(theme.colors.textPrimary)
                                                    .accentColor(theme.colors.textPrimary)
                                                    .autocapitalization(.allCharacters)
                                                    .onChange(of: location) { _, newValue in
                                                        showSuggestions = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
                                                        locationSearcher.search(prefix: newValue)
                                                        if attemptedSubmit { validateAll() }
                                                    }
                                                    .onTapGesture {
                                                        if !location.isEmpty {
                                                            showSuggestions = true
                                                        }
                                                    }
                                            }
                                            .padding(.horizontal, 12)
                                            .frame(height: 48)
                                            .background(theme.colors.cardBackground)
                                            .background(theme.colors.barMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke((attemptedSubmit && locationError != nil) ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
                                            )
                                            .cornerRadius(16)
                                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

                                            if showSuggestions && !locationSearcher.suggestions.isEmpty {
                                                VStack(spacing: 0) {
                                                    ForEach(locationSearcher.suggestions) { suggestion in
                                                        Button {
                                                            location = suggestion.displayName
                                                            showSuggestions = false
                                                            locationSearcher.clear()
                                                            if attemptedSubmit { validateAll() }
                                                        } label: {
                                                            HStack {
                                                                Image(systemName: "mappin.and.ellipse")
                                                                    .foregroundColor(theme.colors.textSecondary)
                                                                Text(suggestion.displayName)
                                                                    .foregroundColor(theme.colors.textPrimary)
                                                                    .font(.system(size: 14))
                                                                Spacer()
                                                            }
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 10)
                                                            .background(theme.colors.cardBackground.opacity(0.95))
                                                        }
                                                        .buttonStyle(.plain)

                                                        if suggestion.id != locationSearcher.suggestions.last?.id {
                                                            Divider().background(theme.colors.cardStroke.opacity(0.6))
                                                        }
                                                    }
                                                }
                                                .background(theme.colors.cardBackground.opacity(0.98))
                                                .overlay(RoundedRectangle(cornerRadius: 12)
                                                    .stroke(theme.colors.cardStroke, lineWidth: 1))
                                                .cornerRadius(12)
                                                .padding(.top, 56)
                                                .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
                                            }
                                        }

                                        if let locationError {
                                            Text(locationError)
                                                .font(.system(size: 12))
                                                .foregroundColor(.red)
                                        }
                                    }

                                    ValidatingPasswordField(label: "Password",
                                                            placeholder: "Create a password",
                                                            text: $password,
                                                            showPassword: $showPassword,
                                                            attemptedSubmit: $attemptedSubmit,
                                                            error: $passwordError)
                                        .onChange(of: password) { _, _ in if attemptedSubmit { validateAll() } }

                                    ValidatingPasswordField(label: "Confirm Password",
                                                            placeholder: "Confirm your password",
                                                            text: $confirmPassword,
                                                            showPassword: $showConfirmPassword,
                                                            attemptedSubmit: $attemptedSubmit,
                                                            error: $confirmPasswordError)
                                        .onChange(of: confirmPassword) { _, _ in if attemptedSubmit { validateAll() } }

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(alignment: .top, spacing: 8) {
                                            Button(action: {
                                                agreedToTerms.toggle()
                                                if attemptedSubmit { validateAll() }
                                            }) {
                                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(agreedToTerms ? Color(hex: "8B5CF6") : theme.colors.textSecondary)
                                            }

                                            Text("I agree to the Terms of Service and Privacy Policy")
                                                .font(.system(size: 12))
                                                .foregroundColor(theme.colors.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }

                                        if let termsError {
                                            Text(termsError)
                                                .font(.system(size: 12))
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.top, 6)

                                    if let apiError {
                                        Text(apiError)
                                            .font(.system(size: 13))
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    Button(action: handleSignUp) {
                                        HStack(spacing: 8) {
                                            if isLoading {
                                                ProgressView()
                                                    .tint(theme.colors.textPrimary)
                                            }
                                            Text("Create Account")
                                        }
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(theme.colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(
                                            LinearGradient(colors: [
                                                Color.white.opacity(theme.isDarkMode ? 0.18 : (canSubmit ? 0.7 : 0.4)),
                                                Color.white.opacity(theme.isDarkMode ? 0.12 : (canSubmit ? 0.5 : 0.3))
                                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .background(theme.colors.barMaterial)
                                        .overlay(RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.colors.cardStroke, lineWidth: 2))
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .disabled(!canSubmit)

                                    HStack(spacing: 12) {
                                        Rectangle().fill(Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4)).frame(height: 2)
                                        Text("or sign up with")
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.colors.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(theme.colors.cardBackground)
                                            .background(theme.colors.barMaterial)
                                            .overlay(RoundedRectangle(cornerRadius: 20)
                                                .stroke(theme.colors.cardStroke, lineWidth: 1))
                                            .cornerRadius(20)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        Rectangle().fill(Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4)).frame(height: 2)
                                    }
                                    .padding(.vertical, 8)

                                    VStack(spacing: 12) {
                                        Button(action: {}) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "globe").font(.system(size: 18))
                                                Text("Google").font(.system(size: 15, weight: .medium))
                                            }
                                            .foregroundColor(theme.colors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(
                                                LinearGradient(colors: [Color.white.opacity(theme.isDarkMode ? 0.18 : 0.7),
                                                                         Color.white.opacity(theme.isDarkMode ? 0.12 : 0.5)],
                                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                            .background(theme.colors.barMaterial)
                                            .overlay(RoundedRectangle(cornerRadius: 16)
                                                .stroke(theme.colors.cardStroke, lineWidth: 2))
                                            .cornerRadius(16)
                                            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                        }
                                        .buttonStyle(ScaleButtonStyle())

                                        Button(action: {}) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "f.circle.fill").font(.system(size: 18))
                                                Text("Facebook").font(.system(size: 15, weight: .medium))
                                            }
                                            .foregroundColor(theme.colors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(
                                                LinearGradient(colors: [Color.white.opacity(theme.isDarkMode ? 0.18 : 0.7),
                                                                         Color.white.opacity(theme.isDarkMode ? 0.12 : 0.5)],
                                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                            .background(theme.colors.barMaterial)
                                            .overlay(RoundedRectangle(cornerRadius: 16)
                                                .stroke(theme.colors.cardStroke, lineWidth: 2))
                                            .cornerRadius(16)
                                            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(24)
                            }
                        }
                        .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                        Button(action: onLoginClick) {
                            Text("Sign In")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
    }
}

// MARK: - Input Fields

private struct ValidatingInputField: View {
    @EnvironmentObject private var theme: Theme
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    @Binding var attemptedSubmit: Bool
    @Binding var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.colors.textSecondary)
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .foregroundColor(theme.colors.textPrimary)
                    .tint(theme.colors.textPrimary)
                    .accentColor(theme.colors.textPrimary)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled()
                    .keyboardType(keyboardType)
                    .textContentType(keyboardType == .emailAddress ? .emailAddress : .name)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke((attemptedSubmit && error != nil) ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

private struct ValidatingPasswordField: View {
    @EnvironmentObject private var theme: Theme
    let label: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    @Binding var attemptedSubmit: Bool
    @Binding var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 18))
                    .foregroundColor(theme.colors.textSecondary)
                if showPassword {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textPrimary)
                        .tint(theme.colors.textPrimary)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textPrimary)
                        .tint(theme.colors.textPrimary)
                }
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 18))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke((attemptedSubmit && error != nil) ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            if let error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Location Search (unchanged)
#Preview {
    SignUpPage(onSignUp: { print("Sign up tapped") },
               onLoginClick: { print("Login tapped") })
    .environmentObject(Theme())
    .environmentObject(AuthStore())
}

