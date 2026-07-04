import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  int? _sentiment;
  String? _note;
  String? _updatedAt;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.getSentiment();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data != null && data['sentiment'] is num) {
        _error = false;
        _sentiment = (data['sentiment'] as num).round().clamp(0, 100);
        _note = data['note']?.toString();
        _updatedAt = data['updated_at']?.toString();
      } else {
        _error = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) return const PremiumLoader(label: 'Reading climate');

    final value = _sentiment ?? 0;
    final color = _color(value, tokens);
    return PremiumScaffold(
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 124),
          children: [
            const AnimatedEntrance(child: _InsightsHeader()),
            const SizedBox(height: 16),
            if (_error)
              const AnimatedEntrance(
                delay: Duration(milliseconds: 80),
                child: _InsightsErrorState(),
              )
            else ...[
              AnimatedEntrance(
                delay: const Duration(milliseconds: 80),
                child: _SentimentCard(value: value, color: color),
              ),
              const SizedBox(height: 16),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 140),
                child: _InsightNotes(
                  value: value,
                  note: _note,
                  updatedAt: _updatedAt,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _color(int value, AppThemeTokens tokens) {
    if (value < 35) return tokens.negative;
    if (value < 65) return tokens.accentWarm;
    return tokens.positive;
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Market breadth and sentiment pulse.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        GlassCircleButton(
          icon: Icons.tune_rounded,
          size: 48,
          color: tokens.surface,
        ),
      ],
    );
  }
}

class _SentimentCard extends StatelessWidget {
  const _SentimentCard({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: 44,
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        colors: [tokens.surface, tokens.surfaceRaised],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _BlackBadge(label: 'Weekly', selected: true),
              const SizedBox(width: 8),
              _BlackBadge(label: 'Month', selected: false),
              const Spacer(),
              Text(
                _label(value),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: AppMotion.slow,
            curve: AppMotion.ease,
            builder: (context, progress, _) {
              return SizedBox(
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 210),
                      painter: _GaugePainter(
                        progress: progress,
                        color: color,
                        tokens: tokens,
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      child: Column(
                        children: [
                          Text(
                            '${(progress * 100).round()}',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontSize: 58,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'sentiment score',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: tokens.textSecondary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: _MetricBubble(
                  value: '48',
                  label: 'lessons',
                  color: tokens.accentWarm,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBubble(
                  value: '12',
                  label: 'hours',
                  color: tokens.accentCool,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBubble(
                  value: '$value%',
                  label: 'pulse',
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(int value) {
    if (value < 35) return 'Caution';
    if (value < 65) return 'Neutral';
    return 'Strong';
  }
}

class _InsightNotes extends StatelessWidget {
  const _InsightNotes({
    required this.value,
    required this.note,
    required this.updatedAt,
  });

  final int value;
  final String? note;
  final String? updatedAt;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          tokens.accentMint,
          Color.lerp(tokens.accentMint, tokens.accentCool, 0.36)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: tokens.accentMint.withValues(alpha: 0.28),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.neutralBlock,
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: tokens.onNeutralBlock,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note?.isNotEmpty == true
                      ? note!
                      : 'Scanner climate is ${value >= 65
                            ? 'constructive'
                            : value < 35
                            ? 'defensive'
                            : 'balanced'} today.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.onAccentMint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (updatedAt?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Updated $updatedAt',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.onAccentMint.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlackBadge extends StatelessWidget {
  const _BlackBadge({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedContainer(
      duration: AppMotion.medium,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? tokens.neutralBlock : tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected ? tokens.onNeutralBlock : tokens.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricBubble extends StatelessWidget {
  const _MetricBubble({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.color,
    required this.tokens,
  });

  final double progress;
  final Color color;
  final AppThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 22);
    final radius = math.min(size.width / 2, size.height) - 28;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 20.0;

    final trackPaint = Paint()
      ..color = tokens.surfaceAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    final gradientPaint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * 2,
        colors: [tokens.negative, tokens.accentWarm, tokens.positive],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * progress, false, gradientPaint);

    final angle = math.pi + math.pi * progress;
    final knob = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(knob, 17, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 12, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _InsightsErrorState extends StatelessWidget {
  const _InsightsErrorState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.all(26),
      gradient: LinearGradient(
        colors: [
          tokens.negative,
          Color.lerp(tokens.negative, tokens.accentWarm, 0.22)!,
        ],
      ),
      shadowColor: tokens.negative.withValues(alpha: 0.28),
      child: Column(
        children: [
          FloatingOrb(
            child: Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Could not load sentiment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to retry fetching data.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
