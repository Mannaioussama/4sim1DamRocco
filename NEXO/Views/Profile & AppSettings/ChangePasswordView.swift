//
//  ChangePasswordView.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = ChangePasswordViewModel()

    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            floatingOrbs

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        securityTipCard
                        passwordInfoCard
                        requirementsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                handleSuccessfulSave()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            viewModel.trackScreenView()
        }
    }

    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Changing password...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }

    // MARK: - Header
    
    private var header: some View {
        VStack {
            ZStack {
                // Glow
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.15),
                                Color(hex: "EC4899").opacity(0.15)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 20)
                    .padding(.horizontal, 8)
                    .frame(height: 52)

                HStack {
                    Button {
                        if let onBack { onBack() } else { dismiss() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .padding(8)
                    }
                    .buttonStyle(.plain)

                    Text("Change Password")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Button(action: handleSave) {
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "8B5CF6").opacity(0.35), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                }
                .padding(.horizontal, 12)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
            )
            .cornerRadius(20)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Security Tip Card
    
    private var securityTipCard: some View {
        ZStack {
            glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.20, radius: 20)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6").opacity(0.2), Color(hex: "EC4899").opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6), lineWidth: 2))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "8B5CF6"))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.securityTipTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(viewModel.securityTipMessage)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(14)
        }
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
        )
        .cornerRadius(20)
    }

    // MARK: - Password Info Card
    
    private var passwordInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Password Information")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.15, radius: 20)

                VStack(spacing: 12) {
                    passwordField(
                        title: "Current Password",
                        text: $viewModel.currentPassword,
                        isVisible: $viewModel.showCurrent,
                        error: viewModel.currentError,
                        onToggle: { viewModel.toggleCurrentPasswordVisibility() }
                    )
                    passwordField(
                        title: "New Password",
                        text: $viewModel.newPassword,
                        isVisible: $viewModel.showNew,
                        error: viewModel.newError,
                        onToggle: { viewModel.toggleNewPasswordVisibility() }
                    )
                    passwordField(
                        title: "Confirm New Password",
                        text: $viewModel.confirmPassword,
                        isVisible: $viewModel.showConfirm,
                        error: viewModel.confirmError,
                        onToggle: { viewModel.toggleConfirmPasswordVisibility() }
                    )
                    
                    // Password strength indicator
                    if viewModel.hasNewPassword {
                        passwordStrengthIndicator
                    }
                }
                .padding(16)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
            )
            .cornerRadius(20)
        }
    }
    
    // MARK: - Password Strength Indicator
    
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Password Strength:")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                
                Spacer()
                
                Text(viewModel.passwordStrengthText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: viewModel.passwordStrengthColor))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: viewModel.passwordStrengthColor))
                        .frame(width: geometry.size.width * (CGFloat(viewModel.passwordStrengthScore) / 5.0), height: 6)
                        .animation(.spring(response: 0.3), value: viewModel.passwordStrengthScore)
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 4)
    }

    // MARK: - Requirements Card
    
    private var requirementsCard: some View {
        ZStack {
            glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.10, radius: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Password Requirements:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.requirements, id: \.text) { requirement in
                        requirementRow(requirement.text, isMet: requirement.isMet)
                    }
                }
            }
            .padding(12)
        }
        .background(theme.colors.cardBackground.opacity(0.9))
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 2)
        )
        .cornerRadius(16)
    }

    // MARK: - Components
    
    private func passwordField(
        title: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        error: String,
        onToggle: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, 2)

            ZStack(alignment: .trailing) {
                Group {
                    if isVisible.wrappedValue {
                        TextField(viewModel.getFieldPlaceholder(for: title), text: text)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    } else {
                        SecureField(viewModel.getFieldPlaceholder(for: title), text: text)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(theme.isDarkMode ? 0.06 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            error.isEmpty ? Color.white.opacity(theme.isDarkMode ? 0.12 : 0.6) : Color.red,
                            lineWidth: 2
                        )
                )
                .cornerRadius(12)

                Button {
                    onToggle()
                    viewModel.trackVisibilityToggled(title, visible: isVisible.wrappedValue)
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(.trailing, 12)
                }
                .buttonStyle(.plain)
            }

            if !error.isEmpty {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 2)
            }
        }
    }

    private func requirementRow(_ text: String, isMet: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(isMet ? Color(hex: "10B981") : Color(hex: "8B5CF6").opacity(0.5))
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(theme.colors.textSecondary)
                .strikethrough(isMet, color: theme.colors.textSecondary.opacity(0.5))
        }
    }

    private func glowBox(colors: [String], opacity: Double, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(
                LinearGradient(
                    colors: colors.map { Color(hex: $0).opacity(opacity) },
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .blur(radius: 24)
            .opacity(0.8)
            .padding(-6)
    }

    private var floatingOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "A78BFA").opacity(0.4), Color(hex: "F472B6").opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 128, height: 128)
                .blur(radius: 48)
                .offset(x: -100, y: -160)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "93C5FD").opacity(0.3), Color(hex: "A78BFA").opacity(0.3)],
                        startPoint: .bottomLeading, endPoint: .topTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 60)
                .offset(x: 110, y: 220)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FBCFE8").opacity(0.3), Color(hex: "DDD6FE").opacity(0.3)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 96, height: 96)
                .blur(radius: 40)
                .offset(x: 0, y: 120)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "E9D5FF").opacity(0.25), Color(hex: "FDE68A").opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 30)
                .offset(x: 120, y: -60)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Actions
    
    private func handleSave() {
        viewModel.savePassword(
            onSuccess: {
                handleSuccessfulSave()
            },
            onError: { error in
                viewModel.trackPasswordChangeFailed(error: error)
            }
        )
    }
    
    private func handleSuccessfulSave() {
        viewModel.trackPasswordChanged()
        onSave?()
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(Theme())
    }
}
