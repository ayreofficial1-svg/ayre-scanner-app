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
              ? t.accent.withValues(alpha: 0.06)
              : AppTheme.transparent,
          splashColor: t.accent.withValues(alpha: 0.07),
          highlightColor: t.accent.withValues(alpha: 0.04),
          child: widget.child,
        ),
      ),
    );
  }
}
/// A row-shaped tap target with press feedback and no rounded clip of its own,
/// so it sits flush inside a [RowGroup] or a card.
///
/// Moved here in Phase 5 from `learn_tab.dart`, where it was a public class
/// living inside a screen file. Signals' compact list needs the same
/// behaviour, and the alternative — importing a screen to reach a widget —
/// is the kind of dependency that turns a screen rebuild into a cascade.
/// Deliberately not [PressableScale]: that one scales and clips to a radius,
/// which pulls a row visibly away from the hairline dividers above and below
/// it. A row presses by tinting, not by shrinking.
class PressableScaleRow extends StatelessWidget {
  const PressableScaleRow({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: t.accent.withValues(alpha: 0.05),
        splashColor: t.accent.withValues(alpha: 0.06),
        highlightColor: t.accent.withValues(alpha: 0.03),
        child: child,
      ),
    );
  }
}