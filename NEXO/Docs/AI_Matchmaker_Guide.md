# AI Matchmaker Guide

This guide explains the AI Matchmaker chat experience that helps users discover activities and partners.

---

## 1. Overview

**Key files:**

- `Views/Ai Features/AIMatchmakerView.swift`
- `Views/Ai Features/AIMatchmakerViewModel.swift`
- `Services/AIMatchmakerAPI.swift`

AI Matchmaker is a chat-style UI where the user talks to an AI assistant that:

- Asks questions about goals and preferences.
- Suggests activities (sessions) that match them.
- Suggests potential partners/users to connect with.
- Provides quick-reply buttons to keep the flow simple.

---

## 2. Backend API

**File:** `Services/AIMatchmakerAPI.swift`

- Sends chat conversations to backend AI via:

```swift
AIMatchmakerAPI.chat(
    message: String,
    conversationHistory: [AIMatchmakerChatMessage]?
)
```

- Endpoint: `POST /ai-matchmaker/chat`
- Request body:
  - `message`: current user input.
  - `conversationHistory`: previous messages, each with:
    - `role`: `"user"` or `"assistant"`
    - `content`: plain text message
- Response (`ChatResponse`):
  - `message`: AI reply text.
  - `suggestedActivities: [SuggestedActivity]?`
  - `suggestedUsers: [SuggestedUser]?`
  - `options: [String]?` – optional quick-reply buttons.

`SuggestedActivity` and `SuggestedUser` contain the fields needed to render cards in the UI (titles, sports, locations, scores, etc.).

---

## 3. View model: AIMatchmakerViewModel

**File:** `Views/Ai Features/AIMatchmakerViewModel.swift`

Published state:

- `messages: [AIMatchMessage]` – the full conversation.
- `inputText: String` – text from the input bar.
- `isTyping: Bool` – shows typing indicator while waiting for backend.

Message model:

```swift
struct AIMatchMessage: Identifiable {
    let id: String
    let type: AIMatchMessageType  // .ai or .user
    let text: String?
    let options: [String]?
    let suggestedActivities: [SuggestedActivity]?
    let suggestedUsers: [SuggestedUser]?
    let suggestedSports: [String]?
}
```

Flow:

1. **Initial message**
   - `loadInitialMessage()` adds a localized AI welcome message with a few options (e.g. running, group activity, discover sports).

2. **User interacts**
   - Tapping an option calls `handleOptionSelect(_:)`.
   - Typing and sending text calls `handleSend()`.
   - Both methods append a user message and call `sendToBackend(_:)`.

3. **Backend call**
   - `sendToBackend(_:)`:
     - Sets `isTyping = true`.
     - Builds `conversationHistory` from existing messages.
     - Awaits `AIMatchmakerAPI.chat(...)`.
     - Appends an AI message with:
       - Reply text
       - Suggested activities/users
       - Next-step options
     - On error, appends a fallback AI error message with recovery options.

4. **Actions**
   - `joinActivity(_:)` – currently prints a log and adds a confirmation message (TODO: hook into real activity detail/booking).
   - `viewProfile(_:)` – currently prints a log (TODO: navigate to profile screen).

The view model also has small analytics hooks (`trackMessageSent`, `trackOptionSelected`) that currently print to console.

---

## 4. View: AIMatchmakerView

**File:** `Views/Ai Features/AIMatchmakerView.swift`

- Layout:
  - Background gradient orbs.
  - Scrollable list of `AIMatchMessageBubble` views.
  - Typing indicator when `viewModel.isTyping`.
  - Input bar at the bottom.
- Navigation bar:
  - Custom back button via `onBack` closure.
  - Centered title using localized `aiMatchmaker.nav.title`.

### 4.1 Callbacks for integration

`AIMatchmakerView` exposes closures so the parent can react to AI suggestions:

```swift
AIMatchmakerView(
    onBack: { ... },
    onJoinActivity: { activityId in ... },
    onViewProfile: { profileId in ... }
)
```

Inside `AIMatchmakerView`, these are passed down to `AIMatchMessageBubble` and called when:

- User taps “Join” on an `ActivitySuggestionCard` → `onJoinActivity?(activityId)`.
- User taps “View profile” on a `UserSuggestionCard` → `onViewProfile?(profileId)`.

> **TODO:** In your parent screen (e.g. Home or a dedicated AI tab), wire these closures to:
>
> - Open the real activity detail / booking flow.
> - Open the user profile screen (with follow/chat options).

---

## 5. How AI Matchmaker and AI Coach differ

- **AI Coach** focuses on training guidance and YouTube videos, heavily using your stats and Strava (once wired fully).
- **AI Matchmaker** focuses on **who** to play/train with and **which session** to join, in a conversational UI.

They are complementary: AI Coach optimizes your training; AI Matchmaker helps you meet people and find the right sessions.
