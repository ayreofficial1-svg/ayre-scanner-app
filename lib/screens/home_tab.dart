import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    HapticFeedback.mediumImpact();
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
    if (_loading) return const PremiumLoader(label: 'Opening scanner', section: AyreSection.home);

    return PremiumScaffold(
      section: AyreSection.home,
      bottomSafe: false,
      child: Stack(
        children: [
          RefreshIndicator(
            color: tokens.primary,
            backgroundColor: tokens.surface,
            onRefresh: _loadData,
            edgeOffset: 120, // push down below header
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 140),
              children: [
                AnimatedEntrance(
                  child: _HomeHeader(
                    displayName: _displayName,
                    onProfileTap: () =>
                        widget.onProfileMenuRequested?.call(_displayName),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: _HeroBoard(market: _market),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AnimatedEntrance(
                  delay: Duration(milliseconds: 150),
                  child: _SignalReadinessCard(),
                ),
                const SizedBox(height: AppSpacing.lg),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 200),
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
                style: AppTypo.bodyMedium(tokens, color: tokens.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Scanner plan',
                style: AppTypo.pageTitle(tokens),
              ),
            ],
          ),
        ),
        GlassCircleButton(
          icon: Icons.notifications_rounded,
          size: 46,
          color: tokens.surfaceAlt,
          iconColor: tokens.textPrimary,
        ),
        const SizedBox(width: AppSpacing.md),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onProfileTap();
          },
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
      radius: AppRadius.heroCard,
      padding: EdgeInsets.zero,
      gradient: AppGradients.heroCard(AyreSection.home, tokens),
      shadowColor: tokens.primary.withValues(alpha: 0.3),
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -50,
              child: AuraHalo(
                color: tokens.teal2,
                size: 240,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SoftPill(
                        label: 'LIVE MARKET',
                        icon: Icons.bolt_rounded,
                        background: tokens.neutralBlock,
                        foreground: tokens.onNeutralBlock,
                      ),
                      const Spacer(),
                      GlassCircleButton(
                        icon: Icons.auto_graph_rounded,
                        size: 44,
                        color: Colors.white.withValues(alpha: 0.2),
                        iconColor: tokens.onPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    '$score%',
                    style: AppTypo.heroValue(tokens, color: tokens.onPrimary).copyWith(
                      fontSize: 64,
                    ),
                  ),
                  Text(
                    'Momentum quality',
                    style: AppTypo.bodyMedium(tokens, color: tokens.onPrimary.withValues(alpha: 0.8)),
                  ),
                  const Spacer(),
                  Sparkline(
                    color: tokens.onPrimary.withValues(alpha: 0.95),
                    height: 80,
                  ),
                ],
              ),
            ),
            Positioned(
              right: AppSpacing.xxl,
              bottom: 90,
              child: FloatingOrb(
                distance: 8,
                child: Container(
                  height: 76,
                  width: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.neutralBlock,
                    boxShadow: [
                      BoxShadow(
                        color: tokens.shadowLg.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    _displayChange(nifty),
                    textAlign: TextAlign.center,
                    style: AppTypo.dataNum(tokens, color: tokens.onNeutralBlock).copyWith(
                      fontSize: 16,
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: LinearGradient(
        colors: [
          tokens.surfaceRaised,
          Color.lerp(tokens.surfaceRaised, tokens.primary, 0.05)!,
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
                height: 72,
                width: 72,
                child: CircularProgressIndicator(
                  value: 0.78,
                  strokeWidth: 8,
                  color: tokens.primary,
                  backgroundColor: tokens.border,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '78%',
                style: AppTypo.dataNum(tokens, color: tokens.textPrimary).copyWith(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trade readiness',
                  style: AppTypo.cardTitle(tokens),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Fresh setups, breadth context, and risk checkpoints are staged for review.',
                  style: AppTypo.body(tokens),
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
        const SizedBox(width: AppSpacing.md),
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
    final fill = tone == _TileTone.mint ? tokens.accentMint : tokens.lavender;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark ? tokens.surface : tokens.onAccentMint;
    
    return PressableScale(
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gradient: LinearGradient(
          colors: [fill, Color.lerp(fill, Colors.white, 0.1)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: fill.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: contentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.show_chart_rounded,
                color: contentColor,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.eyebrow(tokens, color: contentColor.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _displayValue(data),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.dataNum(tokens, color: contentColor).copyWith(
                fontSize: 18,
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
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primaryShifted(tokens),
        border: Border.all(color: tokens.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypo.cardTitle(tokens, color: tokens.onPrimary),
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
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypo.eyebrow(tokens, color: foreground),
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
      top: MediaQuery.paddingOf(context).top + 16,
      left: 0,
      right: 0,
      child: Center(
        child: PremiumCard(
          radius: AppRadius.pill,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          color: tokens.surfaceAlt,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Refreshing',
                style: AppTypo.eyebrow(tokens),
              ),
            ],
          ),
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
