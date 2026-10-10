import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'ayre_instrument_tile.dart';
import 'ayre_sheet.dart';
import 'figure.dart';
import 'pressable_scale.dart';

// ─── Weekly Report (Phase 11 redesign) ─────────────────────────────────────
//
// Presentation-only. Same data, same week navigation, same picker, same
// "See all". Nothing is added to the model.
//
//   Weekly Report                           ‹ ›     standard page-title heading,
//   1 – 8 Sep 2026 ⌄                                 date second, no gradient/rule
//   Latest week · 1 of 3
//
//   Stock card: flat, one inset surface. Header (logo, symbol and company |
//   signed return over the outcome in words), then Entry · Exit in a single
//   inset panel, then Profit per share under a hairline. No hills, no nested
//   cards.
//
// Cards are separated by space, not dividers. The stock cards stay
// quiet — flat, single-level, no decoration behind the results. Outcome
// colour sits on text only (green target / red stop-loss), and direction is
// also in the sign and the written outcome, never colour alone.
//
// Every colour is an `AppThemeTokens` value, so Light and Dark follow the
// theme with no per-mode code.

/// The full Weekly Report section: week header and stock cards.
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
    showAyreSheet<void>(
      context: context,
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
                  if (i > 0) const SizedBox(height: AppSpace.sm),
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

/// The section's heading: "Weekly Report" in the same page-title style the
/// other tabs use, the week under it, and where it sits in the list — with
/// round older / newer buttons on the right. Tapping the date opens the week
/// list. No gradient, glow or divider: it sits directly on the page.
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

    // Hierarchy, in order: the heading (what this is), the date (which
    // week), the position caption (where it sits in the list).
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Weekly Report', style: AppTypo.pageTitle(t)),
        const SizedBox(height: AppSpace.xxs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                range,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypo.rowLabel(t, color: t.accentInk),
              ),
            ),
            if (multiple) ...[
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 18, color: t.accentInk),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: AppTypo.meta(t),
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
            fill: t.textPrimary.withValues(alpha: 0.08),
            ink: t.textPrimary,
          ),
          _WeekArrow(
            glyph: AyreGlyph.forward,
            label: 'Newer week',
            onTap: onNewer,
            fill: t.textPrimary.withValues(alpha: 0.08),
            ink: t.textPrimary,
          ),
        ],
      ],
    );
  }
}

/// A 48pt tap target holding a 34pt tinted circle and a chevron, coloured
/// from the header's ink so it reads on both the light and dark wash. The
/// disabled end fades rather than disappears, so the pair never shifts.
class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.glyph,
    required this.label,
    required this.onTap,
    required this.fill,
    required this.ink,
  });

  static const double size = AppSpace.minTarget;

  final AyreGlyph glyph;
  final String label;
  final VoidCallback? onTap;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
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
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Container(
                width: 36,
                height: 38,
                decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
                child: Center(child: AyreIcon(glyph, size: 16, color: ink)),
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

// ─── Stock card ────────────────────────────────────────────────────────────

/// Sizes and text styles shared by the real stock card and its skeleton, so
/// the placeholder is built from the same measurements and cannot drift.
abstract final class _CardSpec {
  /// Logo tile edge. 44 keeps a bundled logo legible and sits on the 4 pt
  /// grid.
  static const double tile = 44;

  /// Gap between the card's three bands (header · prices · profit).
  static const double band = AppSpace.sm;

  /// Padding inside the Entry / Exit panel.
  static const EdgeInsets panelPadding = EdgeInsets.all(AppSpace.sm);

  /// Inner width the header needs to put the result beside the identity,
  /// per text-scale unit.
  static const double headerSideBySide = 300;

  /// Panel width needed to set Entry and Exit side by side, per text-scale
  /// unit. Below it they stack as label / value lines.
  static const double panelColumns = 2 * 128 + AppSpace.md;

  static TextStyle symbol(AppThemeTokens t) => AppTypo.ui(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: t.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle outcome(Color tone) =>
      AppTypo.ui(fontSize: 12, fontWeight: FontWeight.w700, color: tone);

  static const double returnSize = 22;
  static const double priceSize = 16;
}

/// One stock's result as a flat card with three clear bands:
///
///   1. **Header** — logo, symbol and company on the left; the signed return
///      with the outcome in words beneath it on the right. Identity and
///      result are each one block, so the eye reads "who" then "how it did".
///   2. **Prices** — Entry and Exit side by side in a single inset panel,
///      each label / price / date.
///   3. **Profit / share** — a hairline, then the label left and the figure
///      right in the outcome colour.
///
/// One inset surface inside the card and nothing nested deeper. Direction is
/// carried by the sign, the written outcome and the dot, never colour alone.
///
/// Spacing (Spec §4.1): 16 pt card padding, 12 pt between bands, 4 pt inside
/// a label/value pair, 12 pt between cards. With less room (a 320 pt phone,
/// or larger text) the result drops under the identity and Entry / Exit
/// become label/value lines. Text is never shrunk.
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
    // Text and glyphs use the A4 status-text tokens; the dot is a mark.
    final tone = hit ? t.positiveText : t.negativeText;
    final dot = hit ? t.positive : t.negative;
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

    final scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final k = scale < 1 ? 1.0 : scale;

    final prices = <_MetricData>[
      if (stock.entryPrice != null)
        _MetricData(
          'Entry',
          '₹${formatPrice(stock.entryPrice)}',
          recDate,
          t.textPrimary,
        ),
      if (stock.exitPrice != null)
        _MetricData(
          'Exit',
          '₹${formatPrice(stock.exitPrice)}',
          exitDate,
          t.textPrimary,
        ),
    ];

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AyreInstrumentTile(
          symbol: stock.symbol,
          size: _CardSpec.tile,
          name: hasName ? stock.name : null,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(stock.symbol, style: _CardSpec.symbol(t)),
              if (hasName) ...[
                const SizedBox(height: 2),
                Text(
                  stock.name!,
                  style: AppTypo.meta(t),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final returnFigure = Figure.static(
      formatDelta(stock.profitPct),
      fontSize: _CardSpec.returnSize,
      fontWeight: FontWeight.w700,
      color: tone,
    );
    final outcomeChip = _OutcomeChip(label: outcomeLabel, tone: tone, dot: dot);

    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: AyreCard(
        padding: const EdgeInsets.all(AppSpace.md),
        child: LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            final header = width >= _CardSpec.headerSideBySide * k
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: AppSpace.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          returnFigure,
                          const SizedBox(height: AppSpace.xxs),
                          outcomeChip,
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpace.md,
                        runSpacing: AppSpace.xxs,
                        children: [returnFigure, outcomeChip],
                      ),
                    ],
                  );

            final panelWidth =
                width - _CardSpec.panelPadding.horizontal;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (prices.isNotEmpty) ...[
                  const SizedBox(height: _CardSpec.band),
                  _PricePanel(
                    items: prices,
                    columns: panelWidth >= _CardSpec.panelColumns * k,
                  ),
                ],
                if (pnl != null) ...[
                  const SizedBox(height: _CardSpec.band),
                  const HairlineDivider(),
                  const SizedBox(height: _CardSpec.band),
                  _ProfitRow(value: _formatSignedRupees(pnl), tone: tone),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// `● Target hit` — a dot and the outcome in words, no fill.
class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({
    required this.label,
    required this.tone,
    required this.dot,
  });

  final String label;
  final Color tone;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: _CardSpec.outcome(tone))),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.date, this.valueColor);

  final String label;
  final String value;
  final DateTime? date;
  final Color valueColor;
}

/// Entry and Exit in one inset panel: two even columns, or — with less room —
/// label/value lines separated by a hairline.
class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.items, required this.columns});

  final List<_MetricData> items;
  final bool columns;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final Widget body;
    if (columns) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.md),
            Expanded(child: _MetricStack(data: items[i])),
          ],
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AppSpace.sm),
              const HairlineDivider(),
              const SizedBox(height: AppSpace.sm),
            ],
            _MetricLine(data: items[i]),
          ],
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.inset),
      ),
      child: Padding(padding: _CardSpec.panelPadding, child: body),
    );
  }
}

/// Label, price, date — each on its own line with a clear gap.
class _MetricStack extends StatelessWidget {
  const _MetricStack({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(data.label, style: AppTypo.meta(t)),
        const SizedBox(height: AppSpace.xxs),
        Figure.static(
          data.value,
          fontSize: _CardSpec.priceSize,
          fontWeight: FontWeight.w600,
          color: data.valueColor,
        ),
        if (data.date != null) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(
            _shortDate(data.date!),
            style: AppTypo.meta(t, color: t.foregroundSubtle),
          ),
        ],
      ],
    );
  }
}

/// Label (and date) left, value right — the reflow form. A [Wrap], so a very
/// long figure drops under its label instead of overflowing.
class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.md,
      runSpacing: AppSpace.xxs,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.label, style: AppTypo.meta(t)),
            if (data.date != null) ...[
              const SizedBox(height: AppSpace.xxs),
              Text(
                _shortDate(data.date!),
                style: AppTypo.meta(t, color: t.foregroundSubtle),
              ),
            ],
          ],
        ),
        Figure.static(
          data.value,
          fontSize: _CardSpec.priceSize,
          fontWeight: FontWeight.w600,
          color: data.valueColor,
        ),
      ],
    );
  }
}

/// `Profit / share ············ +₹80` — label left, figure right in the
/// outcome colour. Wraps rather than overflows at large text sizes.
class _ProfitRow extends StatelessWidget {
  const _ProfitRow({required this.value, required this.tone});

  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.md,
      runSpacing: AppSpace.xxs,
      children: [
        Text('Profit / share', style: AppTypo.meta(t)),
        Figure.static(
          value,
          fontSize: _CardSpec.priceSize,
          fontWeight: FontWeight.w700,
          color: tone,
        ),
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
        SizedBox(height: AppSpace.xs),
        _StockCardSkeleton(),
      ],
    );
  }
}

/// Same bands, spacing and text styles as the real stock card (it reads them
/// from [_CardSpec]), with each line of text replaced by a bar of that line's
/// height. Because the height comes from the real styles, the placeholder
/// grows with the text size exactly as the card will, so loading to loaded
/// does not jump.
class _StockCardSkeleton extends StatelessWidget {
  const _StockCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final symbol = _CardSpec.symbol(t);
    final meta = AppTypo.meta(t);
    final ret = AppTypo.ticker(
      fontSize: _CardSpec.returnSize,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final price = AppTypo.ticker(
      fontSize: _CardSpec.priceSize,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final outcome = _CardSpec.outcome(t.foregroundMuted);

    Widget priceStack(double labelW) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GhostLine(style: meta, width: labelW),
          const SizedBox(height: AppSpace.xxs),
          _GhostLine(style: price, width: 80),
          const SizedBox(height: AppSpace.xxs),
          _GhostLine(style: meta, width: 64),
        ],
      ),
    );

    return AyreCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SkeletonBlock(
                      width: _CardSpec.tile,
                      height: _CardSpec.tile,
                      radius: AppRadius.iconTile,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GhostLine(style: symbol, width: 88),
                          const SizedBox(height: 2),
                          _GhostLine(style: meta, width: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _GhostLine(style: ret, width: 72),
                  const SizedBox(height: AppSpace.xxs),
                  _GhostLine(style: outcome, width: 72),
                ],
              ),
            ],
          ),
          const SizedBox(height: _CardSpec.band),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.inset),
            ),
            child: Padding(
              padding: _CardSpec.panelPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  priceStack(36),
                  const SizedBox(width: AppSpace.md),
                  priceStack(32),
                ],
              ),
            ),
          ),
          const SizedBox(height: _CardSpec.band),
          const HairlineDivider(),
          const SizedBox(height: _CardSpec.band),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GhostLine(style: meta, width: 84),
              _GhostLine(style: price, width: 64),
            ],
          ),
        ],
      ),
    );
  }
}

/// A shimmer bar as tall as one line of [style]. An invisible, semantics-free
/// line of real text gives it that height at the current text scale.
class _GhostLine extends StatelessWidget {
  const _GhostLine({required this.style, required this.width});

  final TextStyle style;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bar = (style.fontSize ?? 14) * 0.7;
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Opacity(
              opacity: 0,
              child: Text(' ', style: style, maxLines: 1),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBlock(width: width, height: bar),
            ),
          ),
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