//
//  CoachOnboardingViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import Combine

// MARK: - Enums
enum CoachVerificationStatus {
    case notApplied, pending, approved, rejected
}

enum OnboardingStep {
    case application
    case status
}

// MARK: - Data Models
struct FormData {
    var name: String = ""
    var bio: String = ""
    var certifications: String = ""
    var experience: String = ""
    var specialization: String = ""
    var location: String = ""
    var website: String = ""
}

struct StatusConfig {
    let icon: String
    let color: Color
    let bg: LinearGradient
    let border: Color
    let title: String
    let message: String
}

class CoachOnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var step: OnboardingStep = .application
    @Published var status: CoachVerificationStatus = .notApplied
    @Published var accountType: String = "coach"
    @Published var formData = FormData()
    @Published var documents: [PickedImage] = []
    @Published var uploadButtonFrame: CGRect = .zero
    
    // Picker states
    @Published var showSourceSheet: Bool = false
    @Published var showLibraryPicker: Bool = false
    @Published var showFilesPicker: Bool = false
    
    // Loading and errors
    @Published var isLoading: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    
    // Form validation errors
    @Published var nameError: String = ""
    @Published var bioError: String = ""
    @Published var specializationError: String = ""
    @Published var experienceError: String = ""
    @Published var certificationsError: String = ""
    @Published var locationError: String = ""
    @Published var documentsError: String = ""
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isApplicationStep: Bool {
        return step == .application
    }
    
    var isStatusStep: Bool {
        return step == .status
    }
    
    var isCoachAccount: Bool {
        return accountType == "coach"
    }
    
    var isClubAccount: Bool {
        return accountType == "club"
    }
    
    var nameLabel: String {
        return isCoachAccount ? "Full Name *" : "Club Name *"
    }
    
    var namePlaceholder: String {
        return isCoachAccount ? "John Smith" : "SportHub LA"
    }
    
    var bioPlaceholder: String {
        return isCoachAccount
            ? "Tell us about your coaching experience and philosophy..."
            : "Describe your club, facilities, and what makes you special..."
    }
    
    var specializationLabel: String {
        return isCoachAccount ? "Specialization *" : "Sport Focus *"
    }
    
    var specializationPlaceholder: String {
        return isCoachAccount ? "Running, Fitness" : "Tennis, Swimming"
    }
    
    var certificationsLabel: String {
        return "Certifications / License *"
    }
    
    var certificationsPlaceholder: String {
        return isCoachAccount ? "NASM CPT, ACE, etc." : "Business License Number"
    }
    
    var hasDocuments: Bool {
        return !documents.isEmpty
    }
    
    var documentCount: Int {
        return documents.count
    }
    
    var canSubmit: Bool {
        return validateForm()
    }
    
    var navigationTitle: String {
        return isApplicationStep ? "Apply for Verification" : "Verification Status"
    }
    
    var verifiedBadgeText: String {
        return "✓ Verified \(isCoachAccount ? "Coach" : "Club")"
    }
    
    var experienceOptions: [(String, String)] {
        return [
            ("", "Select years"),
            ("1-2", "1-2 years"),
            ("3-5", "3-5 years"),
            ("5-10", "5-10 years"),
            ("10+", "10+ years")
        ]
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Clear errors when typing
        $formData
            .sink { [weak self] _ in
                self?.clearFormErrors()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Account Type
    
    func selectAccountType(_ type: String) {
        accountType = type
        // Clear form when switching account types
        formData = FormData()
        clearAllErrors()
    }
    
    func isAccountTypeSelected(_ type: String) -> Bool {
        return accountType == type
    }
    
    // MARK: - Document Management
    
    func openSourceSheet(buttonFrame: CGRect) {
        uploadButtonFrame = buttonFrame
        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
            showSourceSheet = true
        }
    }
    
    func closeSourceSheet() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            showSourceSheet = false
        }
    }
    
    func openLibraryPicker() {
        closeSourceSheet()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showLibraryPicker = true
        }
    }
    
    func openFilesPicker() {
        closeSourceSheet()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showFilesPicker = true
        }
    }
    
    func addDocument(_ picked: PickedImage) {
        documents.append(picked)
        documentsError = ""
    }
    
    func removeDocument(at index: Int) {
        guard index < documents.count else { return }
        documents.remove(at: index)
    }
    
    // MARK: - Validation
    
    private func clearFormErrors() {
        nameError = ""
        bioError = ""
        specializationError = ""
        experienceError = ""
        certificationsError = ""
        locationError = ""
        // Don't clear documents error automatically
    }
    
    func clearAllErrors() {
        clearFormErrors()
        documentsError = ""
    }
    
    func validateName() -> Bool {
        if formData.name.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = isCoachAccount ? "Full name is required" : "Club name is required"
            return false
        }
        nameError = ""
        return true
    }
    
    func validateBio() -> Bool {
        if formData.bio.trimmingCharacters(in: .whitespaces).isEmpty {
            bioError = "About section is required"
            return false
        }
        if formData.bio.count < 20 {
            bioError = "Please provide at least 20 characters"
            return false
        }
        bioError = ""
        return true
    }
    
    func validateSpecialization() -> Bool {
        if formData.specialization.trimmingCharacters(in: .whitespaces).isEmpty {
            specializationError = isCoachAccount ? "Specialization is required" : "Sport focus is required"
            return false
        }
        specializationError = ""
        return true
    }
    
    func validateExperience() -> Bool {
        if formData.experience.isEmpty {
            experienceError = "Please select years of experience"
            return false
        }
        experienceError = ""
        return true
    }
    
    func validateCertifications() -> Bool {
        if formData.certifications.trimmingCharacters(in: .whitespaces).isEmpty {
            certificationsError = isCoachAccount ? "Certifications are required" : "License is required"
            return false
        }
        certificationsError = ""
        return true
    }
    
    func validateLocation() -> Bool {
        if formData.location.trimmingCharacters(in: .whitespaces).isEmpty {
            locationError = "Location is required"
            return false
        }
        locationError = ""
        return true
    }
    
    func validateDocuments() -> Bool {
        if documents.isEmpty {
            documentsError = "Please upload at least one verification document"
            return false
        }
        documentsError = ""
        return true
    }
    
    func validateForm() -> Bool {
        let isNameValid = validateName()
        let isBioValid = validateBio()
        let isSpecializationValid = validateSpecialization()
        let isExperienceValid = validateExperience()
        let isCertificationsValid = validateCertifications()
        let isLocationValid = validateLocation()
        let areDocumentsValid = validateDocuments()
        
        return isNameValid && isBioValid && isSpecializationValid &&
               isExperienceValid && isCertificationsValid &&
               isLocationValid && areDocumentsValid
    }
    
    // MARK: - Submit Application
    
    func submitApplication(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        guard validateForm() else {
            errorMessage = "Please fill in all required fields"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // Simulate success (replace with actual API call)
            let success = true
            
            if success {
                withAnimation {
                    self.status = .pending
                    self.step = .status
                }
                self.isLoading = false
                onSuccess()
            } else {
                self.errorMessage = "Failed to submit application. Please try again."
                self.showErrorAlert = true
                self.isLoading = false
                onError(self.errorMessage)
            }
        }
    }
    
    // MARK: - Status Management
    
    func goToStatusStep() {
        withAnimation {
            step = .status
        }
    }
    
    func goToApplicationStep() {
        withAnimation {
            step = .application
        }
    }
    
    func reapply() {
        withAnimation {
            step = .application
            status = .notApplied
            clearAllErrors()
        }
    }
    
    func getStatusConfig(isDarkMode: Bool) -> StatusConfig {
        switch status {
        case .pending:
            return StatusConfig(
                icon: "clock",
                color: .orange,
                bg: LinearGradient(
                    colors: [
                        .yellow.opacity(isDarkMode ? 0.18 : 0.2),
                        .orange.opacity(isDarkMode ? 0.16 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                border: .orange.opacity(0.35),
                title: "Verification Pending",
                message: "Your application is under review. We typically respond within 2–3 business days."
            )
            
        case .approved:
            return StatusConfig(
                icon: "checkmark.circle",
                color: .green,
                bg: LinearGradient(
                    colors: [
                        .green.opacity(isDarkMode ? 0.18 : 0.2),
                        .mint.opacity(isDarkMode ? 0.16 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                border: .green.opacity(0.35),
                title: "Verified!",
                message: "Congratulations! Your account has been verified. You can now create paid sessions and access coach features."
            )
            
        case .rejected:
            return StatusConfig(
                icon: "xmark.circle",
                color: .red,
                bg: LinearGradient(
                    colors: [
                        .red.opacity(isDarkMode ? 0.18 : 0.2),
                        .pink.opacity(isDarkMode ? 0.16 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                border: .red.opacity(0.35),
                title: "Application Rejected",
                message: "Unfortunately, we couldn't verify your credentials. Please review your information and reapply."
            )
            
        case .notApplied:
            return StatusConfig(
                icon: "",
                color: .clear,
                bg: LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                border: .clear,
                title: "",
                message: ""
            )
        }
    }
    
    // MARK: - Helper Methods
    
    func resetForm() {
        formData = FormData()
        documents = []
        clearAllErrors()
        accountType = "coach"
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Coach onboarding screen viewed - step: \(step)")
    }
    
    func trackAccountTypeSelected(_ type: String) {
        // TODO: Implement analytics tracking
        print("Account type selected: \(type)")
    }
    
    func trackDocumentUploaded() {
        // TODO: Implement analytics tracking
        print("Document uploaded - total: \(documents.count)")
    }
    
    func trackDocumentRemoved() {
        // TODO: Implement analytics tracking
        print("Document removed - total: \(documents.count)")
    }
    
    func trackApplicationSubmitted() {
        // TODO: Implement analytics tracking
        print("Application submitted - account type: \(accountType)")
    }
    
    func trackApplicationSuccess() {
        // TODO: Implement analytics tracking
        print("Application submitted successfully")
    }
    
    func trackApplicationFailed(error: String) {
        // TODO: Implement analytics tracking
        print("Application submission failed: \(error)")
    }
    
    func trackReapply() {
        // TODO: Implement analytics tracking
        print("User clicked reapply")
    }
    
    func trackDashboardNavigation() {
        // TODO: Implement analytics tracking
        print("User navigated to dashboard after approval")
    }
}
