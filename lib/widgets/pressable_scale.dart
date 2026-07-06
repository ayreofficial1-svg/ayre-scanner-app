import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadius.md,
    this.scale = 0.97, // Subtle scale (Apple standard is around 0.97-0.98)
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    return AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.ease, // Snappy ease out
      child: Material(
        color: AppTheme.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => _pressed = true),
          onTapUp: widget.onTap == null
              ? null
              : (_) => setState(() => _pressed = false),
          onTapCancel: widget.onTap == null
              ? null
              : () => setState(() => _pressed = false),
          borderRadius: radius,
          splashColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.05),
          highlightColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.02),
          child: widget.child,
        ),
      ),
    );
  }
}
