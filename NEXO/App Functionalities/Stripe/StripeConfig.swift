import Foundation
import StripePaymentSheet

final class StripeConfig {
    static let shared = StripeConfig()
    
    private init() {}
    
    func configure() {
        // Use the central AppConfig to provide the Stripe publishable key
        STPAPIClient.shared.publishableKey = AppConfig.stripePublishableKey
    }
}
