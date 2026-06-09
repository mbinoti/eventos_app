# Material Design 3 In Flutter

Use this reference when the screen or widget is Material-first.

## Authoritative References

- Flutter Material design guide: <https://docs.flutter.dev/ui/design/material>
- Flutter Material widget catalog: <https://docs.flutter.dev/ui/widgets/material>
- Material Design 3 components: <https://m3.material.io/components>

## Theme First

Treat `ThemeData.colorScheme`, `ThemeData.textTheme`, and component themes as the
source of truth. Material 3 is the default in current Flutter SDKs, but preserve
an explicit `useMaterial3: true` when the project already uses it.

Prefer:

```dart
final colorScheme = Theme.of(context).colorScheme;
final textTheme = Theme.of(context).textTheme;

return Card(
  color: colorScheme.surfaceContainer,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Upcoming event', style: textTheme.titleMedium),
  ),
);
```

Avoid choosing `Colors.*`, font sizes, radii, and elevations independently in
each screen. Add a component theme or shared design token when a visual decision
is repeated.

## Common Material 3 Components

| Need | Prefer |
| --- | --- |
| Page structure | `Scaffold`, `AppBar`, `SliverAppBar` |
| Primary action | `FilledButton`, `FilledButton.icon` |
| Lower-emphasis action | `FilledButton.tonal`, `OutlinedButton`, `TextButton` |
| Main destinations | `NavigationBar`, `NavigationRail`, `NavigationDrawer` |
| Mutually exclusive choices | `SegmentedButton`, `Radio`, `RadioListTile` |
| Filters and compact choices | `FilterChip`, `ChoiceChip`, `InputChip` |
| Search | `SearchBar`, `SearchAnchor` |
| Status count | `Badge` |
| Temporary feedback | `SnackBar`, `ScaffoldMessenger` |
| Floating primary action | `FloatingActionButton` |
| Content grouping | `Card`, `ListTile`, `Divider` |

Prefer Material 3 replacements such as `NavigationBar` over older Material 2
components when creating new UI. Do not assume that enabling Material 3 alone
migrates an old widget choice.

## Screen Structure

Use the scaffold slots instead of manually positioning standard page elements:

```dart
class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: const SafeArea(
        child: EventList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        icon: Icon(Icons.add),
        label: Text('Create event'),
      ),
    );
  }
}
```

For scrolling pages with collapsing headers, prefer `CustomScrollView` with
`SliverAppBar` and slivers over nested scroll views.

## Interaction And State

- Let Material widgets provide ripple, focus, hover, pressed, and disabled states.
- Use `WidgetStateProperty` when a component theme must vary by interaction state.
- Disable an action with `onPressed: null` instead of simulating a disabled color.
- Keep one visually dominant primary action per region.
- Use confirmation dialogs only for consequential or destructive actions.
- Show validation close to the relevant field and keep messages actionable.

## Layout And Accessibility

- Use `LayoutBuilder` or parent constraints for layout decisions.
- Use `Expanded` and `Flexible` to prevent row overflows.
- Make long forms scrollable and account for the keyboard.
- Keep destination labels meaningful; do not use empty labels to achieve a visual
  effect.
- Add semantic labels to icon-only actions.
- Test large text, long localized strings, loading states, and disabled states.
- Preserve sufficient contrast by using the color scheme's semantic roles.

## Avoid

- Recreating buttons, navigation bars, dialogs, sheets, or fields with generic
  `Container` widgets when Material components already exist.
- Hardcoding a different color palette in each screen.
- Wrapping every row in a card without a content hierarchy reason.
- Using platform checks to solve a width or orientation problem.
- Mixing Cupertino controls into a Material screen only for appearance.

