import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/app_theme.dart';

/// Critically-damped spring specs (damping ratio 1.0 — resolves directly to
/// target, zero overshoot). These settle like `AppMotion.ease`; the difference
/// only shows up when an animation is interrupted mid-flight and has to
/// re-target from its current position *and velocity* instead of restarting.
///
/// Use these for gesture-driven and interruptible motion: sheet drags,
/// chart/gauge redraws mid-animation, the nav's needle-mark sliding between
/// tabs. Simple tap-triggered fades and slides stay on the duration tiers.
abstract final class AppSpring {
  static final SpringDescription snappy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 1.0,
  );

  static final SpringDescription standard = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 1.0,
  );

  /// The gauge needle's sweep — deliberately the slowest spring in the system,
  /// because it's the most-watched piece of motion in the app.
  static final SpringDescription needle = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 170,
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
      // MediaQuery isn't readable during initState — retarget on the next frame.
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

/// A mechanical digit-roll: the number travels through its intermediate values
/// to the new one, like an odometer settling. A settle, not a flourish —
/// skipped on first load and under reduced motion.
class RollingValue extends StatefulWidget {
  const RollingValue({
    super.key,
    required this.value,
    required this.builder,
    this.duration = AppMotion.settle,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  State<RollingValue> createState() => _RollingValueState();
}

class _RollingValueState extends State<RollingValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1.0;
  }

  @override
  void didUpdateWidget(RollingValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _from = widget.value;
      _to = widget.value;
      _controller.value = 1.0;
      return;
    }
    // Re-target from wherever the roll currently is, so a second update
    // landing mid-roll continues instead of jumping back.
    _from = _current;
    _to = widget.value;
    _controller.forward(from: 0);
  }

  double get _current {
    final t = AppMotion.ease.transform(_controller.value.clamp(0.0, 1.0));
    return _from + (_to - _from) * t;
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
      builder: (context, _) => widget.builder(context, _current),
    );
  }
}

/// The one reusable "live data" signature: a single slow band sweeping across
/// the surface, echoing the engraved tick vocabulary. Plays once when
/// [trigger] changes — never loops. Under reduced motion it collapses to a
/// brief static tint so the "this just updated" message still lands.
class LiveDataPulse extends StatefulWidget {
  const LiveDataPulse({
    super.key,
    required this.trigger,
    required this.child,
    this.color,
    this.radius = AppRadius.card,
  });

  /// Any value that changes when fresh data lands (a timestamp, a revision).
  final Object? trigger;
  final Widget child;
  final Color? color;
  final double radius;

  @override
  State<LiveDataPulse> createState() => _LiveDataPulseState();
}

class _LiveDataPulseState extends State<LiveDataPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.livePulse);
  }

  @override
  void didUpdateWidget(LiveDataPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.tokens.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                if (t == 0 || t == 1) return const SizedBox.shrink();
                if (reduceMotion) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(widget.radius),
                    ),
                  );
                }
                // One pass of a soft band, brightest mid-sweep.
                final fade = 1.0 - (2 * t - 1).abs();
                return ClipRRect(
                  borderRadius: BorderRadius.circular(widget.radius),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.6 + t * 3.2, -1),
                        end: Alignment(-0.6 + t * 3.2, 1),
                        colors: [
                          color.withValues(alpha: 0),
                          color.withValues(alpha: 0.14 * fade),
                          color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
