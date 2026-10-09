import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/equity_detail_screen.dart';
import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/notification_copy.dart';
import '../services/push_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_instrument_tile.dart';
import 'figure.dart';
import 'responsive.dart';
import 'state_views.dart';

/// Lets a host reload a [SignalsSection] (pull-to-refresh, retry) without
/// owning its data. Attached by the section's state; every call is a no-op
/// while nothing is attached (before mount, after dispose).
class SignalsSectionController {
  _SignalsSectionState? _state;

  /// Reloads the signals. [silent] suppresses the section's own haptic, for a
  /// host that already supplies its own feedback for the same gesture.
  Future<void> reload({bool silent = false}) async {
    await _state?._load(initial: silent);
  }
}

/// The signal board as a self-contained, scroll-agnostic section (Spec §13.2).
///
/// One view of every admin-curated stock pick the backend has published. All
/// picks sit together under a single "Signals" heading and are drawn with the
/// same card, so no stock outranks another: there is no featured pick and no
/// "also on watch" tier, and there are deliberately no filters or per-card
/// Bullish/Bearish tags — an admin pick has no long/short direction of its own.
/// Order is exactly what `GET /api/signals` returns.
///
/// This widget **owns** the signals fetch, `keepingLastGood`, the
/// [SeenSignalsStore] diff and the [NotificationLog] write, so that logic runs
/// exactly once per load wherever the section is mounted. It draws a plain
/// Column — no scrolling, refresh indicator or page title; the host supplies
/// those.
class SignalsSection extends StatefulWidget {
  const SignalsSection({
    super.key,
    required this.marketData,
    this.active = true,
    this.controller,
    this.onOpenEquity,
    this.forceColumns,
  });

  final MarketDataService marketData;

  /// Whether the host is currently showing. Loading is deferred until first
  /// active so a shell that mounts every tab doesn't fire all their requests in
  /// the same short window.
  final bool active;

  final SignalsSectionController? controller;

  /// Overrides what a card tap does. Defaults to opening
  /// [EquityDetailScreen] through [terminalRoute].
  final ValueChanged<Signal>? onOpenEquity;

  /// Pins the card grid to this many columns regardless of screen width.
  /// Home passes 1: its content frame is a single reading column, so a
  /// multi-column grid there would only cramp the cards. The multi-column
  /// branch itself is kept for hosts that are wide enough.
  final int? forceColumns;

  @override
  State<SignalsSection> createState() => _SignalsSectionState();
}

class _SignalsSectionState extends State<SignalsSection> {
  DataResult<List<Signal>>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    if (widget.active) _load(initial: true);
    AppLifecycleService.instance.addListener(_onAppResumed);
    PushService.instance.refreshSignalsRequests.addListener(_onRefreshRequested);
  }

  /// An entry-reached push arrived or was tapped: reload once, right away.
  void _onRefreshRequested() {
    if (!mounted) return;
    _load(initial: true);
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
    if (widget.controller?._state == this) widget.controller!._state = null;
    AppLifecycleService.instance.removeListener(_onAppResumed);
    PushService.instance.refreshSignalsRequests
        .removeListener(_onRefreshRequested);
    super.dispose();
  }

  @override
  void didUpdateWidget(SignalsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller!._state = null;
      }
      widget.controller?._state = this;
    }
    if (!oldWidget.active && widget.active && _result == null) {
      _load(initial: true);
    }
  }

  Future<void> _load({bool initial = false}) async {
    final result = (await widget.marketData.getSignals()).keepingLastGood(
      _result,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
    if (!initial) HapticFeedback.mediumImpact();

    if (!result.isReady) return;
    final fresh = await SeenSignalsStore.diffAndRecord(
      result.value!.map((s) => s.symbol),
    );
    if (fresh.isEmpty) return;
    final single = fresh.length == 1
        ? NotificationCopy.newSignal(fresh.first)
        : null;
    await NotificationLog.instance.add(
      Notice(
        kind: NoticeKind.signal,
        title: single?.title ?? '${fresh.length} New Picks',
        body:
            single?.body ??
            '${fresh.take(4).join(', ')}'
                '${fresh.length > 4 ? ', and more' : ''}',
        at: DateTime.now(),
      ),
    );
  }

  void _openEquity(Signal signal) {
    final override = widget.onOpenEquity;
    if (override != null) {
      override(signal);
      return;
    }
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
    final columns = widget.forceColumns ?? AppBreakpoints.columns(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _board(columns),
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

    // The backend returns every published signal in one neutral order, so
    // Flutter shows them all the same way and doesn't re-rank anything.
    final signals = _result!.value!;

    return [
      const Entrance(
        index: 1,
        child: SectionLabel(
          label: 'Signals',
          subtitle: 'Picks worth watching.',
        ),
      ),
      Entrance(
        index: 2,
        child: _SignalList(
          columns: columns,
          signals: signals,
          onTap: _openEquity,
        ),
      ),
    ];
  }
}

/// Every published signal, one identical card each. Single column below
/// [AppBreakpoints.twoColumn]; a multi-column grid at or above it — the same
/// column-count pattern `learn_tab.dart` applies to its course list.
class _SignalList extends StatelessWidget {
  const _SignalList({
    required this.columns,
    required this.signals,
    required this.onTap,
  });

  final int columns;
  final List<Signal> signals;
  final ValueChanged<Signal> onTap;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < signals.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.cardGap),
            _SignalCard(signal: signals[i], onTap: () => onTap(signals[i])),
          ],
        ],
      );
    }

    // Cards carry variable content (rationale, levels), so rows size to their
    // tallest card instead of using a fixed aspect ratio.
    final rows = <Widget>[];
    for (var start = 0; start < signals.length; start += columns) {
      final end = (start + columns).clamp(0, signals.length);
      final slice = signals.sublist(start, end);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpace.cardGap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.cardGap),
                Expanded(
                  child: i < slice.length
                      ? _SignalCard(
                          signal: slice[i],
                          onTap: () => onTap(slice[i]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

// ─── Signal card ───────────────────────────────────────────────────────────

/// One published signal. Every signal uses this same card — no accent edge,
/// no "featured" label — so all picks carry equal visual importance.
class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.signal, required this.onTap});

  final Signal signal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasName = signal.name != null && signal.name!.isNotEmpty;

    // Phase 5: content-dense card — mark tappable without collapsing the
    // rationale/levels detail children carry (unlike TickerRow's terse
    // grouped-label treatment).
    //
    // No Bullish/Bearish badge here — an admin-curated pick has no
    // long/short direction of its own; that concept lives only in the
    // separate market-sentiment system on Home.
    return Semantics(
      button: true,
      child: AyreCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // Top-aligned when there's a two-line symbol+name block, so it
            // starts level with the tile's top edge; centered for a bare
            // symbol, matching the Weekly Report card header's convention.
            crossAxisAlignment:
                hasName ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              AyreInstrumentTile(
                symbol: signal.symbol,
                size: 40,
                name: signal.name,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      signal.symbol,
                      style: AppTypo.featuredHeadline(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasName) ...[
                      const SizedBox(height: 2),
                      // No maxLines/ellipsis — the full company name must
                      // stay visible even when it runs to two lines.
                      Text(
                        signal.name!,
                        style: AppTypo.body(t),
                      ),
                    ],
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
          if (signal.entry != null ||
              signal.exitPrice != null ||
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
                  if (signal.exitPrice != null)
                    Expanded(
                      child: _Level(
                        label: 'Exit',
                        value: signal.exitPrice,
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
          ],
          if (signal.hasEntryReached) ...[
            const SizedBox(height: AppSpace.sm),
            _EntryReachedLine(signal: signal),
          ],
          if (!(signal.entry != null ||
                  signal.exitPrice != null ||
                  signal.stop != null) &&
              signal.addedOn != null) ...[
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

/// Mirrors the uniform card list, so nothing jumps when data lands.
class _SignalsSkeleton extends StatelessWidget {
  const _SignalsSkeleton();

  static const _card = AyreCard(
    padding: EdgeInsets.all(AppSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBlock(width: 160, height: 24),
        SizedBox(height: AppSpace.xs),
        SkeletonBlock(height: 12),
        SizedBox(height: AppSpace.xxs),
        SkeletonBlock(width: 220, height: 12),
        SizedBox(height: AppSpace.md),
        SkeletonBlock(height: 48, radius: AppRadius.inset),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card,
        SizedBox(height: AppSpace.cardGap),
        _card,
        SizedBox(height: AppSpace.cardGap),
        _card,
      ],
    );
  }
}

/// "Entry reached at 10:46 AM · ₹2,850", plus a distinct label when the price
/// had already moved past the level when it was noticed. Shown only for a pick
/// whose entry-reached fact the team published. Informational, not advice.
class _EntryReachedLine extends StatelessWidget {
  const _EntryReachedLine({required this.signal});

  final Signal signal;

  /// Clock time in IST, whatever the phone's own zone is.
  static String? _clock(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    final h12 = ist.hour % 12 == 0 ? 12 : ist.hour % 12;
    final mm = ist.minute.toString().padLeft(2, '0');
    return '$h12:$mm ${ist.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final time = _clock(signal.entryReachedAt!);
    final price = signal.entryReachedPrice;
    final parts = <String>[
      'Entry reached${time == null ? '' : ' at $time'}',
      if (price != null) formatPrice(price),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(parts.join(' · '), style: AppTypo.body(t)),
        if (signal.entryReachedExtended) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(
            'ALREADY PAST THE ENTRY LEVEL WHEN NOTICED',
            style: AppTypo.label(t).copyWith(color: t.negative),
          ),
        ],
      ],
    );
  }
}
