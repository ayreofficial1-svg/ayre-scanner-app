import 'package:flutter/material.dart';

Size measureText(
  BuildContext context,
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
  int? maxLines,
}) {
  final defaults = DefaultTextStyle.of(context);
  final effectiveStyle = style.inherit ? defaults.style.merge(style) : style;
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: MediaQuery.boldTextOf(context)
          ? effectiveStyle.copyWith(fontWeight: FontWeight.bold)
          : effectiveStyle,
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    textHeightBehavior: defaults.textHeightBehavior,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  final size = painter.size;
  painter.dispose();
  return size;
}

double singleLineTextWidth(
  BuildContext context,
  String text,
  TextStyle style,
) => measureText(context, text, style, maxLines: 1).width.ceilToDouble();

/// Keep previews the same length as text grows and wraps onto more lines.
String textPreview(String text, {required int words}) {
  final matches = RegExp(r'\S+').allMatches(text).take(words + 1).toList();
  if (matches.length <= words) return text;
  return '${text.substring(0, matches.last.start).trimRight()}…';
}

/// Material window size classes (Spec §13.2). Additive: the 720/1120 pivots
/// below are test-locked and unchanged.
enum AppWindowClass { compact, medium, expanded }

/// The only breakpoints in the system — everything adaptive keys off these so
/// behaviour stays predictable across screens.
abstract final class AppBreakpoints {
  /// At and above this, list-shaped screens go two-column and the bottom dock
  /// is replaced by the navigation rail. 600–719 pt is served by the
  /// max-width ([dockMaxWidth]) dock.
  static const double twoColumn = 720;

  /// Window class boundaries (compact < 600, medium 600–839, expanded ≥ 840).
  static const double mediumStart = 600;
  static const double expandedStart = 840;

  static AppWindowClass windowClassOf(BuildContext context) {
    final w = _width(context);
    if (w >= expandedStart) return AppWindowClass.expanded;
    if (w >= mediumStart) return AppWindowClass.medium;
    return AppWindowClass.compact;
  }

  /// At and above this, three-column is worth it for card grids.
  static const double threeColumn = 1120;

  /// A comfortable reading measure for single-column content.
  static const double contentMaxWidth = 620;

  /// Widest the Fold's expanded dock is allowed to get before it centres.
  static const double dockMaxWidth = 480;

  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Column count for list/card grids.
  ///
  /// Previously this excluded the widest tier, which meant desktop windows fell
  /// back to a single column — the opposite of the intent. Wider always means
  /// the same or more columns, never fewer.
  static int columns(BuildContext context) {
    final w = _width(context);
    if (w >= threeColumn) return 3;
    if (w >= twoColumn) return 2;
    return 1;
  }

  static bool isCompact(BuildContext context) => _width(context) < 380;

  /// True only where a pointer is actually present, so hover affordances appear
  /// only when they can be used.
  static bool hasPointer(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }
}
