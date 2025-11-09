//
//  LoginPage.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct LoginPage: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var authStore: AuthStore

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    // Validation state
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var attemptedSubmit = false

    // Networking state
    @State private var isLoading = false
    @State private var apiError: String? = nil

    var onLogin: () -> Void
    var onSignUpClick: () -> Void
    var onForgotPasswordClick: () -> Void

    // MARK: - Validation
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let regex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: trimmed)
    }

    private var isPasswordValid: Bool {
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSubmit: Bool {
        isEmailValid && isPasswordValid && !isLoading
    }

    private func validateFields() {
        emailError = isEmailValid ? nil : "Please enter a valid email address"
        passwordError = isPasswordValid ? nil : "Password is required"
    }

    private func submit() {
        attemptedSubmit = true
        validateFields()
        guard canSubmit else { return }
        apiError = nil
        isLoading = true
        Task {
            do {
                try await authStore.login(email: email, password: password)
                isLoading = false
                onLogin()
            } catch {
                isLoading = false
                apiError = (error as? APIError)?.userMessage ?? "Login failed. Please try again."
            }
        }
    }

    var body: some View {
        ZStack {
            // Background (theme-aware)
            theme.colors.backgroundGradient
                .ignoresSafeArea()

            // Floating Orbs - Neon Electric Accents (kept)
            FloatingOrb(
                size: 128,
                color: LinearGradient(
                    colors: [
                        Color(hex: "8B5CF6").opacity(0.3),
                        Color(hex: "C4B5FD").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: -140,
                yOffset: -250,
                delay: 0
            )

            FloatingOrb(
                size: 160,
                color: LinearGradient(
                    colors: [
                        Color(hex: "EC4899").opacity(0.35),
                        Color(hex: "F9A8D4").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 140,
                yOffset: 150,
                delay: 1
            )

            FloatingOrb(
                size: 96,
                color: LinearGradient(
                    colors: [
                        Color(hex: "0066FF").opacity(0.3),
                        Color(hex: "60A5FA").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 0,
                yOffset: 0,
                delay: 2
            )

            FloatingOrb(
                size: 80,
                color: LinearGradient(
                    colors: [
                        Color(hex: "2ECC71").opacity(0.25),
                        Color(hex: "10B981").opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 100,
                yOffset: -150,
                delay: 3
            )

            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Logo Section
                    VStack(spacing: 16) {
                        // Logo with Crystal Glass Effect
                        ZStack {
                            // Shimmer effect
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "8B5CF6").opacity(0.2),
                                            Color.white.opacity(theme.isDarkMode ? 0.25 : 0.4),
                                            Color(hex: "EC4899").opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .blur(radius: 12)

                            ZStack {
                                // Glass container (theme glass)
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                                    )
                                    .cornerRadius(24)

                                // Inner glow
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDarkMode ? 0.25 : 0.5),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .cornerRadius(24)
                                .padding(2)

                                // Logo
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
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                            Text("Sign in to continue your fitness journey")
                                .font(.system(size: 14))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    .padding(.bottom, 32)

                    // Login Form Card
                    VStack(spacing: 0) {
                        ZStack {
                            // Outer glow
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "8B5CF6").opacity(0.2),
                                            Color(hex: "EC4899").opacity(0.2),
                                            Color(hex: "0066FF").opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blur(radius: 12)
                                .opacity(0.75)
                                .padding(-4)

                            ZStack {
                                // Main glass container
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                                    )
                                    .cornerRadius(24)

                                // Top highlight for glass shine
                                VStack {
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(theme.isDarkMode ? 0.18 : 0.6),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 80)
                                    .cornerRadius(24, corners: [.topLeft, .topRight])

                                    Spacer()
                                }

                                // Inner shadow
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Color.black.opacity(theme.isDarkMode ? 0.15 : 0.05), lineWidth: 1)

                                // Form Content
                                VStack(spacing: 12) {
                                    // Email Input
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Email")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(theme.colors.textPrimary)

                                        HStack(spacing: 12) {
                                            Image(systemName: "envelope")
                                                .font(.system(size: 18))
                                                .foregroundColor(theme.colors.textSecondary)

                                            TextField("your@email.com", text: $email)
                                                .font(.system(size: 15))
                                                .foregroundColor(theme.colors.textPrimary)
                                                .tint(theme.colors.textPrimary)
                                                .accentColor(theme.colors.textPrimary)
                                                .autocapitalization(.none)
                                                .autocorrectionDisabled()
                                                .keyboardType(.emailAddress)
                                                .textContentType(.emailAddress)
                                                .onChange(of: email) { _, _ in
                                                    if attemptedSubmit { validateFields() }
                                                }
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(height: 48)
                                        .background(theme.colors.cardBackground)
                                        .background(theme.colors.barMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke((attemptedSubmit && emailError != nil) ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

                                        if let emailError {
                                            Text(emailError)
                                                .font(.system(size: 12))
                                                .foregroundColor(.red)
                                        }
                                    }

                                    // Password Input
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Password")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(theme.colors.textPrimary)

                                        HStack(spacing: 12) {
                                            Image(systemName: "lock")
                                                .font(.system(size: 18))
                                                .foregroundColor(theme.colors.textSecondary)

                                            if showPassword {
                                                TextField("Enter your password", text: $password)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(theme.colors.textPrimary)
                                                    .tint(theme.colors.textPrimary)
                                                    .accentColor(theme.colors.textPrimary)
                                                    .onChange(of: password) { _, _ in
                                                        if attemptedSubmit { validateFields() }
                                                    }
                                            } else {
                                                SecureField("Enter your password", text: $password)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(theme.colors.textPrimary)
                                                    .tint(theme.colors.textPrimary)
                                                    .accentColor(theme.colors.textPrimary)
                                                    .onChange(of: password) { _, _ in
                                                        if attemptedSubmit { validateFields() }
                                                    }
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
                                                .stroke((attemptedSubmit && passwordError != nil) ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

                                        if let passwordError {
                                            Text(passwordError)
                                                .font(.system(size: 12))
                                                .foregroundColor(.red)
                                        }
                                    }

                                    // API error
                                    if let apiError {
                                        Text(apiError)
                                            .font(.system(size: 13))
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    // Forgot Password
                                    HStack {
                                        Spacer()
                                        Button(action: onForgotPasswordClick) {
                                            Text("Forgot password?")
                                                .font(.system(size: 14))
                                                .foregroundColor(theme.colors.textPrimary)
                                        }
                                    }

                                    // Sign In Button
                                    Button(action: submit) {
                                        HStack(spacing: 8) {
                                            if isLoading {
                                                ProgressView()
                                                    .tint(theme.colors.textPrimary)
                                            }
                                            Text("Sign In")
                                        }
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(theme.colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(theme.isDarkMode ? 0.18 : (canSubmit ? 0.7 : 0.4)),
                                                    Color.white.opacity(theme.isDarkMode ? 0.12 : (canSubmit ? 0.5 : 0.3))
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .background(theme.colors.barMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(theme.colors.cardStroke, lineWidth: 2)
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .disabled(!canSubmit)

                                    // Divider
                                    HStack(spacing: 12) {
                                        Rectangle()
                                            .fill(Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4))
                                            .frame(height: 2)

                                        Text("or")
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.colors.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(theme.colors.cardBackground)
                                            .background(theme.colors.barMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                                            )
                                            .cornerRadius(20)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                                        Rectangle()
                                            .fill(Color.white.opacity(theme.isDarkMode ? 0.18 : 0.4))
                                            .frame(height: 2)
                                    }
                                    .padding(.vertical, 8)

                                    // Social Login Buttons
                                    VStack(spacing: 12) {
                                        Button(action: {}) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "globe")
                                                    .font(.system(size: 18))

                                                Text("Continue with Google")
                                                    .font(.system(size: 15, weight: .medium))
                                            }
                                            .foregroundColor(theme.colors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(theme.isDarkMode ? 0.18 : 0.7),
                                                        Color.white.opacity(theme.isDarkMode ? 0.12 : 0.5)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .background(theme.colors.barMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(theme.colors.cardStroke, lineWidth: 2)
                                            )
                                            .cornerRadius(16)
                                            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                        }
                                        .buttonStyle(ScaleButtonStyle())

                                        Button(action: {}) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "f.circle.fill")
                                                    .font(.system(size: 18))

                                                Text("Continue with Facebook")
                                                    .font(.system(size: 15, weight: .medium))
                                            }
                                            .foregroundColor(theme.colors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(theme.isDarkMode ? 0.18 : 0.7),
                                                        Color.white.opacity(theme.isDarkMode ? 0.12 : 0.5)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .background(theme.colors.barMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(theme.colors.cardStroke, lineWidth: 2)
                                            )
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

                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)

                        Button(action: onSignUpClick) {
                            Text("Sign Up")
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
        // Hide the default navigation bar/back button on Login
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

#Preview {
    LoginPage(
        onLogin: {},
        onSignUpClick: {},
        onForgotPasswordClick: {}
    )
    .environmentObject(Theme())
    .environmentObject(AuthStore())
}

