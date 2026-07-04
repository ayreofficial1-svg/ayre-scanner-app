import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  static const _lessons = [
    _Lesson(
      'Read the Setup',
      '12 min',
      'Trend, level, trigger, and clean invalidation.',
      Icons.auto_graph_rounded,
      _LessonTone.orange,
    ),
    _Lesson(
      'Risk First',
      'Core',
      'Position sizing that keeps decisions calm.',
      Icons.shield_rounded,
      _LessonTone.dark,
    ),
    _Lesson(
      'Momentum Check',
      '8 min',
      'Confirm breadth before chasing candles.',
      Icons.speed_rounded,
      _LessonTone.mint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumScaffold(
      bottomSafe: false,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 124),
        itemCount: _lessons.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0)
            return AnimatedEntrance(child: _LearnHero(tokens: tokens));
          return AnimatedEntrance(
            delay: Duration(milliseconds: 60 * index),
            child: _LessonCard(lesson: _lessons[index - 1]),
          );
        },
      ),
    );
  }
}

class _LearnHero extends StatelessWidget {
  const _LearnHero({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 44,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          tokens.accentCool,
          Color.lerp(tokens.accentCool, tokens.negative, 0.32)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: tokens.accentCool.withValues(alpha: 0.28),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -42,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: 34,
              child: Transform.rotate(
                angle: -0.25,
                child: FloatingOrb(
                  child: Icon(
                    Icons.school_rounded,
                    size: 88,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroChip(tokens: tokens),
                  const Spacer(),
                  Text(
                    'My courses',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _HeroStat(label: 'Subjects', value: '12', tokens: tokens),
                      const SizedBox(width: 10),
                      _HeroStat(label: 'Lessons', value: '43', tokens: tokens),
                    ],
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.tokens});

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
        'Trading library',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: tokens.onNeutralBlock,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String label;
  final String value;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});

  final _Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = _colors(tokens, lesson.tone);
    return PressableScale(
      onTap: () {},
      child: PremiumCard(
        radius: 36,
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          colors: [colors.fill, colors.fill2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: colors.fill.withValues(alpha: 0.28),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -40,
              child: Container(
                height: 132,
                width: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.foreground.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.foreground.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      lesson.icon,
                      color: colors.foreground,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.foreground.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            lesson.eyebrow,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.foreground,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colors.foreground,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          lesson.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.foreground.withValues(
                                  alpha: 0.74,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.foreground,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.fill,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _LessonColors _colors(AppThemeTokens tokens, _LessonTone tone) {
    return switch (tone) {
      _LessonTone.orange => _LessonColors(
        tokens.accentWarm,
        Color.lerp(tokens.accentWarm, tokens.negative, 0.2)!,
        tokens.onAccentWarm,
      ),
      _LessonTone.dark => _LessonColors(
        tokens.neutralBlock,
        Color.lerp(tokens.neutralBlock, tokens.primary, 0.12)!,
        tokens.onNeutralBlock,
      ),
      _LessonTone.mint => _LessonColors(
        tokens.accentMint,
        Color.lerp(tokens.accentMint, tokens.accentCool, 0.26)!,
        tokens.onAccentMint,
      ),
    };
  }
}

class _Lesson {
  const _Lesson(
    this.title,
    this.eyebrow,
    this.description,
    this.icon,
    this.tone,
  );

  final String title;
  final String eyebrow;
  final String description;
  final IconData icon;
  final _LessonTone tone;
}

class _LessonColors {
  const _LessonColors(this.fill, this.fill2, this.foreground);

  final Color fill;
  final Color fill2;
  final Color foreground;
}

enum _LessonTone { orange, dark, mint }
