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
import '../services/market_models.dart';
import 'ayre_components.dart';
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
  const _DrawOn({required this.builder});

  final Widget Function(BuildContext context, double progress) builder;

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
      duration: AppMotion.chartDraw,
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

/// Market breadth as a three-segment donut (Spec §12.2): advances in
/// [AppThemeTokens.positive], declines in [AppThemeTokens.negative], unchanged
/// in the subtle foreground tone, with the advance share counting up in the
/// middle.
///
/// This replaced `BreadthMeter`, an earlier linear filled bar against a
/// labelled 0–100 scale. That component was deliberately a bar rather than a
/// dial; the redesign reversed that on both counts — a donut here, and a
/// genuine gauge for sentiment ([SentimentGauge]). The old file was deleted
/// rather than retuned.
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
    this.centerLabel = 'ADVANCING',
    this.primaryLabel = 'Up',
    this.secondaryLabel = 'Down',
    this.neutralLabel = 'Flat',
  });

  final int advances;
  final int declines;
  final int unchanged;

  /// Labels below the ring's centre reading and in its legend. Defaulted to
  /// the original market-breadth wording so every existing call site is
  /// unaffected; Insights' momentum-tilt reading (bullish/bearish rather
  /// than advancing/declining stocks) is the one other reading this shape
  /// fits, and overrides these four instead of duplicating the whole widget.
  final String centerLabel;
  final String primaryLabel;
  final String secondaryLabel;
  final String neutralLabel;

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
                          fontSize: AppTextScale.page,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                          semanticsLabel:
                              '${share.round()} percent '
                              '${centerLabel.toLowerCase()}, $advances '
                              '${primaryLabel.toLowerCase()}, $declines '
                              '${secondaryLabel.toLowerCase()}, $unchanged '
                              '${neutralLabel.toLowerCase()}',
                        ),
                        const SizedBox(height: 2),
                        Text(centerLabel, style: AppTypo.label(t)),
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
              _LegendKey(
                color: t.positive,
                label: primaryLabel,
                value: advances,
              ),
              const SizedBox(width: AppSpace.md),
              _LegendKey(
                color: t.negative,
                label: secondaryLabel,
                value: declines,
              ),
              if (unchanged > 0) ...[
                const SizedBox(width: AppSpace.md),
                _LegendKey(
                  color: t.foregroundSubtle,
                  label: neutralLabel,
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

/// The end-cap dot's radius: exactly half the stroke's thickness, so the dot
/// is flush with the arc's own width — clearly heavier than the hollow marker
/// it replaces, but adding no overhang beyond what the stroke already draws,
/// so the gauge's layout box and anything that clips to it are unaffected.
double _gaugeMarkerRadius(double thickness) => thickness / 2;

/// The sentiment reading as a 180° gauge (Spec §12.2): 176px wide, 11px thick,
/// a `surfaceSunken` track with a flat (non-gradient) fill to `score/100` of
/// the arc, and a solid end-cap dot at the reading — same colour as the fill
/// and as wide as the stroke itself, so it reads as the arc's terminus.
///
/// The band is named in a small pill beneath the arc (`accentInk` text on an
/// `accentSoft` fill by default). The score is spelled out inside the arc, so
/// the reading survives with the arc, its colour, or both removed.
///
/// When a caller passes a directional [tone] (a bearish reading tinted
/// [AppThemeTokens.negative], say) the fill, end-cap and pill all follow it —
/// the gauge never shows a red arc under a green "STRONG" label.
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
    // Default: the spec's `accentInk` on `accentSoft`. A directional tone
    // gets a soft wash of itself instead so the pill never contradicts the
    // arc above it.
    final directional = tone;
    final pillFg = directional ?? t.accentInk;
    final pillBg = directional == null
        ? t.accentSoft
        : directional.withValues(alpha: 0.14);
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
                              fontSize: AppTextScale.hero,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                band.toUpperCase(),
                style: AppTypo.label(t, color: pillFg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
    required this.thickness,
  });

  final double value;
  final Color fill;
  final Color track;
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
    // A solid end-cap in the fill's own colour.
    canvas.drawCircle(at, _gaugeMarkerRadius(thickness), Paint()..color = fill);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) {
    return old.value != value ||
        old.fill != fill ||
        old.track != track ||
        old.thickness != thickness;
  }
}

// ─── VolatilityBars ────────────────────────────────────────────────────────

/// ATR% distribution across the tracked universe, as a small bar histogram
/// (Insights: `GET /api/insights/volatility`).
///
/// No existing widget in this file has this shape — it isn't radial like the
/// three above it — so this is hand-painted from scratch, but keeps this
/// file's rules: tokens only, no gridlines or third-party chart package, and
/// the same `_DrawOn` draw-on used everywhere else here.
///
/// Volatility has no "direction" the way breadth or momentum do — a wide
/// ATR% bucket isn't bullish or bearish — so bars use the brand accent
/// rather than [AppThemeTokens.positive]/[negative], the same call
/// [SentimentGauge] makes for its own non-directional fill.
class VolatilityBars extends StatelessWidget {
  const VolatilityBars({
    super.key,
    required this.buckets,
    this.barMaxHeight = 76,
  });

  /// Ordered bucket label → stock count, e.g. {"0-1%": 120, "1-2%": 90, ...}.
  final Map<String, int> buckets;
  final double barMaxHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final maxCount = buckets.values.fold<int>(0, math.max);

    return _DrawOn(
      builder: (context, progress) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in buckets.entries) ...[
            Expanded(
              child: _VolatilityBar(
                label: entry.key,
                count: entry.value,
                fraction: maxCount == 0 ? 0.0 : entry.value / maxCount,
                progress: progress,
                barMaxHeight: barMaxHeight,
                fill: t.accent,
                track: t.surfaceSunken,
              ),
            ),
            if (entry.key != buckets.keys.last)
              const SizedBox(width: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _VolatilityBar extends StatelessWidget {
  const _VolatilityBar({
    required this.label,
    required this.count,
    required this.fraction,
    required this.progress,
    required this.barMaxHeight,
    required this.fill,
    required this.track,
  });

  final String label;
  final int count;

  /// This bucket's share of the tallest bucket, 0..1.
  final double fraction;

  /// The shared draw-on progress, 0..1.
  final double progress;
  final double barMaxHeight;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final drawnFraction = (fraction * progress).clamp(0.0, 1.0);
    // A bucket with any stocks in it still shows a sliver — a real zero-height
    // bar and "there are stocks here, just very few" must not look the same.
    final barHeight = count > 0
        ? math.max(4.0, barMaxHeight * drawnFraction)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Figure.static(
          '$count',
          fontSize: AppTextScale.hint,
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xxs),
        SizedBox(
          height: barMaxHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Track: the full-height backdrop every bucket sits in, so an
              // empty bucket is still visibly "a column with nothing in it"
              // rather than absent.
              Container(
                width: double.infinity,
                height: barMaxHeight,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(AppRadius.chip / 2),
                ),
              ),
              Container(
                width: double.infinity,
                height: barHeight,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppRadius.chip / 2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          label,
          style: AppTypo.label(t),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── VolumeSurgeLeaderboard ────────────────────────────────────────────────

/// Top stocks by today's-volume ÷ 20-day-average, descending (Insights:
/// `GET /api/insights/volume-surge`) — a ranked horizontal-bar list.
///
/// Another genuinely new shape: not radial, and not a histogram either (each
/// row is its own independently-scaled magnitude, ranked, with a symbol
/// rather than a bucket label). The backend supplies no per-row direction —
/// a volume surge isn't itself bullish or bearish — so bars use the brand
/// accent, same reasoning as [VolatilityBars].
class VolumeSurgeLeaderboard extends StatelessWidget {
  const VolumeSurgeLeaderboard({
    super.key,
    required this.rows,
    this.onTap,
  });

  /// Already ranked (descending) by the caller/backend — this widget does
  /// not re-sort, so a caller that wants a different order controls it.
  final List<VolumeSurgeRow> rows;
  final ValueChanged<VolumeSurgeRow>? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final maxSurge = rows.fold<double>(
      0,
      (max, r) => math.max(max, r.surge.toDouble()),
    );

    return _DrawOn(
      builder: (context, progress) => Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const HairlineDivider(),
            _VolumeSurgeRowTile(
              rank: i + 1,
              row: row,
              fraction: maxSurge <= 0 ? 0.0 : row.surge / maxSurge,
              progress: progress,
              fill: t.accent,
              track: t.surfaceSunken,
              onTap: onTap == null ? null : () => onTap!(row),
            ),
          ],
        ],
      ),
    );
  }
}

class _VolumeSurgeRowTile extends StatelessWidget {
  const _VolumeSurgeRowTile({
    required this.rank,
    required this.row,
    required this.fraction,
    required this.progress,
    required this.fill,
    required this.track,
    this.onTap,
  });

  final int rank;
  final VolumeSurgeRow row;
  final double fraction;
  final double progress;
  final Color fill;
  final Color track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final drawnFraction = (fraction * progress).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.hairlineRowPadding,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: AppTypo.hint(t, color: t.foregroundSubtle),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.symbol,
                    style: AppTypo.rowLabel(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  // The bar itself: a thin track with a proportional fill,
                  // same visual language as ProgressRule but per-row-scaled
                  // rather than 0..1 against a fixed total.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.chip / 2),
                    child: SizedBox(
                      height: 5,
                      child: Stack(
                        children: [
                          Container(color: track),
                          FractionallySizedBox(
                            widthFactor: drawnFraction,
                            child: Container(color: fill),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            ShrinkTrailing(
              child: Figure.static(
                '${row.surge.toStringAsFixed(1)}×',
                fontSize: AppTextScale.rowLabel,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}