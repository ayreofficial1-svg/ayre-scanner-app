import 'package:flutter/material.dart';

/// The repository ships macOS, Windows, Linux and Web targets alongside mobile.
/// These are the only breakpoints in the system — everything adaptive keys off
/// them so behaviour stays predictable across screens.
abstract final class AppBreakpoints {
  /// Above this, the bottom nav becomes a left-side vertical rail (§5.4).
  static const double rail = 900;

  /// Above this, list-shaped tabs (Signals, Learn) may go two-column.
  /// Insights and Home stay single-column at every width — both read as a
  /// linear narrative a grid would break apart.
  static const double twoColumn = 760;

  /// Above this the nav bar stops stretching and centres at a capped width.
  static const double navCap = 620;

  /// A comfortable reading measure for scrollable content.
  static const double contentMaxWidth = 560;

  /// Widest the floating nav bar is allowed to get before it centres.
  static const double navMaxWidth = 560;

  static double _width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool usesRail(BuildContext context) => _width(context) >= rail;

  static bool usesTwoColumn(BuildContext context) =>
      _width(context) >= twoColumn && !usesRail(context);

  /// True where a pointer is actually present, so hover affordances only
  /// appear when they can be used.
  static bool hasPointer(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }
}
