//
//  ButtonStyle+Brand.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI  // ← Required for Color, View, ButtonStyle, etc.

struct BrandButtonStyle: ButtonStyle {
    enum Variant { case `default`, outline, destructive, secondary, ghost, link }
    var variant: Variant = .default

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor(configuration.isPressed))
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    // MARK: - Style Variants
    private var foregroundColor: Color {
        switch variant {
        case .default: return .white
        case .outline, .ghost: return ColorPalette.primary
        default: return .white
        }
    }

    private func backgroundColor(_ pressed: Bool) -> Color {
        switch variant {
        case .default:
            return pressed ? ColorPalette.primary.opacity(0.8) : ColorPalette.primary
        case .destructive:
            return pressed ? ColorPalette.destructive.opacity(0.8) : ColorPalette.destructive
        case .secondary:
            return ColorPalette.accent
        case .ghost, .outline, .link:
            return .clear
        }
    }

    private var borderColor: Color {
        variant == .outline ? ColorPalette.primary : .clear
    }

    private var borderWidth: CGFloat {
        variant == .outline ? 1 : 0
    }
}
