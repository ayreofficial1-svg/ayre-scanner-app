import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'finance_icons.dart';
import 'ayre_instrument_tile.dart';
import 'ayre_masthead.dart';
import 'ayre_sheet.dart';
import 'ayre_tab_scroll.dart';
import 'figure.dart';
import 'pressable_scale.dart';

/// The selected published week, its full summary and its result cards.
class WeeklyReportCard extends StatefulWidget {
  const WeeklyReportCard({
    super.key,
    required this.reports,
    this.collapsedCount = 3,
    this.controller,
    this.onRefresh,
    this.stale = false,
  });

  final List<WeeklyReport> reports;
  final int collapsedCount;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;
  final bool stale;

  @override
  State<WeeklyReportCard> createState() => _WeeklyReportCardState();
}

class _WeeklyReportCardState extends State<WeeklyReportCard> {
  String? _selectedId;
  bool _showAll = false;
  late final String? _firstWeek = widget.reports.firstOrNull?.id;
  bool _changedWeek = false;

  int get _index {
    final i = widget.reports.indexWhere((report) => report.id == _selectedId);
    return i < 0 ? 0 : i;
  }

  @override
  void didUpdateWidget(WeeklyReportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIndex = oldWidget.reports.indexWhere(
      (report) => report.id == _selectedId,
    );
    final previousId = oldWidget.reports.isEmpty
        ? null
        : oldWidget.reports[oldIndex < 0 ? 0 : oldIndex].id;
    final currentId = widget.reports.isEmpty ? null : widget.reports[_index].id;
    if (previousId != currentId) {
      _showAll = false;
      _changedWeek = true;
    }
  }

  void _select(int index) {
    if (index < 0 || index >= widget.reports.length || index == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedId = widget.reports[index].id;
      _showAll = false;
      _changedWeek = true;
    });
  }

  void _openPicker() {
    final reports = widget.reports;
    final selectedIndex = _index;
    HapticFeedback.selectionClick();
    showAyreSheet<void>(
      context: context,
      builder: (_) => _WeekPickerSheet(
        reports: reports,
        selectedIndex: selectedIndex,
        onSelected: (i) {
          if (!mounted) return;
          _select(
            widget.reports.indexWhere((report) => report.id == reports[i].id),
          );
        },
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
    final visible = _showAll ? stocks : stocks.take(widget.collapsedCount);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.pageTransition;
    final animate = !_changedWeek && report.id == _firstWeek && !widget.stale;

    return AyreTabScroll(
      eager: true,
      controller: widget.controller,
      onRefresh: widget.onRefresh,
      header: AyreMastScaffold(
        mast: WeeklyReportMast(
          report: report,
          index: index,
          total: reports.length,
          hasSummary: true,
          onOlder: index < reports.length - 1 ? () => _select(index + 1) : null,
          onNewer: index > 0 ? () => _select(index - 1) : null,
          onPick: reports.length > 1 ? _openPicker : null,
        ),
        overlapChild: _ReportSummary(stocks: stocks, animate: animate),
      ),
      children: [
        const SizedBox(height: AppSpace.s21),
        if (widget.stale) ...[
          Text(
            'Showing the last available reports.',
            style: AppTypo.meta(context.tokens),
          ),
          const SizedBox(height: AppSpace.s13),
        ],
        AnimatedSize(
          duration: duration,
          curve: AppMotion.ease,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: duration,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final child in previous) ExcludeSemantics(child: child),
                ?current,
              ],
            ),
            child: Column(
              key: ValueKey(report.id),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, stock) in visible.indexed) ...[
                  if (i > 0) const SizedBox(height: AppSpace.cardGap),
                  Entrance(
                    index: i,
                    animate: animate && i < widget.collapsedCount,
                    child: _StockCard(stock: stock, report: report),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (canExpand) ...[
          const SizedBox(height: AppSpace.s8),
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

class WeeklyReportMast extends StatelessWidget {
  const WeeklyReportMast({
    super.key,
    this.report,
    this.index = 0,
    this.total = 0,
    this.hasSummary = false,
    this.onOlder,
    this.onNewer,
    this.onPick,
  });

  final WeeklyReport? report;
  final int index;
  final int total;
  final bool hasSummary;
  final VoidCallback? onOlder;
  final VoidCallback? onNewer;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = t.mastChampagne;
    final week = report;
    final status = index == 0 ? 'Latest week' : 'Earlier week';

    return AyreMasthead(
      tone: AyreMastTone.champagne,
      overlap: hasSummary ? AppShape.mastOverlap : 0,
      constrainContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Weekly Report',
              style: AppTypo.pageTitle(t, color: p.ink),
            ),
          ),
          if (week != null) ...[
            const SizedBox(height: AppSpace.s8),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  label:
                      '${_spokenWeekRange(week.weekStart, week.weekEnd)}. $status'
                      '${total > 1 ? ', ${index + 1} of $total' : ''}',
                  button: onPick != null,
                  onTap: onPick,
                  hint: onPick == null ? null : 'Choose a week',
                  excludeSemantics: true,
                  child: PressableScale(
                    onTap: onPick,
                    shape: AppShape.field,
                    focusColor: p.ink,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: onPick == null ? 0 : AppSpace.minTarget,
                      ),
                      child: Wrap(
                        spacing: AppSpace.s8,
                        runSpacing: AppSpace.s8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            formatWeekRange(week.weekStart, week.weekEnd),
                            style: AppTypo.subtitle(t, color: p.muted),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.glass,
                              borderRadius: AppShape.field,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                status,
                                style: AppTypo.meta(t, color: p.ink),
                              ),
                            ),
                          ),
                          if (onPick != null)
                            FinanceIcon(
                              FinanceGlyph.chevron,
                              quarterTurns: 1,
                              size: 16,
                              color: p.ink,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (total > 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MastIconButton(
                        palette: p,
                        semanticLabel: 'Older week',
                        onTap: onOlder,
                        child: FinanceIcon(
                          FinanceGlyph.chevron,
                          quarterTurns: 2,
                          size: 20,
                          color: p.ink,
                        ),
                      ),
                      MastIconButton(
                        palette: p,
                        semanticLabel: 'Newer week',
                        onTap: onNewer,
                        child: FinanceIcon(
                          FinanceGlyph.chevron,
                          size: 20,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.stocks, required this.animate});

  final List<WeeklyReportStock> stocks;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cells = [
      (stocks.length, 'Picks'),
      (stocks.where((stock) => stock.targetHit).length, 'Target hit'),
      (
        stocks.where((stock) => stock.outcome == 'stop_loss').length,
        'Stop-loss hit',
      ),
    ];
    return AyreCard(
      strongShadow: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s13),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (value, label)) in cells.indexed) ...[
              if (i > 0)
                VerticalDivider(width: 1, thickness: 1, color: t.hairline),
              Expanded(
                child: Semantics(
                  label: '$value $label',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CountUpFigure(
                          value: value.toDouble(),
                          from: animate ? 0 : value.toDouble(),
                          format: (number) => number.round().toString(),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTypo.meta(t),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
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
    return AyreSheet(
      title: 'Choose a week',
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < reports.length; i++) ...[
            if (i > 0) const HairlineDivider(indent: AppSpace.lg),
            Builder(
              builder: (context) {
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpace.minTarget,
                      ),
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
                                        ? AppTypo.rowLabel(
                                            t,
                                            color: t.accentInk,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                          )
                                        : AppTypo.rowLabel(t),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count ${count == 1 ? 'stock' : 'stocks'}'
                                    '${i == 0 ? ' · Latest' : ''}',
                                    style: AppTypo.meta(t),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              AyreIcon(
                                AyreGlyph.check,
                                size: 20,
                                color: t.accentInk,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.stock, required this.report});

  final WeeklyReportStock stock;
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final outcome = stock.targetHit ? 'Target hit' : 'Stop-loss hit';
    final name = stock.name?.trim() ?? '';
    final hasName =
        name.isNotEmpty && name.toUpperCase() != stock.symbol.toUpperCase();
    final pct = stock.profitPct;
    final pnl = stock.pnlAmount;
    final returnText = pct.isFinite ? formatDelta(pct) : '—';
    final profitText = pnl != null && pnl.isFinite
        ? _formatSignedRupees(pnl)
        : null;
    final prices = [
      if (stock.entryPrice case final price? when price.isFinite)
        (
          'Entry',
          '₹${formatPrice(price)}',
          stock.dateOfRecommendation == null
              ? 'Week start ${_shortDate(report.weekStart)}'
              : _shortDate(stock.dateOfRecommendation!),
        ),
      if (stock.exitPrice case final price? when price.isFinite)
        (
          'Exit',
          '₹${formatPrice(price)}',
          stock.exitDate == null
              ? 'Week end ${_shortDate(report.weekEnd)}'
              : _shortDate(stock.exitDate!),
        ),
    ];

    Color signedTone(num value) => !value.isFinite || value == 0
        ? t.textPrimary
        : (value > 0 ? t.positiveText : t.negativeText);

    final identity = Row(
      children: [
        AyreInstrumentTile(
          symbol: stock.symbol,
          size: 44,
          name: hasName ? name : null,
        ),
        const SizedBox(width: AppSpace.s13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.symbol,
                style: AppTypo.rowLabel(
                  t,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              if (hasName)
                Text(name, style: AppTypo.meta(t).copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
    final chip = AyreChip(
      label: outcome,
      tone: stock.targetHit ? ChipTone.success : ChipTone.negative,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        stock.symbol,
        if (hasName) name,
        outcome,
        if (pct.isFinite) '${pct.toStringAsFixed(2)} percent',
        if (profitText != null) 'Profit per share $profitText',
        for (final (label, value, date) in prices) '$label $value, $date',
      ].join(', '),
      child: AyreCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
            final inline = constraints.maxWidth >= 285 * scale;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (inline)
                  Row(
                    children: [
                      Expanded(flex: 3, child: identity),
                      const SizedBox(width: AppSpace.s13),
                      Flexible(flex: 2, child: chip),
                    ],
                  )
                else ...[
                  identity,
                  const SizedBox(height: AppSpace.s8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: chip,
                  ),
                ],
                const SizedBox(height: AppSpace.s21),
                Wrap(
                  spacing: AppSpace.s13,
                  runSpacing: AppSpace.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      returnText,
                      style: AppTypo.reportPercent(t, color: signedTone(pct)),
                    ),
                    if (profitText != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profit / share', style: AppTypo.meta(t)),
                          Text(
                            profitText,
                            style: AppTypo.ticker(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: signedTone(pnl!),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (prices.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s21),
                  InkPanel(
                    padding: const EdgeInsets.all(AppSpace.s13),
                    child: _PricePanel(prices: prices, inline: inline),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.prices, required this.inline});

  final List<(String, String, String)> prices;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cells = [
      for (final (i, (label, value, date)) in prices.indexed)
        Column(
          crossAxisAlignment: inline && i == 1
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              '$label · $date',
              style: AppTypo.meta(t),
              textAlign: inline && i == 1 ? TextAlign.end : TextAlign.start,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTypo.ticker(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
    ];
    return inline && cells.length > 1
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cells.first),
              const SizedBox(width: AppSpace.s13),
              Expanded(child: cells.last),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cells.first,
              if (cells.length > 1) ...[
                const SizedBox(height: AppSpace.s13),
                const HairlineDivider(),
                const SizedBox(height: AppSpace.s13),
                cells.last,
              ],
            ],
          );
  }
}

// ─── See all ───────────────────────────────────────────────────────────────

/// "See all N stocks" / "Show less" — an in-place expand of the same week.
/// 48pt tall target.
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
                  fontSize: AppTextScale.body,
                  fontWeight: FontWeight.w700,
                  color: t.accentInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────

class WeeklyReportSummarySkeleton extends StatelessWidget {
  const WeeklyReportSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AyreCard(
      strongShadow: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s13),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            const Expanded(
              child: Column(
                children: [
                  SkeletonBlock(width: 26, height: 21),
                  SizedBox(height: 3),
                  SkeletonBlock(width: 55, height: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class WeeklyReportSkeleton extends StatelessWidget {
  const WeeklyReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.cardGap),
          const AyreCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonTickerRow(),
                SizedBox(height: AppSpace.s21),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SkeletonBlock(width: 89, height: 34),
                ),
                SizedBox(height: AppSpace.s21),
                InkPanel(child: SkeletonBlock(height: 34)),
              ],
            ),
          ),
        ],
      ],
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
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _monthAbbrev = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
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
