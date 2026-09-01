import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ayre_logo.dart';

/// The splash screen: the logo's primary and most prominent placement.
///
/// The mark is the supplied brand asset, centred and generously sized with clear
/// space around it — not a recreation, and not scaled to fill the screen. The
/// previous identity's hand-drawn bar mark is gone: there is a real logo now.
///
/// Motion is a single quiet settle. Nothing rotates, sweeps or bounces.
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
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (reduceMotion) return child!;
            // A short rise and fade in, then a fade out as the app takes over.
            final enter = AppMotion.ease.transform(
              (_controller.value / 0.45).clamp(0.0, 1.0),
            );
            final exit =
                1 - ((_controller.value - 0.88) / 0.12).clamp(0.0, 1.0);
            return Opacity(
              opacity: enter * exit,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - enter)),
                child: child,
              ),
            );
          },
          child: const _SplashMark(),
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
        const SizedBox(height: AppSpace.md),
        Text('MARKET TERMINAL', style: AppTypo.label(t)),
      ],
    );
  }
}
