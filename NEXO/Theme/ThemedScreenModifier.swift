import SwiftUI

struct ThemedScreen: ViewModifier {
    @EnvironmentObject private var theme: Theme
    func body(content: Content) -> some View {
        content
            .background(theme.colors.backgroundGradient.ignoresSafeArea())
            .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
    }
}

extension View {
    func themedScreen() -> some View { modifier(ThemedScreen()) }
}
