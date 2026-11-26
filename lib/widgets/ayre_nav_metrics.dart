import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'responsive.dart';

class NavDestination {
  const NavDestination({required this.label, required this.glyph});

  final String label;
  final AyreGlyph glyph;
}

const kNavDestinations = [
  NavDestination(label: 'Home', glyph: AyreGlyph.home),
  NavDestination(label: 'Reports', glyph: AyreGlyph.report),
  NavDestination(label: 'Learn', glyph: AyreGlyph.learn),
  NavDestination(label: 'Profile', glyph: AyreGlyph.profile),
];

/// Single source of truth for the bottom dock and the navigation rail
/// geometry.
/// The nav itself, scrolling tabs and pushed detail screens all read their
/// clearance from here so the numbers cannot drift.
abstract final class AyreNavMetrics {
  /// Dock height at baseline (no inset, default text scale).
  static const double minHeight = 76;

  /// Padding above the destinations.
  static const double topPadding = 8;

  /// Minimum space below the destination labels.
  static const double minBottomPadding = 16;

  /// Extra air kept between the system inset and the label when an inset
  /// exists.
  static const double insetAir = 8;

  /// Dock horizontal padding.
  static const double horizontalPadding = 8;

  /// Transparent icon slot per destination (55×34, radius 13).
  static const double slotWidth = 55;
  static const double slotHeight = 34;
  static const double slotRadius = 13;

  /// Outline icon size inside the slot.
  static const double glyphSize = 22;

  /// Gap between slot and label.
  static const double labelGap = 5;

  /// Saffron marker: 34×4 on the dock's top edge, skewed −24°.
  static const double markerWidth = 34;
  static const double markerHeight = 4;
  static const double markerSkewDegrees = -24;

  /// Widest the dock gets before it centres ([AppBreakpoints.dockMaxWidth]).
  static const double maxWidth = AppBreakpoints.dockMaxWidth;

  static const double labelPadding = 2;

  /// Navigation rail width and minimum item height.
  static const double railWidth = 80;
  static const double railItemMinHeight = 64;

  static TextStyle labelStyleOf(BuildContext context, {Color? color}) =>
      AppTypo.navLabel(context.tokens, color: color).copyWith(height: 1.15);

  /// True when the rail replaces the dock (at/above the two-column pivot).
  static bool usesRail(double viewportWidth) =>
      viewportWidth >= AppBreakpoints.twoColumn;

  static double dockWidthFor(double viewportWidth) =>
      viewportWidth >= AppBreakpoints.mediumStart
      ? math.min(maxWidth, viewportWidth)
      : viewportWidth;

  static double labelHeightFor(BuildContext context, double slotWidth) {
    final width = math.max(0.0, slotWidth - 2 * labelPadding);
    final style = labelStyleOf(context);
    return kNavDestinations
        .map(
          (entry) => measureText(
            context,
            entry.label,
            style,
            maxWidth: width,
          ).height.ceilToDouble(),
        )
        .reduce(math.max);
  }

  static double dockLabelHeightOf(BuildContext context) {
    final media = MediaQuery.of(context);
    final width =
        dockWidthFor(media.size.width) -
        media.viewPadding.horizontal -
        2 * horizontalPadding;
    return labelHeightFor(context, width / kNavDestinations.length);
  }

  /// Space under the label: the reference breathing room, or the system inset
  /// plus a little air, whichever is larger. The inset is counted once.
  static double bottomPaddingFor(double bottomInset) =>
      math.max(minBottomPadding, bottomInset + insetAir);

  /// Height of the dock including the bottom safe-area inset.
  static double barHeightFor({
    required double labelHeight,
    double bottomInset = 0,
  }) {
    final content =
        topPadding +
        slotHeight +
        labelGap +
        labelHeight +
        bottomPaddingFor(bottomInset);
    return math.max(minHeight, content);
  }

  /// Space a scrolling body must leave at its end so the last row clears the
  /// dock. `0` with the rail.
  ///
  /// [bottomInset] defaults to the system view padding (the physical inset),
  /// not `MediaQuery.padding`, which a `Scaffold` with `extendBody` already
  /// rewrites to include the bar.
  static double clearanceOf(BuildContext context, {double? bottomInset}) {
    final media = MediaQuery.of(context);
    if (usesRail(media.size.width)) return 0;
    return barHeightFor(
      bottomInset: bottomInset ?? media.viewPadding.bottom,
      labelHeight: dockLabelHeightOf(context),
    );
  }
}
