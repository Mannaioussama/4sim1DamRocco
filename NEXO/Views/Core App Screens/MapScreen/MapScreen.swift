//
//  MapScreen.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import MapKit

struct MapScreen: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var activityAPIService: ActivityAPIService
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var viewModel = MapScreenViewModel()
    
    var onActivityClick: (Activity) -> Void
    var onChatClick: ((Activity) -> Void)? = nil
    
    var body: some View {
        ZStack {
            backgroundView
            floatingOrbs
            mainContent
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Attempt to center on user immediately if permission already granted.
            viewModel.handleViewAppeared()
            // If we already have backend activities loaded, use them immediately
            if !activityAPIService.activities.isEmpty {
                viewModel.updateActivities(activityAPIService.activities)
            } else if !activityAPIService.isLoading {
                // First open and nothing loaded yet: trigger initial fetch.
                // Pins will appear when the service publishes activities and onChange fires.
                Task {
                    await activityAPIService.fetchAllActivities()
                }
            }
        }
        .onChange(of: activityAPIService.activities) { newActivities in
            viewModel.updateActivities(newActivities)
        }
        .alert(localizationManager.localized("map.alert.chooseApp"), isPresented: $viewModel.showingDirectionsAlert) {
            Button(localizationManager.localized("map.alert.appleMaps")) {
                viewModel.openInAppleMaps()
            }
            Button(localizationManager.localized("map.alert.googleMaps")) {
                viewModel.openInGoogleMaps()
            }
            Button(localizationManager.localized("common.cancel"), role: .cancel) { }
        } message: {
            let fallbackName = localizationManager.localized("activityRoom.activity.unknownTitle")
            let activityName = viewModel.selectedActivityForDirections?.title ?? fallbackName
            Text(
                String(
                    format: localizationManager.localized("map.alert.chooseApp.messageFormat"),
                    activityName
                )
            )
        }
    }
    
    // MARK: - Background & Decorative Views
    
    private var backgroundView: some View {
        theme.colors.backgroundGradient
            .ignoresSafeArea()
    }
    
    private var floatingOrbs: some View {
        Group {
            FloatingOrb(
                size: 288,
                color: LinearGradient(
                    colors: [
                        Color(hex: "C4B5FD").opacity(0.4),
                        Color(hex: "F9A8D4").opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: -100,
                yOffset: -200,
                delay: 0
            )
            
            FloatingOrb(
                size: 384,
                color: LinearGradient(
                    colors: [
                        Color(hex: "93C5FD").opacity(0.3),
                        Color(hex: "C4B5FD").opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 150,
                yOffset: 500,
                delay: 1
            )
            
            FloatingOrb(
                size: 256,
                color: LinearGradient(
                    colors: [
                        Color(hex: "FBC4E4").opacity(0.3),
                        Color(hex: "DDD6FE").opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                xOffset: 150,
                yOffset: -100,
                delay: 2
            )
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isMapMode {
                mapView
            } else {
                listView
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text(localizationManager.localized("map.loading"))
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 0) {
            headerTopSection
            viewToggleSection
        }
        .padding(16)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private var headerTopSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(localizationManager.localized("map.header.title"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .tracking(-0.5)
                
                Text(localizationManager.localized("map.header.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            sparklesButton
        }
        .padding(.bottom, 12)
    }
    
    private var sparklesButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.accentPurple,
                            theme.colors.accentPink
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
        .frame(width: 44, height: 44)
        .shadow(color: theme.colors.accentPurple.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var viewToggleSection: some View {
        HStack(spacing: 6) {
            mapToggleButton
            listToggleButton
        }
        .padding(6)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private var mapToggleButton: some View {
        Button(action: {
            viewModel.switchToMapMode()
            viewModel.trackViewModeChanged(.map)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "map")
                    .font(.system(size: 16))
                
                Text(localizationManager.localized("map.toggle.map"))
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(viewModel.isMapMode ? .white : theme.colors.textSecondary)
            .background(viewModel.isMapMode ? theme.colors.accentGreen : Color.clear)
            .cornerRadius(12)
            .shadow(color: viewModel.isMapMode ? .black.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
        }
    }
    
    private var listToggleButton: some View {
        Button(action: {
            viewModel.switchToListMode()
            viewModel.trackViewModeChanged(.list)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16))
                
                Text(localizationManager.localized("map.toggle.list"))
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(viewModel.isListMode ? .white : theme.colors.textSecondary)
            .background(viewModel.isListMode ? theme.colors.accentGreen : Color.clear)
            .cornerRadius(12)
            .shadow(color: viewModel.isListMode ? .black.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        ZStack {
            Map(position: $viewModel.position) {
                UserAnnotation()
                
                // Dynamic activity annotations from database, filtered by distance & other filters
                ForEach(viewModel.filteredActivities) { activity in
                    if let coordinate = activity.coordinate {
                        Annotation("", coordinate: coordinate) {
                            Button {
                                viewModel.selectActivity(activity)
                                viewModel.trackActivitySelected(activity)
                            } label: {
                                ActivityMapPin(activity: activity, isSelected: viewModel.isActivitySelected(activity))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
            .id(viewModel.mapReloadToken)
            .onMapCameraChange { context in
                viewModel.updateRegion(context.region)
            }
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 16)
            
            // Map Controls
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    mapControlsView
                }
            }
            
            // Selected Activity Card
            if let activity = viewModel.selectedActivity {
                VStack {
                    Spacer()
                    
                    SelectedActivityCard(
                        activity: activity,
                        onClose: {
                            viewModel.deselectActivity()
                        },
                        onJoin: {
                            viewModel.joinActivity(activity)
                            viewModel.trackActivityJoin(activity)
                            onActivityClick(activity)
                        },
                        onDirections: {
                            viewModel.requestDirections(for: activity)
                        },
                        onChat: {
                            if let onChatClick {
                                onChatClick(activity)
                            } else {
                                viewModel.trackChatRequested(activity)
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private var mapControlsView: some View {
        VStack(spacing: 8) {
            // Zoom Controls
            VStack(spacing: 0) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.zoomIn()
                        viewModel.trackZoomIn()
                    }
                }) {
                    Text("+")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                
                Divider()
                    .background(theme.colors.cardStroke)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.zoomOut()
                        viewModel.trackZoomOut()
                    }
                }) {
                    Text("−")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 44, height: 44)
                }
            }
            .frame(width: 44)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Location Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.centerOnUser()
                    viewModel.trackCenterOnUser()
                }
            }) {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Filters Button
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            .background(theme.colors.accentPurple)
            .cornerRadius(16)
            .shadow(color: theme.colors.accentPurple.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, viewModel.hasSelectedActivity ? 180 : 60)
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Why This Section
                whyTheseSection
                
                // Activity Cards (Dynamic from database)
                ForEach(viewModel.filteredActivities) { activity in
                    AIActivityCard(
                        activity: activity,
                        isSaved: viewModel.isSaved(activity.id),
                        onToggleSave: {
                            viewModel.toggleSave(activity.id)
                            viewModel.trackActivitySave(activity)
                        },
                        onJoin: {
                            viewModel.joinActivity(activity)
                            viewModel.trackActivityJoin(activity)
                            onActivityClick(activity)
                        }
                    )
                    .environmentObject(theme)
                    .onAppear {
                        viewModel.trackActivityView(activity)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
    }
    
    private var personalizedBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.colors.cardBackground)
                    .background(theme.colors.barMaterial)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(localizationManager.localized("map.banner.personalizedTitle"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(localizationManager.localized("map.banner.personalizedDescription"))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    theme.colors.accentPurple,
                    theme.colors.accentPink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: theme.colors.accentPurple.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var whyTheseSection: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.colors.accentPurple,
                                theme.colors.accentPink
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(localizationManager.localized("map.whyThese.title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(localizationManager.localized("map.whyThese.description"))
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.userCoordinate != nil {
                    // Dynamic radius description and selector when we have the user's location
                    VStack(alignment: .leading, spacing: 6) {
                        let radiusKm = max(viewModel.selectedRadius / 1000, 0)
                        Text("Showing sessions within \(Int(radiusKm)) km of your location.")
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.textSecondary)

                        HStack(spacing: 6) {
                            let options: [Double] = [1, 3, 5]
                            ForEach(options.indices, id: \.self) { index in
                                let km = options[index]
                                let isSelected = abs((viewModel.selectedRadius / 1000) - km) < 0.01
                                Button(action: {
                                    viewModel.setRadiusInKilometers(km)
                                }) {
                                    Text("\(Int(km)) km")
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isSelected ? theme.colors.accentPurple.opacity(0.15) : theme.colors.cardBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isSelected ? theme.colors.accentPurple : theme.colors.cardStroke, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.cardStroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Activity Pin

struct ActivityPin: View {
    let activity: Activity
    let isSelected: Bool
    let position: CGPoint
    let onTap: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            Button(action: onTap) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "A855F7").opacity(0.2))
                            .frame(width: 48, height: 48)
                            .offset(y: 24)
                    }
                    
                    // Pin body
                    ZStack {
                        Ellipse()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 12, height: 6)
                            .blur(radius: 2)
                            .offset(y: 48)
                        
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "A855F7"))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                
                                Text(activity.sportIcon)
                                    .font(.system(size: 18))
                            }
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Triangle()
                                .fill(Color(hex: "A855F7"))
                                .frame(width: 12, height: 8)
                                .offset(y: -1)
                        }
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .position(
                x: width * position.x,
                y: height * position.y
            )
        }
    }
}

// MARK: - Activity Map Pin

struct ActivityMapPin: View {
    let activity: Activity
    let isSelected: Bool
    
    private var isCoachSession: Bool {
        activity.isPaidSession
    }
    
    private var pinColor: Color {
        isCoachSession ? Color(hex: "A855F7") : Color(hex: "3B82F6")
    }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(pinColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .offset(y: 24)
            }
            
            VStack(spacing: 0) {
                // AI Sparkle Indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "3B82F6"),
                                    Color(hex: "60A5FA")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .frame(width: 18, height: 18)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .offset(x: 12, y: 8)
                .zIndex(10)
                
                // Pin body
                ZStack {
                    Ellipse()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 12, height: 6)
                        .blur(radius: 2)
                        .offset(y: 48)
                    
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(pinColor)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                            
                            Text(activity.sportIcon)
                                .font(.system(size: 18))
                        }
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Triangle()
                            .fill(pinColor)
                            .frame(width: 12, height: 8)
                            .offset(y: -1)
                    }
                }
            }
        }
    }
}

// MARK: - Selected Activity Card

struct SelectedActivityCard: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager
    let activity: Activity
    let onClose: () -> Void
    let onJoin: () -> Void
    let onDirections: () -> Void
    let onChat: () -> Void
    
    var spotsLeft: Int {
        activity.spotsTotal - activity.spotsTaken
    }

    private var isCoachSession: Bool {
        activity.isPaidSession
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row with profile, name, label, and close button
                HStack(alignment: .center, spacing: 12) {
                    // Profile Image
                    AsyncImage(url: URL(string: activity.hostAvatar)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    
                    // Name and Individual Label
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(activity.hostName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Text(
                                isCoachSession
                                ? localizationManager.localized("map.selected.hostType.coach")
                                : localizationManager.localized("map.selected.hostType.individual")
                            )
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isCoachSession ? Color(hex: "A855F7") : Color(hex: "3B82F6"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    (isCoachSession ? Color(hex: "A855F7") : Color(hex: "3B82F6")).opacity(0.1)
                                )
                                .cornerRadius(12)
                        }
                        
                        // Sport Type
                        Text(activity.sportType)
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 12)
                
                // Session Title
                Text(activity.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(.bottom, 12)
                
                // Date and Time
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "3B82F6"))
                    
                    Text("\(activity.date) • \(activity.time)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.bottom, 12)
                
                // Remaining Spots
                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "3B82F6"))
                    
                    Text(
                        String(
                            format: localizationManager.localized("map.selected.spotsLeftFormat"),
                            activity.spotsLeft
                        )
                    )
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.bottom, 12)
                
                // Level and Action Buttons in same row
                HStack(alignment: .center, spacing: 12) {
                    // Level
                    HStack(spacing: 6) {
                        Image(systemName: "star")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "3B82F6"))
                        
                        Text(activity.level)
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Action Buttons - Stacked vertically
                    VStack(spacing: 8) {
                        Button(action: onDirections) {
                            HStack(spacing: 6) {
                                Image(systemName: "location")
                                    .font(.system(size: 14))
                                Text(localizationManager.localized("map.selected.directionsButton"))
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "3B82F6"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "3B82F6"), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        if isCoachSession {
                            Button(action: onJoin) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 14))
                                    Text(localizationManager.localized("map.selected.joinButton"))
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(hex: "86EFAC"))
                                .cornerRadius(8)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        } else {
                            Button(action: onChat) {
                                HStack(spacing: 6) {
                                    Image(systemName: "message")
                                        .font(.system(size: 14))
                                    Text(localizationManager.localized("map.selected.chatNowButton"))
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(Color(hex: "10B981"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "10B981"), lineWidth: 1)
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .padding(20)
            .padding(.top, 30)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(theme.colors.cardBackground)
                    .clipShape(Circle())
            }
            .padding(16)
        }
        .environmentObject(theme)
    }
}

// MARK: - AI Activity Card

struct AIActivityCard: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var localizationManager: LocalizationManager

    let activity: Activity
    let isSaved: Bool
    let onToggleSave: () -> Void
    let onJoin: () -> Void
    
    var spotsLeft: Int {
        activity.spotsTotal - activity.spotsTaken
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Host info
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: activity.hostAvatar)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(String(activity.hostName.prefix(1)))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "A855F7"))
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.hostName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        HStack(spacing: 6) {
                            Text(activity.sportIcon)
                                .font(.system(size: 12))
                            
                            Text(activity.sportType)
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                .padding(.trailing, 70)
                
                // Title
                Text(activity.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .lineSpacing(2)
                    .padding(.bottom, 10)
                
                // Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("\(activity.date) • \(activity.time)")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("\(activity.location) • \(activity.distance)")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(
                            String(
                                format: localizationManager.localized("map.aiCard.spotsRemainingFormat"),
                                spotsLeft,
                                activity.spotsTotal
                            )
                        )
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .padding(.bottom, 10)
                
                // Actions
                HStack {
                    Text(activity.level)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "A855F7"))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Button(action: onToggleSave) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isSaved ? Color(hex: "EF4444") : theme.colors.textSecondary.opacity(0.6))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onJoin) {
                        Text(localizationManager.localized("map.aiCard.joinButton"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color(hex: "86EFAC"))
                            .cornerRadius(20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(14)
            .padding(.top, 24)
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.cardStroke, lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            // AI Badge
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                
                Text(localizationManager.localized("map.aiCard.badge.aiPick"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "A855F7"),
                        Color(hex: "EC4899")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .padding(.top, 10)
            .padding(.trailing, 10)
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    MapScreen(onActivityClick: { _ in }, onChatClick: { _ in })
        .environmentObject(Theme())
        .environmentObject(ActivityAPIService())
}

