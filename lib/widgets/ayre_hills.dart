import 'package:flutter/material.dart';

/// Header ornament (v5 §2A, "Header decorative hill shapes"): three soft,
/// overlapping translucent silhouettes anchored to the top-right corner of
/// the box they're given, in brand green / ivory at low alpha, furthest-back shape
/// faintest.
///
/// **Purely decorative — not a chart.** It carries no data, is excluded from
/// semantics, and ignores pointers, so it can sit behind any header content.
/// It draws past the right and top edges of its own box on purpose (the
/// ellipses are centred on the corner), so position it flush to — or past —
/// the screen edge and let the viewport clip it: that is the "bleeding off
/// the top-right" look the reference shows.
///
/// Shared by the Home header (Phase 2) and the Profile header (Phase 6,
/// "same soft layered shape device").
///
/// Light: brand deep green (`#0F3D2E`) at ~4/8/12 %. Dark: brand ivory
/// (`#F7F5EF`) at ~5/9/13 %. Written out as ARGB so the layering stays exactly
/// as specified rather than being re-derived from float alphas.
class AyreHills extends StatelessWidget {
  const AyreHills({super.key, this.width = 260, this.height = 170});

  final double width;
  final double height;

  // Outermost (back) → innermost (front).
  static const List<Color> _light = [
    Color(0x0A0F3D2E),
    Color(0x140F3D2E),
    Color(0x1F0F3D2E),
  ];
  static const List<Color> _dark = [
    Color(0x0DF7F5EF),
    Color(0x17F7F5EF),
    Color(0x21F7F5EF),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size(width, height),
          painter: _HillsPainter(colors: dark ? _dark : _light),
        ),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  const _HillsPainter({required this.colors});

  /// Back → front.
  final List<Color> colors;

  // Ellipse centre (as a fraction of the box) and radii (fractions of the
  // box), back → front. Centres sit on/just past the top-right corner and are
  // nudged apart so the arcs layer rather than nest concentrically.
  static const List<(double, double, double, double)> _shapes = [
    (0.98, 0.02, 0.92, 0.90),
    (1.02, -0.02, 0.66, 0.64),
    (1.06, -0.04, 0.40, 0.40),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _shapes.length; i++) {
      final (cx, cy, rx, ry) = _shapes[i];
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * cx, size.height * cy),
          width: size.width * rx * 2,
          height: size.height * ry * 2,
        ),
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HillsPainter old) => old.colors != colors;
}
