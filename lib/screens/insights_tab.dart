import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  List<Map<String, dynamic>> _insights = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    HapticFeedback.lightImpact();
    final data = await ApiService.getSentiment();
    final insights = await ApiService.getInsights();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _insights = insights;
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
    if (_loading) return const PremiumLoader(label: 'Reading climate', section: AyreSection.insights);

    final value = _sentiment ?? 0;
    final color = _color(value, tokens);
    return PremiumScaffold(
      section: AyreSection.insights,
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 140),
          children: [
            const AnimatedEntrance(child: _InsightsHeader()),
            const SizedBox(height: AppSpacing.xxl),
            if (_error)
              const AnimatedEntrance(
                delay: Duration(milliseconds: 100),
                child: _InsightsErrorState(),
              )
            else ...[
              AnimatedEntrance(
                delay: const Duration(milliseconds: 100),
                child: _SentimentCard(value: value, color: color),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 150),
                child: _InsightNotes(
                  value: value,
                  note: _note,
                  updatedAt: _updatedAt,
                ),
              ),
              ..._insights.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: AnimatedEntrance(
                    delay: Duration(milliseconds: 200 + entry.key * 50),
                    child: _InsightContentCard(insight: entry.value),
                  ),
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

class _InsightContentCard extends StatelessWidget {
  const _InsightContentCard({required this.insight});

  final Map<String, dynamic> insight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final title = insight['title']?.toString() ?? '';
    final body = insight['body']?.toString() ?? '';
    final category = insight['category']?.toString();
    final featured = insight['featured'] == true || insight['pinned'] == true;
    
    // Softer backgrounds
    final color = featured ? tokens.accentWarm : tokens.accentCool;
    final bgColor = featured 
        ? tokens.accentWarm.withValues(alpha: 0.1) 
        : tokens.accentCool.withValues(alpha: 0.1);
    
    final foreground = featured ? tokens.accentWarm : tokens.accentCool;

    return PremiumCard(
      radius: AppRadius.card,
      color: bgColor,
      borderColor: color.withValues(alpha: 0.2),
      shadowColor: color.withValues(alpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(
              featured ? Icons.push_pin_rounded : Icons.insights_rounded,
              color: foreground,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category?.isNotEmpty == true) ...[
                  Text(
                    category!.toUpperCase(),
                    style: AppTypo.eyebrow(tokens, color: foreground),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  title,
                  style: AppTypo.cardTitle(tokens),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    style: AppTypo.body(tokens),
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
                style: AppTypo.pageTitle(tokens),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Market breadth and sentiment pulse.',
                style: AppTypo.bodyMedium(tokens, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
        GlassCircleButton(
          icon: Icons.tune_rounded,
          size: 46,
          color: tokens.surfaceAlt,
          iconColor: tokens.textPrimary,
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
      radius: AppRadius.heroCard,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      gradient: AppGradients.heroCard(AyreSection.insights, tokens),
      shadowColor: tokens.primary.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            children: [
              _BlackBadge(label: 'Weekly', selected: true),
              const SizedBox(width: AppSpacing.sm),
              _BlackBadge(label: 'Month', selected: false),
              const Spacer(),
              Text(
                _label(value),
                style: AppTypo.eyebrow(tokens, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: AppMotion.slow,
            curve: AppMotion.ease,
            builder: (context, progress, _) {
              return SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 220),
                      painter: _GaugePainter(
                        progress: progress,
                        color: color,
                        tokens: tokens,
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      child: Column(
                        children: [
                          Text(
                            '${(progress * 100).round()}',
                            style: AppTypo.heroValue(tokens, color: tokens.onPrimary).copyWith(fontSize: 56),
                          ),
                          Text(
                            'SENTIMENT SCORE',
                            style: AppTypo.caption(tokens, color: tokens.onPrimary.withValues(alpha: 0.8)),
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
                  label: 'LESSONS',
                  color: tokens.accentWarm,
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricBubble(
                  value: '12',
                  label: 'HOURS',
                  color: tokens.accentMint,
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricBubble(
                  value: '$value%',
                  label: 'PULSE',
                  color: color,
                  tokens: tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(int value) {
    if (value < 35) return 'CAUTION';
    if (value < 65) return 'NEUTRAL';
    return 'STRONG';
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
      radius: AppRadius.card,
      gradient: LinearGradient(
        colors: [
          tokens.surfaceRaised,
          Color.lerp(tokens.surfaceRaised, tokens.accentMint, 0.05)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.accentMint.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: tokens.accentMint,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
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
                  style: AppTypo.body(tokens).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (updatedAt?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Updated $updatedAt',
                    style: AppTypo.caption(tokens),
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
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected ? tokens.neutralBlock : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypo.eyebrow(tokens, color: selected ? tokens.onNeutralBlock : tokens.onPrimary),
      ),
    );
  }
}

class _MetricBubble extends StatelessWidget {
  const _MetricBubble({
    required this.value,
    required this.label,
    required this.color,
    required this.tokens,
  });

  final String value;
  final String label;
  final Color color;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypo.dataNum(tokens, color: color).copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypo.caption(tokens, color: color),
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
    final center = Offset(size.width / 2, size.height - 24);
    final radius = math.min(size.width / 2, size.height) - 32;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 24.0;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
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
    canvas.drawCircle(knob, 20, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 14, Paint()..color = color);
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
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      gradient: LinearGradient(
        colors: [
          tokens.negative,
          Color.lerp(tokens.negative, tokens.accentWarm, 0.22)!,
        ],
      ),
      shadowColor: tokens.negative.withValues(alpha: 0.3),
      child: Column(
        children: [
          FloatingOrb(
            child: Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Could not load sentiment',
            textAlign: TextAlign.center,
            style: AppTypo.sectionTitle(tokens, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pull down to retry fetching data.',
            textAlign: TextAlign.center,
            style: AppTypo.body(tokens, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
