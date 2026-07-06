import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Scaffold with per-section gradient background + decorative blobs.
class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.child,
    this.section = AyreSection.home,
    this.padding = EdgeInsets.zero,
    this.bottomSafe = true,
  });

  final Widget child;
  final AyreSection section;
  final EdgeInsetsGeometry padding;
  final bool bottomSafe;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.screenBg(section, brightness),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _AmbientShapes(section: section)),
          SafeArea(
            bottom: bottomSafe,
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

/// Frosted card with design-system-compliant borders, shadows, rounded corners.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.card,
    this.gradient,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final Color? shadowColor;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final decoration = BoxDecoration(
      color: gradient == null ? color ?? tokens.surface : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? tokens.borderSubtle,
        width: 1.0, // Thicker, subtle border for premium feel
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? tokens.shadow,
          blurRadius: 32, // Softer, larger shadow
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
      ],
    );
    final body = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: decoration,
      child: clip
          ? ClipRRect(borderRadius: BorderRadius.circular(radius - 1), child: body)
          : body,
    );
  }
}

/// The signature Aura Halo glow behind hero metrics.
class AuraHalo extends StatefulWidget {
  const AuraHalo({
    super.key,
    required this.color,
    this.size = 200,
    this.child,
  });

  final Color color;
  final double size;
  final Widget? child;

  @override
  State<AuraHalo> createState() => _AuraHaloState();
}

class _AuraHaloState extends State<AuraHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.auraPulse,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = reduceMotion ? 0.5 : _controller.value;
        final scale = 1.0 + 0.08 * math.sin(t * math.pi); // Smoother pulsing
        final opacity = 0.5 + 0.2 * math.cos(t * math.pi);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: opacity),
                      widget.color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            if (child != null) child,
          ],
        );
      },
    );
  }
}

/// Glass circle button for icon actions.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: AppTheme.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: tokens.primary.withValues(alpha: 0.1),
        highlightColor: tokens.primary.withValues(alpha: 0.05),
        child: Ink(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? tokens.paper,
            border: Border.all(color: tokens.borderSubtle, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor ?? tokens.textPrimary,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}

/// Staggered fade + upward slide entrance animation.
class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 16),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.cardEntrance + delay,
      curve: AppMotion.ease,
      builder: (context, value, child) {
        final totalMs = (AppMotion.cardEntrance + delay).inMilliseconds;
        final delayMs = delay.inMilliseconds;
        final delayed = (delay == Duration.zero
                ? value
                : ((value - delayMs / totalMs) / (1 - delayMs / totalMs))
                    .clamp(0.0, 1.0))
            .toDouble();
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - delayed),
              offset.dy * (1 - delayed),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Floating bob animation for decorative elements.
class FloatingOrb extends StatefulWidget {
  const FloatingOrb({
    super.key,
    required this.child,
    this.distance = 8, // slightly more float
    this.duration = const Duration(milliseconds: 3000), // smoother float
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<FloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            // Use sin with easeInOut logic
            Curves.easeInOutSine.transform(_controller.value) * -widget.distance,
          ),
          child: child,
        );
      },
    );
  }
}

/// Loading state with floating card.
class PremiumLoader extends StatelessWidget {
  const PremiumLoader({super.key, this.label, this.section = AyreSection.home});

  final String? label;
  final AyreSection section;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumScaffold(
      section: section,
      child: Center(
        child: FloatingOrb(
          child: PremiumCard(
            radius: AppRadius.heroCard,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            gradient: AppGradients.surfaceGlass(tokens),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  width: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: tokens.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    label!,
                    style: AppTypo.caption(tokens).copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini sparkline chart.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.color,
    this.height = 64,
    this.points = const [
      0.62, 0.42, 0.48, 0.34, 0.52, 0.46, 0.22, 0.28, 0.18, 0.52,
    ],
  });

  final Color color;
  final double height;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(color: color, points: points),
      ),
    );
  }
}

/// Decorative blurred blobs per section.
class _AmbientShapes extends StatelessWidget {
  const _AmbientShapes({required this.section});

  final AyreSection section;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blobOpacity = isDark ? 0.08 : 0.12; // More subtle blobs for a premium look

    final (Color c1, Color c2) = switch (section) {
      AyreSection.home => (tokens.primary, tokens.accentMint),
      AyreSection.signals => (tokens.accentMint, tokens.teal),
      AyreSection.insights => (tokens.accentCool, tokens.primary),
      AyreSection.learn => (tokens.gold, tokens.accentWarm),
      AyreSection.profile => (tokens.primary, tokens.accentCool),
    };

    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -80,
              child: _BlurCircle(
                size: 320,
                color: c1.withValues(alpha: blobOpacity),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -120,
              child: _BlurCircle(
                size: 380,
                color: c2.withValues(alpha: blobOpacity * 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72), // Softer blur
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color, required this.points});

  final Color color;
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = (1.0 - points[i].clamp(0.0, 1.0)) * size.height; // Invert Y axis
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final px = (i - 1) / (points.length - 1) * size.width;
        final py = (1.0 - points[i - 1].clamp(0.0, 1.0)) * size.height;
        path.cubicTo(px + size.width / 18, py, x - size.width / 18, y, x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 // Slightly thinner sparkline
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.points != points;
  }
}
