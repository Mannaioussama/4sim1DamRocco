//
//  CreateActivityView.swift
//  NEXO
//
//  Created by ROCCO 4X on 3/11/2025.
//

import SwiftUI

struct CreateActivityView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var theme: Theme
    @StateObject private var viewModel = CreateActivityViewModel()

    var body: some View {
        ZStack {
            // Themed background + orbs
            theme.colors.backgroundGradient.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 0) {
                // Form
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Sport Type
                        fieldGroup(title: "Sport Type *") {
                            Menu {
                                ForEach(viewModel.sportCategories, id: \.1) { item in
                                    let (icon, name) = item
                                    Button("\(icon) \(name)") {
                                        viewModel.selectSport(name)
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    if let emoji = viewModel.selectedSportEmoji {
                                        Text(emoji)
                                            .font(.system(size: 18))
                                    } else {
                                        Image(systemName: "sportscourt.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(theme.colors.textSecondary)
                                    }
                                    Text(viewModel.sportType.isEmpty ? "Select a sport" : viewModel.sportType)
                                        .font(.system(size: 15))
                                        .foregroundColor(viewModel.sportType.isEmpty ? theme.colors.textSecondary : theme.colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                            }
                            .tint(theme.colors.textPrimary)
                        }

                        // Title
                        fieldGroup(title: "Activity Title *") {
                            HStack(spacing: 12) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.colors.textSecondary)
                                TextField("e.g., Morning run at the park", text: $viewModel.title)
                                    .font(.system(size: 15))
                                    .foregroundColor(theme.colors.textPrimary)
                            }
                            .padding(16)
                            .frame(height: 56)
                            .background(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                        }

                        // Description
                        fieldGroup(title: "Description") {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $viewModel.description)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 120)
                                    .padding(12)
                                    .foregroundColor(theme.colors.textPrimary)
                                    .background(theme.colors.cardBackground)
                                    .background(theme.colors.barMaterial)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(theme.colors.cardStroke, lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)

                                if viewModel.description.isEmpty {
                                    Text("Tell participants what to expect...")
                                        .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                                        .font(.system(size: 15))
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }

                        // Location
                        fieldGroup(title: "Location *") {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.colors.textSecondary)
                                TextField("Enter address or venue name", text: $viewModel.location)
                                    .font(.system(size: 15))
                                    .foregroundColor(theme.colors.textPrimary)
                            }
                            .padding(16)
                            .frame(height: 56)
                            .background(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                        }

                        // Date & Time
                        HStack(spacing: 12) {
                            // Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date *")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.colors.textPrimary)

                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 20))
                                        .foregroundColor(theme.colors.textSecondary)
                                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                        .labelsHidden()
                                        .font(.system(size: 15))
                                        .tint(theme.colors.accentPurple)
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                            }

                            // Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time *")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.colors.textPrimary)

                                HStack(spacing: 12) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 20))
                                        .foregroundColor(theme.colors.textSecondary)
                                    DatePicker("", selection: $viewModel.time, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .font(.system(size: 15))
                                        .tint(theme.colors.accentPurple)
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                            }
                        }

                        // Participants
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(theme.colors.textPrimary)
                                Text("Number of Participants: \(viewModel.participantsCount)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(theme.colors.textPrimary)
                            }

                            Slider(value: $viewModel.participants, in: 2...20, step: 1)
                                .tint(theme.colors.accentPurple)

                            HStack {
                                Text("2")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textSecondary)
                                Spacer()
                                Text("20")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }

                        // Skill Level
                        fieldGroup(title: "Skill Level *") {
                            Menu {
                                ForEach(viewModel.skillLevels, id: \.self) { lvl in
                                    Button(action: { viewModel.selectLevel(lvl) }) {
                                        Text(lvl)
                                            .font(.system(size: 16))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.level.isEmpty ? "Select skill level" : viewModel.level)
                                        .font(.system(size: 15))
                                        .foregroundColor(viewModel.level.isEmpty ? theme.colors.textSecondary : theme.colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                            }
                            .tint(theme.colors.textPrimary)
                        }

                        // Visibility
                        fieldGroup(title: "Visibility") {
                            Menu {
                                Button(action: { viewModel.setVisibility("public") }) {
                                    Text("Public - Anyone can join")
                                        .font(.system(size: 16))
                                }
                                Button(action: { viewModel.setVisibility("friends") }) {
                                    Text("Friends Only")
                                        .font(.system(size: 16))
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.visibilityDisplayText)
                                        .font(.system(size: 15))
                                        .foregroundColor(theme.colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(theme.colors.cardBackground)
                                .background(theme.colors.barMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.cardStroke, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                            }
                            .tint(theme.colors.textPrimary)
                        }

                        // Buttons
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
                                viewModel.createActivity()
                            }) {
                                Text("Create Room")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [theme.colors.accentGreenFill, theme.colors.accentGreenGlow],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(28)
                                    .shadow(color: theme.colors.accentGreenGlow.opacity(0.35), radius: 8, x: 0, y: 4)
                            }
                            .disabled(!viewModel.isFormValid)
                            .opacity(viewModel.isFormValid ? 1.0 : 0.6)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Create Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(theme.colors.barMaterial, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.showSuccess) {
            SuccessDialog {
                viewModel.showSuccess = false
                presentationMode.wrappedValue.dismiss()
            }
            .environmentObject(theme)
        }
    }

    // MARK: - Subview for field group
    @ViewBuilder
    private func fieldGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            content()
        }
    }
    
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.accentPurpleFill.opacity(theme.isDarkMode ? 0.25 : 0.4),
                            theme.colors.accentPink.opacity(theme.isDarkMode ? 0.2 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(theme.isDarkMode ? 0.22 : 0.3),
                            theme.colors.accentPurpleFill.opacity(theme.isDarkMode ? 0.18 : 0.2)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 180, y: 500)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.accentPink.opacity(theme.isDarkMode ? 0.18 : 0.3),
                            theme.colors.accentPurpleGlow.opacity(theme.isDarkMode ? 0.14 : 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 150, y: -50)
        }
        .allowsHitTesting(false)
    }
}

struct SuccessDialog: View {
    @EnvironmentObject private var theme: Theme
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.colors.accentGreenFill.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text("🎉")
                    .font(.system(size: 50))
            }
            
            Text("Your session is live!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            
            Text("Your activity has been created. Share the link with friends or wait for others to join.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Text("Close")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(theme.colors.cardBackground)
                        .background(theme.colors.barMaterial)
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(theme.colors.cardStroke, lineWidth: 1)
                        )
                }
                
                Button(action: onClose) {
                    Text("Share Link")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [theme.colors.accentGreenFill, theme.colors.accentGreenGlow],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .padding(.vertical, 30)
        .presentationDetents([.medium])
    }
}

// MARK: - Preview
struct CreateActivityView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreateActivityView()
                .environmentObject(Theme())
        }
    }
}
