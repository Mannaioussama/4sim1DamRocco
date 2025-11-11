//
//  EditProfileViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI
import PhotosUI
import Combine

class EditProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Profile form fields
    @Published var name: String = "Alex Johnson"
    @Published var email: String = "alex.johnson@email.com"
    @Published var phone: String = "+1 (555) 123-4567"
    @Published var bio: String = "Passionate about sports and staying active! Love meeting new people through fitness."
    @Published var location: String = "San Francisco, CA"
    @Published var dateOfBirth: Date = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: "1995-06-15") ?? Calendar.current.date(byAdding: .year, value: -30, to: .now)!
    }()
    
    // Avatar
    @Published var avatarURL: String = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop"
    @Published var pickedItem: PhotosPickerItem?
    @Published var pickedImageData: Data?
    
    // Sports
    @Published var selectedSports: Set<String> = ["Basketball", "Tennis", "Running", "Swimming"]
    
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
    
    // MARK: - Constants
    
    let availableSports: [String] = [
        "Basketball", "Tennis", "Running", "Swimming",
        "Soccer", "Volleyball", "Badminton", "Yoga",
        "Cycling", "Boxing", "Climbing", "Golf"
    ]
    
    let maxBioLength: Int = 200
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Simulation Controls
    
    // Toggle this in previews/tests to simulate API success/failure without triggering compiler warnings.
    var simulateNetworkSuccess: Bool = true
    
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
        return initials.isEmpty ? "A" : initials
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
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Simulate success/failure based on a configurable flag
            let success = self.simulateNetworkSuccess
            
            if success {
                self.successMessage = "Profile updated successfully!"
                self.showSuccessAlert = true
                self.isLoading = false
                onSuccess()
            } else {
                self.errorMessage = "Failed to update profile. Please try again."
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
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            let success = self.simulateNetworkSuccess
            
            if success {
                self.showVerificationSent = true
                self.successMessage = "Verification email sent to \(self.email)"
                self.showSuccessAlert = true
                self.isLoading = false
                onSuccess()
            } else {
                self.errorMessage = "Failed to send verification email. Please try again."
                self.showErrorAlert = true
                self.isLoading = false
                onError(self.errorMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func resetForm() {
        name = "Alex Johnson"
        email = "alex.johnson@email.com"
        phone = "+1 (555) 123-4567"
        bio = "Passionate about sports and staying active! Love meeting new people through fitness."
        location = "San Francisco, CA"
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? Date()
        selectedSports = ["Basketball", "Tennis", "Running", "Swimming"]
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
