import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    HapticFeedback.lightImpact();
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
    if (_loading) return const PremiumLoader(label: 'Scanning setups', section: AyreSection.signals);

    return PremiumScaffold(
      section: AyreSection.signals,
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 140),
          itemCount: _signals.isEmpty ? 2 : _signals.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const AnimatedEntrance(child: _SignalsHeader());
            }
            if (_signals.isEmpty) {
              return const AnimatedEntrance(
                delay: Duration(milliseconds: 100),
                child: _SignalsEmptyState(),
              );
            }
            return AnimatedEntrance(
              delay: Duration(milliseconds: 50 * index),
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
      radius: AppRadius.heroCard,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      gradient: AppGradients.heroCard(AyreSection.signals, tokens),
      shadowColor: tokens.primary.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBadge(tokens: tokens),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Signal board',
                  style: AppTypo.pageTitle(tokens, color: tokens.onPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Curated setups with live movement and compact rationale.',
                  style: AppTypo.bodyMedium(tokens, color: tokens.onPrimary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          FloatingOrb(
            child: Container(
              height: 86,
              width: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Colors.white,
                size: 40,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.neutralBlock,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'LIVE SCANNER',
        style: AppTypo.eyebrow(tokens, color: tokens.onNeutralBlock),
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
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      gradient: AppGradients.surfaceGlass(tokens),
      child: Column(
        children: [
          FloatingOrb(
            child: Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primaryShifted(tokens),
                boxShadow: [
                  BoxShadow(
                    color: tokens.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.travel_explore_rounded,
                color: tokens.onPrimary,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'No fresh setups',
            style: AppTypo.sectionTitle(tokens),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pull down when you want the scanner to sweep again.',
            textAlign: TextAlign.center,
            style: AppTypo.body(tokens),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Softer background colors for signal cards
    final fill = isUp 
        ? (isDark ? tokens.positive.withValues(alpha: 0.15) : tokens.mint) 
        : (isDark ? tokens.negative.withValues(alpha: 0.15) : tokens.peach);
    
    final foreground = isUp 
        ? (isDark ? tokens.positive : tokens.primary)
        : (isDark ? tokens.negative : tokens.negative);
        
    final textColor = isDark ? tokens.textPrimary : tokens.neutralBlock;

    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: PremiumCard(
        radius: AppRadius.card,
        padding: EdgeInsets.zero,
        color: fill,
        borderColor: isUp ? tokens.positive.withValues(alpha: 0.3) : tokens.negative.withValues(alpha: 0.3),
        shadowColor: fill.withValues(alpha: 0.5),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: foreground.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: foreground.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: foreground,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              symbol,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypo.cardTitle(tokens, color: textColor).copyWith(
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              dateAdded.isEmpty
                                  ? 'Scanner pick #$index'
                                  : 'Added $dateAdded',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypo.caption(tokens, color: textColor.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                      _PricePill(
                        price: lastPrice,
                        changePct: changePct,
                        foreground: foreground,
                        backgroundColor: foreground.withValues(alpha: 0.15),
                        tokens: tokens,
                      ),
                    ],
                  ),
                  if (rationale.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      rationale,
                      style: AppTypo.body(tokens, color: textColor.withValues(alpha: 0.85)),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Sparkline(
                    color: foreground.withValues(alpha: 0.9),
                    height: 60,
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
    required this.backgroundColor,
    required this.tokens,
  });

  final dynamic price;
  final dynamic changePct;
  final Color foreground;
  final Color backgroundColor;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isUp = changePct is num ? changePct >= 0 : true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price is num ? price.toStringAsFixed(2) : '--',
            style: AppTypo.dataNum(tokens, color: foreground),
          ),
          Text(
            changePct is num
                ? '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%'
                : '--',
            style: AppTypo.caption(tokens, color: foreground),
          ),
        ],
      ),
    );
  }
}
