import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_instrument_tile.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';
import 'equity_detail_screen.dart';

/// Insights — the market intelligence desk.
///
/// All three mover lists, the volatility / momentum / volume-surge readings and
/// the desk notes live here as one continuous feed: shared row height, shared
/// hairlines, shared label typography. It replaces the old "Climate" tab in
/// name and in concept.
///
/// Each section owns its own state. A failed movers list never takes the
/// volatility reading down with it, and vice versa.
///
/// v5 (redesign plan Phase 4): the three movers lists share the tile + two
/// text lines + trailing value/delta row grammar with a "See all" control
/// top-right. Everything shown is real feed data — there is deliberately
/// **no per-row sparkline**, because the backend supplies no series for
/// movers (§3).
///
/// Every section heading carries a small "i" icon that opens a short,
/// plain-language explanation of what the section shows (see [SectionLabel]).
/// The wording lives in [_InsightInfo] below so it can be edited in one place.
class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key, required this.marketData, this.active = true});

  final MarketDataService marketData;

  /// Whether this tab is the one currently showing in the shell's
  /// [IndexedStack]. See [HomeTab.active] for why this exists: it stops
  /// [_refreshLive] from fetching and rebuilding this screen's live
  /// sections every 10s while another tab is on screen.
  final bool active;

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
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
    // Gainers/losers/most-active only — not _notes, which is
    // editorially authored content that doesn't change tick to tick.
    // Safe to poll this often: the backend serves the market-data pieces
    // from Fyers' single live WebSocket feed, so this never adds extra
    // Fyers/NSE requests no matter how frequently it ticks.
    _liveTimer = Timer.periodic(
      liveMarketRefreshInterval,
      (_) => _refreshLive(),
    );
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  /// Fired once, shortly after the app returns to the foreground. Resets the
  /// in-flight guard (a request cut off by backgrounding may never complete).
  void _onAppResumed() {
    if (!mounted || !widget.active) return;
    _liveRefreshInFlight = false;
    if (AppLifecycleService.instance.lastAway > const Duration(minutes: 5)) {
      _load(initial: true);
    } else {
      _refreshLive();
    }
  }

  @override
  void didUpdateWidget(InsightsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      // First time this tab has ever been selected: it never ran its
      // initial load (see initState), so a plain live-refresh would leave
      // _notes/_volatility/_momentum/_volumeSurge stuck null forever.
      _gainers == null ? _load(initial: true) : _refreshLive();
    }
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLive() async {
    // Off-screen tabs skip the tick entirely — see [InsightsTab.active].
    if (!widget.active) return;
    // Backgrounded or still settling after resume — see _onAppResumed.
    if (!AppLifecycleService.instance.canFetch) return;
    // See HomeTab._refreshLive: skips a tick rather than let it stack behind
    // a still-running one.
    if (!mounted || _liveRefreshInFlight) return;
    _liveRefreshInFlight = true;
    try {
      final results = await Future.wait([
        widget.marketData.getTopGainers(),
        widget.marketData.getTopLosers(),
        widget.marketData.getMostActive(),
      ]);
      if (!mounted) return;
      // A failed poll never replaces good data already on screen.
      setState(() {
        _gainers = results[0].keepingLastGood(_gainers);
        _losers = results[1].keepingLastGood(_losers);
        _mostActive = results[2].keepingLastGood(_mostActive);
      });
    } finally {
      _liveRefreshInFlight = false;
    }
  }

  Future<void> _load({bool initial = false}) async {
    // Fired together so one slow section doesn't hold up the rest of the desk.
    final results = await Future.wait([
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
      _gainers = (results[0] as DataResult<List<Quote>>).keepingLastGood(
        _gainers,
      );
      _losers = (results[1] as DataResult<List<Quote>>).keepingLastGood(
        _losers,
      );
      _mostActive = (results[2] as DataResult<List<Quote>>).keepingLastGood(
        _mostActive,
      );
      _notes = (results[3] as DataResult<List<InsightNote>>).keepingLastGood(
        _notes,
      );
      _volatility = (results[4] as DataResult<VolatilityHistogram>)
          .keepingLastGood(_volatility);
      _momentum = (results[5] as DataResult<MomentumTilt>).keepingLastGood(
        _momentum,
      );
      _volumeSurge = (results[6] as DataResult<VolumeSurgeBoard>)
          .keepingLastGood(_volumeSurge);
      _loading = false;
    });
    if (!initial) HapticFeedback.mediumImpact();
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
      terminalRoute(
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
      terminalRoute(
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
          message: _kInsightsEmptyMessage,
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
    final columns = AppBreakpoints.columns(context);

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
        // Widened the same way `learn_tab.dart`/`signals_tab.dart` widen
        // once their lists go multi-column (Phase 2A) — the default 620pt
        // reading measure otherwise starves a 2-/3-column movers grid.
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
                    Text('Insights', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      'Market data, in a snapshot.',
                      style: AppTypo.body(t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sectionGap),

            // ── Sections 1–3: the movers lists ──────────────────────────────
            _MoversSection(
              label: 'Top gainers',
              info: _InsightInfo.topGainers,
              result: _loading ? null : _gainers,
              onOpen: _openEquity,
              columns: columns,
              failedMessage: "Top Gainers didn't load.",
            ),
            const SizedBox(height: AppSpace.sectionGap),
            _MoversSection(
              label: 'Top losers',
              info: _InsightInfo.topLosers,
              result: _loading ? null : _losers,
              onOpen: _openEquity,
              columns: columns,
              failedMessage: "Top Losers didn't load.",
            ),
            const SizedBox(height: AppSpace.sectionGap),
            _MoversSection(
              label: 'Most active',
              info: _InsightInfo.mostActive,
              result: _loading ? null : _mostActive,
              onOpen: _openEquity,
              byVolume: true,
              columns: columns,
              failedMessage: "Most Active didn't load.",
            ),

            // ── Section 4: volatility ────────────────────────────────────────
            // Refreshes at scan cadence, not the 10s live tick — see the
            // field doc on _volatility.
            const SizedBox(height: AppSpace.sectionGap),
            _VolatilitySection(
              result: _loading ? null : _volatility,
              onRetry: _reloadVolatility,
            ),

            // ── Section 5: momentum tilt ─────────────────────────────────────
            const SizedBox(height: AppSpace.sectionGap),
            _MomentumSection(
              result: _loading ? null : _momentum,
              onRetry: _reloadMomentum,
            ),

            // ── Section 6: volume-surge leaderboard ──────────────────────────
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
              const SectionLabel(
                label: 'Desk notes',
                info: _InsightInfo.deskNotes,
              ),
              ..._deskNotes(),
            ],
          ],
        ),
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

class _MoversSection extends StatefulWidget {
  const _MoversSection({
    required this.label,
    required this.result,
    required this.onOpen,
    required this.failedMessage,
    required this.columns,
    required this.info,
    this.byVolume = false,
  });

  final String label;

  /// The plain-language explanation opened by the heading's "i" icon.
  /// Phase 4: the redundant one-line subtitle that used to sit under this
  /// heading was removed — every heading here already carries an "i" icon
  /// with this same explanation, so the subtitle only repeated it.
  final String info;
  final DataResult<List<Quote>>? result;
  final ValueChanged<Quote> onOpen;

  /// Phase 4: this section's own empty-state sentence was replaced by
  /// [_kInsightsEmptyMessage], the one message shared by every empty state
  /// on this screen — there is no longer a per-section string to hold here.
  final String failedMessage;
  final bool byVolume;

  /// [AppBreakpoints.columns] of the page, threaded down from
  /// `InsightsTab.build` so this list can switch from the single hairline-
  /// divided `RowGroup` to a card grid at wider viewports (Phase 2A).
  final int columns;

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
          info: widget.info,
          // The "See all" link carries its own vertical tap padding, which
          // already supplies most of the gap under the label. The
          // description sits with the heading, so the link's height only
          // adds room around the pair.
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
          const StatePanel.empty(
            headline: 'No movers',
            message: _kInsightsEmptyMessage,
            compact: true,
          )
        else
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.pageTransition,
            curve: AppMotion.ease,
            alignment: Alignment.topCenter,
            child: widget.columns == 1
                ? RowGroup(
                    // Hairlines start at the text, not under the tile.
                    indent: AppSpace.md +
                        AyreInstrumentTile.defaultSize +
                        AppSpace.md,
                    children: [
                      for (final quote in _rows) _row(quote),
                    ],
                  )
                // Phase 2A: the same column-count grid `learn_tab.dart` uses
                // for its course list, so this rank-ordered list reads left-
                // to-right, top-to-bottom rather than losing its order.
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _rows.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.columns,
                      mainAxisSpacing: AppSpace.cardGap,
                      crossAxisSpacing: AppSpace.cardGap,
                      childAspectRatio: 3.6,
                    ),
                    itemBuilder: (context, index) => AyreCard(
                      padding: EdgeInsets.zero,
                      child: _row(_rows[index]),
                    ),
                  ),
          ),
      ],
    );
  }

  // §2.2's row grammar: monogram tile, symbol over company name, price over
  // change. The old rank numeral is gone — the list is already in rank order
  // and the tile is the leading element now. No sparkline: the feed carries
  // no series for movers (§3).
  Widget _row(Quote quote) => TickerRow(
        leading: AyreInstrumentTile(symbol: quote.symbol),
        symbol: quote.symbol,
        name: quote.name == quote.symbol ? null : quote.name,
        price: quote.lastPrice,
        changePercent: quote.percentChange,
        changeAbsolute: widget.byVolume ? null : quote.change,
        volume: widget.byVolume ? quote.volume : null,
        onTap: () => widget.onOpen(quote),
      );
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

  @override
  Widget build(BuildContext context) {
    // The freshness stamp ("As of ...") is intentionally not shown on this
    // tab — see the Insights heading description.
    if (!showToggle) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: _SeeAllLink(expanded: expanded, onTap: onToggle),
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

// ─── Explanations ──────────────────────────────────────────────────────────

/// The text behind each section's "i" icon.
///
/// Written for someone who has never looked at a market screen before: plain,
/// everyday words, short sentences, and each one says what the bars, rings or
/// numbers on the card actually stand for. Edit the wording here — nothing else
/// needs to change.
/// The one shared empty-state message for this screen (Phase 4) — every
/// section below used to write its own sentence ("The desk has not
/// published a reading for this session yet.", "No stock is trading
/// meaningfully above its 20-day average volume right now.", and so on);
/// now every one of them reads this same short, plain, gently witty line,
/// so an empty section always feels like part of one consistent screen
/// rather than each section improvising its own tone.
const String _kInsightsEmptyMessage = 'Nothing to report yet.';

abstract final class _InsightInfo {
  static const String topGainers =
      'These are the stocks whose price has gone up the most today, compared '
      'with where they finished yesterday. The percentage beside each name '
      'shows how much higher it is right now. The list covers the large, '
      'well-known companies we follow.';

  static const String topLosers =
      'These are the stocks whose price has dropped the most today, compared '
      'with where they finished yesterday. The percentage beside each name '
      'shows how much lower it is right now. A stock on this list simply had '
      'a weak day. It does not mean the company is in trouble.';

  static const String mostActive =
      'These are the stocks that have been bought and sold the most today. '
      'The number beside each name is how many shares have changed hands. '
      'A stock can be busy whether its price is rising or falling.';

  static const String volatility =
      'This chart shows how much stocks usually move up and down in a single '
      'day. Each bar is a group of stocks. The number above a bar is how many '
      'stocks are in that group, and the label below it tells you how big '
      'their usual daily swing is. 0-1% means calm stocks that only move a '
      'little. 3%+ means stocks that swing a lot. The taller the bar, the '
      'more stocks fall in that group.';

  static const String momentum =
      'This ring shows which way most stocks are leaning. Bullish means a '
      "stock's recent price movement is pointing upward. Bearish means it is "
      'pointing downward. The big percentage in the middle is the share of '
      'stocks that are bullish. The two counts underneath show how many '
      'stocks are in each group.';

  static const String volumeSurge =
      'These are stocks being traded far more than they normally are. The '
      'number beside each name, such as 2.4×, tells you how many times bigger '
      "today's trading is compared with its usual day over the past month "
      'or so. The longer the bar, the bigger the jump. A sudden rush of '
      'trading often means people have started paying attention to that '
      'stock.';

  static const String deskNotes =
      'Short written notes from our team about what is happening in the '
      'market and why it may matter. The note marked Featured is the one we '
      'think is most worth reading first.';
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
        const SectionLabel(
          label: 'Volatility',
          info: _InsightInfo.volatility,
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
            message: _kInsightsEmptyMessage,
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
        const SectionLabel(
          label: 'Momentum',
          info: _InsightInfo.momentum,
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
            message: _kInsightsEmptyMessage,
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
        const SectionLabel(
          label: 'Volume surge',
          info: _InsightInfo.volumeSurge,
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
            message: _kInsightsEmptyMessage,
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