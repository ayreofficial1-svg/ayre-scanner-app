import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_states.dart';
import '../widgets/numeral.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/responsive.dart';

class SignalsTab extends StatefulWidget {
  const SignalsTab({super.key});

  @override
  State<SignalsTab> createState() => _SignalsTabState();
}

class _SignalsTabState extends State<SignalsTab> {
  List<Map<String, dynamic>> _signals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final signals = await ApiService.getSignals();
    if (!mounted) return;
    final firstLoad = _loading;
    setState(() {
      _signals = signals;
      _loading = false;
    });
    // A refresh that lands new data confirms itself; the first load doesn't.
    if (!firstLoad) HapticFeedback.mediumImpact();

    final symbols = signals
        .map((s) => s['symbol']?.toString())
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    final fresh = await SeenSignalsStore.diffAndRecord(symbols);
    if (fresh.isEmpty) return;
    await NotificationLog.instance.add(
      Notice(
        kind: NoticeKind.signal,
        title: fresh.length == 1
            ? 'New scanner pick: ${fresh.first}'
            : '${fresh.length} new scanner picks',
        body:
            '${fresh.take(4).join(', ')}'
            '${fresh.length > 4 ? ', and more' : ''}',
        at: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) {
      return const PremiumLoader(
        label: 'Scanning setups',
        section: AyreSection.signals,
      );
    }

    // Signals is a list of self-contained, independently-scannable items, so it
    // goes two-column once the viewport comfortably fits two readable cards.
    final twoColumn = AppBreakpoints.usesTwoColumn(context);

    return PremiumScaffold(
      section: AyreSection.signals,
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: const SliverToBoxAdapter(
                child: AnimatedEntrance(child: _SignalsHeader()),
              ),
            ),
            if (_signals.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: const SliverToBoxAdapter(
                  child: AppStateMessage(
                    icon: Icons.radar_rounded,
                    heading: 'No fresh setups',
                    message:
                        'Pull down when you want the scanner to sweep again.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  140,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: twoColumn ? 2 : 1,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 168,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: _signals.length,
                    (context, index) => AnimatedEntrance(
                      delay: Duration(milliseconds: 40 * (index + 1)),
                      child: _SignalCard(
                        signal: _signals[index],
                        index: index + 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Signals' hero carries no ornament — Home's hero is the one ornamented
/// surface in the app, and this screen relies on the flat, bordered surface
/// treatment instead.
class _SignalsHeader extends StatelessWidget {
  const _SignalsHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: AppRadius.heroCard,
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: AppSurfaces.heroFill(AyreSection.signals, tokens),
      borderColor: tokens.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: 'Live scanner',
            outlined: true,
            foreground: tokens.onPrimary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Signal board',
            style: AppTypo.pageTitle(tokens, color: tokens.onPrimary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Curated setups with live movement and compact rationale.',
            style: AppTypo.bodyMedium(
              tokens,
              color: tokens.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.signal, required this.index});

  final Map<String, dynamic> signal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final symbol = signal['symbol']?.toString() ?? 'SETUP';
    final rationale = signal['rationale']?.toString() ?? '';
    final dateAdded = signal['date_added']?.toString() ?? '';
    final lastPrice = signal['last_price'];
    final changePct = signal['change_pct'];
    final price = lastPrice is num ? lastPrice : null;
    final change = changePct is num ? changePct : null;
    final up = (change ?? 0) >= 0;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypo.cardTitle(tokens).copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dateAdded.isEmpty
                          ? 'Scanner pick #$index'
                          : 'Added $dateAdded',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypo.caption(tokens),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Numeral(
                    formatPrice(price),
                    value: price?.toDouble(),
                    format: formatPrice,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 1),
                  DeltaFigure(change: change, fontSize: 12),
                ],
              ),
            ],
          ),
          if (rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              rationale,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.body(tokens),
            ),
          ],
          const Spacer(),
          // Per-signal traces stay in brass: the trace records the shape of the
          // move, and the sign and glyph above already carry the direction.
          Sparkline(
            height: 44,
            points: up
                ? const [0.24, 0.30, 0.28, 0.44, 0.40, 0.58, 0.62, 0.74]
                : const [0.76, 0.68, 0.70, 0.52, 0.56, 0.38, 0.34, 0.22],
          ),
        ],
      ),
    );
  }
}
