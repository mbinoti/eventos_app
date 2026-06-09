# Cupertino And iOS UI In Flutter

Use this reference when the screen or widget should feel native on iOS.

## Authoritative References

- Flutter Cupertino design guide: <https://docs.flutter.dev/ui/design/cupertino>
- Flutter Cupertino widget catalog: <https://docs.flutter.dev/ui/widgets/cupertino>
- Flutter Cupertino API: <https://api.flutter.dev/flutter/cupertino/cupertino-library.html>
- Apple Human Interface Guidelines: <https://developer.apple.com/design/human-interface-guidelines/>

## Use Cupertino Structure

Prefer Cupertino components for page chrome, navigation, controls, and modal
presentation instead of styling Material widgets to resemble iOS.

| Need | Prefer |
| --- | --- |
| App root | `CupertinoApp` |
| Standard page | `CupertinoPageScaffold` |
| Navigation bar | `CupertinoNavigationBar`, `CupertinoSliverNavigationBar` |
| Tab navigation | `CupertinoTabScaffold`, `CupertinoTabBar`, `CupertinoTabView` |
| Route transition | `CupertinoPageRoute`, `CupertinoPage` |
| Primary action | `CupertinoButton.filled` |
| Text input | `CupertinoTextField`, `CupertinoTextFormFieldRow` |
| Form grouping | `CupertinoFormSection`, `CupertinoFormRow` |
| Search | `CupertinoSearchTextField` |
| Alert | `CupertinoAlertDialog`, `showCupertinoDialog` |
| Choice or destructive actions | `CupertinoActionSheet`, `showCupertinoModalPopup` |
| Sheet presentation | `showCupertinoSheet` |
| Loading | `CupertinoActivityIndicator` |
| Pull to refresh | `CupertinoSliverRefreshControl` |
| Toggle or range | `CupertinoSwitch`, `CupertinoSlider` |
| Short exclusive choices | `CupertinoSlidingSegmentedControl` |

## Theme And Color

- Read colors and text styles from `CupertinoTheme.of(context)`.
- Prefer `CupertinoColors.system*` and `CupertinoDynamicColor` for colors that
  must respond to brightness or accessibility settings.
- Let Cupertino widgets supply current iOS shapes, motion, and materials.
- Avoid manually recreating current iOS visual effects; SDK widgets age better
  as Apple's design language changes.

Example:

```dart
class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Event'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Flutter Meetup', style: textTheme.navLargeTitleTextStyle),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: null,
              child: const Text('Get ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## iOS Conventions

- Preserve back-swipe navigation by using Cupertino routes and navigators.
- Use tab bars for top-level destinations, not for actions within a page.
- Use large titles for content-oriented root pages when it matches the app.
- Place destructive actions in an action sheet or clearly styled confirmation.
- Prefer text labels for navigation-bar actions when an icon is ambiguous.
- Keep search visible and easy to discover when it is a primary task.
- Use system-provided controls for familiar behaviors such as toggles, pickers,
  dialogs, and text editing.

## Forms And Validation

`CupertinoTextField` is not a `FormField`. Use `CupertinoTextFormFieldRow` when
the feature needs `Form` integration, or keep validation state outside the field
and show an adjacent error message.

Keep controllers, validation rules, submission callbacks, and loading state
shared with the Material implementation.

## Mixing Libraries

A `CupertinoApp` does not automatically provide every Material ancestor,
localization, or visual surface. If shared content includes a Material widget,
verify its requirements and wrap only the smallest necessary subtree. Prefer
foundation widgets or a Cupertino equivalent when the Material styling would
leak into the iOS experience.

## Avoid

- Building an iOS screen from `Scaffold`, `AppBar`, and heavily restyled Material
  controls when a native Cupertino experience is required.
- Using Material floating action buttons as a default iOS pattern.
- Hardcoding colors that fail in dark mode.
- Replacing all app branding with Cupertino styling when only a system control
  needs to feel native.
- Copying business logic into separate iOS-only widget trees.

