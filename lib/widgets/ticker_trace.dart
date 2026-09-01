import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A hairline trace — never a filled or gradient area chart. Straight segments,
/// not eased curves: a feed records what happened, it doesn't smooth it.
///
/// On first load the trace draws on from left to right, which is what makes live
/// data feel live. When the points change it morphs to the new shape instead of
/// clearing and redrawing, so an update reads as the same trace moving.
class TickerTrace extends StatefulWidget {
  const TickerTrace({
    super.key,
    required this.points,
    this.color,
    this.height = 44,
    this.strokeWidth = 1.4,
    this.showGrid = false,
    this.showLastMarker = true,
  });

  /// Normalised 0..1 samples, oldest first. Fewer than two points renders empty.
  final List<double> points;

  /// Defaults to the neutral chart line. Pass Citrine only where the trace is
  /// explicitly the brand's featured metric.
  final Color? color;
  final double height;
  final double strokeWidth;
  final bool showGrid;

  /// A small tick at the latest sample — the "you are here" of a feed.
  final bool showLastMarker;

  @override
  State<TickerTrace> createState() => _TickerTraceState();
}

class _TickerTraceState extends State<TickerTrace>
        // Two controllers — the initial draw-on and the shape morph — so this needs
        // the multi-ticker mixin, not the single one.
        with
        TickerProviderStateMixin {
  late final AnimationController _draw;
  late final AnimationController _morph;
  late List<double> _from;
  late List<double> _to;

  @override
  void initState() {
    super.initState();
    _from = widget.points;
    _to = widget.points;
    _draw = AnimationController(vsync: this, duration: AppMotion.traceDraw);
    _morph = AnimationController(vsync: this, duration: AppMotion.slow)
      ..value = 1.0;
    _draw.forward();
  }

  @override
  void didUpdateWidget(TickerTrace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.points, widget.points)) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _from = widget.points;
      _to = widget.points;
      _morph.value = 1.0;
      _draw.value = 1.0;
      return;
    }
    _from = _interpolated;
    _to = widget.points;
    _morph.forward(from: 0);
    // Already drawn on; a data change morphs rather than redrawing from zero.
    _draw.value = 1.0;
  }

  List<double> get _interpolated {
    final t = AppMotion.ease.transform(_morph.value.clamp(0.0, 1.0));
    if (_from.length != _to.length) return _to;
    return [
      for (var i = 0; i < _to.length; i++) _from[i] + (_to[i] - _from[i]) * t,
    ];
  }

  @override
  void dispose() {
    _draw.dispose();
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([_draw, _morph]),
          builder: (context, _) => CustomPaint(
            painter: _TracePainter(
              points: _interpolated,
              color: widget.color ?? t.chartLine,
              gridColor: t.chartGrid,
              strokeWidth: widget.strokeWidth,
              showGrid: widget.showGrid,
              showLastMarker: widget.showLastMarker,
              drawn: reduceMotion
                  ? 1.0
                  : AppMotion.ease.transform(_draw.value.clamp(0.0, 1.0)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({
    required this.points,
    required this.color,
    required this.gridColor,
    required this.strokeWidth,
    required this.showGrid,
    required this.showLastMarker,
    required this.drawn,
  });

  final List<double> points;
  final Color color;
  final Color gridColor;
  final double strokeWidth;
  final bool showGrid;
  final bool showLastMarker;

  /// 0..1 fraction of the trace revealed, left to right.
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0) return;

    if (showGrid) {
      final grid = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (var i = 1; i < 4; i++) {
        final y = size.height * i / 4;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    const inset = 2.0;
    final usable = (size.height - inset * 2).clamp(1.0, size.height);
    Offset at(int i) {
      final x = i / (points.length - 1) * size.width;
      final y = inset + (1.0 - points[i].clamp(0.0, 1.0)) * usable;
      return Offset(x, y);
    }

    // Reveal by clipping rather than by rebuilding the path, so the geometry is
    // identical whether animating or static.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * drawn, size.height));

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p = at(i);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter,
    );
    canvas.restore();

    if (showLastMarker && drawn >= 0.999) {
      final last = at(points.length - 1);
      canvas.drawRect(
        Rect.fromCenter(center: last, width: 3, height: 3),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) {
    return old.drawn != drawn ||
        old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.showGrid != showGrid ||
        old.showLastMarker != showLastMarker ||
        !listEquals(old.points, points);
  }
}

/// Normalises a series of raw values to 0..1 for [TickerTrace]. A flat series
/// renders as a centred line rather than dividing by zero.
List<double> normaliseTrace(List<num> raw) {
  if (raw.length < 2) return const [];
  var min = raw.first.toDouble();
  var max = raw.first.toDouble();
  for (final value in raw) {
    if (value < min) min = value.toDouble();
    if (value > max) max = value.toDouble();
  }
  final span = max - min;
  if (span <= 0) return List<double>.filled(raw.length, 0.5);
  return [for (final value in raw) (value - min) / span];
}
