# Activities & Map Guide

This guide explains how activities are modeled, fetched, and displayed on the map and lists.

---

## 1. Activity model

**File:** `Views/Core App Screens/MapScreen/MapScreenModels.swift`

- `struct Activity: Identifiable, Codable, Equatable` with fields like:
  - `id`, `title`, `sportType`, `sportIcon`
  - `hostName`, `hostAvatar`, `creator`
  - `date`, `time`, `location`, `distance`
  - `spotsTotal`, `spotsTaken`, `level`, `visibility`
  - `latitude`, `longitude`, `participantIds`, `isPaidSession`, `price`, `description`
- Computed helpers:
  - `coordinate` (from latitude/longitude)
  - `spotsLeft`
  - `hasCoordinates`

---

## 2. Activity API service

**File:** `Services/ActivityAPIService.swift`

Responsibilities:

- Holds published state:
  - `activities: [Activity]` – all activities.
  - `userActivities: [Activity]` – created / joined by the current user.
- Provides async methods:
  - `fetchAllActivities()` – loads all activities from `/activities`.
  - `fetchMyActivities()` – loads user activities from `/activities/my-activities`.
  - `searchActivities(query:sport:distanceMiles:)` – server fetch + local filtering.
  - `createActivity(...)` – POST `/activities` to create.
  - `deleteActivity(id:)` – DELETE `/activities/:id`.
- Handles:
  - Authorization headers via `AuthTokenManager`.
  - Basic logging and error state (`isLoading`, `error`).
  - Caching to disk (simple JSON cache under `cachesDirectory`).

Activities from the backend are decoded as `APIActivity` then converted to the UI `Activity` model via `convertToActivity(_:)`.

---

## 3. MapScreen & list view

**Files:**

- `Views/Core App Screens/MapScreen/MapScreen.swift`
- `Views/Core App Screens/MapScreen/MapScreenViewModel.swift`
- `Views/Core App Screens/MapScreen/MapScreenModels.swift` (for `Activity`, `MapFilters`, `DirectionsRequest`, etc.)

### 3.1 MapScreenViewModel

- Owns:
  - Current user location and map region.
  - List of activities from `ActivityAPIService` filtered by `MapFilters`.
  - Whether map or list mode is active.
- Uses `ActivityAPIService` to refresh activities (usually via shared environment object).

### 3.2 MapScreen

- Displays:
  - Map with annotations for `Activity` when coordinates are available.
  - List mode showing cards for nearby sessions.
- Supports filters (`MapFilters`) by sport type, level, and radius.
- Can request directions via `DirectionsRequest` and open Apple Maps.

---

## 4. Creating & managing activities

**Files:**

- `Views/Activity & Events/CreateActivityView/CreateActivityView.swift`
- `Views/Activity & Events/CreateActivityView/CreateActivityViewModel.swift`
- `Views/Activity & Events/CreateActivityView/CreateSessionView.swift`

Core flow:

1. User fills out form fields (title, sport type, location, date/time, level, visibility, participants, optional price).
2. View model normalizes and validates the data.
3. Calls `ActivityAPIService.createActivity(...)`.
4. On success, the service refreshes `activities` and `userActivities`.

Deleting an activity uses `ActivityAPIService.deleteActivity(id:)`, then reloads lists.

---

## 5. How AI features use activities

- AI Coach reads `ActivityAPIService.userActivities` to compute weekly stats and sport preferences.
- AI Matchmaker and AI Suggestions use activity lists and summary helpers like:
  - `getActivitiesForAIRecommendation(...)`
  - `getActivitySummaryForAI()`

When you add new fields to activities that should influence AI, make sure to:

1. Add them to `APIActivity`.
2. Map them into `Activity` in `convertToActivity(_:)`.
3. Extend AI request models and prompts accordingly.
