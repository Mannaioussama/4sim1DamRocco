# QuickMatch Guide

QuickMatch is a swipe-style matching system that suggests compatible profiles and lets users like or pass on them quickly.

---

## 1. Service: QuickMatchService

**File:** `Services/QuickMatchService.swift`

- Protocol `QuickMatchServicing` defines:
  - `getProfiles(page:limit:)` → fetch a page of candidate profiles.
  - `likeProfile(profileId:)` → like someone.
  - `passProfile(profileId:)` → skip someone.
  - `getMatches()` → list mutual matches.
  - `getLikesReceived()` → list who liked you.

- `QuickMatchService` is an `actor` implementing this protocol:
  - Handles auth via `AuthStore.shared.accessToken()` or `AuthTokenManager.shared.getToken()`.
  - Constructs authorized `URLRequest`s and uses `URLSession.shared`.
  - Endpoints:
    - `GET /quick-match/profiles`
    - `POST /quick-match/like`
    - `POST /quick-match/pass`
    - `GET /quick-match/matches`
    - `GET /quick-match/likes-received`

The actor design makes it safe for caching and mutation from multiple tasks in the future.

---

## 2. View model & UI

**Typical files:**

- `Views/Activity & Events/QuickMatch/QuickMatchViewModel.swift`
- QuickMatch UI under `Views/Activity & Events/QuickMatch/`.

### 2.1 QuickMatchViewModel

- Owns:
  - List of profiles to show.
  - Current index / card.
  - Loading & error state.
- Uses `QuickMatchService` to:
  - Load initial profiles (`getProfiles`).
  - Request the next page when the user nears the end.
  - Send like/pass actions.
  - Load matches and likes-received tabs.

### 2.2 QuickMatch UI

The UI typically shows:

- A stack of cards, each representing a profile.
- Buttons or swipe gestures to:
  - Like (e.g. ❤️)
  - Pass (e.g. ✖️)
- Additional sections/tabs for:
  - `Matches` – mutual likes obtained via `getMatches()`.
  - `Likes received` – people who liked you, via `getLikesReceived()`.

---

## 3. Integrating QuickMatch with other features

Some common next steps once a match is created:

- **Chat:**
  - After identifying a mutual match, navigate to a chat conversation for that user.
- **Profile:**
  - Tapping a profile card can open the full profile screen (`ProfilePage`).

Those flows can be built by:

1. Using `AppRouter` to switch to the `chat` or `profile` tab.
2. Pushing a conversation or profile route with the matched user’s id.

---

## 4. Relationship with AI features

- QuickMatch is a more **traditional swipe experience**.
- AI Matchmaker can *feed into* QuickMatch by:
  - Suggesting people who should be prioritized or pre-filtered by interests.

Use this guide when modifying the QuickMatch logic or connecting it to new social/AI flows.
