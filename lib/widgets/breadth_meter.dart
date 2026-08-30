import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'figure.dart';
import 'spring.dart';

/// Market sentiment as a horizontal meter readout — a filled bar against a
/// labelled scale with the reading in the ticker face.
///
/// Deliberately not a dial, gauge or needle: that motif belonged to the previous
/// identity and is retired. The marker slides on a critically-damped spring when
/// the reading changes, so a new value is legible as movement without overshoot.
class BreadthMeter extends StatelessWidget {
  const BreadthMeter({
    super.key,
    required this.value,
    required this.band,
    this.tone,
  });

  /// 0..100
  final int value;

  /// The band this reading falls in — CAUTION / NEUTRAL / STRONG.
  final String band;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = tone ?? t.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Figure(
              '$value',
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
              semanticsLabel: 'Sentiment $value of 100, $band',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5, left: 2),
              child: Text('/100', style: AppTypo.valueSmall(t)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                band.toUpperCase(),
                style: AppTypo.label(t, color: accent, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 22,
          child: SpringValue(
            value: value / 100,
            animateOnMount: true,
            from: 0,
            spring: AppSpring.standard,
            builder: (context, progress, _) => CustomPaint(
              painter: _MeterPainter(
                progress: progress.clamp(0.0, 1.0),
                fill: accent,
                track: t.surfaceAlt,
                tick: t.chartGrid,
                edge: t.border,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // A labelled scale, so the number has somewhere to sit.
        Row(
          children: [
            Text('0 BEARISH', style: AppTypo.label(t)),
            const Spacer(),
            Text('50', style: AppTypo.label(t)),
            const Spacer(),
            Text('BULLISH 100', style: AppTypo.label(t)),
          ],
        ),
      ],
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({
    required this.progress,
    required this.fill,
    required this.track,
    required this.tick,
    required this.edge,
  });

  final double progress;
  final Color fill;
  final Color track;
  final Color tick;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    const barHeight = 10.0;
    final top = (size.height - barHeight) / 2;
    final rect = Rect.fromLTWH(0, top, size.width, barHeight);
    final radius = const Radius.circular(AppRadius.chip);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = track,
    );

    // Scale graduations behind the fill — the "labelled scale" of a readout.
    final tickPaint = Paint()
      ..color = tick
      ..strokeWidth = 1;
    for (var i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, top), Offset(x, top + barHeight), tickPaint);
    }

    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, size.width * progress, barHeight),
          radius,
        ),
        Paint()..color = fill,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // The reading marker: a full-height index line at the current value.
    final x = (size.width * progress).clamp(1.0, size.width - 1);
    canvas.drawRect(
      Rect.fromLTWH(x - 1, 0, 2, size.height),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) {
    return old.progress != progress ||
        old.fill != fill ||
        old.track != track ||
        old.tick != tick ||
        old.edge != edge;
  }
}
