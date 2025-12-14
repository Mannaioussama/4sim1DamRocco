import SwiftUI
import UIKit

struct PremiumBillingView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = false
    @State private var error: String?
    @State private var totalPaid: Double = 0
    @State private var nextPaymentDate: String = "-"
    @State private var nextPaymentAmount: String = ""
    @State private var history: [BillingHistoryItem] = []
    @State private var shareItems: [Any] = []
    @State private var isShowingShareSheet = false
    @State private var shareSheetID = UUID()
    
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
                            Text(localizationManager.localized("premium.billing.paymentHistory"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            if history.isEmpty {
                                Text(localizationManager.localized("premium.billing.noPayments"))
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textSecondary)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(history) { item in
                                        BillingHistoryRow(
                                            item: item,
                                            onInvoiceTapped: { handleInvoiceTap(for: item) }
                                        )
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
                Text(localizationManager.localized("premium.billing.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .task {
            await loadBillingData()
        }
        .alert(localizationManager.localized("common.error"), isPresented: .constant(error != nil)) {
            Button(localizationManager.localized("common.ok")) { error = nil }
        } message: {
            if let error = error {
                Text(error)
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(activityItems: shareItems)
                .id(shareSheetID)
        }
    }
    
    private var billingSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localized("premium.billing.totalPaid"))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            
            Text(formatCurrency(totalPaid))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 4)
            
            Text(localizationManager.localized("premium.billing.nextPayment"))
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
            let price = subscription.monthlyPrice
            totalPaid = calculateTotalPaid(from: subscription)
            
            if let nextDate = subscription.nextBillingDate, !nextDate.isEmpty {
                nextPaymentDate = formatBillingDate(nextDate)
            } else {
                nextPaymentDate = "-"
            }
            
            if price > 0 {
                nextPaymentAmount = formatCurrency(price)
            } else {
                nextPaymentAmount = ""
            }
            
            // Placeholder static history data to mirror design; wire to backend when available
            history = [
                BillingHistoryItem(planName: subscription.type.replacingOccurrences(of: "_", with: " ").uppercased(),
                                   date: formatBillingDate(subscription.startDate),
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

    private func formatBillingDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = isoFormatter.date(from: isoString)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: isoString)
        }
        guard let finalDate = date else { return isoString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: finalDate)
    }

    private func calculateTotalPaid(from subscription: SubscriptionResponse) -> Double {
        let price = subscription.monthlyPrice
        guard price > 0 else { return 0 }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func parseDate(_ string: String?) -> Date? {
            guard let s = string, !s.isEmpty else { return nil }
            var date = isoFormatter.date(from: s)
            if date == nil {
                isoFormatter.formatOptions = [.withInternetDateTime]
                date = isoFormatter.date(from: s)
            }
            return date
        }

        guard let start = parseDate(subscription.startDate) else {
            // Fallback: at least one billing period if we can't parse
            return max(price, 0)
        }

        let end = parseDate(subscription.endDate) ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: start, to: end)
        let months = max((components.month ?? 0) + 1, 1)
        return Double(months) * price
    }

    private func handleInvoiceTap(for item: BillingHistoryItem) {
        guard let pdfData = generateInvoicePDF(for: item) else {
            error = localizationManager.localized("premium.billing.invoiceError")
            return
        }
        let filename = "Invoice-\(UUID().uuidString.prefix(8)).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try pdfData.write(to: tempURL)
            shareItems = [tempURL]
            shareSheetID = UUID() // force ShareSheet to be recreated with new items
            isShowingShareSheet = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func generateInvoicePDF(for item: BillingHistoryItem) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size in points
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            let margin: CGFloat = 40
            let contentWidth = pageRect.width - margin * 2
            var y: CGFloat = margin

            func drawText(_ text: String, font: UIFont, color: UIColor = .black, x: CGFloat? = nil) -> CGSize {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let size = text.size(withAttributes: attributes)
                let drawX = x ?? margin
                text.draw(at: CGPoint(x: drawX, y: y), withAttributes: attributes)
                y += size.height + 4
                return size
            }

            func drawRightAligned(_ text: String, font: UIFont, color: UIColor = .black) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let size = text.size(withAttributes: attributes)
                let drawX = margin + contentWidth - size.width
                text.draw(at: CGPoint(x: drawX, y: y), withAttributes: attributes)
            }

            func drawLine(y: CGFloat, alpha: CGFloat = 0.4) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: margin + contentWidth, y: y))
                UIColor.lightGray.withAlphaComponent(alpha).setStroke()
                path.lineWidth = 0.8
                path.stroke()
            }

            // Background
            UIColor.white.setFill()
            UIRectFill(pageRect)

            // MARK: Header
            drawText("Invoice", font: .boldSystemFont(ofSize: 26))
            let headerY = y
            y = margin
            drawRightAligned("nexoo", font: .boldSystemFont(ofSize: 18), color: .darkGray)
            y = headerY + 12

            // Invoice meta (left column)
            let invoiceNumber = "INV-\(UUID().uuidString.prefix(6).uppercased())"
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let today = Date()
            let todayString = dateFormatter.string(from: today)
            let dueString = todayString

            drawText("Invoice number", font: .systemFont(ofSize: 11, weight: .semibold))
            drawText(invoiceNumber, font: .systemFont(ofSize: 11))
            y += 4
            drawText("Date of issue", font: .systemFont(ofSize: 11, weight: .semibold))
            drawText(todayString, font: .systemFont(ofSize: 11))
            y += 4
            drawText("Date due", font: .systemFont(ofSize: 11, weight: .semibold))
            drawText(dueString, font: .systemFont(ofSize: 11))

            // From / Bill to block
            y += 18
            let leftBlockTop = y
            drawText("nexoo", font: .systemFont(ofSize: 12, weight: .semibold))
            drawText("San Francisco, California", font: .systemFont(ofSize: 11))
            drawText("United States", font: .systemFont(ofSize: 11))

            // Bill to on the right
            y = leftBlockTop
            let billToX = margin + contentWidth / 2
            _ = drawText("Bill to", font: .systemFont(ofSize: 11, weight: .semibold), color: .black, x: billToX)
            _ = drawText("Premium subscriber", font: .systemFont(ofSize: 11), color: .black, x: billToX)

            y += 18

            // Amount due summary
            drawText("\(item.amount) due \(dueString)", font: .boldSystemFont(ofSize: 16), color: .systemBlue)
            y += 8

            // MARK: Line items table
            y += 12
            drawLine(y: y)
            y += 6

            let descriptionX = margin
            let qtyX = margin + contentWidth * 0.6
            let unitPriceX = margin + contentWidth * 0.75
            let amountX = margin + contentWidth * 0.88

            func drawColumnHeader(_ text: String, x: CGFloat) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: UIColor.darkGray
                ]
                text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
            }

            drawColumnHeader("Description", x: descriptionX)
            drawColumnHeader("Qty", x: qtyX)
            drawColumnHeader("Unit price", x: unitPriceX)
            drawColumnHeader("Amount", x: amountX)
            y += 18
            drawLine(y: y)
            y += 8

            // Single line item
            let bodyFont = UIFont.systemFont(ofSize: 11)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black
            ]
            item.planName.draw(at: CGPoint(x: descriptionX, y: y), withAttributes: attributes)
            let dateY = y + 14
            item.date.draw(at: CGPoint(x: descriptionX, y: dateY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ])

            "1".draw(at: CGPoint(x: qtyX, y: y), withAttributes: attributes)
            item.amount.draw(at: CGPoint(x: unitPriceX, y: y), withAttributes: attributes)
            item.amount.draw(at: CGPoint(x: amountX, y: y), withAttributes: attributes)

            y = max(dateY + 18, y + 24)
            drawLine(y: y)

            // MARK: Totals block (bottom right)
            y += 16
            let totalsStartY = y
            let labelFont = UIFont.systemFont(ofSize: 11)
            let valueFont = UIFont.systemFont(ofSize: 11)

            func drawTotalRow(label: String, value: String, bold: Bool = false) {
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: bold ? UIFont.boldSystemFont(ofSize: 11) : labelFont,
                    .foregroundColor: UIColor.darkGray
                ]
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: bold ? UIFont.boldSystemFont(ofSize: 11) : valueFont,
                    .foregroundColor: UIColor.black
                ]

                let labelSize = label.size(withAttributes: labelAttributes)
                let labelX = margin + contentWidth * 0.6
                label.draw(at: CGPoint(x: labelX, y: y), withAttributes: labelAttributes)

                let valueSize = value.size(withAttributes: valueAttributes)
                let valueX = margin + contentWidth - valueSize.width
                value.draw(at: CGPoint(x: valueX, y: y), withAttributes: valueAttributes)

                y += max(labelSize.height, valueSize.height) + 6
            }

            drawTotalRow(label: "Subtotal", value: item.amount)
            drawTotalRow(label: "Total", value: item.amount)
            drawTotalRow(label: "Amount due", value: item.amount, bold: true)

            y = totalsStartY - 8

            // Footer page number
            let footerText = "Page 1 of 1"
            let footerFont = UIFont.systemFont(ofSize: 9)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.lightGray
            ]
            let footerSize = footerText.size(withAttributes: footerAttributes)
            let footerY = pageRect.height - margin - footerSize.height
            let footerX = (pageRect.width - footerSize.width) / 2
            footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)
        }

        return data
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
    let onInvoiceTapped: (() -> Void)?
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    private var statusText: String {
        switch item.status {
        case .pending: return localizationManager.localized("premium.billing.status.pending")
        case .failed: return localizationManager.localized("premium.billing.status.failed")
        case .paid: return localizationManager.localized("premium.billing.status.paid")
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
                    Button(action: { onInvoiceTapped?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 11))
                            Text(localizationManager.localized("premium.billing.invoice"))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.colors.cardBackground.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .foregroundColor(theme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)
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
