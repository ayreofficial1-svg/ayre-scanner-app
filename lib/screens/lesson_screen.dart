import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';

/// The destination behind a course row. The list truncates the body to stay
/// scannable; this shows it in full, which is what the chevron has always implied.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = course.progress;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(course.category),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          children: [
            // Wraps rather than overflowing at large text scales — the header
            // row that broke in the previous build.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: [
                AyreIcon(AyreGlyph.course, size: 16, color: t.textTertiary),
                Text(course.category.toUpperCase(), style: AppTypo.label(t)),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Text(course.title, style: AppTypo.pageTitle(t)),
            if (progress != null) ...[
              const SizedBox(height: AppSpace.md),
              ProgressRule(value: progress),
              const SizedBox(height: AppSpace.xs),
              Figure.static(
                '${course.lessonsDone}/${course.lessonsTotal} lessons complete',
                fontSize: 11,
                color: t.textTertiary,
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            const HairlineDivider(),
            const SizedBox(height: AppSpace.lg),
            Text(
              course.body.isEmpty
                  ? 'This course has no written body yet.'
                  : course.body,
              style: AppTypo.body(t).copyWith(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
