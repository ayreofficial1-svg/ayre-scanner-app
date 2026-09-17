import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show AppThemeController;
import '../services/api_service.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_logo.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';
import '../widgets/ticker_trace.dart';
import 'home_shell.dart' show initialsFor;
import 'index_detail_screen.dart';
import 'notifications_screen.dart';

/// Home — the market gateway (Spec §13.1).
///
/// Rebuilt in Phase 5 against §13.1's own list: greeting header with a theme
/// toggle, the index strip, a breadth donut, a sentiment gauge, and a footer
/// line. The screen's *information* is unchanged from v3 — the same board, the
/// same breadth reading — but almost every component rendering it is new, and
/// three v3 devices are gone for good:
///
/// * **The ink readout panel.** v3 sat each index's live figures on a dark
///   "terminal feed" plate. v4 has no such concept (`inkPanel`/`onInkPanel`
///   were retired in Phase 0); the figures sit on the card, and what marks
///   them as live is the LIVE chip and the trace, not a plate behind them.
/// * **The bespoke breadth ring.** `_BreadthRing`/`_RingPainter` were a
///   private, one-screen donut written before there was a shared one. Phase 3
///   built `BreadthDonut` to §12.2; this screen now uses it and the private
///   pair is deleted rather than kept as a near-duplicate.
/// * **The inlined direction rendering.** `_BreadthFigure` did its own
///   caret-plus-tinted-count layout, which is exactly what §20.7 says must be
///   one reused component. Advances/declines now read through the donut's own
///   labelled legend, and `DirectionBadge` carries direction wherever a badge
///   is what's wanted.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.marketData,
    this.onAccountResolved,
    this.onOpenProfile,
  });

  final MarketDataService marketData;
  final ValueChanged<String>? onAccountResolved;
  final VoidCallback? onOpenProfile;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DataResult<List<Quote>>? _board;
  DataResult<Sentiment>? _breadth;
  String _accountName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    final session = await ApiService.getSession();
    final board = await widget.marketData.getIndexBoard();
    final breadth = await widget.marketData.getSentiment(monthly: false);
    if (!mounted) return;

    final name =
        session?['display_name']?.toString() ??
        session?['username']?.toString() ??
        '';

    setState(() {
      _accountName = name;
      _board = board;
      _breadth = breadth;
      _loading = false;
    });
    widget.onAccountResolved?.call(name);

    if (board.stale) {
      NotificationLog.instance.add(
        Notice(
          kind: NoticeKind.staleData,
          title: 'Index feed is behind',
          body:
              'Levels are older than their usual update interval. '
              'Last known values are still shown.',
          at: DateTime.now(),
        ),
      );
    }

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
            SafeArea(
              bottom: false,
              child: Entrance(
                child: _Header(
                  name: displayName,
                  onOpenProfile: widget.onOpenProfile,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sectionGap),
            Entrance(
              index: 1,
              child: SectionLabel(
                label: 'Index board',
                trailing: _board?.isReady == true
                    ? FreshnessStamp(
                        asOf: _board!.value!
                            .map((q) => q.asOf)
                            .reduce((a, b) => a.isAfter(b) ? a : b),
                        stale: _board!.stale,
                      )
                    : null,
              ),
            ),
            _IndexBoard(
              result: _loading ? null : _board,
              onOpen: _openIndex,
              onRetry: _load,
            ),
            const SizedBox(height: AppSpace.sectionGap),
            Entrance(
              index: 2,
              child: const SectionLabel(label: 'Market breadth'),
            ),
            _BreadthCard(result: _loading ? null : _breadth, onRetry: _load),
            const SizedBox(height: AppSpace.sectionGap),
            const Entrance(index: 3, child: _FooterLine()),
          ],
        ),
      ),
    );
  }

  void _openIndex(Quote quote) {
    final index =
        IndexId.fromId(quote.symbol) ??
        IndexId.values.firstWhere(
          (i) => i.label == quote.name,
          orElse: () => IndexId.nifty50,
        );
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
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

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onOpenProfile});

  final String name;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final resolved = name.trim();

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
              const SizedBox(height: AppSpace.xxs),
              Text(
                resolved.isEmpty ? 'Hi there' : 'Hi, $resolved',
                style: AppTypo.pageTitle(t),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
/// Writes to the same `setThemeMode` the Settings segmented control does, so
/// the two can never disagree — this is the re-verification Phase 0 asked for
/// and it holds: there is one setter, on `AppThemeController`, and both call
/// it. No System option exists to fall through to (§13.6/§20.11).
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

/// Header controls: a rounded-square tile with a hairline edge (§7 — icon
/// tiles are rounded squares, never circles), sized to the 44pt floor rather
/// than the 40px this used to be.
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
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.iconTile,
        child: Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.iconTile),
            border: Border.all(color: t.hairline),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AyreIcon(glyph, size: 18, color: t.foregroundMuted),
              if (badge)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    height: 7,
                    width: 7,
                    decoration: BoxDecoration(
                      // v4 has no "info" accent (retired in Phase 0). An
                      // unread marker is the brand asking for attention, not a
                      // market signal, so it takes the accent — not `neutral`,
                      // which is reserved for delayed/offline states.
                      color: t.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.surface, width: 1.5),
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
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'Profile',
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.circle,
        child: Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surfaceRaised,
            // The one circle §7 allows alongside the toggle knob: this is an
            // avatar, not an icon tile.
            shape: BoxShape.circle,
            border: Border.all(color: t.hairline),
          ),
          child: Text(
            initialsFor(name),
            style: AppTypo.ui(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
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

    return AyreCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  quote.name,
                  style: AppTypo.cardTitle(t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              ShrinkTrailing(
                child: stale
                    ? const AyreChip(
                        label: 'Delayed',
                        tone: ChipTone.attention,
                      )
                    : const AyreChip(
                        label: 'Live',
                        tone: ChipTone.live,
                        pulse: true,
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.inCardGap),
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
              semanticsLabel:
                  '${quote.name} at ${formatPrice(quote.lastPrice)}',
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              Flexible(
                child: FittedBox(
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
              ),
              const SizedBox(width: AppSpace.sm),
              // The clock is a non-flex child, so it would otherwise be
              // measured against unbounded width and push the row over in a
              // narrow multi-column card at a large text scale.
              ShrinkTrailing(
                child: Text(
                  formatClock(quote.asOf),
                  style: AppTypo.valueSmall(t),
                ),
              ),
            ],
          ),
          if (quote.trace.length >= 2) ...[
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

/// The skeleton mirrors the real card's shape, block for block (§14.4).
class _IndexCardSkeleton extends StatelessWidget {
  const _IndexCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 96, height: 15),
          SizedBox(height: AppSpace.inCardGap),
          SkeletonBlock(width: 170, height: 34, radius: AppRadius.inset),
          SizedBox(height: AppSpace.xs),
          SkeletonBlock(width: 140, height: 12),
          SizedBox(height: AppSpace.inCardGap),
          SkeletonBlock(height: 36, radius: AppRadius.inset),
        ],
      ),
    );
  }
}

// ─── Breadth ───────────────────────────────────────────────────────────────

/// Market breadth (§13.1): the advance/decline split as a donut, with the
/// composite sentiment reading beside it as a gauge.
///
/// The two charts answer different questions and §13.1 asks for both, so they
/// sit side by side rather than one being demoted to a figure the way v3 did:
/// the donut says *how many* went each way, the gauge says *how the desk reads
/// it*. Stacked on a phone, paired once there's width for it.
class _BreadthCard extends StatelessWidget {
  const _BreadthCard({required this.result, required this.onRetry});

  final DataResult<Sentiment>? result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (result == null) return const _BreadthSkeleton();

    if (result!.isFailed) {
      return StatePanel.failed(
        headline: "Market breadth didn't load",
        message: 'The index levels above are unaffected.',
        compact: true,
        onRetry: onRetry,
      );
    }

    if (result!.isEmpty) {
      return const StatePanel.empty(
        headline: 'No breadth reading yet',
        message: 'Advances and declines appear once the session is under way.',
        compact: true,
      );
    }

    final sentiment = result!.value!;
    final advances = sentiment.advances;
    final declines = sentiment.declines;

    // With no counts there is nothing to lead with, so say that plainly rather
    // than rendering zeroes as if they were real. The donut would otherwise
    // draw an empty ring around a confident-looking "0%".
    if (advances == null && declines == null) {
      return StatePanel.empty(
        headline: 'Breadth counts unavailable',
        message:
            'The feed returned a sentiment reading but no advance or '
            'decline counts. Score: ${sentiment.score}.',
        compact: true,
      );
    }

    final donut = BreadthDonut(
      advances: advances ?? 0,
      declines: declines ?? 0,
      unchanged: sentiment.unchanged ?? 0,
    );
    final gauge = SentimentGauge(
      score: sentiment.score,
      band: _band(sentiment.score),
      // §12.1 over §12.2 here, deliberately: a sentiment reading's subject is
      // direction, and tinting a bearish gauge with the brand accent would
      // make the one chart on this screen that has an opinion the one chart
      // that doesn't show it. Open decision #12 — this is the call this screen
      // makes; revisit if the Spec says otherwise.
      tone: switch (sentiment.score) {
        < 35 => t.negative,
        < 65 => t.neutral,
        _ => t.positive,
      },
    );

    return AyreCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Paired only where both charts fit at their fixed widths
              // (132 + 176 + gap) without either being squeezed. Below that
              // they stack — a donut compressed to 90px stops being readable
              // long before it stops fitting.
              final paired = constraints.maxWidth >= 132 + 176 + AppSpace.lg;
              if (!paired) {
                return Column(
                  children: [
                    Center(child: donut),
                    const SizedBox(height: AppSpace.lg),
                    const HairlineDivider(),
                    const SizedBox(height: AppSpace.lg),
                    Center(child: gauge),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Center(child: donut)),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(child: Center(child: gauge)),
                ],
              );
            },
          ),
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

  /// The band the score falls in. Named here rather than taken from the feed
  /// because `Sentiment` carries no band field — v3's `BreadthMeter` was
  /// handed one by `insights_tab.dart`, which derived it the same way.
  static String _band(int score) => switch (score) {
    < 20 => 'Bearish',
    < 40 => 'Cautious',
    < 60 => 'Neutral',
    < 80 => 'Constructive',
    _ => 'Bullish',
  };
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
          SizedBox(height: AppSpace.lg),
          SkeletonBlock(width: 176, height: 88, radius: AppRadius.inset),
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
          'Levels are indicative and may be delayed. '
          'Nothing here is investment advice.',
          textAlign: TextAlign.center,
          style: AppTypo.hint(t),
        ),
      ],
    );
  }
}