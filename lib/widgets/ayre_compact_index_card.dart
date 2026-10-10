import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_index_art.dart';
import 'figure.dart';

/// Sizes for the compact index card (D-1: name 14, level 22, delta 13,
/// points 12). Scoped to this file on purpose.
abstract final class _CompactIndexScale {
  /// Card height at default text scale in the horizontal scroller. It grows
  /// with text scale up to [stackAbove]; beyond that the board stops being a
  /// scroller and becomes a vertical list of content-height cards, so text is
  /// reflowed rather than shrunk or capped.
  static const double baseHeight = 112;

  /// Above this text scale the horizontal row cannot hold a five-figure level
  /// at full size, so Home stacks the cards.
  static const double stackAbove = 1.15;

  /// Narrowest a card may get before the row scrolls instead of shrinking it.
  static const double minWidth = 164;

  static const double padding = AppSpace.md;
  static const double nameFontSize = 14;
  static const double levelFontSize = 22;
  static const double deltaFontSize = 13;
  static const double pointsFontSize = 12;
  static const double dotSize = 7;
}

/// Layout numbers the Home row needs, kept next to the card that defines them.
abstract final class AyreCompactIndexMetrics {
  static const double minWidth = _CompactIndexScale.minWidth;

  /// True when the ambient text scale is too large for the horizontal row;
  /// Home then lays the cards out as a vertical list.
  static bool stacksFor(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > _CompactIndexScale.stackAbove;

  /// The card height for the horizontal row at the ambient text scale.
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return _CompactIndexScale.baseHeight *
        scale.clamp(1.0, _CompactIndexScale.stackAbove);
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
/// Size the card from outside: a tight width and height (the horizontal row)
/// or just a width, in which case it is as tall as its content (the stacked
/// list). Text is never shrunk or capped; the name wraps.
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
    final label =
        '${quote.name}, ${formatPrice(quote.lastPrice)}, '
        '${up ? 'up' : 'down'} '
        '${quote.percentChange.abs().toStringAsFixed(2)} percent, '
        'opens details';

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AyreCard(
        onTap: onTap,
        // `AppRadius.card` (the default) matches the Sentiment and Signal
        // cards on the same page.
        color: tint.cardBackground,
        padding: const EdgeInsets.all(_CompactIndexScale.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    quote.name,
                    maxLines: 2,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: LivePulseDot(
                      color: t.positive,
                      size: _CompactIndexScale.dotSize,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            // The level is a numeral whose truncation would hide data: the
            // one documented FittedBox (D-9 exception) in this card.
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
            const SizedBox(height: AppSpace.xs),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.xs,
              children: [
                DeltaFigure(
                  change: quote.percentChange,
                  fontSize: _CompactIndexScale.deltaFontSize,
                ),
                Figure(
                  formatDelta(quote.change, percent: false),
                  fontSize: _CompactIndexScale.pointsFontSize,
                  color: t.foregroundMuted,
                ),
              ],
            ),
          ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBlock(width: 72, height: 14),
          SizedBox(height: AppSpace.xs),
          SkeletonBlock(width: 96, height: 22, radius: AppRadius.inset),
          SizedBox(height: AppSpace.xs),
          SkeletonBlock(width: 80, height: 13),
        ],
      ),
    );
  }
}