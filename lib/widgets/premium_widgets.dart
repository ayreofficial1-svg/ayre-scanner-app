import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'instrument_marks.dart';
import 'responsive.dart';

/// The engraved ornament a hero surface may carry. At most one per screen, on
/// the single most prominent surface — Home's hero takes one, Signals and Learn
/// take none, Login and Splash share the bearing mark.
enum HeroOrnament { none, ticks, contour, bearing }

/// Screen frame. A flat, warm canvas — no gradient wash, no blurred blobs.
/// Separation on this canvas comes from whitespace and surface tint, never
/// from atmosphere behind the content.
class PremiumScaffold extends StatelessWidget {
  const PremiumScaffold({
    super.key,
    required this.child,
    this.section = AyreSection.home,
    this.padding = EdgeInsets.zero,
    this.bottomSafe = true,
  });

  final Widget child;
  final AyreSection section;
  final EdgeInsetsGeometry padding;
  final bool bottomSafe;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.tokens.background,
      child: SafeArea(
        bottom: bottomSafe,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// The app's default card material: a flat, matte, opaque tinted surface with
/// an optional hairline edge. Separation follows a strict restraint hierarchy —
/// whitespace first, then a tint/lightness shift, then a hairline only if the
/// first two don't read clearly. No frosted translucency, no blur, no drop
/// shadow, and no soft "glass" fill anywhere in this system.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.card,
    this.color,
    this.borderColor,
    this.hairline = true,
    this.clip = true,
    this.ornament = HeroOrnament.none,
    this.ornamentColor,
    this.shape,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  /// Draws the 1px edge. Turn it off where a tint shift alone already reads.
  final bool hairline;
  final bool clip;

  /// The engraved treatment behind the card's content, if this is the one
  /// ornamented surface on the screen.
  final HeroOrnament ornament;
  final Color? ornamentColor;

  /// Overrides the rounded-rectangle voice — pass a [ChamferedBorder] for
  /// instrument-coded elements.
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = color ?? tokens.surface;
    final edge = hairline
        ? BorderSide(color: borderColor ?? tokens.borderSubtle, width: 1)
        : BorderSide.none;

    Widget body = Padding(padding: padding, child: child);

    if (ornament != HeroOrnament.none) {
      body = Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _Ornament(
                ornament: ornament,
                color: ornamentColor ?? tokens.engraved,
              ),
            ),
          ),
          body,
        ],
      );
    }

    if (shape != null) {
      final outline = shape is OutlinedBorder
          ? (shape! as OutlinedBorder).copyWith(side: edge)
          : shape!;
      return Material(
        color: fill,
        shape: outline,
        elevation: 0,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: body,
      );
    }

    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.fromBorderSide(edge),
      ),
      child: clip
          ? ClipRRect(
              borderRadius: BorderRadius.circular(math.max(0, radius - 1)),
              child: body,
            )
          : body,
    );
  }
}

class _Ornament extends StatelessWidget {
  const _Ornament({required this.ornament, required this.color});

  final HeroOrnament ornament;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (ornament) {
      HeroOrnament.none => const SizedBox.shrink(),
      HeroOrnament.ticks => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 12,
          child: TickMarks(color: color, count: 40, length: 4, majorLength: 8),
        ),
      ),
      HeroOrnament.contour => ContourLines(color: color, lines: 8),
      HeroOrnament.bearing => Align(
        alignment: Alignment.centerRight,
        child: FractionalTranslation(
          translation: const Offset(0.28, 0),
          child: BearingMark(color: color, size: 200, showNeedle: false),
        ),
      ),
    };
  }
}

/// One hairline divider treatment, reused everywhere a separator is needed —
/// Profile, Settings, grouped sections, section breaks.
class HairlineDivider extends StatelessWidget {
  const HairlineDivider({super.key, this.indent = 0, this.endIndent = 0});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: context.tokens.hairline,
    );
  }
}

/// A small, discrete status chip — one of the two places the stadium shape
/// survives (the other is the nav bar).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.outlined = false,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = foreground ?? tokens.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: outlined ? AppTheme.transparent : background ?? tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: outlined ? Border.all(color: fg.withValues(alpha: 0.45)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 12),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label.toUpperCase(), style: AppTypo.microLabel(tokens, color: fg)),
        ],
      ),
    );
  }
}

/// Flat, bordered icon button. Replaces the old frosted-glass circle: a matte
/// surface with a hairline edge, nothing translucent. Never renders without an
/// [onTap] — an icon-only affordance either acts or isn't there.
class InstrumentIconButton extends StatelessWidget {
  const InstrumentIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 44,
    this.color,
    this.iconColor,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;
  final Color? color;
  final Color? iconColor;

  /// A small "new"/fresh dot. Small-area only, per the accentMint rule.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: Material(
          color: color ?? tokens.surfaceAlt,
          shape: CircleBorder(side: BorderSide(color: tokens.borderSubtle)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: tokens.primary.withValues(alpha: 0.06),
            splashColor: tokens.primary.withValues(alpha: 0.10),
            highlightColor: tokens.primary.withValues(alpha: 0.05),
            child: SizedBox(
              height: size,
              width: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? tokens.textPrimary,
                    size: size * 0.45,
                  ),
                  if (badge)
                    Positioned(
                      top: size * 0.22,
                      right: size * 0.24,
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.accentMint,
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

/// Staggered fade + upward slide entrance. The mechanism is unchanged from
/// before the redesign: restrained, single-play, index-delayed, and it doesn't
/// replay when a tab is revisited.
class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 12),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.cardEntrance + delay,
      curve: AppMotion.ease,
      builder: (context, value, child) {
        final totalMs = (AppMotion.cardEntrance + delay).inMilliseconds;
        final delayMs = delay.inMilliseconds;
        final delayed = (delay == Duration.zero
                ? value
                : ((value - delayMs / totalMs) / (1 - delayMs / totalMs))
                      .clamp(0.0, 1.0))
            .toDouble();
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - delayed),
              offset.dy * (1 - delayed),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Tab-level loading. Re-dressed in the flat instrument register: a calibration
/// strip and a hairline progress arc, no floating card and no glass.
class PremiumLoader extends StatelessWidget {
  const PremiumLoader({super.key, this.label, this.section = AyreSection.home});

  final String? label;
  final AyreSection section;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumScaffold(
      section: section,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: tokens.primary,
                backgroundColor: tokens.borderSubtle,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 8,
              width: 72,
              child: TickMarks(
                color: tokens.engraved,
                count: 13,
                length: 4,
                majorEvery: 6,
                majorLength: 8,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(label!, style: AppTypo.microLabel(tokens)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A fine hairline trace with a tick baseline — a barograph strip chart, not a
/// filled-gradient area chart. The default stroke is brass: the sparkline is
/// the instrument's trace first and a directional signal second, and direction
/// is carried redundantly by the accompanying figure and glyph.
///
/// On a points change the path redraws progressively rather than swapping
/// instantly — the shape change itself is the information.
class Sparkline extends StatefulWidget {
  const Sparkline({
    super.key,
    this.color,
    this.height = 56,
    this.strokeWidth = 1.4,
    this.baseline = true,
    this.points = const [
      0.62, 0.42, 0.48, 0.34, 0.52, 0.46, 0.22, 0.28, 0.18, 0.52,
    ],
  });

  /// Defaults to `primary` (brass) — never a gain/loss color.
  final Color? color;
  final double height;
  final double strokeWidth;
  final bool baseline;
  final List<double> points;

  @override
  State<Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;
  late List<double> _from;
  late List<double> _to;

  @override
  void initState() {
    super.initState();
    _from = widget.points;
    _to = widget.points;
    _draw = AnimationController(vsync: this, duration: AppMotion.slow)
      ..value = 1.0;
  }

  @override
  void didUpdateWidget(Sparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.points, widget.points)) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _from = widget.points;
      _to = widget.points;
      _draw.value = 1.0;
      return;
    }
    // Re-target from whatever is on screen right now, so an update landing
    // mid-redraw continues the morph instead of snapping back.
    _from = _interpolated;
    _to = widget.points;
    _draw.forward(from: 0);
  }

  /// Morphs the old path into the new one rather than clearing and redrawing,
  /// so a live update reads as the same trace moving.
  List<double> get _interpolated {
    final t = AppMotion.ease.transform(_draw.value.clamp(0.0, 1.0));
    if (_from.length != _to.length) return _to;
    return [
      for (var i = 0; i < _to.length; i++) _from[i] + (_to[i] - _from[i]) * t,
    ];
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _draw,
        builder: (context, _) => CustomPaint(
          painter: _SparklinePainter(
            color: widget.color ?? tokens.primary,
            points: _interpolated,
            strokeWidth: widget.strokeWidth,
            baseline: widget.baseline,
            baselineColor: tokens.engraved,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.color,
    required this.points,
    required this.strokeWidth,
    required this.baseline,
    required this.baselineColor,
  });

  final Color color;
  final List<double> points;
  final double strokeWidth;
  final bool baseline;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    if (baseline) {
      final tickPaint = Paint()
        ..color = baselineColor
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        tickPaint,
      );
      // Calibration ticks along the baseline, one per sample.
      for (var i = 0; i < points.length; i++) {
        final x = i / (points.length - 1) * size.width;
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x, size.height - (i % 2 == 0 ? 4 : 2)),
          tickPaint,
        );
      }
    }

    // Straight segments, not eased curves: an instrument trace records what
    // happened, it doesn't smooth it.
    final path = Path();
    const topInset = 2.0;
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = topInset +
          (1.0 - points[i].clamp(0.0, 1.0)) * (size.height - topInset - 6);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) {
    return old.color != color ||
        !listEquals(old.points, points) ||
        old.strokeWidth != strokeWidth ||
        old.baseline != baseline ||
        old.baselineColor != baselineColor;
  }
}

/// Constrains scrollable content to a centred column once the viewport is
/// wider than a comfortable reading measure — the principle Login already got
/// right, applied app-wide.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppBreakpoints.contentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
