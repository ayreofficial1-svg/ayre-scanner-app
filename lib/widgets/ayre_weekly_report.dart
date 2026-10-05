import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_hills.dart';
import 'ayre_icons.dart';
import 'ayre_instrument_tile.dart';
import 'figure.dart';
import 'pressable_scale.dart';

// ─── Weekly Report (Phase 11 redesign) ─────────────────────────────────────
//
// Presentation-only. Same data, same week navigation, same picker, same
// "See all". Nothing is added to the model.
//
//   ───────────────────────────────────────           hairline separator
//   WEEKLY REPORT                                  ‹ ›
//   1 – 8 Sep 2026 ⌄                                  ← the week, large
//   Latest week · 1 of 3
//
//   ┌──────────────────────────────────────┐
//   │ [logo]  RELIANCE            ┌────────┐│     one card per stock,
//   │         ● Target hit        │+896.40%││     always fully visible:
//   │                             └────────┘│     who → how it ended → how
//   │ ┌─────────────┐ ┌─────────────┐       │     much → the trade
//   │ │ ENTRY       │ │ EXIT        │       │
//   │ │ ₹444.00     │ │ ₹4,424.00   │       │     Entry carries the date of
//   │ │ 1 Sep 2026  │ │ 8 Sep 2026  │       │     recommendation, Exit
//   │ └─────────────┘ └─────────────┘       │     carries the exit date.
//   │ PROFIT / SHARE             +₹3,980    │
//   └──────────────────────────────────────┘
//
// Cards are separated by space, not dividers; the soft green hills in each
// card's corner are the Ayre device, which is what sets this section apart
// from the other Home cards. The return and the profit tile are tinted by
// outcome (green for target, red for stop-loss); direction is also in the
// sign and the written outcome, never colour alone.
//
// Every colour is an `AppThemeTokens` value, so Light and Dark follow the
// theme with no per-mode code.

/// The full Weekly Report section: separator, week header and stock cards.
///
/// [reports] is the backend's list, newest week first (`GET
/// /api/weekly-report`). The first entry is selected initially.
class WeeklyReportCard extends StatefulWidget {
  const WeeklyReportCard({
    super.key,
    required this.reports,
    this.collapsedCount = 3,
  });

  final List<WeeklyReport> reports;

  /// How many stock cards show before "See all". Weeks with this many or
  /// fewer show every card and no control.
  final int collapsedCount;

  @override
  State<WeeklyReportCard> createState() => _WeeklyReportCardState();
}

class _WeeklyReportCardState extends State<WeeklyReportCard> {
  // Selected week is remembered by id so a refresh that inserts a newer week
  // doesn't silently move the user onto another one.
  String? _selectedId;
  bool _showAll = false;

  int get _index {
    final id = _selectedId;
    if (id == null) return 0;
    final i = widget.reports.indexWhere((r) => r.id == id);
    return i < 0 ? 0 : i;
  }

  void _select(int index) {
    if (index < 0 || index >= widget.reports.length || index == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedId = widget.reports[index].id;
      _showAll = false;
    });
  }

  void _openPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => _WeekPickerSheet(
        reports: widget.reports,
        selectedIndex: _index,
        onSelected: _select,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = widget.reports;
    if (reports.isEmpty) return const SizedBox.shrink();

    final index = _index;
    final report = reports[index];
    final stocks = report.stocks;
    final canExpand = stocks.length > widget.collapsedCount;
    final visible = (_showAll || !canExpand)
        ? stocks
        : stocks.take(widget.collapsedCount).toList();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HairlineDivider(),
        const SizedBox(height: AppSpace.md),
        _WeekHeader(
          report: report,
          index: index,
          total: reports.length,
          // Older = next in the newest-first list.
          onOlder: index < reports.length - 1
              ? () => _select(index + 1)
              : null,
          onNewer: index > 0 ? () => _select(index - 1) : null,
          onPick: reports.length > 1 ? _openPicker : null,
        ),
        const SizedBox(height: AppSpace.md),
        AnimatedSize(
          duration: reduceMotion ? Duration.zero : AppMotion.pageTransition,
          curve: AppMotion.ease,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : AppMotion.buttonPress,
            child: Column(
              // Keyed by week only — "See all" animates through AnimatedSize
              // rather than cross-fading the list.
              key: ValueKey(report.id),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpace.cardGap),
                  _StockCard(
                    stock: visible[i],
                    fallbackStart: report.weekStart,
                    fallbackEnd: report.weekEnd,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (canExpand) ...[
          const SizedBox(height: AppSpace.xxs),
          _ExpandToggle(
            expanded: _showAll,
            count: stocks.length,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showAll = !_showAll);
            },
          ),
        ],
      ],
    );
  }
}

// ─── Week header ───────────────────────────────────────────────────────────

/// Eyebrow, the week at display size, and where it sits in the list — on the
/// page itself, not in a card. Older / newer are quiet round buttons on the
/// right; tapping the date opens the week list.
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.report,
    required this.index,
    required this.total,
    required this.onOlder,
    required this.onNewer,
    required this.onPick,
  });

  final WeeklyReport report;
  final int index;
  final int total;
  final VoidCallback? onOlder;
  final VoidCallback? onNewer;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final range = formatWeekRange(report.weekStart, report.weekEnd);
    final spoken = _spokenWeekRange(report.weekStart, report.weekEnd);
    final multiple = total > 1;
    final sub = total == 1
        ? 'Latest week'
        : (index == 0
              ? 'Latest week · 1 of $total'
              : 'Earlier week · ${index + 1} of $total');

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WEEKLY REPORT',
          style: AppTypo.label(t, color: t.foregroundMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  range,
                  maxLines: 1,
                  style: AppTypo.ui(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),
            if (multiple) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 22,
                color: t.foregroundMuted,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: AppTypo.hint(t, color: t.foregroundMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            button: onPick != null,
            label: 'Weekly report, $spoken. $sub.',
            hint: onPick != null ? 'Opens a list of weeks' : null,
            excludeSemantics: true,
            child: onPick == null
                ? titleBlock
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPick,
                    child: titleBlock,
                  ),
          ),
        ),
        if (multiple) ...[
          const SizedBox(width: AppSpace.xs),
          _WeekArrow(
            glyph: AyreGlyph.back,
            label: 'Older week',
            onTap: onOlder,
          ),
          _WeekArrow(
            glyph: AyreGlyph.forward,
            label: 'Newer week',
            onTap: onNewer,
          ),
        ],
      ],
    );
  }
}

/// A 44pt tap target holding a 34pt recessed circle and a chevron. The
/// disabled end fades rather than disappears, so the pair never shifts.
class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  static const double size = 44;

  final AyreGlyph glyph;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: PressableScale(
          onTap: onTap,
          borderRadius: size / 2,
          scale: 0.9,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.surfaceSunken,
                border: Border.all(color: t.hairline),
              ),
              child: Center(
                child: AyreIcon(
                  glyph,
                  size: 16,
                  color: enabled ? t.textPrimary : t.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Week picker ───────────────────────────────────────────────────────────

class _WeekPickerSheet extends StatelessWidget {
  const _WeekPickerSheet({
    required this.reports,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<WeeklyReport> reports;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.xl,
            AppSpace.lg,
            AppSpace.sm,
          ),
          child: Text('Choose a week', style: AppTypo.sectionTitle(t)),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpace.lg),
            itemCount: reports.length,
            separatorBuilder: (_, _) =>
                const HairlineDivider(indent: AppSpace.lg),
            itemBuilder: (context, i) {
              final r = reports[i];
              final selected = i == selectedIndex;
              final count = r.stocks.length;
              return Semantics(
                button: true,
                selected: selected,
                child: PressableScaleRow(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(i);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatWeekRange(r.weekStart, r.weekEnd),
                                style: selected
                                    ? AppTypo.rowLabel(t, color: t.accentInk)
                                    : AppTypo.rowLabel(t),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count ${count == 1 ? 'stock' : 'stocks'}'
                                '${i == 0 ? ' · Latest' : ''}',
                                style: AppTypo.hint(
                                  t,
                                  color: t.foregroundMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          AyreIcon(
                            AyreGlyph.check,
                            size: 18,
                            color: t.accentInk,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Stock card ────────────────────────────────────────────────────────────

/// One stock's result, fully visible — three tiers, top to bottom:
///
///   1. Who and how it ended: logo, symbol, company (when present), a
///      written outcome chip, and the return in a tinted pill.
///   2. The trade: Entry and Exit tiles, each with its date (Entry carries
///      the date of recommendation, Exit the exit date).
///   3. Profit / share, a slim single-line tile — supporting, not a headline.
///
/// [fallbackStart]/[fallbackEnd] are the report's own week range, used only
/// when this stock doesn't carry its own dates — real data, not a guess.
class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.stock,
    required this.fallbackStart,
    required this.fallbackEnd,
  });

  final WeeklyReportStock stock;
  final DateTime? fallbackStart;
  final DateTime? fallbackEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hit = stock.targetHit;
    final tone = hit ? t.positive : t.negative;
    final toneSoft = hit ? t.positiveSoft : t.negativeSoft;
    final outcomeLabel = hit ? 'Target hit' : 'Stop-loss hit';

    final recDate = stock.dateOfRecommendation ?? fallbackStart;
    final exitDate = stock.exitDate ?? fallbackEnd;
    final pnl = stock.pnlAmount;
    final hasName =
        stock.name != null &&
        stock.name!.isNotEmpty &&
        stock.name!.toUpperCase() != stock.symbol.toUpperCase();

    final spoken = [
      stock.symbol,
      if (hasName) stock.name!,
      outcomeLabel,
      '${stock.profitPct.toStringAsFixed(2)} percent',
      if (stock.entryPrice != null)
        'Entry ₹${formatPrice(stock.entryPrice)}'
            '${recDate != null ? ' on ${_shortDate(recDate)}' : ''}',
      if (stock.exitPrice != null)
        'Exit ₹${formatPrice(stock.exitPrice)}'
            '${exitDate != null ? ' on ${_shortDate(exitDate)}' : ''}',
      if (pnl != null) 'Profit per share ${_formatSignedRupees(pnl)}',
    ].join(', ');

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AyreInstrumentTile(
          symbol: stock.symbol,
          size: 52,
          name: hasName ? stock.name : null,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stock.symbol,
                style: AppTypo.ui(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasName) ...[
                const SizedBox(height: 1),
                Text(
                  stock.name!,
                  style: AppTypo.hint(t, color: t.foregroundMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              _OutcomeChip(label: outcomeLabel, tone: tone, soft: toneSoft),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: toneSoft,
            borderRadius: BorderRadius.circular(AppRadius.iconTile),
          ),
          child: Figure.static(
            formatDelta(stock.profitPct),
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: tone,
          ),
        ),
      ],
    );

    final trade = <Widget>[
      if (stock.entryPrice != null)
        Expanded(
          child: _PriceTile(
            label: 'Entry',
            price: stock.entryPrice!,
            date: recDate,
          ),
        ),
      if (stock.entryPrice != null && stock.exitPrice != null)
        const SizedBox(width: AppSpace.xs),
      if (stock.exitPrice != null)
        Expanded(
          child: _PriceTile(
            label: 'Exit',
            price: stock.exitPrice!,
            date: exitDate,
          ),
        ),
    ];

    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: AyreCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            // The Ayre hills, bleeding off the card's top-right corner.
            const Positioned(
              top: 0,
              right: 0,
              child: AyreHills(width: 190, height: 120),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  if (trade.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.md),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: trade,
                      ),
                    ),
                  ],
                  if (pnl != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    _ProfitTile(value: pnl, tone: tone, soft: toneSoft),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `● Target hit` — a small tinted chip; the outcome in words.
class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({
    required this.label,
    required this.tone,
    required this.soft,
  });

  final String label;
  final Color tone;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypo.ui(
                fontSize: AppTextScale.hint,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ENTRY / EXIT: eyebrow, the price, and its date underneath.
class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.label,
    required this.price,
    required this.date,
  });

  final String label;
  final num price;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.inset + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.toUpperCase(), style: AppTypo.label(t, fontSize: 10.5)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Figure.static(
                '₹${formatPrice(price)}',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
            if (date != null) ...[
              const SizedBox(height: 2),
              Text(
                _shortDate(date!),
                style: AppTypo.hint(t, color: t.foregroundMuted),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// PROFIT / SHARE as one slim line — label left, value right — so it
/// supports the return above rather than competing with it.
class _ProfitTile extends StatelessWidget {
  const _ProfitTile({
    required this.value,
    required this.tone,
    required this.soft,
  });

  final num value;
  final Color tone;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.inset + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'PROFIT / SHARE',
                style: AppTypo.label(t, fontSize: 10.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Figure.static(
              _formatSignedRupees(value),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── See all ───────────────────────────────────────────────────────────────

/// "See all N stocks" / "Show less" — an in-place expand of the same week.
/// 48pt tall, above the 44pt floor.
class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({
    required this.expanded,
    required this.count,
    required this.onTap,
  });

  final bool expanded;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      expanded: expanded,
      child: PressableScaleRow(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text(
                expanded ? 'Show less' : 'See all $count stocks',
                style: AppTypo.ui(
                  fontSize: AppTextScale.hint,
                  fontWeight: FontWeight.w700,
                  color: t.accentInk,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────

/// Mirrors the section's shape — separator, week header, two cards — so
/// nothing jumps once real data arrives.
class WeeklyReportSkeleton extends StatelessWidget {
  const WeeklyReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HairlineDivider(),
        SizedBox(height: AppSpace.md),
        SkeletonBlock(width: 110, height: 11),
        SizedBox(height: AppSpace.xs),
        SkeletonBlock(width: 200, height: 26),
        SizedBox(height: AppSpace.xs),
        SkeletonBlock(width: 90, height: 11),
        SizedBox(height: AppSpace.md),
        _StockCardSkeleton(),
        SizedBox(height: AppSpace.cardGap),
        _StockCardSkeleton(),
      ],
    );
  }
}

class _StockCardSkeleton extends StatelessWidget {
  const _StockCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkeletonBlock(width: 52, height: 52, radius: AppRadius.iconTile),
              SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 96, height: 16),
                    SizedBox(height: 8),
                    SkeletonBlock(width: 80, height: 22, radius: 11),
                  ],
                ),
              ),
              SkeletonBlock(width: 88, height: 40, radius: AppRadius.iconTile),
            ],
          ),
          SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: SkeletonBlock(height: 76)),
              SizedBox(width: AppSpace.xs),
              Expanded(child: SkeletonBlock(height: 76)),
            ],
          ),
          SizedBox(height: AppSpace.xs),
          SkeletonBlock(height: 40),
        ],
      ),
    );
  }
}

// ─── Formatting ────────────────────────────────────────────────────────────

/// The week as a compact range with the year — "1 – 8 Sep 2026",
/// "28 Sep – 4 Oct 2026". When the week straddles New Year each end carries
/// its own year ("29 Dec 2026 – 4 Jan 2027"). Computed from the plain ISO
/// dates the backend sends, so the display format can change without a data
/// migration.
String formatWeekRange(DateTime start, DateTime end) {
  const dash = '\u2009–\u2009';
  if (start.year != end.year) {
    return '${_shortDate(start)}$dash${_shortDate(end)}';
  }
  if (start.month == end.month) {
    return '${start.day}$dash${end.day} ${_monthAbbrev[end.month - 1]} '
        '${end.year}';
  }
  return '${start.day} ${_monthAbbrev[start.month - 1]}$dash'
      '${end.day} ${_monthAbbrev[end.month - 1]} ${end.year}';
}

/// The long spoken form — "1st September to 8th September 2026" — used only
/// for screen-reader labels, where "1 – 8 Sep" would be read poorly.
String _spokenWeekRange(DateTime start, DateTime end) {
  if (start.year == end.year) {
    return '${_ordinalDay(start)} to ${_ordinalDay(end)} ${end.year}';
  }
  return '${_ordinalDay(start)} ${start.year} to '
      '${_ordinalDay(end)} ${end.year}';
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

/// "23 Sep 2026" — the detail's compact date format, always with the year.
String _shortDate(DateTime date) =>
    '${date.day} ${_monthAbbrev[date.month - 1]} ${date.year}';

/// A signed rupee amount — "+₹4,200" / "−₹700". Whole-rupee amounts render
/// without decimals; anything with a fractional part keeps two, same
/// rounding [formatPrice] itself uses everywhere else.
String _formatSignedRupees(num value) {
  final sign = value >= 0 ? '+' : '−';
  final abs = value.abs();
  final decimals = abs == abs.roundToDouble() ? 0 : 2;
  return '$sign₹${formatPrice(abs, decimals: decimals)}';
}