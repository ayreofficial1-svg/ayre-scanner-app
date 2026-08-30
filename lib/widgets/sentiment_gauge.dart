import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'instrument_marks.dart';
import 'numeral.dart';
import 'spring.dart';

/// A real needle-and-dial pressure gauge: a near-semicircular dial face with
/// fine engraved calibration ticks, a thin index needle, and the reading set in
/// the instrument-readout monospace.
///
/// The needle *sweeps* from its previous reading to the new one on a critically
/// damped spring — the app's clearest expression of the instrument idea, and
/// the one place `primary` is allowed to double as a data indicator, because
/// here the needle genuinely is both the brand mark and the reading.
class SentimentGauge extends StatelessWidget {
  const SentimentGauge({
    super.key,
    required this.value,
    required this.label,
    this.tone,
    this.height = 210,
  });

  /// 0–100.
  final int value;

  /// The band the reading falls in: CAUTION / NEUTRAL / STRONG.
  final String label;

  /// The semantic color for the current band. The needle takes this; the dial
  /// face and ticks stay neutral.
  final Color? tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final needleTone = tone ?? tokens.primary;

    return SizedBox(
      height: height,
      child: SpringValue(
        value: value / 100,
        spring: AppSpring.needle,
        animateOnMount: true,
        builder: (context, progress, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DialPainter(
                    progress: progress.clamp(0.0, 1.0),
                    needleColor: needleTone,
                    tokens: tokens,
                    dialFace: AppSurfaces.dialFace(tokens),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Numeral(
                      '$value',
                      value: value.toDouble(),
                      format: (v) => v.round().toString(),
                      fontSize: 46,
                      fontWeight: FontWeight.w400,
                      color: tokens.textPrimary,
                      semanticsLabel: 'Sentiment score $value of 100, $label',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label.toUpperCase(),
                      style: AppTypo.microLabel(tokens, color: needleTone),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.progress,
    required this.needleColor,
    required this.tokens,
    required this.dialFace,
  });

  final double progress;
  final Color needleColor;
  final AppThemeTokens tokens;
  final Gradient dialFace;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 18);
    final r = math.min(size.width / 2 - 8, size.height - 30);
    if (r <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: r);

    // Dial face: a flat, shaded plate. This gradient is sanctioned — it shades
    // a dial for depth, it isn't atmosphere behind a hero.
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      true,
      Paint()..shader = dialFace.createShader(rect),
    );

    final hairline = Paint()
      ..color = tokens.engraved
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dial rim and the inner reference arc the needle reads against.
    canvas.drawArc(rect, math.pi, math.pi, false, hairline);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.62),
      math.pi,
      math.pi,
      false,
      hairline,
    );
    canvas.drawLine(
      Offset(center.dx - r, center.dy),
      Offset(center.dx + r, center.dy),
      hairline,
    );

    // Engraved calibration: 41 ticks across the sweep, every fifth one long.
    const ticks = 41;
    for (var i = 0; i < ticks; i++) {
      final t = i / (ticks - 1);
      final a = math.pi + math.pi * t;
      final major = i % 5 == 0;
      final inner = r * (major ? 0.78 : 0.86);
      final paint = Paint()
        ..color = major ? tokens.engraved : tokens.engraved.withValues(alpha: 0.55)
        ..strokeWidth = major ? 1.4 : 1;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * (r - 1), math.sin(a) * (r - 1)),
        paint,
      );
    }

    // The needle: a fine index line with a counterweight tail and a hub.
    final a = math.pi + math.pi * progress;
    final tip = center + Offset(math.cos(a) * r * 0.80, math.sin(a) * r * 0.80);
    final tail = center - Offset(math.cos(a) * r * 0.13, math.sin(a) * r * 0.13);
    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawCircle(center, 5, Paint()..color = tokens.surfaceRaised);
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = needleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) {
    return old.progress != progress || old.needleColor != needleColor;
  }
}

/// The dial housing: the gauge sits in a chamfered plate, the shape system's
/// second voice, reserved for instrument-coded elements like this one.
class GaugeHousing extends StatelessWidget {
  const GaugeHousing({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.surface,
      shape: ChamferedBorder(
        cut: AppRadius.chamfer,
        side: BorderSide(color: tokens.border),
        corners: const {ChamferCorner.topRight, ChamferCorner.bottomLeft},
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
