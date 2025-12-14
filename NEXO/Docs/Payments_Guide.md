# Payments Guide

This guide focuses on **one-off payments** in the NEXO app (e.g. paying for a single coach session or purchase).

---

## 1. Stripe configuration

**Files:**

- `Config/StripeConfig.swift`
- `NEXOApp.swift`

### 1.1 StripeConfig

- Encapsulates Stripe SDK setup (publishable key, configuration options).
- Called once at app startup:

```swift
.onAppear {
    StripeConfig.shared.configure()
}
```

---

## 2. PaymentAPIService

**File:** `Services/PaymentAPIService.swift`

- Handles **single payments** such as:
  - Paying for a coach session.
  - Paying for a one-time purchase.
- Talks to backend payment endpoints to:
  - Create payment intents.
  - Confirm / update payments.
- Wraps Stripe PaymentSheet / Apple Pay flows on iOS.

The exact methods depend on your backend contract, but the pattern is:

1. Call backend to create a PaymentIntent or SetupIntent.
2. Present Stripe UI with the client secret.
3. Notify backend on completion and update app state accordingly.

---

## 3. Using payments in UI

Typical places where one-off payments are used:

- Coach session booking screens.
- Any feature that is unlocked once per purchase (as opposed to a recurring subscription).

Flow:

1. User taps a **"Book"** or **"Pay"** button.
2. View model asks `PaymentAPIService` to create/initiate a payment.
3. Stripe PaymentSheet / Apple Pay sheet is shown.
4. On success, backend confirms the payment and the UI updates (e.g. session is booked).

See also `Subscriptions_Guide.md` for recurring payments.
