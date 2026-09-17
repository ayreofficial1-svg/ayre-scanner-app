// The radial chart family (Spec §12.2): BreadthDonut, ProgressRing and
// SentimentGauge.
//
// All three are hand-painted arcs, not a chart package — §12.1's "custom, not
// a third-party library" rule, which `ticker_trace.dart` already followed for
// the line family. They share `_ArcGeometry` below rather than each
// re-deriving cap/gap compensation, because getting that wrong is invisible in
// code review and obvious on screen.
//
// Each draws on over `AppMotion.chartDraw` and snaps to its final state under
// reduced motion (§15.9). None of them carries meaning in colour alone: the
// donut labels its segments, the ring labels its percentage, the gauge labels
// its band.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'figure.dart';

// ─── Shared arc geometry ───────────────────────────────────────────────────

/// Round stroke caps and inter-segment gaps both eat into the arc a segment
/// actually occupies, and they do it in *pixels* while an arc is drawn in
/// *radians* — so the conversion depends on the radius and has to happen once,
/// here, rather than being eyeballed per painter.
///
/// A round cap extends half the stroke width past each end of the arc, so an
/// arc drawn at its nominal sweep is visually `strokeWidth` longer than it
/// should be and its neighbour's gap disappears. Both ends are pulled in by
/// the cap allowance plus half the gap.
class _ArcGeometry {
  const _ArcGeometry(this.radius, this.strokeWidth);

  final double radius;
  final double strokeWidth;

  /// Radians consumed by one round cap.
  double get capRadians => radius <= 0 ? 0 : (strokeWidth / 2) / radius;

  /// Radians consumed by a [gapPixels]-wide gap at this radius.
  double gapRadians(double gapPixels) => radius <= 0 ? 0 : gapPixels / radius;

  /// The sweep actually painted for a segment nominally [sweep] wide, once a
  /// cap at each end and half a gap at each end are taken out. Returns null
  /// when the segment is too small to survive that — a 0.4% slice cannot be
  /// drawn with round caps and a gap, and drawing it anyway produces a
  /// backwards arc, not a tiny one.
  double? inset(double sweep, double gapPixels) {
    final trimmed = sweep - gapRadians(gapPixels) - capRadians * 2;
    return trimmed <= 0 ? null : trimmed;
  }
}

/// Drives a 0→1 draw-on, honouring reduced motion. Every chart in this file
/// wraps its painter in one of these rather than each growing its own
/// controller and its own `disableAnimationsOf` check.
class _DrawOn extends StatefulWidget {
  const _DrawOn({required this.builder, this.duration});

  final Widget Function(BuildContext context, double progress) builder;
  final Duration? duration;

  @override
  State<_DrawOn> createState() => _DrawOnState();
}

class _DrawOnState extends State<_DrawOn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AppMotion.chartDraw,
    );
    // MediaQuery isn't readable in initState — decide on the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(
          context,
          AppMotion.ease.transform(_controller.value.clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}

// ─── BreadthDonut ──────────────────────────────────────────────────────────

/// Market breadth as a three-segment donut (Spec §12.2): advances in sage,
/// declines in rose, unchanged in the subtle foreground tone, with the advance
/// share counting up in the middle.
///
/// This replaces `BreadthMeter`, the previous identity's linear filled bar
/// against a labelled 0–100 scale. That component's own doc comment argued a
/// bar was *deliberately* not a dial; v4 reverses that on both counts — a
/// donut here, and a genuine gauge for sentiment ([SentimentGauge]). The old
/// file was deleted rather than retuned, following the Phase 2 precedent with
/// `curved_nav_bar.dart`.
///
/// Segments are never smaller than they are: a slice too thin to draw with
/// round caps and a 2px gap is dropped from the ring entirely rather than
/// painted as a smear, and the legend still lists it with its real count.
class BreadthDonut extends StatelessWidget {
  const BreadthDonut({
    super.key,
    required this.advances,
    required this.declines,
    this.unchanged = 0,
    this.size = 132,
    this.thickness = 12,
    this.showLegend = true,
  });

  final int advances;
  final int declines;
  final int unchanged;

  /// Outer diameter. The Spec fixes a size for [ProgressRing] (64) and
  /// [SentimentGauge] (176) but not for the donut; 132 sits between them and
  /// leaves room for the centre reading at the default text scale. Flagged in
  /// the plan for confirmation against the Spec's own figure.
  final double size;
  final double thickness;

  /// The labelled counts beneath the ring. Colour alone never carries which
  /// arc is which (§19), so this is on by default and should only be turned
  /// off where the caller supplies its own labelled breakdown.
  final bool showLegend;

  int get _total => advances + declines + unchanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = _total;
    // The centre reading is the advance share — the same quantity the largest
    // arc already shows, so the number and the picture agree. (A *net*
    // advance figure, (adv − dec) / total, would be a different number from
    // anything drawn here; flagged in the plan as the one place §12.2's
    // "net-advance %" wording could be read either way.)
    final share = total == 0 ? 0.0 : advances / total * 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: _DrawOn(
            builder: (context, progress) => CustomPaint(
              painter: _DonutPainter(
                segments: [
                  (advances.toDouble(), t.positive),
                  (declines.toDouble(), t.negative),
                  (unchanged.toDouble(), t.foregroundSubtle),
                ],
                track: t.surfaceSunken,
                thickness: thickness,
                progress: progress,
              ),
              // The centre reading lives inside a fixed-diameter ring, so at
              // large accessibility text scales it has nowhere to grow into.
              // Shrinking to fit is the same treatment `FreshnessStamp` and
              // `ShrinkTrailing` already use for trailing slots — it keeps the
              // reading legible where clipping or an overflow stripe would
              // not. The inset leaves the ring's own stroke clear.
              child: Padding(
                padding: EdgeInsets.all(thickness + AppSpace.xs),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CountUpFigure(
                          value: share,
                          format: (v) => '${v.round()}%',
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                          semanticsLabel:
                              '${share.round()} percent advancing, $advances '
                              'up, $declines down, $unchanged unchanged',
                        ),
                        const SizedBox(height: 2),
                        Text('ADVANCING', style: AppTypo.label(t)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: AppSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendKey(color: t.positive, label: 'Up', value: advances),
              const SizedBox(width: AppSpace.md),
              _LegendKey(color: t.negative, label: 'Down', value: declines),
              if (unchanged > 0) ...[
                const SizedBox(width: AppSpace.md),
                _LegendKey(
                  color: t.foregroundSubtle,
                  label: 'Flat',
                  value: unchanged,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// A dot, a name and a count. The dot is the *confirming* channel — the name
/// and count carry the meaning on their own with colour stripped out.
class _LegendKey extends StatelessWidget {
  const _LegendKey({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.xxs + 2),
        Text(label, style: AppTypo.hint(t, color: t.foregroundMuted)),
        const SizedBox(width: AppSpace.xxs),
        Figure.static(
          '$value',
          fontSize: AppTextScale.hint,
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.track,
    required this.thickness,
    required this.progress,
  });

  /// (value, colour), in ring order.
  final List<(double, Color)> segments;
  final Color track;
  final double thickness;
  final double progress;

  static const double _gapPixels = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - thickness) / 2;
    if (radius <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final geo = _ArcGeometry(radius, thickness);

    Paint stroke(Color color, StrokeCap cap) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = cap;

    // The track is a full circle, so it takes a butt cap — a round cap on a
    // closed ring does nothing but cost a draw.
    canvas.drawCircle(center, radius, stroke(track, StrokeCap.butt));

    final total = segments.fold<double>(0, (sum, s) => sum + s.$1);
    if (total <= 0 || progress <= 0) return;

    const start = -math.pi / 2; // Twelve o'clock.
    final revealTo = start + 2 * math.pi * progress;

    var cursor = start;
    for (final (value, color) in segments) {
      if (value <= 0) continue;
      final sweep = value / total * 2 * math.pi;
      final trimmed = geo.inset(sweep, _gapPixels);
      if (trimmed == null) {
        // Too thin to draw honestly — skipped, not smeared. The legend still
        // reports its real count.
        cursor += sweep;
        continue;
      }

      final from = cursor + geo.gapRadians(_gapPixels) / 2 + geo.capRadians;
      // Clip the segment against the single sweeping reveal, so the whole ring
      // draws on as one motion rather than three arcs racing each other.
      final visible = math.min(from + trimmed, revealTo) - from;
      if (visible > 0) {
        canvas.drawArc(
          rect,
          from,
          visible,
          false,
          stroke(color, StrokeCap.round),
        );
      }
      cursor += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    return old.progress != progress ||
        old.thickness != thickness ||
        old.track != track ||
        old.segments.length != segments.length ||
        !_sameSegments(old.segments, segments);
  }

  static bool _sameSegments(List<(double, Color)> a, List<(double, Color)> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].$1 != b[i].$1 || a[i].$2 != b[i].$2) return false;
    }
    return true;
  }
}

// ─── ProgressRing ──────────────────────────────────────────────────────────

/// Circular course/lesson progress (Spec §12.2): 64px across, 6px thick, track
/// in [AppThemeTokens.surfaceRaised], fill in the brand accent — switching to
/// [AppThemeTokens.positive] on completion, which is the one place a
/// completion genuinely is an affirmative outcome rather than a brand action.
///
/// Confirms plan §7 open decision #4 from the other direction: `ProgressRule`
/// (`ayre_components.dart`) is a linear `LinearProgressIndicator`-backed bar
/// despite the suggestive name, so this was written from scratch rather than
/// adapted. Both survive — Learn's list rows use the rule, the continue-card
/// uses the ring.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.thickness = 6,
    this.label,
    this.showPercent = true,
  });

  /// 0..1.
  final double value;
  final double size;
  final double thickness;

  /// Replaces the centred percentage entirely (e.g. a check glyph on
  /// completion, a lesson count).
  final Widget? label;

  final bool showPercent;

  bool get _complete => value >= 0.999;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final clamped = value.clamp(0.0, 1.0);
    final fill = _complete ? t.positive : t.accent;

    return SizedBox(
      width: size,
      height: size,
      child: _DrawOn(
        builder: (context, progress) => CustomPaint(
          painter: _RingPainter(
            value: clamped * progress,
            fill: fill,
            track: t.surfaceRaised,
            thickness: thickness,
          ),
          // Same fixed-diameter problem as the donut: the ring is 64px whatever
          // the text scale, so the label shrinks to fit rather than overflowing
          // it.
          child: Padding(
            padding: EdgeInsets.all(thickness + 2),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child:
                    label ??
                    (showPercent
                        ? CountUpFigure(
                            value: clamped * 100,
                            format: (v) => '${v.round()}%',
                            fontSize: size * 0.24,
                            fontWeight: FontWeight.w600,
                            color: _complete ? t.positive : t.textPrimary,
                            semanticsLabel:
                                '${(clamped * 100).round()} percent complete',
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.fill,
    required this.track,
    required this.thickness,
  });

  final double value;
  final Color fill;
  final Color track;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - thickness) / 2;
    if (radius <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );

    if (value <= 0) return;
    final geo = _ArcGeometry(radius, thickness);
    // A full ring closes on itself, so it needs no cap allowance; a partial
    // one is pulled in by half a cap at each end so the round ends land where
    // the value says they should rather than overshooting it.
    final full = value >= 0.999;
    final sweep = full
        ? 2 * math.pi
        : math.max(0.0, 2 * math.pi * value - geo.capRadians * 2);
    if (sweep <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (full ? 0 : geo.capRadians),
      sweep,
      false,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = full ? StrokeCap.butt : StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.value != value ||
        old.fill != fill ||
        old.track != track ||
        old.thickness != thickness;
  }
}

// ─── SentimentGauge ────────────────────────────────────────────────────────

/// The sentiment reading as a 180° gauge (Spec §12.2): 176px wide, 11px thick,
/// a track with the accent filled to `score/100` of the arc, and a marker dot
/// at the reading — surface-filled, accent-stroked, so it reads as a position
/// on the arc rather than another segment of it.
///
/// This reverses the previous identity explicitly. `BreadthMeter`'s doc comment
/// stated a gauge motif "belonged to the previous identity and is retired";
/// the Spec brings it back by name, and the plan (§6) treats that as a
/// deliberate reversal rather than an oversight to be argued with.
///
/// The score is spelled out beneath the arc and the band is named, so the
/// reading survives with the arc, its colour, or both removed.
class SentimentGauge extends StatelessWidget {
  const SentimentGauge({
    super.key,
    required this.score,
    required this.band,
    this.tone,
    this.width = 176,
    this.thickness = 11,
  });

  /// 0..100.
  final int score;

  /// The band this reading falls in — the words the user actually reads.
  final String band;

  /// Defaults to the brand accent, which is what §12.2 specifies for the fill.
  /// Callers that legitimately own a direction (a bearish reading tinted
  /// [AppThemeTokens.negative]) may override; §12.1's "a chart inherits the
  /// colour of its subject" is the reason the hook exists at all.
  final Color? tone;

  final double width;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fill = tone ?? t.accent;
    final clamped = (score / 100).clamp(0.0, 1.0);
    // A 180° arc of radius r occupies r + half a stroke vertically.
    final radius = (width - thickness) / 2;
    final arcHeight = radius + thickness / 2;

    return Semantics(
      label: 'Sentiment $score out of 100, $band',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width,
              height: arcHeight,
              child: _DrawOn(
                builder: (context, progress) => CustomPaint(
                  painter: _GaugePainter(
                    value: clamped * progress,
                    fill: fill,
                    track: t.surfaceSunken,
                    markerFill: t.surface,
                    thickness: thickness,
                  ),
                  // The reading sits inside the arc's own opening rather than
                  // below it — the gauge is the frame for the number, not a
                  // decoration beside it.
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: thickness * 0.2,
                        left: thickness * 2,
                        right: thickness * 2,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CountUpFigure(
                              value: score.toDouble(),
                              format: (v) => '${v.round()}',
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 4,
                                left: 2,
                              ),
                              child: Text(
                                '/100',
                                style: AppTypo.valueSmall(t),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              band.toUpperCase(),
              style: AppTypo.label(t, color: fill),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.fill,
    required this.track,
    required this.markerFill,
    required this.thickness,
  });

  final double value;
  final Color fill;
  final Color track;

  /// The marker is filled with the surface it sits on and stroked in the fill
  /// colour, so it reads as a position marker rather than a blob of arc.
  final Color markerFill;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - thickness) / 2;
    if (radius <= 0) return;
    // The arc's centre is its bottom-middle: a half-circle sitting on the
    // widget's baseline.
    final center = Offset(size.width / 2, size.height - thickness / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final geo = _ArcGeometry(radius, thickness);

    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // π → 2π: left end, over the top, to the right end.
    canvas.drawArc(rect, math.pi, math.pi, false, stroke(track));

    if (value > 0) {
      // Half a cap in from the start so the rounded end sits flush with the
      // track's own rounded end instead of poking past it.
      final sweep = math.max(0.0, math.pi * value - geo.capRadians);
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          math.pi + geo.capRadians,
          sweep,
          false,
          stroke(fill),
        );
      }
    }

    final angle = math.pi + math.pi * value.clamp(0.0, 1.0);
    final at = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final markerRadius = thickness * 0.34;
    canvas.drawCircle(at, markerRadius, Paint()..color = markerFill);
    canvas.drawCircle(
      at,
      markerRadius,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) {
    return old.value != value ||
        old.fill != fill ||
        old.track != track ||
        old.markerFill != markerFill ||
        old.thickness != thickness;
  }
}