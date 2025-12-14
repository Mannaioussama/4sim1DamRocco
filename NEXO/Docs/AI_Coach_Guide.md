# AI Coach – Implementation Guide & Roadmap

This document focuses on the **AI Coach feature**: how it works today and what improvements are planned. It complements the root `README.md`.

---

## 1. Current AI Coach Architecture

**Key files:**

- `Views/Ai Features/AICoachView.swift`
- `Views/Ai Features/AICoachViewModel.swift`
- `AICoach/Services/AICoachRemoteDataSource.swift`
- `AICoach/Models/` (suggestions, tips, YouTube videos, optional `StravaData`)
- `AICoach/Services/StravaOAuthHandler.swift`
- `Config/StravaConfig.swift`
- `Services/AchievementsAPI.swift`
- `Services/ActivityAPIService.swift`
- `Services/Gemini/WeatherKitService.swift` + `LegacyWeatherService`

### 1.1 View hierarchy

- `AICoachView` – main entry. Contains:
  - `StatsHeaderView` – stats cards, Strava connect/connected state, weather summary cell.
  - Segmented control for tabs: **Suggestions / Tips / Videos**.
  - `SuggestionsTabView`, `TipsTabView`, `YouTubeVideosTabView`.

- `AICoachViewModel` (ObservableObject):
  - `@Published` state for:
    - `suggestions`, `tips`, `youtubeVideos`
    - loading flags & `errorMessage`
    - weekly stats: `weeklyWorkouts`, `weeklyCalories`, `weeklyMinutes`, `currentStreak`
    - preferences: `sportPreferences`, `location`, `preferredTimeOfDay`
    - optional integrators: `stravaData`, `isStravaConnected`

### 1.2 Remote data source

- `AICoachRemoteDataSource` encapsulates all backend calls:
  - `getSuggestions(request:)` → `/ai-coach/suggestions`
  - `getPersonalizedTips(request:)` → `/ai-coach/personalized-tips`
  - `getYouTubeVideos(...)` → `/ai-coach/youtube-videos`

Request models mirror the backend JSON contracts so the LLM / AI backend receives everything it needs about the user.

---

## 2. Stats & Context Feeding

### 2.1 Bootstrapping from app data

`AICoachView` calls:

```swift
viewModel.bootstrapIfNeeded(activityAPIService: activityAPIService)
```

`bootstrapIfNeeded` runs once per app lifecycle and:

1. Calls `AchievementsAPI.getSummary()` to get:
   - Current level, total XP, XP to next level
   - Total badges, current streak, best streak
2. Ensures `ActivityAPIService.userActivities` is loaded (fetches `/activities/my-activities` if empty).
3. Builds stats in `computeStats(from:activities:)`:
   - `weeklyWorkouts` = `userActivities.count`
   - `weeklyMinutes` ≈ `weeklyWorkouts * 60` (current heuristic)
   - `weeklyCalories` ≈ `weeklyWorkouts * 300` (current heuristic)
   - `currentStreak` = `summary.stats.currentStreak`
   - `sportPreferences` = unique `Activity.sportType` values from `userActivities`
4. Calls `loadSuggestions()`.

### 2.2 Suggestions request payload

`loadSuggestions()` creates `AISuggestionsRequest` (conceptually):

- `workouts`: `weeklyWorkouts`
- `calories`: `weeklyCalories`
- `minutes`: `weeklyMinutes`
- `streak`: `currentStreak`
- `sportPreferences`: optional comma-separated string (or `nil` if empty)
- `stravaData`: optional structured JSON string (currently unused until backend supports it)
- `location`: optional string (currently empty)
- `preferredTimeOfDay`: "morning" / "afternoon" / "evening" / `nil` if `"any"`

The backend then returns:

- `suggestions`: list of `AISuggestion`
- Optionally `personalizedTips`: list of `PersonalizedTip` (pre-populated tips tab)

### 2.3 Tips & YouTube videos

- `loadTips()` sends a **similar request** to `/ai-coach/personalized-tips`, but converts `sportPreferences` to an array and optionally adds encoded `stravaData`.
- `loadYouTubeVideos()` calls `/ai-coach/youtube-videos` with `sportPreferences` to get curated videos.

---

## 3. Strava Integration – iOS Side (Current)

### 3.1 Config

`StravaConfig.swift`:

- `clientId = "188930"`
- `redirectScheme = "nexofitness"`
- `backendRedirectURI = "https://apinest-production.up.railway.app/strava/callback"`
- `appCallbackURL = "nexofitness://strava/callback"`

Strava dev portal is configured with:

- **Authorization Callback Domain:** `apinest-production.up.railway.app`
- Redirect URL in OAuth = `https://apinest-production.up.railway.app/strava/callback`

### 3.2 Starting OAuth

In `StatsHeaderView`:

- Connect button opens Strava via `SafariView` using:

```text
https://www.strava.com/oauth/mobile/authorize
  ?client_id=188930
  &redirect_uri=https://apinest-production.up.railway.app/strava/callback
  &response_type=code
  &approval_prompt=auto
  &scope=read,activity:read_all,profile:read_all
  &state=nexo_ai_coach
```

### 3.3 Deep link handling

- Xcode `Info` has URL type:
  - Scheme: `nexofitness`
- `NEXOApp`:

```swift
.onOpenURL { url in
    _ = StravaOAuthHandler.shared.handleDeepLink(url)
}
```

`StravaOAuthHandler.handleDeepLink`:

1. Ensures scheme is `nexofitness`, host is `strava`, path is `/callback`.
2. Reads query items:
   - If `error` is present → posts a failure `StravaConnectionResult`.
   - Else extracts `code` and calls `exchangeCodeForToken(code:)`.

### 3.4 Exchanging code with backend (iOS side)

`exchangeCodeForToken(code:)`:

1. Reads JWT from `AuthTokenManager.getToken()`.
2. Builds request:

```text
POST https://apinest-production.up.railway.app/strava/oauth/callback
Authorization: Bearer <JWT>
Content-Type: application/json

{ "code": "..." }
```

3. On HTTP 2xx:
   - Parses `{ success, message }` (optionally `athleteId`).
   - Posts `Notification.Name.stravaOAuthCompleted` with `StravaConnectionResult(success: true, message: ...)`.
4. On non-2xx or network error:
   - Posts `StravaConnectionResult(success: false, message: <friendly error>)`.

> **Backend status:** as of now, `POST /strava/oauth/callback` is **not yet implemented**, so the app shows `"Cannot POST /strava/oauth/callback"`. This is tracked as a separate backend TODO.

### 3.5 Reacting in AI Coach UI

In `AICoachView`:

```swift
.onReceive(NotificationCenter.default.publisher(for: .stravaOAuthCompleted)) { notification in
    if let result = notification.object as? StravaConnectionResult {
        if result.success {
            viewModel.markStravaConnected()
            viewModel.loadSuggestions()
        } else {
            viewModel.errorMessage = result.message
        }
    }
}
```

- `markStravaConnected()` sets `isStravaConnected = true` and persists it in `UserDefaults`.
- `StatsHeaderView` uses `isStravaConnected` to:
  - Hide the connect button after success.
  - Show a small "Strava connected" label under the stats.

---

## 4. Weather Integration in AI Coach

- `StatsHeaderView` calls `loadWeather()` on appear.
- Implementation:

```swift
if #available(iOS 16.0, *) {
    Task {
        let service = WeatherKitService()
        await service.requestLocationAndWeather()
        await MainActor.run {
            if let info = service.getWeatherInfo() {
                self.weatherInfo = info
            } else {
                let legacy = LegacyWeatherService()
                self.weatherInfo = legacy.weatherInfo
            }
        }
    }
} else {
    let legacy = LegacyWeatherService()
    self.weatherInfo = legacy.weatherInfo
}
```

- Because WeatherKit needs entitlements and can fail on device, we always fall back to `LegacyWeatherService` so a weather card is *always* displayed.

---

## 5. Known TODOs & Improvement Ideas (Deliberately Incomplete)

This section collects the main AI Coach improvements we discussed, marked as **not yet implemented**. They are mirrored in the assistants TODO list so you can come back to them later.

### 5.1 Backend Strava OAuth callback

- **TODO:** Implement `POST /strava/oauth/callback` on the NestJS backend.
- Behavior:
  - Takes `{ code }` + authenticated user from JWT.
  - Calls Stravas `POST https://www.strava.com/oauth/token` with `client_id`, `client_secret`, `code`.
  - Saves `stravaAccessToken`, `stravaRefreshToken`, `stravaTokenExpiresAt`, `stravaAthleteId` to the user.
  - Returns `{ success: true, message, athleteId }`.
- Without this, the app shows `"Cannot POST /strava/oauth/callback"` after authorization.

### 5.2 Use real workout durations & calories

- **Current state:**
  - `weeklyMinutes` = `weeklyWorkouts * 60`.
  - `weeklyCalories` = `weeklyWorkouts * 300`.
- **Idea:**
  - Once backend exposes durations / distances / estimates, compute:
    - `weeklyMinutes` = sum of durations.
    - `weeklyCalories` = per-sport or MET-based calorie estimates.
  - Optionally merge Strava workout durations when available.

### 5.3 Feed summarized Strava data into AI Coach

- **Current state:**
  - `stravaData` model exists in iOS and is part of request payload types, but is not yet populated.
- **Planned:**
  1. Backend exposes an endpoint like `GET /strava/summary` using users stored tokens.
  2. iOS calls it after a successful connect to get:
     - Weekly distance & time by sport.
     - Recent workouts list.
  3. `AICoachViewModel.updateStravaData(_:)` is used to:
     - Store the data.
     - Override or complement `weeklyWorkouts`, `weeklyMinutes`, etc.
  4. Requests to `/ai-coach/suggestions` & `/ai-coach/personalized-tips` include serialized `stravaData`.

### 5.4 Strava disconnect / reset flow

- **Goal:** Allow the user to disconnect Strava from Settings or Profile.
- **Expected UX:**
  - A toggle or button: "Disconnect Strava".
  - On tap:
    - Show a confirmation alert.
    - Call backend `DELETE /strava/connection` (or similar) to clear tokens.
    - iOS clears `isStravaConnected` and any cached `stravaData`.
    - AI Coach header returns to "Connect Strava for better suggestions" state.

### 5.5 Richer AI Coach header

- **Ideas:**
  - Add XP & level chip from `AchievementsAPI.getSummary()` to the AI Coach header next to stats.
  - Show a short streak message:
    - e.g. "🔥 Amazing streak!" if streak >= 7, reusing Achievements logic.
  - Optionally show a small text like:
    - "Using your sessions, achievements and Strava data" when Strava is connected.

### 5.6 Error handling & observability

- Improve logging & error feedback for AI Coach requests:
  - Map backend `APIError.userMessage` more clearly to the UI.
  - Track AI Coach screen views and tab switches for analytics.

---

## 6. How to Extend AI Coach Safely

When adding new AI features or changing prompts/requests:

1. **Extend the request models** in `AICoach/Models` with new fields.
2. **Update `AICoachViewModel`** to compute or fetch these fields from:
   - `ActivityAPIService`
   - `AchievementsAPI`
   - Strava summary endpoints
   - Weather or other sensors
3. **Update `AICoachRemoteDataSource`** to send the new fields to the appropriate `/ai-coach/*` endpoint.
4. **Coordinate with backend / LLM prompts** so the new metadata is actually used.
5. **Keep UI resilient:** if new data is missing, fall back to existing behavior.

This guide plus the root `README.md` should give you enough context to pick up AI Coach changes in the future without re-reading the entire codebase.
