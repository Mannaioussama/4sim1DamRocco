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
    @StateObject private var viewModel = MapScreenViewModel()
    
    var onActivityClick: (Activity) -> Void
    
    var body: some View {
        ZStack {
            backgroundView
            floatingOrbs
            mainContent
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
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
            Text("Loading AI suggestions...")
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
                Text(viewModel.headerTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .tracking(-0.5)
                
                Text(viewModel.headerSubtitle)
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
                
                Text("Map")
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
                
                Text("List")
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
            }
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
            
            // Activity Pins
            ForEach(Array(viewModel.aiSuggestions.enumerated()), id: \.element.id) { index, activity in
                ActivityPin(
                    activity: activity,
                    isSelected: viewModel.isActivitySelected(activity),
                    position: viewModel.getPinPosition(for: index),
                    onTap: {
                        viewModel.selectActivity(activity)
                        viewModel.trackActivitySelected(activity)
                    }
                )
            }
            
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
                // AI Info Banner
                personalizedBanner
                
                // Why This Section
                whyTheseSection
                
                // Activity Cards
                ForEach(viewModel.aiSuggestions) { activity in
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
                Text(viewModel.personalizedTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(viewModel.personalizedDescription)
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
                Text(viewModel.whyTheseTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(viewModel.whyTheseDescription)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                    
                    VStack(spacing: 0) {
                        // AI Sparkle Indicator
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "A855F7"),
                                            Color(hex: "EC4899")
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
            }
            .buttonStyle(ScaleButtonStyle())
            .position(
                x: width * position.x,
                y: height * position.y
            )
        }
    }
}

// MARK: - Selected Activity Card

struct SelectedActivityCard: View {
    @EnvironmentObject private var theme: Theme
    let activity: Activity
    let onClose: () -> Void
    let onJoin: () -> Void
    
    var spotsLeft: Int {
        activity.spotsTotal - activity.spotsTaken
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // AI Badge
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    
                    Text("AI Pick")
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
                .offset(x: -10, y: -10)
                
                // Host info
                HStack(spacing: 12) {
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
                        
                        HStack(spacing: 8) {
                            Text(activity.sportIcon)
                                .font(.system(size: 20))
                            
                            Text(activity.sportType)
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                .padding(.bottom, 12)
                
                // Title
                Text(activity.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(.bottom, 8)
                
                // Details
                Text("\(activity.date) • \(activity.time) • \(activity.distance)")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.bottom, 12)
                
                // Actions
                HStack {
                    Text("\(spotsLeft) spots left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "A855F7"))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Directions")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                            .cornerRadius(20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onJoin) {
                        Text("Join")
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
                        
                        Text("\(spotsLeft) of \(activity.spotsTotal) spots remaining")
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
                        Text("Join")
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
                
                Text("AI Pick")
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
    MapScreen(onActivityClick: { _ in })
        .environmentObject(Theme())
}
