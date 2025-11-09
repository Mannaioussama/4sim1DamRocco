//
//  EditProfileView.swift
//  NEXO
//
//  Created by ChatGPT on 11/8/2025.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: Theme

    var onBack: (() -> Void)?
    var onSave: (() -> Void)?

    // Profile form state (mirrors the React example)
    @State private var name: String = "Alex Johnson"
    @State private var email: String = "alex.johnson@email.com"
    @State private var phone: String = "+1 (555) 123-4567"
    @State private var bio: String = "Passionate about sports and staying active! Love meeting new people through fitness."
    @State private var location: String = "San Francisco, CA"
    @State private var dateOfBirth: Date = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: "1995-06-15") ?? Calendar.current.date(byAdding: .year, value: -30, to: .now)!
    }()

    // Avatar
    @State private var avatarURL: String = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop"
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImageData: Data?

    // Sports
    @State private var selectedSports: Set<String> = ["Basketball", "Tennis", "Running", "Swimming"]

    private let availableSports: [String] = [
        "Basketball", "Tennis", "Running", "Swimming",
        "Soccer", "Volleyball", "Badminton", "Yoga",
        "Cycling", "Boxing", "Climbing", "Golf"
    ]

    var body: some View {
        ZStack {
            theme.colors.backgroundGradient.ignoresSafeArea()
            floatingOrbs

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        photoCard
                        basicInfoSection
                        bioSection
                        sportsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Header
    private var header: some View {
        VStack {
            ZStack {
                // Glow
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.15),
                                Color(hex: "EC4899").opacity(0.15)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 20)
                    .padding(.horizontal, 8)
                    .frame(height: 52)

                HStack {
                    Button {
                        if let onBack { onBack() }
                        else { dismiss() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .padding(8)
                    }
                    .buttonStyle(.plain)

                    Text("Edit Profile")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Button(action: handleSave) {
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "8B5CF6").opacity(0.35), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
            )
            .cornerRadius(20)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Photo Card
    private var photoCard: some View {
        ZStack {
            glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.20, radius: 24)

            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 4))
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)

                    PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                Text("Tap to change photo")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(16)
        }
        .background(theme.colors.cardBackground)
        .background(theme.colors.barMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
        )
        .cornerRadius(20)
        .task(id: pickedItem) {
            await loadPickedPhoto()
        }
    }

    // MARK: - Basic Info
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic Information")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.15, radius: 24)

                VStack(spacing: 12) {
                    labeledField("Full Name") {
                        TextField("Your name", text: $name)
                            .textContentType(.name)
                            .submitLabel(.done)
                    }

                    labeledField(icon: "envelope.fill", label: "Email") {
                        TextField("email@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .submitLabel(.done)
                    }

                    labeledField(icon: "phone.fill", label: "Phone") {
                        TextField("+1 (555) 123-4567", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .submitLabel(.done)
                    }

                    labeledField(icon: "calendar", label: "Date of Birth") {
                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                            .labelsHidden()
                    }

                    labeledField(icon: "mappin", label: "Location") {
                        TextField("City, State", text: $location)
                            .textContentType(.fullStreetAddress)
                            .submitLabel(.done)
                    }
                }
                .padding(16)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
            )
            .cornerRadius(20)
        }
    }

    // MARK: - Bio
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Me")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.15, radius: 24)

                VStack(alignment: .leading, spacing: 8) {
                    // Make TextEditor background fully transparent
                    TextEditor(text: $bio)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 100)
                        .font(.system(size: 14))

                    Text("\(bio.count)/200 characters")
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(.horizontal, 2)
                }
                .padding(16)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
            )
            .cornerRadius(20)
        }
    }

    // MARK: - Sports
    private var sportsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "EC4899"))
                Text("Sports Interests")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.horizontal, 6)

            ZStack {
                glowBox(colors: ["8B5CF6","EC4899"], opacity: 0.15, radius: 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Select the sports you're interested in")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textSecondary)

                    // Flow of chips
                    FlowLayout(spacing: 8) {
                        ForEach(availableSports, id: \.self) { sport in
                            let isSelected = selectedSports.contains(sport)
                            Button {
                                toggleSport(sport)
                            } label: {
                                Text(sport)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(isSelected ? .white : theme.colors.textPrimary.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Group {
                                            if isSelected {
                                                LinearGradient(
                                                    colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                                )
                                            } else {
                                                Color.clear // no white background when unselected
                                            }
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 999)
                                            .stroke(
                                                isSelected
                                                ? Color.clear
                                                : theme.colors.cardStroke,
                                                lineWidth: isSelected ? 0 : 2
                                            )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: isSelected ? Color.black.opacity(0.15) : .clear, radius: 8, y: 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(theme.colors.cardBackground)
            .background(theme.colors.barMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.8), lineWidth: 2)
            )
            .cornerRadius(20)
        }
    }

    // MARK: - Helpers
    private func labeledField(_ label: String, @ViewBuilder field: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 2)
            field()
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(theme.isDarkMode ? 0.06 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.6), lineWidth: 2)
                )
                .cornerRadius(12)
        }
    }

    private func labeledField(icon: String, label: String, @ViewBuilder field: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textSecondary)
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, 2)

            field()
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(theme.isDarkMode ? 0.06 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(theme.isDarkMode ? 0.12 : 0.6), lineWidth: 2)
                )
                .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = pickedImageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else if let url = URL(string: avatarURL) {
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                initialsPlaceholder
            }
        } else {
            initialsPlaceholder
        }
    }

    private var initialsPlaceholder: some View {
        let initials = name.split(separator: " ").compactMap { $0.first }.map(String.init).joined()
        return Text(initials.isEmpty ? "A" : initials)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Color(hex: "8B5CF6"))
            .frame(width: 96, height: 96)
            .background(
                LinearGradient(
                    colors: [Color(hex: "8B5CF6").opacity(0.2), Color(hex: "EC4899").opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }

    private func glowBox(colors: [String], opacity: Double, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(
                LinearGradient(
                    colors: colors.map { Color(hex: $0).opacity(opacity) },
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .blur(radius: 24)
            .opacity(0.8)
            .padding(-6)
    }

    private var floatingOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "A78BFA").opacity(0.4), Color(hex: "F472B6").opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 128, height: 128)
                .blur(radius: 48)
                .offset(x: -100, y: -160)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "93C5FD").opacity(0.3), Color(hex: "A78BFA").opacity(0.3)],
                        startPoint: .bottomLeading, endPoint: .topTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 60)
                .offset(x: 110, y: 220)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FBCFE8").opacity(0.3), Color(hex: "DDD6FE").opacity(0.3)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 96, height: 96)
                .blur(radius: 40)
                .offset(x: 0, y: 120)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "E9D5FF").opacity(0.25), Color(hex: "FDE68A").opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 30)
                .offset(x: 120, y: -60)
        }
        .allowsHitTesting(false)
    }

    private func toggleSport(_ sport: String) {
        if selectedSports.contains(sport) {
            selectedSports.remove(sport)
        } else {
            selectedSports.insert(sport)
        }
    }

    private func handleSave() {
        onSave?()
        if let onBack { onBack() } else { dismiss() }
    }

    // Load the selected photo into Data
    private func loadPickedPhoto() async {
        guard let item = pickedItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                pickedImageData = data
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(Theme())
    }
}
