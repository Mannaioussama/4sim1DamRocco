import SwiftUI
import StripePaymentSheet

struct PremiumSubscriptionView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showStripePayment = false
    
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        HeroSectionView(currentPlan: viewModel.currentPlan)
                            .padding(.top, 12)
                        
                        if let current = viewModel.currentPlan {
                            CurrentPlanCardView(plan: current)
                            PremiumStatisticsCard(
                                activitiesUsed: current.activitiesUsedThisMonth,
                                activitiesLimit: current.activitiesLimit,
                                freeActivitiesRemaining: current.freeActivitiesRemaining,
                                subscriptionType: current.type
                            )
                            UsageActionsRow()
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text(localizationManager.localized("premium.choosePlan.title"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.plans) { plan in
                                PlanCardView(
                                    plan: plan,
                                    isCurrentPlan: viewModel.currentPlan?.type == plan.type,
                                    isLoading: viewModel.isSubscribing,
                                    onUpgrade: {
                                        handleUpgrade(planType: plan.type)
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        FeatureComparisonView()
                            .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
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
                Text(localizationManager.localized("premium.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .task {
            await viewModel.loadPlans()
            await viewModel.loadCurrentSubscription()
        }
        .alert(localizationManager.localized("common.error"), isPresented: .constant(viewModel.error != nil)) {
            Button(localizationManager.localized("common.ok")) {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .alert(localizationManager.localized("premium.alert.successTitle"), isPresented: $viewModel.subscriptionSuccess) {
            Button(localizationManager.localized("common.ok")) {
                viewModel.clearSuccess()
            }
        } message: {
            Text(localizationManager.localized("premium.alert.successMessage"))
        }
        .sheet(isPresented: $showStripePayment) {
            if let clientSecret = viewModel.clientSecret {
                StripeSetupIntentSheet(
                    clientSecret: clientSecret,
                    onPaymentCompleted: {
                        Task {
                            await viewModel.subscribeToPlan(
                                planType: viewModel.selectedPlanType ?? "",
                                setupIntentId: viewModel.setupIntentId
                            )
                        }
                        showStripePayment = false
                    },
                    onPaymentCanceled: {
                        viewModel.resetPaymentState()
                        showStripePayment = false
                    }
                )
            }
        }
        .onChange(of: viewModel.clientSecret) { _, newValue in
            if newValue != nil && !viewModel.isInitializingPayment {
                showStripePayment = true
            }
        }
    }
    
    // MARK: - Handle Upgrade
    private func handleUpgrade(planType: String) {
        if planType == "free" {
            Task { await viewModel.subscribeToPlan(planType: planType) }
        } else {
            Task { await viewModel.initializePayment(planType: planType) }
        }
    }
}

// MARK: - Components

private struct HeroSectionView: View {
    let currentPlan: SubscriptionResponse?
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "FFC107"))
            
            Text(localizationManager.localized("premium.hero.title"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(localizationManager.localized("premium.hero.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let currentPlan = currentPlan {
                Text("\(localizationManager.localized("premium.hero.currentPrefix")) \(currentPlan.type.replacingOccurrences(of: "_", with: " ").uppercased())")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "22C55E"))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        .padding(.horizontal, 16)
    }
}

private struct CurrentPlanCardView: View {
    let plan: SubscriptionResponse
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localizationManager.localized("premium.currentPlan.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text(plan.type.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "22C55E"))
            }
            
            let limitText = plan.activitiesLimit == -1
                ? "Unlimited"
                : "\(plan.activitiesUsedThisMonth)/\(plan.activitiesLimit)"
            
            Text("Activities this month: \(limitText)")
                .font(.system(size: 13))
                .foregroundColor(theme.colors.textSecondary)
            
            if plan.freeActivitiesRemaining > 0 {
                Text("Free activities remaining: \(plan.freeActivitiesRemaining)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "22C55E"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "22C55E"), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
        .padding(.horizontal, 16)
    }
}

private struct PlanCardView: View {
    let plan: SubscriptionPlan
    let isCurrentPlan: Bool
    let isLoading: Bool
    let onUpgrade: () -> Void
    
    private var gradientColors: [Color] {
        switch plan.type {
        case "free":
            return [Color(hex: "757575"), Color(hex: "9E9E9E")]
        case "premium_normal":
            return [Color(hex: "3B82F6"), Color(hex: "1D4ED8")]
        case "premium_gold":
            return [Color(hex: "FACC15"), Color(hex: "EAB308")]
        case "premium_platinum":
            return [Color(hex: "8B5CF6"), Color(hex: "6366F1")]
        default:
            return [Color(hex: "757575"), Color(hex: "9E9E9E")]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if plan.popular == true {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                        Text("POPULAR")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "FACC15"))
                    )
                }
            }
            
            Text(plan.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(plan.displayPrice)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Divider().background(Color.white.opacity(0.3))
            
            FeatureRow(icon: "checkmark.circle.fill", text: plan.activitiesLimitText)
            
            if plan.features.advancedAnalytics {
                FeatureRow(icon: "chart.bar.fill", text: "Advanced Analytics")
            }
            if plan.features.prioritySupport {
                FeatureRow(icon: "person.fill", text: "Priority Support")
            }
            if plan.features.customBranding {
                FeatureRow(icon: "paintbrush.fill", text: "Custom Branding")
            }
            if plan.features.featuredListing == true {
                FeatureRow(icon: "star.fill", text: "Featured Listing")
            }
            if plan.features.apiAccess {
                FeatureRow(icon: "building.2.fill", text: "White Label Solution")
            }
            
            Button(action: onUpgrade) {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(isCurrentPlan ? "Current Plan" : "Upgrade Now")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isCurrentPlan ? .white.opacity(0.7) : .black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentPlan ? Color.white.opacity(0.3) : Color.white)
            )
            .disabled(isCurrentPlan || isLoading)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: .black.opacity(plan.popular == true ? 0.25 : 0.18), radius: plan.popular == true ? 10 : 6, y: 4)
        )
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }
}

private struct FeatureComparisonView: View {
    @EnvironmentObject private var theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Why Choose Premium?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            
            FeatureItem(
                icon: "chart.line.uptrend.xyaxis",
                title: "Unlimited Growth",
                description: "Create as many activities as you want to grow your coaching business"
            )
            FeatureItem(
                icon: "chart.bar.fill",
                title: "Advanced Analytics",
                description: "Track your performance with detailed analytics and insights"
            )
            FeatureItem(
                icon: "person.fill",
                title: "Priority Support",
                description: "Get priority support from our team whenever you need help"
            )
            FeatureItem(
                icon: "star.fill",
                title: "Featured Listing",
                description: "Get your activities featured prominently in search results"
            )
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

private struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "FACC15"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

private struct PremiumStatisticsCard: View {
    let activitiesUsed: Int
    let activitiesLimit: Int
    let freeActivitiesRemaining: Int
    let subscriptionType: String
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack {
                Text(localizationManager.localized("premium.stats.usageStatistics"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "FACC15"))
            }

            // Green pill for unlimited or remaining
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(activitiesLimit == -1
                     ? localizationManager.localized("premium.stats.unlimitedActivities")
                     : activitiesRemainingText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "16A34A"))
            .clipShape(Capsule())

            // Inner tiles row
            HStack(spacing: 10) {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "3B82F6"))
                    Text("\(activitiesUsed)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(localizationManager.localized("premium.stats.created"))
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(theme.colors.cardBackground.opacity(0.9))
                .cornerRadius(14)

                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "FACC15"))
                    Text(planTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(localizationManager.localized("premium.stats.planLabel"))
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(theme.colors.cardBackground.opacity(0.9))
                .cornerRadius(14)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground.opacity(0.95))
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }

    private var activitiesRemainingText: String {
        if activitiesLimit == -1 {
            return localizationManager.localized("premium.stats.unlimited")
        }
        let remaining = max(activitiesLimit - activitiesUsed, 0)
        return String(format: localizationManager.localized("premium.stats.activitiesRemainingFormat"), remaining)
    }

    private var planTitle: String {
        subscriptionType
            .replacingOccurrences(of: "_", with: " ")
            .uppercased()
    }
}

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// Row of quick actions under Usage Statistics (Analytics / Billing / Notifications)
private struct UsageActionsRow: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        HStack(spacing: 10) {
            UsageActionButton(icon: "chart.bar.fill", title: localizationManager.localized("premium.usage.analytics")) {
                router.push(.premiumAnalytics)
            }
            UsageActionButton(icon: "building.columns", title: localizationManager.localized("premium.usage.billing")) {
                router.push(.premiumBilling)
            }
            UsageActionButton(icon: "bell.fill", title: localizationManager.localized("premium.usage.notifications")) {
                router.push(.premiumNotifications)
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct UsageActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @EnvironmentObject private var theme: Theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(theme.colors.textPrimary)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(theme.colors.cardBackground.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Stripe SetupIntent Sheet Wrapper

struct StripeSetupIntentSheet: UIViewControllerRepresentable {
    let clientSecret: String
    let onPaymentCompleted: () -> Void
    let onPaymentCanceled: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Nexo Sports"
        
        let paymentSheet = PaymentSheet(
            setupIntentClientSecret: clientSecret,
            configuration: configuration
        )
        
        DispatchQueue.main.async {
            paymentSheet.present(from: viewController) { result in
                switch result {
                case .completed:
                    onPaymentCompleted()
                case .canceled:
                    onPaymentCanceled()
                case .failed:
                    onPaymentCanceled()
                }
            }
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
