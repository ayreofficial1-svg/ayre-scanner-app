import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The line-chart primitive, in three named sizes (Spec §12.2).
///
/// One painter serves all three — the plan's §6 table asked Phase 3 to confirm
/// whether Sparkline and AreaTrend are really the same drawing at different
/// parameters, and they are: same polyline, same normalised 0..1 input, same
/// left-to-right draw-on. Only the box, the stroke weight, whether the area
/// beneath is filled, and whether the latest sample carries a dot differ.
/// Building three painters would have meant three places to fix a geometry bug.
///
/// Two rules from §12.1 are enforced here rather than left to call sites:
///
/// * **No gridlines.** The previous identity's `showGrid` flag is gone, not
///   deprecated — a small chart with gridlines reads as a terminal readout,
///   which is the identity this replaces. `chartGrid` was retired as a token
///   in Phase 0 for the same reason.
/// * **A chart inherits the colour of its subject.** There is no neutral
///   "chart line" token any more. [color] should be the semantic colour of the
///   thing being plotted (positive/negative for a mover, the accent for a
///   brand metric); the [AppThemeTokens.foregroundMuted] fallback exists so a
///   caller that genuinely has no subject colour still renders, not as a
///   default to lean on.
class TickerTrace extends StatefulWidget {
  const TickerTrace({
    super.key,
    required this.points,
    this.color,
    this.width,
    this.height = 32,
    this.strokeWidth = 1.6,
    this.fill = false,
    this.endDot = false,
  });

  /// Sparkline (§12.2) — the inline trend beside a row or under a figure.
  /// 96×32, 1.6px, area fill optional and off unless asked for.
  const TickerTrace.sparkline({
    super.key,
    required this.points,
    this.color,
    this.fill = false,
  }) : width = 96,
       height = 32,
       strokeWidth = 1.6,
       endDot = false;

  /// Sparkline thumbnail (§12.2) — the list-row chart cell. Squarer, heavier
  /// stroke to survive the smaller box, fill always off (a filled area at this
  /// size reads as a solid block, not a trend).
  const TickerTrace.thumbnail({
    super.key,
    required this.points,
    this.color,
  }) : width = 64,
       height = 48,
       strokeWidth = 1.8,
       fill = false,
       endDot = false;

  /// AreaTrend (§12.2) — the featured chart on a card. 320×120, 2px, gradient
  /// fill, and a dot on the latest sample.
  const TickerTrace.areaTrend({
    super.key,
    required this.points,
    this.color,
    this.width = 320,
    this.height = 120,
  }) : strokeWidth = 2,
       fill = true,
       endDot = true;

  /// Normalised 0..1 samples, oldest first. Fewer than two points renders
  /// empty — see [normaliseTrace].
  final List<double> points;

  /// The subject's own colour. See the class note: this is not a styling
  /// choice, it's the semantic colour of the thing being plotted.
  final Color? color;

  /// Null stretches to the parent's width — the named constructors above give
  /// the Spec's fixed boxes, but a card-width trend still needs to fill its
  /// card.
  final double? width;
  final double height;
  final double strokeWidth;

  /// A vertical gradient beneath the line, from the line's own colour at low
  /// alpha down to fully transparent.
  final bool fill;

  /// A dot on the latest sample — "you are here". Round, in the line's colour,
  /// ringed in the surface colour so it stays legible where the line doubles
  /// back under it.
  final bool endDot;

  @override
  State<TickerTrace> createState() => _TickerTraceState();
}

class _TickerTraceState extends State<TickerTrace>
        // Two controllers — the initial draw-on and the shape morph — so this
        // needs the multi-ticker mixin, not the single one.
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
    // Retuned in Phase 3 onto the Spec's own chart-draw timing (§15.2,
    // 1.1–1.4s) — the previous 620ms was the old identity's "feed ticking in"
    // pace and reads hurried against v4's motion. `AppMotion.traceDraw` was
    // retired with this change rather than left as a second chart duration.
    _draw = AnimationController(vsync: this, duration: AppMotion.chartDraw);
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
        width: widget.width ?? double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([_draw, _morph]),
          builder: (context, _) => CustomPaint(
            painter: _TracePainter(
              points: _interpolated,
              color: widget.color ?? t.foregroundMuted,
              haloColor: t.surface,
              strokeWidth: widget.strokeWidth,
              fill: widget.fill,
              endDot: widget.endDot,
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
    required this.haloColor,
    required this.strokeWidth,
    required this.fill,
    required this.endDot,
    required this.drawn,
  });

  final List<double> points;
  final Color color;
  final Color haloColor;
  final double strokeWidth;
  final bool fill;
  final bool endDot;

  /// 0..1 fraction of the trace revealed, left to right.
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0) return;

    // Inset by half the stroke so a sample at 0 or 1 isn't clipped in half by
    // the box edge — with round caps the cap itself also needs the room.
    final inset = strokeWidth / 2 + 1;
    final usable = (size.height - inset * 2).clamp(1.0, size.height);
    Offset at(int i) {
      final x = i / (points.length - 1) * size.width;
      final y = inset + (1.0 - points[i].clamp(0.0, 1.0)) * usable;
      return Offset(x, y);
    }

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final p = at(i);
      line.lineTo(p.dx, p.dy);
    }

    // Reveal by clipping rather than by rebuilding the path, so the geometry
    // is identical whether animating or static — and so the area fill and the
    // line reveal as one object rather than drifting apart.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * drawn, size.height));

    if (fill) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        // Round, not the previous identity's butt/miter. A mitred join on a
        // sharp reversal throws a spike well past the stroke width, which is
        // the "terminal" read v4 is moving away from — and §7's rounded
        // geometry applies to drawn strokes, not just box corners.
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    if (endDot && drawn >= 0.999) {
      final last = at(points.length - 1);
      // Halo first: the dot sits on top of the line, and where the trace
      // doubles back beneath it the two would otherwise merge into a blob.
      canvas.drawCircle(
        last,
        strokeWidth * 1.9,
        Paint()..color = haloColor,
      );
      canvas.drawCircle(last, strokeWidth * 1.25, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) {
    return old.drawn != drawn ||
        old.color != color ||
        old.haloColor != haloColor ||
        old.strokeWidth != strokeWidth ||
        old.fill != fill ||
        old.endDot != endDot ||
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