import SwiftUI

struct CoachDashboardView: View {
    @EnvironmentObject private var theme: Theme
    var onBack: () -> Void

    @State private var activeTab: String = "income" // "income" or "feedback"
    @State private var currentMonth: Date = Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 1)) ?? Date()

    // Mock stats
    private let stats = (totalEvents: 24, totalParticipants: 187, avgRating: 4.8, totalIncome: 8450)

    // Mock income data per day for November 2025
    private let incomeData: [String: Int] = [
        "2025-11-01": 120,
        "2025-11-03": 200,
        "2025-11-05": 150,
        "2025-11-07": 180,
        "2025-11-10": 250,
        "2025-11-12": 140,
        "2025-11-14": 220,
        "2025-11-17": 190,
        "2025-11-19": 160,
        "2025-11-21": 210,
        "2025-11-24": 175,
        "2025-11-26": 230,
        "2025-11-28": 145,
    ]

    private struct FeedbackItem: Identifiable {
        let id: String
        let userName: String
        let rating: Int
        let comment: String
        let event: String
        let date: String
    }

    private let feedback: [FeedbackItem] = [
        .init(id: "1", userName: "Sarah M.", rating: 5,
              comment: "Best HIIT session I've attended! Great motivation and clear instructions.",
              event: "Morning HIIT Training", date: "Oct 30, 2025"),
        .init(id: "2", userName: "Mike R.", rating: 5,
              comment: "Excellent technique coaching. Really helped improve my form.",
              event: "Swimming Technique Class", date: "Oct 28, 2025"),
        .init(id: "3", userName: "Emma L.", rating: 4,
              comment: "Great session! Very professional and accommodating to different skill levels.",
              event: "Yoga & Meditation", date: "Oct 26, 2025"),
    ]

    var body: some View {
        ZStack {
            // Crystal app-wide background
            theme.colors.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
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
                        Text("Coach Dashboard")
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
                                        Text("Total Earnings")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("$\(stats.totalIncome)")
                                            .font(.system(size: 26, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
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
            tabButton(title: "Income", value: "income")
            tabButton(title: "Feedback", value: "feedback")
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
                Text("Days with earnings")
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
            Text("Total: $\(incomeData.values.reduce(0, +))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding(.top, 4)
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
                    Image(systemName: star <= Int(stats.avgRating.rounded(.down)) ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(star <= Int(stats.avgRating.rounded(.down)) ? Color(hex: "FACC15") : theme.colors.textSecondary.opacity(0.4))
                }
            }
            Text(String(format: "%.1f", stats.avgRating))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "111827"))
            Text("Average Rating from \(stats.totalEvents) events")
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
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        let year = components.year ?? 2025
        let month = components.month ?? 11
        let key = String(format: "%04d-%02d-%02d", year, month, day)
        return incomeData[key] ?? 0
    }

    private func previousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

#Preview {
    NavigationStack {
        CoachDashboardView(onBack: {})
            .environmentObject(Theme())
    }
}
