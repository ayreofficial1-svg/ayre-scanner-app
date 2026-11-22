import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'responsive.dart';

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

  /// Label text scale is capped here (single-word labels in a fixed-width
  /// slot); beyond it a `FittedBox(scaleDown)` is the last resort.
  static const double labelScaleCap = 1.3;

  /// Navigation rail width and minimum item height.
  static const double railWidth = 80;
  static const double railItemMinHeight = 64;

  /// Dock label size: 11/700 on every platform.
  static double labelSizeFor(TargetPlatform platform) => AppTextScale.navLabel;

  static double get labelSize => labelSizeFor(defaultTargetPlatform);

  /// True when the rail replaces the dock (at/above the two-column pivot).
  static bool usesRail(double viewportWidth) =>
      viewportWidth >= AppBreakpoints.twoColumn;

  static double labelLineFor(double textScale, double labelSize) =>
      labelSize * math.min(textScale, labelScaleCap) * 1.15;

  /// Space under the label: the reference breathing room, or the system inset
  /// plus a little air, whichever is larger. The inset is counted once.
  static double bottomPaddingFor(double bottomInset) =>
      math.max(minBottomPadding, bottomInset + insetAir);

  /// Height of the dock including the bottom safe-area inset.
  static double barHeightFor({
    required double textScale,
    required double labelSize,
    double bottomInset = 0,
  }) {
    final content =
        topPadding +
        slotHeight +
        labelGap +
        labelLineFor(textScale, labelSize) +
        bottomPaddingFor(bottomInset);
    return math.max(minHeight, content);
  }

  /// Pure clearance: the full dock height (inset included), or 0 with a rail.
  static double clearanceFor({
    required double viewportWidth,
    required double bottomInset,
    required double textScale,
    required double labelSize,
  }) {
    if (usesRail(viewportWidth)) return 0;
    return barHeightFor(
      textScale: textScale,
      labelSize: labelSize,
      bottomInset: bottomInset,
    );
  }

  /// Space a scrolling body must leave at its end so the last row clears the
  /// dock. `0` with the rail.
  ///
  /// [bottomInset] defaults to the system view padding (the physical inset),
  /// not `MediaQuery.padding`, which a `Scaffold` with `extendBody` already
  /// rewrites to include the bar.
  static double clearanceOf(BuildContext context, {double? bottomInset}) {
    final media = MediaQuery.of(context);
    return clearanceFor(
      viewportWidth: media.size.width,
      bottomInset: bottomInset ?? media.viewPadding.bottom,
      textScale: media.textScaler.scale(labelSize) / labelSize,
      labelSize: labelSize,
    );
  }
}
