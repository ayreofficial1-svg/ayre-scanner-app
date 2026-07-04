import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

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

  String _label(int value) {
    if (value < 35) return 'Caution';
    if (value < 65) return 'Neutral';
    return 'Strong';
  }

  Color _color(int value, AppThemeTokens tokens) {
    if (value < 35) return tokens.negative;
    if (value < 65) return tokens.accentWarm;
    return tokens.positive;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (_loading) {
      return const _InsightsLoading();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.background, tokens.backgroundTint],
        ),
      ),
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xl + 104,
          ),
          children: [
            Text(
              'Market Sentiment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error)
              _InsightsErrorState()
            else
              _SentimentGauge(
                value: _sentiment!,
                color: _color(_sentiment!, tokens),
                tokens: tokens,
              ),
            if (!_error) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _label(_sentiment!),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _color(_sentiment!, tokens),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$_sentiment / 100',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_note != null && _note!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _note!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_updatedAt != null && _updatedAt!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Updated $_updatedAt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightsLoading extends StatelessWidget {
  const _InsightsLoading();

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

class _SentimentGauge extends StatelessWidget {
  const _SentimentGauge({
    required this.value,
    required this.color,
    required this.tokens,
  });

  final int value;
  final Color color;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: AppMotion.slow,
      curve: AppMotion.ease,
      builder: (context, animatedValue, child) {
        final displayValue = animatedValue.round();
        return SizedBox(
          height: 180,
          child: CustomPaint(
            size: const Size(double.infinity, 180),
            painter: _GaugePainter(
              value: displayValue,
              color: color,
              tokens: tokens,
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.tokens,
  });

  final int value;
  final Color color;
  final AppThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = math.min(size.width / 2, size.height) - 22;

    const strokeWidth = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final segments = [
      (tokens.negative, 0.0, 1 / 3),
      (tokens.accentWarm, 1 / 3, 2 / 3),
      (tokens.positive, 2 / 3, 1.0),
    ];

    for (final (segColor, start, end) in segments) {
      final paint = Paint()
        ..color = segColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        math.pi + start * math.pi,
        (end - start) * math.pi,
        false,
        paint,
      );
    }

    final angle = math.pi + (value / 100) * math.pi;
    final needleLength = radius - strokeWidth / 2;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawLine(center, needleEnd, glowPaint);

    final needlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    final hubPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _InsightsErrorState extends StatelessWidget {
  const _InsightsErrorState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg + 2),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: tokens.border),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.negative.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded,
                    color: tokens.negative, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Could not load sentiment',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pull down to retry fetching data.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.refresh_rounded,
                  color: tokens.textSecondary, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}