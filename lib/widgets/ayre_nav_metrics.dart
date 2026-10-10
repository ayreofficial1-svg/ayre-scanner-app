import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'responsive.dart';

/// Shared geometry for the floating bottom dock and the navigation rail
/// (plan §3.3). Everything that needs to know how much room the dock takes —
/// the nav itself, scrolling tabs, detail screens — reads it from here so the
/// numbers cannot drift.
abstract final class AyreNavMetrics {
  /// Dock horizontal margin for viewports ≥ [narrowViewport].
  static const double margin = 16;

  /// Dock horizontal margin below [narrowViewport].
  static const double marginNarrow = 12;

  /// Viewport width below which [marginNarrow] applies.
  static const double narrowViewport = 360;

  /// Gap between the dock and the bottom safe-area inset.
  static const double bottomGap = 12;

  /// Widest the dock gets before it centres ([AppBreakpoints.dockMaxWidth]).
  static const double maxWidth = AppBreakpoints.dockMaxWidth;

  /// Minimum dock height.
  static const double minHeight = 68;

  /// Selected-state indicator capsule.
  static const double capsuleWidth = 56;
  static const double capsuleHeight = 32;
  static const double glyphSize = 24;

  /// Gap between capsule and label.
  static const double labelGap = 4;

  /// Vertical padding above the capsule and below the label.
  static const double verticalPadding = 8;

  /// Label text scale is capped here (single-word labels in a fixed-width
  /// slot); beyond it a `FittedBox(scaleDown)` is the last resort.
  static const double labelScaleCap = 1.3;

  /// Navigation rail width.
  static const double railWidth = 80;

  /// Minimum rail item height.
  static const double railItemMinHeight = 64;

  /// Label size: 11 on iOS/macOS (Apple's minimum), 12 elsewhere.
  static double labelSizeFor(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS ||
    TargetPlatform.macOS => AppTextScale.navLabelApple,
    _ => AppTextScale.navLabel,
  };

  static double get labelSize => labelSizeFor(defaultTargetPlatform);

  static double marginFor(double viewportWidth) =>
      viewportWidth < narrowViewport ? marginNarrow : margin;

  /// True when the rail replaces the dock (at/above the two-column pivot).
  static bool usesRail(double viewportWidth) =>
      viewportWidth >= AppBreakpoints.twoColumn;

  /// Height of the dock's content-driven bar for a given OS/app text scale.
  static double barHeightFor({
    required double textScale,
    required double labelSize,
  }) {
    final labelLine = labelSize * math.min(textScale, labelScaleCap) * 1.15;
    return math.max(
      minHeight,
      verticalPadding + capsuleHeight + labelGap + labelLine + verticalPadding,
    );
  }

  /// Pure clearance calculation: bar height + bottom gap + safe inset, or 0
  /// when a rail is shown.
  static double clearanceFor({
    required double viewportWidth,
    required double bottomInset,
    required double textScale,
    required double labelSize,
  }) {
    if (usesRail(viewportWidth)) return 0;
    return barHeightFor(textScale: textScale, labelSize: labelSize) +
        bottomGap +
        bottomInset;
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
      textScale: media.textScaler.scale(100) / 100,
      labelSize: labelSize,
    );
  }
}
