import Foundation
import Combine

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var plans: [SubscriptionPlan] = []
    @Published var currentPlan: SubscriptionResponse?
    @Published var error: String?
    @Published var isSubscribing = false
    @Published var subscriptionSuccess = false
    
    // Stripe payment state (SetupIntent-based)
    @Published var isInitializingPayment = false
    @Published var clientSecret: String?
    @Published var setupIntentId: String?
    @Published var selectedPlanType: String?
    
    // MARK: - Load Plans
    func loadPlans() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await SubscriptionAPI.getAvailablePlans()
            plans = response.plans
            currentPlan = response.currentPlan
        } catch {
            if let apiError = error as? APIError {
                self.error = apiError.userMessage
            } else {
                self.error = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Load Current Subscription
    func loadCurrentSubscription() async {
        do {
            currentPlan = try await SubscriptionAPI.getCurrentSubscription()
        } catch {
            // Non-blocking; ignore failures here
            print("Failed to load current subscription: \(error)")
        }
    }
    
    // MARK: - Initialize Payment
    func initializePayment(planType: String) async {
        isInitializingPayment = true
        error = nil
        selectedPlanType = planType
        
        do {
            let response = try await SubscriptionAPI.initializePayment(planType: planType)
            clientSecret = response.clientSecret
            setupIntentId = response.setupIntentId
        } catch {
            if let apiError = error as? APIError {
                self.error = apiError.userMessage
            } else {
                self.error = "Erreur lors de l'initialisation du paiement: \(error.localizedDescription)"
            }
            resetPaymentState()
        }
        
        isInitializingPayment = false
    }
    
    // MARK: - Subscribe to Plan
    func subscribeToPlan(planType: String, paymentMethodId: String? = nil, setupIntentId: String? = nil) async {
        isSubscribing = true
        error = nil
        
        do {
            let subscription = try await SubscriptionAPI.createSubscription(
                type: planType,
                paymentMethodId: paymentMethodId,
                setupIntentId: setupIntentId
            )
            currentPlan = subscription
            subscriptionSuccess = true
            resetPaymentState()
            await loadPlans()
        } catch {
            if let apiError = error as? APIError {
                self.error = apiError.userMessage
            } else {
                self.error = "Erreur lors de l'abonnement: \(error.localizedDescription)"
            }
        }
        
        isSubscribing = false
    }
    
    // MARK: - Reset Payment State
    func resetPaymentState() {
        clientSecret = nil
        setupIntentId = nil
        selectedPlanType = nil
    }
    
    // MARK: - Clear Error / Success
    func clearError() {
        error = nil
    }
    
    func clearSuccess() {
        subscriptionSuccess = false
    }
}
