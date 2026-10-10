import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import '../main.dart' show AppThemeController;
import '../services/auth_service.dart';
import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/settings_store.dart';
import '../services/market_models.dart';
import '../onboarding/tour_content.dart' show TourKeys;
import '../theme/app_theme.dart';
import '../widgets/ayre_avatar.dart';
import '../widgets/ayre_compact_index_card.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_hills.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_insight_carousel.dart';
import '../widgets/ayre_logo.dart';
import '../widgets/ayre_signals_section.dart';
import '../widgets/ayre_tab_scroll.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';
import 'home_shell.dart' show initialsFor;
import 'index_detail_screen.dart';
import 'insight_note_screen.dart';
import 'notifications_screen.dart';

/// Home — the market gateway (Spec §13.1).
///
/// Order: greeting header (with the decorative hill ornament behind it) →
/// **Market Sentiment card** → compact index board → **Signals**
/// (the Weekly Report now has its own
/// Reports tab) → **Market Insight carousel**. Sections are separated by
/// `sectionGap` alone (the closing divider duplicated that spacing).
///
/// The "Market breadth" donut card that used to sit between the index board
/// and the insight carousel has been removed; nothing replaces it, and the
/// remaining sections simply keep the standard section gap between them.
///
/// Devices retired in earlier phases and still gone:
///
/// * **The ink readout panel.** v3 sat each index's live figures on a dark
///   "terminal feed" plate. The figures sit on the card, and what marks
///   them as live is the pulse dot, not a plate behind them.
/// * **The inlined direction rendering.** `DirectionBadge` carries direction
///   wherever a badge is what's wanted.
/// * **The "For informational purposes only, not investment advice."
///   footer text.** Removed; the hairline divider that sat above it is kept,
///   unchanged, as the boundary a later phase uses for new content.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.marketData,
    this.onAccountResolved,
    this.onOpenProfile,
    this.active = true,
    this.signalsFocusToken = 0,
    this.scrollController,
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

  /// Changes whenever something (a signal notification) asks Home to bring the
  /// Signals section into view. Zero means no request.
  final int signalsFocusToken;

  /// Optional controller for the tab's scroll view (A2: re-tap scrolls to
  /// top). Null keeps the previous behaviour.
  final ScrollController? scrollController;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DataResult<List<Quote>>? _board;
  DataResult<Sentiment>? _breadth;
  // The full Nifty-500 advance/decline count from `/api/breadth/full`. It no
  // longer has a card of its own on Home, and as of this phase the Market
  // Sentiment card no longer shows a description line either, so this fetch
  // currently has no consumer anywhere in the app. It is kept — rather than
  // silently removed — because deleting a working fetch other code might
  // still be expected to rely on is a bigger decision than this phase's
  // scope; flagged here for a later phase or a deliberate follow-up decision
  // to actually remove it if it stays unused.
  // Refreshes on its own fixed hourly schedule server-side — cache-only on
  // every request — so it's loaded in `_load` alongside everything else but
  // deliberately left out of `_refreshLive`'s 10s tick, the same way
  // Insights treats its own editorial surface (desk notes): polling a cache
  // that only changes hourly would just re-fetch the same numbers.
  DataResult<FullBreadth>? _fullBreadth;
  // The Market Insight carousel's source: the same admin-curated desk notes
  // (`/api/insights`) the Insights tab lists. Editorial content that changes
  // a few times a day at most, so — like `_fullBreadth` — it loads in `_load`
  // and is left out of `_refreshLive`'s 10s tick.
  DataResult<List<InsightNote>>? _notes;
  // The signals section owns its own fetch (see [SignalsSection]); Home only
  // holds a controller so pull-to-refresh can reload it.
  final SignalsSectionController _signalsController =
      SignalsSectionController();
  final GlobalKey _signalsKey = GlobalKey();
  // True from a focus request until the page has finished loading, so a layout
  // shift above the Signals section (sentiment card landing) re-anchors it.
  bool _focusPending = false;
  String _accountName = '';
  bool _loading = true;
  Timer? _liveTimer;
  bool _liveRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.signalsFocusToken > 0) _requestSignalsFocus();
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
      _load();
    } else {
      _refreshLive();
    }
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _refreshLive();
    if (oldWidget.signalsFocusToken != widget.signalsFocusToken &&
        widget.signalsFocusToken > 0) {
      _requestSignalsFocus();
    }
  }

  void _requestSignalsFocus() {
    _focusPending = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSignals(retry: true),
    );
  }

  /// Brings the Signals section into view. Safe to call repeatedly. If the
  /// section isn't built yet it retries once on the next frame, then gives up
  /// silently.
  void _scrollToSignals({bool retry = false}) {
    if (!mounted || !_focusPending || !widget.active) return;
    final target = _signalsKey.currentContext;
    if (target == null) {
      if (retry) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToSignals(),
        );
      }
      return;
    }
    // Keep the request alive until loading has finished, then stop.
    if (!_loading) _focusPending = false;
    Scrollable.ensureVisible(
      target,
      alignment: 0.05,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.pageTransition,
      curve: AppMotion.ease,
    );
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

  Future<void> _load() async {
    final board = await widget.marketData.getIndexBoard();
    final breadth = await widget.marketData.getSentiment(monthly: false);
    final fullBreadth = await widget.marketData.getFullBreadth();
    final notes = await widget.marketData.getInsightNotes();
    if (!mounted) return;

    final name = AuthService.instance.currentUser?.shownName ?? '';

    setState(() {
      _accountName = name;
      _board = board.keepingLastGood(_board);
      _breadth = breadth.keepingLastGood(_breadth);
      _fullBreadth = fullBreadth.keepingLastGood(_fullBreadth);
      _notes = notes.keepingLastGood(_notes);
      _loading = false;
    });
    widget.onAccountResolved?.call(name);
    // The page above Signals has settled; re-anchor a pending focus request.
    if (_focusPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSignals());
    }
    // A5: no completion haptic after a refresh.
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        AuthService.instance.currentUser?.shownName ?? _accountName;

    return AyreTabScroll(
      controller: widget.scrollController,
      // One network pass per surface; the signals reload is silent.
      onRefresh: () => Future.wait([
        _load(),
        _signalsController.reload(silent: true),
      ]),
      children: [
            // The hills are the header's backdrop, not part of its layout:
            // positioned to the page's top-right corner (past the list
            // padding, so they bleed to the viewport edge) and painted first.
            // `Stack` sizes to the SafeArea child alone.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -AppSpace.pageTop,
                  right: -AppSpace.gutterOf(context),
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
            KeyedSubtree(
              key: _signalsKey,
              child: Entrance(
                index: 3,
                child: SignalsSection(
                  marketData: widget.marketData,
                  active: widget.active,
                  controller: _signalsController,
                  forceColumns: 1,
                ),
              ),
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
      ],
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

    // Two stacked bands. The wordmark and the three controls share the top
    // band, so the salutation below gets the page's full width. Nothing here
    // shrinks to fit: the wordmark wraps, the greeting and name wrap to two
    // lines (G-2).
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              // The only in-app brand placement: a small wordmark, sized to
              // sit beneath the live content rather than compete with it.
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpace.xs,
                children: [
                  const LogoWordmark(fontSize: 15),
                  Text(
                    'SCANNER',
                    style: AppTypo.label(t, color: t.foregroundMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            const KeyedSubtree(key: TourKeys.homeTheme, child: _ThemeToggle()),
            const SizedBox(width: AppSpace.xs),
            KeyedSubtree(
              key: TourKeys.homeAlerts,
              child: ListenableBuilder(
                listenable: NotificationLog.instance,
                builder: (context, _) => _HeaderControl(
                  glyph: AyreGlyph.bell,
                  label: 'Alerts',
                  badge: NotificationLog.instance.hasUnread,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      terminalRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            _AccountControl(name: resolved, onTap: onOpenProfile),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        // The salutation is the header's largest text; the name sits on its
        // own line directly beneath it, a step down and heavier-set so the
        // pair still reads as one greeting. Both wrap (up to two lines)
        // instead of scaling down.
        Text(
          greeting,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypo.display(
            fontSize: AppTextScale.greeting,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
            height: 1.1,
            letterSpacing: -1.0,
          ),
        ),
        // With no name yet the salutation stands alone — no empty line, no
        // dangling gap under it.
        if (resolved.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(
            resolved,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypo.display(
              fontSize: AppTextScale.greetingName,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
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

/// Header controls (v5 §2A, "Circular header icon buttons"): flat 40pt
/// circles inside a 48pt hit area — `surface` (white) in light, `surfaceRaised` in dark — with a
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
        child: SizedBox(
          height: AppSpace.minTarget,
          width: AppSpace.minTarget,
          child: Center(
            child: Container(
          height: 40,
          width: 40,
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
        // The identity-accent chip (lavender/plum), never brand green; 40pt
        // visual in a 48pt hit area.
        child: SizedBox(
          height: AppSpace.minTarget,
          width: AppSpace.minTarget,
          child: Center(
            child: AyreAvatar(initials: initialsFor(name), size: 40),
          ),
        ),
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

/// The three instruments as compact cards in one horizontal row, always in the
/// backend's order (`IndexId.values`: Nifty 50, Bank Nifty, Sensex). The whole
/// card is the tap target into Index Detail.
///
/// Where all three fit at a legible width (tablet / desktop) they share the
/// row equally and nothing scrolls. On a phone the row scrolls horizontally,
/// bleeds to the screen edges and lets the next card peek in so it reads as
/// scrollable.
class _IndexBoard extends StatelessWidget {
  const _IndexBoard({
    required this.result,
    required this.onOpen,
    required this.onRetry,
  });

  final DataResult<List<Quote>>? result;
  final ValueChanged<Quote> onOpen;
  final Future<void> Function() onRetry;

  /// Room above and below the cards so their shadows aren't clipped by the
  /// horizontal list's viewport.
  static const double _shadowRoom = 8;

  /// How many cards a phone shows at once (the last one peeks).
  static const double _visibleCards = 2.35;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    if (result == null) {
      return _row(
        context,
        count: 3,
        itemBuilder: (_, _) => const AyreCompactIndexCardSkeleton(),
      );
    }

    if (result.isFailed) {
      return StatePanel.failed(
        headline: 'Index feed unavailable',
        message: "The levels below couldn't be fetched for this session.",
        onRetry: onRetry,
      );
    }

    if (result.isEmpty) {
      return const StatePanel.empty(
        headline: 'No index data',
        message: 'The feed returned no instruments for this session.',
      );
    }

    final quotes = result.value!;
    return _row(
      context,
      count: quotes.length,
      itemBuilder: (context, i) => AyreCompactIndexCard(
        quote: quotes[i],
        indexId: _indexIdFor(quotes[i]),
        stale: result.stale,
        onTap: () => onOpen(quotes[i]),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required int count,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    const gap = AppSpace.cardGap;
    const pad = AppSpace.pageHorizontal;
    final height = AyreCompactIndexMetrics.heightFor(context);

    // Large text: reflow into a vertical list of content-height, full-width
    // cards rather than shrinking or capping the text (D-9).
    if (AyreCompactIndexMetrics.stacksFor(context)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: _shadowRoom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              Entrance(index: i + 1, child: itemBuilder(context, i)),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final fitsAll =
            available >= 3 * AyreCompactIndexMetrics.minWidth + 2 * gap;

        Widget item(int i, double width) => SizedBox(
          width: width,
          height: height,
          child: Entrance(index: i + 1, child: itemBuilder(context, i)),
        );

        // Wide enough: three equal cells, left-aligned so a missing index
        // leaves a gap at the end rather than stretching the others.
        if (fitsAll) {
          final width = (available - 2 * gap) / 3;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: _shadowRoom),
            child: Row(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  item(i, width),
                ],
              ],
            ),
          );
        }

        final width = ((available - 2 * gap) / _visibleCards).clamp(
          AyreCompactIndexMetrics.minWidth,
          double.infinity,
        );
        final list = ScrollConfiguration(
          // Mouse and trackpad can drag on desktop, where it isn't default.
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              ...ScrollConfiguration.of(context).dragDevices,
              if (AppBreakpoints.hasPointer(context)) ...{
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            },
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: pad,
              vertical: _shadowRoom,
            ),
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (context, i) => item(i, width),
          ),
        );

        // Bleed into the page's side padding so cards scroll under the screen
        // edge instead of being cut off 20pt in. Only reached on narrow
        // screens, where the page padding *is* the screen edge.
        return SizedBox(
          height: height + 2 * _shadowRoom,
          child: OverflowBox(
            minWidth: available + 2 * pad,
            maxWidth: available + 2 * pad,
            alignment: Alignment.center,
            child: list,
          ),
        );
      },
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
  static const Color labelLight = Color(0xFF3D5045);
  static const Color labelDark = Color(0xFFD0DCD3);
}

/// The top-of-page Market Sentiment card (§2.1): a small icon + label and the
/// bucketed reading set large and bold with a directional glyph.
///
/// **Everything on it is real.** The bucket comes from the `/api/sentiment`
/// 0–100 score alone. The card no longer carries a one-line description
/// ("X of Y stocks advancing") — status only.
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

  /// The full Nifty-500 breadth reading. No longer consulted by this card
  /// now that its description line is gone — kept as a constructor
  /// parameter (unused here) because `HomeTab._fullBreadth` still fetches it
  /// each load and nothing else in the app currently reads `FullBreadth`;
  /// removing the fetch itself is outside this phase's scope (see
  /// `_HomeTabState._fullBreadth`'s doc comment).
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
      _Mood.bullish => ('Bullish', t.positiveText, AyreGlyph.trendUp),
      _Mood.neutral => ('Neutral', t.neutralText, null),
      _Mood.bearish => ('Bearish', t.negativeText, AyreGlyph.trendDown),
    };
    final labelColor = dark
        ? _SentimentCardColors.labelDark
        : _SentimentCardColors.labelLight;

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
                label: 'Market sentiment: $word, score ${sentiment.score} out '
                    'of 100.',
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
                            'Sentiment',
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
                          child: Text(
                            word,
                            style: AppTypo.pageTitle(t, color: tone),
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
                    // The score is the card's one supporting figure.
                    Row(
                      children: [
                        Figure.static(
                          '${sentiment.score}',
                          fontSize: AppTextScale.body,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                        Text(
                          ' out of 100',
                          style: AppTypo.meta(t, color: labelColor),
                        ),
                      ],
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

}

/// Mirrors the real card's blocks — label, bucket word, score — so the
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
          SkeletonBlock(width: 96, height: 14),
        ],
      ),
    );
  }
}
