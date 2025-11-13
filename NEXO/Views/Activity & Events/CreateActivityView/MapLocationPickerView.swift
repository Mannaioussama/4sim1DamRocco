//
//  MapLocationPickerView.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import SwiftUI
import MapKit

struct MapLocationPickerView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var theme: Theme
    
    // MARK: - ViewModel
    @StateObject private var viewModel = MapLocationPickerViewModel()
    
    // MARK: - Properties
    var onLocationSelected: (MapLocationModel) -> Void
    
    var body: some View {
        ZStack {
            // Background
            theme.colors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(theme.colors.cardBackground)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("Pick Location on Map")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("Tap anywhere on the map to select your location")
                            .font(.system(size: 13))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Invisible spacer for symmetry
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Map
                ZStack {
                    MapView(
                        coordinate: Binding(
                            get: { viewModel.selectedCoordinate },
                            set: { _ in }
                        ),
                        onTap: { coordinate in
                            viewModel.selectLocation(at: coordinate)
                        }
                    )
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    
                    // Compass button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { viewModel.resetToUserLocation() }) {
                                Text("N")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.red)
                                    .frame(width: 48, height: 48)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 36)
                            .padding(.top, 20)
                        }
                        Spacer()
                    }
                    
                    // Zoom controls
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Button(action: { viewModel.zoomIn() }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(theme.colors.textPrimary)
                                        .frame(width: 48, height: 48)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                }
                                
                                Button(action: { viewModel.zoomOut() }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(theme.colors.textPrimary)
                                        .frame(width: 48, height: 48)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                }
                            }
                            .padding(.trailing, 36)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Selected Location Card
                if let location = viewModel.selectedLocation {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.orange)
                            }
                            
                            // Location info
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Selected Location")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.colors.textSecondary)
                                
                                if viewModel.isLoadingAddress {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Fetching address...")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(theme.colors.textPrimary)
                                    }
                                } else {
                                    Text(location.displayName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(theme.colors.textPrimary)
                                        .lineLimit(2)
                                }
                                
                                Text("Coordinates: \(location.coordinate.formatted)")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .cornerRadius(28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        if let location = viewModel.selectedLocation {
                            viewModel.saveToRecent(location)
                            onLocationSelected(location)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("Confirm Location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color.orange.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!viewModel.canConfirmLocation)
                    .opacity(viewModel.canConfirmLocation ? 1.0 : 0.6)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Preview
struct MapLocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        MapLocationPickerView { location in
            print("Selected: \(location.displayName) at \(location.coordinate.formatted)")
        }
        .environmentObject(Theme())
    }
}
