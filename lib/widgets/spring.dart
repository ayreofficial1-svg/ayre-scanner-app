import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Critically-damped spring specs (damping ratio 1.0 — resolves straight to
/// target, zero overshoot).
///
/// These settle much like an eased curve; the difference shows when an animation
/// is interrupted mid-flight and has to re-target from its current position *and
/// velocity* rather than restarting. That is what makes the Fold's unfold feel
/// weighted when tapped twice quickly, and the breadth marker feel continuous
/// when a new reading lands mid-slide.
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

  /// The Fold's shape transition — deliberately the most considered motion in
  /// the app, so it gets its own slightly softer spring.
  static final SpringDescription fold = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 240,
    ratio: 1.0,
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
