import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, this.onProfileMenuRequested});

  final ValueChanged<String>? onProfileMenuRequested;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _displayName = '';
  Map<String, dynamic>? _market;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted && !_loading) setState(() => _refreshing = true);
    final session = await ApiService.getSession();
    final market = await ApiService.getMarket();
    if (!mounted) return;
    setState(() {
      _displayName = session?['display_name'] ?? session?['username'] ?? '';
      _market = market;
      _loading = false;
      _refreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) return const PremiumLoader(label: 'Opening scanner');

    return PremiumScaffold(
      bottomSafe: false,
      child: Stack(
        children: [
          RefreshIndicator(
            color: tokens.primary,
            backgroundColor: tokens.surface,
            onRefresh: _loadData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 124),
              children: [
                AnimatedEntrance(
                  child: _HomeHeader(
                    displayName: _displayName,
                    onProfileTap: () =>
                        widget.onProfileMenuRequested?.call(_displayName),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: _HeroBoard(market: _market),
                ),
                const SizedBox(height: 16),
                const AnimatedEntrance(
                  delay: Duration(milliseconds: 130),
                  child: _SignalReadinessCard(),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 170),
                  child: _MarketTiles(market: _market),
                ),
              ],
            ),
          ),
          if (_refreshing) _RefreshRibbon(tokens: tokens),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.displayName, required this.onProfileTap});

  final String displayName;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = displayName.isEmpty ? 'Raghav' : displayName;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scanner plan',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        GlassCircleButton(
          icon: Icons.notifications_rounded,
          size: 48,
          color: tokens.surface,
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onProfileTap,
          child: _AvatarBadge(name: name),
        ),
      ],
    );
  }
}

class _HeroBoard extends StatelessWidget {
  const _HeroBoard({required this.market});

  final Map<String, dynamic>? market;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final nifty = _marketValue('nifty');
    final score = _scoreFrom(nifty);
    return PremiumCard(
      radius: 46,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          tokens.accentWarm,
          Color.lerp(tokens.accentWarm, tokens.accentMint, 0.52)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: tokens.accentWarm.withValues(alpha: 0.34),
      child: SizedBox(
        height: 308,
        child: Stack(
          children: [
            Positioned(
              top: -76,
              right: -38,
              child: Container(
                height: 190,
                width: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              bottom: -82,
              left: -42,
              child: Container(
                height: 210,
                width: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.primary.withValues(alpha: 0.58),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SoftPill(
                        label: 'Live market',
                        icon: Icons.bolt_rounded,
                        background: tokens.neutralBlock,
                        foreground: tokens.onNeutralBlock,
                      ),
                      const Spacer(),
                      GlassCircleButton(
                        icon: Icons.auto_graph_rounded,
                        size: 44,
                        color: Colors.white.withValues(alpha: 0.32),
                        iconColor: tokens.onAccentWarm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    '$score%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: tokens.onAccentWarm,
                      fontSize: 62,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Momentum quality',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.onAccentWarm.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Sparkline(
                    color: tokens.onAccentWarm.withValues(alpha: 0.9),
                    height: 76,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 84,
              child: FloatingOrb(
                distance: 6,
                child: Container(
                  height: 74,
                  width: 74,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.neutralBlock,
                    boxShadow: [
                      BoxShadow(
                        color: tokens.shadowLg.withValues(alpha: 0.36),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Text(
                    _displayChange(nifty),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.onNeutralBlock,
                      fontWeight: FontWeight.w900,
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

  dynamic _marketValue(String key) =>
      market?[key] ?? market?[key.toUpperCase()];
}

class _SignalReadinessCard extends StatelessWidget {
  const _SignalReadinessCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          tokens.neutralBlock,
          Color.lerp(tokens.neutralBlock, tokens.accentCool, 0.14)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 76,
                width: 76,
                child: CircularProgressIndicator(
                  value: 0.78,
                  strokeWidth: 9,
                  color: tokens.primary,
                  backgroundColor: tokens.onNeutralBlock.withValues(
                    alpha: 0.12,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '78%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tokens.onNeutralBlock,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trade readiness',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: tokens.onNeutralBlock,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fresh setups, breadth context, and risk checkpoints are staged for review.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.onNeutralBlock.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketTiles extends StatelessWidget {
  const _MarketTiles({required this.market});

  final Map<String, dynamic>? market;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MarketTile(
            label: 'NIFTY 50',
            data: _marketValue('nifty'),
            tone: _TileTone.mint,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MarketTile(
            label: 'SENSEX',
            data: _marketValue('sensex'),
            tone: _TileTone.cool,
          ),
        ),
      ],
    );
  }

  dynamic _marketValue(String key) =>
      market?[key] ?? market?[key.toUpperCase()];
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({
    required this.label,
    required this.data,
    required this.tone,
  });

  final String label;
  final dynamic data;
  final _TileTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = tone == _TileTone.mint ? tokens.accentMint : tokens.accentCool;
    return PressableScale(
      child: PremiumCard(
        radius: 34,
        padding: const EdgeInsets.all(18),
        color: fill,
        shadowColor: fill.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.show_chart_rounded,
              color: Colors.black.withValues(alpha: 0.58),
              size: 28,
            ),
            const SizedBox(height: 18),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.black.withValues(alpha: 0.62),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _displayValue(data),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black.withValues(alpha: 0.78),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final initial = name.trim().isEmpty ? 'R' : name.trim()[0].toUpperCase();
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primaryShifted(tokens),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: tokens.onPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  const _SoftPill({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 16, 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshRibbon extends StatelessWidget {
  const _RefreshRibbon({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 14,
      left: 78,
      right: 78,
      child: PremiumCard(
        radius: AppRadius.pill,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: tokens.surface,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: tokens.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Refreshing',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayValue(dynamic raw) {
  final price = _numFrom(raw, const ['last_price', 'price', 'value', 'ltp']);
  if (price != null) return price.toStringAsFixed(2);
  return raw?.toString() ?? '--';
}

String _displayChange(dynamic raw) {
  final change = _numFrom(raw, const [
    'change_pct',
    'percent_change',
    'change',
  ]);
  if (change == null) return '+0.0%';
  return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
}

int _scoreFrom(dynamic raw) {
  final change =
      _numFrom(raw, const ['change_pct', 'percent_change', 'change']) ?? 0;
  return (72 + change.clamp(-8, 8) * 2).round().clamp(48, 94).toInt();
}

num? _numFrom(dynamic raw, List<String> keys) {
  if (raw is num) return raw;
  if (raw is Map) {
    for (final key in keys) {
      final value = raw[key];
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
    }
  }
  if (raw is String) return num.tryParse(raw);
  return null;
}

enum _TileTone { mint, cool }
