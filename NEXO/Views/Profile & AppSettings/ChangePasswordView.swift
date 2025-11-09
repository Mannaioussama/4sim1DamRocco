import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: Theme

    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    // Form state
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    // Visibility toggles
    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false

    // Errors
    @State private var currentError: String = ""
    @State private var newError: String = ""
    @State private var confirmError: String = ""

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
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Header (styled like EditProfileView)
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
                    Text("Security Tip")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Use a strong password with at least 8 characters, including letters, numbers, and symbols.")
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
                        text: $currentPassword,
                        isVisible: $showCurrent,
                        error: currentError
                    )
                    passwordField(
                        title: "New Password",
                        text: $newPassword,
                        isVisible: $showNew,
                        error: newError
                    )
                    passwordField(
                        title: "Confirm New Password",
                        text: $confirmPassword,
                        isVisible: $showConfirm,
                        error: confirmError
                    )
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

    // MARK: - Requirements Card
    private var requirementsCard: some View {
        ZStack {
            glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.10, radius: 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Password Requirements:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)

                VStack(alignment: .leading, spacing: 6) {
                    requirementRow("At least 8 characters long")
                    requirementRow("Include uppercase and lowercase letters")
                    requirementRow("Include at least one number")
                    requirementRow("Include at least one special character")
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
    private func passwordField(title: String, text: Binding<String>, isVisible: Binding<Bool>, error: String) -> some View {
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
                        TextField("••••••••", text: text)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    } else {
                        SecureField("••••••••", text: text)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(theme.isDarkMode ? 0.06 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.6), lineWidth: 2)
                )
                .cornerRadius(12)
                .onChangeCompat(of: text.wrappedValue) {
                    clearError(for: title)
                }

                Button {
                    isVisible.wrappedValue.toggle()
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

    private func requirementRow(_ text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: "8B5CF6"))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(theme.colors.textSecondary)
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

    // MARK: - Validation
    private func clearError(for title: String) {
        switch title {
        case "Current Password": currentError = ""
        case "New Password": newError = ""
        case "Confirm New Password": confirmError = ""
        default: break
        }
    }

    private func validate() -> Bool {
        var ok = true
        if currentPassword.isEmpty {
            currentError = "Current password is required"
            ok = false
        }
        if newPassword.isEmpty {
            newError = "New password is required"
            ok = false
        } else if newPassword.count < 8 {
            newError = "Password must be at least 8 characters"
            ok = false
        }
        if confirmPassword.isEmpty {
            confirmError = "Please confirm your password"
            ok = false
        } else if newPassword != confirmPassword {
            confirmError = "Passwords do not match"
            ok = false
        }
        return ok
    }

    private func handleSave() {
        if validate() {
            onSave?()
            if let onBack { onBack() } else { dismiss() }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(Theme())
    }
}

// MARK: - Compatibility helper for onChange (iOS 17 deprecation)
private extension View {
    @ViewBuilder
    func onChangeCompat<Value: Equatable>(of value: Value, perform action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value, action)
        } else {
            self.onChange(of: value) { _ in action() }
        }
    }
}
