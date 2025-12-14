//
//  CreateActivityViewModel.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import Combine
import CoreLocation

class CreateActivityViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var showSuccess = false
    @Published var showMapPicker = false
    @Published var isSaving = false
    @Published var sportType = ""
    @Published var title = ""
    @Published var description = ""
    @Published var location = ""
    @Published var locationCoordinate: CLLocationCoordinate2D?
    @Published var date = Date()
    @Published var time = Date()
    @Published var participants = 5.0
    @Published var level = ""
    @Published var visibility = "public"
    @Published var price = ""
    @Published var errorMessage: String?
    
    // MARK: - Constants
    
    let sportCategories = [
        ("⚽️", "Football"),
        ("🏀", "Basketball"),
        ("🏃‍♂️", "Running"),
        ("🚴‍♀️", "Cycling")
    ]
    
    let skillLevels = ["Beginner", "Intermediate", "Advanced"]
    private let localization = LocalizationManager.shared
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        // Core validation used by both CreateActivityView (individual) and CreateSessionView (coach)
        // Price validation is handled per-flow so we don't include it here.
        return !sportType.isEmpty &&
               !title.isEmpty &&
               !location.isEmpty &&
               !level.isEmpty
    }
    
    var participantsCount: Int {
        return Int(participants)
    }
    
    var visibilityDisplayText: String {
        return visibility == "public" ? "Public - Anyone can join" : "Friends Only"
    }
    
    var selectedSportEmoji: String? {
        return sportCategories.first(where: { $0.1 == sportType })?.0
    }
    
    // MARK: - Initialization
    
    init() {
        self.participants = 5.0
        self.visibility = "public"
    }
    
    // MARK: - Actions
    
    func selectSport(_ sportName: String) {
        self.sportType = sportName
    }
    
    func selectLevel(_ levelName: String) {
        self.level = levelName
    }
    
    func setVisibility(_ type: String) {
        self.visibility = type
    }
    
    func setLocation(name: String, coordinate: CLLocationCoordinate2D) {
        self.location = name
        self.locationCoordinate = coordinate
    }
    
    // MARK: - API
    
    func createActivity(using service: ActivityAPIService, isCoachSession: Bool) async {
        guard isFormValid else {
            await MainActor.run {
                self.errorMessage = localization.localized("createActivity.error.requiredFields")
            }
            return
        }
        
        // Determine price behavior based on flow:
        // - Coach sessions (CreateSessionView): price is required and makes it a paid session.
        // - Regular activities (CreateActivityView): treated as individual/free, so price is nil.
        var priceValue: Double? = nil
        if isCoachSession {
            let trimmedPrice = price.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedPrice = trimmedPrice.replacingOccurrences(of: ",", with: ".")
            guard !trimmedPrice.isEmpty, let parsed = Double(normalizedPrice), parsed >= 0 else {
                await MainActor.run {
                    self.errorMessage = localization.localized("createSession.error.invalidPrice")
                }
                return
            }
            priceValue = parsed
        }
        
        await MainActor.run {
            self.isSaving = true
            self.errorMessage = nil
        }
        
        let dateString = formatDateForAPI(date)
        let timeString = formatTimeForAPI(time)
        
        let success = await service.createActivity(
            title: title,
            sportType: sportType,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description,
            location: location,
            date: dateString,
            time: timeString,
            participants: participantsCount,
            level: level,
            visibility: visibility,
            latitude: locationCoordinate?.latitude,
            longitude: locationCoordinate?.longitude,
            price: priceValue
        )
        
        await MainActor.run {
            self.isSaving = false
            if success {
                self.showSuccess = true
            } else {
                if let apiError = service.error, !apiError.isEmpty {
                    self.errorMessage = apiError
                } else {
                    let key = isCoachSession ? "createSession.error.submitFailed" : "createActivity.error.submitFailed"
                    self.errorMessage = localization.localized(key)
                }
            }
        }
    }
    
    func buildShareText(isCoachSession: Bool) -> String {
        let titleKey = isCoachSession ? "share.session.inviteTitle" : "share.activity.inviteTitle"
        let inviteTitle = localization.localized(titleKey)
        var lines: [String] = []
        lines.append(inviteTitle)
        lines.append("")

        let emoji = selectedSportEmoji ?? "🏅"
        let mainTitle: String
        if !title.isEmpty {
            mainTitle = title
        } else if !sportType.isEmpty {
            mainTitle = sportType
        } else {
            mainTitle = ""
        }
        if !mainTitle.isEmpty {
            lines.append("\(emoji) \(mainTitle)")
        }

        if !sportType.isEmpty {
            lines.append("\(localization.localized("share.activity.sportLabel")) \(sportType)")
        }
        if !location.isEmpty {
            lines.append("\(localization.localized("share.activity.locationLabel")) \(location)")
        }

        let df = DateFormatter()
        df.dateStyle = .medium
        let dateString = df.string(from: date)
        let tf = DateFormatter()
        tf.timeStyle = .short
        let timeString = tf.string(from: time)

        lines.append("\(localization.localized("share.activity.dateLabel")) \(dateString)")
        lines.append("\(localization.localized("share.activity.timeLabel")) \(timeString)")

        if isCoachSession {
            let trimmedPrice = price.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedPrice = trimmedPrice.replacingOccurrences(of: ",", with: ".")
            if let parsed = Double(normalizedPrice) {
                let priceString = String(format: "$%.2f", parsed)
                lines.append("\(localization.localized("share.activity.priceLabel")) \(priceString)")
            }
        }

        lines.append("")
        lines.append(localization.localized("share.common.appSuffix"))
        return lines.joined(separator: "\n")
    }
    
    func resetForm() {
        sportType = ""
        title = ""
        description = ""
        location = ""
        locationCoordinate = nil
        date = Date()
        time = Date()
        participants = 5.0
        level = ""
        visibility = "public"
        showSuccess = false
        showMapPicker = false
        isSaving = false
        errorMessage = nil
    }
    
    // MARK: - Helpers
    
    private func formatDateForAPI(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    private func formatTimeForAPI(_ date: Date) -> String {
        // ActivityAPIService will convert this display string to ISO internally.
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"
        return tf.string(from: date)
    }
}
