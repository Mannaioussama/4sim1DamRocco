import Foundation
import SwiftUI

struct PersonalizedTip: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: String
    let priority: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, description, icon, category, priority
    }

    init(id: String, title: String, description: String, icon: String, category: String, priority: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.priority = priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            self.id = UUID().uuidString
        }

        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.category = try container.decode(String.self, forKey: .category)
        self.priority = try? container.decodeIfPresent(String.self, forKey: .priority)
    }
    
    var categoryColor: Color {
        switch category.lowercased() {
        case "training": return .blue
        case "nutrition": return .orange
        case "recovery": return .purple
        case "motivation": return .red
        case "health": return .green
        default: return .gray
        }
    }
    
    var priorityColor: Color {
        switch priority?.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "training": return "figure.run"
        case "nutrition": return "fork.knife"
        case "recovery": return "bed.double.fill"
        case "motivation": return "flame.fill"
        case "health": return "heart.fill"
        default: return "lightbulb.fill"
        }
    }
}

struct PersonalizedTipsResponse: Codable {
    let tips: [PersonalizedTip]

    private enum CodingKeys: String, CodingKey { case tips }

    init(tips: [PersonalizedTip]) {
        self.tips = tips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedTips = try? container.decode([PersonalizedTip].self, forKey: .tips) {
            self.tips = decodedTips
        } else {
            self.tips = []
        }
    }
}
