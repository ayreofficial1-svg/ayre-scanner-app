import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_index_art.dart';
import '../widgets/ayre_instrument_tile.dart';
import '../widgets/figure.dart';
import '../widgets/state_views.dart';
import '../widgets/ticker_trace.dart';
import 'equity_detail_screen.dart';

enum _ConstituentSort { changeDesc, changeAsc, name }

/// Index Detail — reached by tapping an index on Home.
///
/// The header carries the same visual weight as the Home card it came from, so
/// the drill-down feels continuous. The index reading and the constituent list
/// load and fail independently: metadata can succeed while constituents fail,
/// and the screen renders that correctly rather than going blank.
class IndexDetailScreen extends StatefulWidget {
  const IndexDetailScreen({
    super.key,
    required this.index,
    required this.marketData,
    this.seed,
  });

  final IndexId index;
  final MarketDataService marketData;

  /// The quote already on screen when the card was tapped, shown immediately so
  /// the header never flashes empty on the way in.
  final Quote? seed;

  @override
  State<IndexDetailScreen> createState() => _IndexDetailScreenState();
}

class _IndexDetailScreenState extends State<IndexDetailScreen> {
  DataResult<Quote>? _quote;
  DataResult<List<Quote>>? _constituents;
  bool _loadingQuote = true;
  bool _loadingConstituents = true;
  _ConstituentSort _sort = _ConstituentSort.changeDesc;
  Timer? _liveTimer;
  bool _liveQuoteInFlight = false;
  bool _liveConstituentsInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _loadConstituents();
    // Safe to poll this often: the backend serves both of these from
    // Fyers' single live WebSocket feed, so this never adds extra
    // Fyers/NSE requests no matter how frequently it ticks.
    _liveTimer = Timer.periodic(liveMarketRefreshInterval, (_) {
      // Backgrounded or still settling after resume — see _onAppResumed.
      if (!AppLifecycleService.instance.canFetch) return;
      // Each guarded independently: quote and constituents are two separate
      // requests with independent latency, so one running long shouldn't
      // hold back the other from ticking again on schedule.
      if (!_liveQuoteInFlight) _loadQuote(silent: true);
      if (!_liveConstituentsInFlight) _loadConstituents(silent: true);
    });
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  /// Fired once, shortly after the app returns to the foreground. Resets the
  /// in-flight guards (a request cut off by backgrounding may never complete)
  /// and refreshes silently.
  void _onAppResumed() {
    if (!mounted) return;
    _liveQuoteInFlight = false;
    _liveConstituentsInFlight = false;
    _loadQuote(silent: true);
    _loadConstituents(silent: true);
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    _liveTimer?.cancel();
    super.dispose();
  }

  /// [silent]: used by the periodic live-refresh tick — updates the data
  /// without flipping the loading flag, so the screen doesn't flash a
  /// spinner every few seconds. Matches the original behavior otherwise:
  /// a manual reload never re-shows the quote's loading state either.
  Future<void> _loadQuote({bool silent = false}) async {
    _liveQuoteInFlight = true;
    try {
      final result = await widget.marketData.getIndex(widget.index);
      if (!mounted) return;
      setState(() {
        _quote = result.keepingLastGood(_quote);
        _loadingQuote = false;
      });
    } finally {
      _liveQuoteInFlight = false;
    }
  }

  Future<void> _loadConstituents({bool silent = false}) async {
    if (!silent) {
      if (!mounted) return;
      setState(() => _loadingConstituents = true);
    }
    _liveConstituentsInFlight = true;
    try {
      final result = await widget.marketData.getConstituents(widget.index);
      if (!mounted) return;
      setState(() {
        _constituents = result.keepingLastGood(_constituents);
        _loadingConstituents = false;
      });
    } finally {
      _liveConstituentsInFlight = false;
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadQuote(), _loadConstituents()]);
    if (mounted) HapticFeedback.mediumImpact();
  }

  List<Quote> get _sorted {
    final rows = [...?_constituents?.value];
    switch (_sort) {
      case _ConstituentSort.changeDesc:
        rows.sort((a, b) => b.percentChange.compareTo(a.percentChange));
      case _ConstituentSort.changeAsc:
        rows.sort((a, b) => a.percentChange.compareTo(b.percentChange));
      case _ConstituentSort.name:
        rows.sort((a, b) => a.symbol.compareTo(b.symbol));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // The seed keeps the header populated during the first fetch.
    final quote = _quote?.value ?? widget.seed;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(widget.index.label),
      ),
      body: RefreshIndicator(
        color: t.accentInk,
        backgroundColor: t.surface,
        onRefresh: _refresh,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.xxl,
            ),
            children: [
              if (_loadingQuote && quote == null)
                const AyreCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 150, height: 32),
                      SizedBox(height: AppSpace.md),
                      SkeletonBlock(width: 120, height: 12),
                      SizedBox(height: AppSpace.lg),
                      SkeletonBlock(height: 90, radius: AppRadius.inset),
                    ],
                  ),
                )
              else if (quote == null)
                StatePanel.failed(
                  // With an explicit onRetry, the button itself already
                  // carries the "Try again" verb (§14.5) — the message
                  // doesn't need to repeat it.
                  headline: 'Index feed unavailable right now',
                  message: "The reading didn't come through this time.",
                  onRetry: _loadQuote,
                )
              else
                _IndexHeader(
                  index: widget.index,
                  quote: quote,
                  stale: _quote?.stale ?? false,
                ),
              const SizedBox(height: AppSpace.xl),
              SectionLabel(
                label: 'Constituents',
                trailing: _constituents?.isReady == true
                    ? _SortControl(
                        sort: _sort,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _sort = value);
                        },
                      )
                    : null,
              ),
              if (_loadingConstituents)
                const AyreCard(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: Column(
                    children: [
                      SkeletonTickerRow(tile: true),
                      SkeletonTickerRow(tile: true),
                      SkeletonTickerRow(tile: true),
                      SkeletonTickerRow(tile: true),
                      SkeletonTickerRow(tile: true),
                    ],
                  ),
                )
              else if (_constituents!.isFailed)
                StatePanel.failed(
                  headline: "Couldn't load the constituent list",
                  message: 'The index reading above is still current.',
                  onRetry: _loadConstituents,
                )
              else if (_constituents!.isEmpty)
                const StatePanel.empty(
                  headline: 'No constituents returned',
                  message: 'The feed listed no companies for this index.',
                )
              else
                AyreCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, row) in _sorted.indexed) ...[
                        // Hairlines start at the text, not under the tile.
                        if (i > 0)
                          const HairlineDivider(
                            indent: AppSpace.md +
                                AyreInstrumentTile.defaultSize +
                                AppSpace.md,
                          ),
                        TickerRow(
                          leading: AyreInstrumentTile(symbol: row.symbol),
                          symbol: row.symbol,
                          name: row.name == row.symbol ? null : row.name,
                          price: row.lastPrice,
                          changePercent: row.percentChange,
                          changeAbsolute: row.change,
                          onTap: () => _openEquity(row),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEquity(Quote row) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      terminalRoute(
        builder: (_) => EquityDetailScreen(
          symbol: row.symbol,
          marketData: widget.marketData,
          seed: row,
        ),
      ),
    );
  }
}

class _IndexHeader extends StatelessWidget {
  const _IndexHeader({
    required this.index,
    required this.quote,
    required this.stale,
  });

  final IndexId index;
  final Quote quote;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // The same identity the Home card wears (v5 §2A, "Index-card identity
    // tints"): tinted fill, circular gradient icon tile, exchange sub-label.
    // Decorative only — gain/loss colour stays on the figures.
    final identity = AyreIndexIdentity.of(context, index);
    final tint = identity.tint;

    return AyreCard(
      accentEdge: true,
      // The featured edge takes the index's own hue, so a green edge never
      // sits around a coral or blue identity fill.
      accentColor: tint.trace,
      color: tint.cardBackground,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AyreIndexIconTile(glyph: identity.glyph, tint: tint),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.name,
                        style: AppTypo.cardTitle(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (identity.exchange != null)
                        Text(
                          identity.exchange!,
                          style: AppTypo.hint(t, color: t.foregroundMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // A stale feed renders nothing in this slot — never a "Live"
                // chip it hasn't earned, and never the word "Delayed" (v5
                // plan §4).
                if (!stale) ...[
                  const SizedBox(width: AppSpace.sm),
                  const ShrinkTrailing(
                    child: AyreChip(
                      label: 'Live',
                      tone: ChipTone.live,
                      pulse: true,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.inCardGap),
            // The figures sit straight on the tinted card. The sunken
            // `InkPanel` this header used before would read as a green-grey
            // box on the coral and blue identities.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Figure(
                formatPrice(quote.lastPrice),
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Figure(
                    formatDelta(quote.change, percent: false),
                    fontSize: 13,
                    color: t.foregroundMuted,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  DeltaFigure(change: quote.percentChange, fontSize: 14),
                ],
              ),
            ),
            if (quote.trace.length >= 2) ...[
              const SizedBox(height: AppSpace.md),
              // §12.1: a chart inherits the colour of its subject — no
              // fixed neutral chart-line token in v5.
              TickerTrace(
                points: normaliseTrace(quote.trace),
                height: 76,
                color: quote.isUp ? t.positive : t.negative,
                fill: true,
              ),
            ],
            if (quote.dayLow != null ||
                quote.dayHigh != null ||
                quote.previousClose != null) ...[
              const SizedBox(height: AppSpace.md),
              _StatsGrid(quote: quote),
            ],
          ],
        ),
      ),
    );
  }
}

/// Labelled tabular figures — the same "label above value" convention used
/// everywhere else in the app.
///
/// Draws its own label/value pairs rather than [LabelledFigure]: this grid
/// sits on an index's identity tint, where the shared label's
/// `foregroundSubtle` measures only ~2.6:1, so the label takes
/// `foregroundMuted` here.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final entries = <(String, String)>[
      if (quote.previousClose != null)
        ('Prev close', formatPrice(quote.previousClose)),
      if (quote.dayLow != null) ('Day low', formatPrice(quote.dayLow)),
      if (quote.dayHigh != null) ('Day high', formatPrice(quote.dayHigh)),
      if (quote.volume != null) ('Volume', formatVolume(quote.volume)),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpace.xl,
      runSpacing: AppSpace.md,
      children: [
        for (final (label, value) in entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypo.label(t, color: t.foregroundMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.xxs),
              Figure(value, fontSize: 13),
            ],
          ),
      ],
    );
  }
}

class _SortControl extends StatelessWidget {
  const _SortControl({required this.sort, required this.onChanged});

  final _ConstituentSort sort;
  final ValueChanged<_ConstituentSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PopupMenuButton<_ConstituentSort>(
      initialValue: sort,
      tooltip: 'Sort constituents',
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      color: t.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: t.hairline),
      ),
      itemBuilder: (context) => [
        for (final entry in const [
          (_ConstituentSort.changeDesc, 'Gainers first'),
          (_ConstituentSort.changeAsc, 'Losers first'),
          (_ConstituentSort.name, 'Symbol A–Z'),
        ])
          PopupMenuItem(
            value: entry.$1,
            child: Text(entry.$2, style: AppTypo.bodyStrong(t)),
          ),
      ],
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label(sort), style: AppTypo.label(t)),
            const SizedBox(width: AppSpace.xs),
            AyreIcon(AyreGlyph.sort, size: 14, color: t.foregroundSubtle),
          ],
        ),
      ),
    );
  }

  static String _label(_ConstituentSort sort) => switch (sort) {
    _ConstituentSort.changeDesc => 'GAINERS',
    _ConstituentSort.changeAsc => 'LOSERS',
    _ConstituentSort.name => 'A–Z',
  };
}