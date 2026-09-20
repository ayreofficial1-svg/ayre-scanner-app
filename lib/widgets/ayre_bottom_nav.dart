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

/// One destination's icon, label and tap target. Never enlarges or shifts on
/// selection — only the icon's fill state and both elements' color change,
/// per the Spec's "never enlarge the item" rule for this control.
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
    final color = selected
        ? _activeContentColor(t, context)
        : _inactiveContentColor(t, context);

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        preferBelow: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: AyreBottomNav.barHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AyreIcon(
                  destination.glyph,
                  size: 22,
                  filled: selected,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  destination.label,
                  style: AppTypo.navLabel(t, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}