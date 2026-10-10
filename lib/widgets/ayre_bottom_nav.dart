import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'ayre_nav_metrics.dart';
import 'spring.dart';

/// A navigation destination. The label is rendered on screen (icon + label on
/// every item) and is also the accessibility name.
class NavDestination {
  const NavDestination({required this.label, required this.glyph});

  final String label;
  final AyreGlyph glyph;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(label: 'Home', glyph: AyreGlyph.home),
  NavDestination(label: 'Reports', glyph: AyreGlyph.report),
  NavDestination(label: 'Insights', glyph: AyreGlyph.insights),
  NavDestination(label: 'Learn', glyph: AyreGlyph.learn),
  NavDestination(label: 'Profile', glyph: AyreGlyph.profile),
];

/// A stable handle on a destination, used by tests, the spotlight tour and the
/// tooltip/semantics wiring.
Key navDestinationKey(String label) => ValueKey('nav-destination-$label');

/// Selected-state indicator: a soft capsule (`accentSoft`) behind the glyph,
/// with the glyph and label in `accentInk`.
///
/// This is the single place to change if the soft capsule feels too quiet on
/// device (plan §3.5): return `(fill: t.accent, glyph: t.onAccent)` for the
/// solid fallback. Geometry, labels, semantics and motion do not change.
({Color fill, Color glyph}) _indicatorColors(AppThemeTokens t) =>
    (fill: t.accentSoft, glyph: t.accentInk);

/// Unselected glyph and label. `foregroundMuted` in light (the translucent bar
/// sits over dark content there), `foregroundSubtle` in dark.
Color _unselectedColor(AppThemeTokens t, bool dark) =>
    dark ? t.foregroundSubtle : t.foregroundMuted;

/// The always-visible bottom navigation: a floating dock (plan §3.3).
///
/// Five equal slots, each an indicator capsule holding a 24-pt glyph with the
/// destination's label beneath it. The selected capsule glides between slots on
/// [AppSpring.navPill]; the glyph crossfades outline to filled and colours lerp
/// on the same value. Nothing pops, lifts or enlarges.
///
/// Surface: iOS/macOS get a light blur, everything else a plain tonal surface.
/// With high-contrast on, the dock is opaque with a visible border.
///
/// [onSelected] fires only for a *new* index (with the selection haptic).
/// [onReselected] fires when the already-selected item is tapped (A2); it never
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
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final platform = theme.platform;
    final apple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final highContrast = MediaQuery.highContrastOf(context);

    final scale = media.textScaler.scale(100) / 100;
    final labelSize = AyreNavMetrics.labelSizeFor(platform);
    final barHeight = AyreNavMetrics.barHeightFor(
      textScale: scale,
      labelSize: labelSize,
    );
    final margin = AyreNavMetrics.marginFor(media.size.width);
    final inset = media.viewPadding.bottom;
    final radius = BorderRadius.circular(AppRadius.pill);

    final alpha = highContrast
        ? 1.0
        : apple
        ? (dark ? 0.82 : 0.88)
        : (dark ? 0.90 : 0.94);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: t.navBg.withValues(alpha: alpha),
        borderRadius: radius,
        border: Border.all(
          color: highContrast ? t.foregroundSubtle : t.navHairline,
        ),
      ),
      child: SizedBox(
        height: barHeight,
        child: _DockItems(
          selectedIndex: selectedIndex,
          onSelected: onSelected,
          onReselected: onReselected,
          barHeight: barHeight,
          labelSize: labelSize,
          textScale: scale,
        ),
      ),
    );
    if (apple && !highContrast) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: surface,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        margin,
        0,
        margin,
        AyreNavMetrics.bottomGap + inset,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AyreNavMetrics.maxWidth),
          child: DecoratedBox(
            // One ambient layer; the shadow sits outside the clip.
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: t.shadowColor.withValues(alpha: dark ? 0.40 : 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(borderRadius: radius, child: surface),
          ),
        ),
      ),
    );
  }
}

class _DockItems extends StatelessWidget {
  const _DockItems({
    required this.selectedIndex,
    required this.onSelected,
    required this.onReselected,
    required this.barHeight,
    required this.labelSize,
    required this.textScale,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int>? onReselected;
  final double barHeight;
  final double labelSize;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final count = kNavDestinations.length;
    final indicator = _indicatorColors(t);

    final labelLine = _labelLineHeight(labelSize, textScale);
    final contentHeight =
        AyreNavMetrics.verticalPadding +
        AyreNavMetrics.capsuleHeight +
        AyreNavMetrics.labelGap +
        labelLine +
        AyreNavMetrics.verticalPadding;
    final top =
        AyreNavMetrics.verticalPadding +
        math.max(0.0, (barHeight - contentHeight) / 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / count;
        final capsuleWidth = math.min(
          AyreNavMetrics.capsuleWidth,
          slotWidth - 4,
        );
        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: SpringValue(
            value: selectedIndex.toDouble(),
            spring: AppSpring.navPill,
            builder: (context, position, _) {
              return Stack(
                children: [
                  Positioned(
                    left: slotWidth * position + (slotWidth - capsuleWidth) / 2,
                    top: top,
                    width: capsuleWidth,
                    height: AyreNavMetrics.capsuleHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: indicator.fill,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: _NavItem(
                            key: navDestinationKey(kNavDestinations[i].label),
                            index: i,
                            destination: kNavDestinations[i],
                            progress: (1 - (position - i).abs()).clamp(
                              0.0,
                              1.0,
                            ),
                            selected: i == selectedIndex,
                            onTap: () => _handleTap(
                              i,
                              selectedIndex,
                              onSelected,
                              onReselected,
                            ),
                            capsuleWidth: capsuleWidth,
                            topPadding: top,
                            height: barHeight,
                            labelSize: labelSize,
                            textScale: textScale,
                            ownCapsule: false,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

double _labelLineHeight(double labelSize, double textScale) =>
    labelSize * math.min(textScale, AyreNavMetrics.labelScaleCap) * 1.15;

void _handleTap(
  int index,
  int selectedIndex,
  ValueChanged<int> onSelected,
  ValueChanged<int>? onReselected,
) {
  if (index == selectedIndex) {
    // A2: a re-tap never plays the selection haptic.
    onReselected?.call(index);
    return;
  }
  HapticFeedback.selectionClick();
  onSelected(index);
}

/// Large-window (at/above [AppBreakpoints.twoColumn]) counterpart to
/// [AyreBottomNav]: the same item, colours, states and semantics, stacked
/// vertically in a scrollable column so landscape phones and large text cannot
/// overflow.
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
    final labelSize = AyreNavMetrics.labelSizeFor(Theme.of(context).platform);
    final scale = media.textScaler.scale(100) / 100;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(right: BorderSide(color: t.hairline)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Column(
              children: [
                for (var i = 0; i < kNavDestinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
                    child: SpringValue(
                      value: i == selectedIndex ? 1.0 : 0.0,
                      spring: AppSpring.navPill,
                      builder: (context, value, _) => _NavItem(
                        key: navDestinationKey(kNavDestinations[i].label),
                        index: i,
                        destination: kNavDestinations[i],
                        progress: value.clamp(0.0, 1.0),
                        selected: i == selectedIndex,
                        onTap: () => _handleTap(
                          i,
                          selectedIndex,
                          onSelected,
                          onReselected,
                        ),
                        capsuleWidth: AyreNavMetrics.capsuleWidth,
                        topPadding: AyreNavMetrics.verticalPadding,
                        height: null,
                        labelSize: labelSize,
                        textScale: scale,
                        ownCapsule: true,
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
    required this.progress,
    required this.selected,
    required this.onTap,
    required this.capsuleWidth,
    required this.topPadding,
    required this.height,
    required this.labelSize,
    required this.textScale,
    required this.ownCapsule,
  });

  final int index;
  final NavDestination destination;

  /// Selection progress 0..1, driven by the parent's spring.
  final double progress;
  final bool selected;
  final VoidCallback onTap;
  final double capsuleWidth;
  final double topPadding;

  /// Fixed height in the dock; `null` in the rail (min height applies).
  final double? height;
  final double labelSize;
  final double textScale;

  /// True where the item draws its own selected capsule (the rail); the dock
  /// draws one sliding capsule behind all items instead.
  final bool ownCapsule;

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final indicator = _indicatorColors(t);
    final p = widget.progress;
    final color = Color.lerp(_unselectedColor(t, dark), indicator.glyph, p)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label = widget.destination.label;
    final radius = BorderRadius.circular(AppRadius.pill);

    // Capsule background: the rail's own selected fill, then press/hover tint
    // for items that are not selected.
    var background = widget.ownCapsule
        ? Color.lerp(const Color(0x00000000), indicator.fill, p)!
        : const Color(0x00000000);
    if (_pressed && p < 0.5) {
      background = Color.alphaBlend(
        indicator.fill.withValues(alpha: 0.5),
        background,
      );
    } else if (_hovered && p < 0.5) {
      background = Color.alphaBlend(
        t.foregroundSubtle.withValues(alpha: 0.08),
        background,
      );
    }

    final labelStyle = AppTypo.navLabel(
      t,
      color: color,
    ).copyWith(fontSize: widget.labelSize, height: 1.15);
    final labelLine = _labelLineHeight(widget.labelSize, widget.textScale);

    final capsule = SizedBox(
      width: widget.capsuleWidth,
      height: AyreNavMetrics.capsuleHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (_focused)
            Positioned(
              left: -3,
              right: -3,
              top: -3,
              bottom: -3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: t.accentInk, width: 2),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: background, borderRadius: radius),
            ),
          ),
          AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: reduceMotion ? Duration.zero : AppMotion.buttonPress,
            curve: AppMotion.ease,
            child: SizedBox(
              width: AyreNavMetrics.glyphSize,
              height: AyreNavMetrics.glyphSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1 - p,
                    child: AyreIcon(
                      widget.destination.glyph,
                      size: AyreNavMetrics.glyphSize,
                      color: color,
                    ),
                  ),
                  Opacity(
                    opacity: p,
                    child: AyreIcon(
                      widget.destination.glyph,
                      size: AyreNavMetrics.glyphSize,
                      filled: true,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Widget content = Padding(
      padding: EdgeInsets.only(
        top: widget.topPadding,
        bottom: AyreNavMetrics.verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          capsule,
          const SizedBox(height: AyreNavMetrics.labelGap),
          // Never ellipsised: the label's scale is capped, then scaled down
          // as a last resort (documented exception to D-9).
          SizedBox(
            height: labelLine,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textScaler: TextScaler.linear(
                    math.min(widget.textScale, AyreNavMetrics.labelScaleCap),
                  ),
                  style: labelStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    content = widget.height != null
        ? SizedBox(
            height: widget.height,
            child: Align(alignment: Alignment.topCenter, child: content),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AyreNavMetrics.railItemMinHeight,
            ),
            child: content,
          );

    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
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
