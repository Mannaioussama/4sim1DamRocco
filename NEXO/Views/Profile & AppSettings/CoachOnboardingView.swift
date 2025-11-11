//
//  CoachOnboardingView.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI

struct CoachOnboardingView: View {
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = CoachOnboardingViewModel()
    
    var onBack: (() -> Void)?
    var onComplete: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Themed background + floating orbs
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            backgroundOrbs
            
            VStack(spacing: 0) {
                if viewModel.isApplicationStep {
                    ScrollView(showsIndicators: false) {
                        formSection
                            .padding()
                    }
                } else {
                    statusSection
                }
            }
            
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.cardBackground, in: Circle())
                            .background(theme.colors.barMaterial, in: Circle())
                            .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        // MARK: - Pickers
        .sheet(isPresented: $viewModel.showLibraryPicker) {
            PhotoLibraryPicker(
                onPick: { picked in
                    viewModel.addDocument(picked)
                    viewModel.trackDocumentUploaded()
                },
                onCancel: {}
            )
        }
        .sheet(isPresented: $viewModel.showFilesPicker) {
            FilesImagePicker(
                onPick: { picked in
                    viewModel.addDocument(picked)
                    viewModel.trackDocumentUploaded()
                },
                onCancel: {}
            )
        }
        // MARK: - Custom Source Sheet Overlay
        .overlay {
            SourcePickerSheet(
                isPresented: $viewModel.showSourceSheet,
                theme: theme,
                anchorFrame: viewModel.uploadButtonFrame,
                onLibrary: { viewModel.openLibraryPicker() },
                onFiles: { viewModel.openFilesPicker() }
            )
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
                
                Text("Submitting application...")
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
    
    // MARK: - Background Orbs
    
    private var backgroundOrbs: some View {
        ZStack {
            orb(
                color1: theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.22 : 0.4),
                color2: theme.colors.accentPink.opacity(theme.isDarkMode ? 0.18 : 0.4),
                size: 300, x: -50, y: -100
            )
            orb(
                color1: Color.blue.opacity(theme.isDarkMode ? 0.18 : 0.3),
                color2: theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.16 : 0.3),
                size: 400, x: 150, y: 500
            )
            orb(
                color1: theme.colors.accentPink.opacity(theme.isDarkMode ? 0.16 : 0.3),
                color2: theme.colors.accentPurple.opacity(theme.isDarkMode ? 0.14 : 0.3),
                size: 250, x: 250, y: 250
            )
        }
    }
    
    private func orb(color1: Color, color2: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(LinearGradient(colors: [color1, color2], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .blur(radius: 60)
            .offset(x: x, y: y)
            .opacity(0.8)
            .allowsHitTesting(false)
    }
    
    // MARK: - Application Form
    
    private var formSection: some View {
        VStack(spacing: 18) {
            // Account type buttons
            accountTypeSelector
            
            textField(
                label: viewModel.nameLabel,
                placeholder: viewModel.namePlaceholder,
                text: $viewModel.formData.name,
                error: viewModel.nameError
            )
            
            textArea(
                label: "About *",
                placeholder: viewModel.bioPlaceholder,
                text: $viewModel.formData.bio,
                error: viewModel.bioError
            )
            
            textField(
                label: viewModel.specializationLabel,
                placeholder: viewModel.specializationPlaceholder,
                text: $viewModel.formData.specialization,
                error: viewModel.specializationError
            )
            
            experiencePicker
            
            textField(
                label: viewModel.certificationsLabel,
                placeholder: viewModel.certificationsPlaceholder,
                text: $viewModel.formData.certifications,
                error: viewModel.certificationsError
            )
            
            textField(
                label: "Location *",
                placeholder: "City, State",
                text: $viewModel.formData.location,
                error: viewModel.locationError
            )
            
            textField(
                label: "Website / Social Media",
                placeholder: "https://...",
                text: $viewModel.formData.website,
                error: ""
            )
            
            uploadButton
            
            if viewModel.hasDocuments {
                documentsPreview
            }
            
            if !viewModel.documentsError.isEmpty {
                Text(viewModel.documentsError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            submitButton
        }
    }
    
    // MARK: - Account Type Selector
    
    private var accountTypeSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("I am a *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            HStack(spacing: 12) {
                accountTypeButton(icon: "rosette", title: "Coach / Trainer", value: "coach")
                accountTypeButton(icon: "building.2", title: "Club Owner", value: "club")
            }
        }
    }
    
    private func accountTypeButton(icon: String, title: String, value: String) -> some View {
        Button(action: {
            viewModel.selectAccountType(value)
            viewModel.trackAccountTypeSelected(value)
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(theme.colors.accentPurple)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        viewModel.isAccountTypeSelected(value)
                        ? AnyShapeStyle(
                            LinearGradient(colors: [
                                theme.colors.accentPurple.opacity(0.2),
                                theme.colors.accentPurpleLight.opacity(0.15)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        : AnyShapeStyle(theme.colors.cardBackground)
                    )
            )
            .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        viewModel.isAccountTypeSelected(value)
                            ? theme.colors.accentPurple.opacity(0.5)
                            : theme.colors.cardStroke,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Experience Picker
    
    private var experiencePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Years of Experience *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            Picker("", selection: $viewModel.formData.experience) {
                ForEach(viewModel.experienceOptions, id: \.0) { value, label in
                    Text(label).tag(value)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding()
            .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        viewModel.experienceError.isEmpty
                            ? theme.colors.cardStroke
                            : Color.red,
                        lineWidth: 1
                    )
            )
            
            if !viewModel.experienceError.isEmpty {
                Text(viewModel.experienceError)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Form Fields
    
    private func textField(label: String, placeholder: String, text: Binding<String>, error: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textPrimary)
                .padding()
                .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(error.isEmpty ? theme.colors.cardStroke : Color.red, lineWidth: 1)
                )
            
            if !error.isEmpty {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
    }
    
    private func textArea(label: String, placeholder: String, text: Binding<String>, error: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(theme.colors.textSecondary.opacity(0.8))
                        .padding(.leading, 16)
                        .padding(.top, 12)
                }
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(height: 110)
                    .padding(8)
                    .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                    .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(error.isEmpty ? theme.colors.cardStroke : Color.red, lineWidth: 1)
                    )
            }
            
            if !error.isEmpty {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Upload Button
    
    private var uploadButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upload Verification Documents *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            GeometryReader { proxy in
                Button(action: {
                    let frame = proxy.frame(in: .global)
                    viewModel.openSourceSheet(buttonFrame: frame)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24))
                            .foregroundColor(theme.colors.textSecondary)
                        Text("Upload ID, Certifications, or Business License")
                            .font(.system(size: 13))
                            .foregroundColor(theme.colors.textPrimary)
                        Text("PNG, JPG, or HEIC (max 5MB each)")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                    .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.colors.cardStroke, style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .frame(height: 120)
        }
    }
    
    // MARK: - Documents Preview
    
    private var documentsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Documents")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            let columns = [GridItem(.adaptive(minimum: 92), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(viewModel.documents.enumerated()), id: \.offset) { index, doc in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: doc.uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 92)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .background(theme.colors.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.colors.cardStroke, lineWidth: 1))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        
                        Button {
                            viewModel.removeDocument(at: index)
                            viewModel.trackDocumentRemoved()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(width: 24, height: 24)
                                .background(theme.colors.cardBackground)
                                .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                        }
                        .padding(6)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.colors.cardStroke, lineWidth: 1))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button(action: handleSubmit) {
            HStack {
                Image(systemName: "doc.text")
                Text("Submit Application")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#3498DB"), Color(hex: "#2980B9")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(50)
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .padding(.top, 8)
        .buttonStyle(ScaleButtonStyle())
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        let config = viewModel.getStatusConfig(isDarkMode: theme.isDarkMode)
        return VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(config.bg)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(config.border, lineWidth: 1))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                
                VStack(spacing: 12) {
                    Image(systemName: config.icon)
                        .font(.system(size: 40))
                        .foregroundColor(config.color)
                        .padding()
                        .background(theme.colors.cardBackground, in: Circle())
                        .background(theme.colors.barMaterial, in: Circle())
                        .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))
                    
                    Text(config.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(config.message)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if viewModel.status == .approved {
                        approvedActions
                    }
                    
                    if viewModel.status == .rejected {
                        rejectedActions
                    }
                }
                .padding(24)
            }
            .padding(.horizontal)
            
            verifiedBenefits
            Spacer()
        }
        .background(theme.colors.backgroundGradient.ignoresSafeArea())
    }
    
    private var approvedActions: some View {
        VStack(spacing: 12) {
            Text(viewModel.verifiedBadgeText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [theme.colors.accentPurple, theme.colors.accentPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(50)
            
            Button("Go to Dashboard") {
                viewModel.trackDashboardNavigation()
                onComplete?()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                LinearGradient(
                    colors: [theme.colors.accentGreenFill, theme.colors.accentGreenGlow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(50)
            .padding(.horizontal)
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private var rejectedActions: some View {
        Button("Reapply") {
            viewModel.reapply()
            viewModel.trackReapply()
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(theme.colors.cardBackground, in: Capsule())
        .background(theme.colors.barMaterial, in: Capsule())
        .overlay(RoundedRectangle(cornerRadius: 50).stroke(theme.colors.cardStroke, lineWidth: 1))
        .foregroundColor(theme.colors.textPrimary)
        .cornerRadius(50)
        .padding(.horizontal)
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var verifiedBenefits: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.colors.cardStroke, lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                
                HStack(spacing: 8) {
                    Image(systemName: "rosette")
                        .foregroundColor(theme.colors.accentPurple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verified Benefits")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        Text("Create paid sessions, get priority in search, and build trust with your community.")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .padding()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        viewModel.submitApplication(
            onSuccess: {
                viewModel.trackApplicationSuccess()
            },
            onError: { error in
                viewModel.trackApplicationFailed(error: error)
            }
        )
    }
}

// MARK: - Custom Source Picker Sheet
private struct SourcePickerSheet: View {
    @Binding var isPresented: Bool
    let theme: Theme
    let anchorFrame: CGRect
    let onLibrary: () -> Void
    let onFiles: () -> Void
    
    @State private var appear = false
    
    var body: some View {
        GeometryReader { geo in
            if isPresented {
                let width = min(geo.size.width * 0.88, 420)
                let startY = min(max(anchorFrame.midY, 0), geo.size.height - 1)
                let targetY = geo.size.height * 0.52
                
                ZStack {
                    Color.black.opacity(appear ? 0.35 : 0)
                        .ignoresSafeArea()
                        .onTapGesture { dismiss() }
                    
                    VStack(spacing: 12) {
                        Text("Upload from")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.top, 4)
                        
                        actionButton(title: "Photo Library", icon: "photo.on.rectangle") {
                            dismiss()
                            onLibrary()
                        }
                        actionButton(title: "Files", icon: "folder") {
                            dismiss()
                            onFiles()
                        }
                        
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.colors.cardStroke, lineWidth: 1))
                                .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(16)
                    .frame(width: width)
                    .background(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.colors.cardStroke, lineWidth: 1))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                    .position(x: geo.size.width / 2, y: appear ? targetY : startY)
                    .opacity(appear ? 1 : 0.6)
                    .onAppear {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            appear = true
                        }
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .allowsHitTesting(isPresented)
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            appear = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            isPresented = false
        }
    }
    
    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.colors.cardStroke, lineWidth: 1))
            .cornerRadius(14)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview
struct CoachOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                CoachOnboardingView()
                    .environmentObject(Theme())
            }
            .previewDisplayName("Application Form")
            .previewDevice("iPhone 15 Pro")
            
            NavigationStack {
                CoachOnboardingView()
                    .environmentObject(Theme())
            }
            .previewDisplayName("Verification Status")
            .previewDevice("iPhone 15 Pro")
        }
    }
}
