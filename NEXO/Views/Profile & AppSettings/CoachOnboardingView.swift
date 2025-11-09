//
//  CoachOnboardingView.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//
//  This file defines the CoachOnboardingView — a SwiftUI implementation of the
//  coach/club verification onboarding flow with gradient glassmorphism design.
//

import SwiftUI

// MARK: - Verification State
enum CoachVerificationStatus {
    case notApplied, pending, approved, rejected
}

// MARK: - Main View
struct CoachOnboardingView: View {
    @EnvironmentObject private var theme: Theme

    @State private var step: String = "application"
    @State private var status: CoachVerificationStatus = .notApplied
    @State private var accountType: String = "coach"
    @State private var formData = FormData()
    
    // MARK: - Document Upload (Option A: add one at a time)
    @State private var showSourceSheet = false
    @State private var showLibraryPicker = false
    @State private var showFilesPicker = false
    @State private var documents: [PickedImage] = [] // multiple certificates/images
    
    // Capture Upload button position to start the sheet animation near the tap
    @State private var uploadButtonFrame: CGRect = .zero
    
    var onBack: (() -> Void)?
    var onComplete: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Themed background + floating orbs
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
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
            
            VStack(spacing: 0) {
                if step == "application" {
                    ScrollView(showsIndicators: false) {
                        formSection
                            .padding()
                    }
                } else {
                    statusSection
                }
            }
        }
        .navigationTitle(step == "application" ? "Apply for Verification" : "Verification Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                theme.colors.cardBackground,
                                in: Circle()
                            )
                            .background(
                                theme.colors.barMaterial,
                                in: Circle()
                            )
                            .overlay(
                                Circle().stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        // MARK: - Pickers
        .sheet(isPresented: $showLibraryPicker) {
            PhotoLibraryPicker(
                onPick: { picked in
                    documents.append(picked)
                },
                onCancel: { /* no-op */ }
            )
        }
        .sheet(isPresented: $showFilesPicker) {
            FilesImagePicker(
                onPick: { picked in
                    documents.append(picked)
                },
                onCancel: { /* no-op */ }
            )
        }
        // MARK: - Custom Source Sheet Overlay
        .overlay {
            SourcePickerSheet(
                isPresented: $showSourceSheet,
                theme: theme,
                anchorFrame: uploadButtonFrame,
                onLibrary: { showLibraryPicker = true },
                onFiles: { showFilesPicker = true }
            )
        }
    }
    
    // MARK: Application Form
    private var formSection: some View {
        VStack(spacing: 18) {
            // Account type buttons
            VStack(alignment: .leading, spacing: 6) {
                Text("I am a *")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
                HStack(spacing: 12) {
                    accountTypeButton(icon: "rosette", title: "Coach / Trainer", value: "coach")
                    accountTypeButton(icon: "building.2", title: "Club Owner", value: "club")
                }
            }
            
            textField(label: accountType == "coach" ? "Full Name *" : "Club Name *",
                      placeholder: accountType == "coach" ? "John Smith" : "SportHub LA",
                      text: $formData.name)
            
            textArea(label: "About *",
                     placeholder: accountType == "coach"
                     ? "Tell us about your coaching experience and philosophy..."
                     : "Describe your club, facilities, and what makes you special...",
                     text: $formData.bio)
            
            textField(label: accountType == "coach" ? "Specialization *" : "Sport Focus *",
                      placeholder: accountType == "coach" ? "Running, Fitness" : "Tennis, Swimming",
                      text: $formData.specialization)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Years of Experience *")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
                Picker("", selection: $formData.experience) {
                    Text("Select years").tag("")
                    Text("1-2 years").tag("1-2")
                    Text("3-5 years").tag("3-5")
                    Text("5-10 years").tag("5-10")
                    Text("10+ years").tag("10+")
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    theme.colors.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .background(
                    theme.colors.barMaterial,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.colors.cardStroke, lineWidth: 1))
            }
            
            textField(label: "Certifications / License *",
                      placeholder: accountType == "coach" ? "NASM CPT, ACE, etc." : "Business License Number",
                      text: $formData.certifications)
            
            textField(label: "Location *",
                      placeholder: "City, State",
                      text: $formData.location)
            
            textField(label: "Website / Social Media",
                      placeholder: "https://...",
                      text: $formData.website)
            
            // MARK: - Upload Verification Documents
            uploadButton
            // Preview of selected documents
            if !documents.isEmpty {
                documentsPreview
            }
            
            submitButton
        }
    }
    
    private func accountTypeButton(icon: String, title: String, value: String) -> some View {
        Button(action: { accountType = value }) {
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
                        accountType == value
                        ? AnyShapeStyle(
                            LinearGradient(colors: [
                                theme.colors.accentPurple.opacity(0.2),
                                theme.colors.accentPurpleLight.opacity(0.15)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        : AnyShapeStyle(theme.colors.cardBackground)
                    )
            )
            .background(
                theme.colors.barMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accountType == value ? theme.colors.accentPurple.opacity(0.5) : theme.colors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func textField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textPrimary)
                .padding()
                .background(
                    theme.colors.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .background(
                    theme.colors.barMaterial,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.colors.cardStroke, lineWidth: 1))
        }
    }
    
    private func textArea(label: String, placeholder: String, text: Binding<String>) -> some View {
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
                    .background(
                        theme.colors.cardBackground,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .background(
                        theme.colors.barMaterial,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.colors.cardStroke, lineWidth: 1))
            }
        }
    }
    
    private var uploadButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upload Verification Documents *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
            GeometryReader { proxy in
                Button(action: {
                    // Save button frame in global coordinates for animation origin
                    let frame = proxy.frame(in: .global)
                    uploadButtonFrame = frame
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                        showSourceSheet = true
                    }
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
                    .background(
                        theme.colors.cardBackground,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .background(
                        theme.colors.barMaterial,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.colors.cardStroke, style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .frame(height: 120) // reserve space for GeometryReader
        }
    }
    
    // MARK: - Documents preview grid
    private var documentsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Documents")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            // Adaptive grid
            let columns = [
                GridItem(.adaptive(minimum: 92), spacing: 10)
            ]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(documents.enumerated()), id: \.offset) { index, doc in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: doc.uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 92)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .background(theme.colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        
                        Button {
                            documents.remove(at: index)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(width: 24, height: 24)
                                .background(theme.colors.cardBackground)
                                .overlay(
                                    Circle().stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
    
    private var submitButton: some View {
        Button(action: {
            withAnimation {
                status = .pending
                step = "status"
            }
        }) {
            HStack {
                Image(systemName: "doc.text")
                Text("Submit Application")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                LinearGradient(colors: [Color(hex: "#3498DB"), Color(hex: "#2980B9")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(50)
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .padding(.top, 8)
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: Status View
    private var statusSection: some View {
        let config = getStatusConfig()
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
                        .background(
                            theme.colors.cardBackground,
                            in: Circle()
                        )
                        .background(
                            theme.colors.barMaterial,
                            in: Circle()
                        )
                        .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))
                    
                    Text(config.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(config.message)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if status == .approved {
                        Text("✓ Verified \(accountType == "coach" ? "Coach" : "Club")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(LinearGradient(colors: [theme.colors.accentPurple, theme.colors.accentPink],
                                                       startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(50)
                        
                        Button("Go to Dashboard") {
                            onComplete?()
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            LinearGradient(colors: [theme.colors.accentGreenFill, theme.colors.accentGreenGlow],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(50)
                        .padding(.horizontal)
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    if status == .rejected {
                        Button("Reapply") {
                            withAnimation {
                                step = "application"
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            theme.colors.cardBackground,
                            in: Capsule()
                        )
                        .background(
                            theme.colors.barMaterial,
                            in: Capsule()
                        )
                        .overlay(RoundedRectangle(cornerRadius: 50).stroke(theme.colors.cardStroke, lineWidth: 1))
                        .foregroundColor(theme.colors.textPrimary)
                        .cornerRadius(50)
                        .padding(.horizontal)
                        .buttonStyle(ScaleButtonStyle())
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
    
    private var verifiedBenefits: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.colors.cardBackground)
                    .background(
                        theme.colors.barMaterial,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
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
    
    // MARK: Status Config
    private func getStatusConfig() -> (icon: String, color: Color, bg: LinearGradient, border: Color, title: String, message: String) {
        switch status {
        case .pending:
            return ("clock", .orange,
                    LinearGradient(colors: [.yellow.opacity(theme.isDarkMode ? 0.18 : 0.2), .orange.opacity(theme.isDarkMode ? 0.16 : 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    .orange.opacity(0.35),
                    "Verification Pending",
                    "Your application is under review. We typically respond within 2–3 business days.")
        case .approved:
            return ("checkmark.circle", .green,
                    LinearGradient(colors: [.green.opacity(theme.isDarkMode ? 0.18 : 0.2), .mint.opacity(theme.isDarkMode ? 0.16 : 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    .green.opacity(0.35),
                    "Verified!",
                    "Congratulations! Your account has been verified. You can now create paid sessions and access coach features.")
        case .rejected:
            return ("xmark.circle", .red,
                    LinearGradient(colors: [.red.opacity(theme.isDarkMode ? 0.18 : 0.2), .pink.opacity(theme.isDarkMode ? 0.16 : 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    .red.opacity(0.35),
                    "Application Rejected",
                    "Unfortunately, we couldn’t verify your credentials. Please review your information and reapply.")
        case .notApplied:
            return ("", .clear,
                    LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                    .clear,
                    "", "")
        }
    }
    
    // MARK: Floating Orb
    private func orb(color1: Color, color2: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(LinearGradient(colors: [color1, color2],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
        .frame(width: size, height: size)
        .blur(radius: 60)
        .offset(x: x, y: y)
        .opacity(0.8)
        .allowsHitTesting(false)
    }
}

// MARK: - Helpers
struct FormData {
    var name = ""
    var bio = ""
    var certifications = ""
    var experience = ""
    var specialization = ""
    var location = ""
    var website = ""
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
                
                // Start position near the upload button, end position slightly above center
                let startY = min(max(anchorFrame.midY, 0), geo.size.height - 1)
                let targetY = geo.size.height * 0.52 // slightly above center
                
                ZStack {
                    // Dim background
                    Color.black.opacity(appear ? 0.35 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismiss()
                        }
                    
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(16)
                    .frame(width: width)
                    .background(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                    .position(x: geo.size.width / 2,
                              y: appear ? targetY : startY)
                    .opacity(appear ? 1 : 0.6)
                    .onAppear {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            appear = true
                        }
                    }
                }
                // prevent touches behind
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
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
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
            .previewDisplayName("Verification Status (Pending)")
            .previewDevice("iPhone 15 Pro")
        }
    }
}
