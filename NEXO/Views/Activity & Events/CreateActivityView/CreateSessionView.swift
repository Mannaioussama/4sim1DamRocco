import SwiftUI

struct CreateSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var activityAPIService: ActivityAPIService
    @StateObject private var viewModel = CreateActivityViewModel()

    // Extra local state for end time (backend will still use start time for now)
    @State private var endTime: Date = Date()

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
                        fieldGroup(title: "Session Title *") {
                            HStack(spacing: 12) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.colors.textSecondary)
                                TextField("e.g., Evening strength session", text: $viewModel.title)
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

                        // Price per Session
                        fieldGroup(title: "Price per Session *") {
                            HStack(spacing: 12) {
                                Image(systemName: "dollarsign.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.colors.textSecondary)

                                TextField("e.g., 20", text: $viewModel.price)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 15))
                                    .foregroundColor(theme.colors.textPrimary)

                                Text("USD")
                                    .font(.system(size: 13, weight: .semibold))
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
                                    Text("Describe the focus of this session...")
                                        .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                                        .font(.system(size: 15))
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }

                        // Location with Map Picker
                        fieldGroup(title: "Location *") {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.colors.textSecondary)

                                TextField("Enter address or venue name", text: $viewModel.location)
                                    .font(.system(size: 15))
                                    .foregroundColor(theme.colors.textPrimary)

                                Button(action: {
                                    viewModel.showMapPicker = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 14))
                                        Text("Pick from Map")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.purple, Color.purple.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(20)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
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

                        // Date & Time (with session start/end)
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

                            // Start / End Session
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start Session *")
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

                                Text("End Session")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.colors.textSecondary)

                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 18))
                                        .foregroundColor(theme.colors.textSecondary)
                                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
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
                        fieldGroup(title: "Participants") {
                            HStack(spacing: 12) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.colors.textSecondary)

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Max participants: \(viewModel.participantsCount)")
                                            .font(.system(size: 14))
                                            .foregroundColor(theme.colors.textPrimary)
                                        Spacer()
                                    }

                                    Slider(value: $viewModel.participants, in: 2...20, step: 1)
                                        .tint(theme.colors.accentPurple)
                                }
                            }
                            .padding(16)
                            .background(theme.colors.cardBackground)
                            .background(theme.colors.barMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.colors.cardStroke, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(theme.isDarkMode ? 0.25 : 0.05), radius: 4, x: 0, y: 2)
                        }

                        // Level
                        fieldGroup(title: "Level *") {
                            Menu {
                                ForEach(viewModel.skillLevels, id: \.self) { level in
                                    Button(level) {
                                        viewModel.selectLevel(level)
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 20))
                                        .foregroundColor(theme.colors.textSecondary)
                                    Text(viewModel.level.isEmpty ? "Select level" : viewModel.level)
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
                                Task {
                                    await viewModel.createActivity(using: activityAPIService, isCoachSession: true)
                                }
                            }) {
                                ZStack {
                                    Text(viewModel.isSaving ? "Creating..." : "Create Session")
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

                                    if viewModel.isSaving {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                            }
                            .disabled(!viewModel.isFormValid || viewModel.price.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSaving)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Create Session")
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
        .sheet(isPresented: $viewModel.showMapPicker) {
            MapLocationPickerView { location in
                viewModel.setLocation(name: location.displayName, coordinate: location.coordinate.clCoordinate)
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

#Preview {
    NavigationStack {
        CreateSessionView()
            .environmentObject(Theme())
            .environmentObject(ActivityAPIService())
    }
}
