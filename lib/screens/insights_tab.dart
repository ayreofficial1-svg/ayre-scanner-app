import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/breadth_meter.dart';
import '../widgets/figure.dart';
import '../widgets/state_views.dart';
import 'equity_detail_screen.dart';

/// Insights — the market intelligence desk.
///
/// Sentiment, breadth and all three mover lists live here as one continuous feed:
/// shared row height, shared hairlines, shared label typography. It replaces the
/// old "Climate" tab in name and in concept.
///
/// Each section owns its own state. A failed movers list never takes the
/// sentiment reading down with it, and vice versa.
class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key, required this.marketData});

  final MarketDataService marketData;

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  DataResult<Sentiment>? _sentiment;
  DataResult<List<Quote>>? _gainers;
  DataResult<List<Quote>>? _losers;
  DataResult<List<Quote>>? _mostActive;
  DataResult<List<InsightNote>>? _notes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    // Fired together so one slow section doesn't hold up the rest of the desk.
    final results = await Future.wait([
      widget.marketData.getSentiment(monthly: false),
      widget.marketData.getTopGainers(),
      widget.marketData.getTopLosers(),
      widget.marketData.getMostActive(),
      widget.marketData.getInsightNotes(),
    ]);
    if (!mounted) return;
    setState(() {
      _sentiment = results[0] as DataResult<Sentiment>;
      _gainers = results[1] as DataResult<List<Quote>>;
      _losers = results[2] as DataResult<List<Quote>>;
      _mostActive = results[3] as DataResult<List<Quote>>;
      _notes = results[4] as DataResult<List<InsightNote>>;
      _loading = false;
    });
    if (!initial) HapticFeedback.mediumImpact();
  }

  Future<void> _reloadSentiment() async {
    final result = await widget.marketData.getSentiment(monthly: false);
    if (!mounted) return;
    setState(() => _sentiment = result);
  }

  void _openEquity(Quote quote) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EquityDetailScreen(
          symbol: quote.symbol,
          marketData: widget.marketData,
          seed: quote,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Insights', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      "Breadth, sentiment, and the day's movers, in one feed.",
                      style: AppTypo.body(t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // ── Section 1: sentiment / breadth ──────────────────────────────
            // The weekly/monthly toggle that used to sit here is gone: the
            // backend stores a single sentiment value and accepts no window
            // parameter, so both options returned identical data. Reinstate it
            // when /api/sentiment genuinely supports a window.
            const Entrance(
              index: 1,
              child: SectionLabel(label: 'Market sentiment'),
            ),
            _SentimentSection(
              result: _loading ? null : _sentiment,
              onRetry: _reloadSentiment,
            ),

            // ── Sections 2–4: the movers lists ──────────────────────────────
            const SizedBox(height: AppSpace.xl),
            _MoversSection(
              label: 'Top gainers',
              result: _loading ? null : _gainers,
              onOpen: _openEquity,
              emptyMessage:
                  'No advancing equities reported for this session yet.',
              failedMessage: "Top Gainers didn't load.",
            ),
            const SizedBox(height: AppSpace.xl),
            _MoversSection(
              label: 'Top losers',
              result: _loading ? null : _losers,
              onOpen: _openEquity,
              emptyMessage:
                  'No declining equities reported for this session yet.',
              failedMessage: "Top Losers didn't load.",
            ),
            const SizedBox(height: AppSpace.xl),
            _MoversSection(
              label: 'Most active',
              result: _loading ? null : _mostActive,
              onOpen: _openEquity,
              byVolume: true,
              emptyMessage: 'No traded volume reported for this session yet.',
              failedMessage: "Most Active didn't load.",
            ),

            // ── Written notes, when the desk publishes them ─────────────────
            if (!_loading && _notes?.isReady == true) ...[
              const SizedBox(height: AppSpace.xl),
              const SectionLabel(label: 'Desk notes'),
              for (final note in _notes!.value!) ...[
                _NoteCard(note: note),
                const SizedBox(height: AppSpace.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SentimentSection extends StatelessWidget {
  const _SentimentSection({required this.result, required this.onRetry});

  final DataResult<Sentiment>? result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (result == null) {
      return const AyreCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 110, height: 34),
            SizedBox(height: AppSpace.md),
            SkeletonBlock(height: 10, radius: AppRadius.chip),
            SizedBox(height: AppSpace.md),
            SkeletonBlock(width: 180, height: 10),
          ],
        ),
      );
    }

    if (result!.isFailed) {
      return StatePanel.failed(
        headline: 'Sentiment reading unavailable',
        message: 'Pull down to retry.',
        compact: true,
        onRetry: onRetry,
      );
    }

    if (result!.isEmpty) {
      return const StatePanel.empty(
        headline: 'No sentiment reading',
        message: 'The desk has not published a reading for this window yet.',
        compact: true,
      );
    }

    final sentiment = result!.value!;
    final tone = switch (sentiment.score) {
      < 35 => t.loss,
      < 65 => t.textPrimary,
      _ => t.gain,
    };

    return AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadthMeter(
            value: sentiment.score,
            band: sentiment.band,
            tone: tone,
          ),
          if (sentiment.advances != null || sentiment.declines != null) ...[
            const SizedBox(height: AppSpace.md),
            const HairlineDivider(),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: LabelledFigure(
                    label: 'Advances',
                    value: sentiment.advances == null
                        ? '—'
                        : '${sentiment.advances}',
                    color: sentiment.advances == null ? null : t.gain,
                    fontSize: 15,
                  ),
                ),
                Expanded(
                  child: LabelledFigure(
                    label: 'Declines',
                    value: sentiment.declines == null
                        ? '—'
                        : '${sentiment.declines}',
                    color: sentiment.declines == null ? null : t.loss,
                    fontSize: 15,
                  ),
                ),
                Expanded(
                  child: LabelledFigure(
                    label: 'Unchanged',
                    value: sentiment.unchanged == null
                        ? '—'
                        : '${sentiment.unchanged}',
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
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

/// A ranked ticker list. All three movers sections use this, which is what makes
/// the desk read as one feed rather than three relocated cards.
class _MoversSection extends StatelessWidget {
  const _MoversSection({
    required this.label,
    required this.result,
    required this.onOpen,
    required this.emptyMessage,
    required this.failedMessage,
    this.byVolume = false,
  });

  final String label;
  final DataResult<List<Quote>>? result;
  final ValueChanged<Quote> onOpen;
  final String emptyMessage;
  final String failedMessage;
  final bool byVolume;

  /// Movers lists show a fixed few rows, not a long scroll.
  static const int maxRows = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: label,
          trailing: result?.isReady == true
              ? FreshnessStamp(
                  asOf: result!.value!
                      .map((q) => q.asOf)
                      .reduce((a, b) => a.isAfter(b) ? a : b),
                  stale: result!.stale,
                )
              : null,
        ),
        if (result == null)
          const AyreCard(
            padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Column(
              children: [
                SkeletonTickerRow(),
                SkeletonTickerRow(),
                SkeletonTickerRow(),
              ],
            ),
          )
        else if (result!.isFailed)
          StatePanel.failed(
            headline: failedMessage,
            message: 'Pull down to retry.',
            compact: true,
          )
        else if (result!.isEmpty)
          StatePanel.empty(
            headline: 'No movers',
            message: emptyMessage,
            compact: true,
          )
        else
          AyreCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, quote) in _rows.indexed) ...[
                  if (i > 0) const HairlineDivider(indent: AppSpace.md),
                  TickerRow(
                    rank: i + 1,
                    symbol: quote.symbol,
                    name: quote.name == quote.symbol ? null : quote.name,
                    price: quote.lastPrice,
                    changePercent: quote.percentChange,
                    changeAbsolute: byVolume ? null : quote.change,
                    volume: byVolume ? quote.volume : null,
                    onTap: () => onOpen(quote),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  List<Quote> get _rows {
    final rows = result!.value!;
    return rows.length <= maxRows ? rows : rows.sublist(0, maxRows);
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final InsightNote note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.category != null && note.category!.isNotEmpty)
                Expanded(
                  child: Text(
                    note.category!.toUpperCase(),
                    style: AppTypo.label(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              if (note.featured)
                const AyreChip(label: 'Featured', tone: ChipTone.attention),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(note.title, style: AppTypo.cardTitle(t)),
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(note.body, style: AppTypo.body(t)),
          ],
        ],
      ),
    );
  }
}
