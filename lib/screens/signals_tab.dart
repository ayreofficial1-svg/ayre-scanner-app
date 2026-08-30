import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/state_views.dart';
import 'equity_detail_screen.dart';

/// Signals — the signal board.
///
/// Dense terminal rows rather than generously-spaced editorial cards: this is a
/// data-desk screen. Conviction reads as filled/unfilled signal ticks, never a
/// dial.
class SignalsTab extends StatefulWidget {
  const SignalsTab({super.key, required this.marketData});

  final MarketDataService marketData;

  @override
  State<SignalsTab> createState() => _SignalsTabState();
}

class _SignalsTabState extends State<SignalsTab> {
  DataResult<List<Signal>>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    final result = await widget.marketData.getSignals();
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
    await NotificationLog.instance.add(
      Notice(
        kind: NoticeKind.signal,
        title: fresh.length == 1
            ? 'New scanner pick: ${fresh.first}'
            : '${fresh.length} new scanner picks',
        body: '${fresh.take(4).join(', ')}'
            '${fresh.length > 4 ? ', and more' : ''}',
        at: DateTime.now(),
      ),
    );
  }

  void _openEquity(Signal signal) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EquityDetailScreen(
          symbol: signal.symbol,
          marketData: widget.marketData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIVE SCANNER', style: AppTypo.label(t)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Signal board', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Curated setups with live movement and compact rationale.',
                      style: AppTypo.body(t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_loading)
              const AyreCard(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    SkeletonTickerRow(),
                    SkeletonTickerRow(),
                    SkeletonTickerRow(),
                    SkeletonTickerRow(),
                  ],
                ),
              )
            else if (_result!.isFailed)
              StatePanel.failed(
                headline: "The scanner couldn't refresh",
                message: 'Pull down to sweep again.',
              )
            else if (_result!.isEmpty)
              const StatePanel.empty(
                headline: 'No fresh setups right now',
                message: 'Pull down when you want the scanner to sweep again.',
              )
            else
              for (final (i, signal) in _result!.value!.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                Entrance(
                  index: i + 1,
                  child: _SignalRowCard(
                    signal: signal,
                    onTap: () => _openEquity(signal),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _SignalRowCard extends StatelessWidget {
  const _SignalRowCard({required this.signal, required this.onTap});

  final Signal signal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tone = signal.bullish ? t.jade : t.garnet;

    return AyreCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The bias glyph carries direction alongside the colour.
              AyreIcon(
                signal.bullish ? AyreGlyph.trendUp : AyreGlyph.trendDown,
                size: 17,
                color: tone,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.symbol,
                      style: AppTypo.rowLabel(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (signal.name != null && signal.name!.isNotEmpty)
                      Text(
                        signal.name!,
                        style: AppTypo.caption(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (signal.lastPrice != null)
                        Figure(formatPrice(signal.lastPrice), fontSize: 14),
                      const SizedBox(height: AppSpacing.xxs),
                      DeltaFigure(change: signal.percentChange, fontSize: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (signal.rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              signal.rationale,
              style: AppTypo.body(t),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const HairlineDivider(),
          const SizedBox(height: AppSpacing.sm),
          // The levels row only renders the figures the feed actually provided.
          Row(
            children: [
              if (signal.strength != null) ...[
                Text('CONVICTION', style: AppTypo.label(t)),
                const SizedBox(width: AppSpacing.xs),
                SignalStrength(level: signal.strength!, color: tone),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      if (signal.entry != null)
                        _Level(label: 'Entry', value: signal.entry),
                      if (signal.target != null)
                        _Level(label: 'Target', value: signal.target, tone: t.jade),
                      if (signal.stop != null)
                        _Level(label: 'Stop', value: signal.stop, tone: t.garnet),
                      if (signal.entry == null &&
                          signal.target == null &&
                          signal.stop == null &&
                          signal.addedOn != null)
                        Text(
                          'ADDED ${signal.addedOn!.toUpperCase()}',
                          style: AppTypo.label(t),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: AppTypo.label(t)),
          const SizedBox(width: AppSpacing.xs),
          Figure(formatPrice(value), fontSize: 12, color: tone),
        ],
      ),
    );
  }
}
