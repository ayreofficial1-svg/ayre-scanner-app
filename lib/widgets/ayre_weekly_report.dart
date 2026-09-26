import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'figure.dart';

// ─── Weekly Report (Phase 5; moved to Home in Phase 2; restyled in Phase 3;
// redesigned in Phase 6 after a reference screenshot of a trade-card style
// weekly report) ──────────────────────────────────────────────────────────
//
// Phase 6 extends `WeeklyReportStock` (`market_models.dart`) with a set of
// OPTIONAL fields the admin can now fill in on the website — `name`,
// `bullish`, `tradeLabel`, `entryPrice`, `exitPrice`, `pnlAmount`,
// `dateOfRecommendation`, `exitDate`, `durationDays` — instead of replacing
// the feature. Every one of Phase 3's original fields (`symbol`,
// `profitPct`, `outcome`) keeps meaning exactly what it always has, and a
// report saved before Phase 6 (none of the new fields present) still
// renders correctly: [WeeklyReportStockCard] falls back to Phase 3's plain
// single-headline layout whenever `pnlAmount` is absent, so nothing that
// used to display now shows a hole or an invented number.
//
// Two week-level dates already existed and are real, not invented
// (`report.weekStart`/`weekEnd`, shown in the section's subtitle via
// [formatWeekRange]); the new details band's Date/Duration/Exit-date rows
// fall back to those when a stock doesn't carry its own dates, rather than
// fabricating a value the backend never sent.
//
// What's carried over from the reference image, adapted to this app's own
// components rather than copied: per-stock containment in its own card
// (unchanged since Phase 3); a bullish/bearish tag using the exact
// [DirectionBadge] component `signals_tab.dart`'s featured signal already
// uses for the same concept; a trade-description row with right-aligned
// entry/exit columns; a colour-tinted headline band split into a P&L amount
// row and a % return row; and a plain details band for the recommendation
// date, duration and exit date. Every colour is an existing
// `AppThemeTokens` value — no new component-specific colour constant was
// needed.

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
          WeeklyReportStockCard(
            stock: report.stocks[i],
            fallbackStart: report.weekStart,
            fallbackEnd: report.weekEnd,
          ),
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

/// One stock's result, as its own bounded, tinted, radiused card.
///
/// Three visually distinct bands, so identity, trade detail and outcome
/// never blur together: a plain header carrying the symbol/name and a
/// bullish/bearish tag; an optional trade-description row with right-aligned
/// entry/exit prices; an outcome-tinted band holding the P&L headline; and a
/// plain details band for the recommendation date, duration and exit date.
///
/// [fallbackStart]/[fallbackEnd] are the report's own week range, used only
/// when this stock doesn't carry its own [WeeklyReportStock.dateOfRecommendation]
/// / [WeeklyReportStock.exitDate] — real data already shown in the section's
/// subtitle, not a guess.
class WeeklyReportStockCard extends StatelessWidget {
  const WeeklyReportStockCard({
    super.key,
    required this.stock,
    this.fallbackStart,
    this.fallbackEnd,
  });

  final WeeklyReportStock stock;
  final DateTime? fallbackStart;
  final DateTime? fallbackEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = stock.targetHit ? t.positive : t.negative;
    final soft = stock.targetHit ? t.positiveSoft : t.negativeSoft;
    final outcomeLabel = stock.targetHit ? 'Target hit' : 'Stop-loss hit';

    final recDate = stock.dateOfRecommendation ?? fallbackStart;
    final exitDate = stock.exitDate ?? fallbackEnd;
    final duration =
        stock.durationDays ??
        ((recDate != null && exitDate != null)
            ? exitDate.difference(recDate).inDays + 1
            : null);

    final hasTradeRow = (stock.tradeLabel != null && stock.tradeLabel!.isNotEmpty) ||
        stock.entryPrice != null ||
        stock.exitPrice != null;
    final hasDetails = recDate != null || exitDate != null || duration != null;

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
            _StockHeader(stock: stock, tone: tone, soft: soft),
            if (hasTradeRow) ...[
              const HairlineDivider(),
              _TradeRow(stock: stock, tone: tone),
            ],
            const HairlineDivider(),
            _OutcomeBand(
              stock: stock,
              tone: tone,
              soft: soft,
            ),
            if (hasDetails) ...[
              const HairlineDivider(),
              _DetailsBand(
                recDate: recDate,
                exitDate: exitDate,
                duration: duration,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Identity header — symbol, optional company name, and a bullish/bearish
/// tag using the same [DirectionBadge] `signals_tab.dart`'s featured signal
/// card already uses for this exact concept.
class _StockHeader extends StatelessWidget {
  const _StockHeader({required this.stock, required this.tone, required this.soft});

  final WeeklyReportStock stock;
  final Color tone;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasName = stock.name != null &&
        stock.name!.isNotEmpty &&
        stock.name!.toUpperCase() != stock.symbol.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stock.symbol,
                  style: AppTypo.cardTitle(t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasName)
                  Text(
                    stock.name!,
                    style: AppTypo.hint(t, color: t.foregroundSubtle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          ShrinkTrailing(
            child: DirectionBadge(
              up: stock.bullish,
              label: stock.bullish ? 'Bullish' : 'Bearish',
            ),
          ),
        ],
      ),
    );
  }
}

/// The trade-description row — e.g. "BUY SEP 3850 CE" — with right-aligned
/// entry/exit price columns. Only rendered when the admin has entered a
/// trade label or a price, since not every historical row will have one.
class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.stock, required this.tone});

  final WeeklyReportStock stock;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    (stock.tradeLabel != null && stock.tradeLabel!.isNotEmpty)
                        ? stock.tradeLabel!
                        : 'Single stock trade',
                    style: AppTypo.rowLabel(t),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (stock.entryPrice != null) ...[
            const SizedBox(width: AppSpace.md),
            _PriceStat(label: 'Entry', value: stock.entryPrice!),
          ],
          if (stock.exitPrice != null) ...[
            const SizedBox(width: AppSpace.md),
            _PriceStat(label: 'Exit', value: stock.exitPrice!),
          ],
        ],
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  const _PriceStat({required this.label, required this.value});

  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTypo.label(t, fontSize: 10)),
        const SizedBox(height: 2),
        Figure('₹${formatPrice(value)}', fontSize: 13, fontWeight: FontWeight.w600),
      ],
    );
  }
}

/// The outcome-tinted headline band. With [WeeklyReportStock.pnlAmount] set,
/// shows a Profit/Loss ₹ amount row and a separate % Return row (the
/// reference-image split); without it, falls back exactly to Phase 3's
/// single big % headline plus supporting sentence, so older admin-entered
/// rows are unaffected.
class _OutcomeBand extends StatelessWidget {
  const _OutcomeBand({
    required this.stock,
    required this.tone,
    required this.soft,
  });

  final WeeklyReportStock stock;
  final Color tone;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pnl = stock.pnlAmount;

    return DecoratedBox(
      decoration: BoxDecoration(color: soft),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.md,
        ),
        child: pnl == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DeltaFigure(
                    change: stock.profitPct,
                    color: tone,
                    fontSize: AppTextScale.featuredHeadline,
                    fontWeight: FontWeight.w700,
                    // The header's bullish/bearish tag already carries
                    // direction; a second arrow here (keyed to `profitPct`'s
                    // sign, not `outcome`) could disagree with it on an
                    // edge-case row and read as a contradiction.
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
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pnl >= 0 ? 'Profit' : 'Loss',
                        style: AppTypo.body(t, color: t.foregroundSubtle),
                      ),
                      const Spacer(),
                      Figure(
                        _formatSignedRupees(pnl),
                        fontSize: AppTextScale.featuredHeadline,
                        fontWeight: FontWeight.w700,
                        color: tone,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  const HairlineDivider(indent: 0, endIndent: 0),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '% Return',
                        style: AppTypo.body(t, color: t.foregroundSubtle),
                      ),
                      const Spacer(),
                      DeltaFigure(
                        change: stock.profitPct,
                        color: tone,
                        fontSize: AppTextScale.rowLabel,
                        fontWeight: FontWeight.w700,
                        showGlyph: false,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// The plain details band — recommendation date, duration (in days) and
/// exit date — separated from the outcome band by a hairline so it reads as
/// bookkeeping rather than part of the P&L headline.
class _DetailsBand extends StatelessWidget {
  const _DetailsBand({this.recDate, this.exitDate, this.duration});

  final DateTime? recDate;
  final DateTime? exitDate;
  final int? duration;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      if (recDate != null)
        _DetailRow('Date of recommendation', _shortDate(recDate!)),
      if (duration != null) _DetailRow('Duration', '$duration'),
      if (exitDate != null) _DetailRow('Exit Date', _shortDate(exitDate!)),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AppSpace.xs),
              const HairlineDivider(),
              const SizedBox(height: AppSpace.xs),
            ],
            Row(
              children: [
                Text(rows[i].label, style: AppTypo.body(t, color: t.foregroundSubtle)),
                const Spacer(),
                Text(rows[i].value, style: AppTypo.bodyStrong(t)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
}

/// Mirrors [WeeklyReportStockCard]'s expanded shape, so nothing visibly
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
                SkeletonBlock(width: 72, height: 20, radius: AppRadius.pill),
              ],
            ),
          ),
          const HairlineDivider(),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            child: Row(
              children: [
                Expanded(child: SkeletonBlock(height: 14)),
                SizedBox(width: AppSpace.md),
                SkeletonBlock(width: 48, height: 14),
                SizedBox(width: AppSpace.md),
                SkeletonBlock(width: 48, height: 14),
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
          const HairlineDivider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              AppSpace.md,
            ),
            child: Column(
              children: [
                SkeletonBlock(height: 12),
                SizedBox(height: AppSpace.sm),
                SkeletonBlock(height: 12),
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

const List<String> _monthAbbrev = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

/// "23 Sep 2026" — the details band's compact date format, distinct from
/// [formatWeekRange]'s ordinal-day style used by the section subtitle.
String _shortDate(DateTime date) =>
    '${date.day} ${_monthAbbrev[date.month - 1]} ${date.year}';

/// A signed rupee amount — "+₹4,200" / "−₹700" — for the P&L headline row.
/// Whole-rupee amounts render without decimals; anything with a fractional
/// part keeps two, same rounding [formatPrice] itself uses everywhere else.
String _formatSignedRupees(num value) {
  final sign = value >= 0 ? '+' : '−';
  final abs = value.abs();
  final decimals = abs == abs.roundToDouble() ? 0 : 2;
  return '$sign₹${formatPrice(abs, decimals: decimals)}';
}
