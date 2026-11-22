import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Investee icon vocabulary: 24 outline glyphs on a 24-unit grid, no
/// fills, square caps and miter joins. One stroke weight (1.75) everywhere —
/// selection is expressed by colour and the saffron marker, never by a filled
/// variant.
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
  });

  final FinanceGlyph glyph;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  /// Clockwise quarter turns, e.g. a right-pointing chevron rotated to point
  /// down (1), left (2) or up (3).
  final int quarterTurns;

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
  });

  final FinanceGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.save();
    canvas.scale(scale);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..strokeMiterLimit = 4;
    for (final path in _paths(glyph)) {
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  static Path _poly(List<double> pts, {bool close = false}) {
    final path = Path()..moveTo(pts[0], pts[1]);
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(pts[i], pts[i + 1]);
    }
    if (close) path.close();
    return path;
  }

  static Path _circle(double cx, double cy, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

  static Path _rect(double l, double t, double w, double h) =>
      Path()..addRect(Rect.fromLTWH(l, t, w, h));

  static List<Path> _paths(FinanceGlyph g) {
    switch (g) {
      case FinanceGlyph.home:
        return [
          _poly([3, 11, 12, 3, 21, 11]),
          _poly([5, 9.5, 5, 21, 19, 21, 19, 9.5]),
          _poly([10, 21, 10, 14, 14, 14, 14, 21]),
        ];
      case FinanceGlyph.reports:
        return [
          _poly([5, 3, 19, 3, 19, 21, 5, 21], close: true),
          _poly([9, 17, 9, 13]),
          _poly([12, 17, 12, 10]),
          _poly([15, 17, 15, 7]),
        ];
      case FinanceGlyph.learn:
        return [
          Path()
            ..moveTo(12, 6)
            ..cubicTo(10, 4.5, 7, 4, 3, 4.5)
            ..lineTo(3, 18)
            ..cubicTo(7, 17.5, 10, 18, 12, 20)
            ..cubicTo(14, 18, 17, 17.5, 21, 18)
            ..lineTo(21, 4.5)
            ..cubicTo(17, 4, 14, 4.5, 12, 6)
            ..close(),
          _poly([12, 6, 12, 20]),
        ];
      case FinanceGlyph.profile:
        return [
          _circle(12, 8, 4),
          Path()
            ..moveTo(4, 21)
            ..cubicTo(4, 16.5, 7.5, 14, 12, 14)
            ..cubicTo(16.5, 14, 20, 16.5, 20, 21),
        ];
      case FinanceGlyph.bell:
        return [
          Path()
            ..moveTo(6, 17)
            ..lineTo(6, 11)
            ..cubicTo(6, 7.5, 8.5, 5, 12, 5)
            ..cubicTo(15.5, 5, 18, 7.5, 18, 11)
            ..lineTo(18, 17),
          _poly([4, 17, 20, 17]),
          _poly([10, 20.5, 14, 20.5]),
          _poly([12, 3, 12, 5]),
        ];
      case FinanceGlyph.moon:
        return [
          Path()
            ..moveTo(20, 14.5)
            ..arcToPoint(
              const Offset(9.5, 4),
              radius: const Radius.circular(8),
              largeArc: true,
              clockwise: false,
            )
            ..arcToPoint(
              const Offset(20, 14.5),
              radius: const Radius.circular(6.5),
              clockwise: true,
            )
            ..close(),
        ];
      case FinanceGlyph.sun:
        final rays = <Path>[];
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final c = math.cos(a), s = math.sin(a);
          rays.add(_poly([12 + c * 7, 12 + s * 7, 12 + c * 9.5, 12 + s * 9.5]));
        }
        return [_circle(12, 12, 4), ...rays];
      case FinanceGlyph.chevron:
        return [
          _poly([9, 5, 16, 12, 9, 19]),
        ];
      case FinanceGlyph.back:
        return [
          _poly([19, 12, 5, 12]),
          _poly([11, 6, 5, 12, 11, 18]),
        ];
      case FinanceGlyph.sliders:
        return [
          _poly([4, 7, 20, 7]),
          _poly([4, 17, 20, 17]),
          _poly([9, 4, 9, 10]),
          _poly([15, 14, 15, 20]),
        ];
      case FinanceGlyph.help:
        return [
          _circle(12, 12, 9),
          Path()
            ..moveTo(9.5, 9.5)
            ..cubicTo(9.5, 8, 10.7, 7, 12, 7)
            ..cubicTo(13.3, 7, 14.5, 8, 14.5, 9.5)
            ..cubicTo(14.5, 11.2, 12, 11.5, 12, 13.5),
          _poly([12, 16.5, 12, 17]),
        ];
      case FinanceGlyph.info:
        return [
          _circle(12, 12, 9),
          _poly([12, 11, 12, 17]),
          _poly([12, 7, 12, 7.5]),
        ];
      case FinanceGlyph.pulse:
        return [
          _poly([3, 12, 7, 12, 9.5, 5, 13.5, 19, 16, 12, 21, 12]),
        ];
      case FinanceGlyph.shield:
        return [
          Path()
            ..moveTo(12, 3)
            ..lineTo(20, 6)
            ..lineTo(20, 12)
            ..cubicTo(20, 16.5, 16.5, 19.5, 12, 21)
            ..cubicTo(7.5, 19.5, 4, 16.5, 4, 12)
            ..lineTo(4, 6)
            ..close(),
        ];
      case FinanceGlyph.lock:
        return [
          _rect(5, 11, 14, 10),
          Path()
            ..moveTo(8, 11)
            ..lineTo(8, 7.5)
            ..arcToPoint(
              const Offset(16, 7.5),
              radius: const Radius.circular(4),
              clockwise: true,
            )
            ..lineTo(16, 11),
        ];
      case FinanceGlyph.mail:
        return [
          _rect(3, 5, 18, 14),
          _poly([3, 6, 12, 13, 21, 6]),
        ];
      case FinanceGlyph.trash:
        return [
          _poly([4, 7, 20, 7]),
          _poly([9, 7, 9, 4, 15, 4, 15, 7]),
          _poly([6, 7, 7, 21, 17, 21, 18, 7]),
          _poly([10, 11, 10, 17]),
          _poly([14, 11, 14, 17]),
        ];
      case FinanceGlyph.refresh:
        return [
          Path()
            ..moveTo(20, 12)
            ..arcToPoint(
              const Offset(17.66, 6.34),
              radius: const Radius.circular(8),
              largeArc: true,
              clockwise: true,
            ),
          _poly([20, 3.5, 20, 7.5, 16, 7.5]),
        ];
      case FinanceGlyph.trend:
        return [
          _poly([3, 17, 9, 11, 13, 15, 21, 7]),
          _poly([15, 7, 21, 7, 21, 13]),
        ];
      case FinanceGlyph.check:
        return [
          _poly([5, 12.5, 10, 17.5, 19, 7]),
        ];
      case FinanceGlyph.eye:
        return [_eye(), _circle(12, 12, 3)];
      case FinanceGlyph.eyeOff:
        return [
          _eye(),
          _circle(12, 12, 3),
          _poly([4, 4, 20, 20]),
        ];
      case FinanceGlyph.edit:
        return [
          _poly([4, 20, 5, 15, 16, 4, 20, 8, 9, 19], close: true),
          _poly([14, 6, 18, 10]),
        ];
      case FinanceGlyph.document:
        return [
          _poly([6, 3, 14, 3, 19, 8, 19, 21, 6, 21], close: true),
          _poly([14, 3, 14, 8, 19, 8]),
          _poly([9, 13, 16, 13]),
          _poly([9, 17, 16, 17]),
        ];
    }
  }

  static Path _eye() => Path()
    ..moveTo(2, 12)
    ..cubicTo(5, 6.5, 8.5, 5, 12, 5)
    ..cubicTo(15.5, 5, 19, 6.5, 22, 12)
    ..cubicTo(19, 17.5, 15.5, 19, 12, 19)
    ..cubicTo(8.5, 19, 5, 17.5, 2, 12)
    ..close();

  @override
  bool shouldRepaint(_FinanceIconPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
