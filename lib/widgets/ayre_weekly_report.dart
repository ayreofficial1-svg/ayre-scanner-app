import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'figure.dart';

// ─── Weekly Report (Phase 5; moved to Home in Phase 2; restyled in Phase 3) ─
//
// Moved here from `lib/screens/signals_tab.dart` in Phase 2. Phase 3 restyles
// the per-stock presentation from a hairline-divided row list into its own
// bounded, outcome-highlighted card per stock — see [WeeklyReportStockCard].
// Nothing about the section's heading, week-range subtitle, data source, or
// loading/failed/empty behaviour changes here; only how each stock reads.
//
// Reference-image ideas that could NOT be carried over, because
// `WeeklyReportStock` (`market_models.dart`) only carries `symbol`,
// `profitPct` and `outcome` — no entry/exit price fields, no trade-type
// descriptor, and no per-stock date/duration — so building side-by-side
// entry/exit columns, an options-style trade-type label, or a dates/duration
// detail block would mean inventing data the backend never sends. Only the
// week-level range (already shown in the section's subtitle, via
// [formatWeekRange]) is real. What *is* carried over: per-stock containment
// in its own card, a distinct identity header separated from the numbers, a
// bold color-coded headline outcome, and a quieter supporting line beneath
// it, built entirely from the fields the model actually has.

/// The Weekly Report section body — each stock in its own
/// [WeeklyReportStockCard], followed by the always-visible disclaimer
/// (§A.3, §A.9).
class WeeklyReportCard extends StatelessWidget {
  const WeeklyReportCard({super.key, required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < report.stocks.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.cardGap),
          WeeklyReportStockCard(stock: report.stocks[i]),
        ],
        const SizedBox(height: AppSpace.sm),
        // Compliance-relevant, so this stays plain, factual and always
        // visible — never behind a tap, never marketing copy (§A.3, §A.9).
        Text(
          'Historical results, shown for transparency. Past performance '
          'does not guarantee similar results in future.',
          style: AppTypo.hint(t, color: t.foregroundSubtle),
        ),
      ],
    );
  }
}

/// One stock's result, as its own bounded, tinted, radiused card — the same
/// "give each thing its own card rather than a shared row list" pattern
/// `_IndexCard` already uses for the index board, rather than a
/// hairline-divided row.
///
/// Two visually distinct bands, so identity and outcome never blur together
/// (reference-image idea): a plain header carrying the symbol and a quiet
/// outcome label, and — beneath a hairline — an outcome-tinted band holding
/// the headline profit/loss figure set large and bold, with a quieter
/// supporting line beneath it. The tint and the headline color both come
/// from [WeeklyReportStock.outcome], never the raw sign of [profitPct] — a
/// stop-loss row is transparency, not an error state, matching the same
/// distinction `_Mood.bearish` draws elsewhere in this app (§A.9).
///
/// Every color here is an existing `AppThemeTokens` value
/// (`positive`/`negative`/`positiveSoft`/`negativeSoft`/`surface`/
/// `foregroundSubtle`) — the same soft-background-plus-solid-foreground
/// pairing `DirectionBadge` and the "Live" chip already use elsewhere in this
/// codebase — so no new component-specific color constant was needed for
/// this widget.
class WeeklyReportStockCard extends StatelessWidget {
  const WeeklyReportStockCard({super.key, required this.stock});

  final WeeklyReportStock stock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = stock.targetHit ? t.positive : t.negative;
    final soft = stock.targetHit ? t.positiveSoft : t.negativeSoft;
    final outcomeLabel = stock.targetHit ? 'Target hit' : 'Stop-loss hit';

    return Semantics(
      label:
          '${stock.symbol}, $outcomeLabel, '
          '${stock.profitPct.toStringAsFixed(2)} percent',
      excludeSemantics: true,
      child: AyreCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identity header — the card's plain `surface` background (via
            // `AyreCard`'s own default), kept visually distinct from the
            // outcome-tinted band beneath it.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.md,
                AppSpace.md,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: soft),
                    child: AyreIcon(AyreGlyph.equity, size: 16, color: tone),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      stock.symbol,
                      style: AppTypo.cardTitle(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(outcomeLabel.toUpperCase(), style: AppTypo.label(t, color: tone)),
                ],
              ),
            ),
            const HairlineDivider(),
            // Outcome band — the headline figure, larger and bolder than
            // anything else on the card, colored by outcome; a quieter
            // supporting line sits beneath it.
            DecoratedBox(
              decoration: BoxDecoration(color: soft),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DeltaFigure(
                      change: stock.profitPct,
                      color: tone,
                      fontSize: AppTextScale.featuredHeadline,
                      fontWeight: FontWeight.w700,
                      // The header's outcome label already carries the
                      // direction; a second arrow here (which `DeltaFigure`
                      // would key to `profitPct`'s sign, not `outcome`) could
                      // disagree with it on an edge-case row and read as a
                      // contradiction.
                      showGlyph: false,
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      stock.targetHit
                          ? 'Closed the week at target.'
                          : 'Closed the week at stop-loss.',
                      style: AppTypo.hint(t, color: t.foregroundSubtle),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors [WeeklyReportStockCard]'s two-band shape, so nothing visibly
/// jumps in size or position once real data replaces the skeleton.
class WeeklyReportSkeleton extends StatelessWidget {
  const WeeklyReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeeklyReportStockCardSkeleton(),
        SizedBox(height: AppSpace.cardGap),
        _WeeklyReportStockCardSkeleton(),
      ],
    );
  }
}

class _WeeklyReportStockCardSkeleton extends StatelessWidget {
  const _WeeklyReportStockCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return AyreCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.md,
              AppSpace.md,
              AppSpace.sm,
            ),
            child: Row(
              children: [
                SkeletonBlock(width: 32, height: 32, radius: AppRadius.circle),
                SizedBox(width: AppSpace.sm),
                Expanded(child: SkeletonBlock(height: 16)),
                SizedBox(width: AppSpace.sm),
                SkeletonBlock(width: 64, height: 12),
              ],
            ),
          ),
          const HairlineDivider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              AppSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 96, height: 26),
                SizedBox(height: AppSpace.xxs),
                SkeletonBlock(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a week's date range the way the Weekly Report section always
/// shows it — e.g. "6th September to 12th September". Computed here, from
/// the plain ISO dates the backend sends, rather than expecting a
/// pre-formatted string from the API (see [WeeklyReport]'s doc comment) —
/// so the display format can change later without a data migration.
String formatWeekRange(DateTime start, DateTime end) {
  return '${_ordinalDay(start)} to ${_ordinalDay(end)}';
}

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _ordinalDay(DateTime date) =>
    '${date.day}${_ordinalSuffix(date.day)} ${_monthNames[date.month - 1]}';

String _ordinalSuffix(int day) {
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
