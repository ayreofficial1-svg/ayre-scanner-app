import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_page_header.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = course.progress;

    return AyrePageScaffold(
      title: 'Lesson',
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TagPill(label: course.category),
        ),
        const SizedBox(height: AppSpace.s13),
        Semantics(
          header: true,
          child: Text(
            course.title,
            style: course.title.length > 65
                ? AppTypo.sectionTitle(t)
                : AppTypo.pageTitle(t),
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: AppSpace.s13),
          ProgressRule(value: progress),
          const SizedBox(height: AppSpace.xs),
          Text(
            '${course.lessonsDone}/${course.lessonsTotal} lessons complete',
            style: AppTypo.meta(t),
          ),
        ],
        const SizedBox(height: AppSpace.s21),
        const HairlineDivider(),
        const SizedBox(height: AppSpace.s21),
        Text(
          course.body.isEmpty
              ? 'This course has no written body yet.'
              : course.body,
          style: AppTypo.reading(t),
        ),
      ],
    );
  }
}
