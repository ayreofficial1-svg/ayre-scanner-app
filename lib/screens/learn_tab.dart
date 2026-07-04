import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  static const _lessons = [
    _Lesson(
      title: 'Read the Setup',
      eyebrow: '5 min',
      description: 'Translate trend, level, and trigger into a clean trade idea.',
      icon: Icons.auto_graph_rounded,
      tone: _LessonTone.warm,
    ),
    _Lesson(
      title: 'Risk Before Reward',
      eyebrow: 'Core',
      description: 'Size positions around invalidation instead of conviction.',
      icon: Icons.shield_rounded,
      tone: _LessonTone.dark,
    ),
    _Lesson(
      title: 'Momentum Check',
      eyebrow: '3 min',
      description: 'Use market breadth and price action to avoid late entries.',
      icon: Icons.speed_rounded,
      tone: _LessonTone.positive,
    ),
  ];

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
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xl + 104,
        ),
        itemCount: _lessons.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _LearnHeader();
          }
          return _LessonCard(lesson: _lessons[index - 1]);
        },
      ),
    );
  }
}

class _LearnHeader extends StatelessWidget {
  const _LearnHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learn',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Short lessons for reading scanner ideas with calmer execution.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});

  final _Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = _colorsFor(tokens, lesson.tone);

    return PressableScale(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.fill, colors.fill.withValues(alpha: 0.92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colors.fill.withValues(alpha: 0.25),
              blurRadius: 22,
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
                    _LessonBadge(label: lesson.eyebrow, fill: colors.pill),
                    const Spacer(),
                    Icon(lesson.icon, color: colors.foreground, size: 28),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  lesson.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.85),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _LessonButton(colors: colors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _LessonColors _colorsFor(AppThemeTokens tokens, _LessonTone tone) {
    return switch (tone) {
      _LessonTone.warm => _LessonColors(
          fill: tokens.accentWarm,
          foreground: tokens.onAccentWarm,
          pill: tokens.neutralBlock,
        ),
      _LessonTone.dark => _LessonColors(
          fill: tokens.neutralBlock,
          foreground: tokens.onNeutralBlock,
          pill: tokens.accentWarm,
        ),
      _LessonTone.positive => _LessonColors(
          fill: tokens.positive,
          foreground: tokens.onPositive,
          pill: tokens.neutralBlock,
        ),
    };
  }
}

class _LessonBadge extends StatelessWidget {
  const _LessonBadge({required this.label, required this.fill});

  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final onLabel = Theme.of(context).brightness == Brightness.dark
        ? tokens.onNeutralBlock
        : tokens.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: onLabel,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _LessonButton extends StatelessWidget {
  const _LessonButton({required this.colors});

  final _LessonColors colors;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final onLabel = colors.pill == tokens.neutralBlock
        ? tokens.onNeutralBlock
        : tokens.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: colors.pill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 2,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Start Learning',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: onLabel,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: onLabel.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: onLabel,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _Lesson {
  const _Lesson({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String eyebrow;
  final String description;
  final IconData icon;
  final _LessonTone tone;
}

class _LessonColors {
  const _LessonColors({
    required this.fill,
    required this.foreground,
    required this.pill,
  });

  final Color fill;
  final Color foreground;
  final Color pill;
}

enum _LessonTone { warm, dark, positive }