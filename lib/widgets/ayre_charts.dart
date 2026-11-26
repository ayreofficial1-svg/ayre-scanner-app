// The progress ring used by Learn.
//
// Hand-painted arc, not a chart package. It uses `_ArcGeometry` below rather
// than re-deriving cap compensation, because getting that wrong is invisible
// in code review and obvious on screen.
//
// It draws on over `AppMotion.chartDraw` and snaps to its final state under
// reduced motion. It never carries meaning in colour alone: the ring labels
// its percentage.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'figure.dart';
import 'responsive.dart';

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
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.chartDraw,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
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

  double diameterOf(BuildContext context) {
    if (!showPercent || label != null) return size;

    final metrics = measureText(
      context,
      '100%',
      AppTypo.num(
        fontSize: size * 0.24,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    );
    final diagonal = math.sqrt(
      metrics.width * metrics.width + metrics.height * metrics.height,
    );
    return math.max(size, diagonal + 2 * (thickness + 2));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final clamped = value.clamp(0.0, 1.0);
    final fill = _complete ? t.positive : t.accent;

    final caption =
        label ??
        (showPercent
            ? CountUpFigure(
                value: clamped * 100,
                format: (v) => '${v.round()}%',
                fontSize: size * 0.24,
                fontWeight: FontWeight.w600,
                color: _complete ? t.positiveText : t.textPrimary,
                textAlign: TextAlign.center,
                semanticsLabel: '${(clamped * 100).round()} percent complete',
              )
            : null);
    final preferredDiameter = diameterOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(preferredDiameter, constraints.maxWidth);
        final fitsInside = diameter >= preferredDiameter;
        final ring = SizedBox.square(
          dimension: diameter,
          child: _DrawOn(
            builder: (context, progress) => CustomPaint(
              painter: _RingPainter(
                value: clamped * progress,
                fill: fill,
                track: t.surfaceRaised,
                thickness: thickness,
              ),
              child: fitsInside ? Center(child: caption) : null,
            ),
          ),
        );
        if (fitsInside || caption == null) return ring;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ring,
            const SizedBox(height: AppSpace.xxs),
            caption,
          ],
        );
      },
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
