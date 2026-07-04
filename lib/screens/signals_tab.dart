import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
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

    if (_loading) {
      return const _SignalsLoading();
    }

    if (_signals.isEmpty) {
      return RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [_SignalsEmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      color: tokens.primary,
      backgroundColor: tokens.surface,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xl + 104,
        ),
        itemCount: _signals.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => _SignalCard(signal: _signals[i]),
      ),
    );
  }
}

class _SignalsLoading extends StatelessWidget {
  const _SignalsLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.background, tokens.backgroundTint],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: tokens.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tokens.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: tokens.primary,
            ),
          ),
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          height: 90,
          width: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tokens.accentWarm, tokens.accentMint],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tokens.primary.withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(Icons.radar_rounded, color: tokens.onAccentWarm, size: 42),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'No new setups yet',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pull to refresh when you want to scan again.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.signal});

  final Map<String, dynamic> signal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final symbol = signal['symbol']?.toString() ?? '';
    final rationale = signal['rationale']?.toString() ?? '';
    final dateAdded = signal['date_added']?.toString() ?? '';
    final lastPrice = signal['last_price'];
    final changePct = signal['change_pct'];

    final isUp = (changePct is num) ? changePct >= 0 : null;
    final cardColor =
        isUp == null ? tokens.surface : (isUp ? tokens.positive : tokens.negative);
    final onCardColor =
        isUp == null ? tokens.textPrimary : (isUp ? tokens.onPositive : tokens.onNegative);
    final secondaryColor = isUp == null ? tokens.textSecondary : onCardColor;

    return PressableScale(
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: (isUp == null ? tokens.shadow : cardColor)
                  .withValues(alpha: isUp == null ? 0.4 : 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        symbol,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: onCardColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          lastPrice is num ? lastPrice.toStringAsFixed(2) : '--',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: onCardColor,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: onCardColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            changePct is num
                                ? '${isUp! ? '+' : ''}${changePct.toStringAsFixed(2)}%'
                                : '--',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: onCardColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (rationale.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    rationale,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: secondaryColor,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
                if (dateAdded.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: secondaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Added $dateAdded',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}