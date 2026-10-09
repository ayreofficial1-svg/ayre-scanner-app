import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'onboarding_widgets.dart' show OnboardingPageIndicator;

/// One stop of a spotlight tutorial.
class SpotlightStep {
  const SpotlightStep({
    this.target,
    required this.title,
    required this.body,
    this.onEnter,
  });

  /// Key of the live widget to highlight. Null (or a key that never resolves)
  /// shows the explanation on a fully dimmed screen instead.
  final Key? target;
  final String title;
  final String body;

  /// Runs when the step becomes current, e.g. to switch tabs so [target]
  /// exists. The overlay keeps looking for [target] until it appears.
  final VoidCallback? onEnter;
}

/// A dimmed, blurred overlay that cuts a hole around real widgets and explains
/// them one at a time.
///
/// The overlay is inserted in the **root** overlay, so it sits above every
/// pushed route and works the same on the shell and on Settings. Targets are
/// found by key in the live element tree and re-measured every frame, so the
/// highlight follows tab fades, scrolling, rotation and window resizes without
/// any hand-measured geometry.
abstract final class SpotlightTour {
  static _Session? _session;

  static bool get isActive => _session != null;

  /// Starts a tour. [onClosed] receives true when the person reached Finish and
  /// false when they skipped. Does nothing if a tour is already showing.
  static void show(
    BuildContext context, {
    required List<SpotlightStep> steps,
    void Function(bool completed)? onClosed,
  }) {
    if (_session != null || steps.isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final _Session session;
    final entry = OverlayEntry(
      builder: (_) => _SpotlightOverlay(
        steps: steps,
        onClose: (completed) {
          if (!identical(_session, session)) return;
          _session = null;
          session.entry.remove();
          onClosed?.call(completed);
        },
      ),
    );
    session = _Session(entry);
    _session = session;
    overlay.insert(entry);
  }

  /// Removes any visible tour without calling its `onClosed`. For owners that
  /// are being disposed (sign-out, leaving Settings) and must not be called
  /// back.
  static void dismiss() {
    final session = _session;
    if (session == null) return;
    _session = null;
    // Deferred: this is usually called from a State.dispose, mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (session.entry.mounted) session.entry.remove();
    });
  }
}

class _Session {
  _Session(this.entry);
  final OverlayEntry entry;
}

/// Finds the live element carrying [key], or null.
Element? _findElement(Key key) {
  Element? found;
  void visit(Element element) {
    if (found != null) return;
    if (element.widget.key == key) {
      found = element;
      return;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

class _SpotlightOverlay extends StatefulWidget {
  const _SpotlightOverlay({required this.steps, required this.onClose});

  final List<SpotlightStep> steps;
  final void Function(bool completed) onClose;

  @override
  State<_SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<_SpotlightOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// How long to keep looking for a target before explaining without it.
  static const Duration _searchTimeout = Duration(milliseconds: 1500);

  late final Ticker _ticker;
  int _index = 0;
  bool _closed = false;

  Element? _element;
  bool _scrolled = false;
  Duration _stepStart = Duration.zero;
  Duration _now = Duration.zero;
  Duration _last = Duration.zero;

  /// Where the hole is drawn now; eases toward the measured target.
  Rect? _display;

  SpotlightStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
    // The first step's onEnter may change the shell's state, which is not
    // allowed while this overlay is still being inserted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _step.onEnter?.call();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  /// Android back closes the tour instead of leaving the app.
  @override
  Future<bool> didPopRoute() async {
    if (_closed) return false;
    _close(false);
    return true;
  }

  void _close(bool completed) {
    if (_closed) return;
    _closed = true;
    widget.onClose(completed);
  }

  void _go(int index) {
    if (_closed || index < 0 || index >= widget.steps.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = index;
      _element = null;
      _scrolled = false;
      _stepStart = _now;
    });
    _step.onEnter?.call();
  }

  void _next() => _isLast ? _finish() : _go(_index + 1);

  void _finish() {
    HapticFeedback.mediumImpact();
    _close(true);
  }

  Rect? _measure(Element element) {
    final box = element.renderObject;
    final self = context.findRenderObject();
    if (box is! RenderBox || self is! RenderBox) return null;
    if (!box.attached || !box.hasSize || !self.hasSize) return null;
    final topLeft = self.globalToLocal(box.localToGlobal(Offset.zero));
    return (topLeft & box.size).inflate(AppSpace.xs);
  }

  void _onTick(Duration elapsed) {
    if (_closed || !mounted) return;
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _now = elapsed;

    final key = _step.target;
    Rect? target;
    var searching = false;
    if (key != null) {
      var element = _element;
      if (element == null || !element.mounted) {
        element = _findElement(key);
        _element = element;
        _scrolled = false;
      }
      if (element != null) {
        if (!_scrolled) {
          _scrolled = true;
          final reduce = MediaQuery.disableAnimationsOf(context);
          unawaited(
            Scrollable.ensureVisible(
              element,
              alignment: 0.15,
              duration: reduce ? Duration.zero : AppMotion.pageTransition,
              curve: AppMotion.ease,
            ),
          );
        }
        target = _measure(element);
      } else if (elapsed - _stepStart < _searchTimeout) {
        searching = true;
      }
    }

    if (searching) return; // Keep the previous hole until the next one exists.

    if (target == null) {
      if (_display != null) setState(() => _display = null);
      return;
    }

    final current = _display;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (current == null || reduce) {
      if (current != target) setState(() => _display = target);
      return;
    }
    final k = 1 - math.exp(-dt * 16);
    var next = Rect.lerp(current, target, k)!;
    if ((next.left - target.left).abs() < 0.5 &&
        (next.top - target.top).abs() < 0.5 &&
        (next.right - target.right).abs() < 0.5 &&
        (next.bottom - target.bottom).abs() < 0.5) {
      next = target;
    }
    if (next != current) setState(() => _display = next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final hole = _display;
    final radius = hole == null
        ? 0.0
        : (hole.shortestSide <= 72
              ? hole.shortestSide / 2
              : AppRadius.card);

    // Card placement: below the hole if it fits, else above, else pinned to
    // the bottom edge (a tall target such as a whole settings group).
    final need = 200 * math.max(1.0, textScale);
    final spaceBelow = hole == null ? 0.0 : size.height - hole.bottom - padding.bottom;
    final spaceAbove = hole == null ? 0.0 : hole.top - padding.top;
    final maxCardHeight = size.height - padding.top - padding.bottom - AppSpace.xl;

    double? top;
    double? bottom;
    if (hole == null) {
      top = padding.top + AppSpace.xl;
      bottom = padding.bottom + AppSpace.xl;
    } else if (spaceBelow >= need) {
      top = hole.bottom + AppSpace.sm;
    } else if (spaceAbove >= need) {
      bottom = size.height - hole.top + AppSpace.sm;
    } else {
      bottom = padding.bottom + AppSpace.md;
    }

    final scrim = Colors.black.withValues(alpha: dark ? 0.72 : 0.58);

    return BlockSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                _go(_index - 1),
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                _close(false),
          },
          child: Focus(
            autofocus: true,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: reduce ? 1.0 : 0.0, end: 1.0),
              duration: reduce ? Duration.zero : AppMotion.pageTransition,
              curve: AppMotion.ease,
              builder: (context, fade, child) =>
                  Opacity(opacity: fade, child: child),
              child: Stack(
                children: [
                  // The scrim swallows every tap, including those over the
                  // hole: the highlighted control is explained, not pressed.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: ClipPath(
                        clipper: _HoleClipper(hole, radius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: ColoredBox(color: scrim),
                        ),
                      ),
                    ),
                  ),
                  if (hole != null)
                    Positioned.fromRect(
                      rect: hole,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(color: t.accent, width: 2),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top,
                    bottom: bottom,
                    child: Align(
                      alignment: top != null && bottom != null
                          ? Alignment.center
                          : (top != null
                                ? Alignment.topCenter
                                : Alignment.bottomCenter),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 420 + AppSpace.xl * 2,
                          maxHeight: maxCardHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.xl,
                          ),
                          child: _Card(
                            step: _step,
                            index: _index,
                            total: widget.steps.length,
                            isLast: _isLast,
                            onNext: _next,
                            onBack: _index > 0 ? () => _go(_index - 1) : null,
                            onSkip: () => _close(false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything except a rounded hole, so the blur and dim apply only outside it.
class _HoleClipper extends CustomClipper<Path> {
  _HoleClipper(this.hole, this.radius);

  final Rect? hole;
  final double radius;

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final h = hole;
    if (h == null) return full;
    final cut = Path()
      ..addRRect(RRect.fromRectAndRadius(h, Radius.circular(radius)));
    return Path.combine(PathOperation.difference, full, cut);
  }

  @override
  bool shouldReclip(_HoleClipper old) => old.hole != hole || old.radius != radius;
}

class _Card extends StatelessWidget {
  const _Card({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final SpotlightStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return AyreCard(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: reduce ? Duration.zero : AppMotion.pageTransition,
              switchInCurve: AppMotion.ease,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: Column(
                key: ValueKey<int>(index),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      step.title,
                      style: AppTypo.display(
                        fontSize: AppTextScale.cardTitle,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    step.body,
                    style: AppTypo.ui(
                      fontSize: AppTextScale.rowLabel,
                      fontWeight: FontWeight.w500,
                      color: t.foregroundMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            OnboardingPageIndicator(page: index, total: total),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: AppSpace.xs,
              children: [
                if (isLast)
                  const SizedBox.shrink()
                else
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        AppSpace.minTarget,
                        AppSpace.minTarget,
                      ),
                      foregroundColor: t.foregroundMuted,
                    ),
                    child: Text('Skip', style: AppTypo.button(t)),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onBack != null) ...[
                      TextButton(
                        onPressed: onBack,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            AppSpace.minTarget,
                            AppSpace.minTarget,
                          ),
                          foregroundColor: t.foregroundMuted,
                        ),
                        child: Text('Back', style: AppTypo.button(t)),
                      ),
                      const SizedBox(width: AppSpace.xs),
                    ],
                    AyreButton(
                      label: isLast ? 'Finish' : 'Next',
                      onPressed: onNext,
                      expand: false,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
