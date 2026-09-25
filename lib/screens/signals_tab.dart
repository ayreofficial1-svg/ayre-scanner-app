import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';
import 'equity_detail_screen.dart';

/// Signals — the signal board (Spec §13.2).
///
/// One view of every stock the backend has pushed: a featured signal card, a
/// compact signal list, and the bar strength meter. There are deliberately no
/// filters — no All / Bullish / Bearish switch — so what the backend pushes is
/// exactly what is shown.
///
/// v3 rendered every signal as an identical mid-weight card, which meant the
/// board had no shape — twelve equally loud things and no way in. §13.2's
/// featured-plus-list structure gives the highest-conviction pick the
/// accent-edged card (§8.4) and drops the rest to compact hairline-divided
/// rows inside one card, so the screen reads as "here's the one, here are the
/// others" rather than as a wall.
class SignalsTab extends StatefulWidget {
  const SignalsTab({super.key, required this.marketData, this.active = true});

  final MarketDataService marketData;

  /// Whether this is the tab currently showing in the shell's
  /// [IndexedStack]. The shell mounts all five tabs immediately (that's
  /// what lets a tab keep its scroll position/state when you switch away
  /// and back), so without this every tab's first load fires the instant
  /// you land on the shell — five tabs' worth of HTTP calls landing and
  /// getting JSON-decoded/rebuilt on the UI thread in the same short
  /// window right after login. Deferring the load until the tab is first
  /// actually selected spreads that burst out instead.
  final bool active;

  @override
  State<SignalsTab> createState() => _SignalsTabState();
}

class _SignalsTabState extends State<SignalsTab> {
  DataResult<List<Signal>>? _result;

  /// Phase 5: admin-entered weekly performance (`GET /api/weekly-report`),
  /// shown as its own section below the board. Loaded alongside the board
  /// so one pull-to-refresh covers both; kept as a separate result so a
  /// failure here never touches the board above it.
  DataResult<List<WeeklyReport>>? _weeklyResult;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load(initial: true);
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  /// Fired once, shortly after the app returns to the foreground. Reloads
  /// silently if the app was away long enough for the board to be out of date.
  void _onAppResumed() {
    if (!mounted || !widget.active || _result == null) return;
    if (AppLifecycleService.instance.lastAway < const Duration(seconds: 30)) {
      return;
    }
    _load(initial: true);
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    super.dispose();
  }

  @override
  void didUpdateWidget(SignalsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && _result == null) {
      _load(initial: true);
    }
  }

  Future<void> _load({bool initial = false}) async {
    // Fired together so a slow weekly-report fetch never holds up the board.
    final results = await Future.wait([
      widget.marketData.getSignals(),
      widget.marketData.getWeeklyReports(),
    ]);
    if (!mounted) return;
    final result = (results[0] as DataResult<List<Signal>>).keepingLastGood(
      _result,
    );
    final weekly = (results[1] as DataResult<List<WeeklyReport>>)
        .keepingLastGood(_weeklyResult);
    setState(() {
      _result = result;
      _weeklyResult = weekly;
      _loading = false;
    });
    if (!initial) HapticFeedback.mediumImpact();

    if (!result.isReady) return;
    final fresh = await SeenSignalsStore.diffAndRecord(
      result.value!.map((s) => s.symbol),
    );
    if (fresh.isEmpty) return;
    await NotificationLog.instance.add(
      Notice(
        kind: NoticeKind.signal,
        title: fresh.length == 1
            ? 'New scanner pick: ${fresh.first}'
            : '${fresh.length} new scanner picks',
        body:
            '${fresh.take(4).join(', ')}'
            '${fresh.length > 4 ? ', and more' : ''}',
        at: DateTime.now(),
      ),
    );
  }

  void _openEquity(Signal signal) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      terminalRoute(
        builder: (_) => EquityDetailScreen(
          symbol: signal.symbol,
          marketData: widget.marketData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final columns = AppBreakpoints.columns(context);

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
        // Single column keeps the app's default 620pt reading measure;
        // once the board goes multi-column (Phase 2A) it needs the wider
        // frame `learn_tab.dart` already uses for the same reason.
        maxWidth: columns > 1 ? 960 : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.pageHorizontal,
            AppSpace.pageTop,
            AppSpace.pageHorizontal,
            120,
          ),
          children: [
            SafeArea(
              bottom: false,
              child: Entrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signal board', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      'Stocks flagged as potential opportunities.',
                      style: AppTypo.body(t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sectionGap),
            ..._board(columns),
            ..._weeklyReportSection(),
          ],
        ),
      ),
    );
  }

  List<Widget> _board(int columns) {
    if (_loading) return const [_SignalsSkeleton()];

    if (_result!.isFailed) {
      return [
        StatePanel.failed(
          headline: "The scanner couldn't refresh",
          message: 'The last sweep is still shown below where available.',
          onRetry: _load,
        ),
      ];
    }

    if (_result!.isEmpty) {
      return const [
        StatePanel.empty(
          headline: 'No fresh setups right now',
          message: 'Pull down when you want the scanner to sweep again.',
        ),
      ];
    }

    // The featured slot goes to the highest conviction, and ties break toward
    // the largest move — otherwise the "featured" pick would silently be
    // whichever the feed happened to list first.
    final ranked = [..._result!.value!]
      ..sort((a, b) {
        final byStrength = (b.strength ?? 0).compareTo(a.strength ?? 0);
        if (byStrength != 0) return byStrength;
        return (b.percentChange ?? 0).abs().compareTo(
          (a.percentChange ?? 0).abs(),
        );
      });
    final featured = ranked.first;
    final rest = ranked.skip(1).toList();

    return [
      Entrance(
        index: 1,
        child: _FeaturedSignal(
          signal: featured,
          onTap: () => _openEquity(featured),
        ),
      ),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: AppSpace.sectionGap),
        const Entrance(index: 2, child: SectionLabel(label: 'Also on watch')),
        Entrance(index: 3, child: _AlsoOnWatch(columns: columns, signals: rest, onTap: _openEquity)),
      ],
    ];
  }

  /// Phase 5: the Weekly Report section, directly below the board — an
  /// admin-entered, hand-verified record of one past week's outcomes (§A.3).
  /// Loads and fails independently of the board above it (`_weeklyResult`),
  /// and renders nothing at all when there's simply no report yet, per §A.8
  /// ("render nothing or a minimal state rather than a broken-looking empty
  /// section").
  List<Widget> _weeklyReportSection() {
    if (_loading) {
      return const [
        SizedBox(height: AppSpace.sectionGap),
        _WeeklyReportSkeleton(),
      ];
    }

    final weekly = _weeklyResult;
    if (weekly == null || weekly.isEmpty) return const [];

    if (weekly.isFailed) {
      return [
        const SizedBox(height: AppSpace.sectionGap),
        StatePanel.failed(
          headline: "Weekly report didn't load",
          message: 'The signal board above is unaffected.',
          compact: true,
          onRetry: _load,
        ),
      ];
    }

    final reports = weekly.value;
    final report = (reports != null && reports.isNotEmpty)
        ? reports.first
        : null;
    if (report == null) return const [];

    return [
      const SizedBox(height: AppSpace.sectionGap),
      Entrance(
        index: 4,
        child: SectionLabel(
          label: 'Weekly Report',
          subtitle: formatWeekRange(report.weekStart, report.weekEnd),
        ),
      ),
      Entrance(index: 5, child: _WeeklyReportCard(report: report)),
    ];
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

/// The "also on watch" list, single-column below [AppBreakpoints.twoColumn]
/// (the hairline-divided `RowGroup` §13.2 specifies) and a card grid at or
/// above it (Phase 2A) — the same column-count pattern `learn_tab.dart`
/// already applies to its course list, replicated rather than reinvented.
class _AlsoOnWatch extends StatelessWidget {
  const _AlsoOnWatch({
    required this.columns,
    required this.signals,
    required this.onTap,
  });

  final int columns;
  final List<Signal> signals;
  final ValueChanged<Signal> onTap;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      // `RowGroup` *is* the card — it wraps its rows in one `AyreCard` with
      // hairline dividers between them (§8.3). Wrapping it in another card
      // would nest cards, which §19 forbids outright.
      return RowGroup(
        children: [
          for (final signal in signals)
            _CompactSignalRow(signal: signal, onTap: () => onTap(signal)),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: signals.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpace.cardGap,
        crossAxisSpacing: AppSpace.cardGap,
        // Ratio-driven, not a fixed extent, so a large accessibility text
        // scale grows the tile instead of overflowing it — same reasoning
        // as `learn_tab.dart`'s course grid.
        childAspectRatio: 3.6,
      ),
      itemBuilder: (context, index) => AyreCard(
        padding: EdgeInsets.zero,
        child: _CompactSignalRow(
          signal: signals[index],
          onTap: () => onTap(signals[index]),
        ),
      ),
    );
  }
}

// ─── Featured signal ───────────────────────────────────────────────────────

/// The board's lead pick (§13.2). An accent-tinted border marks it featured
/// (§8.4) — never a tinted fill behind it, which is the pattern v4 retired.
class _FeaturedSignal extends StatelessWidget {
  const _FeaturedSignal({required this.signal, required this.onTap});

  final Signal signal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = signal.bullish ? t.positive : t.negative;

    // Phase 5: content-dense card — mark tappable without collapsing the
    // rationale/levels detail children carry (unlike TickerRow's terse
    // grouped-label treatment).
    return Semantics(
      button: true,
      child: AyreCard(
      onTap: onTap,
      accentEdge: true,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TOP CONVICTION', style: AppTypo.label(t, color: t.accentInk)),
              const Spacer(),
              ShrinkTrailing(
                child: DirectionBadge(
                  up: signal.bullish,
                  label: signal.bullish ? 'Bullish' : 'Bearish',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.inCardGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.symbol,
                      style: AppTypo.featuredHeadline(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (signal.name != null && signal.name!.isNotEmpty)
                      Text(
                        signal.name!,
                        style: AppTypo.body(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (signal.lastPrice != null)
                        Figure(
                          formatPrice(signal.lastPrice),
                          fontSize: AppTextScale.cardTitle,
                          fontWeight: FontWeight.w600,
                        ),
                      const SizedBox(height: AppSpace.xxs),
                      DeltaFigure(
                        change: signal.percentChange,
                        fontSize: AppTextScale.body,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (signal.rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpace.inCardGap),
            Text(
              signal.rationale,
              style: AppTypo.body(t),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (signal.strength != null) ...[
            const SizedBox(height: AppSpace.inCardGap),
            Row(
              children: [
                Text('CONVICTION', style: AppTypo.label(t)),
                const SizedBox(width: AppSpace.xs),
                SignalStrength(level: signal.strength!, color: tone, height: 18),
              ],
            ),
          ],
          if (signal.entry != null ||
              signal.target != null ||
              signal.stop != null) ...[
            const SizedBox(height: AppSpace.md),
            // A sunken inset, not a nested card (§8.3) — the levels are a
            // sub-region of this card, and v4 forbids a card inside a card.
            InkPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: [
                  if (signal.entry != null)
                    Expanded(child: _Level(label: 'Entry', value: signal.entry)),
                  if (signal.target != null)
                    Expanded(
                      child: _Level(
                        label: 'Target',
                        value: signal.target,
                        tone: t.positive,
                      ),
                    ),
                  if (signal.stop != null)
                    Expanded(
                      child: _Level(
                        label: 'Stop',
                        value: signal.stop,
                        tone: t.negative,
                      ),
                    ),
                ],
              ),
            ),
          ] else if (signal.addedOn != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text('ADDED ${signal.addedOn!.toUpperCase()}',
                style: AppTypo.label(t)),
          ],
        ],
      ),
      ),
    );
  }
}

// ─── Compact list ──────────────────────────────────────────────────────────

/// One row of the "also on watch" list (§13.2's compact signal list, §11.7's
/// row convention). Deliberately thinner than the featured card: symbol,
/// direction, move, conviction. The rationale and the levels live one tap
/// away, on Equity Detail.
class _CompactSignalRow extends StatelessWidget {
  const _CompactSignalRow({required this.signal, required this.onTap});

  final Signal signal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = signal.bullish ? t.positive : t.negative;

    // Phase 5: grouped announcement (symbol, direction, price, change) —
    // same pattern as TickerRow.
    final buf = StringBuffer(signal.symbol);
    if (signal.name != null && signal.name!.isNotEmpty) {
      buf.write(', ${signal.name}');
    }
    buf.write(', ${signal.bullish ? 'bullish' : 'bearish'}');
    if (signal.lastPrice != null) {
      buf.write(', ${formatPrice(signal.lastPrice)}');
    }
    if (signal.percentChange != null) {
      final up = signal.percentChange! >= 0;
      buf.write(
        ', ${up ? 'up' : 'down'} '
        '${signal.percentChange!.abs().toStringAsFixed(2)} percent',
      );
    }

    return Semantics(
      button: true,
      label: buf.toString(),
      excludeSemantics: true,
      child: PressableScaleRow(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.hairlineRowPadding,
          ),
        child: Row(
          children: [
            AyreIcon(
              signal.bullish ? AyreGlyph.trendUp : AyreGlyph.trendDown,
              size: 17,
              color: tone,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signal.symbol,
                    style: AppTypo.rowLabel(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (signal.name != null && signal.name!.isNotEmpty)
                    Text(
                      signal.name!,
                      style: AppTypo.hint(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            if (signal.strength != null) ...[
              SignalStrength(level: signal.strength!, color: tone),
              const SizedBox(width: AppSpace.sm),
            ],
            Flexible(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (signal.lastPrice != null)
                      Figure(
                        formatPrice(signal.lastPrice),
                        fontSize: AppTextScale.body,
                      ),
                    const SizedBox(height: AppSpace.xxs),
                    DeltaFigure(
                      change: signal.percentChange,
                      fontSize: AppTextScale.hint,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Level extends StatelessWidget {
  const _Level({required this.label, required this.value, this.tone});

  final String label;
  final num? value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypo.label(t),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpace.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Figure(
            formatPrice(value),
            fontSize: AppTextScale.body,
            fontWeight: FontWeight.w600,
            color: tone,
          ),
        ),
      ],
    );
  }
}

/// Mirrors the featured-plus-list shape, so nothing jumps when data lands.
class _SignalsSkeleton extends StatelessWidget {
  const _SignalsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AyreCard(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(width: 120, height: 11),
              SizedBox(height: AppSpace.inCardGap),
              SkeletonBlock(width: 160, height: 24),
              SizedBox(height: AppSpace.xs),
              SkeletonBlock(height: 12),
              SizedBox(height: AppSpace.xxs),
              SkeletonBlock(width: 220, height: 12),
              SizedBox(height: AppSpace.md),
              SkeletonBlock(height: 48, radius: AppRadius.inset),
            ],
          ),
        ),
        SizedBox(height: AppSpace.sectionGap),
        AyreCard(
          padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Column(
            children: [
              SkeletonTickerRow(),
              SkeletonTickerRow(),
              SkeletonTickerRow(),
              SkeletonTickerRow(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Weekly Report (Phase 5) ────────────────────────────────────────────────

/// The Weekly Report card — one week's admin-entered rows plus the
/// always-visible disclaimer (§A.3, §A.9). An accent-edged border marks it as
/// a highlight, the same "tinted border, never a tinted fill" convention
/// [_FeaturedSignal] uses above, rather than introducing a new treatment.
class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard({required this.report});

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
            _WeeklyReportRow(stock: report.stocks[i]),
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
/// `t.negative` the same way [_Mood.bearish] does for a plain market
/// reading elsewhere in the app (§A.9), never an alarm color.
class _WeeklyReportRow extends StatelessWidget {
  const _WeeklyReportRow({required this.stock});

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

/// Mirrors [_WeeklyReportCard]'s shape, so nothing jumps when data lands.
class _WeeklyReportSkeleton extends StatelessWidget {
  const _WeeklyReportSkeleton();

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