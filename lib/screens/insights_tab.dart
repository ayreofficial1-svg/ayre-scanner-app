import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_instrument_tile.dart';
import '../widgets/figure.dart';
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
///
/// v5 (redesign plan Phase 4): the sentiment card pairs the gauge with the
/// desk's written takeaway and a one-line breadth stat (§2.2); the three movers
/// lists share the tile + two text lines + trailing value/delta row grammar
/// with a "See all" control top-right. Everything shown is real feed data —
/// there is deliberately **no per-row sparkline**, because the backend supplies
/// no series for movers (§3).
class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key, required this.marketData, this.active = true});

  final MarketDataService marketData;

  /// Whether this tab is the one currently showing in the shell's
  /// [IndexedStack]. See [HomeTab.active] for why this exists: it stops
  /// [_refreshLive] from fetching and rebuilding this screen's four
  /// sections every 10s while another tab is on screen.
  final bool active;

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
    if (widget.active) _load(initial: true);
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
  void didUpdateWidget(InsightsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      // First time this tab has ever been selected: it never ran its
      // initial load (see initState), so a plain live-refresh would leave
      // _notes/_volatility/_momentum/_volumeSurge stuck null forever.
      _sentiment == null ? _load(initial: true) : _refreshLive();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLive() async {
    // Off-screen tabs skip the tick entirely — see [InsightsTab.active].
    if (!widget.active) return;
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
    // reading's subject is direction, so a bearish gauge reads red and a
    // neutral one gold. Open decision #12.
    //
    // A *bullish* reading passes no tone at all, which is §2A's own spec for
    // this gauge — flat `accent` fill and end-cap, `accentInk` on `accentSoft`
    // for the band pill — and is the case the reference image shows. Emerald is
    // both the brand accent and the gain colour, so the arc still reads as
    // "up" without a second green being introduced.
    final Color? tone = switch (sentiment.score) {
      < 35 => t.negative,
      < 65 => t.neutral,
      _ => null,
    };
    final hasCounts =
        sentiment.advances != null || sentiment.declines != null;

    return AyreCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SentimentHeadline(sentiment: sentiment, tone: tone),
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
          if (result!.stale) ...[
            const SizedBox(height: AppSpace.inCardGap),
            const StaleNotice(),
          ],
        ],
      ),
    );
  }
}

/// The top of the sentiment card (§2.2): the gauge, paired beside the desk's
/// written takeaway and a one-line breadth stat with a small trend glyph.
///
/// **Nothing here is written by the app.** The takeaway is the feed's own
/// `note` — shown verbatim, only when the desk supplied one — and the stat is
/// computed from the feed's real advance/decline counts, only when it supplied
/// both. With neither, the gauge stands alone rather than being padded with an
/// invented sentence.
///
/// Side by side where the card is wide enough and the text scale is modest;
/// stacked (gauge above, text below) otherwise, so an accessibility text size
/// or a 320pt phone never squeezes the takeaway into a sliver.
class _SentimentHeadline extends StatelessWidget {
  const _SentimentHeadline({required this.sentiment, required this.tone});

  final Sentiment sentiment;
  final Color? tone;

  /// Inner card width at which gauge + gap + a readable text column fit.
  static const double _sideBySideMinWidth = 296;

  /// The gauge's width when it shares the row (its stacked width is the
  /// spec's 176). Thickness is unchanged, so the arc keeps its weight.
  static const double _pairedGaugeWidth = 148;

  /// Above this text scale the pairing stacks.
  static const double _maxPairedTextScale = 1.3;

  /// A takeaway this short reads as a headline; longer notes drop to body
  /// weight so a paragraph is never set in bold.
  static const int _headlineMaxChars = 90;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final note = sentiment.note?.trim();
    final takeaway = (note == null || note.isEmpty) ? null : note;
    final breadth = _breadthLine(sentiment, t);

    if (takeaway == null && breadth == null) {
      return Center(
        child: SentimentGauge(
          score: sentiment.score,
          band: sentiment.band,
          tone: tone,
        ),
      );
    }

    final details = _SentimentDetails(
      takeaway: takeaway,
      breadth: breadth,
      headline: takeaway != null && takeaway.length <= _headlineMaxChars,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(100) / 100;
        final paired =
            constraints.maxWidth >= _sideBySideMinWidth &&
            textScale <= _maxPairedTextScale;

        if (paired) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SentimentGauge(
                score: sentiment.score,
                band: sentiment.band,
                tone: tone,
                width: _pairedGaugeWidth,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(child: details),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SentimentGauge(
                score: sentiment.score,
                band: sentiment.band,
                tone: tone,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            details,
          ],
        );
      },
    );
  }

  /// "X of Y stocks advancing" (or "declining", when more names fell than
  /// rose) from the feed's own counts, with a matching trend glyph. Null unless
  /// the feed supplied both advances and declines and they cover at least one
  /// stock — the same precondition Home's sentiment card applies.
  static ({String text, AyreGlyph? glyph, Color tone})? _breadthLine(
    Sentiment s,
    AppThemeTokens t,
  ) {
    final adv = s.advances;
    final dec = s.declines;
    if (adv == null || dec == null) return null;
    final total = adv + dec + (s.unchanged ?? 0);
    if (total <= 0) return null;

    final declining = dec > adv;
    final count = declining ? dec : adv;
    final AyreGlyph? glyph = switch (adv.compareTo(dec)) {
      > 0 => AyreGlyph.trendUp,
      < 0 => AyreGlyph.trendDown,
      _ => null,
    };
    final Color tone = switch (adv.compareTo(dec)) {
      > 0 => t.positive,
      < 0 => t.negative,
      _ => t.foregroundMuted,
    };

    return (
      text:
          '${formatPrice(count, decimals: 0)} of '
          '${formatPrice(total, decimals: 0)} stocks '
          '${declining ? 'declining' : 'advancing'}',
      glyph: glyph,
      tone: tone,
    );
  }
}

/// The written half of [_SentimentHeadline]: the takeaway, then the breadth
/// stat under it.
class _SentimentDetails extends StatelessWidget {
  const _SentimentDetails({
    required this.takeaway,
    required this.breadth,
    required this.headline,
  });

  final String? takeaway;
  final ({String text, AyreGlyph? glyph, Color tone})? breadth;

  /// True for a short takeaway, which is set in the strong body weight.
  final bool headline;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final line = breadth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (takeaway != null)
          Text(
            takeaway!,
            style: headline
                ? AppTypo.bodyStrong(t)
                : AppTypo.body(t, color: t.textPrimary),
          ),
        if (takeaway != null && line != null)
          const SizedBox(height: AppSpace.xs),
        if (line != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (line.glyph != null) ...[
                AyreIcon(line.glyph!, size: 14, color: line.tone),
                const SizedBox(width: AppSpace.xxs),
              ],
              Expanded(
                child: Text(
                  line.text,
                  style: AppTypo.caption(t, color: t.foregroundMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
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

class _MoversSection extends StatefulWidget {
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

  /// Movers lists show a fixed few rows until "See all" is tapped. The backend
  /// returns at most ten per list, so expanding is bounded.
  static const int collapsedRows = 5;

  @override
  State<_MoversSection> createState() => _MoversSectionState();
}

class _MoversSectionState extends State<_MoversSection> {
  /// Whether the list is showing every row the feed returned. Lives here, so
  /// the 10s live refresh — which replaces `result` but not this widget —
  /// doesn't collapse a list the user just opened.
  bool _expanded = false;

  List<Quote> get _all => widget.result?.value ?? const <Quote>[];

  bool get _canExpand => _all.length > _MoversSection.collapsedRows;

  List<Quote> get _rows => (_expanded || !_canExpand)
      ? _all
      : _all.sublist(0, _MoversSection.collapsedRows);

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final ready = result != null && result.isReady && _all.isNotEmpty;
    final showToggle = ready && _canExpand;
    // `ready` implies `result != null`, but Dart doesn't promote through a
    // separate bool, so the staleness is read once here.
    final stale = result?.stale ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: widget.label,
          // The "See all" link carries its own vertical tap padding, which
          // already supplies most of the gap under the label.
          padding: EdgeInsets.only(
            bottom: showToggle ? AppSpace.xxs : AppSpace.sm,
          ),
          trailing: ready
              ? _MoversTrailing(
                  asOf: _all.map((q) => q.asOf).reduce(
                    (a, b) => a.isAfter(b) ? a : b,
                  ),
                  stale: stale,
                  showToggle: showToggle,
                  expanded: _expanded,
                  onToggle: _toggle,
                )
              : null,
        ),
        if (result == null)
          const AyreCard(
            padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(
              children: [
                SkeletonTickerRow(tile: true),
                SkeletonTickerRow(tile: true),
                SkeletonTickerRow(tile: true),
              ],
            ),
          )
        else if (result.isFailed)
          StatePanel.failed(
            headline: widget.failedMessage,
            message: 'The other sections on this page are unaffected.',
            compact: true,
          )
        else if (result.isEmpty || _all.isEmpty)
          StatePanel.empty(
            headline: 'No movers',
            message: widget.emptyMessage,
            compact: true,
          )
        else
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.pageTransition,
            curve: AppMotion.ease,
            alignment: Alignment.topCenter,
            child: RowGroup(
              // Hairlines start at the text, not under the tile.
              indent:
                  AppSpace.md + AyreInstrumentTile.defaultSize + AppSpace.md,
              children: [
                // §2.2's row grammar: monogram tile, symbol over company
                // name, price over change. The old rank numeral is gone — the
                // list is already in rank order and the tile is the leading
                // element now. No sparkline: the feed carries no series for
                // movers (§3).
                for (final quote in _rows)
                  TickerRow(
                    leading: AyreInstrumentTile(symbol: quote.symbol),
                    symbol: quote.symbol,
                    name: quote.name == quote.symbol ? null : quote.name,
                    price: quote.lastPrice,
                    changePercent: quote.percentChange,
                    changeAbsolute: widget.byVolume ? null : quote.change,
                    volume: widget.byVolume ? quote.volume : null,
                    onTap: () => widget.onOpen(quote),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A movers list's trailing header slot: the freshness stamp, and — when the
/// feed returned more rows than the collapsed list shows — the "See all"
/// control (§2.2).
///
/// Scaled down as one unit rather than letting either part overflow: this slot
/// is narrow, and both parts are wider than they look at large text sizes.
/// Past a 1.3× text scale the stamp is dropped when the control is present —
/// shrinking both to fit would leave the one tappable part unreadably small,
/// and the stamp is passive.
class _MoversTrailing extends StatelessWidget {
  const _MoversTrailing({
    required this.asOf,
    required this.stale,
    required this.showToggle,
    required this.expanded,
    required this.onToggle,
  });

  final DateTime asOf;
  final bool stale;
  final bool showToggle;
  final bool expanded;
  final VoidCallback onToggle;

  static const double _maxStampedTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final showStamp = !showToggle || textScale <= _maxStampedTextScale;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showStamp) FreshnessStamp(asOf: asOf, stale: stale),
          if (showToggle) ...[
            if (showStamp) const SizedBox(width: AppSpace.sm),
            _SeeAllLink(expanded: expanded, onTap: onToggle),
          ],
        ],
      ),
    );
  }
}

/// "See all" / "Show less" — an in-place expand of the same list, not a new
/// screen: the feed's whole list is already in hand (at most ten rows), so a
/// route would only re-render it.
///
/// The vertical padding is tap area, not decoration: 15pt above and below a
/// ~16pt line clears the 44pt target floor.
class _SeeAllLink extends StatelessWidget {
  const _SeeAllLink({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
          child: Text(
            expanded ? 'Show less' : 'See all',
            style: AppTypo.ui(
              fontSize: AppTextScale.hint,
              fontWeight: FontWeight.w700,
              color: t.accentInk,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
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