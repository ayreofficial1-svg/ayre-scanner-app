import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'figure.dart';
import 'pressable_scale.dart';
import 'responsive.dart';

/// The app's card material: flat fill, crisp radius, 1px hairline, no shadow and
/// no gradient. A terminal card, not a soft app card.
class AyreCard extends StatelessWidget {
  const AyreCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.color,
    this.borderColor,
    this.radius = AppRadius.card,
    this.onTap,
    this.accentEdge = false,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  /// A 3px Citrine bar down the leading edge — the hero card's signature accent.
  /// Used sparingly: identity, not decoration.
  final bool accentEdge;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final borderRadius = BorderRadius.circular(radius);

    final Widget body = Padding(padding: padding, child: child);

    // The accent bar is a positioned child inside the card's own clip. A
    // non-uniform Border can't take a radius, and a stretched Row child would
    // force an infinite height inside a list — this does neither: positioned
    // children don't contribute to the Stack's size.
    final Widget contents = accentEdge
        ? Stack(
            children: [
              body,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: accentColor ?? t.accent),
              ),
            ],
          )
        : body;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? t.surface,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? t.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: contents,
      ),
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, borderRadius: radius, child: card);
  }
}

/// The terminal readout embedded inside a card — the one deliberately near-black
/// surface in light mode, and a cooler inset panel in dark. Live figures sit
/// here so they read as coming off a feed rather than being page content.
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: AppSpace.md,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: t.inkPanel,
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: child,
    );
  }
}

/// A section header in the terminal-label convention, with room for a trailing
/// control (a freshness stamp, a sort affordance).
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpace.sm),
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label.toUpperCase(),
              style: AppTypo.label(t, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            // Flex rather than a bare child: a non-flex Row child gets
            // unbounded width, which breaks any trailing widget that lays out
            // its own flexible children (the segmented control, for one).
            Flexible(
              flex: 2,
              child: Align(alignment: Alignment.centerRight, child: trailing!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wraps a trailing widget so it shrinks instead of overflowing.
///
/// A non-flexible child of a [Row] is laid out with unbounded width, so a chip
/// or stamp on the end of a header row will happily report a width larger than
/// the row and push the row into overflow. Giving it a flex slot bounds it, and
/// the [FittedBox] scales it down rather than clipping — which matters at large
/// accessibility text scales, where "DELAYED" is wider than it looks.
class ShrinkTrailing extends StatelessWidget {
  const ShrinkTrailing({super.key, required this.child, this.flex = 2});

  final Widget child;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: child,
      ),
    );
  }
}

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

// ─── Buttons ───────────────────────────────────────────────────────────────

enum AyreButtonKind { primary, outline, danger }

/// Flat, rounded-rect (never a capsule). Primary is a solid Citrine fill with
/// ink text, because Citrine is light enough that white text would under-perform.
class AyreButton extends StatelessWidget {
  const AyreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AyreButtonKind.primary,
    this.glyph,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AyreButtonKind kind;
  final AyreGlyph? glyph;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null && !busy;

    final (Color bg, Color fg, Color? edge) = switch (kind) {
      AyreButtonKind.primary => (t.accent, t.onAccent, null),
      AyreButtonKind.outline => (AppTheme.transparent, t.textPrimary, t.border),
      AyreButtonKind.danger => (
        AppTheme.transparent,
        t.loss,
        t.loss.withValues(alpha: 0.5),
      ),
    };

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: PressableScale(
        onTap: enabled ? onPressed : null,
        borderRadius: AppRadius.button,
        child: Container(
          width: expand ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.button),
            // A Citrine fill on Fogpaper is a light-on-light boundary, so the
            // hairline is what carries the component's 3:1 edge contrast.
            border: Border.all(
              color: edge ?? t.textPrimary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(strokeWidth: 1.6, color: fg),
                )
              else ...[
                if (glyph != null) ...[
                  AyreIcon(glyph!, size: 16, color: fg),
                  const SizedBox(width: AppSpace.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppTypo.button(t, color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Switch ────────────────────────────────────────────────────────────────

/// A flat switch. "On" is Citrine, deliberately never Jade — a toggle turning on
/// must never be visually confusable with a security going up.
class AyreSwitch extends StatelessWidget {
  const AyreSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  static const double _w = 44;
  static const double _h = 24;
  static const double _knob = 18;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onChanged != null;

    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.ease,
            width: _w,
            height: _h,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? t.accent : t.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: value ? t.accent.withValues(alpha: 0.9) : t.border,
              ),
            ),
            child: AnimatedAlign(
              duration: AppMotion.fast,
              curve: AppMotion.ease,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: BoxDecoration(
                  color: value ? t.onAccent : t.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Segmented control ─────────────────────────────────────────────────────

class AyreSegment<T> {
  const AyreSegment({required this.value, required this.label, this.glyph});

  final T value;
  final String label;
  final AyreGlyph? glyph;
}

/// One shared segmented control, used for the appearance selector and the
/// Insights time-window toggle — not a bespoke control per screen.
class AyreSegmented<T> extends StatelessWidget {
  const AyreSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final List<AyreSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _Segment(
                segment: segment,
                selected: segment.value == value,
                compact: compact,
                onTap: () => onChanged(segment.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final AyreSegment<T> segment;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onAccent : t.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.panel,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          padding: EdgeInsets.symmetric(
            vertical: compact ? AppSpace.sm : AppSpace.md,
            horizontal: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? t.accent : AppTheme.transparent,
            borderRadius: BorderRadius.circular(AppRadius.panel),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.glyph != null && !compact) ...[
                AyreIcon(segment.glyph!, size: 16, color: fg, filled: selected),
                const SizedBox(height: AppSpace.xs),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  segment.label.toUpperCase(),
                  style: AppTypo.label(t, color: fg, fontSize: 10),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status chips ──────────────────────────────────────────────────────────

enum ChipTone { neutral, live, attention, info, brand }

/// Small, flat, caps chip for states like LIVE, DELAYED, CLOSED, NEW. Ember
/// carries attention; Slate Violet carries non-market informational tags only.
class AyreChip extends StatelessWidget {
  const AyreChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.glyph,
    this.pulse = false,
  });

  final String label;
  final ChipTone tone;
  final AyreGlyph? glyph;

  /// Only meaningful for [ChipTone.live].
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (Color fg, Color bg) = switch (tone) {
      ChipTone.neutral => (t.textTertiary, t.surfaceAlt),
      ChipTone.live => (t.caution, t.cautionSoft),
      ChipTone.attention => (t.caution, t.cautionSoft),
      ChipTone.info => (t.info, t.info.withValues(alpha: 0.12)),
      ChipTone.brand => (t.accentInk, t.accent.withValues(alpha: 0.16)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tone == ChipTone.live)
            LivePulseDot(color: fg, animate: pulse)
          else if (glyph != null)
            AyreIcon(glyph!, size: 11, color: fg),
          if (tone == ChipTone.live || glyph != null)
            const SizedBox(width: AppSpace.xs),
          Text(label.toUpperCase(), style: AppTypo.label(t, color: fg)),
        ],
      ),
    );
  }
}

/// The one "live" signature in the app: a slow, subtle breath — never a hard
/// blink. Collapses to a static dot under reduced motion.
class LivePulseDot extends StatefulWidget {
  const LivePulseDot({
    super.key,
    required this.color,
    this.size = 6,
    this.animate = true,
  });

  final Color color;
  final double size;
  final bool animate;

  @override
  State<LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.livePulse,
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LivePulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );

    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) return dot;

    // The "live" breath runs for as long as the screen is up, so it gets its own
    // layer rather than dirtying the chip and card it sits in.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: dot,
        builder: (context, child) => Opacity(
          opacity:
              0.45 + 0.55 * AppMotion.easeInOut.transform(_controller.value),
          child: child,
        ),
      ),
    );
  }
}

// ─── The shared ticker row ─────────────────────────────────────────────────

/// The single row component behind Signals, all three Insights movers lists,
/// Index Detail's constituents and Equity Detail's related lists. Building it
/// once is what makes Insights read as one integrated desk rather than three
/// relocated cards.
///
/// The figures column uses [FittedBox] so a large accessibility text scale
/// shrinks the numbers instead of overflowing the row — the failure mode the
/// layout matrix caught in the previous build.
class TickerRow extends StatelessWidget {
  const TickerRow({
    super.key,
    required this.symbol,
    this.name,
    this.rank,
    this.price,
    this.changePercent,
    this.changeAbsolute,
    this.volume,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final String symbol;
  final String? name;

  /// 1-based rank, shown in ranked lists (movers).
  final int? rank;
  final num? price;
  final num? changePercent;
  final num? changeAbsolute;
  final num? volume;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: dense ? AppSpace.sm : AppSpace.row,
      ),
      child: Row(
        children: [
          if (rank != null) ...[
            SizedBox(
              width: 22,
              child: Figure.static(
                '$rank',
                fontSize: 11,
                color: t.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpace.md),
          ],
          // The name column absorbs the remaining width and ellipsizes; long
          // listed-company names are the norm, not the exception.
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  symbol,
                  style: AppTypo.rowLabel(t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (name != null && name!.isNotEmpty)
                  Text(
                    name!,
                    style: AppTypo.caption(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            flex: 4,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (price != null)
                    Figure(formatPrice(price), fontSize: 14)
                  else if (volume != null)
                    Figure(formatVolume(volume), fontSize: 14),
                  const SizedBox(height: AppSpace.xxs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (volume != null && price != null) ...[
                        Figure(
                          formatVolume(volume),
                          fontSize: 11,
                          color: t.textTertiary,
                        ),
                        const SizedBox(width: AppSpace.sm),
                      ] else if (changeAbsolute != null) ...[
                        Figure(
                          formatDelta(changeAbsolute!, percent: false),
                          fontSize: 11,
                          color: t.textTertiary,
                        ),
                        const SizedBox(width: AppSpace.sm),
                      ],
                      if (changePercent != null)
                        DeltaFigure(change: changePercent, fontSize: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return PressableScale(onTap: onTap, borderRadius: 0, child: row);
  }
}

/// A grouped-list row shared by Profile, Settings and Support, so every list in
/// the app uses one row grammar and one disclosure convention: a chevron where
/// the row navigates, a switch where it toggles.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.glyph,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.enabled = true,
  });

  final AyreGlyph glyph;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = danger ? t.loss : t.textSecondary;

    final row = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            AyreIcon(glyph, size: 18, color: tone),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypo.rowLabel(t, color: danger ? t.loss : null),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!, style: AppTypo.caption(t)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : AyreIcon(
                        AyreGlyph.forward,
                        size: 16,
                        color: t.textTertiary,
                      )),
          ],
        ),
      ),
    );

    if (onTap == null || !enabled) return row;
    return PressableScale(onTap: onTap, borderRadius: 0, child: row);
  }
}

/// A grouped card of rows with hairlines between them — Profile and Settings
/// share this so their lists are visually identical.
class RowGroup extends StatelessWidget {
  const RowGroup({super.key, required this.children, this.color});

  final List<Widget> children;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AyreCard(
      padding: EdgeInsets.zero,
      color: color,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const HairlineDivider(indent: AppSpace.md + 18 + AppSpace.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ─── Signal strength ───────────────────────────────────────────────────────

/// Filled/unfilled terminal ticks — "signal bars", deliberately not a dial.
class SignalStrength extends StatelessWidget {
  const SignalStrength({
    super.key,
    required this.level,
    this.of = 4,
    this.color,
    this.height = 14,
  });

  /// 0..[of]
  final int level;
  final int of;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = color ?? t.accentInk;
    return Semantics(
      label: 'Signal strength $level of $of',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < of; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 3,
              height: height * (0.42 + 0.58 * ((i + 1) / of)),
              decoration: BoxDecoration(
                color: i < level ? tone : t.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A thin progress rule — Learn's lesson progress. Citrine, because progress is
/// a brand-carrying affirmative, not a market gain.
class ProgressRule extends StatelessWidget {
  const ProgressRule({super.key, required this.value, this.height = 3});

  /// 0..1
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: t.surfaceAlt,
        valueColor: AlwaysStoppedAnimation(t.accent),
      ),
    );
  }
}

// ─── Skeletons ─────────────────────────────────────────────────────────────

/// A skeleton block shaped like the content it stands in for, with a slow calm
/// pulse — never a spinner for list or card content.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadius.chip,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final block = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: t.skeleton,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return block;
    // Continuous animation: isolated so it repaints only itself.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: block,
        builder: (context, child) => Opacity(
          opacity:
              0.55 + 0.45 * AppMotion.easeInOut.transform(_controller.value),
          child: child,
        ),
      ),
    );
  }
}

/// A skeleton in the exact shape of a [TickerRow].
class SkeletonTickerRow extends StatelessWidget {
  const SkeletonTickerRow({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: dense ? AppSpace.sm : AppSpace.row,
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 74, height: 11),
                SizedBox(height: 5),
                SkeletonBlock(width: 118, height: 9),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonBlock(width: 66, height: 11),
              SizedBox(height: 5),
              SkeletonBlock(width: 44, height: 9),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Entrance ──────────────────────────────────────────────────────────────

/// A restrained, single-play, index-delayed staggered entrance. Plays once per
/// screen visit and does not replay on tab re-visit or a minor rebuild.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 10),
  });

  final Widget child;
  final int index;
  final Offset offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.entrance,
    );
    // Cap the stagger budget so the last element in a long list still starts
    // promptly instead of trickling in.
    final delay = AppMotion.stagger * widget.index.clamp(0, 6);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      // A cancellable Timer rather than Future.delayed: the stagger must not
      // outlive the widget, or it leaks past disposal.
      _delay = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = AppMotion.ease.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(
              widget.offset.dx * (1 - t),
              widget.offset.dy * (1 - t),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Constrains scrollable content to a centred column once the viewport is wider
/// than a comfortable reading measure.
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
