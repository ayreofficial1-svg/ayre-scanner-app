import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.bottomSafe = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool bottomSafe;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.background,
            Color.lerp(tokens.backgroundTint, tokens.accentWarm, 0.1)!,
            Color.lerp(tokens.backgroundTint, tokens.accentCool, 0.14)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _AmbientShapes()),
          SafeArea(
            bottom: bottomSafe,
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.xl,
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
        color:
            borderColor ??
            Colors.white.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.06
                  : 0.58,
            ),
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? tokens.shadowLg.withValues(alpha: 0.28),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: Colors.white.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.02 : 0.4,
          ),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    );
    final body = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: decoration,
      child: clip
          ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: body)
          : body,
    );
  }
}

class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48,
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
        child: Ink(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? tokens.surface.withValues(alpha: 0.76),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
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

class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 24),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow + delay,
      curve: AppMotion.ease,
      builder: (context, value, child) {
        final delayed =
            (delay == Duration.zero
                    ? value
                    : ((value -
                                  delay.inMilliseconds /
                                      (AppMotion.slow + delay).inMilliseconds) /
                              (1 -
                                  delay.inMilliseconds /
                                      (AppMotion.slow + delay).inMilliseconds))
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

class FloatingOrb extends StatefulWidget {
  const FloatingOrb({
    super.key,
    required this.child,
    this.distance = 8,
    this.duration = const Duration(milliseconds: 2200),
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
            math.sin(_controller.value * math.pi) * -widget.distance,
          ),
          child: child,
        );
      },
    );
  }
}

class PremiumLoader extends StatelessWidget {
  const PremiumLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumScaffold(
      child: Center(
        child: FloatingOrb(
          child: PremiumCard(
            radius: AppRadius.xl,
            padding: const EdgeInsets.all(22),
            gradient: AppGradients.surfaceGlass(tokens),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 42,
                  width: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: tokens.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w800,
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

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.color,
    this.height = 72,
    this.points = const [
      0.62,
      0.42,
      0.48,
      0.34,
      0.52,
      0.46,
      0.22,
      0.28,
      0.18,
      0.52,
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

class _AmbientShapes extends StatelessWidget {
  const _AmbientShapes();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -96,
              right: -80,
              child: _BlurCircle(
                size: 260,
                color: tokens.accentWarm.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              top: 170,
              left: -110,
              child: _BlurCircle(
                size: 260,
                color: tokens.accentCool.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              bottom: 90,
              right: -120,
              child: _BlurCircle(
                size: 300,
                color: tokens.primary.withValues(alpha: 0.14),
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
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
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
      final y = points[i].clamp(0.0, 1.0) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final px = (i - 1) / (points.length - 1) * size.width;
        final py = points[i - 1].clamp(0.0, 1.0) * size.height;
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
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.points != points;
  }
}
