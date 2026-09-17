import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Critically-damped spring specs (damping ratio 1.0 — resolves straight to
/// target, zero overshoot). Used for value re-targeting (breadth readouts,
/// count-adjacent figures) where the Spec has no opinion and "settles like an
/// eased curve, never bounces" is the right default.
///
/// These settle much like an eased curve; the difference shows when an animation
/// is interrupted mid-flight and has to re-target from its current position *and
/// velocity* rather than restarting. That is what makes a re-targeted value feel
/// weighted when it changes twice quickly, rather than restarting from zero.
abstract final class AppSpring {
  static final SpringDescription snappy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 560,
    ratio: 1.0,
  );

  static final SpringDescription standard = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 320,
    ratio: 1.0,
  );

  /// Retained for any remaining call site not yet reconciled against a named
  /// v4 spring — identical to [standard].
  static final SpringDescription fold = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 240,
    ratio: 1.0,
  );

  // ── v4 Spec springs (nav pill, segmented, toggle) ─────────────────────────
  //
  // Plan §7 open decision #3: the Spec's `stiffness`/`damping` pairs are
  // authored against Framer Motion's model, which is NOT parameterized the
  // same way as Flutter's `SpringDescription(mass, stiffness, damping)` in
  // general — Framer's `damping` is a linear viscous-damping coefficient in
  // its own unit convention, and a literal pass-through is not guaranteed to
  // land at the same damping ratio in another physical-spring implementation.
  // Verified numerically here rather than assumed:
  //
  //   nav/segmented (stiffness 480, damping 38, mass 1):
  //     ζ (damping ratio) ≈ 0.87, settle-to-2% ≈ 0.21s, peak overshoot ≈ 0.4%
  //   toggle (stiffness 500, damping 34, mass 1):
  //     ζ ≈ 0.76, settle-to-2% ≈ 0.23s, peak overshoot ≈ 2.5%
  //
  // Both land underdamped-but-essentially-non-bouncy (ζ < 1, overshoot under
  // 3%) with a sub-quarter-second settle — this reads as "glides smoothly, no
  // bounce" per the Spec's own description, not as a spring with a visible
  // wobble. On that basis the literal values are used as-is via
  // `SpringDescription(mass, stiffness, damping)` rather than re-derived from
  // a damping ratio — re-verify visually once these drive a real widget
  // (nav pill lands in Phase 2; segmented/toggle retint lands in this phase).
  static const SpringDescription navPill = SpringDescription(
    mass: 1,
    stiffness: 480,
    damping: 38,
  );
  static const SpringDescription toggleKnob = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 34,
  );
}

/// Drives a single `double` toward [value] on a critically-damped spring,
/// re-targeting smoothly (carrying current velocity) whenever [value] changes
/// mid-flight. Under reduced motion the value snaps, so the information still
/// arrives — only the way it communicates changes.
class SpringValue extends StatefulWidget {
  const SpringValue({
    super.key,
    required this.value,
    required this.builder,
    this.spring,
    this.animateOnMount = false,
    this.from = 0.0,
    this.child,
  });

  final double value;
  final Widget Function(BuildContext context, double value, Widget? child)
  builder;
  final SpringDescription? spring;

  /// When false (the default) the first frame renders at [value] rather than
  /// animating in — first load shouldn't look like an update.
  final bool animateOnMount;
  final double from;
  final Widget? child;

  @override
  State<SpringValue> createState() => _SpringValueState();
}

class _SpringValueState extends State<SpringValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
      value: widget.animateOnMount ? widget.from : widget.value,
    );
    if (widget.animateOnMount) {
      // MediaQuery isn't readable in initState — retarget on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _retarget();
      });
    }
  }

  @override
  void didUpdateWidget(SpringValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _retarget();
  }

  void _retarget() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = widget.value;
      return;
    }
    _controller.animateWith(
      SpringSimulation(
        widget.spring ?? AppSpring.standard,
        _controller.value,
        widget.value,
        _controller.velocity,
      ),
    );
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
      builder: (context, child) =>
          widget.builder(context, _controller.value, child),
    );
  }
}