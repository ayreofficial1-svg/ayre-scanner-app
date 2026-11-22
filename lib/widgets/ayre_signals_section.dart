import 'package:flutter/material.dart';

import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/notification_copy.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'ayre_instrument_tile.dart';
import 'figure.dart';
import 'responsive.dart';
import 'state_views.dart';

/// Lets a host reload a [SignalsSection] (pull-to-refresh, retry) without
/// owning its data. Attached by the section's state; every call is a no-op
/// while nothing is attached (before mount, after dispose).
class SignalsSectionController {
  _SignalsSectionState? _state;

  /// Reloads the signals. [silent] is kept for source compatibility; the
  /// section no longer fires a completion haptic (A5).
  Future<void> reload({bool silent = false}) async {
    await _state?._load(initial: silent);
  }
}

/// The signal board as a self-contained, scroll-agnostic section (Spec §13.2).
///
/// One view of every analyst-published stock pick the backend has published.
/// Each card shows the analyst's entry, exit and stop alongside their
/// rationale. Any illustrated range is calculated from those levels. All
/// picks sit together under a single "Recommendations" heading and are drawn with the
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
    this.forceColumns,
  });

  final MarketDataService marketData;

  /// Whether the host is currently showing. Loading is deferred until first
  /// active so a shell that mounts every tab doesn't fire all their requests in
  /// the same short window.
  final bool active;

  final SignalsSectionController? controller;

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
  bool _lastLoadFailed = false;
  bool _hasShownRecommendations = false;
  bool _animateFirstList = false;
  final _drawnRanges = <(String, num?, num?, num?, String?)>{};

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
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
    if (widget.controller?._state == this) widget.controller!._state = null;
    AppLifecycleService.instance.removeListener(_onAppResumed);
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
    final incoming = await widget.marketData.getSignals();
    if (!mounted) return;
    final result = incoming.keepingLastGood(_result);
    setState(() {
      _result = result;
      _lastLoadFailed = incoming.isFailed;
      _loading = false;
      final hasRecommendations = result.value?.isNotEmpty == true;
      _animateFirstList =
          hasRecommendations &&
          !_hasShownRecommendations &&
          !result.stale &&
          !incoming.isFailed;
      _hasShownRecommendations = _hasShownRecommendations || hasRecommendations;
    });
    // A5: no completion haptic after a refresh.

    if (!result.isReady || result.value == null) return;
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

  @override
  Widget build(BuildContext context) {
    final columns = widget.forceColumns ?? AppBreakpoints.columns(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(
          label: 'Recommendations',
          subtitle: 'Stock ideas with entry, exit and stop levels.',
          padding: EdgeInsets.only(bottom: AppSpace.s21),
        ),
        ..._board(columns),
      ],
    );
  }

  List<Widget> _board(int columns) {
    if (_loading) {
      return [
        Semantics(
          label: 'Loading recommendations',
          liveRegion: true,
          child: const _SignalsSkeleton(),
        ),
      ];
    }

    if (_result!.isFailed) {
      return [
        StatePanel.failed(
          headline: "The scanner couldn't refresh",
          message: 'Try again to load the latest published recommendations.',
          onRetry: _load,
        ),
      ];
    }

    final signals = _result!.value ?? const <Signal>[];
    final current = !_result!.stale && !_lastLoadFailed;
    if (signals.isEmpty) {
      return const [
        StatePanel.empty(
          headline: 'No fresh setups right now',
          message: 'Published recommendations will appear here.',
        ),
      ];
    }

    // The backend returns every published signal in one neutral order, so
    // Flutter shows them all the same way and doesn't re-rank anything.
    return [
      if (!current) ...[
        Semantics(
          liveRegion: true,
          child: Text(
            'Showing saved recommendations. Pull down to refresh.',
            style: AppTypo.hint(context.tokens),
          ),
        ),
        const SizedBox(height: AppSpace.s13),
      ],
      _SignalList(
        key: const ValueKey('recommendation-list'),
        columns: columns,
        signals: signals,
        current: current,
        animate: _animateFirstList,
        claimDraw: (signal) => _drawnRanges.add((
          signal.symbol,
          signal.stop,
          signal.entry,
          signal.exitPrice,
          signal.addedOn,
        )),
      ),
      if (current) ...[const SizedBox(height: AppSpace.s26), const _CaughtUp()],
    ];
  }
}

/// Every published signal, one identical card each. Single column below
/// [AppBreakpoints.twoColumn]; a multi-column grid at or above it — the same
/// column-count pattern `learn_tab.dart` applies to its course list.
class _SignalList extends StatelessWidget {
  const _SignalList({
    super.key,
    required this.columns,
    required this.signals,
    required this.current,
    required this.animate,
    required this.claimDraw,
  });

  final int columns;
  final List<Signal> signals;
  final bool current;
  final bool animate;
  final bool Function(Signal) claimDraw;

  Widget _card(int index) {
    final signal = signals[index];
    return Entrance(
      index: index,
      animate: animate,
      child: _SignalCard(
        signal: signal,
        current: current,
        notch: index == 0,
        claimDraw: () => claimDraw(signal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < signals.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.cardGap),
            _card(i),
          ],
        ],
      );
    }

    // Cards carry variable content (rationale, levels), so rows size to their
    // tallest card instead of using a fixed aspect ratio.
    final rows = <Widget>[];
    for (var start = 0; start < signals.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpace.cardGap));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.cardGap),
              Expanded(
                child: start + i < signals.length
                    ? _card(start + i)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.signal,
    required this.current,
    required this.notch,
    required this.claimDraw,
  });

  final Signal signal;
  final bool current;
  final bool notch;
  final bool Function() claimDraw;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = signal.name?.trim();
    final range = _RecommendationRange.fromSignal(signal);
    final prices = <_Level>[
      if (signal.stop case final stop? when stop.isFinite)
        _Level('Stop', stop, change: range?.stopPct, tone: t.negativeText),
      if (signal.entry case final entry? when entry.isFinite)
        _Level('Entry', entry, flex: 3),
      if (signal.exitPrice case final exit? when exit.isFinite)
        _Level('Exit', exit, change: range?.exitPct, tone: t.positiveText),
    ];

    final identity = Row(
      children: [
        AyreInstrumentTile(symbol: signal.symbol, name: signal.name),
        const SizedBox(width: AppSpace.s13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(signal.symbol, style: AppTypo.cardTitle(t)),
              if (name != null && name.isNotEmpty)
                Text(name, style: AppTypo.hint(t)),
            ],
          ),
        ),
      ],
    );
    const active = AyreChip(label: 'Active', tone: ChipTone.success, dot: true);

    return MergeSemantics(
      child: AyreCard(
        notch: notch,
        featured: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (!current) return identity;
                final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
                if (constraints.maxWidth < 130 + 120 * scale) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      identity,
                      const SizedBox(height: AppSpace.s8),
                      active,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: AppSpace.s8),
                    active,
                  ],
                );
              },
            ),
            if (range != null) ...[
              const SizedBox(height: AppSpace.s26),
              _RangeTrack(
                key: ValueKey((
                  signal.symbol,
                  signal.stop,
                  signal.entry,
                  signal.exitPrice,
                  signal.addedOn,
                )),
                position: range.entryPosition,
                claimDraw: claimDraw,
                animate: current,
              ),
            ],
            if (prices.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s21),
              Semantics(
                label: range == null
                    ? null
                    : 'Analyst price levels and distances from entry',
                child: _Levels(prices: prices),
              ),
            ],
            if (range != null) ...[
              const SizedBox(height: AppSpace.s21),
              const HairlineDivider(),
              const SizedBox(height: AppSpace.s13),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: AppSpace.s13,
                  runSpacing: AppSpace.s8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Risk to reward', style: AppTypo.hint(t)),
                    Text(
                      '1 : ${range.rewardLabel}',
                      style: AppTypo.sectionHeading(t),
                    ),
                  ],
                ),
              ),
            ],
            if (signal.rationale.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.s21),
              Text(signal.rationale, style: AppTypo.body(t)),
            ],
            if (signal.addedOn case final date?
                when date.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.s13),
              Text('Added $date', style: AppTypo.meta(t)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Geometry and proportional distances for a positive, ordered long setup.
class _RecommendationRange {
  const _RecommendationRange({
    required this.entryPosition,
    required this.stopPct,
    required this.exitPct,
    required this.rewardRatio,
  });

  final double entryPosition;
  final double stopPct;
  final double exitPct;
  final double rewardRatio;

  String get rewardLabel {
    if (rewardRatio < 0.005) return '<0.01';
    final value = formatPrice(rewardRatio);
    return value.contains('.') && !value.contains('e')
        ? value.replaceFirst(RegExp(r'\.?0{1,2}$'), '')
        : value;
  }

  static _RecommendationRange? fromSignal(Signal signal) {
    final stop = signal.stop;
    final entry = signal.entry;
    final exit = signal.exitPrice;
    if (stop == null ||
        entry == null ||
        exit == null ||
        !stop.isFinite ||
        !entry.isFinite ||
        !exit.isFinite ||
        stop <= 0 ||
        stop >= entry ||
        entry >= exit) {
      return null;
    }

    final risk = (entry - stop).toDouble();
    final reward = (exit - entry).toDouble();
    final stopPct = -risk / entry * 100;
    final exitPct = reward / entry * 100;
    final ratio = reward / risk;
    if (!exitPct.isFinite || !ratio.isFinite) return null;
    return _RecommendationRange(
      entryPosition: risk / (exit - stop),
      stopPct: stopPct,
      exitPct: exitPct,
      rewardRatio: ratio,
    );
  }
}

class _RangeTrack extends StatefulWidget {
  const _RangeTrack({
    super.key,
    required this.position,
    required this.claimDraw,
    required this.animate,
  });

  final double position;
  final bool Function() claimDraw;
  final bool animate;

  @override
  State<_RangeTrack> createState() => _RangeTrackState();
}

class _RangeTrackState extends State<_RangeTrack>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.rangeDraw,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      final firstDraw = widget.claimDraw();
      if (firstDraw && widget.animate && !reduced) {
        _controller.forward();
        return;
      }
    }
    if (reduced || !widget.animate || !_controller.isAnimating) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(_RangeTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate && oldWidget.animate) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _RangePainter(
            position: widget.position,
            progress: AppMotion.ease.transform(_controller.value),
            loss: t.negative,
            gain: t.positive,
            entry: t.highlight,
          ),
          child: child,
        ),
        child: const SizedBox(width: double.infinity, height: 20),
      ),
    );
  }
}

class _RangePainter extends CustomPainter {
  const _RangePainter({
    required this.position,
    required this.progress,
    required this.loss,
    required this.gain,
    required this.entry,
  });

  final double position;
  final double progress;
  final Color loss;
  final Color gain;
  final Color entry;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 20 || progress <= 0) return;
    const start = 10.0;
    final end = size.width - start;
    final x = start + (end - start) * position;
    final center = size.height / 2;
    final revealed = size.width * progress;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, revealed, size.height));
    canvas.drawRect(
      Rect.fromLTRB(start, center - 3, x, center + 3),
      Paint()..color = loss.withValues(alpha: 0.35),
    );
    canvas.drawRect(
      Rect.fromLTRB(x, center - 3, end, center + 3),
      Paint()..color = gain.withValues(alpha: 0.4),
    );
    for (final (offset, color) in [(start, loss), (end, gain)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(offset, center), width: 4, height: 18),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(x - 4, 0)
        ..lineTo(x + 9, 0)
        ..lineTo(x + 4, size.height)
        ..lineTo(x - 9, size.height)
        ..close(),
      Paint()..color = entry,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RangePainter old) =>
      position != old.position ||
      progress != old.progress ||
      loss != old.loss ||
      gain != old.gain ||
      entry != old.entry;
}

class _Levels extends StatelessWidget {
  const _Levels({required this.prices});

  final List<_Level> prices;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpace.s8 * (prices.length - 1);
        final totalFlex = prices.fold(0, (sum, level) => sum + level.flex);
        final scaler = MediaQuery.textScalerOf(context);
        final fits = prices.every((level) {
          final painter = TextPainter(
            text: TextSpan(text: level.price, style: AppTypo.levelPrice(t)),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout();
          final available =
              (constraints.maxWidth - gap) * level.flex / totalFlex;
          final fits = available >= painter.width;
          painter.dispose();
          return fits;
        });
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < prices.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.s13),
                prices[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < prices.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.s8),
              Expanded(
                flex: prices[i].flex,
                child: _Level(
                  prices[i].label,
                  prices[i].value,
                  change: prices[i].change,
                  tone: prices[i].tone,
                  alignment: switch (i) {
                    1 when prices.length == 3 => CrossAxisAlignment.center,
                    2 => CrossAxisAlignment.end,
                    _ => CrossAxisAlignment.start,
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Level extends StatelessWidget {
  const _Level(
    this.label,
    this.value, {
    this.change,
    this.tone,
    this.flex = 2,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final num value;
  final double? change;
  final Color? tone;
  final int flex;
  final CrossAxisAlignment alignment;

  String get price => '₹${formatPrice(value)}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: AppTypo.hint(t)),
        const SizedBox(height: 3),
        Text(price, style: AppTypo.levelPrice(t)),
        if (change case final change?) ...[
          const SizedBox(height: 3),
          Text(
            formatDelta(change, percent: true),
            style: AppTypo.value(t, color: tone, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.positiveSoft,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 55,
                child: Center(
                  child: AyreIcon(
                    AyreGlyph.check,
                    size: 25,
                    color: t.positiveText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s13),
            Text('You’re all caught up', style: AppTypo.sectionHeading(t)),
            const SizedBox(height: 3),
            Text(
              'New ideas appear here as soon as they’re published.',
              style: AppTypo.hint(t),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
