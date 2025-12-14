# Achievements Guide

This guide focuses on achievements, badges, streaks, and leaderboards.

---

## 1. Achievements API

**File:** `Services/AchievementsAPI.swift`

Provides backend integration for gamification:

- `getSummary()` → `AchievementSummary` with:
  - `level.currentLevel`, `level.totalXp`, `level.currentLevelXp`, `level.xpForNextLevel`, `level.progressPercentage`.
  - `stats.totalBadges`, `stats.currentStreak`, `stats.bestStreak`.
- `getBadges()` → lists earned and in-progress badges.
- `getChallenges()` → active challenges the user can complete.
- `getLeaderboard(page:limit:)` → XP leaderboard, plus current user info.

---

## 2. AchievementsViewModel & UI

**Files:**

- `Views/Profile & AppSettings/AchievementsViewModel.swift`
- `Views/Profile & AppSettings/AchievementsView.swift` (or equivalent UI)

### 2.1 View model responsibilities

- Maps backend models into UI models:
  - `AchievementsUserStats`
  - `BadgeItem`
  - `ChallengeItem`
  - `LeaderboardEntry`
- Computes convenience values such as:
  - Level text, XP progress text, and percentage.
  - Current and best streaks.
  - Sorted lists of badges (earned vs locked) and challenges (active vs completed).

### 2.2 UI responsibilities

- Show user level and XP progress.
- Show current streak and best streak.
- Display badges and challenges with progress.
- Display global leaderboard with medals/emojis for top ranks.

---

## 3. Connection to AI Coach

AI Coach reuses achievement data to personalize suggestions.

- During bootstrap, `AICoachViewModel` calls `AchievementsAPI.getSummary()`.
- It extracts:
  - `currentLevel`, `currentLevelXp`, `xpForNextLevel`, `totalXp`.
  - `currentStreak`, `bestStreak`.
- Header in `AICoachView` shows:
  - Level chip + XP text.
  - A motivational streak message.

This keeps gamification consistent across the profile, achievements screen, and AI Coach.
