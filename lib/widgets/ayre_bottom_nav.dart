import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'spring.dart';

/// A navigation destination. The label is rendered on screen (icon + label on
/// every item) and is also the accessibility name, so nothing changes for
/// screen-reader users.
class NavDestination {
  const NavDestination({required this.label, required this.glyph});

  final String label;
  final AyreGlyph glyph;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(label: 'Home', glyph: AyreGlyph.home),
  NavDestination(label: 'Signals', glyph: AyreGlyph.signals),
  NavDestination(label: 'Insights', glyph: AyreGlyph.insights),
  NavDestination(label: 'Learn', glyph: AyreGlyph.learn),
  NavDestination(label: 'Profile', glyph: AyreGlyph.profile),
];

/// A stable handle on a destination, used by tests and by the tooltip/
/// semantics wiring.
Key navDestinationKey(String label) => ValueKey('nav-destination-$label');

/// The always-visible bottom navigation — v5's floating glass pill.
///
/// The bar is a fully rounded pill that floats above the bottom edge with a
/// margin on every side (never flush to the screen edges), carrying a soft
/// [AppThemeTokens.shadowColor] shadow beneath it. Every destination shows an
/// icon **and** a label at all times; the active destination is never
/// enlarged — a solid pill (deep ink in light, brand emerald in dark) slides in
/// behind it and its glyph switches from line to filled.
///
/// **Glass effect:** [BackdropFilter] blurs whatever scrolls beneath the bar
/// (Flutter's direct equivalent of CSS `backdrop-filter: blur()`), composed
/// with a saturation boost so the blurred content doesn't wash out — CSS's
/// `saturate(150%)` has no built-in Flutter filter, so it is reproduced here
/// as the literal RGB saturation matrix (`ColorFilter.matrix`, composed
/// after the blur via `ImageFilter.compose`). [AppThemeTokens.navBg] sits on
/// top of the filtered content for the tint, at ~90% alpha in light and ~85%
/// in dark (the dark canvas needs slightly more see-through to still read as
/// glass rather than a solid slab).
///
/// **Motion:** the pill's position is driven by [SpringValue] on
/// [AppSpring.navPill] (numerically verified: ζ≈0.87, settle≈0.21s, ~0.4%
/// overshoot — "glides smoothly, no bounce"), re-targeting mid-flight from
/// wherever it currently sits rather than restarting, so a fast second tap
/// doesn't cause a visible snap-back. Reduced motion is honored by
/// [SpringValue] itself.
class AyreBottomNav extends StatelessWidget {
  const AyreBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Height of the bar's content, excluding the safe-area inset added below
  /// it. Generous enough that icon (22) + gap + label (10, per
  /// [AppTextScale.navLabel]) clear the 48pt touch-target floor vertically
  /// once padding is added.
  static const double barHeight = 64;

  /// Gap between the floating pill and the screen's left/right/bottom edges.
  static const double edgeMargin = 12;

  /// Total vertical space the nav occupies (pill + its bottom margin), for
  /// screens that need to pad their scroll content clear of it. The safe-area
  /// inset is added separately by the caller, as before.
  static const double occupiedHeight = barHeight + edgeMargin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadius.pill);

    // The outer padding is what makes the bar float: transparent margin on
    // the left, right and bottom, with the safe-area inset added beneath it.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        edgeMargin,
        0,
        edgeMargin,
        edgeMargin + bottomInset,
      ),
      child: DecoratedBox(
        // The shadow lives on a DecoratedBox *outside* the ClipRRect: a clip
        // would otherwise cut it off at the pill's own edge. `shadowColor` is
        // a muted sage-gray in light and pure black in dark (per the token's
        // docs).
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: t.shadowColor.withValues(alpha: isDark ? 0.45 : 0.30),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: t.shadowColor.withValues(alpha: isDark ? 0.30 : 0.16),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.compose(
              outer: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              // saturate(150%) — the standard CSS saturation matrix at
              // s = 1.5, applied after the blur so the effect reads like
              // "frosted, slightly vivid" glass rather than a flat gray smear.
              inner: const ColorFilter.matrix(<double>[
                1.3935, -0.3575, -0.036, 0, 0,
                -0.1065, 1.1425, -0.036, 0, 0,
                -0.1065, -0.3575, 1.464, 0, 0,
                0, 0, 0, 1, 0,
              ]),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: t.navBg.withValues(alpha: isDark ? 0.85 : 0.90),
                borderRadius: radius,
                // A full-perimeter hairline, not a top-edge-only rule: a
                // floating pill has no "top edge" to underline, it needs its
                // whole silhouette defined against the page behind it.
                border: Border.all(color: t.navHairline),
              ),
              child: SizedBox(
                height: barHeight,
                child: _NavPillLayer(
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Active-pill fill (§2A "Bottom nav" rows): the deep ink `textPrimary` in
/// light, the brand `accent` in dark. Resolved here from the ambient
/// brightness rather than as a new [AppThemeTokens] field — the token set is
/// fixed (Phase 0), and this pairing is specific to this one component.
Color _activePillColor(AppThemeTokens t, BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? t.accent : t.textPrimary;

/// Active tab icon + label: white on the light theme's ink pill, `onAccent`
/// on the dark theme's emerald pill.
Color _activeContentColor(AppThemeTokens t, BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? t.onAccent
    : const Color(0xFFFFFFFF);

/// Inactive tab icon + label. Light uses the spec's own muted gray
/// (`#8B948E`, a touch lighter than `foregroundSubtle` so inactive items
/// recede against the white bar); dark reuses `foregroundMuted`.
Color _inactiveContentColor(AppThemeTokens t, BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? t.foregroundMuted
    : const Color(0xFF8B948E);

/// The sliding solid pill and the row of items, layered together so the pill
/// paints once beneath the (non-animating) item row.
class _NavPillLayer extends StatelessWidget {
  const _NavPillLayer({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _pillHorizontalInset = 6;
  static const double _pillVerticalInset = 8;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final count = kNavDestinations.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / count;
        return Stack(
          children: [
            Positioned.fill(
              child: SpringValue(
                value: selectedIndex.toDouble(),
                spring: AppSpring.navPill,
                builder: (context, position, _) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: _pillVerticalInset,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Transform.translate(
                        offset: Offset(slotWidth * position, 0),
                        child: SizedBox(
                          width: slotWidth,
                          height:
                              AyreBottomNav.barHeight - _pillVerticalInset * 2,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _pillHorizontalInset,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                // A solid pill, never a wash: the deep
                                // forest-green ink (= `textPrimary`) in
                                // light, the brand emerald (`accent`) in
                                // dark — the one place the nav carries the
                                // brand at full strength.
                                color: _activePillColor(t, context),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: _NavItem(
                      key: navDestinationKey(kNavDestinations[i].label),
                      destination: kNavDestinations[i],
                      selected: i == selectedIndex,
                      onTap: () {
                        if (i == selectedIndex) return;
                        HapticFeedback.selectionClick();
                        onSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Large-screen (≥[AppBreakpoints.twoColumn]) counterpart to [AyreBottomNav]
/// (Phase 2B). Same [kNavDestinations]/[NavDestination]/[navDestinationKey]
/// data, same [AppThemeTokens] palette, so a tablet/desktop window reads as
/// the same product rather than falling back to stock Material
/// `NavigationRail` colors. `HomeShell` swaps this in for the floating pill
/// above the pivot width; nothing about tab state (`IndexedStack`,
/// `TickerMode`) changes — only the nav chrome.
class AyreNavRail extends StatelessWidget {
  const AyreNavRail({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double width = 88;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(right: BorderSide(color: t.hairline)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpace.lg),
            for (var i = 0; i < kNavDestinations.length; i++)
              _RailItem(
                key: navDestinationKey(kNavDestinations[i].label),
                destination: kNavDestinations[i],
                selected: i == selectedIndex,
                onTap: () {
                  if (i == selectedIndex) return;
                  HapticFeedback.selectionClick();
                  onSelected(i);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One [AyreNavRail] destination: icon above label, stacked, at least
/// [AppSpace.minTarget] tall — the same touch-target floor every other
/// interactive row in the app enforces. The selected item takes the same
/// pill treatment as the bottom nav's active item, just laid out vertically,
/// and the same [_NavTransition] emphasis motion as [_NavItem] so the rail
/// and the floating bar read as one animation language.
class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final activeColor = _activeContentColor(t, context);
    final inactiveColor = _inactiveContentColor(t, context);
    final pill = _activePillColor(t, context);

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: _NavPressScale(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xxs,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: _NavTransition(
              selected: selected,
              builder: (context, p, bump, color) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    // The pill itself fades in/out with `p` too, rather than
                    // snapping — the rail's one departure from the bottom
                    // bar's *sliding* pill, since a vertical rail has no
                    // shared track for it to glide along.
                    color: Color.lerp(Colors.transparent, pill, p),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavIconMorph(
                        glyph: destination.glyph,
                        p: p,
                        bump: bump,
                        color: color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destination.label,
                        style: AppTypo.navLabel(t, color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// One destination's icon, label and tap target. The item's own box never
/// enlarges or shifts on selection — that stays the fixed backdrop the
/// sliding pill in [_NavPillLayer] moves against — but the icon and label
/// *within* it now carry [_NavTransition]'s emphasis motion: a brief pop and
/// lift as the glyph crosses from outline to filled, mirrored on the way
/// back down when another tab takes over. See [_NavTransition] for the
/// motion's shape and rationale.
class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final activeColor = _activeContentColor(t, context);
    final inactiveColor = _inactiveContentColor(t, context);

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        preferBelow: false,
        child: _NavPressScale(
          onTap: onTap,
          child: SizedBox(
            height: AyreBottomNav.barHeight,
            child: _NavTransition(
              selected: selected,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              builder: (context, p, bump, color) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavIconMorph(
                      glyph: destination.glyph,
                      p: p,
                      bump: bump,
                      color: color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.label,
                      style: AppTypo.navLabel(t, color: color),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Drives one nav item's selection emphasis on [AppSpring.navPill] — the
/// same spring [_NavPillLayer] slides the background pill on, so an icon's
/// pop and the pill's glide arrive together rather than reading as two
/// unrelated animations.
///
/// [builder] receives:
///  - `p`: selection progress, clamped to 0–1 (0 = fully inactive, 1 = fully
///    active). Drives color and the icon's line↔fill crossfade.
///  - `bump`: a parabola of `p` (`4·p·(1-p)`) that is *zero at both rest
///    states* and peaks mid-transition. This is what gives the icon a
///    transient pop/lift exactly while it is changing state, in either
///    direction, without ever leaving it visually enlarged at rest — keeping
///    faith with the "never enlarge the item" rule while still giving the
///    change itself some weight, per the reference's "how it becomes active
///    ... and how it returns to normal" brief.
///  - `color`: inactive→active color already interpolated by `p`, so callers
///    never lerp it themselves.
class _NavTransition extends StatelessWidget {
  const _NavTransition({
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.builder,
  });

  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Widget Function(
    BuildContext context,
    double p,
    double bump,
    Color color,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return SpringValue(
      value: selected ? 1.0 : 0.0,
      spring: AppSpring.navPill,
      builder: (context, raw, _) {
        final p = raw.clamp(0.0, 1.0);
        final bump = 4 * p * (1 - p);
        final color = Color.lerp(inactiveColor, activeColor, p)!;
        return builder(context, p, bump, color);
      },
    );
  }
}

/// The glyph itself: crossfades outline→filled as `p` runs 0→1 (a soft
/// weight change rather than a hard swap) and rides [bump] into a small pop
/// (scale) and lift (translateY), both zero at rest. Two stacked [AyreIcon]s
/// rather than one continuously-morphing painter — [AyreIcon]'s glyphs are
/// hand-drawn per state, not parameterized by fill fraction, so a dissolve
/// between the two fixed drawings is the low-risk way to get a soft
/// transition out of the existing icon set.
class _NavIconMorph extends StatelessWidget {
  const _NavIconMorph({
    required this.glyph,
    required this.p,
    required this.bump,
    required this.color,
  });

  final AyreGlyph glyph;
  final double p;
  final double bump;
  final Color color;

  /// Fixed at the one size every nav item actually uses — [AyreBottomNav]
  /// and [AyreNavRail] both call this without overriding it, so a
  /// configurable `size` parameter was dead weight the analyzer flagged
  /// (`unused_element_parameter`). Reintroduce it as a constructor field if
  /// a second call site ever needs a different size.
  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -bump * 1.6),
      child: Transform.scale(
        scale: 1 + bump * 0.12,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - p,
                child: AyreIcon(glyph, size: _size, filled: false, color: color),
              ),
              Opacity(
                opacity: p,
                child: AyreIcon(glyph, size: _size, filled: true, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a nav tap target with a small press-down scale — the tactile cue
/// that the row itself responds to touch, independent of (and a beat ahead
/// of) the selection change [_NavTransition] plays once the tap commits.
/// Snaps instead of animating under reduced motion, matching [SpringValue]'s
/// own reduced-motion behavior elsewhere in this file.
///
/// Deliberately not the shared `PressableScale` (widgets/pressable_scale.dart):
/// that one clips to a rounded card and shows an ink splash, which reads fine
/// on a standalone card but would visibly bleed across neighboring items
/// inside the nav's single shared glass pill, which has no per-item clip
/// boundary of its own. This is scale-only, no splash, so it stays this
/// component's private helper rather than a variant bolted onto the shared
/// one.
class _NavPressScale extends StatefulWidget {
  const _NavPressScale({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_NavPressScale> createState() => _NavPressScaleState();
}

class _NavPressScaleState extends State<_NavPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: reduceMotion ? Duration.zero : AppMotion.buttonPress,
        curve: AppMotion.ease,
        child: widget.child,
      ),
    );
  }
}