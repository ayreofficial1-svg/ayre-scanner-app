import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadius.lg,
    this.scale = 0.96,
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
      curve: AppMotion.ease,
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
          ).colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: AppTheme.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}
