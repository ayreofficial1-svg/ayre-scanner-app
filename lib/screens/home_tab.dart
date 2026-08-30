import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/market_movers_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/instrument_marks.dart';
import '../widgets/market_movers_section.dart';
import '../widgets/numeral.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/spring.dart';
import 'home_shell.dart' show NavAvatar;
import 'notifications_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    this.onIdentityResolved,
    this.onOpenProfile,
    this.marketMovers = const AyreBackendMarketMoversService(),
  });

  final ValueChanged<String>? onIdentityResolved;
  final VoidCallback? onOpenProfile;

  /// Injected so nothing on this screen knows which provider is behind the
  /// three market-mover sections.
  final MarketMoversService marketMovers;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _displayName = '';
  Map<String, dynamic>? _market;
  bool _loading = true;

  MarketMoversResult? _gainers;
  MarketMoversResult? _losers;
  MarketMoversResult? _mostActive;
  bool _moversLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final session = await ApiService.getSession();
    final market = await ApiService.getMarket();
    if (!mounted) return;
    final firstLoad = _loading;
    setState(() {
      _displayName = session?['display_name'] ?? session?['username'] ?? '';
      _market = market;
      _loading = false;
    });
    widget.onIdentityResolved?.call(_displayName);

    await _loadMovers();

    if (!mounted) return;
    // A pull-to-refresh that successfully lands new data earns a confirmation
    // weight haptic; opening the app is not an action to confirm.
    if (!firstLoad) HapticFeedback.mediumImpact();
  }

  Future<void> _loadMovers() async {
    final results = await Future.wait([
      widget.marketMovers.getTopGainers(),
      widget.marketMovers.getTopLosers(),
      widget.marketMovers.getMostActiveEquities(),
    ]);
    if (!mounted) return;
    setState(() {
      _gainers = results[0];
      _losers = results[1];
      _mostActive = results[2];
      _moversLoading = false;
    });

    if (results.any((r) => r.stale)) {
      NotificationLog.instance.add(
        Notice(
          kind: NoticeKind.staleData,
          title: 'Market data is behind',
          body:
              'The mover lists are older than their normal update interval. '
              'Last known values are still shown.',
          at: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) {
      return const PremiumLoader(
        label: 'Opening scanner',
        section: AyreSection.home,
      );
    }

    final nifty = _marketValue('nifty');
    final score = _scoreFrom(nifty);

    return PremiumScaffold(
      section: AyreSection.home,
      bottomSafe: false,
      // One refresh indicator, app-wide. The bespoke ribbon that used to run
      // alongside it is gone.
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _refresh,
        edgeOffset: 96,
        child: ContentWidth(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              140,
            ),
            children: [
              AnimatedEntrance(
                child: _HomeHeader(
                  displayName: _displayName,
                  onOpenProfile: widget.onOpenProfile,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 100),
                child: _HeroBoard(market: _market, score: score),
              ),
              const SizedBox(height: AppSpacing.md),
              const AnimatedEntrance(
                delay: Duration(milliseconds: 150),
                child: _SignalReadinessCard(),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 200),
                child: _MarketTiles(market: _market),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 250),
                child: MarketMoversSection(
                  title: 'Top gainers',
                  result: _gainers,
                  loading: _moversLoading,
                  emptyMessage:
                      'No advancing equities in this session yet. This list '
                      'fills once the market is open.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 280),
                child: MarketMoversSection(
                  title: 'Top losers',
                  result: _losers,
                  loading: _moversLoading,
                  emptyMessage:
                      'No declining equities in this session yet. This list '
                      'fills once the market is open.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 310),
                child: MarketMoversSection(
                  title: 'Most active equities',
                  result: _mostActive,
                  loading: _moversLoading,
                  showVolume: true,
                  emptyMessage:
                      'No traded volume reported yet for this session.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  dynamic _marketValue(String key) =>
      _market?[key] ?? _market?[key.toUpperCase()];
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.displayName, required this.onOpenProfile});

  final String displayName;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = displayName.trim().isEmpty ? 'there' : displayName.trim();

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
              const SizedBox(height: AppSpacing.xxs),
              Text('Scanner plan', style: AppTypo.pageTitle(tokens)),
            ],
          ),
        ),
        // The bell now goes somewhere: a reverse-chronological list of the
        // alerts the app has actually recorded.
        ListenableBuilder(
          listenable: NotificationLog.instance,
          builder: (context, _) => InstrumentIconButton(
            icon: Icons.notifications_none_rounded,
            semanticLabel: 'Alerts',
            size: 44,
            badge: NotificationLog.instance.hasUnread,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: true,
          label: 'Profile',
          child: PressableScale(
            borderRadius: 24,
            onTap: onOpenProfile == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onOpenProfile!();
                  },
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: NavAvatar(name: displayName, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}

/// Home's hero — the one surface on this screen permitted an ornament, and the
/// one place besides the splash wordmark where a numeral renders in the display
/// serif.
class _HeroBoard extends StatelessWidget {
  const _HeroBoard({required this.market, required this.score});

  final Map<String, dynamic>? market;
  final int score;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final nifty = market?['nifty'] ?? market?['NIFTY'];
    final changePct = _numFrom(nifty, const [
      'change_pct',
      'percent_change',
      'change',
    ]);

    // Ember appears here only when the reading is genuinely notable — a strong
    // or a poor score. A middling reading gets brass like everything else.
    final notable = score >= 82 || score <= 55;
    final ringTone = notable ? tokens.accentWarm : tokens.onPrimary;
    final onHero = AppSurfaces.onHero(AyreSection.home, tokens);

    return PremiumCard(
      radius: AppRadius.heroCard,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      color: AppSurfaces.heroFill(AyreSection.home, tokens),
      borderColor: tokens.primary.withValues(alpha: 0.35),
      ornament: HeroOrnament.contour,
      ornamentColor: onHero.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: 'Live market',
                icon: Icons.circle,
                outlined: true,
                foreground: onHero,
              ),
              const Spacer(),
              _MomentumRing(score: score, tone: ringTone, track: onHero),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The display-serif numeral exception, moment one of two.
              Text('$score', style: AppTypo.heroSerif(tokens, color: onHero)),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '/100',
                  style: AppTypo.bodyMedium(
                    tokens,
                    color: onHero.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Text(
                'Momentum quality',
                style: AppTypo.bodyMedium(
                  tokens,
                  color: onHero.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DeltaFigure(
                change: changePct,
                fontSize: 13,
                color: onHero.withValues(alpha: 0.92),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Brass-family trace, not a gain/loss color: the sparkline is the
          // instrument's record first and a direction second.
          Sparkline(
            color: onHero.withValues(alpha: 0.9),
            height: 64,
            points: _traceFor(changePct),
          ),
        ],
      ),
    );
  }

  /// A deterministic trace shape from the day's move, so the hero doesn't
  /// pretend to intraday history the backend doesn't return.
  List<double> _traceFor(num? changePct) {
    final lift = ((changePct ?? 0) / 4).clamp(-0.4, 0.4).toDouble();
    const base = [0.42, 0.46, 0.40, 0.52, 0.48, 0.58, 0.54, 0.62];
    return [
      for (var i = 0; i < base.length; i++)
        (base[i] + lift * (i / (base.length - 1))).clamp(0.05, 0.95).toDouble(),
    ];
  }
}

/// The momentum-score ring. Ember-toned only when the reading is notable — the
/// first of the four sanctioned ember uses.
class _MomentumRing extends StatelessWidget {
  const _MomentumRing({
    required this.score,
    required this.tone,
    required this.track,
  });

  final int score;
  final Color tone;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: 44,
      child: SpringValue(
        value: score / 100,
        animateOnMount: true,
        builder: (context, progress, _) => CustomPaint(
          painter: _RingPainter(
            progress: progress.clamp(0.0, 1.0),
            tone: tone,
            track: track.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.tone,
    required this.track,
  });

  final double progress;
  final Color tone;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 2,
    );
    canvas.drawArc(
      rect,
      0,
      6.28318,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawArc(
      rect,
      -1.5708,
      6.28318 * progress,
      false,
      Paint()
        ..color = tone
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.tone != tone || old.track != track;
}

class _SignalReadinessCard extends StatelessWidget {
  const _SignalReadinessCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: tokens.surface,
      child: Row(
        children: [
          SizedBox(
            height: 52,
            width: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: 0.78,
                      tone: tokens.primary,
                      track: tokens.border,
                    ),
                  ),
                ),
                const Numeral.static('78', fontSize: 14),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trade readiness', style: AppTypo.cardTitle(tokens)),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Fresh setups, breadth context and risk checkpoints are '
                  'staged for review.',
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
          child: _MarketTile(label: 'NIFTY 50', data: _marketValue('nifty')),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MarketTile(label: 'SENSEX', data: _marketValue('sensex')),
        ),
      ],
    );
  }

  dynamic _marketValue(String key) =>
      market?[key] ?? market?[key.toUpperCase()];
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({required this.label, required this.data});

  final String label;
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final price = _numFrom(data, const ['last_price', 'price', 'value', 'ltp']);
    final changePct = _numFrom(data, const [
      'change_pct',
      'percent_change',
      'change',
    ]);

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: tokens.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypo.microLabel(tokens),
                ),
              ),
              SizedBox(
                height: 8,
                width: 24,
                child: TickMarks(
                  color: tokens.engraved,
                  count: 5,
                  length: 3,
                  majorEvery: 4,
                  majorLength: 7,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Numeral(
            formatPrice(price),
            value: price?.toDouble(),
            format: formatPrice,
            fontSize: 19,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: AppSpacing.xxs),
          DeltaFigure(change: changePct, fontSize: 12),
        ],
      ),
    );
  }
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
