import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_logo.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import '../widgets/spring.dart';
import '../widgets/state_views.dart';
import '../widgets/ticker_trace.dart';
import 'home_shell.dart' show initialsFor;
import 'index_detail_screen.dart';
import 'notifications_screen.dart';

/// Home — the market gateway.
///
/// Greets, shows the three primary instruments as tappable cards, gives one
/// high-level scanner summary, and routes onward. The movers lists used to live
/// here and now belong to the Insights desk.
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
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
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
            const SizedBox(height: AppSpace.xl),
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
            const SizedBox(height: AppSpace.xl),
            Entrance(
              index: 2,
              child: const SectionLabel(label: 'Market breadth'),
            ),
            _ScannerSummary(result: _loading ? null : _breadth, onRetry: _load),
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
              // The only in-app brand placement: a small wordmark, sized to sit
              // beneath the live content rather than compete with it.
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
        const SizedBox(width: AppSpace.sm),
        _AccountControl(name: resolved, onTap: onOpenProfile),
      ],
    );
  }
}

/// Header controls are flat and hairline-bordered — no circular soft fills.
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
        borderRadius: AppRadius.control,
        child: Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: t.border),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AyreIcon(glyph, size: 18, color: t.textSecondary),
              if (badge)
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    height: 6,
                    width: 6,
                    decoration: BoxDecoration(
                      color: t.info,
                      shape: BoxShape.circle,
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
        borderRadius: AppRadius.control,
        child: Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: t.border),
          ),
          child: Text(
            initialsFor(name),
            style: AppTypo.ui(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The three instruments, each a physical-card-like block with an embedded ink
/// readout. The whole card is the tap target into Index Detail.
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
            if (i > 0) const SizedBox(height: AppSpace.md),
            const _IndexCardSkeleton(),
          ],
        ],
      );
    }

    if (result!.isFailed) {
      return StatePanel.failed(
        headline: 'Index feed unavailable',
        message: 'Pull down to try again.',
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
            if (i > 0) const SizedBox(height: AppSpace.md),
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
            if (i > 0) const SizedBox(width: AppSpace.md),
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

    return AyreCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      accentEdge: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
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
            const SizedBox(height: AppSpace.sm),
            // The readout panel: the live figures sit on ink, so they read as
            // coming off a feed rather than being page content.
            InkPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Figure(
                      formatPrice(quote.lastPrice),
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: t.onInkPanel,
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
                              Figure(
                                formatDelta(quote.change, percent: false),
                                fontSize: 12,
                                color: t.onInkPanel.withValues(alpha: 0.75),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              DeltaFigure(
                                change: quote.percentChange,
                                fontSize: 13,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      // The clock is a non-flex child, so it would otherwise be
                      // measured against unbounded width and push the row over
                      // in a narrow multi-column card at a large text scale.
                      ShrinkTrailing(
                        child: Text(
                          _clock(quote.asOf),
                          style: AppTypo.valueSmall(
                            t,
                            color: t.onInkPanel.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (quote.trace.length >= 2) ...[
                    const SizedBox(height: AppSpace.sm),
                    TickerTrace(
                      points: normaliseTrace(quote.trace),
                      height: 34,
                      color: t.onInkPanel.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'VIEW CONSTITUENTS',
                    style: AppTypo.label(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                AyreIcon(AyreGlyph.forward, size: 12, color: t.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _clock(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}

class _IndexCardSkeleton extends StatelessWidget {
  const _IndexCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      padding: EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 96, height: 13),
          SizedBox(height: AppSpace.md),
          SkeletonBlock(height: 30, radius: AppRadius.panel),
          SizedBox(height: AppSpace.sm),
          SkeletonBlock(width: 140, height: 11),
        ],
      ),
    );
  }
}

/// Market breadth — the Home page's primary overview figures.
///
/// Advances and Declines lead: they are the two numbers that actually say what
/// the market did today, whereas a single composite sentiment score says it at
/// one remove. The score is kept as a supporting figure rather than dropped, so
/// nothing is lost — Insights remains its fuller home.
///
/// A ring shows the advance/decline split, which is the one place a proportion
/// genuinely reads better as a shape than as two numbers side by side.
class _ScannerSummary extends StatelessWidget {
  const _ScannerSummary({required this.result, required this.onRetry});

  final DataResult<Sentiment>? result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (result == null) {
      return const AyreCard(
        child: Row(
          children: [
            SkeletonBlock(width: 72, height: 72, radius: AppRadius.circle),
            SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 110, height: 26),
                  SizedBox(height: AppSpace.sm),
                  SkeletonBlock(width: 150, height: 11),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (result!.isFailed) {
      return StatePanel.failed(
        headline: "Market breadth didn't load",
        message: 'Pull down to try again.',
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
    // than rendering zeroes as if they were real.
    if (advances == null && declines == null) {
      return StatePanel.empty(
        headline: 'Breadth counts unavailable',
        message:
            'The feed returned a sentiment reading but no advance or '
            'decline counts. Score: ${sentiment.score}.',
        compact: true,
      );
    }

    final up = advances ?? 0;
    final down = declines ?? 0;
    final total = up + down + (sentiment.unchanged ?? 0);

    return AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BreadthRing(advances: up, declines: down, total: total),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BreadthFigure(
                      label: 'Advances',
                      value: advances,
                      tone: t.gain,
                      up: true,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    _BreadthFigure(
                      label: 'Declines',
                      value: declines,
                      tone: t.loss,
                      up: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          const HairlineDivider(),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: LabelledFigure(
                  label: 'Unchanged',
                  value: sentiment.unchanged == null
                      ? '—'
                      : '${sentiment.unchanged}',
                  fontSize: AppTextScale.body,
                ),
              ),
              // The composite score, demoted to a supporting figure.
              Expanded(
                child: LabelledFigure(
                  label: 'Sentiment',
                  value: '${sentiment.score}',
                  fontSize: AppTextScale.body,
                ),
              ),
            ],
          ),
          if (sentiment.note != null && sentiment.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(sentiment.note!, style: AppTypo.body(t)),
          ],
          if (result!.stale) ...[
            const SizedBox(height: AppSpace.sm),
            const StaleNotice(),
          ],
        ],
      ),
    );
  }
}

/// One oversized breadth figure with its direction carried by a caret and a
/// sign-free count — a count has no sign, so the glyph does that work alone.
class _BreadthFigure extends StatelessWidget {
  const _BreadthFigure({
    required this.label,
    required this.value,
    required this.tone,
    required this.up,
  });

  final String label;
  final int? value;
  final Color tone;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        DirectionGlyph(up: up, color: tone, size: 13),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypo.label(t),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Figure(
                  value == null ? '—' : '$value',
                  fontSize: AppTextScale.section,
                  fontWeight: FontWeight.w600,
                  color: tone,
                  semanticsLabel: '$label ${value ?? 'unavailable'}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The advance/decline split as a ring, with the traded count in the middle.
class _BreadthRing extends StatelessWidget {
  const _BreadthRing({
    required this.advances,
    required this.declines,
    required this.total,
  });

  final int advances;
  final int declines;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final denominator = total > 0 ? total : (advances + declines);
    final share = denominator > 0 ? advances / denominator : 0.0;

    return RepaintBoundary(
      child: SizedBox(
        height: 76,
        width: 76,
        child: SpringValue(
          value: share,
          animateOnMount: true,
          builder: (context, progress, _) => CustomPaint(
            painter: _RingPainter(
              advanceShare: progress.clamp(0.0, 1.0),
              gain: t.gain,
              loss: t.loss,
              track: t.surfaceAlt,
            ),
            child: Center(
              // The ring is a fixed 76pt, so its centre label scales down inside
              // it rather than growing past it at a large text size.
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Figure(
                        denominator == 0 ? '—' : '$denominator',
                        fontSize: AppTextScale.body,
                        fontWeight: FontWeight.w600,
                      ),
                      Text('TRADED', style: AppTypo.label(t, fontSize: 8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.advanceShare,
    required this.gain,
    required this.loss,
    required this.track,
  });

  final double advanceShare;
  final Color gain;
  final Color loss;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    const start = -1.5708;
    const full = 6.28319;

    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0, full, false, arc(track));
    // Declines fill the remainder, so the ring always reads as a whole.
    canvas.drawArc(
      rect,
      start + full * advanceShare,
      full * (1 - advanceShare),
      false,
      arc(loss),
    );
    canvas.drawArc(rect, start, full * advanceShare, false, arc(gain));
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.advanceShare != advanceShare ||
      old.gain != gain ||
      old.loss != loss ||
      old.track != track;
}
