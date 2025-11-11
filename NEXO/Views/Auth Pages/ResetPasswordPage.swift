//
//  ResetPasswordPage.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct ResetPasswordPage: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var viewModel: ResetPasswordViewModel
    
    var onBackToLogin: () -> Void
    
    init(onBackToLogin: @escaping () -> Void, authStore: AuthStore) {
        self.onBackToLogin = onBackToLogin
        _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(authStore: authStore))
    }
    
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    if viewModel.isInputState {
                        ResetPasswordInputView(
                            email: $viewModel.email,
                            emailError: viewModel.emailError,
                            apiError: viewModel.apiError,
                            isLoading: viewModel.isLoading,
                            onSubmit: handleSubmit,
                            onBackToLogin: handleBackToLogin
                        )
                        .environmentObject(theme)
                    } else {
                        ResetPasswordSuccessView(
                            email: viewModel.email,
                            onBackToLogin: handleBackToLogin,
                            onResend: handleResend
                        )
                        .environmentObject(theme)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
        .onAppear {
            viewModel.trackScreenView()
        }
    }
    
    // MARK: - Background Orbs
    
    private var backgroundOrbs: some View {
        ZStack {
            FloatingOrb(
                size: 128,
                color: LinearGradient(
                    colors: [Color(hex: "8B5CF6").opacity(0.3), Color(hex: "C4B5FD").opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                xOffset: -140, yOffset: -250, delay: 0
            )
            FloatingOrb(
                size: 160,
                color: LinearGradient(
                    colors: [Color(hex: "EC4899").opacity(0.35), Color(hex: "F9A8D4").opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                xOffset: 140, yOffset: 150, delay: 1
            )
            FloatingOrb(
                size: 96,
                color: LinearGradient(
                    colors: [Color(hex: "0066FF").opacity(0.3), Color(hex: "60A5FA").opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                xOffset: 0, yOffset: 0, delay: 2
            )
            FloatingOrb(
                size: 80,
                color: LinearGradient(
                    colors: [Color(hex: "2ECC71").opacity(0.25), Color(hex: "10B981").opacity(0.15)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                xOffset: 100, yOffset: -150, delay: 3
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        viewModel.sendResetEmail(
            onSuccess: {
                viewModel.trackResetEmailSent()
            },
            onError: { error in
                viewModel.trackResetEmailFailed(error: error)
            }
        )
    }
    
    private func handleResend() {
        viewModel.trackResendClicked()
        viewModel.resendResetEmail(
            onSuccess: {},
            onError: { _ in }
        )
    }
    
    private func handleBackToLogin() {
        viewModel.trackBackToLoginClicked()
        viewModel.resetToInput()
        onBackToLogin()
    }
}

// MARK: - Reset Password Input View

struct ResetPasswordInputView: View {
    @EnvironmentObject private var theme: Theme
    @Binding var email: String
    let emailError: String?
    let apiError: String?
    let isLoading: Bool
    let onSubmit: () -> Void
    let onBackToLogin: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            logoSection
            formCard
            backToLoginLink
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.2),
                                Color.white.opacity(theme.isDarkMode ? 0.25 : 0.4),
                                Color(hex: "EC4899").opacity(0.2)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .blur(radius: 12)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(theme.colors.cardStroke, lineWidth: 2)
                        )
                        .cornerRadius(24)
                    
                    LinearGradient(
                        colors: [
                            Color.white.opacity(theme.isDarkMode ? 0.18 : 0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .cornerRadius(24)
                    .padding(2)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                }
                .frame(width: 80, height: 80)
                .shadow(color: Color(hex: "8B5CF6").opacity(0.2), radius: 30, x: 0, y: 10)
            }
            
            VStack(spacing: 8) {
                Text("Reset Password")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text("Enter your email address and we'll send you a link to reset your password")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Form Card
    
    private var formCard: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.2),
                                Color(hex: "EC4899").opacity(0.2),
                                Color(hex: "0066FF").opacity(0.2)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 12)
                    .opacity(0.75)
                    .padding(-4)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(theme.colors.cardStroke, lineWidth: 2)
                        )
                        .cornerRadius(24)
                    
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDarkMode ? 0.18 : 0.6),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 80)
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                        Spacer()
                    }
                    
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.black.opacity(theme.isDarkMode ? 0.15 : 0.05), lineWidth: 1)
                    
                    formContent
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
        }
        .padding(.horizontal, 24)
    }
    
    private var formContent: some View {
        VStack(spacing: 24) {
            emailField
            
            if let apiError = apiError {
                Text(apiError)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            submitButton
        }
        .padding(24)
    }
    
    // MARK: - Email Field
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
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
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(emailError != nil ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            
            if let emailError = emailError {
                Text(emailError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button(action: onSubmit) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(theme.colors.textPrimary)
                }
                Text("Send Reset Link")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(theme.colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(theme.isDarkMode ? 0.18 : 0.7),
                        Color.white.opacity(theme.isDarkMode ? 0.12 : 0.5)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
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
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
    
    // MARK: - Back to Login Link
    
    private var backToLoginLink: some View {
        HStack(spacing: 4) {
            Text("Remember your password?")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
            
            Button(action: onBackToLogin) {
                Text("Back to Sign In")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
        .padding(.top, 24)
    }
}

// MARK: - Reset Password Success View

struct ResetPasswordSuccessView: View {
    @EnvironmentObject private var theme: Theme
    let email: String
    let onBackToLogin: () -> Void
    let onResend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            successLogoSection
            successCard
        }
    }
    
    // MARK: - Success Logo Section
    
    private var successLogoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "2ECC71").opacity(0.2),
                                Color.white.opacity(theme.isDarkMode ? 0.25 : 0.4),
                                Color(hex: "10B981").opacity(0.2)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .blur(radius: 12)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(theme.colors.cardStroke, lineWidth: 2)
                        )
                        .cornerRadius(24)
                    
                    LinearGradient(
                        colors: [
                            Color.white.opacity(theme.isDarkMode ? 0.18 : 0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .cornerRadius(24)
                    .padding(2)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "2ECC71"))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                }
                .frame(width: 80, height: 80)
                .shadow(color: Color(hex: "2ECC71").opacity(0.2), radius: 30, x: 0, y: 10)
            }
            
            VStack(spacing: 8) {
                Text("Check Your Email")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text("We've sent a password reset link to")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                
                Text(email)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(.top, 4)
            }
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Success Card
    
    private var successCard: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.2),
                                Color(hex: "EC4899").opacity(0.2),
                                Color(hex: "0066FF").opacity(0.2)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 12)
                    .opacity(0.75)
                    .padding(-4)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(theme.colors.cardStroke, lineWidth: 2)
                        )
                        .cornerRadius(24)
                    
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDarkMode ? 0.18 : 0.6),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 80)
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                        Spacer()
                    }
                    
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.black.opacity(theme.isDarkMode ? 0.15 : 0.05), lineWidth: 1)
                    
                    successContent
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
        }
        .padding(.horizontal, 24)
    }
    
    private var successContent: some View {
        VStack(spacing: 16) {
            infoBox
            backToSignInButton
            resendLink
        }
        .padding(24)
    }
    
    private var infoBox: some View {
        VStack(spacing: 0) {
            Text("Click the link in the email to reset your password. If you don't see the email, check your spam folder.")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(16)
        }
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var backToSignInButton: some View {
        Button(action: onBackToLogin) {
            Text("Back to Sign In")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(theme.isDarkMode ? 0.18 : 0.7),
                            Color.white.opacity(theme.isDarkMode ? 0.12 : 0.5)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
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
    
    private var resendLink: some View {
        Button(action: onResend) {
            Text("Didn't receive the email? Send again")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview("Reset Password Input") {
    ResetPasswordPage(
        onBackToLogin: {
            print("Back to login")
        },
        authStore: AuthStore()
    )
    .environmentObject(Theme())
    .environmentObject(AuthStore())
}

#Preview("Reset Password Success") {
    @Previewable @State var email = "test@example.com"
    
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 245/255, green: 246/255, blue: 248/255),
                Color(red: 240/255, green: 242/255, blue: 245/255),
                Color(red: 235/255, green: 237/255, blue: 240/255)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            ResetPasswordSuccessView(
                email: email,
                onBackToLogin: {},
                onResend: {}
            )
            .environmentObject(Theme())
            .padding(.top, 80)
        }
    }
}
