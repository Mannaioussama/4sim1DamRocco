import SwiftUI

struct PremiumAnalyticsView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Top summary grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        AnalyticsStatCard(title: localizationManager.localized("premium.analytics.stat.totalActivities"), value: "0")
                        AnalyticsStatCard(title: localizationManager.localized("premium.analytics.stat.thisMonth"), value: "0")
                        AnalyticsStatCard(title: localizationManager.localized("premium.analytics.stat.revenue"), value: "€0.00")
                        AnalyticsStatCard(title: localizationManager.localized("premium.analytics.stat.fillRate"), value: "0.0%")
                    }
                    
                    AnalyticsStatisticsCard()
                    
                    AnalyticsSectionRow(title: localizationManager.localized("premium.analytics.section.activitiesByMonth"))
                    AnalyticsSectionRow(title: localizationManager.localized("premium.analytics.section.topActivities"))
                    
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
                Text(localizationManager.localized("premium.analytics.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
    }
}

private struct AnalyticsStatCard: View {
    let title: String
    let value: String
    @EnvironmentObject private var theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

private struct AnalyticsStatisticsCard: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localized("premium.analytics.statistics.title"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            VStack(spacing: 10) {
                AnalyticsListRow(label: localizationManager.localized("premium.analytics.statistics.avgActivitiesPerMonth"), value: "0.0")
                AnalyticsListRow(label: localizationManager.localized("premium.analytics.statistics.totalParticipants"), value: "0")
                AnalyticsListRow(label: localizationManager.localized("premium.analytics.statistics.avgParticipantsPerActivity"), value: "0.0")
                AnalyticsListRow(label: localizationManager.localized("premium.analytics.statistics.avgRevenuePerActivity"), value: "€0.00")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

private struct AnalyticsListRow: View {
    let label: String
    let value: String
    @EnvironmentObject private var theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

private struct AnalyticsSectionRow: View {
    let title: String
    @EnvironmentObject private var theme: Theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }
}
