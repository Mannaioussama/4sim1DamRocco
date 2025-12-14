import SwiftUI
import LocalAuthentication

struct CoachDashboardView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    var onBack: () -> Void

    @StateObject private var viewModel = CoachDashboardViewModel()
    @State private var activeTab: String = "income" // "income" or "feedback"
    @State private var currentMonth: Date = Date()
    @State private var showWithdrawDialog: Bool = false
    @State private var showWithdrawHistoryDialog: Bool = false

    private struct FeedbackItem: Identifiable {
        let id: String
        let userName: String
        let rating: Int
        let comment: String
        let event: String
        let date: String
    }

    private var feedback: [FeedbackItem] {
        guard let coachReviews = viewModel.coachReviews else { return [] }
        return coachReviews.reviews.map { review in
            FeedbackItem(
                id: review.id,
                userName: review.userName,
                rating: review.rating,
                comment: review.comment ?? "",
                event: review.activityTitle ?? "",
                date: formatReviewDate(review.createdAt)
            )
        }
    }

    var body: some View {
        ZStack {
            // Crystal app-wide background
            theme.colors.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }

            if showWithdrawDialog || showWithdrawHistoryDialog {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()

                    if showWithdrawDialog {
                        WithdrawDialogView(
                            availableBalance: viewModel.withdrawBalance?.availableBalance ?? (viewModel.allTimeEarnings?.totalEarnings ?? 0),
                            onDismiss: { showWithdrawDialog = false },
                            onConfirm: { amount, bankAccount in
                                Task {
                                    let success = await viewModel.requestWithdraw(amount: amount, bankAccount: bankAccount)
                                    if success {
                                        showWithdrawDialog = false
                                    }
                                }
                            }
                        )
                    } else if showWithdrawHistoryDialog {
                        WithdrawHistoryDialogView(
                            items: viewModel.withdrawHistory,
                            onDismiss: { showWithdrawHistoryDialog = false }
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.2), value: showWithdrawDialog || showWithdrawHistoryDialog)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadInitialData(currentMonth: currentMonth)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                // No separate background here; use the root gradient so it’s continuous
                Color.clear

                VStack(spacing: 0) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(8)
                                .background(theme.colors.cardBackground.opacity(0.9))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text(localizationManager.localized("coachDashboard.title"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    // Total income card
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.25), radius: 10, y: 5)

                            HStack {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Image(systemName: "dollarsign")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(localizationManager.localized("coachDashboard.totalEarnings"))
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(totalEarningsText)
                                            .font(.system(size: 26, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    Button(action: authenticateAndShowWithdrawDialog) {
                                        HStack(spacing: 6) {
                                            Text(localizationManager.localized("coachDashboard.withdraw.primaryButton"))
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.18))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        Task {
                                            await viewModel.loadWithdrawHistory()
                                            withAnimation {
                                                showWithdrawHistoryDialog = true
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Text(localizationManager.localized("coachDashboard.withdraw.historyButton"))
                                                .font(.system(size: 12, weight: .semibold))
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(theme.colors.cardBackground.opacity(0.96))
                                        .foregroundColor(theme.colors.textPrimary)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: - Content
    private var content: some View {
        VStack(spacing: 0) {
            tabs
            TabView(selection: $activeTab) {
                incomeTab
                    .tag("income")
                feedbackTab
                    .tag("feedback")
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            tabButton(title: localizationManager.localized("coachDashboard.tab.income"), value: "income")
            tabButton(title: localizationManager.localized("coachDashboard.tab.feedback"), value: "feedback")
        }
        .padding(8)
        .background(theme.colors.cardBackground.opacity(0.7))
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.top, 24) // a bit more space under header like design 2
    }

    private func tabButton(title: String, value: String) -> some View {
        Button(action: { withAnimation { activeTab = value } }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(activeTab == value ? Color(hex: "A855F7") : theme.colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if activeTab == value {
                            Color.white.opacity(0.9)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Income tab
    private var incomeTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                calendarCard
                legend
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(6)
                        .background(theme.colors.cardBackground.opacity(0.8))
                        .clipShape(Circle())
                }
                Spacer()
                Text(formatMonthYear(currentMonth))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(6)
                        .background(theme.colors.cardBackground.opacity(0.8))
                        .clipShape(Circle())
                }
            }

            calendarGrid
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(
            LinearGradient(
                colors: [theme.colors.cardBackground.opacity(0.95), theme.colors.cardBackground.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private var calendarGrid: some View {
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let daysInMonth = getDaysInMonth(currentMonth)
        let firstDay = getFirstDayOfMonth(currentMonth)

        return VStack(spacing: 8) {
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let totalCells = daysInMonth + firstDay
            let rows = Int(ceil(Double(totalCells) / 7.0))

            VStack(spacing: 8) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            if index < firstDay {
                                Color.clear.frame(maxWidth: .infinity, minHeight: 40, maxHeight: 44)
                            } else {
                                let day = index - firstDay + 1
                                if day <= daysInMonth {
                                    let income = getIncomeForDay(day)
                                    let hasIncome = income > 0
                                    VStack(spacing: 2) {
                                        Text("\(day)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(hasIncome ? .black : theme.colors.textSecondary)
                                        if hasIncome {
                                            Text("$\(income)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color(hex: "22C55E"))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 44)
                                    .padding(6)
                                    .background(
                                        Group {
                                            if hasIncome {
                                                LinearGradient(
                                                    colors: [Color(hex: "22C55E").opacity(0.2), Color(hex: "16A34A").opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            } else {
                                                Color.white.opacity(0.35)
                                            }
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(hasIncome ? Color(hex: "22C55E").opacity(0.4) : Color.white.opacity(0.6), lineWidth: hasIncome ? 2 : 1)
                                    )
                                    .cornerRadius(10)
                                } else {
                                    Color.clear.frame(maxWidth: .infinity, minHeight: 40, maxHeight: 44)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "22C55E").opacity(0.2), Color(hex: "16A34A").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 14, height: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(hex: "22C55E").opacity(0.4), lineWidth: 1)
                    )
                Text(localizationManager.localized("coachDashboard.legend.daysWithEarnings"))
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
            Text("\(localizationManager.localized("coachDashboard.legend.total")) $\(viewModel.monthlyTotalIncome)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding(.top, 4)
    }

    private func authenticateAndShowWithdrawDialog() {
        let context = LAContext()
        var error: NSError?

        // Try biometric auth (Face ID / Touch ID). If unavailable, fall back to showing the dialog directly.
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to confirm your withdraw"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                if success {
                    DispatchQueue.main.async {
                        withAnimation {
                            showWithdrawDialog = true
                        }
                    }
                } else if let authError {
                    print("Withdraw biometric auth failed: \(authError.localizedDescription)")
                }
            }
        } else {
            withAnimation {
                showWithdrawDialog = true
            }
        }
    }

    // MARK: - Feedback tab
    private var feedbackTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                averageRatingCard
                ForEach(feedback) { item in
                    feedbackCard(for: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }

    private var averageRatingCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    let rating = viewModel.coachReviews?.averageRating ?? 0
                    Image(systemName: star <= Int(rating.rounded(.down)) ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(star <= Int(rating.rounded(.down)) ? Color(hex: "FACC15") : theme.colors.textSecondary.opacity(0.4))
                }
            }
            Text(String(format: "%.1f", viewModel.coachReviews?.averageRating ?? 0.0))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "111827"))
            Text(String(format: localizationManager.localized("coachDashboard.averageRatingFormat"), viewModel.coachReviews?.totalReviews ?? 0))
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6B7280"))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            LinearGradient(
                colors: [Color(hex: "FEF9C3"), Color(hex: "FFE9B8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
    }

    private func feedbackCard(for item: FeedbackItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "E5E7EB"), Color(hex: "D1D5DB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(item.userName.prefix(1)))
                            .font(.system(size: 14, weight: .semibold))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.userName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "111827"))
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "FACC15"))
                            Text("\(item.rating)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                    Text(item.event)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "6B7280"))
                }
            }

            Text(item.comment)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "111827"))

            Text(item.date)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "9CA3AF"))
        }
        .padding(16)
        .background(
            Color.white.opacity(0.98)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
    }

    // MARK: - Helpers
    private func getDaysInMonth(_ date: Date) -> Int {
        let calendar = Calendar.current
        if let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        } else {
            return 30
        }
    }

    private func getFirstDayOfMonth(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDate = calendar.date(from: components) ?? date
        return calendar.component(.weekday, from: firstDate) - 1 // make Sunday = 0
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private func getIncomeForDay(_ day: Int) -> Int {
        viewModel.incomeForDay(day, inMonth: currentMonth)
    }

    private func previousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
            viewModel.reloadMonth(newDate)
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
            viewModel.reloadMonth(newDate)
        }
    }

    private var totalEarningsText: String {
        let value = viewModel.allTimeEarnings?.totalEarnings ?? 0
        let intValue = Int(value.rounded())
        return "$\(intValue)"
    }

    private func formatReviewDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return isoString
    }
}

// MARK: - Withdraw Dialog

struct WithdrawDialogView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager

    let availableBalance: Double
    let onDismiss: () -> Void
    let onConfirm: (Double, String) -> Void

    @State private var amountText: String = ""
    @State private var bankAccountText: String = ""

    private var isValidAmount: Bool {
        guard let value = Double(amountText), value > 0 else { return false }
        return value <= availableBalance
    }

    private var isValidBankAccount: Bool {
        let trimmed = bankAccountText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 10
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.13, green: 0.69, blue: 0.38),
                                    Color(red: 0.06, green: 0.53, blue: 0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localized("coachDashboard.withdraw.title"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)

                    Text("\(localizationManager.localized("coachDashboard.withdraw.availableBalanceLabel")) $\(String(format: "%.2f", availableBalance))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()
            }

            Divider()
                .background(theme.colors.divider)

            // Balance card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localized("coachDashboard.withdraw.balanceCardTitle"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)

                    Text(String(format: "$%.2f", availableBalance))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(red: 0.02, green: 0.59, blue: 0.41))
                }

                Spacer()

                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(Color(red: 0.02, green: 0.59, blue: 0.41))
                    .font(.system(size: 30))
            }
            .padding(14)
            .background(theme.colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)

            // Amount input
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localized("coachDashboard.withdraw.amountLabel"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)

                HStack {
                    Text("$")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(.leading, 12)

                    ZStack(alignment: .leading) {
                        if amountText.isEmpty {
                            Text(localizationManager.localized("coachDashboard.withdraw.amountPlaceholder"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.colors.textSecondary)
                        }

                        TextField("", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .onChange(of: amountText) { newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    amountText = filtered
                                }
                            }
                    }
                }
                .padding(.vertical, 10)
                .background(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValidAmount ? Color(red: 0.13, green: 0.69, blue: 0.38) : theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(12)
            }

            // Bank account input
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localized("coachDashboard.withdraw.bankLabel"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)

                HStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(Color(red: 0.13, green: 0.69, blue: 0.38))
                        .font(.system(size: 20))

                    ZStack(alignment: .leading) {
                        if bankAccountText.isEmpty {
                            Text(localizationManager.localized("coachDashboard.withdraw.bankPlaceholder"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.colors.textSecondary)
                        }

                        TextField("", text: $bankAccountText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                .padding(12)
                .background(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValidBankAccount ? Color(red: 0.13, green: 0.69, blue: 0.38) : theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(12)

                if !bankAccountText.isEmpty && !isValidBankAccount {
                    Text(localizationManager.localized("coachDashboard.withdraw.bankValidationShort"))
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }

            // Withdraw all shortcut
            Button(action: {
                amountText = String(format: "%.2f", availableBalance)
            }) {
                Text(localizationManager.localized("coachDashboard.withdraw.withdrawAll"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.13, green: 0.69, blue: 0.38))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.13, green: 0.69, blue: 0.38), lineWidth: 1)
                    )
            }

            // Buttons
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text(localizationManager.localized("common.cancel"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.colors.cardStroke, lineWidth: 1.5)
                        )
                }

                Button(action: {
                    guard isValidAmount, isValidBankAccount, let value = Double(amountText) else { return }
                    onConfirm(value, bankAccountText)
                }) {
                    Text(localizationManager.localized("coachDashboard.withdraw.primaryButton"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            (isValidAmount && isValidBankAccount)
                            ? Color(red: 0.13, green: 0.69, blue: 0.38)
                            : Color.gray.opacity(0.4)
                        )
                        .cornerRadius(14)
                }
                .disabled(!isValidAmount || !isValidBankAccount)
            }
        }
        .padding(24)
        .frame(maxWidth: 380)
        .background(theme.colors.surfaceSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.25), radius: 18, y: 10)
        .padding(.horizontal, 24)
    }
}

struct WithdrawHistoryDialogView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager

    let items: [WithdrawItemResponse]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "1D4ED8"),
                                    Color(hex: "0EA5E9")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localized("coachDashboard.withdraw.historyTitle"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)

                    Text(localizationManager.localized("coachDashboard.withdraw.historyStatus"))
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()
            }

            Divider()
                .background(theme.colors.divider)

            if items.isEmpty {
                Text(localizationManager.localized("coachDashboard.withdraw.historyEmpty"))
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(items) { item in
                            historyRow(for: item)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 260)
            }

            Button(action: onDismiss) {
                Text(localizationManager.localized("common.cancel"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.cardStroke, lineWidth: 1.5)
                    )
            }
        }
        .padding(24)
        .frame(maxWidth: 380)
        .background(theme.colors.surfaceSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.25), radius: 18, y: 10)
        .padding(.horizontal, 24)
    }

    private func historyRow(for item: WithdrawItemResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formattedAmount(item))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Text(statusText(for: item.status))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(for: item.status))
                    .clipShape(Capsule())
            }

            Text(formattedDate(item.createdAt))
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)

            if let reason = item.failureReason, !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func formattedAmount(_ item: WithdrawItemResponse) -> String {
        let amount = item.amount
        let currencyCode = item.currency.uppercased()
        return String(format: "%.2f %@", amount, currencyCode)
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return isoString
    }

    private func statusText(for rawStatus: String) -> String {
        switch rawStatus.lowercased() {
        case "pending":
            return localizationManager.localized("coachDashboard.withdraw.status.pending")
        case "processing":
            return localizationManager.localized("coachDashboard.withdraw.status.processing")
        case "completed", "succeeded", "paid":
            return localizationManager.localized("coachDashboard.withdraw.status.completed")
        case "failed", "canceled":
            return localizationManager.localized("coachDashboard.withdraw.status.failed")
        default:
            return rawStatus.capitalized
        }
    }

    private func statusColor(for rawStatus: String) -> Color {
        switch rawStatus.lowercased() {
        case "pending", "processing":
            return Color(hex: "FACC15")
        case "completed", "succeeded", "paid":
            return Color(hex: "22C55E")
        case "failed", "canceled":
            return Color(hex: "EF4444")
        default:
            return theme.colors.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        CoachDashboardView(onBack: {})
            .environmentObject(Theme())
            .environmentObject(LocalizationManager.shared)
    }
}
