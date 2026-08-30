import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Press feedback for every tappable surface: a 0.97 scale with no overshoot.
/// The interaction weight was already right — this only extends it to the
/// surfaces that lacked it, and adds a hover tint where a cursor exists.
///
/// Hover shifts the background tint only; it never scales, because a cursor
/// passing over a card isn't a press.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadius.md,
    this.scale = 0.97,
    this.hoverTint = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double scale;
  final bool hoverTint;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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
          hoverColor: widget.hoverTint
              ? tokens.primary.withValues(alpha: 0.05)
              : AppTheme.transparent,
          splashColor: tokens.primary.withValues(alpha: 0.06),
          highlightColor: tokens.primary.withValues(alpha: 0.03),
          child: widget.child,
        ),
      ),
    );
  }
}
