import Foundation
import SwiftUI

struct AISuggestion: Codable, Identifiable {
    let id: String
    let title: String
    let sportType: String
    let location: String
    let date: String
    let time: String
    let participants: Int
    let maxParticipants: Int
    let level: String
    let matchScore: Int
    let reason: String?
    
    var matchScoreColor: Color {
        if matchScore >= 80 {
            return .green
        } else if matchScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    var matchScoreText: String {
        "\(matchScore)% match"
    }
    
    var formattedDate: String {
        // Backend already returns formatted date (DD/MM/YYYY)
        date
    }
    
    var formattedTime: String {
        // Backend already returns formatted time (HH:MM)
        time
    }
    
    var isAvailable: Bool {
        participants < maxParticipants
    }
}

struct AISuggestionsResponse: Codable {
    let suggestions: [AISuggestion]
    let personalizedTips: [PersonalizedTip]?

    private enum CodingKeys: String, CodingKey {
        case suggestions
        case personalizedTips
    }

    init(suggestions: [AISuggestion], personalizedTips: [PersonalizedTip]?) {
        self.suggestions = suggestions
        self.personalizedTips = personalizedTips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let decodedSuggestions = try? container.decode([AISuggestion].self, forKey: .suggestions) {
            self.suggestions = decodedSuggestions
        } else {
            self.suggestions = []
        }

        self.personalizedTips = try? container.decodeIfPresent([PersonalizedTip].self, forKey: .personalizedTips)
    }
}
