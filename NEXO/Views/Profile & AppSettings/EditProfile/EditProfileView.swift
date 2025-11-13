//
//  EditProfileView.swift
//  NEXO
//
//  Created by ChatGPT on 11/8/2025.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = EditProfileViewModel()

    var onBack: (() -> Void)?
    var onSave: (() -> Void)?
    var onSendVerification: (() -> Void)?

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            floatingOrbs

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        photoCard
                        basicInfoSection
                        bioSection
                        sportsSection
                        emailVerificationSection
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
            Button("OK") {}
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
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
                
                Text("Saving profile...")
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
                        if let onBack { onBack() }
                        else { dismiss() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .padding(8)
                    }
                    .buttonStyle(.plain)

                    Text("Edit Profile")
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

    // MARK: - Photo Card
    
    private var photoCard: some View {
        ZStack {
            glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.20, radius: 24)

            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 4))
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)

                    PhotosPicker(selection: $viewModel.pickedItem, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .onChange(of: viewModel.hasPickedNewPhoto) { _, _ in
                        viewModel.trackPhotoChanged()
                    }
                }
                Text("Tap to change photo")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
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

    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic Information")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.15, radius: 24)

                VStack(spacing: 12) {
                    labeledField("Full Name", error: viewModel.nameError) {
                        TextField("Your name", text: $viewModel.name)
                            .textContentType(.name)
                            .submitLabel(.done)
                    }

                    labeledField(icon: "envelope.fill", label: "Email", error: viewModel.emailError) {
                        TextField("email@example.com", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .submitLabel(.done)
                    }

                    labeledField(icon: "phone.fill", label: "Phone", error: viewModel.phoneError) {
                        TextField("+1 (555) 123-4567", text: $viewModel.phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .submitLabel(.done)
                    }

                    labeledField(icon: "calendar", label: "Date of Birth", error: "") {
                        DatePicker("", selection: $viewModel.dateOfBirth, displayedComponents: .date)
                            .labelsHidden()
                    }

                    labeledField(icon: "mappin", label: "Location", error: viewModel.locationError) {
                        TextField("City, State", text: $viewModel.location)
                            .textContentType(.fullStreetAddress)
                            .submitLabel(.done)
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

    // MARK: - Bio
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Me")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.15, radius: 24)

                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $viewModel.bio)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 100)
                        .font(.system(size: 14))

                    HStack {
                        Text(viewModel.bioCharacterCountText)
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.isBioTooLong ? .red : theme.colors.textSecondary)
                            .padding(.horizontal, 2)
                        
                        if viewModel.isBioTooLong {
                            Text("Too long!")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(16)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        viewModel.isBioTooLong
                            ? Color.red
                            : Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8),
                        lineWidth: 2
                    )
            )
            .cornerRadius(20)
        }
    }

    // MARK: - Sports
    
    private var sportsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "EC4899"))
                Text("Sports Interests")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.selectedSportsCount) selected")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.15, radius: 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Select the sports you're interested in")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)

                    WrapHStack(items: viewModel.availableSports) { sport in
                        sportChip(for: sport)
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

    private func sportChip(for sport: String) -> some View {
        let isSelected = viewModel.isSportSelected(sport)
        return Button {
            viewModel.toggleSport(sport)
            viewModel.trackSportToggled(sport, selected: !isSelected)
        } label: {
            Text(sport)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.colors.textPrimary.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(
                            isSelected ? Color.clear : theme.colors.cardStroke,
                            lineWidth: isSelected ? 0 : 2
                        )
                )
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.15) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Email Verification
    
    private var emailVerificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: viewModel.emailVerificationColor))
                Text("Email Verification")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: viewModel.emailVerificationGlowColors, opacity: 0.15, radius: 20)

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: viewModel.emailVerificationGlowColors[0]).opacity(0.2),
                                        Color(hex: viewModel.emailVerificationGlowColors[1]).opacity(0.2)
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6), lineWidth: 2))

                        Image(systemName: viewModel.emailVerificationIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: viewModel.emailVerificationColor))
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(viewModel.emailVerificationTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            if viewModel.emailVerified {
                                Text("✓ Verified")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "2ECC71"))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(viewModel.emailVerificationMessage)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)

                        if !viewModel.emailVerified {
                            Button {
                                handleSendVerification()
                            } label: {
                                Text("Send Verification Email")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "F39C12"), Color(hex: "E67E22")],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: Color(hex: "F39C12").opacity(0.35), radius: 8, y: 3)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                            .disabled(viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.6 : 1.0)
                        }
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
    }

    // MARK: - Helpers
    
    private func labeledField(_ label: String, error: String = "", @ViewBuilder field: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 2)
            field()
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(theme.isDarkMode ? 0.06 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            error.isEmpty
                                ? Color.white.opacity(theme.isDarkMode ? 0.12 : 0.6)
                                : Color.red,
                            lineWidth: 2
                        )
                )
                .cornerRadius(12)
            
            if !error.isEmpty {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 2)
            }
        }
    }

    private func labeledField(icon: String, label: String, error: String = "", @ViewBuilder field: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, 2)

            field()
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(theme.isDarkMode ? 0.06 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            error.isEmpty
                                ? Color.white.opacity(theme.isDarkMode ? 0.12 : 0.6)
                                : Color.red,
                            lineWidth: 2
                        )
                )
                .cornerRadius(12)
            
            if !error.isEmpty {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 2)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = viewModel.pickedImageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else if let url = URL(string: viewModel.avatarURL) {
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                initialsPlaceholder
            }
        } else {
            initialsPlaceholder
        }
    }

    private var initialsPlaceholder: some View {
        Text(viewModel.displayInitials)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Color(hex: "8B5CF6"))
            .frame(width: 96, height: 96)
            .background(
                LinearGradient(
                    colors: [Color(hex: "8B5CF6").opacity(0.2), Color(hex: "EC4899").opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
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
        viewModel.saveProfile(
            onSuccess: {
                viewModel.trackProfileSaved()
                onSave?()
                if let onBack {
                    onBack()
                } else {
                    dismiss()
                }
            },
            onError: { error in
                viewModel.trackProfileSaveFailed(error: error)
            }
        )
    }
    
    private func handleSendVerification() {
        viewModel.sendVerificationEmail(
            onSuccess: {
                viewModel.trackVerificationEmailSent()
                onSendVerification?()
            },
            onError: { _ in }
        )
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(Theme())
    }
}
