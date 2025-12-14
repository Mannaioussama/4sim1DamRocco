# Profile Guide

This guide focuses on user profile data and profile-related screens.

---

## 1. Profile API

**File:** `Services/ProfileAPI.swift`

- Fetches and updates user profile from backend.
- Typical operations:
  - `GET /users/profile` – load current user.
  - `PATCH /users/profile` – update name, location, bio, sports interests, etc.
  - Upload or change profile pictures.

Profile data includes:

- Name, email, location.
- Sports interests.
- Avatar URLs.
- Coach verification status (if applicable).

---

## 2. Profile screen

**Files:**

- `Views/Core App Screens/ProfilePage.swift`
- `Views/Core App Screens/ProfilePageViewModel.swift`

ProfilePage typically shows:

- Avatar, name, location.
- Sports interests.
- Level / XP (using achievements summary).
- Followers / following counts.
- Buttons or links to:
  - Edit profile.
  - View achievements.
  - Open Settings.

The view model coordinates with `ProfileAPI` and `AchievementsAPI` to populate this data.

---

## 3. Settings & account management

**Files:**

- `Views/Profile & AppSettings/SettingsView.swift`
- `Views/Profile & AppSettings/SettingsViewModel.swift`
- Other settings-related screens (change password, edit profile, etc.).

Responsibilities:

- Expose actions for logout (clearing tokens and resetting router).
- Provide entry points to profile editing, notifications, language/theme settings, and subscription/coach onboarding flows.

See also:

- `Achievements_Guide.md` for gamification.
- `Subscriptions_Guide.md` for premium subscriptions.
- `AI_Coach_Guide.md` for how achievements and stats feed into AI features.
