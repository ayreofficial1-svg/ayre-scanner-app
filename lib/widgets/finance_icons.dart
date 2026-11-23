import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Investee icon vocabulary on a 24-unit grid, with the supplied artwork
/// and additional glyphs for existing controls.
enum FinanceGlyph {
  home,
  reports,
  learn,
  profile,
  bell,
  moon,
  sun,
  chevron,
  back,
  sliders,
  help,
  info,
  pulse,
  shield,
  lock,
  mail,
  trash,
  refresh,
  trend,
  check,
  eye,
  eyeOff,
  edit,
  document,
}

/// Renders a [FinanceGlyph]. Colour defaults to the ambient [IconTheme];
/// pass an explicit semantic colour on every new surface.
class FinanceIcon extends StatelessWidget {
  const FinanceIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.75,
    this.semanticLabel,
    this.quarterTurns = 0,
    this.filled = false,
  });

  final FinanceGlyph glyph;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  /// Clockwise quarter turns, e.g. a right-pointing chevron rotated to point
  /// down (1), left (2) or up (3).
  final int quarterTurns;

  /// Uses the solid variant of the bell.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFF124B32);
    Widget icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FinanceIconPainter(
          glyph: glyph,
          color: resolved,
          strokeWidth: strokeWidth,
          filled: filled,
        ),
      ),
    );
    if (quarterTurns % 4 != 0) {
      icon = RotatedBox(quarterTurns: quarterTurns, child: icon);
    }
    if (semanticLabel == null) return ExcludeSemantics(child: icon);
    return Semantics(label: semanticLabel, image: true, child: icon);
  }
}

class _FinanceIconPainter extends CustomPainter {
  const _FinanceIconPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
    required this.filled,
  });

  final FinanceGlyph glyph;
  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.shortestSide / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..strokeMiterLimit = 4
      ..isAntiAlias = true;

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

    void poly(List<double> points, {bool close = false}) {
      final path = Path()..moveTo(points[0], points[1]);
      for (var i = 2; i < points.length; i += 2) {
        path.lineTo(points[i], points[i + 1]);
      }
      if (close) path.close();
      canvas.drawPath(path, paint);
    }

    void rect(double x, double y, double w, double h) =>
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    void circle(double cx, double cy, double r) =>
        canvas.drawCircle(Offset(cx, cy), r, paint);
    void bezier(void Function(Path) build) {
      final path = Path();
      build(path);
      canvas.drawPath(path, paint);
    }

    switch (glyph) {
      case FinanceGlyph.home:
        // Door is an upward squared U cut into the house's lower wall.
        poly([
          3,
          10.0,
          12,
          3.0,
          21,
          10.0,
          21,
          21,
          14.7,
          21,
          14.7,
          15.1,
          9.3,
          15.1,
          9.3,
          21,
          3,
          21,
        ], close: true);
      case FinanceGlyph.reports:
        rect(2.7, 14.6, 4.2, 6.4);
        rect(9.9, 9.8, 4.2, 11.2);
        rect(17.1, 4.1, 4.2, 16.9);
      case FinanceGlyph.learn:
        // Folded book has an angular central crease.
        poly([
          2,
          5,
          8.8,
          5,
          12,
          7,
          15.2,
          5,
          22,
          5,
          22,
          18.6,
          15.5,
          18.6,
          12,
          21,
          8.5,
          18.6,
          2,
          18.6,
        ], close: true);
        line(12, 7, 12, 21);
      case FinanceGlyph.profile:
        circle(12, 7.5, 4.4);
        bezier((p) {
          p.moveTo(9, 13);
          p.lineTo(4.3, 15.5);
          p.lineTo(2.6, 18.2);
          p.lineTo(2.6, 21);
          p.lineTo(21.4, 21);
          p.lineTo(21.4, 18.2);
          p.lineTo(19.7, 15.5);
          p.lineTo(15, 13);
        });
      case FinanceGlyph.bell:
        // Flared base, flat bottom, and a rectangular clapper.
        if (filled) paint.style = PaintingStyle.fill;
        bezier((p) {
          p.moveTo(4.7, 17.7);
          p.lineTo(5.8, 15.6);
          p.lineTo(6.1, 9.2);
          p.cubicTo(6.1, 5.4, 8.6, 3.5, 12, 3.5);
          p.cubicTo(15.4, 3.5, 17.9, 5.4, 17.9, 9.2);
          p.lineTo(18.2, 15.6);
          p.lineTo(19.3, 17.7);
          p.close();
        });
        rect(10.7, 17.7, 2.6, 2.3);
        paint.style = PaintingStyle.stroke;
        line(12, 2.2, 12, 3.4);
      case FinanceGlyph.moon:
        // Pointed crescent, matching the intentional sharp ends.
        bezier((p) {
          p.moveTo(16.2, 2.8);
          p.cubicTo(9.5, 3.0, 5.1, 7.4, 5.1, 13.2);
          p.cubicTo(5.1, 18.2, 8.8, 21.1, 13.1, 21.1);
          p.cubicTo(16.0, 21.1, 18.5, 20.0, 20.5, 17.8);
          p.cubicTo(13.3, 19.4, 9.1, 14.2, 11.0, 8.0);
          p.cubicTo(11.5, 5.9, 13.1, 4.1, 16.2, 2.8);
          p.close();
        });
      case FinanceGlyph.sun:
        // Octagonal center with eight rays.
        poly([
          9.4,
          7.2,
          14.6,
          7.2,
          16.8,
          9.4,
          16.8,
          14.6,
          14.6,
          16.8,
          9.4,
          16.8,
          7.2,
          14.6,
          7.2,
          9.4,
        ], close: true);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final dx = math.sin(angle);
          final dy = -math.cos(angle);
          line(12 + dx * 9, 12 + dy * 9, 12 + dx * 11, 12 + dy * 11);
        }

      case FinanceGlyph.chevron:
        poly([8.3, 4, 16.3, 12, 8.3, 20]);
      case FinanceGlyph.back:
        poly([10, 4.5, 2.5, 12, 10, 19.5]);
        line(3, 12, 21, 12);
      case FinanceGlyph.sliders:
        line(3, 8, 6, 8);
        rect(6, 5.9, 3.8, 4.2);
        line(9.8, 8, 21, 8);
        line(3, 16.2, 13.1, 16.2);
        rect(13.1, 14.1, 3.8, 4.2);
        line(16.9, 16.2, 21, 16.2);
      case FinanceGlyph.help:
        circle(12, 12, 9.0);
        poly([
          9,
          9.1,
          9,
          7.7,
          10.3,
          6.6,
          13.6,
          6.6,
          15,
          8,
          15,
          10.4,
          12,
          13.3,
          12,
          15,
        ]);
        line(12, 18.1, 12, 18.3);
      case FinanceGlyph.info:
        circle(12, 12, 9.0);
        line(12, 10.5, 12, 17.8);
        line(12, 6.4, 12, 6.6);
      case FinanceGlyph.pulse:
        poly([
          2,
          12.5,
          7,
          12.5,
          9.5,
          6.4,
          13.1,
          18.4,
          16.1,
          10.0,
          18,
          12.5,
          22,
          12.5,
        ]);
      case FinanceGlyph.shield:
        bezier((p) {
          p.moveTo(12, 2.8);
          p.lineTo(20, 5.8);
          p.lineTo(20, 13.8);
          p.cubicTo(20, 16.8, 16.2, 19.7, 12, 22);
          p.cubicTo(7.8, 19.7, 4, 16.8, 4, 13.8);
          p.lineTo(4, 5.8);
          p.close();
        });

      case FinanceGlyph.lock:
        // Round shackle but square-sided body, as pictured.
        bezier((p) {
          p.moveTo(7.2, 10);
          p.lineTo(7.2, 7);
          p.cubicTo(7.2, 0.9, 16.8, 0.9, 16.8, 7);
          p.lineTo(16.8, 10);
        });
        rect(4.1, 10, 15.8, 11.7);
        line(12, 15.1, 12, 18.0);
      case FinanceGlyph.mail:
        rect(2.5, 5.2, 19, 13.6);
        poly([2.7, 6, 12, 13.4, 21.3, 6]);
      case FinanceGlyph.trash:
        poly([4.8, 7, 19.2, 7]);
        rect(9, 3.2, 6, 3.8);
        poly([6.2, 7.4, 6.2, 21, 17.8, 21, 17.8, 7.4]);
        line(10, 11.1, 10, 17.8);
        line(14, 11.1, 14, 17.8);
      case FinanceGlyph.refresh:
        // C-shaped circular arrow, deliberately open at the right.
        bezier((p) {
          p.moveTo(19.1, 10.1);
          p.cubicTo(18.2, 6, 14.9, 3.4, 10.8, 3.4);
          p.cubicTo(5.8, 3.4, 2.7, 7.4, 2.7, 12.4);
          p.cubicTo(2.7, 17.4, 6.6, 21, 11.6, 21);
          p.cubicTo(16.7, 21, 20, 17.9, 20, 13.9);
        });
        poly([19.1, 5.9, 19.1, 10.1, 14.7, 10.1]);
      case FinanceGlyph.trend:
        poly([2.2, 19.7, 8.7, 12.0, 12.1, 15.2, 20.3, 5.4]);
        poly([15.8, 5.4, 20.3, 5.4, 20.3, 10.0]);
      case FinanceGlyph.check:
        poly([3.2, 12.7, 9.2, 18.5, 20.8, 5.6]);
      case FinanceGlyph.eye:
      case FinanceGlyph.eyeOff:
        // Almond outline with a square pupil.
        bezier((p) {
          p.moveTo(2.0, 12);
          p.cubicTo(5.1, 7.2, 8.0, 5.0, 12, 5.0);
          p.cubicTo(16.0, 5.0, 18.9, 7.2, 22, 12);
          p.cubicTo(18.9, 16.8, 16.0, 19, 12, 19);
          p.cubicTo(8.0, 19, 5.1, 16.8, 2.0, 12);
          p.close();
        });
        rect(9.7, 9.7, 4.6, 4.6);
        if (glyph == FinanceGlyph.eyeOff) poly([4, 4, 20, 20]);
      case FinanceGlyph.edit:
        poly([4, 20, 5, 15, 16, 4, 20, 8, 9, 19], close: true);
        poly([14, 6, 18, 10]);
      case FinanceGlyph.document:
        poly([6, 3, 14, 3, 19, 8, 19, 21, 6, 21], close: true);
        poly([14, 3, 14, 8, 19, 8]);
        line(9, 13, 16, 13);
        line(9, 17, 16, 17);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FinanceIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.filled != filled;
}
