import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';

/// The single component every numeric market value renders through, so no screen
/// can fall back to the UI face for a price. It always uses the ticker face with
/// tabular figures.
///
/// When the value changes, **only the digits that actually changed** roll to
/// their new character — an unchanged rupee-lakh digit doesn't twitch because
/// the paise moved. Skipped on first build and under reduced motion.
class Figure extends StatefulWidget {
  const Figure(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.color,
    this.roll = true,
    this.semanticsLabel,
    this.textAlign = TextAlign.left,
  });

  /// A figure that isn't live market data but still belongs in the readout face
  /// (an app version, a static count).
  const Figure.static(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.color,
    this.semanticsLabel,
    this.textAlign = TextAlign.left,
  }) : roll = false;

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final bool roll;
  final String? semanticsLabel;
  final TextAlign textAlign;

  @override
  State<Figure> createState() => _FigureState();
}

class _FigureState extends State<Figure> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _from;
  late String _to;

  @override
  void initState() {
    super.initState();
    _from = widget.text;
    _to = widget.text;
    _controller = AnimationController(vsync: this, duration: AppMotion.digitRoll)
      ..value = 1.0;
  }

  @override
  void didUpdateWidget(Figure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    if (!widget.roll || MediaQuery.disableAnimationsOf(context)) {
      _from = widget.text;
      _to = widget.text;
      _controller.value = 1.0;
      return;
    }
    // Re-target from what's on screen now so a second update mid-roll continues
    // rather than snapping back.
    _from = _controller.isAnimating ? _from : _to;
    _to = widget.text;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = AppTypo.ticker(
      fontSize: widget.fontSize,
      fontWeight: widget.fontWeight,
      color: widget.color ?? tokens.textPrimary,
      height: 1.15,
    );

    // Not rolling, or the string changed shape entirely: render plainly. A
    // shape change (12.5 → 112.50) has no per-digit correspondence to animate.
    if (!widget.roll || _from == _to || _from.length != _to.length) {
      return Text(
        widget.text,
        style: style,
        textAlign: widget.textAlign,
        semanticsLabel: widget.semanticsLabel,
        maxLines: 1,
      );
    }

    final lineHeight = widget.fontSize * 1.15;
    return Semantics(
      label: widget.semanticsLabel ?? _to,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = AppMotion.ease.transform(_controller.value);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _to.length; i++)
                _from[i] == _to[i]
                    // Unchanged: no motion at all.
                    ? Text(_to[i], style: style, maxLines: 1)
                    : _RollingChar(
                        from: _from[i],
                        to: _to[i],
                        progress: t,
                        style: style,
                        height: lineHeight,
                      ),
            ],
          );
        },
      ),
    );
  }
}

/// One character sliding from its old value to its new one, clipped to a single
/// line so it reads as a mechanical roll rather than a fade.
class _RollingChar extends StatelessWidget {
  const _RollingChar({
    required this.from,
    required this.to,
    required this.progress,
    required this.style,
    required this.height,
  });

  final String from;
  final String to;
  final double progress;
  final TextStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(0, -height * progress),
              child: Text(from, style: style, maxLines: 1),
            ),
            Transform.translate(
              offset: Offset(0, height * (1 - progress)),
              child: Text(to, style: style, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// A signed change figure. Color is always a confirming second channel: the sign
/// lives in the string and a directional caret sits beside it, so direction
/// survives with color removed entirely.
class DeltaFigure extends StatelessWidget {
  const DeltaFigure({
    super.key,
    required this.change,
    this.percent = true,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.decimals = 2,
    this.showGlyph = true,
  });

  /// Signed change. Null renders a neutral placeholder.
  final num? change;
  final bool percent;
  final double fontSize;
  final FontWeight fontWeight;

  /// Overrides the semantic gain/loss color, for surfaces that already carry
  /// the direction (e.g. an ink panel).
  final Color? color;
  final int decimals;
  final bool showGlyph;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (change == null) {
      return Figure.static(
        '—',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: t.textTertiary,
      );
    }

    final up = change! >= 0;
    final tone = color ?? (up ? t.jade : t.garnet);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGlyph) ...[
          DirectionGlyph(up: up, color: tone, size: fontSize * 0.78),
          const SizedBox(width: AppSpacing.xs),
        ],
        Figure(
          formatDelta(change!, percent: percent, decimals: decimals),
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: tone,
          semanticsLabel:
              '${up ? 'up' : 'down'} '
              '${change!.abs().toStringAsFixed(decimals)}'
              '${percent ? ' percent' : ''}',
        ),
      ],
    );
  }
}

/// A label above a value — the terminal convention applied in one place so every
/// data point in the app is captioned the same way.
class LabelledFigure extends StatelessWidget {
  const LabelledFigure({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.fontSize = 14,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color? color;
  final double fontSize;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypo.label(t),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Figure(value, fontSize: fontSize, color: color),
      ],
    );
  }
}

// ─── Formatters ────────────────────────────────────────────────────────────

/// Signed, fixed-decimal delta. The sign is part of the string so direction
/// survives where color and glyph are stripped. Uses a true minus, not a hyphen.
String formatDelta(num value, {bool percent = true, int decimals = 2}) {
  final sign = value >= 0 ? '+' : '−';
  return '$sign${_group(value.abs().toStringAsFixed(decimals))}${percent ? '%' : ''}';
}

/// A price or index level, grouped in the Indian convention (12,34,567.80) since
/// this is an Indian-market product.
String formatPrice(num? value, {int decimals = 2}) {
  if (value == null) return '—';
  final body = _group(value.abs().toStringAsFixed(decimals));
  return value < 0 ? '−$body' : body;
}

/// Compact traded volume or value: 1.24Cr, 4.5L, 82.1K.
String formatVolume(num? value) {
  if (value == null) return '—';
  final v = value.abs();
  final (scaled, suffix) = switch (v) {
    >= 10000000 => (v / 10000000, 'Cr'),
    >= 100000 => (v / 100000, 'L'),
    >= 1000 => (v / 1000, 'K'),
    _ => (v, ''),
  };
  if (suffix.isEmpty) return scaled.toStringAsFixed(0);
  return '${scaled.toStringAsFixed(scaled >= 100 ? 0 : 2)}$suffix';
}

String formatClock(DateTime at) {
  final local = at.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String formatClockShort(DateTime at) {
  final local = at.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// Indian digit grouping: the last three digits, then pairs.
String _group(String fixed) {
  final parts = fixed.split('.');
  var digits = parts.first;
  if (digits.length <= 3) return fixed;

  final tail = digits.substring(digits.length - 3);
  var head = digits.substring(0, digits.length - 3);
  final chunks = <String>[];
  while (head.length > 2) {
    chunks.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) chunks.insert(0, head);

  final grouped = '${chunks.join(',')},$tail';
  return parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
}
