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
/// Rebuilt in Phase 5 to §13.2's four parts: filter chips, a featured signal
/// card, a compact signal list, and the bar strength meter.
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

/// The board's filters. Bias, not sector or timeframe — bias is the one axis
/// every signal is guaranteed to carry (`Signal.bullish` is non-nullable),
/// so a filter on it can never produce a silently-empty board because the
/// feed omitted a field.
enum _Filter {
  all('All'),
  bullish('Bullish'),
  bearish('Bearish');

  const _Filter(this.label);

  final String label;

  bool matches(Signal s) => switch (this) {
    _Filter.all => true,
    _Filter.bullish => s.bullish,
    _Filter.bearish => !s.bullish,
  };
}

class _SignalsTabState extends State<SignalsTab> {
  DataResult<List<Signal>>? _result;
  bool _loading = true;
  _Filter _filter = _Filter.all;

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
    final result = await widget.marketData.getSignals();
    if (!mounted) return;
    final shown = result.keepingLastGood(_result);
    setState(() {
      _result = shown;
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
    final all = _result?.value ?? const <Signal>[];
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
                    Text('LIVE SCANNER', style: AppTypo.label(t)),
                    const SizedBox(height: AppSpace.xxs),
                    Text('Signal board', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      'Curated setups with live movement and compact '
                      'rationale.',
                      style: AppTypo.body(t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            // Chips render even while loading, greyed by their own zero
            // counts — a filter row that appears only after data lands makes
            // the header jump, which is the reflow skeletons exist to avoid.
            Entrance(index: 1, child: _FilterRow(
              selected: _filter,
              signals: all,
              onSelect: (f) {
                HapticFeedback.selectionClick();
                setState(() => _filter = f);
              },
            )),
            const SizedBox(height: AppSpace.sectionGap),
            ..._board(columns),
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

    final matching = _result!.value!.where(_filter.matches).toList();

    // A filtered-to-nothing board is not an empty feed and must not read like
    // one: the data arrived, the query is too narrow, and the action is the
    // user's. That distinction is exactly what Phase 4 added `noResults` for.
    if (matching.isEmpty) {
      return [
        StatePanel.noResults(
          headline: 'No ${_filter.label.toLowerCase()} setups in this sweep',
          message: 'The scanner found setups, just none on this side.',
          retryLabel: 'Show all',
          onRetry: () => setState(() => _filter = _Filter.all),
        ),
      ];
    }

    // The featured slot goes to the highest conviction, and ties break toward
    // the largest move — otherwise the "featured" pick would silently be
    // whichever the feed happened to list first.
    final ranked = [...matching]
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
        index: 2,
        child: _FeaturedSignal(
          signal: featured,
          onTap: () => _openEquity(featured),
        ),
      ),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: AppSpace.sectionGap),
        const Entrance(index: 3, child: SectionLabel(label: 'Also on watch')),
        Entrance(index: 4, child: _AlsoOnWatch(columns: columns, signals: rest, onTap: _openEquity)),
      ],
      if (_result!.stale) ...[
        const SizedBox(height: AppSpace.md),
        const StaleNotice(),
      ],
    ];
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

// ─── Filters ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.signals,
    required this.onSelect,
  });

  final _Filter selected;
  final List<Signal> signals;
  final ValueChanged<_Filter> onSelect;

  @override
  Widget build(BuildContext context) {
    // Scrolls rather than wraps: at a large text scale three chips plus their
    // counts exceed a 320pt width, and a wrapped filter row changes the
    // header's height as the text scale changes.
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          for (final filter in _Filter.values) ...[
            if (filter != _Filter.values.first)
              const SizedBox(width: AppSpace.xs),
            AyreFilterChip(
              label: filter.label,
              selected: filter == selected,
              count: signals.where(filter.matches).length,
              onTap: () => onSelect(filter),
            ),
          ],
        ],
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