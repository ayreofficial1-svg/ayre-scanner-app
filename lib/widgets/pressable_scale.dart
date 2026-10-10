import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Press feedback for every tappable surface: a 0.97 scale with no overshoot
/// (suppressed under reduce-motion), a visible keyboard focus ring in
/// `accentInk`, and a hover tint that only a pointer device can produce.
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
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(widget.borderRadius);
    final enabled = widget.onTap != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // The ring only shows for keyboard / switch-access focus, never after a
    // touch or mouse press.
    final showRing =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    return AnimatedScale(
      scale: (_pressed && !reduceMotion) ? widget.scale : 1,
      duration: reduceMotion ? Duration.zero : AppMotion.fast,
      curve: AppMotion.ease,
      child: Container(
        foregroundDecoration: showRing
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: t.accentInk, width: 2),
              )
            : null,
        child: Material(
          color: AppTheme.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onFocusChange: _setFocused,
            borderRadius: radius,
            // Hover only reacts to a pointer device; touch never produces it.
            hoverColor: widget.hoverTint
                ? t.accent.withValues(alpha: 0.06)
                : AppTheme.transparent,
            focusColor: t.accent.withValues(alpha: 0.08),
            splashColor: t.accent.withValues(alpha: 0.07),
            highlightColor: t.accent.withValues(alpha: 0.04),
            child: widget.child,
          ),
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
class PressableScaleRow extends StatefulWidget {
  const PressableScaleRow({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressableScaleRow> createState() => _PressableScaleRowState();
}

class _PressableScaleRowState extends State<PressableScaleRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final showRing =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Container(
      foregroundDecoration: showRing
          ? BoxDecoration(border: Border.all(color: t.accentInk, width: 2))
          : null,
      child: Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (v) {
          if (_focused != v) setState(() => _focused = v);
        },
        focusColor: t.accent.withValues(alpha: 0.08),
        hoverColor: t.accent.withValues(alpha: 0.05),
        splashColor: t.accent.withValues(alpha: 0.06),
        highlightColor: t.accent.withValues(alpha: 0.03),
        child: widget.child,
      ),
    ),
    );
  }
}