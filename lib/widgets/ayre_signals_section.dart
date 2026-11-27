import 'dart:math' as math;

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
          padding: EdgeInsets.only(bottom: AppSpace.sm),
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

    final result = _result!;
    final signals = result.value ?? const <Signal>[];
    final current = !result.stale && !_lastLoadFailed;
    if (result.isFailed || (signals.isEmpty && !current)) {
      return [
        StatePanel.failed(
          headline: "The scanner couldn't refresh",
          message: 'Try again to load the latest published recommendations.',
          onRetry: _load,
        ),
      ];
    }

    if (signals.isEmpty) {
      return const [_CaughtUp()];
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
    final symbolStyle = AppTypo.cardTitle(t);
    final range = _RecommendationRange.fromSignal(signal);
    final prices = <_Level>[
      if (signal.stop case final stop? when stop.isFinite)
        _Level('Stop', stop, change: range?.stopPct, tone: t.negativeText),
      if (signal.entry case final entry? when entry.isFinite)
        _Level('Entry', entry),
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
              Text(signal.symbol, style: symbolStyle),
              if (name != null &&
                  name.isNotEmpty &&
                  name.toUpperCase() != signal.symbol.toUpperCase())
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
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (!current) return identity;
                final tickerWidth =
                    AyreInstrumentTile.defaultSize +
                    AppSpace.s13 +
                    singleLineTextWidth(context, signal.symbol, symbolStyle);
                final badgeWidth = active.singleLineWidth(context);
                if (constraints.maxWidth <
                    tickerWidth + AppSpace.s8 + badgeWidth) {
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
                    SizedBox(width: badgeWidth, child: active),
                  ],
                );
              },
            ),
            if (range != null) ...[
              const SizedBox(height: AppSpace.s13),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppShape.field,
                  border: Border.all(
                    color: Color.lerp(t.hairline, t.positive, 0.18)!,
                  ),
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      t.positiveSoft,
                      Color.lerp(t.surface, t.positiveSoft, 0.25)!,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s13),
                  child: _PriceSummary(
                    ring: _RangeRing(
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
                    levels: prices.reversed.toList(),
                    ratio: '1 : ${range.rewardLabel}',
                  ),
                ),
              ),
            ] else if (prices.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s13),
              _Levels(prices: prices),
            ],
            if (signal.rationale.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.s21),
              const HairlineDivider(),
              const SizedBox(height: AppSpace.s13),
              Text(signal.rationale, style: AppTypo.body(t)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.ring,
    required this.levels,
    required this.ratio,
  });

  final _RangeRing ring;
  final List<_Level> levels;
  final String ratio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = ring.diameterOf(context);
        final ladder = _LevelStack(levels: levels, ratio: ratio);
        final roomForRing =
            constraints.maxWidth -
            AppSpace.s13 -
            ladder.singleLineWidth(context);
        if (diameter <= roomForRing) {
          final ringWidth = math.max(
            diameter,
            math.min(roomForRing, math.min(196.0, constraints.maxWidth * 0.56)),
          );
          return Row(
            children: [
              SizedBox(width: ringWidth, child: ring),
              const SizedBox(width: AppSpace.s13),
              Expanded(child: ladder),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: ring),
            const SizedBox(height: AppSpace.s13),
            const HairlineDivider(),
            const SizedBox(height: AppSpace.s13),
            _LevelStack(levels: levels, ratio: ratio, inlineLabels: true),
          ],
        );
      },
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

/// A D-shaped gauge showing entry's position between the stop and exit.
class _RangeRing extends StatefulWidget {
  const _RangeRing({
    super.key,
    required this.position,
    required this.claimDraw,
    required this.animate,
  });

  final double position;
  final bool Function() claimDraw;
  final bool animate;

  static const _minDiameter = 142.0;
  static const _inset = 3.0;
  static const _labelPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const _buy = 'Strong buy';
  static const _sell = 'Strong sell';

  static double strokeFor(double diameter) => math.min(15.0, diameter * 0.16);

  static TextStyle _labelStyle(AppThemeTokens t, {Color? color}) =>
      AppTypo.meta(t, color: color).copyWith(fontWeight: FontWeight.w800);

  double diameterOf(BuildContext context) {
    final style = _labelStyle(context.tokens);
    final labelWidth = math.max(
      singleLineTextWidth(context, _buy, style),
      singleLineTextWidth(context, _sell, style),
    );
    return math.max(
      _minDiameter,
      labelWidth + _labelPadding.horizontal + AppSpace.s34,
    );
  }

  @override
  State<_RangeRing> createState() => _RangeRingState();
}

class _RangeRingState extends State<_RangeRing>
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
  void didUpdateWidget(_RangeRing oldWidget) {
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
    final percent = (widget.position * 100).round();
    final preferredDiameter = widget.diameterOf(context);

    return Semantics(
      image: true,
      excludeSemantics: true,
      label:
          'Strong buy at the red end. Strong sell at the green end. '
          'Entry is $percent percent of the way from stop to exit',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = preferredDiameter.clamp(
            constraints.minWidth,
            constraints.maxWidth,
          );
          const padding = _RangeRing._labelPadding;
          final endpointInset =
              _RangeRing._inset + _RangeRing.strokeFor(diameter) / 2;

          Size labelSize(String text) {
            final size = measureText(
              context,
              text,
              _RangeRing._labelStyle(t),
              maxWidth: math.max(0.0, diameter - padding.horizontal),
            );
            return Size(
              math.min(
                diameter,
                size.width.ceilToDouble() + padding.horizontal,
              ),
              size.height.ceilToDouble() + padding.vertical,
            );
          }

          final buySize = labelSize(_RangeRing._buy);
          final sellSize = labelSize(_RangeRing._sell);
          final top = math.max(0.0, buySize.height / 2 - endpointInset);
          final bottom = math.max(0.0, sellSize.height / 2 - endpointInset);

          Widget label(
            String text,
            Size size,
            Color ink,
            Color tint,
            double y,
          ) {
            return Positioned(
              left: (diameter / 2 - size.width + AppSpace.xs).clamp(
                0.0,
                diameter - size.width,
              ),
              top: y,
              width: size.width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(t.surface, tint, 0.58),
                  border: Border.all(color: ink.withValues(alpha: 0.20)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Padding(
                  padding: padding,
                  child: Text(
                    text,
                    style: _RangeRing._labelStyle(t, color: ink),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          return SizedBox(
            width: diameter,
            height: top + diameter + bottom,
            child: Stack(
              children: [
                Positioned(
                  top: top,
                  width: diameter,
                  height: diameter,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _RangeRingPainter(
                        position: widget.position,
                        animation: _controller,
                        loss: t.negative,
                        gain: t.positive,
                        track: t.surface,
                        needle: t.highlight,
                        ink: t.textPrimary,
                      ),
                    ),
                  ),
                ),
                label(
                  _RangeRing._buy,
                  buySize,
                  t.negativeText,
                  t.negativeSoft,
                  top + endpointInset - buySize.height / 2,
                ),
                label(
                  _RangeRing._sell,
                  sellSize,
                  t.positiveText,
                  t.positiveSoft,
                  top + diameter - endpointInset - sellSize.height / 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RangeRingPainter extends CustomPainter {
  _RangeRingPainter({
    required this.position,
    required this.animation,
    required this.loss,
    required this.gain,
    required this.track,
    required this.needle,
    required this.ink,
  }) : super(repaint: animation);

  static const double _start = -math.pi / 2;
  static const double _sweep = math.pi;

  final double position;
  final Animation<double> animation;
  final Color loss;
  final Color gain;
  final Color track;
  final Color needle;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = _RangeRing.strokeFor(size.shortestSide);
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2 - _RangeRing._inset;
    if (radius <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final cap = stroke / 2 / radius;
    final progress = AppMotion.ease.transform(animation.value);
    final reveal = _sweep * progress;
    final split = _sweep * position.clamp(0.0, 1.0);
    final gap = math.min(3 / radius, math.min(split, _sweep - split) / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final face = Path()
      ..arcTo(rect, _start, _sweep, true)
      ..close();
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          colors: [track.withValues(alpha: 0.28), track.withValues(alpha: 0.8)],
        ).createShader(Rect.fromLTWH(center.dx, rect.top, radius, rect.height)),
    );
    canvas.drawArc(rect, _start, _sweep, false, paint..color = track);

    void segment(double from, double to, Color color) {
      final lo = from + (from > 0 ? gap / 2 : 0);
      final hi = math.min(to - (to < _sweep ? gap / 2 : 0), reveal);
      final sweep = hi - lo;
      if (sweep <= 0) return;
      final round = sweep > 2 * cap;
      final trim = round ? cap : 0.0;
      canvas.drawArc(
        rect,
        _start + lo + trim,
        sweep - 2 * trim,
        false,
        paint
          ..color = color
          ..strokeCap = round ? StrokeCap.round : StrokeCap.butt,
      );
    }

    segment(0, split, loss);
    segment(split, _sweep, gain);

    final tickPaint = Paint()
      ..color = ink.withValues(alpha: 0.20)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;
    for (final fraction in const [0.25, 0.5, 0.75]) {
      final angle = _start + _sweep * fraction;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - stroke * 0.7),
        center + direction * (radius - stroke * 1.05),
        tickPaint,
      );
    }

    final angle = _start + split * progress;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final wing = Offset(-direction.dy, direction.dx) * (stroke * 0.21);
    final tip = center + direction * (radius * 0.63);
    final pointer = Path()
      ..moveTo((center + wing).dx, (center + wing).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo((center - wing).dx, (center - wing).dy)
      ..close();
    final fill = Paint()..color = needle.withValues(alpha: progress);
    canvas.drawPath(
      pointer.shift(const Offset(0, 1)),
      Paint()..color = ink.withValues(alpha: 0.18 * progress),
    );
    canvas.drawPath(pointer, fill);
    canvas.drawCircle(
      center,
      stroke * 0.36,
      Paint()..color = ink.withValues(alpha: progress),
    );
    canvas.drawCircle(center, stroke * 0.18, fill);
  }

  @override
  bool shouldRepaint(_RangeRingPainter old) =>
      position != old.position ||
      animation != old.animation ||
      loss != old.loss ||
      gain != old.gain ||
      track != old.track ||
      needle != old.needle ||
      ink != old.ink;
}

/// Right-aligned price ladder. Below the ring it has room for labels beside
/// their amounts.
class _LevelStack extends StatelessWidget {
  const _LevelStack({
    required this.levels,
    required this.ratio,
    this.inlineLabels = false,
  });

  final List<_Level> levels;
  final String ratio;
  final bool inlineLabels;

  static const _ratioLabel = 'Risk / reward';
  static const _ratioPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);

  static TextStyle _priceStyle(AppThemeTokens t, _Level level) =>
      AppTypo.levelPrice(
        t,
        color: (level.change ?? 0) > 0 ? t.positiveText : null,
      );

  static TextStyle _changeStyle(AppThemeTokens t, _Level level) =>
      AppTypo.value(t, color: level.tone, fontSize: 12);

  static TextStyle _ratioStyle(AppThemeTokens t) =>
      AppTypo.value(t, color: t.accentInk, fontSize: 17);

  double _rowWidth(double labelWidth, double valueWidth) => inlineLabels
      ? labelWidth + AppSpace.s13 + valueWidth
      : math.max(labelWidth, valueWidth);

  double singleLineWidth(BuildContext context) {
    final t = context.tokens;
    var width =
        _ratioPadding.horizontal +
        _rowWidth(
          singleLineTextWidth(context, _ratioLabel, AppTypo.meta(t)),
          singleLineTextWidth(context, ratio, _ratioStyle(t)),
        );
    for (final level in levels) {
      final labelWidth = singleLineTextWidth(
        context,
        level.label,
        AppTypo.meta(t),
      );
      final priceWidth = singleLineTextWidth(
        context,
        level.price,
        _priceStyle(t, level),
      );
      final change = level.change;
      final changeWidth = change == null
          ? 0.0
          : singleLineTextWidth(
              context,
              formatDelta(change),
              _changeStyle(t, level),
            );
      final valueWidth = math.max(priceWidth, changeWidth);
      width = math.max(width, _rowWidth(labelWidth, valueWidth));
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Analyst price levels and distances from entry',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inline =
              inlineLabels && singleLineWidth(context) <= constraints.maxWidth;

          Widget rowFor(_Level level) {
            final label = Text(
              level.label,
              style: AppTypo.meta(t),
              textAlign: inline ? TextAlign.start : TextAlign.end,
            );
            final value = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  level.price,
                  style: _priceStyle(t, level),
                  textAlign: TextAlign.end,
                ),
                if (level.change case final change?) ...[
                  const SizedBox(height: 2),
                  Text(
                    formatDelta(change),
                    style: _changeStyle(t, level),
                    textAlign: TextAlign.end,
                  ),
                ],
              ],
            );
            if (!inline) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [label, const SizedBox(height: 2), value],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: label),
                const SizedBox(width: AppSpace.s13),
                value,
              ],
            );
          }

          final ratioLabel = Text(
            _ratioLabel,
            style: AppTypo.meta(t),
            textAlign: inline ? TextAlign.start : TextAlign.end,
          );
          final ratioValue = Text(
            ratio,
            style: _ratioStyle(t),
            textAlign: TextAlign.end,
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < levels.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.s8),
                rowFor(levels[i]),
              ],
              const SizedBox(height: AppSpace.s13),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(t.surface, t.positiveSoft, 0.25),
                  border: Border.all(
                    color: Color.lerp(t.hairline, t.positive, 0.14)!,
                  ),
                  borderRadius: AppShape.field,
                ),
                child: Padding(
                  padding: _ratioPadding,
                  child: inline
                      ? Row(
                          children: [
                            Expanded(child: ratioLabel),
                            const SizedBox(width: AppSpace.s13),
                            ratioValue,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [ratioLabel, ratioValue],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Levels extends StatelessWidget {
  const _Levels({required this.prices});

  final List<_Level> prices;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.s8;
        final widths = [
          for (final level in prices) level.minimumWidth(context),
        ];
        final requiredWidth =
            widths.reduce((a, b) => a + b) + gap * (widths.length - 1);
        if (requiredWidth > constraints.maxWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < prices.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.s8),
                prices[i],
              ],
            ],
          );
        }

        final extra = (constraints.maxWidth - requiredWidth) / widths.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < prices.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: widths[i] + extra,
                child: _Level(
                  prices[i].label,
                  prices[i].value,
                  change: prices[i].change,
                  tone: prices[i].tone,
                  alignment: switch (i) {
                    0 => CrossAxisAlignment.start,
                    _ when i == prices.length - 1 => CrossAxisAlignment.end,
                    _ => CrossAxisAlignment.center,
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
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final num value;
  final double? change;
  final Color? tone;
  final CrossAxisAlignment alignment;

  String get price => '₹${formatPrice(value)}';

  double minimumWidth(BuildContext context) {
    final t = context.tokens;
    final labelWidth = singleLineTextWidth(context, label, AppTypo.hint(t));
    final priceWidth = singleLineTextWidth(
      context,
      price,
      AppTypo.levelPrice(t),
    );
    if (change case final change?) {
      final changeWidth = singleLineTextWidth(
        context,
        formatDelta(change),
        AppTypo.value(t, color: tone, fontSize: 12),
      );
      return math.max(math.max(labelWidth, priceWidth), changeWidth);
    }
    return math.max(labelWidth, priceWidth);
  }

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
            Text(
              'You’re all caught up',
              style: AppTypo.sectionHeading(t),
              textAlign: TextAlign.center,
            ),
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
