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

    final signals = result.value;
    if (signals == null) return;
    final fresh = await SeenSignalsStore.diffAndRecord(signals.map((s) => s.symbol));
    if (fresh.isEmpty) return;
    final newPick = fresh.length == 1
        ? signals.firstWhere((signal) => signal.symbol == fresh.first)
        : null;
    final name = newPick?.name?.trim();
    final single = newPick == null
        ? null
        : NotificationCopy.signal(
            stock: name == null || name.isEmpty ? newPick.symbol : name,
            potentialReturnPct: newPick.potentialReturnPct,
          );
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
    required this.claimDraw,
  });

  final Signal signal;
  final bool current;
  final bool Function() claimDraw;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = signal.name?.trim();
    final symbolStyle = AppTypo.cardTitle(t);
    final range = _RecommendationRange.fromSignal(signal);
    const logoSize = AppSpace.s34;
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
        AyreInstrumentTile(
          symbol: signal.symbol,
          name: signal.name,
          size: logoSize,
        ),
        const SizedBox(width: AppSpace.s8),
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
        padding: const EdgeInsets.all(AppSpace.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (!current) return identity;
                final tickerWidth =
                    logoSize +
                    AppSpace.s8 +
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
            if (prices.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              _Levels(prices: prices),
            ],
            if (signal.rationale.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.s13),
              const HairlineDivider(),
              const SizedBox(height: AppSpace.s13),
              Text(signal.rationale, style: AppTypo.body(t)),
            ],
            if (range != null) ...[
              const SizedBox(height: AppSpace.md),
              InkPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s13,
                  vertical: AppSpace.s13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpace.s8,
                      runSpacing: AppSpace.xxs,
                      children: [
                        Text('Risk / reward', style: AppTypo.hint(t)),
                        Text(
                          '1 : ${range.rewardLabel}',
                          style: AppTypo.value(t, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s13),
                    _RangeGauge(
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
                ),
              ),
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
    final exitPct = signal.potentialReturnPct;
    final ratio = reward / risk;
    if (exitPct == null || !ratio.isFinite) return null;
    return _RecommendationRange(
      entryPosition: risk / (exit - stop),
      stopPct: stopPct,
      exitPct: exitPct,
      rewardRatio: ratio,
    );
  }
}

/// A semicircle showing entry's position between stop and exit.
class _RangeGauge extends StatefulWidget {
  const _RangeGauge({
    super.key,
    required this.position,
    required this.claimDraw,
    required this.animate,
  });

  final double position;
  final bool Function() claimDraw;
  final bool animate;

  @override
  State<_RangeGauge> createState() => _RangeGaugeState();
}

class _RangeGaugeState extends State<_RangeGauge>
    with SingleTickerProviderStateMixin {
  static const _maxRadius = 102.0;
  static const _buyLabel = 'Strong buy';
  static const _sellLabel = 'Strong sell';

  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.rangeDraw + AppMotion.controlChange,
  );
  late final _labelOpacity = _controller.drive(
    CurveTween(curve: const Interval(0.42, 1, curve: AppMotion.ease)),
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
  void didUpdateWidget(_RangeGauge oldWidget) {
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
    final labelStyle = AppTypo.meta(t).copyWith(fontWeight: FontWeight.w700);
    final preferredLabelWidth = math.max(
      singleLineTextWidth(context, _buyLabel, labelStyle),
      singleLineTextWidth(context, _sellLabel, labelStyle),
    );
    final wrappedLabelWidth = singleLineTextWidth(
      context,
      'Strong',
      labelStyle,
    );

    return Semantics(
      label:
          '$_sellLabel on the left. $_buyLabel on the right. '
          'Entry is $percent percent of the way from stop to exit',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wrapLabels = preferredLabelWidth > constraints.maxWidth * 0.42;
          final labelWidth = wrapLabels
              ? math.min(
                  wrappedLabelWidth,
                  math.max(0.0, (constraints.maxWidth - AppSpace.s8) / 2),
                )
              : preferredLabelWidth;
          final radius = math.min(
            _maxRadius,
            (constraints.maxWidth - labelWidth) / 2,
          );

          Widget endpointLabel(String label, Color color) => SizedBox(
            width: labelWidth,
            child: Text(
              wrapLabels ? label.replaceFirst(' ', '\n') : label,
              style: labelStyle.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          );

          // The arc spans the distance between the two label centers.
          return Center(
            child: SizedBox(
              width: 2 * radius + labelWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: radius + _RangeGaugePainter.stroke,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RangeGaugePainter(
                          position: widget.position,
                          animation: _controller,
                          tokens: t,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  FadeTransition(
                    opacity: _labelOpacity,
                    child: Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        endpointLabel(_sellLabel, t.negativeText),
                        endpointLabel(_buyLabel, t.positiveText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RangeGaugePainter extends CustomPainter {
  _RangeGaugePainter({
    required this.position,
    required this.animation,
    required this.tokens,
  }) : super(repaint: animation);

  static const stroke = 10.0;
  static const _arcCurve = Interval(0, 0.78, curve: AppMotion.ease);
  static const _needleCurve = Interval(0.18, 1, curve: AppMotion.easeInOut);
  static const _needleFade = Interval(0.18, 0.48, curve: AppMotion.ease);

  final double position;
  final Animation<double> animation;
  final AppThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    const sweep = math.pi;
    final center = Offset(size.width / 2, size.height - stroke / 2);
    final radius = size.height - stroke;
    if (radius <= 0) return;

    final arc = Rect.fromCircle(center: center, radius: radius);
    final reveal = _arcCurve.transform(animation.value);
    final split = sweep * position;
    final gap = math.min(1.5 / radius, math.min(split, sweep - split) / 2);
    final cap = stroke / 2 / radius;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arc, math.pi, sweep, false, paint..color = tokens.hairline);

    void drawSegment(double from, double to, Color color) {
      final end = math.min(to, sweep * reveal);
      final span = end - from;
      if (span <= 0) return;
      final tint = RadialGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.25)],
        stops: const [0.58, 1],
        radius: 0.5,
      ).createShader(arc);
      canvas.drawArc(arc, math.pi + from, span, true, Paint()..shader = tint);

      final round = span > 2 * cap;
      final startInset = round && from > 0 ? cap : 0.0;
      final endInset = round && end < sweep ? cap : 0.0;
      canvas.drawArc(
        arc,
        math.pi + from + startInset,
        span - startInset - endInset,
        false,
        paint
          ..color = color.withValues(alpha: 0.82)
          ..strokeCap = round ? StrokeCap.round : StrokeCap.butt,
      );
    }

    drawSegment(0, split - gap, tokens.negative);
    drawSegment(split + gap, sweep, tokens.positive);

    final needleProgress = _needleCurve.transform(animation.value);
    final needleColor = tokens.textPrimary.withValues(
      alpha: _needleFade.transform(animation.value),
    );
    final angle = math.pi + split * needleProgress;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final length = math.min(20.0, radius * 0.25);
    final tip = center + direction * (length * 1.4);
    final base = tip - direction * length;
    final wing = Offset(-direction.dy, direction.dx) * (length * 0.25);
    final notch = base + direction * (length * 0.26);
    final pointer = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + wing.dx, base.dy + wing.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(base.dx - wing.dx, base.dy - wing.dy)
      ..close();
    canvas.drawPath(pointer, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(_RangeGaugePainter old) =>
      position != old.position ||
      animation != old.animation ||
      tokens != old.tokens;
}

class _Levels extends StatelessWidget {
  const _Levels({required this.prices});

  final List<_Level> prices;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final labelStyle = AppTypo.hint(t);
    final priceStyle = AppTypo.levelPrice(t).copyWith(fontSize: 17);
    final changeStyle = AppTypo.value(t, fontSize: 12);

    Widget values(_Level level, CrossAxisAlignment alignment) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(level.price, style: priceStyle),
        if (level.delta case final delta?) ...[
          const SizedBox(height: 2),
          Text(delta, style: changeStyle.copyWith(color: level.tone)),
        ],
      ],
    );

    Widget column(_Level level, CrossAxisAlignment alignment) => Column(
      crossAxisAlignment: alignment,
      children: [
        Text(level.label, style: labelStyle),
        const SizedBox(height: AppSpace.xxs),
        values(level, alignment),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.s8;
        final columnWidth =
            (constraints.maxWidth - gap * (prices.length - 1)) / prices.length;
        var widestLabel = 0.0;
        var widestValue = 0.0;
        for (final level in prices) {
          widestLabel = math.max(
            widestLabel,
            singleLineTextWidth(context, level.label, labelStyle),
          );
          widestValue = math.max(
            widestValue,
            singleLineTextWidth(context, level.price, priceStyle),
          );
          final delta = level.delta;
          if (delta != null) {
            widestValue = math.max(
              widestValue,
              singleLineTextWidth(context, delta, changeStyle),
            );
          }
        }

        if (math.max(widestLabel, widestValue) > columnWidth) {
          final fitsInRows =
              widestLabel + gap + widestValue <= constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < prices.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.s8),
                if (fitsInRows)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Text(prices[i].label, style: labelStyle)),
                      const SizedBox(width: gap),
                      values(prices[i], CrossAxisAlignment.end),
                    ],
                  )
                else
                  column(prices[i], CrossAxisAlignment.start),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < prices.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(
                child: column(prices[i], switch (i) {
                  0 => CrossAxisAlignment.start,
                  _ when i == prices.length - 1 => CrossAxisAlignment.end,
                  _ => CrossAxisAlignment.center,
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Level {
  const _Level(this.label, this.value, {this.change, this.tone});

  final String label;
  final num value;
  final double? change;
  final Color? tone;

  String get price => '₹${formatPrice(value)}';
  String? get delta => change == null ? null : formatDelta(change!);
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
