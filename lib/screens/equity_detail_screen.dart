import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/state_views.dart';
import '../widgets/ticker_trace.dart';

/// Equity Detail — reached from Index Detail's constituents, from every Insights
/// movers row, and from a Signals card.
///
/// This is a pushed screen with no natural pull-to-refresh at the point of
/// failure, so its failure state carries an explicit Retry button rather than a
/// "pull down" hint.
class EquityDetailScreen extends StatefulWidget {
  const EquityDetailScreen({
    super.key,
    required this.symbol,
    required this.marketData,
    this.seed,
  });

  final String symbol;
  final MarketDataService marketData;

  /// The row that was tapped, so the header is populated on the way in.
  final Quote? seed;

  @override
  State<EquityDetailScreen> createState() => _EquityDetailScreenState();
}

class _EquityDetailScreenState extends State<EquityDetailScreen> {
  DataResult<Quote>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await widget.marketData.getEquity(widget.symbol);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    await _load();
    if (mounted) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final quote = _result?.value ?? widget.seed;
    // Only a hard failure with nothing to show at all takes over the screen.
    final failedOutright = !_loading && _result?.isReady != true && quote == null;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(widget.symbol.toUpperCase()),
      ),
      body: RefreshIndicator(
        color: t.citrineInk,
        backgroundColor: t.surface,
        onRefresh: _refresh,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            children: [
              if (_loading && quote == null)
                const AyreCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 180, height: 14),
                      SizedBox(height: AppSpacing.md),
                      SkeletonBlock(width: 150, height: 32),
                      SizedBox(height: AppSpacing.lg),
                      SkeletonBlock(height: 80, radius: AppRadius.panel),
                    ],
                  ),
                )
              else if (failedOutright)
                StatePanel.failed(
                  headline: "This company's data didn't come through",
                  message: 'Try again in a moment.',
                  onRetry: _load,
                )
              else if (quote != null) ...[
                _EquityHeader(quote: quote, stale: _result?.stale ?? false),
                const SizedBox(height: AppSpacing.xl),
                const SectionLabel(label: 'Key stats'),
                _KeyStats(quote: quote),
                if (_result?.isReady != true && !_loading) ...[
                  const SizedBox(height: AppSpacing.md),
                  // Partial state: the tapped row's values are still on screen,
                  // and this says plainly that the refresh didn't land.
                  StatePanel.failed(
                    headline: "Couldn't refresh this company",
                    message: 'Showing the values from the list you came from.',
                    compact: true,
                    onRetry: _load,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EquityHeader extends StatelessWidget {
  const _EquityHeader({required this.quote, required this.stale});

  final Quote quote;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyreCard(
      accentEdge: true,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.name,
                        style: AppTypo.cardTitle(t),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(quote.symbol.toUpperCase(), style: AppTypo.label(t)),
                    ],
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
            InkPanel(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Figure(
                      formatPrice(quote.lastPrice),
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: t.onInkPanel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Figure(
                          formatDelta(quote.change, percent: false),
                          fontSize: 13,
                          color: t.onInkPanel.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        DeltaFigure(change: quote.percentChange, fontSize: 14),
                      ],
                    ),
                  ),
                  if (quote.trace.length >= 2) ...[
                    const SizedBox(height: AppSpacing.md),
                    TickerTrace(
                      points: normaliseTrace(quote.trace),
                      height: 64,
                      showGrid: true,
                      color: t.onInkPanel.withValues(alpha: 0.8),
                    ),
                  ],
                ],
              ),
            ),
            if (stale) ...[
              const SizedBox(height: AppSpacing.sm),
              const StaleNotice(),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyStats extends StatelessWidget {
  const _KeyStats({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final range = (quote.dayLow != null && quote.dayHigh != null)
        ? '${formatPrice(quote.dayLow)} – ${formatPrice(quote.dayHigh)}'
        : null;

    final entries = <(String, String)>[
      if (range != null) ('Day range', range),
      if (quote.previousClose != null)
        ('Prev close', formatPrice(quote.previousClose)),
      if (quote.volume != null) ('Volume', formatVolume(quote.volume)),
      ('Change', formatDelta(quote.change, percent: false)),
    ];

    if (entries.isEmpty) {
      return const StatePanel.empty(
        headline: 'No stats published',
        message: 'The feed returned a price but no supporting figures.',
        compact: true,
      );
    }

    return AyreCard(
      child: Wrap(
        spacing: AppSpacing.xxl,
        runSpacing: AppSpacing.lg,
        children: [
          for (final (label, value) in entries)
            SizedBox(
              // Two-up on a phone, more on wider windows, and long values wrap
              // to the next run instead of overflowing.
              width: 132,
              child: LabelledFigure(label: label, value: value, fontSize: 14),
            ),
        ],
      ),
    );
  }
}
