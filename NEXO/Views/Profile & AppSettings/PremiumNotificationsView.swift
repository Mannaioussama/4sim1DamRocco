import SwiftUI

struct PremiumNotificationsView: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(localizationManager.localized("premium.notifications.title"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localized("premium.notifications.comingSoonTitle"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(localizationManager.localized("premium.notifications.comingSoonDescription"))
                            .font(.system(size: 13))
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }
            }
            ToolbarItem(placement: .principal) {
                Text(localizationManager.localized("premium.notifications.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
    }
}
