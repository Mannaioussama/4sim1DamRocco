import Foundation
import SwiftUI
import Combine

@MainActor
final class CoachDashboardViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var allTimeEarnings: CoachEarningsResponse?
    @Published var monthlyEarnings: CoachEarningsResponse?
    @Published var withdrawBalance: WithdrawBalanceResponse?
    @Published var coachReviews: CoachReviewsResponse?
    @Published var withdrawHistory: [WithdrawItemResponse] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let paymentService = PaymentAPIService()
    private let reviewsService = ReviewsService()
    
    // MARK: - Public API
    
    func loadInitialData(currentMonth: Date) {
        Task {
            await fetchAllData(currentMonth: currentMonth)
        }
    }
    
    func reloadMonth(_ newMonth: Date) {
        Task {
            await fetchMonthlyEarnings(for: newMonth)
        }
    }
    
    func loadWithdrawHistory(limit: Int = 50) async {
        do {
            let response = try await paymentService.getWithdrawHistory(limit: limit)
            withdrawHistory = response.withdraws
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
        }
    }
    
    /// Request a withdraw and refresh dashboard data on success.
    @discardableResult
    func requestWithdraw(amount: Double, bankAccount: String) async -> Bool {
        do {
            let request = CreateWithdrawRequest(
                amount: amount,
                bankAccount: bankAccount,
                paymentMethod: "bank_transfer",
                currency: withdrawBalance?.currency ?? "usd",
                description: nil
            )
            _ = try await paymentService.createWithdraw(request: request)
            // After a successful request, refresh balance and earnings
            await fetchAllData(currentMonth: Date())
            return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
            return false
        }
    }
    
    /// Returns the income (rounded to Int) for a given day in the provided month.
    func incomeForDay(_ day: Int, inMonth monthDate: Date) -> Int {
        guard let monthly = monthlyEarnings else { return 0 }
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        guard let year = comps.year, let month = comps.month else { return 0 }
        let key = String(format: "%04d-%02d-%02d", year, month, day)
        if let entry = monthly.earnings.first(where: { $0.date.hasPrefix(key) }) {
            return Int(entry.amount.rounded())
        }
        return 0
    }
    
    /// Sum of all earnings in the currently loaded month (rounded to Int) for legend display.
    var monthlyTotalIncome: Int {
        guard let monthly = monthlyEarnings else { return 0 }
        let sum = monthly.earnings.reduce(0.0) { $0 + $1.amount }
        return Int(sum.rounded())
    }
    
    // MARK: - Private Helpers
    
    private func fetchAllData(currentMonth: Date) async {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: currentMonth)
        let year = comps.year
        let month = comps.month
        
        do {
            async let allTime = paymentService.getCoachEarnings()
            async let monthly = paymentService.getCoachEarnings(year: year, month: month)
            async let balance = paymentService.getWithdrawBalance()
            async let reviews = reviewsService.getCoachReviews(limit: 50)
            async let history = paymentService.getWithdrawHistory(limit: 50)
        
            let (allTimeResult, monthlyResult, balanceResult, reviewsResult, historyResult) = try await (allTime, monthly, balance, reviews, history)
        
            allTimeEarnings = allTimeResult
            monthlyEarnings = monthlyResult
            withdrawBalance = balanceResult
            coachReviews = reviewsResult
            withdrawHistory = historyResult.withdraws
            isLoading = false
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
            isLoading = false
        }
    }
    
    private func fetchMonthlyEarnings(for monthDate: Date) async {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: monthDate)
        let year = comps.year
        let month = comps.month
        
        do {
            let monthly = try await paymentService.getCoachEarnings(year: year, month: month)
            monthlyEarnings = monthly
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
        }
    }
}
