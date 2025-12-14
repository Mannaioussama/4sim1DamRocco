# Coach Sessions & Activity Rooms Guide

This guide describes how live coach sessions and activity rooms work.

---

## 1. Activity rooms (coach sessions)

**Key files:**

- `Services/ActivityRoomWebSocketService.swift`
- `Views/Activity & Events/Coach Session/ActivityRoomViewModel.swift`
- `Views/Activity & Events/Coach Session/ActivityRoomView.swift`
- `Views/Activity & Events/Coach Session/ReviewsModels.swift`

### 1.1 WebSocket service

`ActivityRoomWebSocketService` wraps the WebSocket connection to the backend:

- Connects to `APIConfig.webSocketEndpoint` with appropriate path/query for a room.
- Sends/receives messages for:
  - Chat
  - Presence / attendees
  - Reactions or coach-specific events
- Exposes delegate/callbacks used by the view model.

### 1.2 ActivityRoomViewModel

- Owns:
  - Current room state (participants, messages, typing indicators, etc.).
  - Connection status.
- Uses `ActivityRoomWebSocketService` to:
  - Join a room.
  - Send messages.
  - Handle incoming events and update SwiftUI state.

### 1.3 ActivityRoomView

- SwiftUI UI for the live session:
  - Header with host/coach info.
  - List of messages.
  - Input bar for sending new messages.
  - Any coach-specific UI (e.g. rating, ending session).

---

## 2. Coach reviews

**File:** `Views/Activity & Events/Coach Session/ReviewsModels.swift`

- Models coach reviews and ratings shown after a session.
- Typically connected to a backend reviews service (`ReviewsService`).

---

## 3. Creating paid coach sessions

Paid sessions are activities with a non-nil `price`:

- The `ActivityAPIService` marks `isPaidSession = true` when `price != nil`.
- UI can show price labels and gate join actions behind Stripe payments.

**Related services and views:**

- `Services/PaymentAPIService.swift`
- `Services/SubscriptionAPI.swift`
- Coach onboarding / profile screens under `Views/Profile & AppSettings/`.

---

## 4. Extending coach experiences with AI (future)

Planned ideas (not yet fully implemented):

- Suggest optimal times and prices for sessions based on:
  - Past attendance
  - Reviews
  - Earnings
- Provide AI-generated descriptions/titles for new coach sessions.

When you implement these, reuse the existing activity + reviews models and pipe additional metadata into the `/ai-coach` backend or a dedicated coach-AI endpoint.
