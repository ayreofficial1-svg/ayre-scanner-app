import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_states.dart';
import '../widgets/numeral.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import 'lesson_screen.dart';

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
    final lessons = await ApiService.getLearnArticles();
    if (!mounted) return;
    final firstLoad = _loading;
    setState(() {
      _lessons = lessons;
      _loading = false;
    });
    if (!firstLoad) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) {
      return const PremiumLoader(
        label: 'Loading library',
        section: AyreSection.learn,
      );
    }

    final twoColumn = AppBreakpoints.usesTwoColumn(context);

    return PremiumScaffold(
      section: AyreSection.learn,
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: AnimatedEntrance(child: _LearnHero(lessons: _lessons)),
              ),
            ),
            if (_lessons.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  // Brought up to the shared template — it used to be a bare
                  // line of unstyled text while the other tabs had designed
                  // states.
                  child: AppStateMessage(
                    icon: Icons.menu_book_outlined,
                    heading: 'No lessons yet',
                    message:
                        'New material appears here as the library grows. Pull '
                        'down to check again.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  140,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: twoColumn ? 2 : 1,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 152,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: _lessons.length,
                    (context, index) => AnimatedEntrance(
                      delay: Duration(milliseconds: 40 * (index + 1)),
                      child: _LessonCard(
                        lesson: _Lesson.fromJson(_lessons[index]),
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
}

/// Learn's hero carries no ornament, same reasoning as Signals.
class _LearnHero extends StatelessWidget {
  const _LearnHero({required this.lessons});

  final List<Map<String, dynamic>> lessons;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final onHero = tokens.onPrimary;
    final subjects = lessons
        .map((lesson) => lesson['category']?.toString())
        .where((category) => category != null && category.isNotEmpty)
        .toSet()
        .length;

    return PremiumCard(
      radius: AppRadius.heroCard,
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: AppSurfaces.heroFill(AyreSection.learn, tokens),
      borderColor: tokens.primary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: 'Trading library',
            outlined: true,
            foreground: onHero,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'My courses',
            style: AppTypo.pageTitle(tokens, color: onHero),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _HeroStat(label: 'SUBJECTS', value: subjects, tone: onHero),
              const SizedBox(width: AppSpacing.xl),
              _HeroStat(label: 'LESSONS', value: lessons.length, tone: onHero),
            ],
          ),
        ],
      ),
    );
  }
}

/// Counts are figures, so they take the readout face — the all-caps label
/// beside them is a categorical micro-label in Inter.
class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final int value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Numeral(
          '$value',
          value: value.toDouble(),
          format: (v) => v.round().toString(),
          fontSize: 17,
          color: tone,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypo.microLabel(tokens, color: tone.withValues(alpha: 0.8)),
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

    return PressableScale(
      borderRadius: AppRadius.card,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LessonScreen(
              title: lesson.title,
              eyebrow: lesson.eyebrow,
              body: lesson.description,
              icon: lesson.icon,
            ),
          ),
        );
      },
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(lesson.icon, size: 20, color: tokens.accentCool),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    lesson.eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypo.microLabel(tokens),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: tokens.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              lesson.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.sectionTitle(tokens).copyWith(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: Text(
                lesson.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypo.body(tokens),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lesson {
  const _Lesson(this.title, this.eyebrow, this.description, this.icon);

  final String title;
  final String eyebrow;
  final String description;
  final IconData icon;

  factory _Lesson.fromJson(Map<String, dynamic> json) {
    return _Lesson(
      json['title']?.toString() ?? '',
      json['category']?.toString() ?? json['eyebrow']?.toString() ?? 'Lesson',
      json['body']?.toString() ?? json['description']?.toString() ?? '',
      _iconFrom(json['icon']?.toString()),
    );
  }

  static IconData _iconFrom(String? value) {
    return switch (value) {
      'shield' => Icons.shield_outlined,
      'speed' => Icons.speed_outlined,
      'school' => Icons.school_outlined,
      'psychology' => Icons.psychology_alt_outlined,
      _ => Icons.insights_outlined,
    };
  }
}
