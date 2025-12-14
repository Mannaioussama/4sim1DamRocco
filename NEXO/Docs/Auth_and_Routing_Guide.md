# Auth & Routing Guide

This guide explains how authentication and navigation work in the NEXO iOS app.

---

## 1. Auth stack

**Key files:**

- `Auth/AuthStore.swift` – holds `isLoggedIn`, manages login/logout state.
- `Auth/AuthAPI.swift` – calls backend auth endpoints.
- `Services/AuthTokenManager.swift` – stores JWT + user id in `UserDefaults`.
- `Auth/APIConfig.swift` – base URL + `endpoint(_:)` helper.

### 1.1 AuthTokenManager

- Saves and retrieves the JWT used for all authorized backend calls.
- Provides:
  - `saveToken(_:)`, `getToken()`, `clearToken()`.
  - `saveUserId(_:)`, `getUserId()`.

### 1.2 AuthStore

- Observable object injected via `@EnvironmentObject`.
- Tracks:
  - `isLoggedIn`
  - any in-memory user info required by the auth flow.
- Coordinates with `AuthAPI` when the user logs in / signs up / logs out.

---

## 2. App startup & root routing

**Key files:**

- `NEXOApp.swift`
- `RootView`
- `Navigation/AppRouter.swift`
- `Navigation/AppShellView.swift`

### 2.1 NEXOApp

- Entry point marked with `@main`.
- Creates global environment objects:
  - `Theme`
  - `AuthStore`
  - `ActivityAPIService`
  - `LocalizationManager`
- Root content: `RootView()`.

### 2.2 RootView

- Decides which stack to show:
  - If `router.isAuthenticated == true` → **main AppShellView**.
  - Otherwise → **auth flow** (`SplashScreenView`, `OnboardingView`, `LoginView`, `SignUpPage`, `ResetPasswordPage`).
- Keeps a dedicated `NavigationStack` for auth routes so they never pollute the main app shell path.

### 2.3 AppRouter & AppShellView

- `AppRouter`:
  - Owns the selected tab (home / map / chat / profile / etc.).
  - Stores navigation paths for nested flows when needed.
- `AppShellView`:
  - Renders bottom tab bar / main layout.
  - Hosts core screens (e.g. `HomeFeedView`, `MapScreen`, `ChatRootView`, `ProfilePage`).

---

## 3. Auth flow screens

**Main views:**

- `Views/Auth/SplashScreenView.swift` – decides whether to show onboarding or login.
- `Views/Auth/OnboardingView.swift` – intro pages.
- `Views/Auth/LoginView.swift` – login form, uses `AuthStore` + `AuthAPI`.
- `Views/Auth/SignUpPage.swift` – sign up flow.
- `Views/Auth/ResetPasswordPage.swift` – password reset.

The auth flow uses `NavigationStack` with a `Route` enum to handle navigation between login, signup, reset password, and onboarding.

---

## 4. How to add a new protected screen

1. Implement your screen under `Views/Core App Screens/YourFeature`.
2. Add navigation into it from an existing tab (e.g. push from `HomeFeedView`).
3. Ensure you only present it from inside `AppShellView` so it is naturally protected by the auth gate in `RootView`.

---

## 5. How logout works

A typical logout should:

1. Clear the JWT + user id via `AuthTokenManager.clearToken()`.
2. Set `authStore.isLoggedIn = false`.
3. Reset `AppRouter` state and send user back to the login stack.

This guarantees the app returns to the auth flow and all protected API services stop sending stale tokens.
