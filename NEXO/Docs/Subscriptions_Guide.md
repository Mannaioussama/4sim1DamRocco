# Subscriptions Guide

This guide focuses on **recurring subscriptions** in the NEXO app (premium plans for coaches or power users).

---

## 1. Subscription models & API

**File:** `Services/SubscriptionAPI.swift`

### 1.1 Models

- `SubscriptionResponse` – current subscription details.
- `SubscriptionPlan` – plan metadata (name, price, interval, features, Stripe price id).
- `SubscriptionPlansResponse` – available plans + `currentPlan`.
- `CheckLimitResponse` – tells whether the user can create more activities.
- `InitializePaymentResponse` – Stripe setup intent + client secret.

### 1.2 Endpoints

- `GET /subscriptions/plans` → available plans + current subscription.
- `GET /subscriptions/me` → current subscription only.
- `GET /subscriptions/check-limit` → validate if the user can create a new activity.
- `POST /subscriptions/initialize-payment` → prepare Stripe setup intent for a plan type.
- `POST /subscriptions` → create a subscription for a given plan.

`SubscriptionAPI` wraps these via static async methods:

```swift
static func getAvailablePlans() async throws -> SubscriptionPlansResponse
static func getCurrentSubscription() async throws -> SubscriptionResponse
static func checkActivityLimit() async throws -> CheckLimitResponse
static func initializePayment(planType: String) async throws -> InitializePaymentResponse
static func createSubscription(type: String, paymentMethodId: String?, setupIntentId: String?) async throws -> SubscriptionResponse
```

---

## 2. SubscriptionViewModel & PremiumBillingView

**Files:**

- `Views/Profile & AppSettings/SubscriptionViewModel.swift`
- `Views/Profile & AppSettings/PremiumBillingView.swift` (or equivalent UI)

### 2.1 SubscriptionViewModel

Published state:

- `plans: [SubscriptionPlan]`
- `currentPlan: SubscriptionResponse?`
- Loading & error flags.
- Payment-init state: `clientSecret`, `setupIntentId`, `selectedPlanType`.

Main methods:

- `loadPlans()` – fetch `SubscriptionAPI.getAvailablePlans()`.
- `loadCurrentSubscription()` – fetch `SubscriptionAPI.getCurrentSubscription()`.
- `initializePayment(planType:)` – calls `SubscriptionAPI.initializePayment`, sets `clientSecret` & `setupIntentId`.
- `subscribeToPlan(planType:paymentMethodId:setupIntentId:)` – calls `SubscriptionAPI.createSubscription`.

### 2.2 PremiumBillingView

- Reads from `SubscriptionViewModel`.
- Shows:
  - List of available plans with pricing and feature highlights.
  - Current plan information.
- Triggers flows:
  - Start subscription for selected plan.
  - Show Stripe PaymentSheet using the `clientSecret` from `initializePayment`.

---

## 3. Activity limits & gating features

Some features (like creating many activities per month) are gated by subscription.

- Use `SubscriptionAPI.checkActivityLimit()` before allowing creation of a new activity.
- Use the `CheckLimitResponse` fields to decide:
  - Whether to block the action.
  - Whether to show an upsell/paywall for upgrading the plan.

---

## 4. Adding a new subscription tier

1. **Backend:**
   - Define a new plan type and Stripe price id.
   - Ensure it appears in `/subscriptions/plans`.

2. **iOS:**
   - No code changes needed if plans are fully data-driven.
   - Optionally add custom UI labels or highlighting for the new plan.

See also `Payments_Guide.md` for one-off payments.
