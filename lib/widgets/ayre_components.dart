import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'figure.dart';
import 'pressable_scale.dart';
import 'responsive.dart';
import 'spring.dart';

/// The app's card material: `surface` fill, 18px radius, 1px hairline, and a
/// soft two-layer shadow (§8 of the Spec — shadows are part of the identity,
/// flat/no-shadow is not a rule). Never nested — a card inside a card is
/// always a hairline-divided row group ([RowGroup]) or a sunken/raised tonal
/// fill ([InkPanel]) instead.
class AyreCard extends StatelessWidget {
  const AyreCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.cardPadding),
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

  /// An accent-tinted border (§8.4) marking a featured card — emphasis comes
  /// from the tinted edge itself, never a solid tint fill behind the card.
  /// Renders as a 1.5px full-perimeter accent-toned border, not a leading-edge
  /// bar.
  final bool accentEdge;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final borderRadius = BorderRadius.circular(radius);
    final edgeColor = accentColor ?? t.accent;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? t.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: accentEdge
              ? edgeColor.withValues(alpha: 0.55)
              : (borderColor ?? t.hairline),
          width: accentEdge ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: t.shadowColor.withValues(alpha: 0.10),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: t.shadowColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, borderRadius: radius, child: card);
  }
}

/// A tonal fill nested inside a card (Spec §8.3, `.ayre-inset`) — either
/// recessed into the surface ([raised] false, the default: a track, an inset
/// readout region) or lifted slightly off it ([raised] true: a nested tonal
/// block, an icon tile backing). This is a repurposing of the previous
/// "terminal readout panel" concept, not a rename-only pass — there are no
/// "live feed" semantics for this component, just a plain sub-surface fill at
/// the Spec's 12px inset radius. The class name is kept as `InkPanel` (rather
/// than introducing e.g. `AyreInset`) so the existing call sites in
/// `equity_detail_screen.dart`, `home_tab.dart` and `index_detail_screen.dart`
/// — none of which are in this phase's file list — don't need touching to
/// keep compiling; consider a rename when one of those screens' own phase
/// (5/6) is in progress.
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: AppSpace.md,
    ),
    this.raised = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// False (default): recessed/sunken fill ([AppThemeTokens.surfaceSunken]).
  /// True: lifted/raised fill ([AppThemeTokens.surfaceRaised]).
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: raised ? t.surfaceRaised : t.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.inset),
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
/// accessibility text scales, where a caps chip label is wider than it looks.
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

/// A fully-rounded pill (Spec §11.1 — buttons are pills, not rounded rects, in
/// v5). Primary is a solid accent fill: white text in light (`onAccent`), near-
/// black ink in dark. The light pairing measures ~4.38:1, just under AA for
/// normal-size text — see the Phase 0 contrast note on
/// [AppThemeTokens.onAccent].
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
      AyreButtonKind.outline => (
        AppTheme.transparent,
        t.textPrimary,
        t.hairline,
      ),
      AyreButtonKind.danger => (
        AppTheme.transparent,
        t.negative,
        t.negative.withValues(alpha: 0.5),
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
            // An accent fill against mint paper/near-black is a mid-lightness
            // fill in both themes, so a hairline still carries the
            // component's edge definition rather than relying on the fill
            // alone to read as a distinct shape.
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

/// A flat switch. "On" is the brand accent, deliberately never [positive] — a
/// toggle turning on must never be visually confusable with a security going
/// up. The knob's slide is driven by the Spec's toggle spring
/// ([AppSpring.toggleKnob], numerically checked in `spring.dart`) via
/// [SpringValue] rather than a plain eased tween — this is the one place in
/// this file a spring actually drives motion, per plan §7 open decision #2's
/// sibling guidance that springs are reserved for nav/segmented/toggle only.
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
  static const double _travel = _w - _knob - 2 * 3; // track minus padding

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
            duration: AppMotion.buttonPress,
            curve: AppMotion.ease,
            width: _w,
            height: _h,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? t.accent : t.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: value ? t.accent.withValues(alpha: 0.9) : t.hairline,
              ),
            ),
            child: SpringValue(
              value: value ? _travel : 0,
              spring: AppSpring.toggleKnob,
              builder: (context, dx, child) =>
                  Transform.translate(offset: Offset(dx, 0), child: child),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: BoxDecoration(
                    // Off-knob is `foregroundMuted`, not `foregroundSubtle`:
                    // on the spec'd `surfaceSunken` off-track the subtle tone
                    // measures 2.54:1 in light (under the 3:1 non-text floor);
                    // muted measures 4.68:1 light / 8.6:1 dark.
                    color: value ? t.onAccent : t.foregroundMuted,
                    shape: BoxShape.circle,
                  ),
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
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: t.hairline),
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

  // Note (plan §7 open decision #2 sibling item, resolved in Phase 1): this
  // toggles each segment's own fill rather than sliding one shared pill
  // behind the row (a `layoutId`-equivalent shared-element transition, which
  // Flutter has no direct primitive for outside `Hero` — wrong tool here per
  // the plan's own note). Kept as-is: with only 2–3 segments and every
  // segment animating its own fill on the same `AppMotion.buttonPress`
  // timing, the visual result reads as one control changing state, not three
  // separate ones — a sliding-pill rebuild is not warranted by the Spec's
  // "glides smoothly" description, which this already satisfies.
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onAccent : t.foregroundMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: AnimatedContainer(
          duration: AppMotion.buttonPress,
          curve: AppMotion.ease,
          padding: EdgeInsets.symmetric(
            vertical: compact ? AppSpace.sm : AppSpace.md,
            horizontal: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? t.accent : AppTheme.transparent,
            borderRadius: BorderRadius.circular(AppRadius.control),
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

/// `info` is retired (plan §3.3 / §7 open decision — the Spec's fixed
/// accent set is accent/positive/negative/neutral only, with no separate
/// "info" role). The one real call site using it
/// (`profile_tab.dart`'s tier badge — a non-market identity tag) is
/// reconciled onto [neutral], since a tier label is attention-worthy
/// metadata, not a brand or market-direction signal.
enum ChipTone { neutral, live, attention, brand }

/// Small, flat, caps chip for states like LIVE, CLOSED, NEW. LIVE is
/// [AppThemeTokens.positive] on `positiveSoft`; neutral/attention (muted gold)
/// carries warnings; the brand accent carries non-market identity tags only
/// (tiers, badges) — never a market-direction signal.
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
      ChipTone.neutral => (t.foregroundSubtle, t.surfaceRaised),
      // LIVE is a market-liveness signal: `positive` on `positiveSoft` in
      // both themes, regardless of any per-card identity tint around it.
      ChipTone.live => (t.positive, t.positiveSoft),
      ChipTone.attention => (t.neutral, t.neutralSoft),
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
                color: t.foregroundSubtle,
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
                          color: t.foregroundSubtle,
                        ),
                        const SizedBox(width: AppSpace.sm),
                      ] else if (changeAbsolute != null) ...[
                        Figure(
                          formatDelta(changeAbsolute!, percent: false),
                          fontSize: 11,
                          color: t.foregroundSubtle,
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
    final tone = danger ? t.negative : t.foregroundMuted;

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
                    style: AppTypo.rowLabel(
                      t,
                      color: danger ? t.negative : null,
                    ),
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
                        color: t.foregroundSubtle,
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
  const RowGroup({
    super.key,
    required this.children,
    this.color,
    this.indent = defaultIndent,
  });

  /// Where the hairlines start: the row padding, an 18px leading icon and the
  /// gap after it — the Profile/Settings row grammar.
  static const double defaultIndent = AppSpace.md + 18 + AppSpace.md;

  final List<Widget> children;
  final Color? color;

  /// Left inset of the hairlines between rows. Lists whose rows lead with
  /// something other than an 18px icon (the Insights movers' instrument tile)
  /// pass their own leading width so the dividers start at the text, not
  /// under the tile.
  final double indent;

  @override
  Widget build(BuildContext context) {
    return AyreCard(
      padding: EdgeInsets.zero,
      color: color,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) HairlineDivider(indent: indent),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ─── Signal strength ───────────────────────────────────────────────────────

/// Filled/unfilled bars — deliberately not a dial. Heights step at the Spec's
/// own 40/55/70/85/100% band (§11.6) rather than the previous formula-derived
/// curve — with the default `of: 4` this plan inherited from v3, the last
/// four of those five steps are used (55/70/85/100%) so the tallest bar still
/// reads as "full". Retinted to the caller's direction color (gain/loss) by
/// default via [color]; falls back to the brand accent only when no direction
/// applies.
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

  /// The Spec's exact bar-height percentages (§11.6), tallest last.
  static const List<double> _heightSteps = [0.40, 0.55, 0.70, 0.85, 1.00];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = color ?? t.accentInk;
    // Sample the last `of` steps of the Spec's 5-step band so a smaller bar
    // count still ends on "full height" rather than re-deriving a new curve.
    final steps = _heightSteps.sublist(
      (_heightSteps.length - of).clamp(0, _heightSteps.length),
    );
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
              height: height * (i < steps.length ? steps[i] : 1.0),
              decoration: BoxDecoration(
                // Unfilled bars sit on `surfaceSunken`, not `hairline`.
                // Hairline is a ~6% alpha edge tone — correct for a 1px
                // divider, effectively invisible as a 3px-wide filled bar, and
                // an unread bar that can't be seen isn't a meter, it's a
                // shorter meter. Retinted in Phase 3 alongside the rest of the
                // data-viz family.
                color: i < level ? tone : t.surfaceSunken,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A thin progress rule — Learn's lesson progress. The brand accent, because
/// progress is a brand-carrying affirmative, not a market gain (so it never
/// borrows [AppThemeTokens.positive]).
class ProgressRule extends StatelessWidget {
  const ProgressRule({
    super.key,
    required this.value,
    this.height = 3,
    this.color,
  });

  /// 0..1
  final double value;
  final double height;

  /// Overrides the brand accent. Added in Phase 5 for Learn's completion
  /// state (§13.4), where a finished course reads in
  /// [AppThemeTokens.positive] — the one case where progress genuinely is an
  /// outcome rather than a brand-carrying action, matching the same switch
  /// `ProgressRing` makes at 100%.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: t.surfaceSunken,
        valueColor: AlwaysStoppedAnimation(color ?? t.accent),
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

  /// §14.4: one sweep every 1.7s, eased in and out.
  static const Duration _sweep = Duration(milliseconds: 1700);

  /// How wide the highlight band is, as a fraction of the sweep's travel. Wide
  /// enough to read as a soft wash moving across the block rather than a hard
  /// glint crossing it.
  static const double _bandWidth = 0.22;

  @override
  void initState() {
    super.initState();
    // Not `reverse: true`. A reversing sweep travels back the way it came,
    // which reads as something scrubbing rather than loading. Because the band
    // is fully off-block at both ends of the travel, the restart is invisible.
    _controller = AnimationController(vsync: this, duration: _sweep)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = t.skeleton;

    BoxDecoration decoration({Gradient? gradient}) => BoxDecoration(
      color: gradient == null ? base : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(widget.radius),
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: decoration(),
      );
    }

    // A soft foreground-tinted highlight over the skeleton fill (§14.4),
    // replacing the previous identity's whole-block opacity pulse. A pulse
    // dims the layout it is standing in for; a sweep leaves the shape at a
    // constant weight and only moves light across it, which is what keeps a
    // loading screen calm rather than throbbing.
    final highlight = Color.alphaBlend(
      t.textPrimary.withValues(alpha: 0.07),
      base,
    );

    // Continuous animation: isolated so it repaints only itself.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final p = AppMotion.easeInOut.transform(_controller.value);
          // Travel from fully off the left edge to fully off the right, so the
          // band never pops into or out of existence mid-block.
          final centre = -_bandWidth + p * (1 + _bandWidth * 2);
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: decoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [base, highlight, base],
                stops: [
                  (centre - _bandWidth).clamp(0.0, 1.0),
                  centre.clamp(0.0, 1.0),
                  (centre + _bandWidth).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A skeleton in the exact shape of a [TickerRow]. [tile] adds the leading
/// instrument-tile block for lists whose rows lead with an
/// `AyreInstrumentTile`, so the loaded list doesn't shift sideways.
class SkeletonTickerRow extends StatelessWidget {
  const SkeletonTickerRow({super.key, this.dense = false, this.tile = false});

  final bool dense;
  final bool tile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: dense ? AppSpace.sm : AppSpace.row,
      ),
      child: Row(
        children: [
          if (tile) ...const [
            SkeletonBlock(width: 40, height: 40, radius: AppRadius.iconTile),
            SizedBox(width: AppSpace.md),
          ],
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

// ─── Direction badge ───────────────────────────────────────────────────────

/// A signed market direction shown as icon + label on a tint-on-wash fill —
/// never a solid fill (Spec §11.5, §20.7: exactly one reused component for
/// this, never inlined per-screen). Extracted in Phase 1 per plan §6/§9 as a
/// **new** shared component: no equivalent existed as an isolated widget
/// before — [DeltaFigure] (`figure.dart`) renders a signed *figure* inline
/// with a caret, and `home_tab.dart`'s private `_BreadthFigure` does its own
/// bespoke direction rendering; neither is this component. This widget is
/// additive in this phase — rewiring call sites onto it (including
/// `home_tab.dart`'s inline pattern) is Phase 5/6 work, done screen by screen
/// against its own Spec subsection rather than here.
///
/// Color is never the only channel: the caret glyph and the upper-case label
/// both carry direction independently of the tint.
class DirectionBadge extends StatelessWidget {
  const DirectionBadge({
    super.key,
    required this.up,
    required this.label,
    this.neutral = false,
  });

  /// Ignored when [neutral] is true.
  final bool up;
  final String label;

  /// Renders in the neutral/gold tone instead of positive/negative — for a
  /// flat/unchanged reading that still needs a badge (e.g. "UNCHANGED").
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (Color fg, Color bg) = neutral
        ? (t.neutral, t.neutralSoft)
        : up
        ? (t.positive, t.positiveSoft)
        : (t.negative, t.negativeSoft);

    return Semantics(
      label: '${neutral ? 'unchanged' : (up ? 'up' : 'down')} $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!neutral) ...[
              DirectionGlyph(up: up, color: fg, size: 11),
              const SizedBox(width: 4),
            ],
            Text(label.toUpperCase(), style: AppTypo.label(t, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ─── Filter chip ───────────────────────────────────────────────────────────

/// A selectable filter chip (Spec §11.2, used by §13.2's Signals board).
///
/// Added in Phase 5, and deliberately a **third** chip-family component rather
/// than a flag on an existing one. The three do genuinely different jobs and
/// conflating them produces nonsense:
///
/// * [AyreChip] reports a **state** the user cannot change — LIVE, CLOSED, a
///   tier. A "selected" LIVE chip means nothing.
/// * [TagPill] labels a **piece of content** — an article's category. It never
///   pulses, animates, or responds to touch.
/// * This carries a **choice the user makes**, so it is the only one of the
///   three that is tappable, has a selected state, and needs a 44pt target.
///
/// Selection is not colour-only: the selected chip also gains a filled border
/// and heavier text weight, so the active filter survives with colour removed.
class AyreFilterChip extends StatelessWidget {
  const AyreFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// An optional match count. Rendered through [Figure] like every other
  /// number in the app rather than interpolated into the label string.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onAccent : t.foregroundMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: AnimatedContainer(
          duration: AppMotion.buttonPress,
          curve: AppMotion.ease,
          // 44pt tall, not §17's 32px chip minimum — plan §8 resolved that
          // conflict in favour of the HIG floor, since an accessibility
          // minimum isn't a place to split the difference.
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? t.accent : t.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypo.ui(
                  fontSize: AppTextScale.body,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpace.xs),
                Figure.static(
                  '$count',
                  fontSize: AppTextScale.hint,
                  fontWeight: FontWeight.w600,
                  color: selected ? fg : t.foregroundSubtle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tag pill ──────────────────────────────────────────────────────────────

/// A small, neutral, non-market informational tag — the category label on an
/// Insights note, a topic marker. Distinct from [AyreChip]: chips carry a
/// state (LIVE, CLOSED, a tier), tags label a piece of content and never
/// pulse, animate, or carry a glyph. Extracted in Phase 1 per plan §6 as a
/// **new** shared component: `insights_tab.dart`'s `note.category` label was
/// previously rendered as a bare uppercase [Text] with no pill/fill at all,
/// not an inlined variant of this widget — nothing is retired by adding this.
/// Rewiring that call site onto [TagPill] is Phase 5 work (`insights_tab.dart`
/// against Spec §13.3), not done here.
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypo.label(t, color: t.foregroundMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}