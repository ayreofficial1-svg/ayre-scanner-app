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
//   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   black / white section rule
//   ┌──────────────────────────────────────┐
//   │ Weekly Report                    ‹ ›  │   teal gradient header (light wash / dark):
//   │ 1 – 8 Sep 2026 ⌄                      │   heading first, date second
//   │ Latest week · 1 of 3                  │
//   └──────────────────────────────────────┘
//
//   ┌──────────────────────────────────────┐
//   │ [logo]  RELIANCE                +896.40%│     one card per stock,
//   │         ● Target hit                   │     always fully visible:
//   │                                        │     who → how it ended → how
//   │ ┌─────────────┐ ┌─────────────┐       │     much → the trade
//   │ │ ENTRY       │ │ EXIT        │       │
//   │ │ ₹444.00     │ │ ₹4,424.00   │       │     Entry carries the date of
//   │ │ 1 Sep 2026  │ │ 8 Sep 2026  │       │     recommendation, Exit
//   │ └─────────────┘ └─────────────┘       │     carries the exit date.
//   │ ─────────────────────────────────────  │
//   │ PROFIT / SHARE             +₹3,980    │
//   └──────────────────────────────────────┘
//
// Cards are separated by space, not dividers. The gradient header is what
// sets this section apart from the other Home cards; the stock cards stay
// quiet — a faint corner of hills, no fills behind the results. Outcome
// colour sits on text only (green target / red stop-loss), and direction is
// also in the sign and the written outcome, never colour alone.
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
        const _SectionRule(),
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

// ─── Section rule ──────────────────────────────────────────────────────────

/// A subtle line marking where the Weekly Report starts.
class _SectionRule extends StatelessWidget {
  const _SectionRule();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          color: (dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
              .withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(0.5),
        ),
      ),
    );
  }
}

// ─── Week header ───────────────────────────────────────────────────────────

/// The section's title card: the heading, the week under it, and where it
/// sits in the list — on a teal gradient that follows the theme, with round older /
/// newer buttons on the right. Tapping the date opens the week list.
///
/// The gradient is a fixed pair per brightness rather than a token: it is
/// the one strongly coloured block in the section, and white text on it must
/// hold contrast in both themes. Dark runs a darker petrol so it sits in the
/// dark canvas instead of glowing on it.
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

  // Teal-blue with a warm amber glow. Every other gradient on Home is a
  // green (sentiment card, insight carousel, index art); this one sits at the
  // cool teal end of the Ayre palette so the Weekly Report is unmistakable
  // at a glance. It follows the theme: a soft, light wash with petrol text in
  // Light mode; a deep petrol with white text in Dark mode.
  static const List<Color> _lightGradient = [
    Color(0xFFE4F3F5),
    Color(0xFFC9E8EB),
    Color(0xFFABDCDD),
  ];
  static const List<Color> _darkGradient = [
    Color(0xFF061821),
    Color(0xFF0A2C38),
    Color(0xFF0E4850),
  ];
  static const Color _glow = Color(0xFFF2C46D);

  // Ink on the light wash.
  static const Color _lightHeading = Color(0xFF0B2E3D);
  static const Color _lightDate = Color(0xFF0E6A70);
  static const Color _lightCaption = Color(0xFF4A6B74);

  // Ink on the dark gradient.
  static const Color _darkHeading = Color(0xFFFFFFFF);
  static const Color _darkDate = Color(0xFFA6EBCB);
  static const Color _darkCaption = Color(0xFFBCD3D6);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final range = formatWeekRange(report.weekStart, report.weekEnd);
    final spoken = _spokenWeekRange(report.weekStart, report.weekEnd);
    final multiple = total > 1;
    final sub = total == 1
        ? 'Latest week'
        : (index == 0
              ? 'Latest week · 1 of $total'
              : 'Earlier week · ${index + 1} of $total');

    final headingColor = dark ? _darkHeading : _lightHeading;
    final dateColor = dark ? _darkDate : _lightDate;
    final captionColor = dark ? _darkCaption : _lightCaption;
    // Arrow buttons and the faint ring take the heading's ink, so they work
    // on both washes.
    final arrowFill = headingColor.withValues(alpha: dark ? 0.16 : 0.09);

    // Hierarchy, in order: the heading (what this is), the date (which
    // week), the position caption (where it sits in the list).
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Weekly Report',
            maxLines: 1,
            style: AppTypo.ui(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: headingColor,
              height: 1.08,
              letterSpacing: -1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: dateColor,
                    height: 1.2,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
            if (multiple) ...[
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 18, color: dateColor),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: AppTypo.hint(t, color: captionColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return AyreCard(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark ? _darkGradient : _lightGradient,
          ),
        ),
        child: Stack(
          children: [
            // A warm amber glow in the top-right corner and one faint ring.
            // Decorative only.
            Positioned(
              top: -90,
              right: -70,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _glow.withValues(alpha: dark ? 0.20 : 0.50),
                          _glow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -30,
              child: _Disc(size: 170, color: headingColor.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
              ),
              child: Row(
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
                      fill: arrowFill,
                      ink: headingColor,
                    ),
                    _WeekArrow(
                      glyph: AyreGlyph.forward,
                      label: 'Newer week',
                      onTap: onNewer,
                      fill: arrowFill,
                      ink: headingColor,
                    ),
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

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

/// A 44pt tap target holding a 34pt tinted circle and a chevron, coloured
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

  static const double size = 44;

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
                width: 34,
                height: 34,
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
              _OutcomeChip(label: outcomeLabel, tone: tone),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Figure.static(
          formatDelta(stock.profitPct),
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: tone,
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
            // A small, faint touch of the Ayre hills in the corner — kept
            // quiet so the header above is the one place the section is loud.
            const Positioned(
              top: 0,
              right: 0,
              child: AyreHills(width: 110, height: 70),
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
                    const SizedBox(height: AppSpace.sm),
                    const HairlineDivider(),
                    _ProfitRow(value: pnl, tone: tone),
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

/// `● Target hit` — a dot and the outcome in words, no fill.
class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
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
              color: t.foregroundMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

/// PROFIT / SHARE as one slim line — label left, value right, no fill —
/// under a hairline, so it supports the return above rather than competing.
class _ProfitRow extends StatelessWidget {
  const _ProfitRow({required this.value, required this.tone});

  final num value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
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
