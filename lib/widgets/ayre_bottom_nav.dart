import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'ayre_nav_metrics.dart';

export 'ayre_nav_metrics.dart' show NavDestination, kNavDestinations;

/// A stable handle on a destination, used by tests, the spotlight tour and the
/// tooltip/semantics wiring.
Key navDestinationKey(String label) => ValueKey('nav-destination-$label');

/// The always-visible bottom navigation: a full-width card dock with a 1px
/// top border and 26px top corners, flush with the window bottom.
///
/// Four equally spaced destinations, each an outline glyph in a transparent
/// 55×34 slot with an 11/700 label. The dock uses two rows when needed to fit
/// the destination labels at the chosen text size. Selection is the brand
/// colour plus one saffron marker (34×4, skewed −24°) that glides between
/// item centres.
///
/// [onSelected] fires only for a *new* index (with the selection haptic).
/// [onReselected] fires when the already-selected item is tapped; it never
/// plays a haptic.
class AyreBottomNav extends StatelessWidget {
  const AyreBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.onReselected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int>? onReselected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final media = MediaQuery.of(context);
    final highContrast = MediaQuery.highContrastOf(context);

    final columns = AyreNavMetrics.dockColumnsOf(context);
    final labelHeight = AyreNavMetrics.dockLabelHeightOf(context, columns);
    final inset = media.viewPadding.bottom;
    final barHeight = AyreNavMetrics.barHeightFor(
      columns: columns,
      labelHeight: labelHeight,
      bottomInset: inset,
    );

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppShape.sheetTop,
        border: Border(
          top: BorderSide(color: highContrast ? t.foregroundMuted : t.hairline),
          left: BorderSide(color: t.hairline),
          right: BorderSide(color: t.hairline),
        ),
      ),
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: EdgeInsets.only(
            left: AyreNavMetrics.horizontalPadding + media.viewPadding.left,
            right: AyreNavMetrics.horizontalPadding + media.viewPadding.right,
          ),
          child: _DockItems(
            columns: columns,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            onReselected: onReselected,
            labelHeight: labelHeight,
          ),
        ),
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AyreNavMetrics.dockWidthFor(media.size.width),
        ),
        child: ClipRRect(borderRadius: AppShape.sheetTop, child: surface),
      ),
    );
  }
}

class _DockItems extends StatelessWidget {
  const _DockItems({
    required this.columns,
    required this.selectedIndex,
    required this.onSelected,
    required this.onReselected,
    required this.labelHeight,
  });

  final int columns;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int>? onReselected;
  final double labelHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final count = kNavDestinations.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final rows = (count / columns).ceil();
    final itemHeight = AyreNavMetrics.dockItemHeightFor(labelHeight);

    Widget row(int rowIndex) => Row(
      children: [
        for (var i = rowIndex * columns; i < (rowIndex + 1) * columns; i++)
          Expanded(
            child: i < count
                ? _NavItem(
                    key: navDestinationKey(kNavDestinations[i].label),
                    index: i,
                    destination: kNavDestinations[i],
                    selected: i == selectedIndex,
                    onTap: () =>
                        _handleTap(i, selectedIndex, onSelected, onReselected),
                    labelHeight: labelHeight,
                    vertical: false,
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / columns;
        // The marker's left edge, centred on the selected item. The dock is
        // inset by its own padding, so the marker is positioned in the same
        // coordinate space as the items.
        final markerLeft =
            slotWidth * (selectedIndex % columns) +
            (slotWidth - AyreNavMetrics.markerWidth) / 2;
        final markerTop =
            (selectedIndex ~/ columns) *
            (itemHeight + AyreNavMetrics.dockRowGap);
        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  for (var i = 0; i < rows - 1; i++) ...[
                    SizedBox(height: itemHeight, child: row(i)),
                    const SizedBox(height: AyreNavMetrics.dockRowGap),
                  ],
                  Expanded(child: row(rows - 1)),
                ],
              ),
              AnimatedPositionedDirectional(
                duration: reduceMotion ? Duration.zero : AppMotion.navMarker,
                curve: AppMotion.easeInOut,
                start: markerLeft,
                top: markerTop,
                width: AyreNavMetrics.markerWidth,
                height: AyreNavMetrics.markerHeight,
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.skewX(
                        math.tan(
                          AyreNavMetrics.markerSkewDegrees * math.pi / 180,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.notch,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _handleTap(
  int index,
  int selectedIndex,
  ValueChanged<int> onSelected,
  ValueChanged<int>? onReselected,
) {
  if (index == selectedIndex) {
    // A re-tap never plays the selection haptic.
    onReselected?.call(index);
    return;
  }
  HapticFeedback.selectionClick();
  onSelected(index);
}

/// Large-window (at/above the two-column pivot) counterpart to
/// [AyreBottomNav]: the same items, colours, states and semantics, stacked
/// vertically in a scrollable column on a card surface with a hairline
/// divider and a small vertical saffron marker.
class AyreNavRail extends StatelessWidget {
  const AyreNavRail({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.onReselected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int>? onReselected;

  static const double width = AyreNavMetrics.railWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final media = MediaQuery.of(context);
    final width = AyreNavMetrics.railWidthOf(context);
    final labelHeight = AyreNavMetrics.labelHeightFor(context, width);

    final duration = media.disableAnimations
        ? Duration.zero
        : AppMotion.navMarker;
    const gap = AppSpace.xxs;
    const railTop = AppSpace.s13;
    final itemHeight = math.max(
      AyreNavMetrics.railItemMinHeight,
      16 + AyreNavMetrics.slotHeight + AyreNavMetrics.labelGap + labelHeight,
    );
    final leftToRight = Directionality.of(context) == TextDirection.ltr;
    final leadingInset = leftToRight ? media.padding.left : media.padding.right;

    return Container(
      width: width + leadingInset,
      decoration: BoxDecoration(
        color: t.surface,
        border: BorderDirectional(end: BorderSide(color: t.hairline)),
      ),
      child: SafeArea(
        left: leftToRight,
        right: !leftToRight,
        child: SingleChildScrollView(
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: railTop),
                  child: Column(
                    children: [
                      for (var i = 0; i < kNavDestinations.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: gap),
                          child: SizedBox(
                            height: itemHeight,
                            child: _NavItem(
                              key: navDestinationKey(kNavDestinations[i].label),
                              index: i,
                              destination: kNavDestinations[i],
                              selected: i == selectedIndex,
                              onTap: () => _handleTap(
                                i,
                                selectedIndex,
                                onSelected,
                                onReselected,
                              ),
                              labelHeight: labelHeight,
                              vertical: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedPositionedDirectional(
                  duration: duration,
                  curve: AppMotion.easeInOut,
                  start: 0,
                  top:
                      railTop +
                      gap +
                      8 +
                      selectedIndex * (itemHeight + 2 * gap),
                  width: AyreNavMetrics.markerHeight,
                  height: AyreNavMetrics.slotHeight,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.notch,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One destination, shared by the dock and the rail so states, semantics and
/// focus cannot drift. The whole slot is the hit target.
class _NavItem extends StatefulWidget {
  const _NavItem({
    super.key,
    required this.index,
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.labelHeight,
    required this.vertical,
  });

  final int index;
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final double labelHeight;

  /// True in the rail, where each destination is centred in its row.
  final bool vertical;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final selected = widget.selected;
    final color = selected ? t.accentInk : t.foregroundMuted;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label = widget.destination.label;
    const radius = BorderRadius.all(Radius.circular(AyreNavMetrics.slotRadius));

    var background = AppTheme.transparent;
    if (_pressed) {
      background = t.surfaceRaised;
    } else if (_hovered) {
      background = t.surfaceRaised.withValues(alpha: 0.6);
    }

    final labelStyle = AyreNavMetrics.labelStyleOf(context, color: color);

    final slot = SizedBox(
      width: AyreNavMetrics.slotWidth,
      height: AyreNavMetrics.slotHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : AppMotion.buttonPress,
              curve: AppMotion.easeInOut,
              decoration: BoxDecoration(
                color: background,
                borderRadius: radius,
                border: _focused
                    ? Border.all(color: t.focusRing, width: 2)
                    : null,
              ),
            ),
          ),
          AyreIcon(
            widget.destination.glyph,
            size: AyreNavMetrics.glyphSize,
            color: color,
          ),
        ],
      ),
    );

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        slot,
        const SizedBox(height: AyreNavMetrics.labelGap),
        SizedBox(
          height: widget.labelHeight,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AyreNavMetrics.labelPadding,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                label,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.vertical) {
      content = Center(child: content);
    } else {
      content = Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: AyreNavMetrics.topPadding),
          child: content,
        ),
      );
    }

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      hint: 'Tab ${widget.index + 1} of ${kNavDestinations.length}',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        preferBelow: false,
        excludeFromSemantics: true,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: content,
          ),
        ),
      ),
    );
  }
}
