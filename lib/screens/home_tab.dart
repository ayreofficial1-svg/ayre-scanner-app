import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../main.dart' show AppThemeController;
import '../services/api_service.dart';
import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_avatar.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_hills.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_index_art.dart';
import '../widgets/ayre_insight_carousel.dart';
import '../widgets/ayre_logo.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';
import '../widgets/ticker_trace.dart';
import 'home_shell.dart' show initialsFor;
import 'index_detail_screen.dart';
import 'insight_note_screen.dart';
import 'notifications_screen.dart';

/// Home — the market gateway (Spec §13.1).
///
/// v5 order: greeting header (with the decorative hill ornament behind it) →
/// **Market Sentiment card** → index board → market-breadth donut →
/// **Market Insight carousel** → footer line. The screen's *information* is
/// unchanged from v4 except that the composite sentiment reading, which used to be a gauge beside the breadth
/// donut, is now the top-of-page Market Sentiment card (a bucketed
/// Bullish/Neutral/Bearish label with a one-line description). The gauge
/// itself lives on Insights; the donut stays here, in its own card, because
/// it is the only surface showing the full Nifty-500 advance/decline split.
///
/// Devices retired in earlier phases and still gone:
///
/// * **The ink readout panel.** v3 sat each index's live figures on a dark
///   "terminal feed" plate. The figures sit on the card, and what marks
///   them as live is the LIVE chip and the trace, not a plate behind them.
/// * **The bespoke breadth ring.** `_BreadthRing`/`_RingPainter` were a
///   private, one-screen donut written before there was a shared one. This
///   screen uses `BreadthDonut`.
/// * **The inlined direction rendering.** `DirectionBadge` carries direction
///   wherever a badge is what's wanted.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.marketData,
    this.onAccountResolved,
    this.onOpenProfile,
    this.active = true,
  });

  final MarketDataService marketData;
  final ValueChanged<String>? onAccountResolved;
  final VoidCallback? onOpenProfile;

  /// Whether this tab is the one currently showing in the shell's
  /// [IndexedStack]. The tab stays mounted (and its state preserved) while
  /// on another tab, but there is no reason to keep fetching and rebuilding
  /// its live data every 10s while it isn't on screen — that's main-thread
  /// work (network completion, JSON decode, setState, a full chart/carousel
  /// rebuild) spent on a screen nobody can see. [_liveTimer] keeps ticking
  /// on its normal cadence regardless, but [_refreshLive] no-ops while
  /// inactive and a becoming-active transition triggers one immediate catch-
  /// up refresh instead.
  final bool active;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DataResult<List<Quote>>? _board;
  DataResult<Sentiment>? _breadth;
  // The donut's source (spec §4): the full Nifty-500 count from
  // `/api/breadth/full`, not `_breadth`'s ~140-stock live-tick count.
  // Refreshes on its own fixed hourly schedule server-side — cache-only on
  // every request — so it's loaded in `_load` alongside everything else but
  // deliberately left out of `_refreshLive`'s 10s tick, the same way
  // Insights treats its own scan-cadence surfaces (volatility/momentum/
  // volume-surge): polling a cache that only changes hourly would just
  // re-fetch the same numbers.
  DataResult<FullBreadth>? _fullBreadth;
  // The Market Insight carousel's source: the same admin-curated desk notes
  // (`/api/insights`) the Insights tab lists. Editorial content that changes
  // a few times a day at most, so — like `_fullBreadth` — it loads in `_load`
  // and is left out of `_refreshLive`'s 10s tick.
  DataResult<List<InsightNote>>? _notes;
  String _accountName = '';
  bool _loading = true;
  Timer? _liveTimer;
  bool _liveRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    // Board + breadth only — session is already resolved above, and this
    // fires often enough that re-checking it every tick would be wasted
    // work. Safe to poll this often: the backend serves it from Fyers'
    // single live WebSocket, so this never adds extra Fyers/NSE requests.
    _liveTimer = Timer.periodic(
      liveMarketRefreshInterval,
      (_) => _refreshLive(),
    );
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  /// Fired once, shortly after the app returns to the foreground (after the
  /// network has had a moment to reconnect). A request that was in flight when
  /// the app was backgrounded may never complete, so its guard is reset.
  void _onAppResumed() {
    if (!mounted || !widget.active) return;
    _liveRefreshInFlight = false;
    if (AppLifecycleService.instance.lastAway > const Duration(minutes: 5)) {
      // Away long enough that the hourly/editorial surfaces are stale too.
      _load(initial: true);
    } else {
      _refreshLive();
    }
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _refreshLive();
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLive() async {
    // Off-screen tabs (the shell keeps every tab mounted in an
    // IndexedStack) skip the tick entirely rather than fetch and rebuild
    // for a screen nobody can see — see [HomeTab.active].
    if (!widget.active) return;
    // Backgrounded, or still waiting for the network to settle after resume —
    // the resume listener triggers the catch-up refresh.
    if (!AppLifecycleService.instance.canFetch) return;
    // A tick that fires while the previous one is still awaiting its
    // response would otherwise pile a second request on top of the first —
    // harmless individually, but across every live-refreshing screen it's
    // how a single slow response turns into an ever-growing backlog of
    // in-flight requests. Skipping the tick is enough: the next one four
    // seconds later picks up cleanly.
    if (!mounted || _liveRefreshInFlight) return;
    _liveRefreshInFlight = true;
    try {
      final board = await widget.marketData.getIndexBoard();
      final breadth = await widget.marketData.getSentiment(monthly: false);
      if (!mounted) return;
      // A failed poll never replaces good data already on screen.
      setState(() {
        _board = board.keepingLastGood(_board);
        _breadth = breadth.keepingLastGood(_breadth);
      });
    } finally {
      _liveRefreshInFlight = false;
    }
  }

  Future<void> _load({bool initial = false}) async {
    final session = await ApiService.getSession();
    final board = await widget.marketData.getIndexBoard();
    final breadth = await widget.marketData.getSentiment(monthly: false);
    final fullBreadth = await widget.marketData.getFullBreadth();
    final notes = await widget.marketData.getInsightNotes();
    if (!mounted) return;

    final name =
        session?['display_name']?.toString() ??
        session?['username']?.toString() ??
        '';

    setState(() {
      _accountName = name;
      _board = board.keepingLastGood(_board);
      _breadth = breadth.keepingLastGood(_breadth);
      _fullBreadth = fullBreadth.keepingLastGood(_fullBreadth);
      _notes = notes.keepingLastGood(_notes);
      _loading = false;
    });
    widget.onAccountResolved?.call(name);

    // A refresh that lands new data confirms itself; opening the app doesn't.
    if (!initial) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final displayName =
        SettingsStore.instance.displayNameOverride ?? _accountName;

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
        child: ListView(
          // §6.1's page padding: 20 horizontal, 12 top. The bottom leaves room
          // for the glass nav bar, which the shell draws over the body.
          padding: const EdgeInsets.fromLTRB(
            AppSpace.pageHorizontal,
            AppSpace.pageTop,
            AppSpace.pageHorizontal,
            120,
          ),
          children: [
            // The hills are the header's backdrop, not part of its layout:
            // positioned to the page's top-right corner (past the list
            // padding, so they bleed to the viewport edge) and painted first.
            // `Stack` sizes to the SafeArea child alone.
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  top: -AppSpace.pageTop,
                  right: -AppSpace.pageHorizontal,
                  child: AyreHills(),
                ),
                SafeArea(
                  bottom: false,
                  child: Entrance(
                    child: _Header(
                      name: displayName,
                      onOpenProfile: widget.onOpenProfile,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sectionGap),
            Entrance(
              index: 1,
              child: _SentimentCard(
                sentimentResult: _loading ? null : _breadth,
                breadthResult: _loading ? null : _fullBreadth,
                onRetry: _load,
              ),
            ),
            const SizedBox(height: AppSpace.sectionGap),
            const Entrance(
              index: 2,
              child: SectionLabel(label: 'Index board'),
            ),
            _IndexBoard(
              result: _loading ? null : _board,
              onOpen: _openIndex,
              onRetry: _load,
            ),
            const SizedBox(height: AppSpace.sectionGap),
            Entrance(
              index: 3,
              child: const SectionLabel(label: 'Market breadth'),
            ),
            _BreadthCard(
              breadthResult: _loading ? null : _fullBreadth,
              onRetry: _load,
            ),
            // An empty desk omits the card *and* its gap, so Home doesn't end
            // in a hole; loading and failed still show their own states.
            if (_showsInsights) ...[
              const SizedBox(height: AppSpace.sectionGap),
              Entrance(
                index: 4,
                child: _InsightSection(
                  result: _loading ? null : _notes,
                  onReadMore: _openInsight,
                  onRetry: _load,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.sectionGap),
            const Entrance(index: 5, child: _FooterLine()),
          ],
        ),
      ),
    );
  }

  /// False only when the desk answered with nothing to show.
  bool get _showsInsights {
    if (_loading) return true;
    final notes = _notes;
    if (notes == null || notes.isFailed) return true;
    return notes.isReady && notes.value!.isNotEmpty;
  }

  void _openInsight(InsightNote note) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      terminalRoute(builder: (_) => InsightNoteScreen(note: note)),
    );
  }

  void _openIndex(Quote quote) {
    final index = _indexIdFor(quote) ?? IndexId.nifty50;
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      terminalRoute(
        builder: (_) => IndexDetailScreen(
          index: index,
          marketData: widget.marketData,
          seed: quote,
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

/// Time-of-day salutation from the device clock. Local time, three buckets —
/// there's no server-side notion of the user's morning to defer to.
String _greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onOpenProfile});

  final String name;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final resolved = name.trim();
    final greeting = _greetingFor(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The only in-app brand placement: a small wordmark, sized to
              // sit beneath the live content rather than compete with it.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const LogoWordmark(fontSize: 15),
                    const SizedBox(width: AppSpace.xs),
                    Text('SCANNER', style: AppTypo.label(t)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              // §2.1's hierarchy: a lighter, smaller salutation over the
              // name, which is the boldest, largest text in the header. Both
              // are existing scale steps (`featuredHeadline` / `page`) — no
              // new type role. With no name yet, the salutation stands alone
              // at title size rather than dangling a comma.
              if (resolved.isEmpty)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(greeting, style: AppTypo.pageTitle(t)),
                )
              else
                // Greeting and name are wrapped together in one FittedBox
                // (rather than two separately-scaled ones) so they share a
                // single baseline and scale as one unit — the fix for the
                // pair drifting out of alignment with each other and with
                // the icon controls beside them.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$greeting, ',
                        style: AppTypo.display(
                          fontSize: AppTextScale.featuredHeadline,
                          fontWeight: FontWeight.w500,
                          color: t.textPrimary,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(resolved, style: AppTypo.pageTitle(t)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        const _ThemeToggle(),
        const SizedBox(width: AppSpace.xs),
        ListenableBuilder(
          listenable: NotificationLog.instance,
          builder: (context, _) => _HeaderControl(
            glyph: AyreGlyph.bell,
            label: 'Alerts',
            badge: NotificationLog.instance.hasUnread,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                terminalRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        _AccountControl(name: resolved, onTap: onOpenProfile),
      ],
    );
  }
}

/// The Home theme toggle (§13.1).
///
/// Writes to the same `setThemeMode` the Settings tiles do, so the two can
/// never disagree — there is one setter, on `AppThemeController`, and both
/// call it. Phase 1A restored `System` as a Settings option; this toggle
/// still only moves between explicit Light/Dark, matching a single-button
/// toggle's "shows the mode you're about to move to" convention — tapping
/// it while on `System` pins the theme to the opposite of whatever `System`
/// is currently resolving to, same as picking a tile in Settings would.
///
/// Icon-only, so unlike the nav it genuinely needs a semantic label — and the
/// label states what tapping *does*, not what mode you're in, since "Dark" as
/// a button name is ambiguous about direction.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HeaderControl(
      // Shows the mode you are about to move to, which is the convention that
      // makes a single-button toggle legible.
      glyph: isDark ? AyreGlyph.sun : AyreGlyph.moon,
      label: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      onTap: () {
        HapticFeedback.selectionClick();
        controller.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }
}

/// Header controls (v5 §2A, "Circular header icon buttons"): flat 44pt
/// circles — `surface` (white) in light, `surfaceRaised` in dark — with a
/// `textPrimary` glyph and, for the bell, a `negative` unread dot. A circle
/// is the spec'd exception to the rounded-square icon-tile rule here;
/// no gradient, no shadow.
class _HeaderControl extends StatelessWidget {
  const _HeaderControl({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.badge = false,
  });

  final AyreGlyph glyph;
  final String label;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? t.surfaceRaised : t.surface;
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.circle,
        child: Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: t.hairline),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AyreIcon(glyph, size: 18, color: t.textPrimary),
              if (badge)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      // An unread marker is an alert: the true-red `negative`
                      // token, ringed in the button's own fill so it reads as
                      // a dot sitting on the circle.
                      color: t.negative,
                      shape: BoxShape.circle,
                      border: Border.all(color: fill, width: 1.5),
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

class _AccountControl extends StatelessWidget {
  const _AccountControl({required this.name, required this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profile',
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.circle,
        // The identity-accent chip (lavender/plum), never brand green.
        child: AyreAvatar(initials: initialsFor(name)),
      ),
    );
  }
}

/// Which of the three known indices a quote is, by symbol and then by label;
/// null for anything else (a card then takes the neutral identity rather than
/// borrowing another index's tint).
IndexId? _indexIdFor(Quote quote) {
  final bySymbol = IndexId.fromId(quote.symbol);
  if (bySymbol != null) return bySymbol;
  for (final candidate in IndexId.values) {
    if (candidate.label == quote.name) return candidate;
  }
  return null;
}

// ─── Index board ───────────────────────────────────────────────────────────

/// The three instruments. The whole card is the tap target into Index Detail.
class _IndexBoard extends StatelessWidget {
  const _IndexBoard({
    required this.result,
    required this.onOpen,
    required this.onRetry,
  });

  final DataResult<List<Quote>>? result;
  final ValueChanged<Quote> onOpen;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.cardGap),
            const _IndexCardSkeleton(),
          ],
        ],
      );
    }

    if (result!.isFailed) {
      return StatePanel.failed(
        headline: 'Index feed unavailable',
        message: "The levels below couldn't be fetched for this session.",
        onRetry: onRetry,
      );
    }

    if (result!.isEmpty) {
      return const StatePanel.empty(
        headline: 'No index data',
        message: 'The feed returned no instruments for this session.',
      );
    }

    final quotes = result!.value!;
    final columns = AppBreakpoints.columns(context);

    // Home stays a linear narrative on phones; wider viewports lay the three
    // instruments side by side rather than stretching one card across a desk.
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < quotes.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.cardGap),
            Entrance(
              index: i + 1,
              child: _IndexCard(
                quote: quotes[i],
                stale: result!.stale,
                onTap: () => onOpen(quotes[i]),
              ),
            ),
          ],
        ],
      );
    }

    // IntrinsicHeight so the three cards share a height. A bare stretch would
    // ask this Row's unbounded parent for an infinite height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < quotes.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.cardGap),
            Expanded(
              child: Entrance(
                index: i + 1,
                child: _IndexCard(
                  quote: quotes[i],
                  stale: result!.stale,
                  onTap: () => onOpen(quotes[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One index card (v5 §2.1): a circular, radial-gradient icon tile + name +
/// exchange, the LIVE chip opposite, the hero level, the change row, and the
/// "VIEW CONSTITUENTS" link — on the index's own identity tint (§2A).
///
/// **No period tabs and no Open/High/Low row.** The backend supplies neither
/// for an index (plan §3), so the reference's sparkline slot is an ornament
/// ([AyreIndexFlourish]) behind the figures — and only while `trace` is empty.
/// The moment a quote carries a real trace, the flourish is not built and the
/// sparkline draws beneath the change row as before.
class _IndexCard extends StatelessWidget {
  const _IndexCard({
    required this.quote,
    required this.stale,
    required this.onTap,
  });

  final Quote quote;
  final bool stale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final up = quote.percentChange >= 0;
    // §12.1: the trace inherits the colour of its subject. This is the one
    // decision that makes the sparkline informative rather than decorative.
    final tone = up ? t.positive : t.negative;
    final identity = AyreIndexIdentity.of(context, _indexIdFor(quote));
    final tint = identity.tint;
    final hasTrace = quote.trace.length >= 2;

    // The level and its change row. Wrapped in the flourish backdrop below
    // when there is no trace; otherwise laid out bare.
    final figures = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The level counts up (§12.3/§15.2) rather than rolling its digits.
        // `formatPrice` keeps Indian grouping while it counts, so the string
        // doesn't change shape as it arrives.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: CountUpFigure(
            value: quote.lastPrice.toDouble(),
            // Counting a five-figure index level up from zero would be a
            // slot machine, so it starts within sight of the target — the
            // exact case `CountUpFigure`'s `from` exists for.
            from: quote.lastPrice.toDouble() - quote.change.toDouble(),
            format: (v) => formatPrice(v),
            fontSize: AppTextScale.hero,
            color: t.textPrimary,
            semanticsLabel: '${quote.name} at ${formatPrice(quote.lastPrice)}',
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              DeltaFigure(
                change: quote.percentChange,
                fontSize: AppTextScale.rowLabel,
              ),
              const SizedBox(width: AppSpace.xs),
              Figure(
                formatDelta(quote.change, percent: false),
                fontSize: AppTextScale.hint,
                color: t.foregroundMuted,
              ),
            ],
          ),
        ),
      ],
    );

    return AyreCard(
      onTap: onTap,
      color: tint.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AyreIndexIconTile(glyph: identity.glyph, tint: tint),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                flex: 3,
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
              // chip it hasn't earned, and never the word "Delayed" (§4).
              // Omitted outright rather than a `SizedBox.shrink()` inside
              // `ShrinkTrailing`: same result, without a zero-size
              // `FittedBox` child or a dangling gap.
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
          if (hasTrace)
            figures
          else
            AyreIndexFlourish(color: tint.trace, child: figures),
          if (hasTrace) ...[
            const SizedBox(height: AppSpace.inCardGap),
            // Full card width rather than §12.2's fixed 96px sparkline box:
            // this is the card's own trend, not an inline marker beside a row.
            TickerTrace(
              points: normaliseTrace(quote.trace),
              height: 36,
              color: tone,
              fill: true,
            ),
          ],
          const SizedBox(height: AppSpace.inCardGap),
          Row(
            children: [
              Expanded(
                child: Text(
                  'VIEW CONSTITUENTS',
                  style: AppTypo.label(t, color: t.accentInk),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              AyreIcon(AyreGlyph.forward, size: 12, color: t.accentInk),
            ],
          ),
        ],
      ),
    );
  }
}

/// The skeleton mirrors the real card's shape, block for block (§14.4):
/// circular tile + two label lines, the level, the change row, the link.
class _IndexCardSkeleton extends StatelessWidget {
  const _IndexCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBlock(width: 44, height: 44, radius: AppRadius.circle),
              SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 96, height: 15),
                    SizedBox(height: AppSpace.xxs),
                    SkeletonBlock(width: 36, height: 11),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpace.inCardGap),
          SkeletonBlock(width: 170, height: 34, radius: AppRadius.inset),
          SizedBox(height: AppSpace.xs),
          SkeletonBlock(width: 140, height: 12),
          SizedBox(height: AppSpace.inCardGap),
          SkeletonBlock(width: 110, height: 11),
        ],
      ),
    );
  }
}

// ─── Market Insight ────────────────────────────────────────────────────────

/// The carousel's loading / failed / ready states. An empty desk never gets
/// here — `HomeTab` omits the whole section instead.
class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.result,
    required this.onReadMore,
    required this.onRetry,
  });

  final DataResult<List<InsightNote>>? result;
  final ValueChanged<InsightNote> onReadMore;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) return const AyreInsightSkeleton();

    if (r.isFailed) {
      return StatePanel.failed(
        headline: "Market insight didn't load",
        message: 'The rest of the page is unaffected.',
        compact: true,
        onRetry: onRetry,
      );
    }

    final notes = r.value;
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();
    return AyreInsightCarousel(notes: notes, onReadMore: onReadMore);
  }
}

// ─── Market Sentiment ──────────────────────────────────────────────────────

/// The three buckets a 0–100 sentiment score is read into.
///
/// Breakpoints are **< 35 bearish · 35–64 neutral · ≥ 65 bullish** — the same
/// cut points `Sentiment.band` (Caution / Neutral / Strong) and the Insights
/// gauge's directional tone already use, so the same score never reads as two
/// different moods on two tabs.
enum _Mood { bullish, neutral, bearish }

_Mood _moodFor(int score) => switch (score) {
  < 35 => _Mood.bearish,
  < 65 => _Mood.neutral,
  _ => _Mood.bullish,
};

/// Component-specific colors for the Market Sentiment card (v5 §2A component
/// table). Not `AppThemeTokens` fields — Phase 0 forbids adding any — so they
/// live beside the one widget that consumes them. The bucket word/arrow
/// deliberately do *not* appear here: those reuse `positive`/`neutral`/
/// `negative` per the spec.
abstract final class _SentimentCardColors {
  static const List<Color> gradientLight = [
    Color(0xFFDCEEDF),
    Color(0xFFEAF5EC),
  ];
  static const List<Color> gradientDark = [
    Color(0xFF14251A),
    Color(0xFF0F1D15),
  ];
  static const Color labelLight = Color(0xFF4F6357);
  static const Color labelDark = Color(0xFF9FB0A4);
  static const Color descriptionLight = Color(0xFF64766B);
  static const Color descriptionDark = Color(0xFF9FB0A4);
}

/// The top-of-page Market Sentiment card (§2.1): a small icon + label, the
/// bucketed reading set large and bold with a directional glyph, and a
/// one-line description.
///
/// **Everything on it is real.** The bucket comes from the `/api/sentiment`
/// 0–100 score. The description is, in order of preference: the feed's own
/// `note` when there is one; else "X of Y stocks advancing" from the real
/// advance/decline counts (the sentiment feed's own live-tick counts first,
/// the full Nifty-500 breadth second); else a generic line that states no
/// numbers. It never implies data the API didn't return.
///
/// Neutral carries no glyph, matching `DirectionBadge`'s convention for a
/// flat reading: the word itself is the non-color channel.
class _SentimentCard extends StatelessWidget {
  const _SentimentCard({
    required this.sentimentResult,
    required this.breadthResult,
    required this.onRetry,
  });

  final DataResult<Sentiment>? sentimentResult;

  /// Only consulted for the description fallback — never for the bucket.
  final DataResult<FullBreadth>? breadthResult;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final result = sentimentResult;
    if (result == null) return const _SentimentSkeleton();

    if (result.isFailed) {
      return StatePanel.failed(
        headline: "Sentiment didn't load",
        message: 'The index levels below are unaffected.',
        compact: true,
        onRetry: onRetry,
      );
    }

    final sentiment = result.value;
    if (sentiment == null) {
      return const StatePanel.empty(
        headline: 'No sentiment reading yet',
        message: 'The overall market mood appears once the session is under way.',
        compact: true,
      );
    }

    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (String word, Color tone, AyreGlyph? glyph) = switch (_moodFor(
      sentiment.score,
    )) {
      _Mood.bullish => ('Bullish', t.positive, AyreGlyph.trendUp),
      _Mood.neutral => ('Neutral', t.neutral, null),
      _Mood.bearish => ('Bearish', t.negative, AyreGlyph.trendDown),
    };
    final description = _describe(sentiment, breadthResult?.value);
    final labelColor = dark
        ? _SentimentCardColors.labelDark
        : _SentimentCardColors.labelLight;
    final descriptionColor = dark
        ? _SentimentCardColors.descriptionDark
        : _SentimentCardColors.descriptionLight;

    return AyreCard(
      // The gradient has to reach the card's edge, so the padding moves
      // inside it; `AyreCard` still supplies the radius clip, hairline and
      // shadow.
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? _SentimentCardColors.gradientDark
                : _SentimentCardColors.gradientLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                excludeSemantics: true,
                label:
                    'Market sentiment: $word, score ${sentiment.score} out '
                    'of 100. $description',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AyreIcon(
                          AyreGlyph.instrument,
                          size: 16,
                          color: labelColor,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            'Market Sentiment',
                            style: AppTypo.ui(
                              fontSize: AppTextScale.body,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              word,
                              style: AppTypo.pageTitle(t, color: tone),
                            ),
                          ),
                        ),
                        if (glyph != null) ...[
                          const SizedBox(width: AppSpace.xs),
                          AyreIcon(
                            glyph,
                            size: 26,
                            color: tone,
                            strokeWidth: 2.4,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      description,
                      style: AppTypo.body(t, color: descriptionColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The one-line reading under the bucket. See the class doc for the
  /// fallback order; nothing here is invented.
  static String _describe(Sentiment sentiment, FullBreadth? fullBreadth) {
    final note = sentiment.note?.trim();
    if (note != null && note.isNotEmpty) return note;

    final adv = sentiment.advances;
    final dec = sentiment.declines;
    if (adv != null && dec != null) {
      final total = adv + dec + (sentiment.unchanged ?? 0);
      if (total > 0) return _advancing(adv, total);
    }

    if (fullBreadth != null) {
      final total =
          fullBreadth.advances + fullBreadth.declines + fullBreadth.unchanged;
      if (total > 0) return _advancing(fullBreadth.advances, total);
    }

    return 'Overall market mood, from the latest sentiment reading.';
  }

  static String _advancing(int advances, int total) =>
      '${formatPrice(advances, decimals: 0)} of '
      '${formatPrice(total, decimals: 0)} stocks advancing';
}

/// Mirrors the real card's blocks — label, bucket word, description — so the
/// loaded card doesn't reflow the page (§14.4).
class _SentimentSkeleton extends StatelessWidget {
  const _SentimentSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      padding: EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 120, height: 12),
          SizedBox(height: AppSpace.sm),
          SkeletonBlock(width: 150, height: 30, radius: AppRadius.inset),
          SizedBox(height: AppSpace.xs),
          SkeletonBlock(height: 12),
        ],
      ),
    );
  }
}

// ─── Breadth ───────────────────────────────────────────────────────────────

/// Market breadth (§13.1): the full Nifty-500 advance/decline split as a
/// donut, in its own card.
///
/// The composite sentiment reading that used to sit beside it as a gauge is
/// now the Market Sentiment card at the top of the page, so this card has a
/// single source — [FullBreadth] (`GET /api/breadth/full`, a separate hourly
/// poll across the entire Nifty 500) — and a single ready/empty/failed state
/// of its own. Sentiment failing no longer blanks it, and vice versa.
class _BreadthCard extends StatelessWidget {
  const _BreadthCard({required this.breadthResult, required this.onRetry});

  final DataResult<FullBreadth>? breadthResult;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final result = breadthResult;
    if (result == null) return const _BreadthSkeleton();

    if (result.isFailed) {
      return StatePanel.failed(
        headline: "Market breadth didn't load",
        message: 'The index levels above are unaffected.',
        compact: true,
        onRetry: onRetry,
      );
    }

    final breadth = result.value;
    if (breadth == null) {
      return const StatePanel.empty(
        headline: 'No breadth reading yet',
        message: 'Advances and declines appear once the session is under way.',
        compact: true,
      );
    }

    return AyreCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: BreadthDonut(
              advances: breadth.advances,
              declines: breadth.declines,
              unchanged: breadth.unchanged,
              // Home shows the plain picture only: no "ADVANCING" caption
              // inside the ring and no counts beside the legend labels.
              centerLabel: null,
              showLegendCounts: false,
            ),
          ),
          const SizedBox(height: AppSpace.inCardGap),
          Center(
            child: Text(
              'How stocks moved today',
              textAlign: TextAlign.center,
              style: AppTypo.hint(t, color: t.foregroundMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadthSkeleton extends StatelessWidget {
  const _BreadthSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      padding: EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          // Circular, because what it stands in for is: a skeleton that
          // doesn't share the real layout's shape just moves the reflow later.
          SkeletonBlock(width: 132, height: 132, radius: AppRadius.circle),
          SizedBox(height: AppSpace.md),
          SkeletonBlock(width: 190, height: 12),
        ],
      ),
    );
  }
}

/// The footer line (§13.1) — the quiet last word on the page, stating what the
/// data is rather than advertising anything.
class _FooterLine extends StatelessWidget {
  const _FooterLine();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        const HairlineDivider(),
        const SizedBox(height: AppSpace.md),
        Text(
          'For informational purposes only, not investment advice.',
          textAlign: TextAlign.center,
          style: AppTypo.hint(t),
        ),
      ],
    );
  }
}