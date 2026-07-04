import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';

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
    setState(() {
      _signals = signals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) return const PremiumLoader(label: 'Scanning setups');

    return PremiumScaffold(
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 124),
          itemCount: _signals.isEmpty ? 2 : _signals.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            if (index == 0)
              return const AnimatedEntrance(child: _SignalsHeader());
            if (_signals.isEmpty)
              return const AnimatedEntrance(
                delay: Duration(milliseconds: 80),
                child: _SignalsEmptyState(),
              );
            return AnimatedEntrance(
              delay: Duration(milliseconds: 45 * index),
              child: _SignalCard(signal: _signals[index - 1], index: index),
            );
          },
        ),
      ),
    );
  }
}

class _SignalsHeader extends StatelessWidget {
  const _SignalsHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        colors: [
          tokens.negative,
          Color.lerp(tokens.negative, tokens.accentWarm, 0.34)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: tokens.negative.withValues(alpha: 0.26),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBadge(tokens: tokens),
                const SizedBox(height: 24),
                Text(
                  'Signal board',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Curated setups with live movement and compact rationale.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FloatingOrb(
            child: Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: tokens.neutralBlock,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Live scanner',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: tokens.onNeutralBlock,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SignalsEmptyState extends StatelessWidget {
  const _SignalsEmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.all(28),
      gradient: AppGradients.surfaceGlass(tokens),
      child: Column(
        children: [
          FloatingOrb(
            child: Container(
              height: 104,
              width: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.warmShifted(tokens),
                boxShadow: [
                  BoxShadow(
                    color: tokens.accentWarm.withValues(alpha: 0.32),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Icon(
                Icons.travel_explore_rounded,
                color: tokens.onAccentWarm,
                size: 46,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No fresh setups',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down when you want the scanner to sweep again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w700,
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
    final isUp = changePct is num ? changePct >= 0 : true;
    final fill = isUp ? tokens.accentMint : tokens.negative;
    final foreground = isUp ? tokens.onAccentMint : tokens.onNegative;

    return PressableScale(
      onTap: () {},
      child: PremiumCard(
        radius: 36,
        padding: EdgeInsets.zero,
        color: fill,
        shadowColor: fill.withValues(alpha: 0.3),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -40,
              child: Container(
                height: 142,
                width: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.neutralBlock,
                        ),
                        child: Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: tokens.onNeutralBlock,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              symbol,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Text(
                              dateAdded.isEmpty
                                  ? 'Scanner pick #$index'
                                  : 'Added $dateAdded',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: foreground.withValues(alpha: 0.68),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _PricePill(
                        price: lastPrice,
                        changePct: changePct,
                        foreground: foreground,
                      ),
                    ],
                  ),
                  if (rationale.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      rationale,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Sparkline(
                    color: foreground.withValues(alpha: 0.8),
                    height: 54,
                    points: isUp
                        ? const [0.72, 0.64, 0.7, 0.5, 0.58, 0.38, 0.42, 0.24]
                        : const [0.24, 0.38, 0.32, 0.5, 0.48, 0.62, 0.58, 0.72],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.price,
    required this.changePct,
    required this.foreground,
  });

  final dynamic price;
  final dynamic changePct;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final isUp = changePct is num ? changePct >= 0 : true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price is num ? price.toStringAsFixed(2) : '--',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            changePct is num
                ? '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%'
                : '--',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
