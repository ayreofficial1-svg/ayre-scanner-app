import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_charts.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_masthead.dart';
import '../widgets/ayre_stat_tile.dart';
import '../widgets/figure.dart';
import '../widgets/ayre_tab_scroll.dart';
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
  const LearnTab({
    super.key,
    required this.marketData,
    this.active = true,
    this.scrollController,
  });

  final MarketDataService marketData;

  /// See [HomeTab.active] — defers this tab's first load until it's
  /// actually selected, instead of firing on shell mount alongside every
  /// other tab.
  final bool active;

  /// Optional controller for the tab's scroll view (A2: re-tap scrolls to
  /// top). Null keeps the previous behaviour.
  final ScrollController? scrollController;

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  DataResult<List<Course>>? _result;
  bool _loading = true;

  /// The selected subject filter; null means "All".
  String? _category;
  bool _hasShownCourses = false;
  bool _animateCourses = false;

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
    setState(() {
      final result = fetched.keepingLastGood(_result);
      final hasCourses = result.value?.isNotEmpty == true;
      _result = fetched.isFailed && result.isReady
          ? DataResult.ready(result.value, stale: true)
          : result;
      _animateCourses =
          hasCourses && !_hasShownCourses && !result.stale && !fetched.isFailed;
      _hasShownCourses = _hasShownCourses || hasCourses;
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
    setState(() {
      _category = subject;
      _animateCourses = false;
    });
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
    const tone = AyreMastTone.learn;
    final p = tone.paletteOf(t);
    final courses = _result?.value ?? const <Course>[];
    final subjects = _subjects;
    final columns = AppBreakpoints.columns(context);
    final resume = _inProgress;
    final countsKnown = !_loading && _result != null && !_result!.isFailed;
    final showLibrary = !_loading && _result!.isReady && courses.isNotEmpty;
    final visible = _category == null
        ? courses
        : courses.where((course) => course.category == _category).toList();
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.expand;

    return AyreTabScroll(
      eager: true,
      controller: widget.scrollController,
      onRefresh: _load,
      maxWidth: columns > 1 ? 960 : null,
      header: AyreMastScaffold(
        mast: AyreMasthead.tab(
          tone: tone,
          overlap: AppShape.mastOverlap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Learning Hub',
                  style: AppTypo.pageTitle(t, color: p.ink),
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                'Understand the stock market better.',
                style: AppTypo.subtitle(t, color: p.muted),
              ),
            ],
          ),
        ),
        overlapChild: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AyreStatTile(
                  value: countsKnown ? '${subjects.length}' : '—',
                  label: 'Subjects',
                  animate: _result?.stale != true,
                ),
              ),
              const SizedBox(width: AppSpace.cardGap),
              Expanded(
                child: AyreStatTile(
                  value: countsKnown ? '${courses.length}' : '—',
                  label: 'Courses',
                  animate: _result?.stale != true,
                ),
              ),
            ],
          ),
        ),
      ),
      children: [
        if (_result?.stale == true) ...[
          const SizedBox(height: AppSpace.s13),
          Text('Showing the last available lessons.', style: AppTypo.meta(t)),
        ],
        if (resume != null) ...[
          const SizedBox(height: AppSpace.s13),
          Entrance(
            animate: _animateCourses,
            child: _ContinueCard(course: resume, onTap: () => _open(resume)),
          ),
        ],
        const SizedBox(height: AppSpace.s13),
        if (showLibrary) const SectionLabel(label: 'Library'),
        if (showLibrary && subjects.length > 1) ...[
          _SubjectFilter(
            subjects: subjects,
            selected: _category,
            onSelected: _selectSubject,
          ),
          const SizedBox(height: AppSpace.s8),
        ],
        AnimatedSize(
          alignment: Alignment.topCenter,
          duration: duration,
          curve: AppMotion.easeInOut,
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: AppMotion.easeInOut,
            switchOutCurve: AppMotion.easeInOut,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final child in previous)
                  ExcludeFocus(
                    child: ExcludeSemantics(child: IgnorePointer(child: child)),
                  ),
                ?current,
              ],
            ),
            child: KeyedSubtree(
              key: ValueKey(_category),
              child: _list(columns, visible),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sectionGap),
        const _LearnFooter(),
      ],
    );
  }

  Widget _list(int columns, List<Course> courses) {
    if (_loading) {
      return Semantics(
        label: 'Loading lessons',
        liveRegion: true,
        child: const AyreCard(
          child: Column(
            children: [
              SkeletonTickerRow(),
              SkeletonTickerRow(),
              SkeletonTickerRow(),
            ],
          ),
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
        illustration: const _LibraryIllustration(),
        onRetry: _load,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpace.cardGap) / columns;
        return Wrap(
          spacing: AppSpace.cardGap,
          runSpacing: AppSpace.cardGap,
          children: [
            for (final (index, course) in courses.indexed)
              SizedBox(
                width: width,
                child: Entrance(
                  index: index,
                  animate: _animateCourses,
                  child: _CourseRow(course: course, onTap: () => _open(course)),
                ),
              ),
          ],
        );
      },
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
/// the same argument any progress ring makes.
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
      label:
          'Continue, ${course.title}, '
          '${course.lessonsDone} of ${course.lessonsTotal} lessons',
      onTap: onTap,
      excludeSemantics: true,
      child: AyreCard(
        onTap: onTap,
        notch: true,
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
                  Text('CONTINUE', style: AppTypo.label(t, color: t.accentInk)),
                  const SizedBox(height: AppSpace.xxs),
                  Text(course.title, style: AppTypo.sectionTitle(t)),
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
    final lessons = '${course.lessonsDone} of ${course.lessonsTotal} lessons';
    final spoken = [
      course.title,
      course.category,
      if (complete) 'Complete' else if (progress != null) lessons,
    ].join(', ');

    return Semantics(
      button: true,
      label: spoken,
      onTap: onTap,
      excludeSemantics: true,
      child: AyreCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppShape.iconTileSize,
                  height: AppShape.iconTileSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surfaceRaised,
                    borderRadius: AppShape.field,
                  ),
                  child: AyreIcon(
                    complete ? AyreGlyph.check : AyreGlyph.course,
                    size: 20,
                    color: complete ? t.positiveText : t.accentInk,
                  ),
                ),
                const SizedBox(width: AppSpace.s13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title, style: AppTypo.cardTitle(t)),
                      const SizedBox(height: 3),
                      Text(course.category, style: AppTypo.meta(t)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                AyreIcon(AyreGlyph.forward, size: 16, color: t.foregroundMuted),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpace.s13),
              if (complete)
                const AyreChip(label: 'Complete', tone: ChipTone.success)
              else ...[
                ProgressRule(value: progress),
                const SizedBox(height: AppSpace.s8),
                Text(lessons, style: AppTypo.meta(t)),
              ],
            ] else if (course.body.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s8),
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

class _LibraryIllustration extends StatelessWidget {
  const _LibraryIllustration();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ExcludeSemantics(
      child: SizedBox(
        height: 64,
        child: FittedBox(
          child: CustomPaint(
            size: const Size(105, 89),
            painter: _LibraryOutline(t.accentInk, t.highlight),
          ),
        ),
      ),
    );
  }
}

class _LibraryOutline extends CustomPainter {
  const _LibraryOutline(this.ink, this.accent);

  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final (i, height) in [27.0, 44.0, 61.0].indexed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(12.0 + i * 29, 80 - height, 21, height),
          const Radius.circular(3),
        ),
        outline,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(9, 21)
        ..lineTo(26, 17)
        ..lineTo(26, 25)
        ..lineTo(9, 29)
        ..close(),
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_LibraryOutline oldDelegate) =>
      ink != oldDelegate.ink || accent != oldDelegate.accent;
}
