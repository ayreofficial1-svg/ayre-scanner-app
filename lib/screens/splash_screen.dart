import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
  late final Animation<double> _intro;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.splash);
    _intro = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.66, curve: Curves.easeOutBack),
    );
    _exit = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1, curve: Curves.easeInCubic),
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
    return Scaffold(
      body: PremiumScaffold(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _exit.value,
                child: Transform.scale(
                  scale: 0.72 + _intro.value * 0.28,
                  child: _SplashMark(
                    tokens: tokens,
                    rotation: _controller.value * math.pi * 2,
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
  const _SplashMark({required this.tokens, required this.rotation});

  final AppThemeTokens tokens;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 172,
          width: 172,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: rotation,
                child: Container(
                  height: 168,
                  width: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        tokens.accentWarm,
                        tokens.primary,
                        tokens.accentCool,
                        tokens.accentWarm,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withValues(alpha: 0.34),
                        blurRadius: 42,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 126,
                width: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.surface,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.radar_rounded,
                  color: tokens.primary,
                  size: 58,
                ),
              ),
              Positioned(
                right: 12,
                top: 20,
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.accentWarm,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                bottom: 18,
                child: Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.accentCool,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Ayre Scanner',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: tokens.neutralBlock,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            'Market Intelligence',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tokens.onNeutralBlock,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
