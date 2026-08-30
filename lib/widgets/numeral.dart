import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'spring.dart';

/// The single component every live data figure renders through, so no screen
/// can accidentally fall back to the body typeface for a price or percentage.
///
/// It always uses the instrument-readout monospace with tabular figures, and
/// it rolls mechanically through intermediate values when the number changes —
/// a settle, not a flourish. Skipped on first build and under reduced motion.
class Numeral extends StatelessWidget {
  const Numeral(
    this.text, {
    super.key,
    this.value,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w500,
    this.color,
    this.roll = true,
    this.format,
    this.textAlign,
    this.semanticsLabel,
  });

  /// The rendered string. When [value] and [format] are both supplied, the
  /// rolling animation drives the text instead and this is only the fallback.
  final String text;

  /// The numeric value behind [text]. Supplying it (with [format]) enables the
  /// digit-roll.
  final double? value;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final bool roll;
  final String Function(double value)? format;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  /// A figure that isn't live data but still belongs in the readout face
  /// (an app version, a static count).
  const Numeral.static(
    this.text, {
    super.key,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w500,
    this.color,
    this.textAlign,
    this.semanticsLabel,
  }) : value = null,
       roll = false,
       format = null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = AppTypo.dataNum(
      tokens,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );

    if (!roll || value == null || format == null) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        semanticsLabel: semanticsLabel,
      );
    }

    return RollingValue(
      value: value!,
      builder: (context, v) => Text(
        format!(v),
        style: style,
        textAlign: textAlign,
        semanticsLabel: semanticsLabel ?? text,
      ),
    );
  }
}

/// A gain/loss figure. Color is always a confirming second channel: the sign
/// lives in the number itself and a directional glyph sits beside it, so the
/// direction survives with color removed entirely.
class DeltaFigure extends StatelessWidget {
  const DeltaFigure({
    super.key,
    required this.change,
    this.percent = true,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.glyphSize,
    this.color,
    this.decimals = 2,
    this.roll = true,
  });

  /// The signed change. Null renders a neutral placeholder.
  final num? change;
  final bool percent;
  final double fontSize;
  final FontWeight fontWeight;
  final double? glyphSize;

  /// Overrides the semantic gain/loss color — used where the surface already
  /// carries the direction (e.g. inverted hero cards).
  final Color? color;
  final int decimals;
  final bool roll;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (change == null) {
      return Numeral.static(
        '--',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: tokens.textTertiary,
      );
    }

    final up = change! >= 0;
    final tone = color ?? (up ? tokens.positive : tokens.negative);
    final glyph = up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(glyph, size: glyphSize ?? fontSize, color: tone),
        const SizedBox(width: AppSpacing.xxs),
        Numeral(
          formatDelta(change!, percent: percent, decimals: decimals),
          value: roll ? change!.toDouble() : null,
          format: roll
              ? (v) => formatDelta(v, percent: percent, decimals: decimals)
              : null,
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

/// "as of 15:31" — a freshness marker whose time portion is in the readout
/// face. Flags with the ember token and explicit copy once the reading is
/// older than the provider's normal cadence, rather than blanking the value.
class FreshnessMark extends StatelessWidget {
  const FreshnessMark({
    super.key,
    required this.asOf,
    this.stale = false,
    this.staleLabel = 'Data may be delayed',
  });

  final DateTime? asOf;
  final bool stale;
  final String staleLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (asOf == null && !stale) return const SizedBox.shrink();

    final tone = stale ? tokens.accentWarm : tokens.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stale) ...[
          Icon(Icons.schedule_rounded, size: 12, color: tone),
          const SizedBox(width: AppSpacing.xs),
          Text(staleLabel, style: AppTypo.caption(tokens, color: tone)),
          const SizedBox(width: AppSpacing.xs),
        ] else ...[
          Text('as of ', style: AppTypo.caption(tokens, color: tone)),
        ],
        if (asOf != null)
          Numeral.static(
            formatClock(asOf!),
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: tone,
          ),
      ],
    );
  }
}

/// Signed, fixed-decimal delta. The sign is part of the string so the
/// direction survives even where color and glyph are stripped.
String formatDelta(num value, {bool percent = true, int decimals = 2}) {
  final sign = value >= 0 ? '+' : '−'; // true minus, not a hyphen
  return '$sign${value.abs().toStringAsFixed(decimals)}${percent ? '%' : ''}';
}

/// Indian-market convention: 2 decimals, grouped thousands.
String formatPrice(num? value, {int decimals = 2}) {
  if (value == null) return '--';
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final digits = parts.first;
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final body = parts.length > 1 ? '$grouped.${parts[1]}' : grouped.toString();
  return value < 0 ? '−$body' : body;
}

/// Compact volume/traded-value figures: 1.2Cr, 4.5L, 82.1K.
String formatVolume(num? value) {
  if (value == null) return '--';
  final v = value.abs();
  final (scaled, suffix) = switch (v) {
    >= 10000000 => (v / 10000000, 'Cr'),
    >= 100000 => (v / 100000, 'L'),
    >= 1000 => (v / 1000, 'K'),
    _ => (v, ''),
  };
  final text = scaled >= 100 || suffix.isEmpty
      ? scaled.toStringAsFixed(0)
      : scaled.toStringAsFixed(1);
  return '$text$suffix';
}

String formatClock(DateTime at) {
  final local = at.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
