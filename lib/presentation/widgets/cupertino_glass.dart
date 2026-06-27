import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';

class CupertinoGlassStyle {
  CupertinoGlassStyle._();

  static const Color navigationBarBackground = Color(0xA616181D);
  static const Color tabBarBackground = Color(0x731C2028);
  static const Color tabSelectionBackground = Color(0x3DFFFFFF);
  static const Color surfaceBackground = Color(0x8F1C2028);
  static const Color prominentBackground = Color(0xA33A84FF);
  static const Color stroke = Color(0x38FFFFFF);
  static const Color tabSelectionStroke = Color(0x7AFFFFFF);
  static const Color prominentStroke = Color(0x70B8DAFF);
  static const Color highlight = Color(0x2EFFFFFF);
  static const Color lowlight = Color(0x05FFFFFF);
}

CupertinoNavigationBar cupertinoGlassNavigationBar({
  Widget? leading,
  Widget? middle,
  Widget? trailing,
}) {
  return CupertinoNavigationBar(
    transitionBetweenRoutes: false,
    backgroundColor: CupertinoGlassStyle.navigationBarBackground,
    border: const Border(
      bottom: BorderSide(
        color: CupertinoGlassStyle.stroke,
        width: 0,
      ),
    ),
    leading: leading,
    middle: middle,
    trailing: trailing,
  );
}

class CupertinoGlassSurface extends StatelessWidget {
  const CupertinoGlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.backgroundColor = CupertinoGlassStyle.surfaceBackground,
    this.borderColor = CupertinoGlassStyle.stroke,
    this.blurSigma = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CupertinoGlassStyle.highlight,
                CupertinoGlassStyle.lowlight,
              ],
            ),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class CupertinoGlassTabItem {
  const CupertinoGlassTabItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class CupertinoGlassTabBar extends StatefulWidget {
  const CupertinoGlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<CupertinoGlassTabItem> items;

  @override
  State<CupertinoGlassTabBar> createState() => _CupertinoGlassTabBarState();
}

class _CupertinoGlassTabBarState extends State<CupertinoGlassTabBar> {
  double? _dragPosition;

  void _updateDragPosition(Offset localPosition, double width) {
    final itemCount = widget.items.length;
    if (itemCount == 0 || width <= 0) {
      return;
    }

    final itemWidth = width / itemCount;
    final position = ((localPosition.dx - (itemWidth / 2)) / itemWidth)
        .clamp(0.0, (itemCount - 1).toDouble())
        .toDouble();
    setState(() => _dragPosition = position);
  }

  void _finishDrag() {
    final position = _dragPosition;
    if (position == null) {
      return;
    }

    setState(() => _dragPosition = null);
    widget.onSelected(
      position.round().clamp(0, widget.items.length - 1).toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(40, 0, 40, 10),
      child: CupertinoGlassSurface(
        padding: const EdgeInsets.all(6),
        borderRadius: BorderRadius.circular(30),
        backgroundColor: CupertinoGlassStyle.tabBarBackground,
        borderColor: CupertinoGlassStyle.stroke,
        blurSigma: 30,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemCount = widget.items.length;
            final width = constraints.maxWidth;
            final itemWidth = width / itemCount;
            final indicatorPosition =
                _dragPosition ?? widget.selectedIndex.toDouble();
            final activeIndex = indicatorPosition
                .round()
                .clamp(0, widget.items.length - 1)
                .toInt();
            final indicatorLeft =
                (itemWidth * indicatorPosition) + ((itemWidth - 44) / 2);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                _updateDragPosition(details.localPosition, width);
              },
              onHorizontalDragUpdate: (details) {
                _updateDragPosition(details.localPosition, width);
              },
              onHorizontalDragEnd: (_) => _finishDrag(),
              onHorizontalDragCancel: () {
                setState(() => _dragPosition = null);
              },
              child: SizedBox(
                height: 48,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: _dragPosition == null
                          ? const Duration(milliseconds: 180)
                          : Duration.zero,
                      curve: Curves.easeOutCubic,
                      left: indicatorLeft,
                      top: 2,
                      child: const _CupertinoGlassTabIndicator(),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: [
                          for (var index = 0; index < itemCount; index++)
                            Expanded(
                              child: _CupertinoGlassTabButton(
                                item: widget.items[index],
                                isSelected: activeIndex == index,
                                onPressed: () => widget.onSelected(index),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CupertinoGlassTabIndicator extends StatelessWidget {
  const _CupertinoGlassTabIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoGlassStyle.tabSelectionBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: CupertinoGlassStyle.tabSelectionStroke,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FFFFFFF),
            blurRadius: 14,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

class _CupertinoGlassTabButton extends StatelessWidget {
  const _CupertinoGlassTabButton({
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  final CupertinoGlassTabItem item;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? const Color(0xFFFFFFFF)
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: CupertinoButton(
        minimumSize: const Size(0, 48),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        pressedOpacity: 0.74,
        onPressed: onPressed,
        child: SizedBox(
          height: 48,
          child: IconTheme.merge(
            data: IconThemeData(color: foregroundColor, size: 25),
            child: Center(
              child: Icon(item.icon),
            ),
          ),
        ),
      ),
    );
  }
}

class CupertinoGlassButton extends StatelessWidget {
  const CupertinoGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    this.minSize = 44,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.isProminent = false,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double minSize;
  final BorderRadius borderRadius;
  final bool isProminent;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final resolvedForeground = foregroundColor ??
        (isProminent
            ? const Color(0xFFFFFFFF)
            : CupertinoColors.activeBlue.resolveFrom(context));
    final effectiveForeground = enabled
        ? resolvedForeground
        : CupertinoColors.inactiveGray.resolveFrom(context);
    final surfaceColor = isProminent
        ? CupertinoGlassStyle.prominentBackground
        : CupertinoGlassStyle.surfaceBackground;
    final borderColor = isProminent
        ? CupertinoGlassStyle.prominentStroke
        : CupertinoGlassStyle.stroke;

    Widget button = CupertinoButton(
      minimumSize: Size.square(minSize),
      padding: EdgeInsets.zero,
      borderRadius: borderRadius,
      pressedOpacity: 0.68,
      onPressed: onPressed,
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: CupertinoGlassSurface(
          padding: padding,
          borderRadius: borderRadius,
          backgroundColor: surfaceColor,
          borderColor: borderColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: math.max(0, minSize - padding.horizontal),
              minHeight: math.max(0, minSize - padding.vertical),
            ),
            child: Center(
              widthFactor: 1,
              child: IconTheme.merge(
                data: IconThemeData(color: effectiveForeground),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: effectiveForeground,
                    fontWeight: FontWeight.w600,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final label = semanticLabel;
    if (label != null) {
      button = Semantics(
        label: label,
        button: true,
        enabled: enabled,
        child: button,
      );
    }

    return button;
  }
}
