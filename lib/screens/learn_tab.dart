import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';

class LearnTab extends StatefulWidget {
  const LearnTab({super.key});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    HapticFeedback.lightImpact();
    final lessons = await ApiService.getLearnArticles();
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) return const PremiumLoader(label: 'Loading library', section: AyreSection.learn);
    
    return PremiumScaffold(
      section: AyreSection.learn,
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 140),
          itemCount: _lessons.isEmpty ? 2 : _lessons.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return AnimatedEntrance(
                child: _LearnHero(tokens: tokens, lessons: _lessons),
              );
            }
            if (_lessons.isEmpty) {
              return const AnimatedEntrance(
                delay: Duration(milliseconds: 100),
                child: _LearnEmptyState(),
              );
            }
            return AnimatedEntrance(
              delay: Duration(milliseconds: 50 * index),
              child: _LessonCard(
                lesson: _Lesson.fromJson(_lessons[index - 1]),
                tokens: tokens,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LearnHero extends StatelessWidget {
  const _LearnHero({required this.tokens, required this.lessons});

  final AppThemeTokens tokens;
  final List<Map<String, dynamic>> lessons;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AppRadius.heroCard,
      padding: EdgeInsets.zero,
      gradient: AppGradients.heroCard(AyreSection.learn, tokens),
      shadowColor: tokens.accentWarm.withValues(alpha: 0.25),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -50,
              child: Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 30,
              child: Transform.rotate(
                angle: -0.2,
                child: FloatingOrb(
                  child: Icon(
                    Icons.school_rounded,
                    size: 96,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroChip(tokens: tokens),
                  const Spacer(),
                  Text(
                    'My courses',
                    style: AppTypo.pageTitle(tokens, color: tokens.onPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _HeroStat(
                        label: 'SUBJECTS',
                        value: lessons
                            .map((lesson) => lesson['category']?.toString())
                            .where((category) => category?.isNotEmpty == true)
                            .toSet()
                            .length
                            .toString(),
                        tokens: tokens,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _HeroStat(
                        label: 'LESSONS',
                        value: lessons.length.toString(),
                        tokens: tokens,
                      ),
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

class _LearnEmptyState extends StatelessWidget {
  const _LearnEmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      gradient: AppGradients.surfaceGlass(tokens),
      child: Text(
        'No lessons available.',
        textAlign: TextAlign.center,
        style: AppTypo.sectionTitle(tokens),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.neutralBlock,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'TRADING LIBRARY',
        style: AppTypo.eyebrow(tokens, color: tokens.onNeutralBlock),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: AppTypo.dataNum(tokens, color: Colors.white).copyWith(fontSize: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypo.eyebrow(tokens, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.tokens});

  final _Lesson lesson;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(tokens, lesson.tone);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Create a softer card background instead of solid color
    final cardBg = isDark 
        ? colors.fill.withValues(alpha: 0.15) 
        : colors.fill.withValues(alpha: 0.1);
        
    final iconBg = colors.foreground.withValues(alpha: 0.15);

    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: PremiumCard(
        radius: AppRadius.card,
        padding: EdgeInsets.zero,
        color: cardBg,
        borderColor: colors.fill.withValues(alpha: 0.3),
        shadowColor: colors.fill.withValues(alpha: 0.1),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -50,
              child: Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.foreground.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBg,
                    ),
                    child: Icon(
                      lesson.icon,
                      color: colors.foreground,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            lesson.eyebrow.toUpperCase(),
                            style: AppTypo.eyebrow(tokens, color: colors.foreground),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          lesson.title,
                          style: AppTypo.cardTitle(tokens).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          lesson.description,
                          style: AppTypo.body(tokens),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.foreground,
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDark ? tokens.background : Colors.white,
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
        tokens.accentWarm,
      ),
      _LessonTone.dark => _LessonColors(
        tokens.primary,
        Color.lerp(tokens.primary, tokens.teal2, 0.12)!,
        tokens.primary,
      ),
      _LessonTone.mint => _LessonColors(
        tokens.accentMint,
        Color.lerp(tokens.accentMint, tokens.accentCool, 0.26)!,
        tokens.accentMint,
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

  factory _Lesson.fromJson(Map<String, dynamic> json) {
    return _Lesson(
      json['title']?.toString() ?? '',
      json['category']?.toString() ??
          json['eyebrow']?.toString() ??
          'Lesson',
      json['body']?.toString() ??
          json['description']?.toString() ??
          '',
      _iconFrom(json['icon']?.toString()),
      _toneFrom(json['tone']?.toString()),
    );
  }

  static IconData _iconFrom(String? value) {
    return switch (value) {
      'shield' => Icons.shield_rounded,
      'speed' => Icons.speed_rounded,
      'school' => Icons.school_rounded,
      'psychology' => Icons.psychology_alt_rounded,
      _ => Icons.auto_graph_rounded,
    };
  }

  static _LessonTone _toneFrom(String? value) {
    return switch (value) {
      'dark' => _LessonTone.dark,
      'mint' => _LessonTone.mint,
      _ => _LessonTone.orange,
    };
  }
}

class _LessonColors {
  const _LessonColors(this.fill, this.fill2, this.foreground);

  final Color fill;
  final Color fill2;
  final Color foreground;
}

enum _LessonTone { orange, dark, mint }
