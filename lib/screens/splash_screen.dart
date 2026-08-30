import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/instrument_marks.dart';
import '../widgets/premium_widgets.dart';

class AyreSplashScreen extends StatefulWidget {
  const AyreSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<AyreSplashScreen> createState() => _AyreSplashScreenState();
}

class _AyreSplashScreenState extends State<AyreSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _introScale;
  late final Animation<double> _introOpacity;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.splash);
    // Was easeOutBack, which overshot and contradicted the app-wide no-bounce
    // rule. Same duration, standard deceleration.
    _introScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.60, curve: Curves.easeOutCubic),
    );
    _introOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.40, curve: Curves.easeOutCubic),
    );
    _exit = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1, curve: Curves.easeInCubic),
      ),
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
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: PremiumScaffold(
        section: AyreSection.home,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: reduceMotion ? 1 : _introOpacity.value * _exit.value,
                child: Transform.scale(
                  scale: reduceMotion ? 1 : 0.90 + _introScale.value * 0.10,
                  child: _SplashMark(
                    tokens: tokens,
                    // One slow-rotating needle, critically damped and never
                    // overshooting, in place of the retired rotating gradient
                    // ring. The needle is the same motif as the nav's
                    // needle-mark and the gauge's needle.
                    needleAngle: reduceMotion
                        ? -math.pi / 4
                        : (Curves.easeOutCubic.transform(_controller.value) *
                                  math.pi *
                                  1.4) -
                              (math.pi / 2),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark({required this.tokens, required this.needleAngle});

  final AppThemeTokens tokens;
  final double needleAngle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BearingMark(
          color: tokens.engraved,
          size: 168,
          needleColor: tokens.primary,
          needleAngle: needleAngle,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        // The wordmark: the second and last place the display serif carries a
        // brand moment on its own.
        Text(
          'Ayre Scanner',
          style: AppTypo.serif(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 8,
          width: 96,
          child: TickMarks(
            color: tokens.engraved,
            count: 17,
            length: 3,
            majorEvery: 8,
            majorLength: 8,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('MARKET INTELLIGENCE', style: AppTypo.microLabel(tokens)),
      ],
    );
  }
}
