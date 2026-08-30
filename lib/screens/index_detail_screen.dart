import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
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

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _loadConstituents();
  }

  Future<void> _loadQuote() async {
    final result = await widget.marketData.getIndex(widget.index);
    if (!mounted) return;
    setState(() {
      _quote = result;
      _loadingQuote = false;
    });
  }

  Future<void> _loadConstituents() async {
    setState(() => _loadingConstituents = true);
    final result = await widget.marketData.getConstituents(widget.index);
    if (!mounted) return;
    setState(() {
      _constituents = result;
      _loadingConstituents = false;
    });
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
        color: t.citrineInk,
        backgroundColor: t.surface,
        onRefresh: _refresh,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            children: [
              if (_loadingQuote && quote == null)
                const AyreCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 150, height: 32),
                      SizedBox(height: AppSpacing.md),
                      SkeletonBlock(width: 120, height: 12),
                      SizedBox(height: AppSpacing.lg),
                      SkeletonBlock(height: 90, radius: AppRadius.panel),
                    ],
                  ),
                )
              else if (quote == null)
                StatePanel.failed(
                  headline: 'Index feed unavailable right now',
                  message: 'Pull down to try again.',
                  onRetry: _loadQuote,
                )
              else
                _IndexHeader(quote: quote, stale: _quote?.stale ?? false),
              const SizedBox(height: AppSpacing.xl),
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
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      SkeletonTickerRow(),
                      SkeletonTickerRow(),
                      SkeletonTickerRow(),
                      SkeletonTickerRow(),
                      SkeletonTickerRow(),
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
                        if (i > 0) const HairlineDivider(indent: AppSpacing.md),
                        TickerRow(
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
      MaterialPageRoute(
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
  const _IndexHeader({required this.quote, required this.stale});

  final Quote quote;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyreCard(
      accentEdge: true,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quote.name,
                    style: AppTypo.cardTitle(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ShrinkTrailing(
                  child: stale
                      ? const AyreChip(label: 'Delayed', tone: ChipTone.attention)
                      : const AyreChip(
                          label: 'Live',
                          tone: ChipTone.live,
                          pulse: true,
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            InkPanel(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Figure(
                      formatPrice(quote.lastPrice),
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: t.onInkPanel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Figure(
                          formatDelta(quote.change, percent: false),
                          fontSize: 13,
                          color: t.onInkPanel.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        DeltaFigure(change: quote.percentChange, fontSize: 14),
                      ],
                    ),
                  ),
                  if (quote.trace.length >= 2) ...[
                    const SizedBox(height: AppSpacing.md),
                    TickerTrace(
                      points: normaliseTrace(quote.trace),
                      height: 76,
                      showGrid: true,
                      color: t.onInkPanel.withValues(alpha: 0.8),
                    ),
                  ],
                ],
              ),
            ),
            if (stale) ...[
              const SizedBox(height: AppSpacing.sm),
              const StaleNotice(),
            ],
            if (quote.dayLow != null ||
                quote.dayHigh != null ||
                quote.previousClose != null) ...[
              const SizedBox(height: AppSpacing.md),
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
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      if (quote.previousClose != null)
        ('Prev close', formatPrice(quote.previousClose)),
      if (quote.dayLow != null) ('Day low', formatPrice(quote.dayLow)),
      if (quote.dayHigh != null) ('Day high', formatPrice(quote.dayHigh)),
      if (quote.volume != null) ('Volume', formatVolume(quote.volume)),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.md,
      children: [
        for (final (label, value) in entries)
          LabelledFigure(label: label, value: value, fontSize: 13),
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
        side: BorderSide(color: t.border),
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
            const SizedBox(width: AppSpacing.xs),
            AyreIcon(AyreGlyph.sort, size: 14, color: t.textTertiary),
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
