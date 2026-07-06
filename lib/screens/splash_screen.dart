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
  late final Animation<double> _introScale;
  late final Animation<double> _introOpacity;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.splash);
    _introScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.60, curve: Curves.easeOutBack),
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
    return Scaffold(
      body: PremiumScaffold(
        section: AyreSection.home,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _introOpacity.value * _exit.value,
                child: Transform.scale(
                  scale: 0.85 + _introScale.value * 0.15, // Softer zoom
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
          height: 180,
          width: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: rotation,
                child: Container(
                  height: 172,
                  width: 172,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        tokens.primary,
                        tokens.teal,
                        tokens.accentMint,
                        tokens.primary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 132,
                width: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.surface,
                  border: Border.all(
                    color: tokens.borderSubtle,
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.radar_rounded,
                  color: tokens.primary,
                  size: 64,
                ),
              ),
              Positioned(
                right: 14,
                top: 24,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.teal,
                    border: Border.all(color: tokens.surface, width: 3),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                bottom: 22,
                child: Container(
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.accentMint,
                    border: Border.all(color: tokens.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'Ayre Scanner',
          style: AppTypo.pageTitle(tokens),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: tokens.neutralBlock,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Market Intelligence',
            style: AppTypo.eyebrow(tokens, color: tokens.onNeutralBlock),
          ),
        ),
      ],
    );
  }
}
