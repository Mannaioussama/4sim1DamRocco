//
//  EditProfileViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import SwiftUI
import PhotosUI
import Combine

class EditProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Profile form fields
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var bio: String = ""
    @Published var location: String = ""
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? Date()
    
    // Avatar
    @Published var avatarURL: String = ""
    @Published var pickedItem: PhotosPickerItem?
    @Published var pickedImageData: Data?
    
    // Sports
    @Published var selectedSports: Set<String> = []
    
    // Email verification
    @Published var emailVerified: Bool = false
    @Published var showVerificationSent: Bool = false
    
    // Loading and errors
    @Published var isLoading: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSuccessAlert: Bool = false
    @Published var successMessage: String = ""
    
    // Form validation errors
    @Published var nameError: String = ""
    @Published var emailError: String = ""
    @Published var phoneError: String = ""
    @Published var locationError: String = ""
    
    // MARK: - Dependencies
    
    private let profileAPI = ProfileAPI.shared
    private let tokenStore = KeychainTokenStore.shared
    
    // MARK: - Constants
    
    let availableSports: [String] = [
        "Basketball", "Tennis", "Running", "Swimming",
        "Soccer", "Volleyball", "Badminton", "Yoga",
        "Cycling", "Boxing", "Climbing", "Golf"
    ]
    
    let maxBioLength: Int = 200
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    private var originalEmail: String = ""  // Track original email to detect changes
    
    // MARK: - Computed Properties
    
    var bioCharacterCount: Int {
        return bio.count
    }
    
    var bioCharacterCountText: String {
        return "\(bioCharacterCount)/\(maxBioLength) characters"
    }
    
    var isBioTooLong: Bool {
        return bioCharacterCount > maxBioLength
    }
    
    var hasSelectedSports: Bool {
        return !selectedSports.isEmpty
    }
    
    var selectedSportsCount: Int {
        return selectedSports.count
    }
    
    var hasPickedNewPhoto: Bool {
        return pickedImageData != nil
    }
    
    var displayInitials: String {
        let initials = name.split(separator: " ").compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "?" : initials.uppercased()
    }
    
    var canSave: Bool {
        return !hasValidationErrors() && !isLoading
    }
    
    var emailVerificationTitle: String {
        return emailVerified ? "Email Verified" : "Verify Your Email"
    }
    
    var emailVerificationMessage: String {
        return emailVerified
            ? "Your email \(email) has been verified."
            : "Please verify \(email) to unlock all features and secure your account."
    }
    
    var emailVerificationIcon: String {
        return emailVerified ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
    }
    
    var emailVerificationColor: String {
        return emailVerified ? "2ECC71" : "F39C12"
    }
    
    var emailVerificationGlowColors: [String] {
        return emailVerified ? ["2ECC71", "27AE60"] : ["F39C12", "E67E22"]
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        loadUserProfile()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Clear errors when typing
        $name
            .sink { [weak self] _ in
                self?.nameError = ""
            }
            .store(in: &cancellables)
        
        $email
            .sink { [weak self] _ in
                self?.emailError = ""
            }
            .store(in: &cancellables)
        
        $phone
            .sink { [weak self] _ in
                self?.phoneError = ""
            }
            .store(in: &cancellables)
        
        $location
            .sink { [weak self] _ in
                self?.locationError = ""
            }
            .store(in: &cancellables)
        
        // Enforce bio character limit
        $bio
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if newValue.count > self.maxBioLength {
                    self.bio = String(newValue.prefix(self.maxBioLength))
                }
            }
            .store(in: &cancellables)
        
        // Load photo when picked item changes
        $pickedItem
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadPickedPhoto()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load User Profile
    
    func loadUserProfile() {
        Task { @MainActor in
            guard let token = tokenStore.getAccessToken() else {
                print("No access token found")
                return
            }
            
            do {
                let user = try await profileAPI.getProfile(token: token)
                
                // Update UI with user data
                self.currentUserId = user.id
                self.name = user.name
                self.email = user.email
                self.originalEmail = user.email
                self.phone = user.phone ?? ""
                self.bio = user.about ?? ""
                self.location = user.location
                self.emailVerified = user.isEmailVerified
                self.avatarURL = user.profileImageUrl ?? ""
                
                // Parse date of birth
                if let dobString = user.dateOfBirth,
                   let date = Date.fromBackendDateString(dobString) {
                    self.dateOfBirth = date
                }
                
                // Parse sports interests
                if let sports = user.sportsInterests {
                    self.selectedSports = Set(sports)
                }
                
            } catch {
                print("Failed to load profile: \(error.localizedDescription)")
                self.errorMessage = "Failed to load profile. Please try again."
                self.showErrorAlert = true
            }
        }
    }
    
    // MARK: - Photo Management
    
    func loadPickedPhoto() async {
        guard let item = pickedItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                pickedImageData = data
            }
        }
    }
    
    func clearPickedPhoto() {
        pickedItem = nil
        pickedImageData = nil
    }
    
    // MARK: - Sports Management
    
    func toggleSport(_ sport: String) {
        if selectedSports.contains(sport) {
            selectedSports.remove(sport)
        } else {
            selectedSports.insert(sport)
        }
    }
    
    func isSportSelected(_ sport: String) -> Bool {
        return selectedSports.contains(sport)
    }
    
    func selectAllSports() {
        selectedSports = Set(availableSports)
    }
    
    func deselectAllSports() {
        selectedSports.removeAll()
    }
    
    // MARK: - Validation
    
    func validateName() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "Name is required"
            return false
        }
        if name.count < 2 {
            nameError = "Name must be at least 2 characters"
            return false
        }
        nameError = ""
        return true
    }
    
    func validateEmail() -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            emailError = "Email is required"
            return false
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: trimmed) {
            emailError = "Please enter a valid email address"
            return false
        }
        
        emailError = ""
        return true
    }
    
    func validatePhone() -> Bool {
        // Phone is optional, so only validate if not empty
        if !phone.trimmingCharacters(in: .whitespaces).isEmpty {
            // Basic validation - just check it has some digits
            let digits = phone.filter { $0.isNumber }
            if digits.count < 10 {
                phoneError = "Please enter a valid phone number"
                return false
            }
        }
        phoneError = ""
        return true
    }
    
    func validateLocation() -> Bool {
        if location.trimmingCharacters(in: .whitespaces).isEmpty {
            locationError = "Location is required"
            return false
        }
        locationError = ""
        return true
    }
    
    func hasValidationErrors() -> Bool {
        let isNameValid = validateName()
        let isEmailValid = validateEmail()
        let isPhoneValid = validatePhone()
        let isLocationValid = validateLocation()
        
        return !(isNameValid && isEmailValid && isPhoneValid && isLocationValid)
    }
    
    // MARK: - Save Profile
    
    func saveProfile(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        guard !hasValidationErrors() else {
            errorMessage = "Please fix the errors before saving"
            showErrorAlert = true
            return
        }
        
        if isBioTooLong {
            errorMessage = "Bio is too long. Maximum \(maxBioLength) characters allowed."
            showErrorAlert = true
            return
        }
        
        guard let userId = currentUserId else {
            errorMessage = "User ID not found. Please log in again."
            showErrorAlert = true
            return
        }
        
        guard let token = tokenStore.getAccessToken() else {
            errorMessage = "Not authenticated. Please log in again."
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                // Step 1: Upload profile image if changed
                if let imageData = pickedImageData {
                    _ = try await profileAPI.uploadProfileImage(
                        userId: userId,
                        token: token,
                        imageData: imageData
                    )
                }
                
                // Step 2: Update profile data
                let request = UpdateProfileRequest(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    phone: phone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
                    dateOfBirth: dateOfBirth.toBackendDateString(),
                    location: location.trimmingCharacters(in: .whitespaces),
                    about: bio.trimmingCharacters(in: .whitespaces).isEmpty ? nil : bio.trimmingCharacters(in: .whitespaces),
                    sportsInterests: Array(selectedSports)
                )
                
                let updatedUser = try await profileAPI.updateProfile(
                    userId: userId,
                    token: token,
                    request: request
                )
                
                // Update local state with response
                self.avatarURL = updatedUser.profileImageUrl ?? self.avatarURL
                self.emailVerified = updatedUser.isEmailVerified
                
                // Check if email changed (user will need to verify new email)
                if email != originalEmail {
                    self.emailVerified = false
                    self.originalEmail = email
                }
                
                // Clear picked image data after successful upload
                self.pickedImageData = nil
                self.pickedItem = nil
                
                self.successMessage = "Profile updated successfully!"
                self.showSuccessAlert = true
                self.isLoading = false
                
                // Notify others (e.g., Profile page) that profile has updated
                NotificationCenter.default.post(name: .profileDidUpdate, object: updatedUser)
                
                onSuccess()
                
            } catch let error as APIError {
                // Handle APIError specifically
                self.errorMessage = error.userMessage
                self.showErrorAlert = true
                self.isLoading = false
                onError(self.errorMessage)
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                self.isLoading = false
                onError(self.errorMessage)
            }
        }
    }
    
    // MARK: - Email Verification
    
    func sendVerificationEmail(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        guard validateEmail() else {
            errorMessage = "Please enter a valid email address"
            showErrorAlert = true
            return
        }
        
        guard let token = tokenStore.getAccessToken() else {
            errorMessage = "Not authenticated. Please log in again."
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                let message = try await profileAPI.sendVerificationEmail(
                    email: email,
                    token: token
                )
                
                self.showVerificationSent = true
                self.successMessage = message
                self.showSuccessAlert = true
                self.isLoading = false
                
                onSuccess()
                
            } catch let error as APIError {
                self.errorMessage = error.userMessage
                self.showErrorAlert = true
                self.isLoading = false
                onError(self.errorMessage)
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
                self.isLoading = false
                onError(self.errorMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func resetForm() {
        loadUserProfile()  // Reload from server
        clearPickedPhoto()
        clearAllErrors()
    }
    
    func clearAllErrors() {
        nameError = ""
        emailError = ""
        phoneError = ""
        locationError = ""
    }
    
    // MARK: - Analytics
    
    func trackScreenView() {
        // TODO: Implement analytics tracking
        print("Edit profile screen viewed")
    }
    
    func trackProfileSaved() {
        // TODO: Implement analytics tracking
        print("Profile saved successfully")
    }
    
    func trackProfileSaveFailed(error: String) {
        // TODO: Implement analytics tracking
        print("Profile save failed: \(error)")
    }
    
    func trackPhotoChanged() {
        // TODO: Implement analytics tracking
        print("Profile photo changed")
    }
    
    func trackSportToggled(_ sport: String, selected: Bool) {
        // TODO: Implement analytics tracking
        print("Sport \(sport) \(selected ? "selected" : "deselected")")
    }
    
    func trackVerificationEmailSent() {
        // TODO: Implement analytics tracking
        print("Verification email sent")
    }
    
    func trackFieldEdited(_ field: String) {
        // TODO: Implement analytics tracking
        print("Field edited: \(field)")
    }
}

