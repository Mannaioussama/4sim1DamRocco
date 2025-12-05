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
struct FormData: Codable {
    var name: String = ""
    var bio: String = ""
    var certifications: String = ""
    var experience: String = ""
    var specialization: String = ""
    var location: String = ""
    var website: String = ""
    var email: String = ""
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
    @Published var isCoachAlreadyVerified: Bool = false
    @Published var lastVerificationResponse: CoachVerificationResponse? = nil
    @Published var lastSubmittedForm: FormData? = nil
    @Published var canModifyData: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    private let coachVerificationService = CoachVerificationService.shared
    private let profileAPI = ProfileAPI.shared
    private let tokenManager = AuthTokenManager.shared
    private let userDefaults = UserDefaults.standard
    
    // For local testing you can flip this, but real logic now goes through the API
    private var simulateAPISubmissionSuccess: Bool = true
    
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

    // MARK: - Local Persistence

    private func formStorageKey(for userId: String) -> String {
        "coachVerificationForm_\(userId)"
    }

    private func saveLastForm(_ form: FormData, for userId: String) {
        let key = formStorageKey(for: userId)
        if let data = try? JSONEncoder().encode(form) {
            userDefaults.set(data, forKey: key)
        }
    }

    private func loadLastForm(for userId: String) -> FormData? {
        let key = formStorageKey(for: userId)
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FormData.self, from: data)
    }

    // MARK: - Load Existing Verification Status
    
    func checkIfAlreadyVerified() {
        guard let token = tokenManager.getToken() else { return }
        
        Task {
            do {
                let profile = try await profileAPI.getProfile(token: token)
                await MainActor.run {
                    self.isCoachAlreadyVerified = profile.isCoachVerified ?? false
                    if self.formData.email.isEmpty {
                        self.formData.email = profile.email
                    }
                    if self.formData.name.isEmpty {
                        self.formData.name = profile.name
                    }
                    if self.isCoachAlreadyVerified {
                        self.applyExistingVerificationData(profile.coachVerificationData)
                    }
                    if let userId = self.tokenManager.getUserId(),
                       let savedForm = self.loadLastForm(for: userId) {
                        self.lastSubmittedForm = savedForm
                        self.canModifyData = true
                    }
                }
            } catch {
                print("Failed to load coach verification status: \(error)")
            }
        }
    }

    private func applyExistingVerificationData(_ data: CoachVerificationData?) {
        guard let data = data else { return }
        let confidence = data.confidenceScore ?? 0
        let reasons = data.verificationReasons ?? []
        let response = CoachVerificationResponse(
            isCoach: true,
            confidenceScore: confidence,
            verificationReasons: reasons,
            aiAnalysis: nil,
            documentAnalysis: nil
        )
        // Prefill form fields from stored verification data when available
        if let coachName = data.coachName, !coachName.isEmpty {
            formData.name = coachName
        }
        if let about = data.about, !about.isEmpty {
            formData.bio = about
        }
        if let specialization = data.specialization, !specialization.isEmpty {
            formData.specialization = specialization
        }
        if let years = data.yearsOfExperience, !years.isEmpty {
            formData.experience = years
        }
        if let certs = data.certifications, !certs.isEmpty {
            formData.certifications = certs
        }
        if let location = data.location, !location.isEmpty {
            formData.location = location
        }
        if let note = data.note, !note.isEmpty {
            formData.website = note
        }
        lastVerificationResponse = response
        status = .approved
        step = .status
        canModifyData = true
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
        
        guard let token = tokenManager.getToken(), let userId = tokenManager.getUserId() else {
            errorMessage = "Authentication required to submit coach verification."
            showErrorAlert = true
            return
        }
        
        isLoading = true
        trackApplicationSubmitted()
        // Remember the form that was just submitted so we can prefill it on 'Modify my data'.
        lastSubmittedForm = formData
        canModifyData = true
        saveLastForm(formData, for: userId)
        
        Task {
            do {
                // 1) TODO: upload documents when backend endpoint is available.
                // For now, send an empty documents array so the AI endpoint still works.
                let documentURLs: [String] = []
                
                // 2) Build AI verification request
                let years = formData.experience.isEmpty ? "" : formData.experience
                let request = CoachVerificationRequest(
                    userType: isCoachAccount ? "Coach / Trainer" : "Club Owner",
                    fullName: formData.name,
                    email: formData.email,
                    about: formData.bio,
                    specialization: formData.specialization,
                    yearsOfExperience: years,
                    certifications: formData.certifications,
                    location: formData.location,
                    documents: documentURLs,
                    note: formData.website.isEmpty ? nil : formData.website
                )
                
                // 3) Call AI verification endpoint
                let response = try await coachVerificationService.verifyCoach(token: token, request: request)
                
                if response.isCoach {
                    // 4) Persist verification status in backend profile
                    let reasons = response.verificationReasons
                    let payload = ProfileAPI.CoachVerificationStatusPayload(
                        isCoachVerified: true,
                        coachName: formData.name,
                        confidenceScore: response.confidenceScore,
                        verificationReasons: reasons
                    )
                    _ = try await profileAPI.updateCoachVerificationStatus(userId: userId, token: token, status: payload)
                    
                    await MainActor.run {
                        self.lastVerificationResponse = response
                        withAnimation {
                            self.status = .approved
                            self.step = .status
                        }
                        self.isLoading = false
                        self.trackApplicationSuccess()
                        onSuccess()
                    }
                } else {
                    await MainActor.run {
                        self.lastVerificationResponse = response
                        self.status = .rejected
                        self.isLoading = false
                        self.errorMessage = "We could not verify your coach credentials. Please review your details and documents."
                        self.showErrorAlert = true
                        self.trackApplicationFailed(error: self.errorMessage)
                        onError(self.errorMessage)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    if let apiErr = error as? APIError {
                        self.errorMessage = apiErr.userMessage
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.showErrorAlert = true
                    self.trackApplicationFailed(error: self.errorMessage)
                    onError(self.errorMessage)
                }
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
            if let saved = lastSubmittedForm {
                formData = saved
            }
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
