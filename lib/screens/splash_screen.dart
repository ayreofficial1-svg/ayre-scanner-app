import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ayre_logo.dart';

/// The splash screen: the approved lockup centred on the page canvas with the
/// tagline beneath it and a short decorative track near the bottom.
///
/// No card, no gradient, nothing rotates or bounces. The track is a quiet
/// startup indicator, not a measured progress value: a 21px saffron segment
/// settles along a 55×4 track while the (unchanged) ~1s completion timer runs.
/// With reduced motion the mark and indicator are static.
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
      duration: const Duration(milliseconds: 1000),
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
      // Purely presentational and time-boxed — auto-dismisses via onFinished,
      // so screen readers should not announce it as content or a loading
      // state that outlives its ~1s visible duration.
      body: ExcludeSemantics(
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (reduceMotion) return child!;
                  // A short rise and fade in, then a fade out as the app
                  // takes over.
                  final enter = AppMotion.ease.transform(
                    (_controller.value / 0.45).clamp(0.0, 1.0),
                  );
                  final exit =
                      1 -
                      AppMotion.easeInOut.transform(
                        ((_controller.value - 0.81) / 0.19).clamp(0.0, 1.0),
                      );
                  return Opacity(
                    opacity: enter * exit,
                    child: Transform.translate(
                      offset: Offset(0, 6 * (1 - enter)),
                      child: child,
                    ),
                  );
                },
                child: const _SplashMark(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpace.s89 + MediaQuery.paddingOf(context).bottom,
              child: Center(
                child: _SplashTrack(
                  animation: reduceMotion ? null : _controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LogoMark(placement: LogoPlacement.splash),
        const SizedBox(height: AppSpace.s21),
        Text(
          'Market research and signals.',
          textAlign: TextAlign.center,
          style: AppTypo.ui(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.foregroundMuted,
          ),
        ),
      ],
    );
  }
}

/// 55×4 track (radius 2) with a 21×4 saffron leading segment.
class _SplashTrack extends StatelessWidget {
  const _SplashTrack({required this.animation});

  final Animation<double>? animation;

  static const double _width = 55;
  static const double _segment = 21;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget segment(double progress) => Positioned(
      left: (_width - _segment) * progress,
      top: 0,
      width: _segment,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.highlight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    return SizedBox(
      width: _width,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.splashTrack,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          children: [
            if (animation == null)
              segment(0)
            else
              AnimatedBuilder(
                animation: animation!,
                builder: (context, _) => Stack(
                  children: [
                    segment(AppMotion.easeInOut.transform(animation!.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
