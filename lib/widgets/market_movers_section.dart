import 'package:flutter/material.dart';

import '../services/market_movers_service.dart';
import '../theme/app_theme.dart';
import 'app_states.dart';
import 'numeral.dart';
import 'premium_widgets.dart';
import 'spring.dart';

/// One market-mover section — Top Gainers, Top Losers, or Most Active Equities.
///
/// Every numeral in here goes through [Numeral], so last price, absolute change,
/// percentage change and volume are all in the instrument monospace without
/// exception. Direction is carried by the sign in the number and a directional
/// glyph; color only confirms it.
///
/// A failed fetch is scoped to this section: it shows the calm error template
/// in place and leaves the rest of Home alone.
class MarketMoversSection extends StatelessWidget {
  const MarketMoversSection({
    super.key,
    required this.title,
    required this.result,
    required this.loading,
    this.showVolume = false,
    this.maxRows = 5,
    this.emptyMessage = 'Nothing to show right now.',
  });

  final String title;

  /// Null while the first request is still in flight.
  final MarketMoversResult? result;
  final bool loading;

  /// Most Active leads with traded volume/value; the other two lead with the
  /// percentage change.
  final bool showVolume;
  final int maxRows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final data = result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTypo.sectionEyebrow(tokens),
              ),
            ),
            if (data != null && data.rows.isNotEmpty)
              FreshnessMark(asOf: _newestAsOf(data.rows), stale: data.stale),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (loading && data == null)
          PremiumCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) const SkeletonRow(height: 44),
              ],
            ),
          )
        else if (data == null || data.failed)
          const AppStateMessage(
            icon: Icons.cloud_off_rounded,
            heading: 'Could not load this list',
            message: 'Pull down to try again.',
            compact: true,
          )
        else if (data.isEmpty)
          AppStateMessage(
            icon: Icons.horizontal_rule_rounded,
            heading: 'No movers',
            message: emptyMessage,
            compact: true,
          )
        else
          LiveDataPulse(
            trigger: _newestAsOf(data.rows),
            child: PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, row) in _visible(data.rows).indexed) ...[
                    if (i > 0) const HairlineDivider(indent: AppSpacing.lg),
                    _MoverRow(mover: row, showVolume: showVolume),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<MarketMover> _visible(List<MarketMover> rows) =>
      rows.length <= maxRows ? rows : rows.sublist(0, maxRows);

  DateTime? _newestAsOf(List<MarketMover> rows) {
    if (rows.isEmpty) return null;
    return rows.map((r) => r.asOf).reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({required this.mover, required this.showVolume});

  final MarketMover mover;
  final bool showVolume;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Rows aren't interactive: there's no stock-detail or trading surface
    // anywhere in the app for them to lead to, and inventing one just to give
    // the row a destination would be worse than leaving it static.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mover.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypo.cardTitle(tokens).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(
                  mover.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypo.caption(tokens),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (showVolume && mover.volumeOrValue != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Numeral(
                  formatVolume(mover.volumeOrValue),
                  value: mover.volumeOrValue!.toDouble(),
                  format: formatVolume,
                  fontSize: 13,
                  color: tokens.textSecondary,
                ),
                Text('VOL', style: AppTypo.microLabel(tokens)),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Numeral(
                formatPrice(mover.lastPrice),
                value: mover.lastPrice.toDouble(),
                format: formatPrice,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Numeral(
                    formatDelta(mover.change, percent: false),
                    value: mover.change.toDouble(),
                    format: (v) => formatDelta(v, percent: false),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: tokens.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  DeltaFigure(change: mover.percentChange, fontSize: 12),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
