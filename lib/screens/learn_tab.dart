import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';
import 'lesson_screen.dart';

/// Learn — the trading library.
///
/// Flat list rows with a progress readout. The open-book motif is gone; counters
/// are figures, so they take the ticker face.
class LearnTab extends StatefulWidget {
  const LearnTab({super.key, required this.marketData});

  final MarketDataService marketData;

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  DataResult<List<Course>>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    final result = await widget.marketData.getCourses();
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
    if (!initial) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final courses = _result?.value ?? const <Course>[];
    final subjects = courses.map((c) => c.category).toSet().length;
    final columns = AppBreakpoints.columns(context);

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
        maxWidth: columns > 1 ? 960 : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
            120,
          ),
          children: [
            SafeArea(
              bottom: false,
              child: Entrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRADING LIBRARY', style: AppTypo.label(t)),
                    const SizedBox(height: AppSpace.xs),
                    Text('My courses', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        LabelledFigure(
                          label: 'Subjects',
                          value: '$subjects',
                          fontSize: 16,
                        ),
                        const SizedBox(width: AppSpace.xxl),
                        LabelledFigure(
                          label: 'Courses',
                          value: '${courses.length}',
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            if (_loading)
              const AyreCard(
                padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Column(
                  children: [
                    SkeletonTickerRow(),
                    SkeletonTickerRow(),
                    SkeletonTickerRow(),
                  ],
                ),
              )
            else if (_result!.isFailed)
              StatePanel.failed(
                headline: "Your library didn't load",
                message: 'Pull down to check again.',
              )
            else if (_result!.isEmpty)
              const StatePanel.empty(
                headline: 'No lessons yet',
                message: 'New material appears here as the library grows.',
              )
            else if (columns == 1)
              AyreCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, course) in courses.indexed) ...[
                      if (i > 0) const HairlineDivider(indent: AppSpace.md),
                      _CourseRow(course: course, onTap: () => _open(course)),
                    ],
                  ],
                ),
              )
            else
              // Learn is a list of self-contained, independently-scannable items,
              // so it goes multi-column once the viewport genuinely fits it.
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: courses.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpace.md,
                  crossAxisSpacing: AppSpace.md,
                  // Height driven by content rather than a fixed extent, so a
                  // large accessibility text scale grows the tile instead of
                  // overflowing it.
                  childAspectRatio: 2.4,
                ),
                itemBuilder: (context, index) => AyreCard(
                  padding: EdgeInsets.zero,
                  child: _CourseRow(
                    course: courses[index],
                    onTap: () => _open(courses[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _open(Course course) {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LessonScreen(course: course)));
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = course.progress;

    return PressableScaleRow(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AyreIcon(AyreGlyph.course, size: 17, color: t.textTertiary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    course.category.toUpperCase(),
                    style: AppTypo.label(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AyreIcon(AyreGlyph.forward, size: 14, color: t.textTertiary),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              course.title,
              style: AppTypo.cardTitle(t),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpace.sm),
              ProgressRule(value: progress),
              const SizedBox(height: AppSpace.xs),
              Figure.static(
                '${course.lessonsDone}/${course.lessonsTotal} lessons',
                fontSize: 11,
                color: t.textTertiary,
              ),
            ] else if (course.body.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                course.body,
                style: AppTypo.body(t),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row-shaped tap target with press feedback and no rounded clip of its own,
/// so it sits flush inside a [RowGroup] or a card.
class PressableScaleRow extends StatelessWidget {
  const PressableScaleRow({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: context.tokens.accent.withValues(alpha: 0.05),
        splashColor: context.tokens.accent.withValues(alpha: 0.06),
        highlightColor: context.tokens.accent.withValues(alpha: 0.03),
        child: child,
      ),
    );
  }
}
