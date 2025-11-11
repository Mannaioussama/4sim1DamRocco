//
//  LoginView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var viewModel: LoginViewModel
    
    var onLogin: () -> Void
    var onSignUpClick: () -> Void
    var onForgotPasswordClick: () -> Void
    
    // MARK: - Initialization
    init(
        authStore: AuthStore,
        onLogin: @escaping () -> Void,
        onSignUpClick: @escaping () -> Void,
        onForgotPasswordClick: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authStore: authStore))
        self.onLogin = onLogin
        self.onSignUpClick = onSignUpClick
        self.onForgotPasswordClick = onForgotPasswordClick
    }
    
    var body: some View {
        ZStack {
            // Background (theme-aware)
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            // Floating Orbs - Neon Electric Accents
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
                    logoSection
                    
                    // Login Form Card
                    loginFormCard
                    
                    // Sign Up Link
                    signUpLink
                }
            }
        }
        .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - View Components
    
    private var logoSection: some View {
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
    }
    
    private var loginFormCard: some View {
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
                        emailField
                        passwordField
                        
                        // API error
                        if let apiError = viewModel.apiError {
                            Text(apiError)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        forgotPasswordButton
                        signInButton
                        divider
                        socialLoginButtons
                    }
                    .padding(24)
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
        }
        .padding(.horizontal, 24)
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Email")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .font(.system(size: 18))
                    .foregroundColor(theme.colors.textSecondary)
                
                TextField("your@email.com", text: $viewModel.email)
                    .font(.system(size: 15))
                    .foregroundColor(theme.colors.textPrimary)
                    .tint(theme.colors.textPrimary)
                    .accentColor(theme.colors.textPrimary)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .onChange(of: viewModel.email) { _, _ in
                        if viewModel.attemptedSubmit { viewModel.validateFields() }
                    }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke((viewModel.attemptedSubmit && viewModel.emailError != nil) ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            
            if let emailError = viewModel.emailError {
                Text(emailError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 18))
                    .foregroundColor(theme.colors.textSecondary)
                
                if viewModel.showPassword {
                    TextField("Enter your password", text: $viewModel.password)
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textPrimary)
                        .tint(theme.colors.textPrimary)
                        .accentColor(theme.colors.textPrimary)
                        .onChange(of: viewModel.password) { _, _ in
                            if viewModel.attemptedSubmit { viewModel.validateFields() }
                        }
                } else {
                    SecureField("Enter your password", text: $viewModel.password)
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.textPrimary)
                        .tint(theme.colors.textPrimary)
                        .accentColor(theme.colors.textPrimary)
                        .onChange(of: viewModel.password) { _, _ in
                            if viewModel.attemptedSubmit { viewModel.validateFields() }
                        }
                }
                
                Button(action: { viewModel.showPassword.toggle() }) {
                    Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
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
                    .stroke((viewModel.attemptedSubmit && viewModel.passwordError != nil) ? Color.red.opacity(0.6) : theme.colors.cardStroke, lineWidth: 2)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            
            if let passwordError = viewModel.passwordError {
                Text(passwordError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button(action: onForgotPasswordClick) {
                Text("Forgot password?")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
    }
    
    private var signInButton: some View {
        Button(action: { viewModel.submit(onSuccess: onLogin) }) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
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
                        Color.white.opacity(theme.isDarkMode ? 0.18 : (viewModel.canSubmit ? 0.7 : 0.4)),
                        Color.white.opacity(theme.isDarkMode ? 0.12 : (viewModel.canSubmit ? 0.5 : 0.3))
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
        .disabled(!viewModel.canSubmit)
    }
    
    private var divider: some View {
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
    }
    
    private var socialLoginButtons: some View {
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
    
    private var signUpLink: some View {
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

// MARK: - Preview

#Preview {
    LoginView(
        authStore: AuthStore(),
        onLogin: {},
        onSignUpClick: {},
        onForgotPasswordClick: {}
    )
    .environmentObject(Theme())
    .environmentObject(AuthStore())
}
