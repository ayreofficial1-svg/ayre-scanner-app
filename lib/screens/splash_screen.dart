import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The brand mark: three ascending bars on a baseline rule, drawn in Citrine —
/// the same shape family as the Signals glyph, so the wordmark and the app's
/// iconography read as one identity.
///
/// The bars rise on load, once, with no overshoot. No rotating ring, no gradient
/// sweep, no gauge — none of that survives from the previous identity.
class AyreSplashScreen extends StatefulWidget {
  const AyreSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<AyreSplashScreen> createState() => _AyreSplashScreenState();
}

class _AyreSplashScreenState extends State<AyreSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _controller.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: t.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final rise = reduceMotion
                ? 1.0
                : AppMotion.ease.transform(
                    (_controller.value / 0.7).clamp(0.0, 1.0),
                  );
            final fade = reduceMotion
                ? 1.0
                : ((_controller.value - 0.2) / 0.4).clamp(0.0, 1.0);
            final exit = reduceMotion
                ? 1.0
                : 1 - ((_controller.value - 0.86) / 0.14).clamp(0.0, 1.0);

            return Opacity(
              opacity: exit,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 68,
                    width: 84,
                    child: CustomPaint(
                      painter: _MarkPainter(
                        rise: rise,
                        color: t.citrine,
                        rule: t.hairline,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Opacity(
                    opacity: fade,
                    child: Column(
                      children: [
                        Text(
                          'AYRE SCANNER',
                          style: AppTypo.display(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                            letterSpacing: 3.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'MARKET TERMINAL',
                          style: AppTypo.label(t, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.rise,
    required this.color,
    required this.rule,
  });

  /// 0..1 — how far the bars have risen.
  final double rise;
  final Color color;
  final Color rule;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 1;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = rule
        ..strokeWidth = 1,
    );

    const heights = [0.46, 0.78, 1.0];
    final barWidth = size.width / 7;
    final paint = Paint()..color = color;

    for (var i = 0; i < heights.length; i++) {
      // Later bars start a beat after the earlier ones.
      final staged = ((rise - i * 0.12) / (1 - 0.24)).clamp(0.0, 1.0);
      final height = size.height * heights[i] * staged;
      if (height <= 0) continue;
      final left = barWidth * (1 + i * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, baseline - height, left + barWidth, baseline),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.rise != rise || old.color != color || old.rule != rule;
}
