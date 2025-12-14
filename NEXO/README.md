# NEXO iOS App – Architecture & Guides

This document summarizes the **main parts of the NEXO iOS app** and how they work together. Its meant as a practical map of the codebase plus quick guides for the core flows.

---

## 1. Tech Stack & High-Level Structure

- **Language:** Swift, SwiftUI
- **Architecture:** MVVM + service layer, router-driven navigation
- **Networking:** `URLSession` with `APIConfig` helpers
- **Auth:** JWT stored via `AuthTokenManager`
- **Backend:** `https://apinest-production.up.railway.app`
- **Realtime:** WebSockets for activity rooms
- **Payments:** Stripe SDK

**Main folders under `NEXO/`:**

- `NEXOApp.swift` – app entry, global environment objects, routing bootstrap.
- `Auth/` – login, signup, tokens, base API config.
- `Navigation/` – `AppRouter`, main tab shell & routing.
- `Views/Core App Screens/` – Home feed, map/sessions, profile, etc.
- `Views/Activity & Events/` – activity creation, discovery, coach sessions.
- `Views/Ai Features/` – AI Coach UI layer.
- `AICoach/` – AI Coach models & remote data source, Strava OAuth handler.
- `Views/Profile & AppSettings/` – profile, settings, achievements.
- `Services/` – Activity / Chat / Payment / Achievements / Gemini / etc.
- `Config/` – API endpoints, Strava config, localization.
- `App Functionalities/` – share sheet, media picker, misc utilities.

---

## 2. App Startup, Auth & Routing

### 2.1 Entry point: `NEXOApp`

- Creates shared environment objects:
  - `Theme`
  - `AuthStore`
  - `ActivityAPIService`
  - `LocalizationManager`
- Root view: `RootView()`
  - Chooses between **auth flow** and **main app shell** based on `router.isAuthenticated`.
  - On first authenticated appearance, eagerly preloads:
    - `activityAPIService.fetchAllActivities()`
    - `activityAPIService.fetchMyActivities()`

### 2.2 Auth & Tokens

- **`AuthTokenManager`** (in `Services/`)
  - Persists `auth_token` + `user_id` in `UserDefaults`.
  - Provides `getToken()` used by all API services.
- **`AuthStore`** (in `Auth/`):
  - Holds `isLoggedIn` and user auth state.
  - Coordinates login/logout with backend via `AuthAPI`.
- **`APIConfig`** (in `Auth/`):
  - `baseURL = https://apinest-production.up.railway.app`
  - `endpoint(_ path: String)` helper for building URLs.

### 2.3 Navigation

- **`AppRouter`** (in `Navigation/`):
  - Owns selected tab (`home`, `map`, `chat`, `profile`, etc.).
  - Stores navigation stacks for sub-flows (e.g. chat, activities).
- **`AppShellView`**:
  - Main tab UI.
  - Hosts `HomeFeedView`, `MapScreen`, `ChatRootView`, `ProfilePage`, etc.

**Guide – Add a new top-level screen:**

1. Create view + view model under `Views/Core App Screens/YourScreen`.
2. Add a new case to `AppTab` in `AppRouter` if its a tab.
3. Wire the new case into `AppShellView`.

---

## 3. Activities, Map & Discovery

### 3.1 Activity data model

- **`Views/Core App Screens/MapScreen/MapScreenModels.swift`**:
  - `struct Activity: Identifiable, Codable, Equatable` used across UI.
  - Contains title, sportType, host, date/time, location, distance, spots, level, coordinates.
  - Convenience helpers: `coordinate`, `spotsLeft`, `hasCoordinates`, distance helpers.

### 3.2 Activity API service

- **`Services/ActivityAPIService.swift`**:
  - Handles:
    - `fetchAllActivities()` – public & nearby activities.
    - `fetchMyActivities()` – activities created / joined by the user.
  - Uses `APIConfig.endpoint` + `AuthTokenManager` under the hood.
  - Keeps `activities` + `userActivities` in memory for Map & AI Coach.

### 3.3 Map screen

- **`Views/Core App Screens/MapScreen/MapScreen.swift`**
  - Main sessions/map UI.
- **`MapScreenViewModel`**
  - Uses `ActivityAPIService` + `MapFilters` to fetch & filter sessions.
  - Coordinates between map mode and list mode.

**Guide – Add a new activity field to UI:**

1. Extend `Activity` in `MapScreenModels.swift` (matching backend JSON).
2. Update mapping logic in `ActivityAPIService` (if needed).
3. Surface the new field in relevant views (`MapScreen`, `HomeFeed`, etc.).

---

## 4. AI Coach – Overview

High-level AI Coach files:

- `Views/Ai Features/AICoachView.swift` – main UI: stats header, tabs, Strava & weather.
- `Views/Ai Features/AICoachViewModel.swift` – state, stats, and network calls.
- `AICoach/Services/AICoachRemoteDataSource.swift` – calls backend `/ai-coach/*` endpoints.
- `AICoach/Models/` – models for suggestions, tips, YouTube videos, optional Strava data.
- `AICoach/Services/StravaOAuthHandler.swift` – handles deep links and backend callback.
- `Config/StravaConfig.swift` – client ID and redirect URIs.

### 4.1 Data sources used by AI Coach

- **App activity stats** from `ActivityAPIService.userActivities`.
- **Achievements summary** from `AchievementsAPI.getSummary()`.
- **Weather** from `WeatherKitService` (iOS 16+) with fallback to `LegacyWeatherService`.
- **(Planned) Strava data** once backend tokens are exchanged.

### 4.2 Flow: stats bootstrap

Triggered by `AICoachView` on appear:

1. `viewModel.bootstrapIfNeeded(activityAPIService:)`.
2. Internally:
   - Calls `AchievementsAPI.getSummary()` for level & streak.
   - Ensures `ActivityAPIService.userActivities` is loaded (`fetchMyActivities()` if empty).
   - Calls `computeStats(from:summary, activities:)`:
     - `weeklyWorkouts` = number of user activities.
     - `weeklyMinutes` ≈ `workouts * 60` (current heuristic).
     - `weeklyCalories` ≈ `workouts * 300` (current heuristic).
     - `currentStreak` = `summary.stats.currentStreak`.
     - `sportPreferences` = unique `Activity.sportType` values, joined.
   - Calls `loadSuggestions()` to fetch personalized suggestions.

### 4.3 Suggestions / tips / videos

- **`loadSuggestions()`**
  - Builds `AISuggestionsRequest` with:
    - `workouts`, `calories`, `minutes`, `streak`.
    - Optional `sportPreferences`, `location`, `preferredTimeOfDay`.
    - Optional `stravaData` (not yet fully used until backend supports it).
  - Calls `AICoachRemoteDataSource.getSuggestions()` → `/ai-coach/suggestions`.

- **`loadTips()`**
  - Builds `PersonalizedTipsRequest` with same stats + optional `stravaData` JSON.
  - Calls `/ai-coach/personalized-tips`.

- **`loadYouTubeVideos()`**
  - Calls `/ai-coach/youtube-videos` with sport preferences.

### 4.4 Strava integration (iOS side)

**Start OAuth (from AI Coach header):**

- `StatsHeaderView` shows:
  - Connect button **or** "Strava connected" indicator.
- Connect button opens:

  ```text
  https://www.strava.com/oauth/mobile/authorize
    ?client_id=188930
    &redirect_uri=https://apinest-production.up.railway.app/strava/callback
    &response_type=code
    &approval_prompt=auto
    &scope=read,activity:read_all,profile:read_all
    &state=nexo_ai_coach
  ```

**Deep link back into app:**

- Backend `GET /strava/callback` should redirect to:
  - `nexofitness://strava/callback?code=...`.
- `NEXOApp` has:

  ```swift
  .onOpenURL { url in
      _ = StravaOAuthHandler.shared.handleDeepLink(url)
  }
  ```

**Exchange code for tokens:**

- `StravaOAuthHandler`:
  - Validates URL & extracts `code`.
  - Uses `AuthTokenManager.getToken()` for JWT.
  - POSTs JSON `{ "code": "..." }` to:

    ```text
    POST https://apinest-production.up.railway.app/strava/oauth/callback
    Authorization: Bearer <JWT>
    ```

  - On success/failure posts `Notification.Name.stravaOAuthCompleted` with `StravaConnectionResult`.

**AI Coach reaction:**

- `AICoachView` listens with `.onReceive`:
  - On success:
    - `viewModel.markStravaConnected()` (persists flag in `UserDefaults`).
    - `viewModel.loadSuggestions()`.
  - On failure:
    - Sets `viewModel.errorMessage` to show an alert.

> **TODO (backend):** implement `POST /strava/oauth/callback` to exchange the Strava `code` for tokens and save them per user.

### 4.5 AI Coach improvement ideas (not yet implemented)

These are ideas we discussed to further improve AI Coach. They are **deliberately left incomplete** so you can revisit them later:

1. **Use real durations & calories instead of heuristics**
   - Derive `weeklyMinutes` and `weeklyCalories` from:
     - Actual activity durations (once available from backend/Strava),
     - Or per-sport defaults (e.g. running vs basketball vs cycling).
2. **Feed rich Strava data into AI Coach requests**
   - After backend stores Strava tokens, add an endpoint to fetch a summarized `StravaData` model (weekly stats, recent workouts).
   - Populate `AICoachViewModel.stravaData` and send encoded JSON to `/ai-coach/suggestions` and `/ai-coach/personalized-tips`.
3. **Strava disconnect / reset**
   - Add a toggle in Settings or Profile to disconnect Strava:
     - iOS: call backend `DELETE /strava/connection` (or similar).
     - Backend: revoke tokens with Strava & clear users Strava fields.
4. **Tune stats & header UX**
   - Optionally add:
     - XP / level from `AchievementsAPI` in the AI Coach header.
     - A streak message like "🔥 Amazing streak" reusing `AchievementsViewModel` logic.
5. **Highlight data sources in UI**
   - In Suggestions header, add a subtle subtitle like:
     - "Uses your NEXO sessions, achievements and Strava data" when connected.

(These items are also tracked as TODOs in the assistants task list so they remain easy to revisit.)

---

## 5. Achievements & Gamification

### 5.1 AchievementsAPI

Located in `Services/AchievementsAPI.swift`:

- `GET /achievements/summary` → `AchievementSummary` (level + streak stats).
- `GET /achievements/badges` → earned + in-progress badges.
- `GET /achievements/challenges` → active challenges.
- `GET /achievements/leaderboard` → XP leaderboard.

### 5.2 AchievementsViewModel

In `Views/Profile & AppSettings/AchievementsViewModel.swift`:

- Maps raw API models into UI structures:
  - `AchievementsUserStats`, `BadgeItem`, `ChallengeItem`, `LeaderboardEntry`.
- Used by the Achievements screen to show:
  - Current level / XP progress.
  - Badges (earned + in-progress).
  - Challenges and rewards.
  - Global leaderboard.

**Guide – Connect new achievements to AI Coach or other screens:**

- Reuse `AchievementsAPI.getSummary()` to avoid duplicating level/streak logic.
- Derive simple computed values (e.g. `xpToNextLevel`) in the view model.

---

## 6. Chat, Social & Realtime

### 6.1 Chat API

- `Services/ChatAPI.swift` handles:
  - Listing conversations
  - Loading messages
  - Sending messages
  - Creating group chats tied to activities (`createActivityGroupChat`).

### 6.2 Activity room (coach sessions)

- `Services/ActivityRoomWebSocketService.swift`:
  - Wraps a WebSocket connection to backend for live coach sessions.
- `Views/Activity & Events/Coach Session/ActivityRoomViewModel.swift` & `ActivityRoomView.swift`:
  - Manage realtime messages, attendees, reactions, etc.

**Guide – Start a group chat from AI Coach suggestion:**

- `SuggestionsTabView` calls:

  ```swift
  let response = try await ChatAPI.createActivityGroupChat(activityId: suggestion.id)
  router.select(.chat)
  router.push(.chatConversation(chatId: response.chat.id))
  ```

---

## 7. Payments & Subscriptions

- `StripeConfig` (configured at app start in `NEXOApp`).
- `Services/PaymentAPIService.swift`, `SubscriptionAPI.swift`:
  - Create payment intents.
  - Handle subscription status for premium features.

**Guide – Add a new paid feature:**

1. Model the feature flag on backend & expose via subscription endpoints.
2. Add a property in the relevant view model (e.g. `isPremiumEnabled`).
3. Read subscription state via `SubscriptionAPI` and gate premium UI.

---

## 8. Localization & Theming

- `Config/LocalizationManager.swift`:
  - Tracks selected language and RTL/LTR direction.
  - `NEXOApp` applies `.environment(\.layoutDirection, ...)` based on it.
- `Theme` environment object:
  - Central palette and typography.
  - Used everywhere via `@EnvironmentObject`.

**Guide – Add a new localized string:**

1. Add entry to your `.strings` or localization source.
2. Use `LocalizationManager` where dynamic behaviors are needed (e.g. RTL).

---

## 9. Weather Integration

- `Services/Gemini/WeatherKitService.swift`:
  - Uses Apple WeatherKit on iOS 16+ (requires entitlements in production).
  - Provides `getWeatherInfo()` for UI and `getWeatherAnalysisForAI()` for AI.
- `LegacyWeatherService`:
  - Simple static weather used when WeatherKit is unavailable.
- `StatsHeaderView` in `AICoachView`:
  - Calls `loadWeather()`:
    - Tries WeatherKit → if nil, falls back to `LegacyWeatherService`.
    - Always shows a `WeatherSummaryCell` with temperature, condition, and short description.

---

## 10. Where to go next

- Use this README as a map of the apps modules.
- For feature-specific implementation details and roadmaps, see the guides under `NEXO/Docs/`:
  - `Docs/Auth_and_Routing_Guide.md`
  - `Docs/Activities_and_Map_Guide.md`
  - `Docs/Coach_Sessions_Guide.md`
  - `Docs/Chat_and_Social_Guide.md`
  - `Docs/Profile_Guide.md`
  - `Docs/Achievements_Guide.md`
  - `Docs/Payments_Guide.md`
  - `Docs/Subscriptions_Guide.md`
  - `Docs/Localization_and_Theme_Guide.md`
  - `Docs/AI_Coach_Guide.md`
  - `Docs/AI_Matchmaker_Guide.md`
  - `Docs/QuickMatch_Guide.md`

When you pick up a future task (e.g. finishing Strava backend, improving stats, or extending AI Coach), you can:

- Start from the relevant section here.
- Cross-check the dedicated feature guide in `Docs/` for endpoints, flows, and TODOs.

---

## 11. Docs

This section provides a brief overview of the main project parts and guides you to the relevant documentation.

### Main Project Parts

- **Auth and Routing**: Handles user authentication and routing within the app.
- **Activities and Map**: Manages activities, maps, and related features.
- **Coach Sessions**: Handles live coach sessions and related features.
- **Chat and Social**: Manages chat, social features, and related functionality.
- **Profile**: Handles user profiles and account-related features.
- **Achievements**: Handles badges, levels, streaks, and leaderboards.
- **Payments**: Manages one-off payments.
- **Subscriptions**: Manages recurring premium plans.
- **Localization and Theme**: Handles localization, theming, and related features.
- **AI Coach**: Handles AI Coach-related features and functionality.
- **AI Matchmaker**: AI chat-based matchmaker flow.
- **QuickMatch**: Swipe-style quick matching system.

### Guides

- Each guide provides detailed information on a specific feature or functionality, including endpoints, flows, and TODOs.
- Use the guides to implement new features, fix bugs, or improve existing functionality.
