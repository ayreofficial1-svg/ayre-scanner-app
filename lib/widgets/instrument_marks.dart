import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The engraved line-work vocabulary that replaces every soft glow, blob and
/// gradient sweep in the app. Everything here is flat and hairline — nothing
/// is blurred, and nothing is a gradient wash.
///
/// Usage rule: at most one ornament per screen, on the single most prominent
/// hero surface. Home's hero carries one; Signals and Learn carry none; Login
/// and Splash share the bearing mark.

/// Short parallel hairlines, evoking a dial's calibration ticks. Used as a
/// restrained edge treatment on hero cards, section dividers and the nav bar's
/// top edge.
class TickMarks extends StatelessWidget {
  const TickMarks({
    super.key,
    required this.color,
    this.axis = Axis.horizontal,
    this.count = 24,
    this.length = 6,
    this.majorEvery = 4,
    this.majorLength = 10,
    this.thickness = 1,
    this.alignEnd = false,
  });

  final Color color;
  final Axis axis;
  final int count;

  /// Length of a minor tick, measured perpendicular to [axis].
  final double length;

  /// Every nth tick is drawn at [majorLength]. Set to 0 for uniform ticks.
  final int majorEvery;
  final double majorLength;
  final double thickness;

  /// Draw ticks from the far edge inward instead of the near edge.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TickMarksPainter(
        color: color,
        axis: axis,
        count: count,
        length: length,
        majorEvery: majorEvery,
        majorLength: majorLength,
        thickness: thickness,
        alignEnd: alignEnd,
      ),
    );
  }
}

class _TickMarksPainter extends CustomPainter {
  const _TickMarksPainter({
    required this.color,
    required this.axis,
    required this.count,
    required this.length,
    required this.majorEvery,
    required this.majorLength,
    required this.thickness,
    required this.alignEnd,
  });

  final Color color;
  final Axis axis;
  final int count;
  final double length;
  final int majorEvery;
  final double majorLength;
  final double thickness;
  final bool alignEnd;

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square;

    final span = axis == Axis.horizontal ? size.width : size.height;
    final step = span / (count - 1);

    for (var i = 0; i < count; i++) {
      final isMajor = majorEvery > 0 && i % majorEvery == 0;
      final len = isMajor ? majorLength : length;
      final at = i * step;
      if (axis == Axis.horizontal) {
        final from = alignEnd ? size.height : 0.0;
        final to = alignEnd ? size.height - len : len;
        canvas.drawLine(Offset(at, from), Offset(at, to), paint);
      } else {
        final from = alignEnd ? size.width : 0.0;
        final to = alignEnd ? size.width - len : len;
        canvas.drawLine(Offset(from, at), Offset(to, at), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TickMarksPainter old) {
    return old.color != color ||
        old.axis != axis ||
        old.count != count ||
        old.length != length ||
        old.majorEvery != majorEvery ||
        old.majorLength != majorLength ||
        old.thickness != thickness ||
        old.alignEnd != alignEnd;
  }
}

/// Thin, gently-curved parallel hairlines — isobar/depth-contour in spirit.
/// Background texture for at most one hero surface per screen.
class ContourLines extends StatelessWidget {
  const ContourLines({
    super.key,
    required this.color,
    this.lines = 7,
    this.thickness = 1,
  });

  final Color color;
  final int lines;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ContourPainter(
        color: color,
        lines: lines,
        thickness: thickness,
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  const _ContourPainter({
    required this.color,
    required this.lines,
    required this.thickness,
  });

  final Color color;
  final int lines;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    // Nested, slowly-flattening arcs — a depth chart, not a decorative swirl.
    for (var i = 0; i < lines; i++) {
      final t = i / math.max(1, lines - 1);
      final y = size.height * (0.34 + t * 0.62);
      final depth = size.height * (0.20 - t * 0.11);
      final path = Path()
        ..moveTo(-size.width * 0.08, y)
        ..cubicTo(
          size.width * 0.26,
          y - depth,
          size.width * 0.68,
          y + depth * 0.55,
          size.width * 1.08,
          y - depth * 0.25,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourPainter old) {
    return old.color != color ||
        old.lines != lines ||
        old.thickness != thickness;
  }
}

/// Ayre's brand mark: a fine circular bearing ring with calibration ticks and
/// a single index needle. Replaces the radar-sweep motif and the rotating
/// gradient ring. Where movement is warranted (Splash), the needle rotates
/// slowly — critically damped, no overshoot — instead of a gradient wash.
class BearingMark extends StatelessWidget {
  const BearingMark({
    super.key,
    required this.color,
    this.size = 160,
    this.needleAngle = -math.pi / 2,
    this.needleColor,
    this.showNeedle = true,
  });

  final Color color;
  final double size;

  /// Needle bearing in radians, measured clockwise from straight up.
  final double needleAngle;
  final Color? needleColor;
  final bool showNeedle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BearingPainter(
          color: color,
          needleAngle: needleAngle,
          needleColor: needleColor ?? color,
          showNeedle: showNeedle,
        ),
      ),
    );
  }
}

class _BearingPainter extends CustomPainter {
  const _BearingPainter({
    required this.color,
    required this.needleAngle,
    required this.needleColor,
    required this.showNeedle,
  });

  final Color color;
  final double needleAngle;
  final Color needleColor;
  final bool showNeedle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;

    final hairline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, r - 1, hairline);
    canvas.drawCircle(center, r * 0.72, hairline);

    // Calibration ticks around the outer ring; cardinals run longer.
    const ticks = 32;
    for (var i = 0; i < ticks; i++) {
      final a = (i / ticks) * math.pi * 2 - math.pi / 2;
      final isCardinal = i % 8 == 0;
      final inner = r * (isCardinal ? 0.80 : 0.90);
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * (r - 1), math.sin(a) * (r - 1)),
        hairline..strokeWidth = isCardinal ? 1.4 : 1,
      );
    }

    if (!showNeedle) return;

    final a = needleAngle - math.pi / 2;
    final needle = Paint()
      ..color = needleColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      center - Offset(math.cos(a) * r * 0.16, math.sin(a) * r * 0.16),
      center + Offset(math.cos(a) * r * 0.66, math.sin(a) * r * 0.66),
      needle,
    );
    canvas.drawCircle(center, 2.4, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _BearingPainter old) {
    return old.color != color ||
        old.needleAngle != needleAngle ||
        old.needleColor != needleColor ||
        old.showNeedle != showNeedle;
  }
}

/// A chamfered container border: a single flat cut across the chosen corners.
/// The shape system's second, controlled voice, reserved for instrument-coded
/// elements (section-header accent marks, the gauge's dial housing). Cards and
/// general containers keep the smaller rounded-corner treatment; a screen
/// never uses more than these two voices at once.
class ChamferedBorder extends OutlinedBorder {
  const ChamferedBorder({
    super.side = BorderSide.none,
    this.cut = AppRadius.chamfer,
    this.corners = const {ChamferCorner.topRight, ChamferCorner.bottomLeft},
  });

  final double cut;
  final Set<ChamferCorner> corners;

  @override
  ShapeBorder scale(double t) =>
      ChamferedBorder(side: side.scale(t), cut: cut * t, corners: corners);

  @override
  ChamferedBorder copyWith({BorderSide? side, double? cut}) => ChamferedBorder(
    side: side ?? this.side,
    cut: cut ?? this.cut,
    corners: corners,
  );

  Path _build(Rect rect, double inset) {
    final r = rect.deflate(inset);
    final c = math.min(cut, math.min(r.width, r.height) / 2);
    final path = Path();

    if (corners.contains(ChamferCorner.topLeft)) {
      path.moveTo(r.left, r.top + c);
      path.lineTo(r.left + c, r.top);
    } else {
      path.moveTo(r.left, r.top);
    }

    if (corners.contains(ChamferCorner.topRight)) {
      path.lineTo(r.right - c, r.top);
      path.lineTo(r.right, r.top + c);
    } else {
      path.lineTo(r.right, r.top);
    }

    if (corners.contains(ChamferCorner.bottomRight)) {
      path.lineTo(r.right, r.bottom - c);
      path.lineTo(r.right - c, r.bottom);
    } else {
      path.lineTo(r.right, r.bottom);
    }

    if (corners.contains(ChamferCorner.bottomLeft)) {
      path.lineTo(r.left + c, r.bottom);
      path.lineTo(r.left, r.bottom - c);
    } else {
      path.lineTo(r.left, r.bottom);
    }

    return path..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _build(rect, side.strokeInset);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _build(rect, 0);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      _build(rect, side.strokeOffset / 2),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChamferedBorder &&
      other.side == side &&
      other.cut == cut &&
      setEquals(other.corners, corners);

  @override
  int get hashCode => Object.hash(side, cut, Object.hashAllUnordered(corners));
}

/// The corners a [ChamferedBorder] may cut.
enum ChamferCorner { topLeft, topRight, bottomRight, bottomLeft }
