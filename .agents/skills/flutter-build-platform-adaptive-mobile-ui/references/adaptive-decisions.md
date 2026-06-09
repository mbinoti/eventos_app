# Platform-Adaptive Flutter UI

Use this reference when one feature must serve Android and iOS or when the
correct visual contract is unclear.

## Authoritative References

- Adaptive and responsive design: <https://docs.flutter.dev/ui/adaptive-responsive>
- General approach to adaptive apps: <https://docs.flutter.dev/ui/adaptive-responsive/general>
- Automatic platform adaptations: <https://docs.flutter.dev/platform-integration/platform-adaptations>

## Separate Three Decisions

Do not collapse these concerns into one platform check:

1. **Visual design:** Should the feature look Material, Cupertino, or branded?
2. **Platform behavior:** Should a control, transition, dialog, or text-editing
   behavior follow an operating-system convention?
3. **Responsive layout:** How should the UI fit the available width and height?

Use platform policy for the first two. Use constraints for the third.

## Decision Guide

| Question | Decision |
| --- | --- |
| Does the app already have a clear visual system? | Follow it before introducing a new platform branch. |
| Did the user request a native iOS experience? | Use Cupertino structure and controls on iOS. |
| Is this an OS-familiar control with the same semantics? | Consider a supported `.adaptive()` constructor. |
| Does navigation or information architecture differ? | Build small Material and Cupertino shells around shared content. |
| Is the problem caused by screen size? | Use `LayoutBuilder`, constraints, or responsive navigation. |
| Would branching duplicate validation or state? | Extract shared behavior before building the platform shells. |

## Platform Detection

Prefer the app's existing platform policy helper. If the app has none:

- Use `Theme.of(context).platform` inside a Material widget tree when theme
  overrides should affect the result.
- Use `defaultTargetPlatform` at a platform presentation boundary when there is
  no Material theme.
- Avoid `dart:io Platform.isIOS` in widgets because it is harder to test and does
  not support web builds.
- Allow an explicit style or platform parameter when a reusable widget must be
  previewed or tested independently.

Do not check the platform to decide whether a device is a phone, tablet, or
desktop. Use the available constraints.

## Adaptive Constructors

Flutter provides `.adaptive()` constructors for some controls, including common
selection, progress, refresh, and dialog widgets. The exact list and behavior can
change with the SDK, so inspect the local API before use.

Use an adaptive constructor when:

- The control has the same meaning and callback contract on both platforms.
- The platform-specific visual and behavioral differences are desirable.
- The surrounding screen can support either implementation.

Do not expect `.adaptive()` to choose navigation structure, page chrome, content
hierarchy, or app branding.

Example:

```dart
class NotificationToggle extends StatelessWidget {
  const NotificationToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
    );
  }
}
```

## Share Content, Branch Chrome

Keep the feature behavior and content reusable, then branch only where platform
conventions differ:

```dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const content = SettingsContent();

    if (isCupertinoPlatform) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Settings'),
        ),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SafeArea(child: content),
    );
  }
}
```

Use a project-specific helper such as `isCupertinoPlatform` only when it already
exists or when the app deliberately defines that policy.

## Testing Both Branches

- Add widget tests for both target platforms when the widget tree differs.
- Override the platform in tests and restore it during teardown.
- Verify callbacks and state changes independently of visual implementation.
- Add golden tests only when visual fidelity is important enough to justify their
  maintenance cost.

Example test setup:

```dart
debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
addTearDown(() => debugDefaultTargetPlatformOverride = null);
```

## Common Failure Modes

- Duplicating whole screens and letting the two implementations drift.
- Using a platform check for a responsive-layout problem.
- Mixing Material controls into a Cupertino page without required ancestors.
- Assuming all Material widgets automatically become Cupertino on iOS.
- Assuming every `.adaptive()` constructor has identical properties or behavior.
- Creating custom controls before checking the Flutter SDK.

