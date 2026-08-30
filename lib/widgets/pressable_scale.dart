import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Press feedback for every tappable surface: a 0.97 scale with no overshoot.
///
/// Hover shifts the background tint only and never scales, because a cursor
/// passing over a card is not a press.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadius.card,
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

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(widget.borderRadius);
    final enabled = widget.onTap != null;

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
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          borderRadius: radius,
          hoverColor: widget.hoverTint
              ? t.citrine.withValues(alpha: 0.06)
              : AppTheme.transparent,
          splashColor: t.citrine.withValues(alpha: 0.07),
          highlightColor: t.citrine.withValues(alpha: 0.04),
          child: widget.child,
        ),
      ),
    );
  }
}
