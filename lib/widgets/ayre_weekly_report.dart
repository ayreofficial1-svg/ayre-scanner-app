import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'ayre_instrument_tile.dart';
import 'figure.dart';
import 'pressable_scale.dart';

// ─── Weekly Report (Phase 5; moved to Home in Phase 2; restyled in Phase 3;
// trade-card data in Phase 6; redesigned in Phase 7 and again in Phase 8) ──
//
// Phase 8 is a hierarchy pass, not a content change. Everything the report
// has always shown is still available — logo, symbol, company name, entry
// price, exit price, return %, profit/share, date of recommendation, exit
// date (each date still falls back to the report's own week range when the
// stock has none, never an invented value). What changed is how much of it
// competes for attention at once.
//
// The design rule: a row answers ONE question at a glance — "how did this
// pick do?" — and everything else is quieter or one tap away.
//
//   Always visible, two lines per row
//     line 1   symbol                                   Return %   ← the only
//                                                                    coloured,
//                                                                    bold item
//     line 2   entry → exit (muted)             profit / share (muted)
//
//   One tap away (inline, one row open at a time)
//     company name · date of recommendation · exit date · "View stock"
//
// Why this shape:
// * A single weight and colour for the result means ten rows scan as one
//   column of numbers instead of ten competing cards. Gain/loss colour is
//   confined to that one figure; the sign is part of the text, so direction
//   survives without colour.
// * Prices and profit/share stay visible (they ARE the performance record)
//   but in a muted tone, so they support the headline instead of rivalling it.
// * Dates are usually identical across a week and already framed by the week
//   header, so repeating them on every row was the biggest source of noise.
//   They now live in the row's detail, with the year.
// * The week header is a plain, left-aligned title with quiet arrows on the
//   right (Calendar-style) — no tinted band, no centred stack.
// * More than [WeeklyReportCard.collapsedCount] stocks: the first five show,
//   "See all N stocks" reveals the rest in place.
// * Every week the backend returns is reachable via the arrows or by tapping
//   the date range to open a week list.
//
// Every colour is an existing `AppThemeTokens` value, so Light and Dark both
// follow the theme with no per-mode code.

/// The Weekly Report section body: one card for the selected week.
///
/// [reports] is the backend's list, newest week first (`GET
/// /api/weekly-report`). The first entry is selected initially.
class WeeklyReportCard extends StatefulWidget {
  const WeeklyReportCard({
    super.key,
    required this.reports,
    this.onOpenStock,
    this.collapsedCount = 5,
  });

  final List<WeeklyReport> reports;

  /// Called when "View stock" is tapped in a row's detail. When null, the
  /// link is omitted.
  final ValueChanged<WeeklyReportStock>? onOpenStock;

  /// How many stocks show before "See all". Weeks with this many or fewer
  /// show every row and no control.
  final int collapsedCount;

  @override
  State<WeeklyReportCard> createState() => _WeeklyReportCardState();
}

class _WeeklyReportCardState extends State<WeeklyReportCard> {
  // The selected week is remembered by id, not position, so a refresh that
  // inserts a newer week doesn't silently move the user onto another one.
  String? _selectedId;
  bool _showAll = false;

  // At most one row's detail is open at a time, which keeps the list calm.
  // Keyed by week id + row index.
  String? _openRowKey;

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
      _openRowKey = null;
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

  void _toggleRow(String key) {
    HapticFeedback.selectionClick();
    setState(() => _openRowKey = _openRowKey == key ? null : key);
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

    return AyreCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekHeader(
            report: report,
            index: index,
            total: reports.length,
            // Left arrow = older week (next in the newest-first list).
            onOlder: index < reports.length - 1
                ? () => _select(index + 1)
                : null,
            onNewer: index > 0 ? () => _select(index - 1) : null,
            onPick: reports.length > 1 ? _openPicker : null,
          ),
          const HairlineDivider(),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : AppMotion.pageTransition,
            curve: AppMotion.ease,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : AppMotion.buttonPress,
              child: Column(
                // Keyed by week only — opening a row or "See all" animates
                // through AnimatedSize instead of cross-fading the list.
                key: ValueKey(report.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0)
                      const HairlineDivider(indent: _StockRow.textIndent),
                    _StockRow(
                      stock: visible[i],
                      fallbackStart: report.weekStart,
                      fallbackEnd: report.weekEnd,
                      open: _openRowKey == '${report.id}:$i',
                      onToggle: () => _toggleRow('${report.id}:$i'),
                      onOpenStock: widget.onOpenStock == null
                          ? null
                          : () => widget.onOpenStock!(visible[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canExpand) ...[
            const HairlineDivider(),
            _ExpandToggle(
              expanded: _showAll,
              count: stocks.length,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _showAll = !_showAll;
                  // A row past the cap can't stay open once it's hidden.
                  if (!_showAll) _openRowKey = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Week header ───────────────────────────────────────────────────────────

/// A plain, left-aligned title — the week's date range with its year — and,
/// when there is more than one week, quiet older/newer arrows on the right.
/// Tapping the title opens the week list.
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
    final sub = total == 1
        ? 'Latest week'
        : (index == 0
              ? 'Latest week · 1 of $total'
              : 'Earlier week · ${index + 1} of $total');
    final multiple = total > 1;

    final title = Padding(
      padding: const EdgeInsets.only(
        left: AppSpace.md,
        top: AppSpace.sm,
        bottom: AppSpace.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              range,
              style: AppTypo.rowLabel(t),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  sub,
                  style: AppTypo.hint(t, color: t.foregroundSubtle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (multiple) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: t.foregroundSubtle,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: onPick != null,
            label: 'Weekly report, $range. $sub.',
            hint: onPick != null ? 'Opens a list of weeks' : null,
            excludeSemantics: true,
            child: onPick == null
                ? title
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPick,
                    child: title,
                  ),
          ),
        ),
        if (multiple) ...[
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
          const SizedBox(width: AppSpace.xxs),
        ] else
          const SizedBox(width: AppSpace.md),
      ],
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  /// 44pt — the app's minimum tappable dimension.
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
            child: AyreIcon(
              glyph,
              size: 18,
              // Quiet by default; the disabled end is quieter still.
              color: enabled ? t.foregroundMuted : t.textDisabled,
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

// ─── Stock row ─────────────────────────────────────────────────────────────

/// One stock's result.
///
/// Two lines, two columns. The left column is identity + the trade
/// (`symbol` over `entry → exit`); the right column is the outcome (`return
/// %` over `profit / share`). Only the Return % is bold and coloured —
/// everything else is muted so the eye lands on the result first.
///
/// Tapping the row opens its detail in place: company name (when present),
/// date of recommendation, exit date, and a "View stock" link. The detail
/// only exists when there is something to put in it.
///
/// [fallbackStart]/[fallbackEnd] are the report's own week range, used only
/// when this stock doesn't carry its own dates — real data, not a guess.
class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.stock,
    required this.fallbackStart,
    required this.fallbackEnd,
    required this.open,
    required this.onToggle,
    this.onOpenStock,
  });

  static const double tileSize = AyreInstrumentTile.defaultSize;

  /// Where the hairlines between rows start — under the text, not the logo —
  /// and where the detail's content aligns.
  static const double textIndent = AppSpace.md + tileSize + AppSpace.sm;

  final WeeklyReportStock stock;
  final DateTime? fallbackStart;
  final DateTime? fallbackEnd;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback? onOpenStock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = stock.targetHit ? t.positive : t.negative;
    final outcomeLabel = stock.targetHit ? 'Target hit' : 'Stop-loss hit';

    final recDate = stock.dateOfRecommendation ?? fallbackStart;
    final exitDate = stock.exitDate ?? fallbackEnd;
    final pnl = stock.pnlAmount;
    final hasPrices = stock.entryPrice != null || stock.exitPrice != null;
    final hasName =
        stock.name != null &&
        stock.name!.isNotEmpty &&
        stock.name!.toUpperCase() != stock.symbol.toUpperCase();
    final hasDates = recDate != null || exitDate != null;
    final expandable = hasName || hasDates || onOpenStock != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final summary = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.hairlineRowPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AyreInstrumentTile(
            symbol: stock.symbol,
            size: tileSize,
            name: hasName ? stock.name : null,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Line 1 — the question and its answer.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        stock.symbol,
                        style: AppTypo.rowLabel(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Figure.static(
                      formatDelta(stock.profitPct),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tone,
                    ),
                  ],
                ),
                // Line 2 — supporting numbers, deliberately quiet.
                if (hasPrices || pnl != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (hasPrices)
                        Flexible(
                          flex: 5,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _PriceLine(
                              entry: stock.entryPrice,
                              exit: stock.exitPrice,
                            ),
                          ),
                        )
                      else
                        const Spacer(flex: 5),
                      if (pnl != null) ...[
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          flex: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _ProfitPerShare(value: pnl),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (expandable) ...[
            const SizedBox(width: AppSpace.xs),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: reduceMotion ? Duration.zero : AppMotion.buttonPress,
              curve: AppMotion.ease,
              child: Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: t.foregroundSubtle,
              ),
            ),
          ],
        ],
      ),
    );

    final summaryTappable = Semantics(
      button: expandable,
      expanded: expandable ? open : null,
      label:
          '${stock.symbol}, $outcomeLabel, '
          '${stock.profitPct.toStringAsFixed(2)} percent',
      excludeSemantics: true,
      child: expandable
          ? PressableScaleRow(onTap: onToggle, child: summary)
          : summary,
    );

    if (!expandable || !open) return summaryTappable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        summaryTappable,
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduceMotion ? Duration.zero : AppMotion.pageTransition,
          curve: AppMotion.ease,
          builder: (context, v, child) => Opacity(opacity: v, child: child),
          child: _RowDetail(
            name: hasName ? stock.name : null,
            recDate: recDate,
            exitDate: exitDate,
            onOpenStock: onOpenStock,
          ),
        ),
      ],
    );
  }
}

/// `₹456.00 → ₹489.00`, muted. When only one price exists it is captioned,
/// so a lone number is never ambiguous.
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.entry, required this.exit});

  final num? entry;
  final num? exit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget price(num v) => Figure.static(
      '₹${formatPrice(v)}',
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: t.foregroundMuted,
    );

    final semantics = [
      if (entry != null) 'Entry ₹${formatPrice(entry)}',
      if (exit != null) 'Exit ₹${formatPrice(exit)}',
    ].join(', ');

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry != null && exit != null) ...[
            price(entry!),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AyreIcon(
                AyreGlyph.forward,
                size: 11,
                color: t.foregroundSubtle,
              ),
            ),
            price(exit!),
          ] else if (entry != null) ...[
            Text('Entry ', style: AppTypo.hint(t, color: t.foregroundSubtle)),
            price(entry!),
          ] else if (exit != null) ...[
            Text('Exit ', style: AppTypo.hint(t, color: t.foregroundSubtle)),
            price(exit!),
          ],
        ],
      ),
    );
  }
}

/// `+₹44 / share`, muted — the sign carries direction, so no colour needed.
class _ProfitPerShare extends StatelessWidget {
  const _ProfitPerShare({required this.value});

  final num value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Figure.static(
          _formatSignedRupees(value),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: t.foregroundMuted,
        ),
        const SizedBox(width: 3),
        Text('/ share', style: AppTypo.hint(t, color: t.foregroundSubtle)),
      ],
    );
  }
}

// ─── Row detail ────────────────────────────────────────────────────────────

/// What a tap reveals: company name (when present), the two dates — always
/// with the year — and a "View stock" link. Aligned to the row's text column
/// so it reads as part of that row, not a new block.
class _RowDetail extends StatelessWidget {
  const _RowDetail({
    required this.name,
    required this.recDate,
    required this.exitDate,
    required this.onOpenStock,
  });

  final String? name;
  final DateTime? recDate;
  final DateTime? exitDate;
  final VoidCallback? onOpenStock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypo.hint(t, color: t.foregroundSubtle)),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypo.hint(
                t,
                color: t.foregroundMuted,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(
        left: _StockRow.textIndent,
        right: AppSpace.md,
        bottom: AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name != null) line('Company', name!),
          if (recDate != null) line('Date of recommendation', _shortDate(recDate!)),
          if (exitDate != null) line('Exit date', _shortDate(exitDate!)),
          if (onOpenStock != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'View stock',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpenStock,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View stock',
                          style: AppTypo.ui(
                            fontSize: AppTextScale.hint,
                            fontWeight: FontWeight.w700,
                            color: t.accentInk,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AyreIcon(
                          AyreGlyph.forward,
                          size: 12,
                          color: t.accentInk,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: AppSpace.xs),
        ],
      ),
    );
  }
}

// ─── See all ───────────────────────────────────────────────────────────────

/// "See all N stocks" / "Show less" — an in-place expand of the same week,
/// matching the Insights movers lists. 48pt tall, above the 44pt floor.
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

/// Mirrors [WeeklyReportCard]'s shape — a header and three two-line rows —
/// so nothing visibly jumps once real data replaces it.
class WeeklyReportSkeleton extends StatelessWidget {
  const WeeklyReportSkeleton({super.key});

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
              AppSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 190, height: 14),
                SizedBox(height: AppSpace.xs),
                SkeletonBlock(width: 90, height: 10),
              ],
            ),
          ),
          const HairlineDivider(),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const HairlineDivider(indent: _StockRow.textIndent),
            const _WeeklyReportRowSkeleton(),
          ],
        ],
      ),
    );
  }
}

class _WeeklyReportRowSkeleton extends StatelessWidget {
  const _WeeklyReportRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.hairlineRowPadding,
      ),
      child: Row(
        children: [
          SkeletonBlock(
            width: _StockRow.tileSize,
            height: _StockRow.tileSize,
            radius: AppRadius.iconTile,
          ),
          SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SkeletonBlock(width: 84, height: 14),
                    Spacer(),
                    SkeletonBlock(width: 56, height: 16),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    SkeletonBlock(width: 130, height: 11),
                    Spacer(),
                    SkeletonBlock(width: 64, height: 11),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formatting ────────────────────────────────────────────────────────────

/// Formats a week's date range with the year — e.g.
/// "6th September to 12th September 2026". When the week straddles New Year
/// each end carries its own year ("29th December 2026 to 4th January 2027").
/// Computed here, from the plain ISO dates the backend sends, rather than
/// expecting a pre-formatted string from the API (see [WeeklyReport]'s doc
/// comment) — so the display format can change later without a data
/// migration.
String formatWeekRange(DateTime start, DateTime end) {
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