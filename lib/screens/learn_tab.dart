import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';
import 'lesson_screen.dart';

/// Learn — the trading library (Spec §13.4).
///
/// Rebuilt in Phase 5 to §13.4's two parts: a continue card carrying a
/// [ProgressRing], and a course list that animates its own completion state
/// change.
///
/// v3 listed every course identically and left the user to find where they
/// were. The continue card fixes that — the thing you were last doing gets the
/// ring and the top of the page, everything else is a list beneath it.
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

  /// The course to continue: the one furthest along that isn't finished. A
  /// completed course is not something to continue, and an untouched one isn't
  /// something to *resume* — so if nothing is part-done there is no continue
  /// card, and the page is just the list.
  Course? get _inProgress {
    final courses = _result?.value;
    if (courses == null) return null;
    Course? best;
    for (final course in courses) {
      final p = course.progress;
      if (p == null || p <= 0 || p >= 1) continue;
      if (best == null || p > best.progress!) best = course;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final courses = _result?.value ?? const <Course>[];
    final subjects = courses.map((c) => c.category).toSet().length;
    final columns = AppBreakpoints.columns(context);
    final resume = _inProgress;

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
        maxWidth: columns > 1 ? 960 : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.pageHorizontal,
            AppSpace.pageTop,
            AppSpace.pageHorizontal,
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
                    const SizedBox(height: AppSpace.xxs),
                    Text('My courses', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        LabelledFigure(
                          label: 'Subjects',
                          value: '$subjects',
                          fontSize: AppTextScale.cardTitle,
                        ),
                        const SizedBox(width: AppSpace.xxl),
                        LabelledFigure(
                          label: 'Courses',
                          value: '${courses.length}',
                          fontSize: AppTextScale.cardTitle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (resume != null) ...[
              const SizedBox(height: AppSpace.sectionGap),
              Entrance(
                index: 1,
                child: _ContinueCard(
                  course: resume,
                  onTap: () => _open(resume),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.sectionGap),
            if (!_loading && _result!.isReady && courses.isNotEmpty)
              const Entrance(index: 2, child: SectionLabel(label: 'Library')),
            _list(columns),
          ],
        ),
      ),
    );
  }

  Widget _list(int columns) {
    if (_loading) {
      return const AyreCard(
        padding: EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: Column(
          children: [
            SkeletonTickerRow(),
            SkeletonTickerRow(),
            SkeletonTickerRow(),
          ],
        ),
      );
    }

    if (_result!.isFailed) {
      return StatePanel.failed(
        headline: "Your library didn't load",
        message: 'Progress you have already made is kept.',
        onRetry: _load,
      );
    }

    if (_result!.isEmpty) {
      return const StatePanel.empty(
        headline: 'No lessons yet',
        message: 'New material appears here as the library grows.',
      );
    }

    final courses = _result!.value!;

    if (columns == 1) {
      return Entrance(
        index: 3,
        child: RowGroup(
          children: [
            for (final course in courses)
              _CourseRow(course: course, onTap: () => _open(course)),
          ],
        ),
      );
    }

    // Learn is a list of self-contained, independently-scannable items, so it
    // goes multi-column once the viewport genuinely fits it.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: courses.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpace.cardGap,
        crossAxisSpacing: AppSpace.cardGap,
        // Height driven by ratio rather than a fixed extent, so a large
        // accessibility text scale grows the tile instead of overflowing it.
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) => AyreCard(
        padding: EdgeInsets.zero,
        child: _CourseRow(
          course: courses[index],
          onTap: () => _open(courses[index]),
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

// ─── Continue card ─────────────────────────────────────────────────────────

/// §13.4's continue card: the ring, the course, and one clear action.
///
/// The ring is the reason this card exists rather than being another list row
/// — a proportion read as a shape is the one thing a row of text can't do, and
/// it's the same argument the breadth donut makes on Home.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = course.progress ?? 0;

    return AyreCard(
      onTap: onTap,
      accentEdge: true,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgressRing(value: progress),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CONTINUE',
                  style: AppTypo.label(t, color: t.accentInk),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  course.title,
                  style: AppTypo.cardTitle(t),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xxs),
                Figure.static(
                  '${course.lessonsDone} of ${course.lessonsTotal} lessons',
                  fontSize: AppTextScale.hint,
                  color: t.foregroundMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          AyreIcon(AyreGlyph.forward, size: 16, color: t.accentInk),
        ],
      ),
    );
  }
}

// ─── Course row ────────────────────────────────────────────────────────────

class _CourseRow extends StatelessWidget {
  const _CourseRow({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final progress = course.progress;
    final complete = progress != null && progress >= 1;

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
                // §13.4's completion state change. Not a colour swap on its
                // own: the glyph itself changes from a course marker to a
                // check, so "finished" survives with colour removed, and the
                // swap crossfades on the Ayre ease rather than cutting. This
                // is the one animated state change on this screen, which is
                // what makes it read as an event rather than as decoration.
                AnimatedSwitcher(
                  duration: AppMotion.pageTransition,
                  switchInCurve: AppMotion.ease,
                  switchOutCurve: AppMotion.ease,
                  child: AyreIcon(
                    complete ? AyreGlyph.check : AyreGlyph.course,
                    key: ValueKey(complete),
                    size: 17,
                    color: complete ? t.positive : t.foregroundSubtle,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    course.category.toUpperCase(),
                    style: AppTypo.label(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (complete) ...[
                  const ShrinkTrailing(
                    child: AyreChip(label: 'Complete', tone: ChipTone.neutral),
                  ),
                  const SizedBox(width: AppSpace.xs),
                ],
                AyreIcon(
                  AyreGlyph.forward,
                  size: 14,
                  color: t.foregroundSubtle,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              course.title,
              style: AppTypo.cardTitle(t),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpace.sm),
              // The rule animates to its value and re-tints on completion, so
              // finishing a lesson is visible as movement when you come back
              // to this list rather than as a bar that was simply already
              // full.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.chartDraw,
                curve: AppMotion.ease,
                builder: (context, value, _) => ProgressRule(
                  value: value,
                  color: complete ? t.positive : null,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Figure.static(
                '${course.lessonsDone}/${course.lessonsTotal} lessons',
                fontSize: AppTextScale.hint,
                color: complete ? t.positive : t.foregroundSubtle,
              ),
            ] else if (course.body.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xxs),
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