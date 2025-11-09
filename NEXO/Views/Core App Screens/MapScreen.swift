//
//  MapScreen.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI
import MapKit
import Combine
import CoreLocation

enum ViewMode {
    case map
    case list
}

struct MapScreen: View {
    @EnvironmentObject private var theme: Theme

    @State private var selectedActivity: Activity? = nil
    @State private var viewMode: ViewMode = .map
    @State private var savedActivities = Set<String>()
    @StateObject private var mapViewModel = MapViewModel()
    
    var onActivityClick: (Activity) -> Void
    
    // AI-suggested activities
    let aiSuggestions: [Activity] = [
        Activity(
            id: "ai-1",
            title: "Morning Beach Volleyball Match",
            sportType: "Volleyball",
            sportIcon: "🏐",
            hostName: "Emma Wilson",
            hostAvatar: "https://i.pravatar.cc/150?img=5",
            date: "Today",
            time: "8:00 AM",
            location: "Santa Monica Beach",
            distance: "1.2 mi",
            spotsTotal: 12,
            spotsTaken: 8,
            level: "Intermediate"
        ),
        Activity(
            id: "ai-2",
            title: "Evening Running Group",
            sportType: "Running",
            sportIcon: "🏃",
            hostName: "Michael Chen",
            hostAvatar: "https://i.pravatar.cc/150?img=12",
            date: "Today",
            time: "6:30 PM",
            location: "Central Park",
            distance: "0.8 mi",
            spotsTotal: 15,
            spotsTaken: 10,
            level: "All Levels"
        ),
        Activity(
            id: "ai-3",
            title: "Yoga & Meditation Session",
            sportType: "Yoga",
            sportIcon: "🧘",
            hostName: "Sarah Johnson",
            hostAvatar: "https://i.pravatar.cc/150?img=9",
            date: "Tomorrow",
            time: "7:00 AM",
            location: "Zen Studio",
            distance: "1.5 mi",
            spotsTotal: 20,
            spotsTaken: 15,
            level: "Beginner"
        ),
        Activity(
            id: "ai-4",
            title: "Pickup Basketball Game",
            sportType: "Basketball",
            sportIcon: "🏀",
            hostName: "James Rodriguez",
            hostAvatar: "https://i.pravatar.cc/150?img=15",
            date: "Tomorrow",
            time: "5:00 PM",
            location: "Downtown Court",
            distance: "2.1 mi",
            spotsTotal: 10,
            spotsTaken: 7,
            level: "Intermediate"
        )
    ]
    
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
            
            if viewMode == .map {
                mapView
            } else {
                listView
            }
        }
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
                Text("Sessions")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .tracking(-0.5)
                
                Text("AI-powered recommendations")
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
        Button(action: { viewMode = .map }) {
            HStack(spacing: 8) {
                Image(systemName: "map")
                    .font(.system(size: 16))
                
                Text("Map")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(viewMode == .map ? .white : theme.colors.textSecondary)
            .background(viewMode == .map ? theme.colors.accentGreen : Color.clear)
            .cornerRadius(12)
            .shadow(color: viewMode == .map ? .black.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
        }
    }
    
    private var listToggleButton: some View {
        Button(action: { viewMode = .list }) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16))
                
                Text("List")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(viewMode == .list ? .white : theme.colors.textSecondary)
            .background(viewMode == .list ? theme.colors.accentGreen : Color.clear)
            .cornerRadius(12)
            .shadow(color: viewMode == .list ? .black.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        ZStack {
            RealMapView(viewModel: mapViewModel)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 16)
            
            ForEach(Array(aiSuggestions.enumerated()), id: \.element.id) { index, activity in
                ActivityPin(
                    activity: activity,
                    isSelected: selectedActivity?.id == activity.id,
                    position: pinPosition(for: index),
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedActivity = activity
                        }
                    }
                )
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // Zoom Controls
                        VStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    mapViewModel.zoomIn()
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
                                    mapViewModel.zoomOut()
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
                                mapViewModel.centerOnUser()
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
                    .padding(.bottom, selectedActivity != nil ? 180 : 60)
                }
            }
            
            if let activity = selectedActivity {
                VStack {
                    Spacer()
                    
                    SelectedActivityCard(
                        activity: activity,
                        onClose: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedActivity = nil
                            }
                        },
                        onJoin: {
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
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // AI Info Banner
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
                        Text("Personalized For You")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Based on your activity & preferences")
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
                
                // Why This Section
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
                        Text("Why these activities?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("We've selected activities matching your skill level, preferred sports, and typical schedule. These are nearby and have availability.")
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
                
                // Activity Cards
                ForEach(aiSuggestions) { activity in
                    AIActivityCard(
                        activity: activity,
                        isSaved: savedActivities.contains(activity.id),
                        onToggleSave: { toggleSave(activity.id) },
                        onJoin: { onActivityClick(activity) }
                    )
                    .environmentObject(theme)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleSave(_ id: String) {
        if savedActivities.contains(id) {
            savedActivities.remove(id)
        } else {
            savedActivities.insert(id)
        }
    }
    
    private func pinPosition(for index: Int) -> CGPoint {
        let positions: [(CGFloat, CGFloat)] = [
            (0.32, 0.22),
            (0.62, 0.38),
            (0.28, 0.52),
            (0.72, 0.68)
        ]
        let position = positions[index % positions.count]
        return CGPoint(x: position.0, y: position.1)
    }
}

// MARK: - Map ViewModel

class MapViewModel: ObservableObject {
    @Published var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @Published var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private let locationManager = CLLocationManager()
    
    init() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func zoomIn() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(currentRegion.span.latitudeDelta * 0.5, 0.001),
            longitudeDelta: max(currentRegion.span.longitudeDelta * 0.5, 0.001)
        )
        currentRegion.span = newSpan
        position = .region(currentRegion)
    }
    
    func zoomOut() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentRegion.span.latitudeDelta * 2.0, 180),
            longitudeDelta: min(currentRegion.span.longitudeDelta * 2.0, 180)
        )
        currentRegion.span = newSpan
        position = .region(currentRegion)
    }
    
    func centerOnUser() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        position = .userLocation(fallback: .automatic)
    }
}

// MARK: - Real Map View with MapKit

struct RealMapView: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        Map(position: $viewModel.position) {
            UserAnnotation()
        }
        .onMapCameraChange { context in
            viewModel.currentRegion = context.region
        }
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
