//
//  EnhancedEventDetailsView.swift
//  NEXO
//
//  Created by ROCCO 4X on 5/11/2025.
//

import SwiftUI
import SafariServices
import MapKit
import StripePaymentSheet

// MARK: - Main View
struct EnhancedEventDetailsView: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var activityAPIService: ActivityAPIService
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: EnhancedEventDetailsViewModel
    @StateObject private var paymentViewModel = PaymentViewModel()
    @State private var showPaymentSuccessPopup: Bool = false

    var onBack: () -> Void
    var onJoin: () -> Void
    var onViewCoach: (_ coachId: String) -> Void

    // MARK: - Initialization
    
    init(
        eventId: String,
        onBack: @escaping () -> Void,
        onJoin: @escaping () -> Void,
        onViewCoach: @escaping (_ coachId: String) -> Void,
        isCoachView: Bool = false
    ) {
        self._viewModel = StateObject(wrappedValue: EnhancedEventDetailsViewModel(eventId: eventId, isCoachView: isCoachView))
        self.onBack = onBack
        self.onJoin = onJoin
        self.onViewCoach = onViewCoach
    }

    /// New initializer used by the main app flow: builds details from a concrete Activity.
    init(
        activity: Activity,
        onBack: @escaping () -> Void,
        onJoin: @escaping () -> Void,
        onViewCoach: @escaping (_ coachId: String) -> Void,
        isCoachView: Bool = false
    ) {
        self._viewModel = StateObject(wrappedValue: EnhancedEventDetailsViewModel(activity: activity, isCoachView: isCoachView))
        self.onBack = onBack
        self.onJoin = onJoin
        self.onViewCoach = onViewCoach
    }

    var body: some View {
        ZStack {
            // Use the same background reference as SettingsView/Profile
            theme.colors.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        eventHeader
                        coachCard
                        tabBar
                        tabContent
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 60) // leave space for bottom bar but reduce extra gap
                }
            }

            if showPaymentSuccessPopup {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Payment successful")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)

                    Text("You're all set for this session.")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)

                    Button(action: {
                        showPaymentSuccessPopup = false
                        onJoin()
                    }) {
                        Text("Proceed to session")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandButtonStyle(variant: .default))

                    Button(action: {
                        showPaymentSuccessPopup = false
                        onBack()
                    }) {
                        Text("Back home")
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BrandButtonStyle(variant: .outline))
                }
                .padding(16)
                .background(theme.colors.cardBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(18)
                .padding(.horizontal, 32)
            }
        }
        // Toolbar styled with Theme references
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.cardBackground)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Event Details")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    Text(viewModel.event.sportType)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button(action: { viewModel.shareEvent() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        // Bottom booking bar pinned
        .safeAreaInset(edge: .bottom) { bottomBar }
        .task {
            await paymentViewModel.checkStatus(activityId: viewModel.event.id)
        }
    }
}

// MARK: - Subviews themed with Theme
private extension EnhancedEventDetailsView {

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(viewModel.event.sportIcon)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(theme.colors.cardBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.cardStroke, lineWidth: 2)
                    )
                    .cornerRadius(14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.event.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(viewModel.event.sportType)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.95))
                }
                Spacer()
            }

            if viewModel.event.coach.isVerified {
                Text("✓ Hosted by Verified Coach")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    infoBox(icon: "calendar", label: "Date", value: viewModel.event.date)
                    infoBox(icon: "line.3.horizontal.decrease", label: "Level", value: viewModel.event.level)
                }
                HStack(spacing: 8) {
                    infoBox(icon: "clock", label: "Start Time", value: viewModel.event.time)
                    infoBox(icon: "clock", label: "End Time", value: viewModel.endTimeText)
                }
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }

    private func infoBox(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11))
                    .opacity(0.9)
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: viewModel.event.coach.avatar)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 2))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.event.coach.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(viewModel.coachRatingText)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                Spacer()
            }

            Text(viewModel.event.coach.bio)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)

            HStack(spacing: 6) {
                ForEach(viewModel.event.coach.certifications, id: \.self) { cert in
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#A855F7"))
                        Text(cert)
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.colors.cardBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }

            HStack(spacing: 8) {
                Button("View Profile") { onViewCoach(viewModel.event.coach.id) }
                    .buttonStyle(BrandButtonStyle(variant: .outline))
                Button(action: openDirectChatWithCoach) {
                    Label("Message", systemImage: "message")
                }
                .buttonStyle(BrandButtonStyle(variant: .outline))
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal, 16)
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(["details", "participants"], id: \.self) { tab in
                Button(action: { viewModel.selectTab(tab) }) {
                    Text(tab.capitalized)
                        .font(.system(size: 12, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(viewModel.selectedTab == tab ? Color(hex: "#A855F7") : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.selectedTab == tab ? Color(hex: "#A855F7") : theme.colors.cardStroke, lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }

    private var tabContent: some View {
        VStack(spacing: 10) {
            if viewModel.selectedTab == "details" {
                availabilityCard
                aboutCard
                locationCard
            } else if viewModel.selectedTab == "participants" {
                participantsList
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut, value: viewModel.selectedTab)
    }

    private var availabilityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Availability")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            VStack(spacing: 6) {
                HStack {
                    Text(viewModel.availabilityText)
                    Spacer()
                    Text(viewModel.spotsLeftText)
                }
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#A855F7"))
                            .frame(width: geo.size.width * viewModel.fillPercentage, height: 8)
                    }
                }
                .frame(height: 8)

                if let warning = viewModel.getAvailabilityWarning() {
                    Text(warning)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EA580C"))
                }
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var aboutCard: some View {
        infoCard(title: "About this session", content: viewModel.event.description)
    }

    private var locationCard: some View {
        let config = locationMapConfig

        return VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(viewModel.event.location)
            }
            .font(.system(size: 12))
            .foregroundColor(theme.colors.textSecondary)

            ZStack {
                Map(
                    coordinateRegion: .constant(config.region),
                    annotationItems: config.annotationItems
                ) { item in
                    MapMarker(coordinate: item.coordinate, tint: Color(hex: "#A855F7"))
                }
                .allowsHitTesting(false)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .frame(height: 280)
            }
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var participantsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.participantsCountText)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
            ForEach(viewModel.participants) { p in
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: p.avatar)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color(hex: "#A855F7"))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 2))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                        Text("Joined this event")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    Spacer()
                    Button("View") {
                        viewModel.viewParticipant(p.id)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.colors.cardBackground)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                    )
                    .cornerRadius(14)
                }
                .padding(12)
                .background(theme.colors.cardBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }

    private var reviewsList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.reviews) { r in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: r.userAvatar)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(theme.colors.cardStroke, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.userName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            Text(r.date)
                                .font(.system(size: 11))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                            Text("\(r.rating)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                    Text(r.comment)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(12)
                .background(theme.colors.cardBackground)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if viewModel.isCoachView {
                    Button("Edit Event") {
                        viewModel.editEvent()
                    }
                    .buttonStyle(BrandButtonStyle(variant: .outline))
                    Button("Manage Participants") {
                        viewModel.manageParticipants()
                    }
                    .buttonStyle(BrandButtonStyle(variant: .default))
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.textSecondary)
                        Text(viewModel.priceDisplay)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#A855F7"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if paymentViewModel.hasPaidForActivity {
                        Button("Check session") {
                            onJoin()
                        }
                        .buttonStyle(BrandButtonStyle(variant: .default))
                    } else {
                        Button("Book Now") {
                            Task {
                                let amount = max(viewModel.event.price, 0)
                                await paymentViewModel.initializePayment(
                                    activityId: viewModel.event.id,
                                    amount: amount,
                                    currency: "eur"
                                )
                                if let sheet = paymentViewModel.paymentSheet,
                                   let root = UIApplication.shared.connectedScenes
                                        .compactMap({ $0 as? UIWindowScene })
                                        .flatMap({ $0.windows })
                                        .first(where: { $0.isKeyWindow })?
                                        .rootViewController {
                                    sheet.present(from: root) { result in
                                        handlePaymentResult(result)
                                    }
                                }
                            }
                        }
                        .buttonStyle(BrandButtonStyle(variant: .default))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.colors.cardBackground.opacity(0.7))
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(theme.colors.cardStroke).frame(height: 1), alignment: .top)
        }
    }

    private func infoCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            Text(content)
                .font(.system(size: 12))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.colors.cardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    /// Starts a one-to-one chat conversation with the coach for this session.
    private func openDirectChatWithCoach() {
        let coachId = viewModel.event.coach.id
        guard !coachId.isEmpty else { return }

        Task {
            do {
                let request = CreateChatRequest(
                    participantIds: [coachId],
                    groupName: nil,
                    groupAvatar: nil
                )
                let chat = try await ChatAPI.createChat(request)
                await MainActor.run {
                    router.select(.chat)
                    router.push(.chatConversation(chatId: chat.id))
                }
            } catch {
                print("Failed to start direct chat with coach: \(error)")
            }
        }
    }
}

// MARK: - Payment Helpers

private extension EnhancedEventDetailsView {
    func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            Task {
                await paymentViewModel.confirmBackendPaymentIfNeeded()
                if paymentViewModel.errorMessage == nil {
                    // Refresh activities so participantIds include the current user,
                    // allowing HomeFeed to show the correct joined state.
                    await activityAPIService.fetchAllActivities()
                    await activityAPIService.fetchMyActivities()
                    showPaymentSuccessPopup = true
                }
            }
        case .failed:
            paymentViewModel.errorMessage = "Payment failed. Please try again."
        case .canceled:
            break
        }
    }
}

// MARK: - Map Helpers

private extension EnhancedEventDetailsView {
    var locationMapConfig: (region: MKCoordinateRegion, annotationItems: [EventLocationAnnotation]) {
        if let lat = viewModel.event.latitude,
           let lon = viewModel.event.longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            let annotations = [EventLocationAnnotation(coordinate: coordinate)]
            return (region, annotations)
        } else {
            let fallbackCoordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
            let region = MKCoordinateRegion(
                center: fallbackCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            return (region, [])
        }
    }
}

// MARK: - Map Annotations

private struct EventLocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - SafariView Wrapper for Payment Page

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var onFinish: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
        // No-op
    }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        private let onFinish: (() -> Void)?

        init(onFinish: (() -> Void)?) {
            self.onFinish = onFinish
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onFinish?()
        }
    }
}

// MARK: - Preview
struct EnhancedEventDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EnhancedEventDetailsView(
                eventId: "1",
                onBack: {},
                onJoin: {},
                onViewCoach: { _ in },
                isCoachView: false
            )
            .environmentObject(Theme())
        }
    }
}

