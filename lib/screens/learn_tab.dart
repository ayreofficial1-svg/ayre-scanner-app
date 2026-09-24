import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_stat_tile.dart';
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
///
/// v5 (redesign plan Phase 5): eyebrow / title / subhead header, two stat tiles
/// (the shared [AyreStatTile]), a subject filter row, the calm centered empty
/// and failed states ([CalmStatePanel]), and a static footer info card.
///
/// **The filter pills are the feed's real subjects, not a fixed set.** The
/// reference image's All / Basics / Technical / Fundamental / Psychology are
/// example labels; the backend's `category` is free text (and null on most
/// articles), so the row is built from whatever categories the loaded courses
/// actually carry, and hidden while there is nothing to choose between.
class LearnTab extends StatefulWidget {
  const LearnTab({super.key, required this.marketData, this.active = true});

  final MarketDataService marketData;

  /// See [SignalsTab.active] — defers this tab's first load until it's
  /// actually selected, instead of firing on shell mount alongside every
  /// other tab.
  final bool active;

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  DataResult<List<Course>>? _result;
  bool _loading = true;

  /// The selected subject filter; null means "All".
  String? _category;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load(initial: true);
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  /// Fired once, shortly after the app returns to the foreground. Reloads
  /// silently if the app was away long enough for the library to be out of
  /// date.
  void _onAppResumed() {
    if (!mounted || !widget.active || _result == null) return;
    if (AppLifecycleService.instance.lastAway < const Duration(seconds: 30)) {
      return;
    }
    _load(initial: true);
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    super.dispose();
  }

  @override
  void didUpdateWidget(LearnTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && _result == null) {
      _load(initial: true);
    }
  }

  Future<void> _load({bool initial = false}) async {
    final fetched = await widget.marketData.getCourses();
    if (!mounted) return;
    final result = fetched.keepingLastGood(_result);
    setState(() {
      _result = result;
      _loading = false;
      // A refresh can drop a subject entirely; a filter left pointing at it
      // would show an empty library with no way to see why.
      final subjects =
          result.value?.map((c) => c.category).toSet() ?? const <String>{};
      if (_category != null && !subjects.contains(_category)) _category = null;
    });
    if (!initial) HapticFeedback.mediumImpact();
  }

  /// Distinct subjects in first-seen order.
  List<String> get _subjects {
    final courses = _result?.value;
    if (courses == null) return const [];
    return courses.map((c) => c.category).toSet().toList();
  }

  void _selectSubject(String? subject) {
    if (subject == _category) return;
    HapticFeedback.selectionClick();
    setState(() => _category = subject);
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
    final subjects = _subjects;
    final columns = AppBreakpoints.columns(context);
    final resume = _inProgress;
    // Counts read "—" until the library has actually answered: a "0 Courses"
    // tile during the first load, or after a failure, would state something
    // the app doesn't know.
    final countsKnown = !_loading && _result != null && !_result!.isFailed;
    final showLibrary = !_loading && _result!.isReady && courses.isNotEmpty;
    final visible = _category == null
        ? courses
        : courses.where((c) => c.category == _category).toList();

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
                    Text('Learning Hub', style: AppTypo.pageTitle(t)),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      'Understand the stock market better.',
                      style: AppTypo.body(t),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sectionGap),
            Entrance(
              index: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                // Two tiles across a tablet-width column would be mostly
                // empty card; they stay a compact pair.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Row(
                    children: [
                      Expanded(
                        child: AyreStatTile(
                          value: countsKnown ? '${subjects.length}' : '—',
                          label: 'Subjects',
                        ),
                      ),
                      const SizedBox(width: AppSpace.cardGap),
                      Expanded(
                        child: AyreStatTile(
                          value: countsKnown ? '${courses.length}' : '—',
                          label: 'Courses',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (resume != null) ...[
              const SizedBox(height: AppSpace.sectionGap),
              Entrance(
                index: 2,
                child: _ContinueCard(
                  course: resume,
                  onTap: () => _open(resume),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.sectionGap),
            if (showLibrary)
              const Entrance(index: 3, child: SectionLabel(label: 'Library')),
            // Nothing to choose between with a single subject, so no filter.
            if (showLibrary && subjects.length > 1) ...[
              Entrance(
                index: 3,
                child: _SubjectFilter(
                  subjects: subjects,
                  selected: _category,
                  onSelected: _selectSubject,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            _list(columns, visible),
            const SizedBox(height: AppSpace.sectionGap),
            const Entrance(index: 4, child: _LearnFooter()),
          ],
        ),
      ),
    );
  }

  Widget _list(int columns, List<Course> courses) {
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
      return CalmStatePanel.failed(
        headline: "Your library didn't load",
        message: 'Progress you have already made is kept.',
        onRetry: _load,
      );
    }

    if (_result!.isEmpty) {
      return CalmStatePanel.empty(
        headline: 'No lessons yet',
        message: 'New material appears here as the library grows.',
        onRetry: _load,
      );
    }

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
    ).push(terminalRoute(builder: (_) => LessonScreen(course: course)));
  }
}

// ─── Subject filter ────────────────────────────────────────────────────────

/// The horizontal pill row (§2.3): "All", then one pill per subject in the
/// loaded library. The active pill is the solid-accent [AyreFilterChip] the
/// app already uses for Signals' filters — same component, same 44pt target,
/// same not-colour-only selected state.
class _SubjectFilter extends StatelessWidget {
  const _SubjectFilter({
    required this.subjects,
    required this.selected,
    required this.onSelected,
  });

  final List<String> subjects;

  /// The selected subject, or null for "All".
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Not clipped: pills scroll out through the page's side padding to the
      // screen edge instead of being cut off a page-margin short of it.
      clipBehavior: Clip.none,
      child: Row(
        children: [
          AyreFilterChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final subject in subjects) ...[
            const SizedBox(width: AppSpace.xs),
            AyreFilterChip(
              label: subject,
              selected: subject == selected,
              onTap: () => onSelected(subject),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Footer ────────────────────────────────────────────────────────────────

/// The short line at the foot of the page: one plain sentence saying what
/// this tab is. Not a warning card, and not a course platform — just
/// reading material about the stock market.
class _LearnFooter extends StatelessWidget {
  const _LearnFooter();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Text(
        'Learn how the market works.',
        textAlign: TextAlign.center,
        style: AppTypo.hint(t, color: t.foregroundMuted),
      ),
    );
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

    return Semantics(
      button: true,
      label: 'Continue, ${course.title}, '
          '${course.lessonsDone} of ${course.lessonsTotal} lessons',
      excludeSemantics: true,
      child: AyreCard(
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

    // Phase 5: grouped announcement (title, category, completion, progress).
    final buf = StringBuffer(course.title);
    buf.write(', ${course.category}');
    if (complete) {
      buf.write(', complete');
    } else if (progress != null) {
      buf.write(', ${course.lessonsDone} of ${course.lessonsTotal} lessons');
    }

    return Semantics(
      button: true,
      label: buf.toString(),
      excludeSemantics: true,
      child: PressableScaleRow(
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
      ),
    );
  }
}