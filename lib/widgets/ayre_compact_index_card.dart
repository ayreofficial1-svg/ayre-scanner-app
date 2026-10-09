import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_index_art.dart';
import 'figure.dart';

/// Sizes for the compact index card. Scoped to this file on purpose: the
/// shared `AppTextScale` / `AppSpace` tokens are used by other surfaces and
/// must not change for Home's benefit.
abstract final class _CompactIndexScale {
  /// Card height at default text scale. The card's own text is capped at
  /// [maxTextScale] and the height grows with it, so a horizontal list never
  /// gets an unbounded or too-small height.
  static const double baseHeight = 104;
  static const double maxTextScale = 1.3;

  /// Narrowest a card may get before the row scrolls instead of shrinking it.
  static const double minWidth = 148;

  static const double padding = AppSpace.sm;
  static const double nameFontSize = 13;
  static const double levelFontSize = 20;
  static const double deltaFontSize = 12;
  static const double pointsFontSize = 11;
  static const double dotSize = 7;
}

/// Layout numbers the Home row needs, kept next to the card that defines them.
abstract final class AyreCompactIndexMetrics {
  static const double minWidth = _CompactIndexScale.minWidth;

  /// The card height for the ambient text scale.
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return _CompactIndexScale.baseHeight *
        scale.clamp(1.0, _CompactIndexScale.maxTextScale);
  }
}

/// One index as a compact, rounded rectangle: name (with a live dot while the
/// feed is fresh), the level, and the percent and point change. The whole card
/// is the tap target into Index Detail.
///
/// A stale feed shows no dot — never a "Live" it hasn't earned, never
/// "Delayed". Colour is never the only carrier of direction: [DeltaFigure]
/// also prints the sign and a glyph, and the semantics label says up or down.
///
/// Size the card from outside (a tight width and height); it fills what it is
/// given.
class AyreCompactIndexCard extends StatelessWidget {
  const AyreCompactIndexCard({
    super.key,
    required this.quote,
    required this.indexId,
    required this.stale,
    required this.onTap,
  });

  final Quote quote;
  final IndexId? indexId;
  final bool stale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tint = AyreIndexIdentity.of(context, indexId).tint;
    final up = quote.percentChange >= 0;
    final scaler = MediaQuery.textScalerOf(context);
    final capped = scaler.scale(1) > _CompactIndexScale.maxTextScale
        ? const TextScaler.linear(_CompactIndexScale.maxTextScale)
        : scaler;

    final label =
        '${quote.name}, ${formatPrice(quote.lastPrice)}, '
        '${up ? 'up' : 'down'} '
        '${quote.percentChange.abs().toStringAsFixed(2)} percent, '
        'opens details';

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: capped),
        child: AyreCard(
          onTap: onTap,
          // `AppRadius.card` (the default) matches the Sentiment and Signal
          // cards on the same page.
          color: tint.cardBackground,
          padding: const EdgeInsets.all(_CompactIndexScale.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quote.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypo.ui(
                        fontSize: _CompactIndexScale.nameFontSize,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  if (!stale) ...[
                    const SizedBox(width: AppSpace.xs),
                    LivePulseDot(
                      color: t.positive,
                      size: _CompactIndexScale.dotSize,
                    ),
                  ],
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CountUpFigure(
                  value: quote.lastPrice.toDouble(),
                  // Starts within sight of the target so a five-figure level
                  // settles rather than spinning up from zero.
                  from: quote.lastPrice.toDouble() - quote.change.toDouble(),
                  format: (v) => formatPrice(v),
                  fontSize: _CompactIndexScale.levelFontSize,
                  color: t.textPrimary,
                  semanticsLabel:
                      '${quote.name} at ${formatPrice(quote.lastPrice)}',
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    DeltaFigure(
                      change: quote.percentChange,
                      fontSize: _CompactIndexScale.deltaFontSize,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Figure(
                      formatDelta(quote.change, percent: false),
                      fontSize: _CompactIndexScale.pointsFontSize,
                      color: t.foregroundMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors [AyreCompactIndexCard] block for block so nothing jumps when data
/// lands. Size it from outside, like the card.
class AyreCompactIndexCardSkeleton extends StatelessWidget {
  const AyreCompactIndexCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      padding: EdgeInsets.all(_CompactIndexScale.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBlock(width: 72, height: 12),
          SkeletonBlock(width: 96, height: 20, radius: AppRadius.inset),
          SkeletonBlock(width: 80, height: 10),
        ],
      ),
    );
  }
}