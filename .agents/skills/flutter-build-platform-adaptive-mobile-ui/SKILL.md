---
name: flutter-build-platform-adaptive-mobile-ui
description: Create and refactor Flutter mobile screens and reusable widgets that use Material Design 3, Cupertino/iOS, or a deliberate platform-adaptive combination. Use when Codex needs to implement a screen, navigation, form, dialog, sheet, list, card, input control, theme, or shared widget for Android and/or iOS; translate a mobile design into Flutter; make an existing Material screen feel native on iOS; or choose between Material, Cupertino, and `.adaptive()` widgets.
---

# Build Platform-Adaptive Flutter Mobile UI

Create mobile UI that feels intentional on its target platform, reuses the app's
theme and architecture, and keeps business behavior separate from visual chrome.

## Workflow

1. Inspect the app before editing:
   - Read `pubspec.yaml`, the root app widget, theme definitions, routing, platform
     helpers, nearby screens, and reusable widgets.
   - Identify whether the app is Material-first, Cupertino-first, or already uses
     separate platform shells.
   - Preserve the existing state-management and feature organization.
2. Choose one visual contract for the feature:
   - **Material 3-first** for a branded cross-platform UI or Android-focused app.
   - **Cupertino-first** when the user requests a native iOS experience or the app
     already uses a Cupertino root on iOS.
   - **Platform-adaptive** when shared content should use different controls,
     navigation, dialogs, or page chrome on Android and iOS.
3. Separate shared behavior from platform presentation:
   - Share models, controllers, validation, callbacks, loading state, and content.
   - Keep platform branches small and close to the widgets that genuinely differ.
   - Do not duplicate business logic in Material and Cupertino widget trees.
4. Implement with SDK widgets before creating custom controls:
   - Read [references/material-3.md](references/material-3.md) for Material work.
   - Read [references/cupertino-ios.md](references/cupertino-ios.md) for iOS work.
   - Read [references/adaptive-decisions.md](references/adaptive-decisions.md) for
     cross-platform work or whenever the visual contract is unclear.
5. Verify behavior, accessibility, and both target platforms.

## Choose Deliberately

| Situation | Preferred approach |
| --- | --- |
| The app has one strong brand across Android and iOS | Use Material 3 consistently; adapt only OS-conventional behavior where useful. |
| The user explicitly asks for native iOS UI | Use Cupertino page structure, navigation, controls, dialogs, and system colors. |
| The app already has separate Material and Cupertino roots | Follow that pattern and share feature content underneath small platform shells. |
| A control has the same meaning but should follow the OS convention | Prefer a supported `.adaptive()` constructor after checking the local SDK. |
| Layout changes because of available width | Use constraints and responsive layout, not platform checks. |

Do not assume every iOS build must use Cupertino. Platform identity, app brand,
and the existing codebase all matter.

## Implementation Rules

- Reuse the app's theme, spacing, typography, icons, and shared components.
- Prefer semantic theme values over hardcoded colors and text styles.
- Prefer Material or Cupertino SDK components over hand-drawn imitations.
- Use the existing platform policy helper. If none exists, keep platform
  detection at a UI boundary and avoid `dart:io` checks inside widgets.
- Use `SafeArea`, keyboard insets, scrollable content, and constraints where the
  screen can be obscured or resized.
- Keep touch targets usable, preserve text scaling, provide meaningful labels,
  and never communicate state by color alone.
- Preserve platform navigation behavior, including Android back navigation and
  iOS back-swipe transitions.
- Avoid mixing Material and Cupertino widgets casually. A widget may require a
  `Material`, theme, localization, or navigator ancestor that the other app root
  does not provide.
- Add a reusable adaptive abstraction only after the same decision appears in
  multiple places or when it clearly removes duplicated widget trees.

## Project Policy

When working in `eventos_app`:

- Reuse `lib/services/platform_info.dart` and its `isCupertinoPlatform` policy.
- Reuse `AppTheme.darkTheme` for Material screens.
- Reuse the `CupertinoThemeData` configured by the root `CupertinoApp`.
- Follow the existing pattern of small `CupertinoPageScaffold` or `Scaffold`
  branches with shared content and callbacks.
- Do not add another iOS detection helper unless the platform policy changes.

## Validation

- Format changed Dart files.
- Run `flutter analyze`.
- Run relevant widget tests and add coverage for meaningful interactions.
- Exercise both Android and iOS branches when platform presentation differs.
- Check loading, empty, error, disabled, focused, keyboard-open, and long-text
  states where relevant.
- Check dark and light themes if the app supports both.
- Inspect the result on a narrow mobile viewport and with larger text scaling.

