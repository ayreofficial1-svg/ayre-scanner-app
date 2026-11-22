import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'finance_icons.dart';
import 'ayre_sheet.dart';
import 'figure.dart';
import 'pressable_scale.dart';
import 'responsive.dart';

/// The app's card material: `surface` fill, 1px opaque line and the
/// asymmetric silhouette (TL 8, TR/BR/BL 26).
///
/// Cards are **flat** by default. A shadow is reserved for the explicitly
/// raised hero surfaces ([featured]; [strongShadow] for the report summary /
/// profile identity). The saffron [notch] is opt-in. Never nested — a card
/// inside a card is a hairline-divided row group ([RowGroup]) or a soft inset
/// ([InkPanel]).
class AyreCard extends StatelessWidget {
  const AyreCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.cardPadding),
    this.color,
    this.borderColor,
    this.radius,
    this.onTap,
    this.accentEdge = false,
    this.accentColor,
    this.featured = false,
    this.strongShadow = false,
    this.notch = false,
    this.clip,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  /// Overrides the asymmetric [AppShape.card] with a uniform radius.
  final double? radius;
  final VoidCallback? onTap;

  /// An accent-tinted 1.5px border marking a featured card.
  final bool accentEdge;
  final Color? accentColor;

  /// Opts the card into the reference raised shadow.
  final bool featured;

  /// The slightly stronger (.13) raised shadow.
  final bool strongShadow;

  /// Draws the saffron notch on the top edge (21 from the left, 21×5).
  final bool notch;

  /// Whether the content is clipped to the card's corners. Null (default)
  /// clips only when [padding] is zero.
  final bool? clip;

  static BorderRadius _inner(BorderRadius r) => BorderRadius.only(
    topLeft: Radius.circular((r.topLeft.x - 1).clamp(0, 999)),
    topRight: Radius.circular((r.topRight.x - 1).clamp(0, 999)),
    bottomRight: Radius.circular((r.bottomRight.x - 1).clamp(0, 999)),
    bottomLeft: Radius.circular((r.bottomLeft.x - 1).clamp(0, 999)),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final borderRadius = radius == null
        ? AppShape.card
        : BorderRadius.circular(radius!);
    final edgeColor = accentColor ?? t.accent;
    final brightness = Theme.of(context).brightness;
    final shouldClip = clip ?? (padding == EdgeInsets.zero);

    final padded = Padding(padding: padding, child: child);

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? t.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: accentEdge
              ? edgeColor.withValues(alpha: 0.55)
              : (borderColor ?? t.hairline),
          width: accentEdge ? 1.5 : 1,
        ),
        boxShadow: strongShadow
            ? AppElevation.raisedStrong(t, brightness)
            : featured
            ? AppElevation.raised(t, brightness)
            : AppElevation.flat,
      ),
      child: shouldClip
          ? ClipRRect(borderRadius: _inner(borderRadius), child: padded)
          : padded,
    );

    if (notch) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            left: AppShape.notchInset,
            top: AppShape.notchOffsetY,
            width: AppShape.notchWidth,
            height: AppShape.notchHeight,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.notch,
                  borderRadius: AppShape.notch,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return card;
    return PressableScale(onTap: onTap, shape: borderRadius, child: card);
  }
}

/// A tonal fill nested inside a card (Spec §8.3, `.ayre-inset`) — either
/// recessed into the surface ([raised] false, the default: a track, an inset
/// readout region) or lifted slightly off it ([raised] true: a nested tonal
/// block, an icon tile backing). This is a repurposing of the previous
/// "terminal readout panel" concept, not a rename-only pass — there are no
/// "live feed" semantics for this component, just a plain sub-surface fill at
/// the Spec's 12px inset radius. The class name is kept as `InkPanel` (rather
/// than introducing e.g. `AyreInset`) so the existing call sites don't need
/// touching to keep compiling; consider a rename when one of those screens' own phase
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

/// A section header (D-2): sentence-case, 17 sp, primary text — the real third
/// level between the page title and content. Has room for a trailing control
/// (a freshness stamp, a sort affordance).
///
/// [subtitle] is an optional one-line description shown directly under the
/// heading. Left null, the header looks exactly as it always has.
///
/// [info] is an optional plain-language explanation of what the section shows.
/// When given, a small, quiet "i" icon sits right after the heading text and
/// opens the explanation in a sheet when tapped. Left null, no icon is drawn.
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.label,
    this.trailing,
    this.subtitle,
    this.info,
    this.eyebrow = false,
    this.padding = const EdgeInsets.only(bottom: AppSpace.sectionLabelBelow),
  });

  final String label;
  final Widget? trailing;
  final String? subtitle;
  final String? info;

  /// The 11/800 tracked uppercase group label instead of the 21/800 section
  /// title.
  final bool eyebrow;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final heading = Semantics(
      header: true,
      child: Text(
        eyebrow ? label.toUpperCase() : label,
        style: eyebrow ? AppTypo.label(t) : AppTypo.sectionTitle(t),
      ),
    );

    // The heading and (when present) its description share one left column,
    // so a tall trailing control such as a "See all" link sits beside the pair
    // instead of pushing the description away from its heading.
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info == null)
          heading
        else
          // The "i" icon rides on the heading's right-hand side. It lives with
          // the heading rather than in the trailing slot so it can never crowd
          // a "See all" link that sits at the far edge of the row.
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: heading),
              SectionInfoButton(title: label, message: info!),
            ],
          ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(subtitle!, style: AppTypo.subtitle(t).copyWith(fontSize: 14)),
        ],
      ],
    );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: titleBlock),
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

/// The small "i in a circle" beside a section heading.
///
/// Deliberately quiet: a 16pt outline in the muted foreground tone, no fill,
/// no shadow. The visual stays small but the hit area is the full 48×48
/// minimum target. Tapping it opens a bottom sheet with [message] — a short,
/// everyday-language explanation of what the section shows.
class SectionInfoButton extends StatelessWidget {
  const SectionInfoButton({
    super.key,
    required this.title,
    required this.message,
  });

  /// The section's name, used as the sheet's heading and the screen-reader
  /// label.
  final String title;

  /// The explanation shown in the sheet.
  final String message;

  static const double _glyphSize = 20;

  void _open(BuildContext context) {
    HapticFeedback.selectionClick();
    showAyreSheet<void>(
      context: context,
      builder: (_) => _SectionInfoSheet(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'About $title',
      onTap: () => _open(context),
      excludeSemantics: true,
      child: PressableScale(
        onTap: () => _open(context),
        borderRadius: AppRadius.control,
        scale: 0.92,
        child: SizedBox(
          width: AppSpace.minTarget,
          height: AppSpace.minTarget,
          child: Center(
            child: FinanceIcon(
              FinanceGlyph.info,
              size: _glyphSize,
              color: t.foregroundMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet opened by [SectionInfoButton]: an [AyreSheet] with the
/// explanation and a single "Got it" button.
class _SectionInfoSheet extends StatelessWidget {
  const _SectionInfoSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AyreSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: AppTypo.reading(context.tokens)),
          const SizedBox(height: AppSpace.xl),
          AyreButton(
            label: 'Got it',
            onPressed: () => Navigator.of(context).pop(),
          ),
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

enum AyreButtonKind { primary, outline, danger, destructive }

/// The reference button: 55 minimum height, TL 8 / others 28 silhouette,
/// 15/800 label. Primary is a solid brand fill with `onAccent` content;
/// outline is a 1.5px ink edge with ink content; danger is a transparent
/// button with `negativeText` content and a negative edge. Never saffron.
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

    final (Color bg, Color fg, Color edge, double edgeWidth) = switch (kind) {
      AyreButtonKind.primary => (t.accent, t.onAccent, t.accent, 1.0),
      AyreButtonKind.outline => (
        AppTheme.transparent,
        t.textPrimary,
        t.textPrimary,
        1.5,
      ),
      AyreButtonKind.danger => (
        AppTheme.transparent,
        t.negativeText,
        t.negative.withValues(alpha: 0.6),
        1.5,
      ),
      AyreButtonKind.destructive => (t.negative, t.onAccent, t.negative, 1.0),
    };

    return Semantics(
      label: busy ? '$label, in progress' : label,
      enabled: enabled,
      button: true,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: PressableScale(
          onTap: enabled ? onPressed : null,
          shape: AppShape.button,
          scale: 0.985,
          child: Container(
            width: expand ? double.infinity : null,
            constraints: const BoxConstraints(
              minHeight: AppShape.controlHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s21,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppShape.button,
              border: Border.all(color: edge, width: edgeWidth),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else ...[
                  if (glyph != null) ...[
                    AyreIcon(glyph!, size: 18, color: fg),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypo.button(t, color: fg),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Switch ────────────────────────────────────────────────────────────────

/// The reference switch: 44×26 track (radius 13), 20 thumb, 3 inset. "On" is
/// the brand accent, deliberately never [positive]. The thumb glides on the
/// calm 150ms ease (no spring, no overshoot); the visual track stays 44×26
/// while the interactive area is the full 48 minimum target.
class AyreSwitch extends StatefulWidget {
  const AyreSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  State<AyreSwitch> createState() => _AyreSwitchState();
}

class _AyreSwitchState extends State<AyreSwitch> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = widget.onChanged != null;
    final value = widget.value;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.buttonPress;

    return Semantics(
      label: widget.semanticLabel,
      toggled: value,
      enabled: enabled,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onChanged?.call(!value);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => widget.onChanged!(!value) : null,
          child: SizedBox(
            width: AppShape.switchWidth + 8,
            height: AppSpace.minTarget,
            child: Center(
              child: Opacity(
                opacity: enabled ? 1 : 0.45,
                child: Container(
                  foregroundDecoration: _focused
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppRadius.chip + 3,
                          ),
                          border: Border.all(color: t.focusRing, width: 2),
                        )
                      : null,
                  child: AnimatedContainer(
                    duration: duration,
                    curve: AppMotion.ease,
                    width: AppShape.switchWidth,
                    height: AppShape.switchHeight,
                    padding: const EdgeInsets.all(AppShape.switchInset),
                    decoration: BoxDecoration(
                      color: value ? t.accent : t.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: value ? t.accent : t.hairline),
                    ),
                    child: AnimatedAlign(
                      duration: duration,
                      curve: AppMotion.ease,
                      alignment: value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: AppShape.switchThumb,
                        height: AppShape.switchThumb,
                        decoration: BoxDecoration(
                          // Off thumb is `foregroundMuted` (≥3:1 on the soft
                          // off-track in both themes).
                          color: value ? t.onAccent : t.foregroundMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
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

/// One shared segmented control, used for the appearance selector and similar
/// choices — not a bespoke control per screen.
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
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    final options = [
      for (final segment in segments)
        _Segment(
          segment: segment,
          selected: segment.value == value,
          compact: compact,
          onTap: () => onChanged(segment.value),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: AppShape.field,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < options.length * (24 + 52 * scale)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: options,
            );
          }
          return Row(
            children: [for (final option in options) Expanded(child: option)],
          );
        },
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
      onTap: onTap,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        shape: AppShape.segmentSelected,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.buttonPress,
          curve: AppMotion.ease,
          // 48 pt hit height in both sizes (Spec §9.5); the label wraps
          // rather than shrinking (D-9).
          constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            vertical: compact ? AppSpace.xs : 10,
            horizontal: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? t.accent : AppTheme.transparent,
            borderRadius: AppShape.segmentSelected,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.glyph != null && !compact) ...[
                AyreIcon(segment.glyph!, size: 16, color: fg),
                const SizedBox(height: AppSpace.xs),
              ],
              Text(
                segment.label,
                style: AppTypo.ui(
                  fontSize: AppTextScale.hint,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status chips ──────────────────────────────────────────────────────────

enum ChipTone {
  neutral,
  attention,
  brand,

  /// Positive / verified: success fill, positive text.
  success,

  /// Negative outcome: tinted red fill, negative text.
  negative,

  /// The filled saffron NEW badge (`#2B1600` ink).
  badge,
}

/// Small, flat, caps chip for states like NEW or a verification status.
/// Neutral/attention (muted gold) carries warnings; the brand accent carries
/// identity tags (tiers, badges).
class AyreChip extends StatelessWidget {
  const AyreChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.glyph,
    this.dot = false,
  });

  final String label;
  final ChipTone tone;
  final AyreGlyph? glyph;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (Color fg, Color bg) = switch (tone) {
      ChipTone.neutral => (t.foregroundMuted, t.surfaceRaised),
      ChipTone.attention => (t.neutralText, t.neutralSoft),
      ChipTone.brand => (t.accentInk, t.accentSoft),
      ChipTone.success => (t.positiveText, t.positiveSoft),
      ChipTone.negative => (t.negativeText, t.negativeSoft),
      ChipTone.badge => (t.onHighlight, t.highlight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            DecoratedBox(
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
            const SizedBox(width: AppSpace.xs),
          ] else if (glyph != null) ...[
            AyreIcon(glyph!, size: 12, color: fg),
            const SizedBox(width: AppSpace.xs),
          ],
          // Status words wrap, never truncate (D-1 floor: chips are 11 sp).
          Flexible(
            child: Text(label.toUpperCase(), style: AppTypo.chip(t, color: fg)),
          ),
        ],
      ),
    );
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
    this.toggled,
    this.status,
  });

  final AyreGlyph glyph;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool enabled;
  final bool? toggled;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = danger ? t.negativeText : t.textPrimary;

    final row = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s21,
            vertical: AppSpace.hairlineRowPadding,
          ),
          child: Row(
            children: [
              Container(
                width: AppShape.iconTileSize,
                height: AppShape.iconTileSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: danger ? t.negativeSoft : t.surfaceRaised,
                  borderRadius: AppShape.field,
                ),
                child: AyreIcon(glyph, size: 22, color: tone),
              ),
              const SizedBox(width: AppSpace.s13),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypo.rowLabel(
                        t,
                        color: danger ? t.negativeText : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypo.body(t, color: t.foregroundMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpace.s8),
                Flexible(child: trailing!),
              ],
              if (onTap != null && (trailing == null || status != null)) ...[
                const SizedBox(width: AppSpace.s8),
                AyreIcon(AyreGlyph.forward, size: 18, color: t.foregroundMuted),
              ],
            ],
          ),
        ),
      ),
    );

    if (onTap == null && enabled && toggled == null) return row;

    final action = enabled ? onTap : null;

    return Semantics(
      button: toggled == null,
      enabled: enabled,
      toggled: toggled,
      onTap: action,
      label: [title, ?subtitle, ?status].join(', '),
      excludeSemantics: true,
      child: action == null
          ? row
          : PressableScaleRow(onTap: action, child: row),
    );
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
    this.notch = false,
  });

  /// Where the hairlines start: the row padding, the 44 icon tile and the
  /// gap after it — the Profile/Settings row grammar.
  static const double defaultIndent =
      AppSpace.s21 + AppShape.iconTileSize + AppSpace.s13;

  final List<Widget> children;
  final Color? color;
  final bool notch;

  /// Left inset of the hairlines between rows. Lists whose rows lead with
  /// something other than an 18px icon (an instrument tile)
  /// pass their own leading width so the dividers start at the text, not
  /// under the tile.
  final double indent;

  @override
  Widget build(BuildContext context) {
    return AyreCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      notch: notch,
      clip: true,
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
        backgroundColor: t.surfaceRaised,
        valueColor: AlwaysStoppedAnimation(color ?? t.accent),
      ),
    );
  }
}

// ─── Skeletons ─────────────────────────────────────────────────────────────

/// A soft skeleton block shaped like the content it stands in for. Static by
/// design: the reference loading state is a calm card silhouette, never a
/// spinner and never an endless shimmer or pulse.
class SkeletonBlock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.tokens.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A skeleton list row. [tile] adds the leading
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
        horizontal: AppSpace.s21,
        vertical: dense ? AppSpace.sm : AppSpace.row,
      ),
      child: Row(
        children: [
          if (tile) ...const [
            SkeletonBlock(width: 44, height: 44, radius: AppRadius.iconTile),
            SizedBox(width: AppSpace.s13),
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

/// A restrained, single-play, index-delayed staggered entrance: 13px rise and
/// fade, 55ms stagger (at most four steps), 280 ms duration. Plays once per
/// screen visit and does not replay on tab re-visit or a minor rebuild.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.animate = true,
    this.offset = const Offset(0, AppMotion.entranceRise),
  });

  final Widget child;
  final int index;
  final bool animate;
  final Offset offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delay;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.entrance,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _finish();
    } else if (!_started) {
      _start();
    }
  }

  @override
  void didUpdateWidget(Entrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate && oldWidget.animate) _finish();
  }

  void _finish() {
    _started = true;
    _delay?.cancel();
    _controller.value = 1;
  }

  void _start() {
    _started = true;
    // Cap the stagger budget so the last element in a long list still starts
    // promptly instead of trickling in.
    final delay = AppMotion.stagger * widget.index.clamp(0, 4);
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
/// Selection is not colour-only: the selected chip also gains a filled border,
/// a check mark and heavier text weight, so the active filter survives with colour removed.
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
      value: count?.toString(),
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        shape: AppShape.field,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.buttonPress,
          curve: AppMotion.ease,
          // 48 pt minimum hit height (Phase 3); grows with text scale.
          constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? t.accent : t.surface,
            borderRadius: AppShape.field,
            border: Border.all(color: selected ? t.accent : t.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                AyreIcon(AyreGlyph.check, size: 14, color: fg),
                const SizedBox(width: AppSpace.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypo.ui(
                    fontSize: AppTextScale.body,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpace.xs),
                Figure.static(
                  '$count',
                  fontSize: AppTextScale.hint,
                  fontWeight: FontWeight.w600,
                  color: selected ? fg : t.foregroundMuted,
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
/// **new** shared component: the insight notes' `note.category` label was
/// previously rendered as a bare uppercase [Text] with no pill/fill at all,
/// not an inlined variant of this widget — nothing is retired by adding this.
/// Rewiring that call site onto [TagPill] was left for a later phase.
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: AppShape.field,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypo.chip(t, color: t.foregroundMuted),
      ),
    );
  }
}
