import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/state_views.dart';
import 'equity_detail_screen.dart';

/// Insights — the market intelligence desk.
///
/// Sentiment, breadth and all three mover lists live here as one continuous feed:
/// shared row height, shared hairlines, shared label typography. It replaces the
/// old "Climate" tab in name and in concept.
///
/// Each section owns its own state. A failed movers list never takes the
/// sentiment reading down with it, and vice versa.
class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key, required this.marketData});

  final MarketDataService marketData;

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  DataResult<Sentiment>? _sentiment;
  DataResult<List<Quote>>? _gainers;
  DataResult<List<Quote>>? _losers;
  DataResult<List<Quote>>? _mostActive;
  DataResult<List<InsightNote>>? _notes;
  // Cache-only on the backend (see market_data_service.dart's endpoint
  // doc): these refresh at scan cadence (up to 7×/day), not on
  // [_liveTimer]'s tick, so they're loaded once in [_load] and left alone
  // by [_refreshLive] — polling them every 10s would just re-fetch the
  // same cached numbers.
  DataResult<VolatilityHistogram>? _volatility;
  DataResult<MomentumTilt>? _momentum;
  DataResult<VolumeSurgeBoard>? _volumeSurge;
  bool _loading = true;
  Timer? _liveTimer;
  bool _liveRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    // Sentiment/gainers/losers/most-active only — not _notes, which is
    // editorially authored content that doesn't change tick to tick.
    // Safe to poll this often: the backend serves the market-data pieces
    // from Fyers' single live WebSocket feed, so this never adds extra
    // Fyers/NSE requests no matter how frequently it ticks.
    _liveTimer = Timer.periodic(
      liveMarketRefreshInterval,
      (_) => _refreshLive(),
    );
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLive() async {
    // See HomeTab._refreshLive: skips a tick rather than let it stack behind
    // a still-running one.
    if (!mounted || _liveRefreshInFlight) return;
    _liveRefreshInFlight = true;
    try {
      final results = await Future.wait([
        widget.marketData.getSentiment(monthly: false),
        widget.marketData.getTopGainers(),
        widget.marketData.getTopLosers(),
        widget.marketData.getMostActive(),
      ]);
      if (!mounted) return;
      setState(() {
        _sentiment = results[0] as DataResult<Sentiment>;
        _gainers = results[1] as DataResult<List<Quote>>;
        _losers = results[2] as DataResult<List<Quote>>;
        _mostActive = results[3] as DataResult<List<Quote>>;
      });
    } finally {
      _liveRefreshInFlight = false;
    }
  }

  Future<void> _load({bool initial = false}) async {
    // Fired together so one slow section doesn't hold up the rest of the desk.
    final results = await Future.wait([
      widget.marketData.getSentiment(monthly: false),
      widget.marketData.getTopGainers(),
      widget.marketData.getTopLosers(),
      widget.marketData.getMostActive(),
      widget.marketData.getInsightNotes(),
      widget.marketData.getVolatility(),
      widget.marketData.getMomentum(),
      widget.marketData.getVolumeSurge(),
    ]);
    if (!mounted) return;
    setState(() {
      _sentiment = results[0] as DataResult<Sentiment>;
      _gainers = results[1] as DataResult<List<Quote>>;
      _losers = results[2] as DataResult<List<Quote>>;
      _mostActive = results[3] as DataResult<List<Quote>>;
      _notes = results[4] as DataResult<List<InsightNote>>;
      _volatility = results[5] as DataResult<VolatilityHistogram>;
      _momentum = results[6] as DataResult<MomentumTilt>;
      _volumeSurge = results[7] as DataResult<VolumeSurgeBoard>;
      _loading = false;
    });
    if (!initial) HapticFeedback.mediumImpact();
  }

  Future<void> _reloadSentiment() async {
    final result = await widget.marketData.getSentiment(monthly: false);
    if (!mounted) return;
    setState(() => _sentiment = result);
  }

  Future<void> _reloadVolatility() async {
    final result = await widget.marketData.getVolatility();
    if (!mounted) return;
    setState(() => _volatility = result);
  }

  Future<void> _reloadMomentum() async {
    final result = await widget.marketData.getMomentum();
    if (!mounted) return;
    setState(() => _momentum = result);
  }

  Future<void> _reloadVolumeSurge() async {
    final result = await widget.marketData.getVolumeSurge();
    if (!mounted) return;
    setState(() => _volumeSurge = result);
  }

  void _openEquity(Quote quote) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EquityDetailScreen(
          symbol: quote.symbol,
          marketData: widget.marketData,
          seed: quote,
        ),
      ),
    );
  }

  /// Same destination as [_openEquity], for rows that don't carry a full
  /// [Quote] — the volume-surge leaderboard's rows are symbol + surge +
  /// close only, so the detail screen fetches its own header data rather
  /// than being seeded with one.
  void _openEquityBySymbol(String symbol) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EquityDetailScreen(
          symbol: symbol,
          marketData: widget.marketData,
        ),
      ),
    );
  }

  /// §13.3: one featured article card, then the rest as a list.
  ///
  /// "Featured" is the feed's own flag where it sets one, and otherwise the
  /// first note — a desk that publishes three notes and marks none of them
  /// featured still has a lead story, and picking one is better than showing
  /// three identical cards and calling that a hierarchy.
  List<Widget> _deskNotes() {
    final notes = _notes!.value!;
    if (notes.isEmpty) {
      return const [
        StatePanel.empty(
          headline: 'No notes published today',
          message: 'The desk publishes written notes through the session.',
          compact: true,
        ),
      ];
    }

    final featured = notes.firstWhere(
      (n) => n.featured,
      orElse: () => notes.first,
    );
    final rest = notes.where((n) => n != featured).toList();

    return [
      _FeaturedNote(note: featured),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: AppSpace.cardGap),
        RowGroup(children: [for (final note in rest) _NoteRow(note: note)]),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
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
                    Text('Insights', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      "Breadth, sentiment, and the day's movers, in one feed.",
                      style: AppTypo.body(t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sectionGap),

            // ── Section 1: sentiment / breadth ──────────────────────────────
            // The weekly/monthly toggle that used to sit here is gone: the
            // backend stores a single sentiment value and accepts no window
            // parameter, so both options returned identical data. Reinstate it
            // when /api/sentiment genuinely supports a window.
            const Entrance(
              index: 1,
              child: SectionLabel(label: 'Market sentiment'),
            ),
            _SentimentSection(
              result: _loading ? null : _sentiment,
              onRetry: _reloadSentiment,
            ),

            // ── Sections 2–4: the movers lists ──────────────────────────────
            const SizedBox(height: AppSpace.sectionGap),
            _MoversSection(
              label: 'Top gainers',
              result: _loading ? null : _gainers,
              onOpen: _openEquity,
              emptyMessage:
                  'No advancing equities reported for this session yet.',
              failedMessage: "Top Gainers didn't load.",
            ),
            const SizedBox(height: AppSpace.sectionGap),
            _MoversSection(
              label: 'Top losers',
              result: _loading ? null : _losers,
              onOpen: _openEquity,
              emptyMessage:
                  'No declining equities reported for this session yet.',
              failedMessage: "Top Losers didn't load.",
            ),
            const SizedBox(height: AppSpace.sectionGap),
            _MoversSection(
              label: 'Most active',
              result: _loading ? null : _mostActive,
              onOpen: _openEquity,
              byVolume: true,
              emptyMessage: 'No traded volume reported for this session yet.',
              failedMessage: "Most Active didn't load.",
            ),

            // ── Section 5: volatility ────────────────────────────────────────
            // Refreshes at scan cadence, not the 10s live tick — see the
            // field doc on _volatility.
            const SizedBox(height: AppSpace.sectionGap),
            _VolatilitySection(
              result: _loading ? null : _volatility,
              onRetry: _reloadVolatility,
            ),

            // ── Section 6: momentum tilt ─────────────────────────────────────
            const SizedBox(height: AppSpace.sectionGap),
            _MomentumSection(
              result: _loading ? null : _momentum,
              onRetry: _reloadMomentum,
            ),

            // ── Section 7: volume-surge leaderboard ──────────────────────────
            const SizedBox(height: AppSpace.sectionGap),
            _VolumeSurgeSection(
              result: _loading ? null : _volumeSurge,
              onOpen: _openEquityBySymbol,
              onRetry: _reloadVolumeSurge,
            ),

            // ── Desk notes: §13.3's featured-article card + article list ────
            //
            // Ordered after the market sections rather than before them, which
            // is a deliberate departure from reading §13.3's component list as
            // a page order: notes are frequently absent (the feed publishes
            // them irregularly), and leading a screen with a section that is
            // usually empty would make Insights look broken on most days.
            // The card *structures* are §13.3's; the sequence is this
            // screen's own. Flagged in the plan.
            if (!_loading && _notes?.isReady == true) ...[
              const SizedBox(height: AppSpace.sectionGap),
              const SectionLabel(label: 'Desk notes'),
              ..._deskNotes(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentimentSection extends StatelessWidget {
  const _SentimentSection({required this.result, required this.onRetry});

  final DataResult<Sentiment>? result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (result == null) {
      return const AyreCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 110, height: 34),
            SizedBox(height: AppSpace.md),
            SkeletonBlock(height: 10, radius: AppRadius.chip),
            SizedBox(height: AppSpace.md),
            SkeletonBlock(width: 180, height: 10),
          ],
        ),
      );
    }

    if (result!.isFailed) {
      return StatePanel.failed(
        headline: 'Sentiment reading unavailable',
        message: 'Pull down to retry.',
        compact: true,
        onRetry: onRetry,
      );
    }

    if (result!.isEmpty) {
      return const StatePanel.empty(
        headline: 'No sentiment reading',
        message: 'The desk has not published a reading for this window yet.',
        compact: true,
      );
    }

    final sentiment = result!.value!;
    // §12.1 over §12.2 on the gauge's fill, same call Home makes: a sentiment
    // reading's subject is direction, so a bearish gauge reads rose. Open
    // decision #12.
    final tone = switch (sentiment.score) {
      < 35 => t.negative,
      < 65 => t.neutral,
      _ => t.positive,
    };
    final hasCounts =
        sentiment.advances != null || sentiment.declines != null;

    return AyreCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SentimentGauge(
              score: sentiment.score,
              band: sentiment.band,
              tone: tone,
            ),
          ),
          if (hasCounts) ...[
            const SizedBox(height: AppSpace.lg),
            const HairlineDivider(),
            const SizedBox(height: AppSpace.lg),
            // Phase 5 completes the Phase 3 swap: the advance/decline counts
            // were three `LabelledFigure`s reading as a table. They are a
            // proportion, and §12.2's donut is the component for that — the
            // legend still names and counts every segment, so nothing that
            // was legible as a number stops being one.
            Center(
              child: BreadthDonut(
                advances: sentiment.advances ?? 0,
                declines: sentiment.declines ?? 0,
                unchanged: sentiment.unchanged ?? 0,
              ),
            ),
          ],
          if (sentiment.note != null && sentiment.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            const HairlineDivider(),
            const SizedBox(height: AppSpace.inCardGap),
            Text(sentiment.note!, style: AppTypo.body(t)),
          ],
          if (result!.stale) ...[
            const SizedBox(height: AppSpace.inCardGap),
            const StaleNotice(),
          ],
        ],
      ),
    );
  }
}

// ─── Desk notes ────────────────────────────────────────────────────────────

/// §13.3's featured article card: accent-tinted edge (§8.4), category as a
/// [TagPill], headline at the featured size.
///
/// **Flagged, not invented:** §13.3 pairs this card with an `AreaTrend` chart
/// and the article rows with sparkline thumbnails. `InsightNote` carries only
/// title, body, category and a featured flag — there is no per-note series in
/// the model and no endpoint that supplies one. Per plan §8, a UI element that
/// needs a new backend field is a blocker to flag, not a reason to invent a
/// parallel API or to plot an unrelated series next to a headline and let it
/// imply a relationship. The cards ship without charts; the chart slot is a
/// backend request.
class _FeaturedNote extends StatelessWidget {
  const _FeaturedNote({required this.note});

  final InsightNote note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyreCard(
      accentEdge: true,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.category != null && note.category!.isNotEmpty)
                Flexible(child: TagPill(label: note.category!))
              else
                const Spacer(),
              const SizedBox(width: AppSpace.xs),
              Text('FEATURED', style: AppTypo.label(t, color: t.accentInk)),
            ],
          ),
          const SizedBox(height: AppSpace.inCardGap),
          Text(note.title, style: AppTypo.featuredHeadline(t)),
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(note.body, style: AppTypo.body(t)),
          ],
        ],
      ),
    );
  }
}

/// One row of §13.3's article list. A row, not a card — the notes below the
/// featured one are one list, and §8.3 makes that one card with hairlines.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final InsightNote note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.hairlineRowPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.category != null && note.category!.isNotEmpty) ...[
            TagPill(label: note.category!),
            const SizedBox(height: AppSpace.xs),
          ],
          Text(
            note.title,
            style: AppTypo.rowLabel(t),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xxs),
            Text(
              note.body,
              style: AppTypo.hint(t),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _MoversSection extends StatelessWidget {
  const _MoversSection({
    required this.label,
    required this.result,
    required this.onOpen,
    required this.emptyMessage,
    required this.failedMessage,
    this.byVolume = false,
  });

  final String label;
  final DataResult<List<Quote>>? result;
  final ValueChanged<Quote> onOpen;
  final String emptyMessage;
  final String failedMessage;
  final bool byVolume;

  /// Movers lists show a fixed few rows, not a long scroll.
  static const int maxRows = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: label,
          trailing: result?.isReady == true
              ? FreshnessStamp(
                  asOf: result!.value!
                      .map((q) => q.asOf)
                      .reduce((a, b) => a.isAfter(b) ? a : b),
                  stale: result!.stale,
                )
              : null,
        ),
        if (result == null)
          const AyreCard(
            padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(
              children: [
                SkeletonTickerRow(),
                SkeletonTickerRow(),
                SkeletonTickerRow(),
              ],
            ),
          )
        else if (result!.isFailed)
          StatePanel.failed(
            headline: failedMessage,
            message: 'The other sections on this page are unaffected.',
            compact: true,
          )
        else if (result!.isEmpty)
          StatePanel.empty(
            headline: 'No movers',
            message: emptyMessage,
            compact: true,
          )
        else
          RowGroup(
            children: [
              // Indexed rather than `indexOf`: two identical symbols in one
              // feed would otherwise both take the first one's rank.
              for (final (i, quote) in _rows.indexed)
                TickerRow(
                  rank: i + 1,
                  symbol: quote.symbol,
                  name: quote.name == quote.symbol ? null : quote.name,
                  price: quote.lastPrice,
                  changePercent: quote.percentChange,
                  changeAbsolute: byVolume ? null : quote.change,
                  volume: byVolume ? quote.volume : null,
                  onTap: () => onOpen(quote),
                ),
            ],
          ),
      ],
    );
  }

  List<Quote> get _rows {
    final rows = result!.value!;
    return rows.length <= maxRows ? rows : rows.sublist(0, maxRows);
  }
}

// ─── Volatility / momentum / volume-surge ─────────────────────────────────
//
// Three byproducts of the same scan (backend spec §2), presented as their
// own independently-failing sections — same "one section's failure doesn't
// take the desk down" rule the rest of this screen already follows.

class _VolatilitySection extends StatelessWidget {
  const _VolatilitySection({required this.result, required this.onRetry});

  final DataResult<VolatilityHistogram>? result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: 'Volatility',
          trailing: result?.isReady == true
              ? FreshnessStamp(
                  asOf: result!.value!.asOf,
                  stale: result!.stale,
                )
              : null,
        ),
        if (result == null)
          const AyreCard(
            child: SkeletonBlock(height: 96, radius: AppRadius.chip),
          )
        else if (result!.isFailed)
          StatePanel.failed(
            headline: "Volatility didn't load.",
            message: 'The other sections on this page are unaffected.',
            compact: true,
            onRetry: onRetry,
          )
        else if (result!.isEmpty)
          const StatePanel.empty(
            headline: 'No volatility reading',
            message: 'The desk has not published a reading for this session yet.',
            compact: true,
          )
        else
          AyreCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: VolatilityBars(buckets: result!.value!.buckets),
          ),
      ],
    );
  }
}

class _MomentumSection extends StatelessWidget {
  const _MomentumSection({required this.result, required this.onRetry});

  final DataResult<MomentumTilt>? result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: 'Momentum',
          trailing: result?.isReady == true
              ? FreshnessStamp(
                  asOf: result!.value!.asOf,
                  stale: result!.stale,
                )
              : null,
        ),
        if (result == null)
          const AyreCard(
            padding: EdgeInsets.all(AppSpace.lg),
            child: Center(
              child: SkeletonBlock(width: 132, height: 132, radius: 66),
            ),
          )
        else if (result!.isFailed)
          StatePanel.failed(
            headline: "Momentum didn't load.",
            message: 'The other sections on this page are unaffected.',
            compact: true,
            onRetry: onRetry,
          )
        else if (result!.isEmpty)
          const StatePanel.empty(
            headline: 'No momentum reading',
            message: 'The desk has not published a reading for this session yet.',
            compact: true,
          )
        else
          AyreCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Center(
              child: BreadthDonut(
                advances: result!.value!.bullish,
                declines: result!.value!.bearish,
                centerLabel: 'BULLISH',
                primaryLabel: 'Bullish',
                secondaryLabel: 'Bearish',
              ),
            ),
          ),
      ],
    );
  }
}

class _VolumeSurgeSection extends StatelessWidget {
  const _VolumeSurgeSection({
    required this.result,
    required this.onOpen,
    required this.onRetry,
  });

  final DataResult<VolumeSurgeBoard>? result;
  final ValueChanged<String> onOpen;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: 'Volume surge',
          trailing: result?.isReady == true
              ? FreshnessStamp(
                  asOf: result!.value!.asOf,
                  stale: result!.stale,
                )
              : null,
        ),
        if (result == null)
          const AyreCard(
            padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(
              children: [
                SkeletonTickerRow(),
                SkeletonTickerRow(),
                SkeletonTickerRow(),
              ],
            ),
          )
        else if (result!.isFailed)
          StatePanel.failed(
            headline: "Volume Surge didn't load.",
            message: 'The other sections on this page are unaffected.',
            compact: true,
            onRetry: onRetry,
          )
        else if (result!.isEmpty)
          const StatePanel.empty(
            headline: 'No volume surge',
            message: 'No stock is trading meaningfully above its 20-day '
                'average volume right now.',
            compact: true,
          )
        else
          AyreCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: VolumeSurgeLeaderboard(
              rows: result!.value!.rows,
              onTap: (row) => onOpen(row.symbol),
            ),
          ),
      ],
    );
  }
}