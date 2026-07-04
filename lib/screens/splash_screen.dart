import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AyreSplashScreen extends StatefulWidget {
  const AyreSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<AyreSplashScreen> createState() => _AyreSplashScreenState();
}

class _AyreSplashScreenState extends State<AyreSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: AppMotion.splash,
      vsync: this,
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.08), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4)),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)),
    );

    _ctrl.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = MediaQuery.sizeOf(context);
    final shortest = math.min(size.width, size.height);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tokens.background, tokens.backgroundTint],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            child: _LogoContent(tokens: tokens, shortest: shortest),
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value * _fadeOut.value,
                child: Transform.scale(scale: _logoScale.value, child: child),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoContent extends StatelessWidget {
  const _LogoContent({required this.tokens, required this.shortest});

  final AppThemeTokens tokens;
  final double shortest;

  @override
  Widget build(BuildContext context) {
    final logoSize = shortest * 0.26;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [tokens.primary, tokens.accentCool],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.primary.withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Icon(Icons.radar_rounded, color: tokens.onPrimary, size: logoSize * 0.55),
        ),
        const SizedBox(height: 28),
        Text(
          'Ayre Scanner',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Market Intelligence',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
        ),
      ],
    );
  }
}