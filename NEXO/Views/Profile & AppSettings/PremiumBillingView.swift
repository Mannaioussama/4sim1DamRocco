import SwiftUI

struct PremiumBillingView: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = false
    @State private var error: String?
    @State private var totalPaid: Double = 0
    @State private var nextPaymentDate: String = "-"
    @State private var nextPaymentAmount: String = ""
    @State private var history: [BillingHistoryItem] = []
    
    var body: some View {
        ZStack {
            theme.colors.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        billingSummaryCard
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Payment History")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            if history.isEmpty {
                                Text("No payments yet.")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textSecondary)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(history) { item in
                                        BillingHistoryRow(item: item)
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
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
                Text("Billing Center")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .task {
            await loadBillingData()
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            if let error = error {
                Text(error)
            }
        }
    }
    
    private var billingSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Paid")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            
            Text(formatCurrency(totalPaid))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 4)
            
            Text("Next Payment")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
            
            Text(nextPaymentDate)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            if !nextPaymentAmount.isEmpty {
                Text(nextPaymentAmount)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "FACC15"))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "14532D"))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
    }
    
    private func loadBillingData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let subscription = try await SubscriptionAPI.getCurrentSubscription()
            totalPaid = 0 // Backend does not yet expose total paid for subscriptions
            
            if let nextDate = subscription.nextBillingDate, !nextDate.isEmpty {
                nextPaymentDate = nextDate
            } else {
                nextPaymentDate = "-"
            }
            
            let price = subscription.monthlyPrice
            if price > 0 {
                nextPaymentAmount = formatCurrency(price)
            } else {
                nextPaymentAmount = ""
            }
            
            // Placeholder static history data to mirror design; wire to backend when available
            history = [
                BillingHistoryItem(planName: subscription.type.replacingOccurrences(of: "_", with: " ").uppercased(),
                                   date: subscription.startDate,
                                   amount: formatCurrency(price),
                                   status: .pending),
            ]
        } catch {
            if let apiError = error as? APIError {
                self.error = apiError.userMessage
            } else {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

enum BillingStatus {
    case pending
    case failed
    case paid
}

struct BillingHistoryItem: Identifiable {
    let id = UUID()
    let planName: String
    let date: String
    let amount: String
    let status: BillingStatus
}

private struct BillingHistoryRow: View {
    let item: BillingHistoryItem
    @EnvironmentObject private var theme: Theme
    
    private var statusText: String {
        switch item.status {
        case .pending: return "Pending"
        case .failed: return "Failed"
        case .paid: return "Paid"
        }
    }
    
    private var statusColor: Color {
        switch item.status {
        case .pending: return Color(hex: "FACC15")
        case .failed: return Color(hex: "EF4444")
        case .paid: return Color(hex: "22C55E")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.planName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(item.date)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(item.amount)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 11))
                        Text("Invoice")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            HStack {
                Text(statusText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .clipShape(Capsule())
                Spacer()
            }
        }
        .padding(14)
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
