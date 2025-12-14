# Chat & Social Guide

This guide explains chat, group conversations, and social interactions.

---

## 1. Chat API

**File:** `Services/ChatAPI.swift`

Responsibilities:

- Fetches conversations and messages from the backend.
- Sends new messages.
- Creates group chats tied to activities:

  ```swift
  ChatAPI.createActivityGroupChat(activityId: ...)
  ```

The exact methods mirror backend endpoints for:

- Listing chats
- Fetching messages
- Sending messages
- Managing group chats

---

## 2. Chat UI

**Typical files (may vary by version):**

- `Views/Activity & Events/ChatConversationView.swift`
- `Views/Activity & Events/ChatConversationViewModel.swift`
- Any chat list / inbox views under `Views/Activity & Events/` or `Views/Core App Screens/`.

The chat view model owns:

- The list of messages.
- Pagination / loading state.
- Sending new messages via `ChatAPI`.

The chat view displays:

- Bubble list.
- Input field.
- Optional typing indicators / read status.

---

## 3. Activity-linked group chats

From AI Coach suggestions (and other places), you can create a group chat for an activity.

**In `SuggestionsTabView`:**

```swift
Task {
    let response = try await ChatAPI.createActivityGroupChat(activityId: suggestion.id)
    router.select(.chat)
    router.push(.chatConversation(chatId: response.chat.id))
}
```

This:

1. Asks backend to create (or reuse) a group chat associated with a given activity.
2. Navigates the app to the chat tab.
3. Pushes the conversation screen.

---

## 4. Social features

Other social-related services include:

- `Services/FollowService.swift` – following/unfollowing users.
- `Views/Core App Screens/HomeFeedView.swift` & `HomeFeedViewModel` – feed of activities / content.
- Profile-related screens where users can see followers/following counts.

These build on top of the same auth and routing infrastructure described in the Auth & Routing guide.
