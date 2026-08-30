import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
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
          body: 'Levels are older than their usual update interval. '
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
      color: t.citrineInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
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
            const SizedBox(height: AppSpacing.xl),
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
            const SizedBox(height: AppSpacing.xl),
            Entrance(index: 2, child: const SectionLabel(label: 'Scanner')),
            _ScannerSummary(result: _loading ? null : _breadth),
          ],
        ),
      ),
    );
  }

  void _openIndex(Quote quote) {
    final index = IndexId.fromId(quote.symbol) ??
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
              Text('WELCOME BACK', style: AppTypo.label(t)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                resolved.isEmpty ? 'Hi there' : 'Hi, $resolved',
                style: AppTypo.pageTitle(t),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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
        const SizedBox(width: AppSpacing.sm),
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
                      color: t.slateViolet,
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
            if (i > 0) const SizedBox(height: AppSpacing.md),
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
            if (i > 0) const SizedBox(height: AppSpacing.md),
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
            if (i > 0) const SizedBox(width: AppSpacing.md),
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
        padding: const EdgeInsets.all(AppSpacing.md),
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
                const SizedBox(width: AppSpacing.sm),
                ShrinkTrailing(
                  child: stale
                      ? const AyreChip(label: 'Delayed', tone: ChipTone.attention)
                      : const AyreChip(
                          label: 'Live',
                          tone: ChipTone.live,
                          pulse: true,
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
                  const SizedBox(height: AppSpacing.xs),
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
                              const SizedBox(width: AppSpacing.sm),
                              DeltaFigure(change: quote.percentChange, fontSize: 13),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.sm),
                    TickerTrace(
                      points: normaliseTrace(quote.trace),
                      height: 34,
                      color: t.onInkPanel.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(width: AppSpacing.xs),
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
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 96, height: 13),
          SizedBox(height: AppSpacing.md),
          SkeletonBlock(height: 30, radius: AppRadius.panel),
          SizedBox(height: AppSpacing.sm),
          SkeletonBlock(width: 140, height: 11),
        ],
      ),
    );
  }
}

/// The scanner summary, restyled as a readout row. The circular momentum ring
/// belonged to the previous identity and is retired.
class _ScannerSummary extends StatelessWidget {
  const _ScannerSummary({required this.result});

  final DataResult<Sentiment>? result;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (result == null) {
      return const AyreCard(
        child: Row(
          children: [
            Expanded(child: SkeletonBlock(width: 70, height: 26)),
            Expanded(child: SkeletonBlock(width: 70, height: 26)),
            Expanded(child: SkeletonBlock(width: 70, height: 26)),
          ],
        ),
      );
    }

    if (!result!.isReady) {
      return StatePanel.failed(
        headline: 'Scanner summary unavailable',
        message: 'Pull down to try again.',
        compact: true,
      );
    }

    final sentiment = result!.value!;
    final advances = sentiment.advances;
    final declines = sentiment.declines;

    return AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LabelledFigure(
                  label: 'Sentiment',
                  value: '${sentiment.score}',
                ),
              ),
              Container(width: 1, height: 30, color: t.hairline),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: LabelledFigure(
                    label: 'Advances',
                    value: advances == null ? '—' : '$advances',
                    color: advances == null ? null : t.jade,
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: t.hairline),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: LabelledFigure(
                    label: 'Declines',
                    value: declines == null ? '—' : '$declines',
                    color: declines == null ? null : t.garnet,
                  ),
                ),
              ),
            ],
          ),
          if (sentiment.note != null && sentiment.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const HairlineDivider(),
            const SizedBox(height: AppSpacing.md),
            Text(sentiment.note!, style: AppTypo.body(t)),
          ],
          if (result!.stale) ...[
            const SizedBox(height: AppSpacing.sm),
            const StaleNotice(),
          ],
        ],
      ),
    );
  }
}
