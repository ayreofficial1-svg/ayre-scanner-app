import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'figure.dart';

// ─── Weekly Report (Phase 5; moved to Home in Phase 2) ─────────────────────
//
// Moved here from `lib/screens/signals_tab.dart` in Phase 2, unchanged in
// visual form — Phase 2 only relocates the feature from the bottom of the
// Signals tab to the Home tab, directly below the index board. Phase 3
// restyles this presentation; nothing here changes that.

/// The Weekly Report card — one week's admin-entered rows plus the
/// always-visible disclaimer (§A.3, §A.9). An accent-edged border marks it as
/// a highlight, the same "tinted border, never a tinted fill" convention
/// `_FeaturedSignal` uses on the Signals tab, rather than introducing a new
/// treatment.
class WeeklyReportCard extends StatelessWidget {
  const WeeklyReportCard({super.key, required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyreCard(
      accentEdge: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < report.stocks.length; i++) ...[
            if (i > 0) const HairlineDivider(indent: AppSpace.md),
            WeeklyReportRow(stock: report.stocks[i]),
          ],
          const HairlineDivider(),
          // Compliance-relevant, so this stays plain, factual and always
          // visible — never behind a tap, never marketing copy (§A.3, §A.9).
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Text(
              'Historical results, shown for transparency. Past performance '
              'does not guarantee similar results in future.',
              style: AppTypo.hint(t, color: t.foregroundSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

/// One stock row in the Weekly Report card: symbol + outcome on the left,
/// the profit percentage on the right. The direction glyph and figure are
/// colored by [WeeklyReportStock.outcome], not by the sign of the percentage
/// — a stop-loss row is transparency, not an error state, so it takes
/// `t.negative` the same way `_Mood.bearish` does for a plain market
/// reading elsewhere in the app (§A.9), never an alarm color.
class WeeklyReportRow extends StatelessWidget {
  const WeeklyReportRow({super.key, required this.stock});

  final WeeklyReportStock stock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = stock.targetHit ? t.positive : t.negative;
    final outcomeLabel = stock.targetHit ? 'Target hit' : 'Stop-loss hit';

    return Semantics(
      label:
          '${stock.symbol}, $outcomeLabel, '
          '${stock.profitPct.toStringAsFixed(2)} percent',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.hairlineRowPadding,
        ),
        child: Row(
          children: [
            AyreIcon(
              stock.targetHit ? AyreGlyph.trendUp : AyreGlyph.trendDown,
              size: 16,
              color: tone,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: AppTypo.rowLabel(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(outcomeLabel, style: AppTypo.hint(t, color: tone)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            DeltaFigure(
              change: stock.profitPct,
              color: tone,
              fontSize: AppTextScale.body,
              // The leading AyreIcon above already carries the outcome's
              // direction; a second arrow here (which DeltaFigure would key
              // to profit_pct's sign, not outcome) could disagree with it on
              // an edge-case row and read as a contradiction.
              showGlyph: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors [WeeklyReportCard]'s shape, so nothing jumps when data lands.
class WeeklyReportSkeleton extends StatelessWidget {
  const WeeklyReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          SkeletonTickerRow(),
          SkeletonTickerRow(),
          SkeletonTickerRow(),
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
