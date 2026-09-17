import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'spring.dart';

/// A navigation destination. Unlike v3's icon-only bar, the label is now
/// rendered on screen — it is still the accessibility name too, so nothing
/// changes for screen-reader users.
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

/// The always-visible bottom navigation — v4's flat glass pill, replacing
/// v3's raised, protruding, icon-only [CurvedNavBar] outright (Spec §9).
///
/// Every particular of the old bar is reversed here: no protrusion (the bar
/// is a flat plane, full width, flush to the bottom edge — nothing rises
/// above its top edge), icon **and** label on every item at all times, and
/// the active item is never enlarged — only a tonal pill slides in behind it
/// and its glyph switches from line to filled.
///
/// **Glass effect:** [BackdropFilter] blurs whatever scrolls beneath the bar
/// (Flutter's direct equivalent of CSS `backdrop-filter: blur()`), composed
/// with a saturation boost so the blurred content doesn't wash out — CSS's
/// `saturate(150%)` has no built-in Flutter filter, so it is reproduced here
/// as the literal RGB saturation matrix (`ColorFilter.matrix`, composed
/// after the blur via `ImageFilter.compose`) rather than approximated or
/// dropped, resolving plan §7 open decision #2. [AppThemeTokens.navBg] at
/// ~66% alpha sits on top of the filtered content for the tint.
///
/// **Motion:** the pill's position is driven by [SpringValue] on
/// [AppSpring.navPill] (Phase 1's numerically-verified spring, ζ≈0.87,
/// settle≈0.21s, ~0.4% overshoot — "glides smoothly, no bounce"), re-
/// targeting mid-flight from wherever it currently sits rather than
/// restarting, so a fast second tap doesn't cause a visible snap-back.
/// Reduced motion is honored by [SpringValue] itself.
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          // saturate(150%) — the standard CSS saturation matrix at s = 1.5,
          // applied after the blur so the effect reads like the Spec's
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
            color: t.navBg.withValues(alpha: 0.66),
            border: Border(top: BorderSide(color: t.navHairline)),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: barHeight,
            child: _NavPillLayer(
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    );
  }
}

/// The sliding tonal pill and the row of items, layered together so the pill
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
                                // The Spec's "flat tonal pill" — never a
                                // solid fill, always a light wash on the
                                // accent, per the same 12–16% wash
                                // convention used for every other soft
                                // semantic tint in this theme.
                                color: t.accent.withValues(alpha: 0.14),
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
    final color = selected ? t.accentInk : t.foregroundSubtle;

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