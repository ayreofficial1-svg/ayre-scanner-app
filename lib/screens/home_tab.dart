import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
    if (mounted && !_loading) {
      setState(() => _refreshing = true);
    }

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

    if (_loading) {
      return const _HomeLoading();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.background, tokens.backgroundTint],
        ),
      ),
      child: Stack(
        children: [
          RefreshIndicator(
            color: tokens.primary,
            backgroundColor: tokens.surface,
            onRefresh: _loadData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xl + 104,
              ),
              children: [
                _HomeHeader(
                  displayName: _displayName,
                  onProfileTap: () {
                    widget.onProfileMenuRequested?.call(_displayName);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _TodayBoard(market: _market),
                const SizedBox(height: AppSpacing.md),
                const _ReadyThisWeekCard(),
              ],
            ),
          ),
          if (_refreshing) _RefreshRibbon(tokens: tokens),
        ],
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

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
            height: 28,
            width: 28,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.displayName, required this.onProfileTap});

  final String displayName;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = displayName.isEmpty ? 'Raghav' : displayName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileAvatar(name: name, onTap: onProfileTap),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ayre Scanner',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Hi $name, here's what we have for you today",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fresh market context and swing-trade readiness at a glance.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final initial =
        widget.name.trim().isEmpty ? 'R' : widget.name.trim()[0].toUpperCase();

    return Semantics(
      button: true,
      label: 'Open profile menu',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primaryShifted(tokens),
              boxShadow: [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
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
          ),
        ),
      ),
    );
  }
}

class _TodayBoard extends StatelessWidget {
  const _TodayBoard({required this.market});

  final Map<String, dynamic>? market;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return _HomePanel(
      title: "Today's Board",
      fillColor: tokens.neutralBlock,
      foregroundColor: tokens.onNeutralBlock,
      trailing: Icon(Icons.auto_graph_rounded, color: tokens.primary),
      child: market == null
          ? Text(
              'Market data unavailable',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
            )
          : Row(
              children: [
                Expanded(
                  child: _TrendCard(
                    label: 'NIFTY 50',
                    data: _marketValue('nifty'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TrendCard(
                    label: 'SENSEX',
                    data: _marketValue('sensex'),
                  ),
                ),
              ],
            ),
    );
  }

  dynamic _marketValue(String key) {
    if (market == null) return null;
    return market![key] ?? market![key.toUpperCase()];
  }
}

class _ReadyThisWeekCard extends StatelessWidget {
  const _ReadyThisWeekCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return _HomePanel(
      title: 'Ready This Week',
      fillColor: tokens.accentWarm,
      foregroundColor: tokens.onAccentWarm,
      trailing: Icon(Icons.event_available_rounded, color: tokens.onAccentWarm),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tokens.positive,
                  tokens.accentMint,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up_rounded,
                color: Color(0xFFFFFFFF), size: 26),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Open Signals when you want the latest curated setups.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.onAccentWarm,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.title,
    required this.fillColor,
    required this.foregroundColor,
    required this.trailing,
    required this.child,
  });

  final String title;
  final Color fillColor;
  final Color foregroundColor;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowLg.withValues(alpha: isDark ? 0.45 : 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: tokens.shadow.withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  trailing,
                ],
              ),
              const SizedBox(height: AppSpacing.md + 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color:
                      foregroundColor.withValues(alpha: isDark ? 0.08 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.label, required this.data});

  final String label;
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final trend = _trendFromData(data);
    final value = _displayValue(data);
    final change = _displayChange(data);

    final colors = switch (trend) {
      _Trend.up => _TrendColors(
          bg: tokens.positive,
          fg: tokens.onPositive,
        ),
      _Trend.down => _TrendColors(
          bg: tokens.negative,
          fg: tokens.onNegative,
        ),
      _Trend.flat => _TrendColors(
          bg: tokens.accentWarm,
          fg: tokens.onAccentWarm,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: colors.bg.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.fg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.fg,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs + 1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.fg.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              change,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
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
    if (change == null) return 'Awaiting move';
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
  }

  _Trend _trendFromData(dynamic raw) {
    final change = _numFrom(raw, const [
      'change_pct',
      'percent_change',
      'change',
    ]);
    if (change == null || change == 0) return _Trend.flat;
    return change > 0 ? _Trend.up : _Trend.down;
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
}

class _TrendColors {
  const _TrendColors({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}

enum _Trend { up, down, flat }

class _RefreshRibbon extends StatelessWidget {
  const _RefreshRibbon({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: tokens.shadowLg,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              'Refreshing',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}