//
//  Theme.swift
//  NEXO
//
//  Created by ChatGPT on 11/7/2025.
//

import SwiftUI
import Combine

final class Theme: ObservableObject {
    // Persisted key
    private let kIsDarkMode = "app.isDarkMode"

    // Persisted appearance (mirrored to UserDefaults)
    @Published var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: kIsDarkMode)
        }
    }

    // Optional: keep a cancellable if you later want to react to more changes
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load last choice if available, else default to system appearance
        if UserDefaults.standard.object(forKey: kIsDarkMode) != nil {
            self.isDarkMode = UserDefaults.standard.bool(forKey: kIsDarkMode)
        } else {
            let systemDark = UITraitCollection.current.userInterfaceStyle == .dark
            self.isDarkMode = systemDark
        }
    }

    var colors: ThemeColors {
        ThemeColors(isDarkMode: isDarkMode)
    }
}

struct ThemeColors {
    let isDarkMode: Bool

    // MARK: - Backgrounds

    var backgroundGradient: LinearGradient {
        if isDarkMode {
            let c1 = Color(hex: "#0F0F0F")
            let c2 = Color(hex: "#1A1A1A")
            let c3 = Color(hex: "#262626")
            return LinearGradient(colors: [c1, c2, c3], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(
                colors: [
                    Color(hex: "E8D5F2"),
                    Color(hex: "FFE4F1"),
                    Color(hex: "E5E5F0")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var surfaceSecondary: Color {
        isDarkMode ? Color(hex: "#1E1E1E") : Color.white.opacity(0.6)
    }

    // Cards / Glass
    var cardBackground: Color {
        if isDarkMode {
            return Color.white.opacity(0.06)
        } else {
            return Color.white.opacity(0.7)
        }
    }

    // Card/border stroke
    var cardStroke: Color {
        if isDarkMode {
            return Color.white.opacity(0.12)
        } else {
            return Color.white.opacity(0.6)
        }
    }

    // MARK: - Text

    var textPrimary: Color {
        isDarkMode ? Color.white : .black
    }

    var textSecondary: Color {
        isDarkMode ? Color(hex: "#B0B0B0") : .gray
    }

    var textTertiary: Color {
        isDarkMode ? Color(hex: "#6B6B6B") : .gray.opacity(0.8)
    }

    var textDisabled: Color {
        isDarkMode ? Color(hex: "#404040") : .gray.opacity(0.5)
    }

    // MARK: - Icons

    var iconPrimary: Color {
        isDarkMode ? .white : .black
    }

    // MARK: - Accents / Buttons

    var accentGreenFill: Color { Color(hex: "#00E5A0") }
    var accentGreenGlow: Color { Color(hex: "#00FFB3") }

    var accentOrangeFill: Color { Color(hex: "#FF9F57") }
    var accentOrangeGlow: Color { Color(hex: "#FFB380") }

    var accentPurpleFill: Color { Color(hex: "#B57BFF") }
    var accentPurpleGlow: Color { Color(hex: "#CDA3FF") }

    // Legacy accents retained for compatibility
    var accentPurple: Color { Color(hex: "#A855F7") }
    var accentPurpleLight: Color { Color(hex: "#C4B5FD") }
    var accentPink: Color { Color(hex: "#EC4899") }
    var accentGreen: Color { isDarkMode ? Color(hex: "#34D399") : Color(hex: "#86EFAC") }
    var accentOrange: Color { isDarkMode ? Color(hex: "#FB923C") : .orange }

    // MARK: - Dividers

    var divider: Color {
        isDarkMode ? Color.white.opacity(0.12) : Color.white.opacity(0.5)
    }

    // MARK: - Materials

    var barMaterial: Material { .ultraThinMaterial }
}
