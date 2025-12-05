import Foundation
import Combine
import StripePaymentSheet

@MainActor
final class PaymentViewModel: ObservableObject {
    @Published var isInitializing = false
    @Published var isConfirming = false
    @Published var errorMessage: String?
    @Published var paymentSheet: PaymentSheet?
    @Published var hasPaidForActivity: Bool = false
    
    private let paymentService = PaymentAPIService()
    private var paymentIntentId: String?
    private var activityId: String?
    
    func checkStatus(activityId: String) async {
        do {
            let status = try await paymentService.checkPaymentStatus(activityId: activityId)
            self.hasPaidForActivity = status.hasPaid || status.isParticipant
        } catch {
            // Silent failure is OK here; leave hasPaidForActivity as-is
            if let apiError = error as? APIError {
                self.errorMessage = apiError.userMessage
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func initializePayment(activityId: String, amount: Double, currency: String = "eur") async {
        guard !isInitializing else { return }
        self.isInitializing = true
        self.errorMessage = nil
        self.activityId = activityId
        do {
            let intent = try await paymentService.createPaymentIntent(activityId: activityId, amount: amount, currency: currency)
            self.paymentIntentId = intent.paymentIntentId
            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "NEXO Coach Session"
            config.allowsDelayedPaymentMethods = false
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: intent.clientSecret, configuration: config)
        } catch {
            if let apiError = error as? APIError {
                self.errorMessage = apiError.userMessage
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
        self.isInitializing = false
    }
    
    func confirmBackendPaymentIfNeeded() async {
        guard let activityId = activityId, let paymentIntentId = paymentIntentId else { return }
        guard !isConfirming else { return }
        isConfirming = true
        defer { isConfirming = false }
        do {
            let result = try await paymentService.confirmPayment(activityId: activityId, paymentIntentId: paymentIntentId)
            if result.success {
                self.hasPaidForActivity = true
            } else {
                self.errorMessage = result.message
            }
        } catch {
            if let apiError = error as? APIError {
                self.errorMessage = apiError.userMessage
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
