# Localization & Theming Guide

This guide describes how localization (languages, RTL) and theming (colors, typography) are handled.

---

## 1. Localization

**File:** `Config/LocalizationManager.swift`

### 1.1 LocalizationManager

- Singleton `LocalizationManager.shared` is an `ObservableObject` used as an environment object.
- Tracks:
  - Current language code.
  - Whether the language is RTL (`isRTL`).
- `NEXOApp` applies layout direction based on `isRTL`:

```swift
.environment(\.layoutDirection, localizationManager.isRTL ? .rightToLeft : .leftToRight)
```

This ensures the entire app flips for RTL languages like Arabic.

### 1.2 Adding new languages

1. Add new `.strings` files and localizations in Xcode.
2. Extend `LocalizationManager` with the new language code and any helper logic.
3. Provide a settings UI to change language if desired.

---

## 2. Theme

**File:** `Theme.swift` (typically under `Theme/` or root).

- `Theme` is an `ObservableObject` that centralizes:
  - Color palette (`theme.colors.*`).
  - Typography and spacing conventions.
  - Dark/light mode toggle (`isDarkMode`).

In `NEXOApp`:

```swift
.preferredColorScheme(theme.isDarkMode ? .dark : .light)
```

### 2.1 Using Theme in views

- Injected via `@EnvironmentObject private var theme: Theme`.
- Views use `theme.colors` for:
  - Backgrounds and cards.
  - Accent colors (`accentPurple`, `accentPink`, `accentGreen`, etc.).
  - Text colors (`textPrimary`, `textSecondary`).

This keeps the visual style consistent across all screens.

---

## 3. Example: AI Coach styling

In `AICoachView` and related views:

- Gradient header in `SuggestionsTabView` uses:

```swift
LinearGradient(
    colors: [theme.colors.accentPurple, theme.colors.accentPink],
    startPoint: .leading,
    endPoint: .trailing
)
```

- Cards reuse theme colors for borders, backgrounds, and shadows.

---

## 4. Best practices

- Always use `theme.colors` and not raw `Color(..)` values for primary UI.
- For RTL-friendly layouts, avoid hard-coded `.leading`/`.trailing` decisions when the intent is visual; prefer semantic stacks and alignment.
- When adding new features, decide which colors and text styles to use by following existing screens for consistency.
