import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_models.dart' show InsightNote;
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'pressable_scale.dart';

/// The Market Insight hero carousel at the bottom of Home (v5 §2.1 / §2A,
/// "Market Insight hero card").
///
/// A dark, self-contained card: a small uppercase eyebrow, a bold two-line
/// headline, a muted description, a pill "Read more" button with a trailing
/// arrow, a top-right pager (‹ 01/04 ›), and — bottom-right, inside a soft
/// radial green glow — a decorative ascending-bar flourish.
///
/// **The content is real.** Every page is an [InsightNote] from
/// `GET /api/insights`, the same admin-curated desk notes the Insights tab
/// lists; nothing is written client-side. Notes flagged `featured` lead, and
/// at most [maxNotes] are paged. The flourish is ornament only — it plots no
/// data and is excluded from semantics.
///
/// **Height is stable and content-sized.** Pages are cross-faded in one
/// `Stack` rather than sitting in a `PageView`, so the card is exactly as
/// tall as its tallest page at the current text scale — no fixed height to
/// overflow at 2× — and it doesn't jump as the pager moves. Paging is by the
/// arrows or a horizontal swipe, wrapping at the ends.
class AyreInsightCarousel extends StatefulWidget {
  const AyreInsightCarousel({
    super.key,
    required this.notes,
    required this.onReadMore,
  });

  final List<InsightNote> notes;

  /// Called with the current page's note when "Read more" is tapped. The
  /// button only appears on notes that have a body to read.
  final ValueChanged<InsightNote> onReadMore;

  /// The most notes paged. The reference shows four; a desk that publishes a
  /// long back-catalogue shouldn't turn a Home card into a feed.
  static const int maxNotes = 5;

  @override
  State<AyreInsightCarousel> createState() => _AyreInsightCarouselState();
}

class _AyreInsightCarouselState extends State<AyreInsightCarousel> {
  int _index = 0;

  /// Featured notes first (the feed's own flag), then the rest in feed order.
  List<InsightNote> get _ordered {
    final featured = widget.notes.where((n) => n.featured);
    final rest = widget.notes.where((n) => !n.featured);
    return [...featured, ...rest].take(AyreInsightCarousel.maxNotes).toList();
  }

  /// [_index] held inside a list that may have shrunk on a refresh.
  int _resolved(int count) => _index >= count ? 0 : _index;

  void _step(int delta, int count) {
    if (count < 2) return;
    HapticFeedback.selectionClick();
    setState(() => _index = (_resolved(count) + delta + count) % count);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = dark ? _InsightPalette.dark : _InsightPalette.light;

    final notes = _ordered;
    if (notes.isEmpty) return const SizedBox.shrink();

    final count = notes.length;
    final index = _resolved(count);
    final multiple = count > 1;
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.pageTransition;
    final current = notes[index];
    final category = current.category?.trim();
    final eyebrow = (category != null && category.isNotEmpty)
        ? category
        : 'Market insight';

    return AyreCard(
      // The gradient has to reach the card's edge, so the padding moves
      // inside it; `AyreCard` still supplies the radius clip and shadow. In
      // dark the card also takes §2A's accent hairline so it reads as a
      // distinct surface on an already-dark page.
      padding: EdgeInsets.zero,
      borderColor: p.border,
      child: GestureDetector(
        onHorizontalDragEnd: multiple
            ? (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -200) {
                  _step(1, count);
                } else if (v > 200) {
                  _step(-1, count);
                }
              }
            : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: p.gradient,
            ),
          ),
          child: Stack(
            children: [
              // Behind everything, in the bottom-right corner.
              Positioned(right: 0, bottom: 0, child: _InsightArt(palette: p)),
              Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AnimatedSwitcher(
                            duration: fade,
                            // The default layout centres its children, which
                            // would float a short eyebrow into the middle of
                            // the row.
                            layoutBuilder: (currentChild, previousChildren) =>
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                ),
                            child: Text(
                              eyebrow.toUpperCase(),
                              key: ValueKey<int>(index),
                              style: AppTypo.label(t, color: p.eyebrow),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (multiple) ...[
                          const SizedBox(width: AppSpace.xs),
                          ShrinkTrailing(
                            child: _Pager(
                              index: index,
                              count: count,
                              palette: p,
                              onPrevious: () => _step(-1, count),
                              onNext: () => _step(1, count),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Stack(
                      children: [
                        for (var i = 0; i < count; i++)
                          AnimatedOpacity(
                            opacity: i == index ? 1 : 0,
                            duration: fade,
                            curve: AppMotion.ease,
                            child: IgnorePointer(
                              ignoring: i != index,
                              child: ExcludeSemantics(
                                excluding: i != index,
                                child: _Page(
                                  note: notes[i],
                                  palette: p,
                                  onReadMore: () =>
                                      widget.onReadMore(notes[i]),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page: headline, description, and — when there is a body to read — the
/// "Read more" pill.
class _Page extends StatelessWidget {
  const _Page({
    required this.note,
    required this.palette,
    required this.onReadMore,
  });

  final InsightNote note;
  final _InsightPalette palette;
  final VoidCallback onReadMore;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final body = note.body.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.title,
          style: AppTypo.featuredHeadline(t, color: palette.headline),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            body,
            style: AppTypo.body(t, color: palette.description),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.md),
          _ReadMoreButton(palette: palette, onTap: onReadMore),
        ],
      ],
    );
  }
}

class _ReadMoreButton extends StatelessWidget {
  const _ReadMoreButton({required this.palette, required this.onTap});

  final _InsightPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'Read more',
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: palette.pill,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Read more',
                style: AppTypo.button(t, color: palette.pillText),
              ),
              const SizedBox(width: AppSpace.xs),
              AyreIcon(AyreGlyph.forward, size: 14, color: palette.pillText),
            ],
          ),
        ),
      ),
    );
  }
}

/// ‹ 01/04 › — two circular arrow buttons around a zero-padded count. Each
/// button is drawn 32pt but hits 44pt.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.index,
    required this.count,
    required this.palette,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int count;
  final _InsightPalette palette;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PagerButton(
          key: const ValueKey('insight-prev'),
          glyph: AyreGlyph.back,
          label: 'Previous insight',
          palette: palette,
          onTap: onPrevious,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
          child: Semantics(
            label: 'Insight ${index + 1} of $count',
            excludeSemantics: true,
            child: Text(
              '${_two(index + 1)}/${_two(count)}',
              style: AppTypo.num(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: palette.pager,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        _PagerButton(
          key: const ValueKey('insight-next'),
          glyph: AyreGlyph.forward,
          label: 'Next insight',
          palette: palette,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    super.key,
    required this.glyph,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final AyreGlyph glyph;
  final String label;
  final _InsightPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.circle,
        scale: 0.9,
        child: SizedBox(
          height: 44,
          width: 44,
          child: Center(
            child: Container(
              height: 32,
              width: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.arrowFill,
                shape: BoxShape.circle,
              ),
              child: AyreIcon(glyph, size: 14, color: palette.pager),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder mirroring the card's blocks — eyebrow, two headline
/// lines, description, pill (§14.4). Deliberately the ordinary `surface`
/// card: a dark slab that then swaps to a different dark slab reads as noise.
class AyreInsightSkeleton extends StatelessWidget {
  const AyreInsightSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      padding: EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 96, height: 11),
          SizedBox(height: AppSpace.sm),
          SkeletonBlock(height: 20),
          SizedBox(height: AppSpace.xxs),
          SkeletonBlock(width: 180, height: 20),
          SizedBox(height: AppSpace.xs),
          SkeletonBlock(height: 12),
          SizedBox(height: AppSpace.md),
          SkeletonBlock(width: 120, height: 44, radius: AppRadius.pill),
        ],
      ),
    );
  }
}

// ─── Decorative art ────────────────────────────────────────────────────────

/// The ascending-bar flourish in a soft radial glow (bottom-right of the
/// card). **Not a chart**: five bars in a fixed ascending ramp, no axis, no
/// data — ornament, like the header hills. Ignores pointers and is excluded
/// from semantics.
class _InsightArt extends StatelessWidget {
  const _InsightArt({required this.palette});

  final _InsightPalette palette;

  static const Size size = Size(112, 96);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          size: size,
          painter: _InsightArtPainter(
            glowStart: palette.glowStart,
            glowEnd: palette.glowEnd,
            bars: palette.bars,
          ),
        ),
      ),
    );
  }
}

class _InsightArtPainter extends CustomPainter {
  const _InsightArtPainter({
    required this.glowStart,
    required this.glowEnd,
    required this.bars,
  });

  final Color glowStart;
  final Color glowEnd;
  final Color bars;

  // Bar heights as fractions of the bar field, strictly ascending; alpha
  // ramps the same way so the tallest bar is the brightest.
  static const List<double> _heights = [0.24, 0.40, 0.55, 0.72, 0.92];
  static const List<double> _alphas = [0.22, 0.32, 0.44, 0.60, 0.80];
  static const double _barWidth = 10;
  static const double _gap = 6;
  static const double _marginRight = 18;

  // Bars stand on the card's bottom padding line (`AppSpace.lg`), so they
  // align with the "Read more" pill's bottom edge beside them.
  static const double _baselineInset = AppSpace.lg;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - _baselineInset;
    final field = baseline - 6;

    // Glow first, centred under the bars.
    final glowCenter = Offset(size.width * 0.62, size.height * 0.70);
    final glowRadius = size.width * 0.95;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [glowStart, glowEnd],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    final total = _heights.length * _barWidth + (_heights.length - 1) * _gap;
    final startX = size.width - _marginRight - total;
    for (var i = 0; i < _heights.length; i++) {
      final h = field * _heights[i];
      final x = startX + i * (_barWidth + _gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, baseline - h, _barWidth, h),
          const Radius.circular(3),
        ),
        Paint()..color = bars.withValues(alpha: _alphas[i]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InsightArtPainter old) =>
      old.glowStart != glowStart ||
      old.glowEnd != glowEnd ||
      old.bars != bars;
}

// ─── Colours ───────────────────────────────────────────────────────────────

/// Component-specific colours for the hero card (v5 §2A component table).
/// Not `AppThemeTokens` fields — Phase 0 forbids adding any — so they live
/// beside the one widget that consumes them.
///
/// [bars] is the one derived value: §2A gives the glow's colour and says the
/// bars "sit inside" it but lists no colour for the bars themselves, so they
/// reuse the glow's own opaque hue (`#2E9E5B` light / `#4ED892` dark — both
/// already in the spec) under a per-bar alpha ramp. No new hue.
@immutable
class _InsightPalette {
  const _InsightPalette({
    required this.gradient,
    required this.border,
    required this.glowStart,
    required this.glowEnd,
    required this.bars,
    required this.eyebrow,
    required this.headline,
    required this.description,
    required this.pill,
    required this.pillText,
    required this.arrowFill,
    required this.pager,
  });

  /// Top-left → bottom-right base fill.
  final List<Color> gradient;

  /// Dark only: accent at 20% alpha, 1px.
  final Color? border;

  final Color glowStart;
  final Color glowEnd;
  final Color bars;
  final Color eyebrow;
  final Color headline;
  final Color description;
  final Color pill;
  final Color pillText;
  final Color arrowFill;

  /// The "01/04" text; also the arrow glyphs.
  final Color pager;

  static const _InsightPalette light = _InsightPalette(
    gradient: [Color(0xFF0F1D15), Color(0xFF16281C)],
    border: null,
    glowStart: Color(0x402E9E5B),
    glowEnd: Color(0x002E9E5B),
    bars: Color(0xFF2E9E5B),
    eyebrow: Color(0xFF9FD9AE),
    headline: Color(0xFFFFFFFF),
    description: Color(0xFFC7D4CB),
    pill: Color(0xFF24382C),
    pillText: Color(0xFFFFFFFF),
    arrowFill: Color(0x1FFFFFFF),
    pager: Color(0xFFB9C7BD),
  );

  static const _InsightPalette dark = _InsightPalette(
    gradient: [Color(0xFF060B07), Color(0xFF0D1710)],
    border: Color(0x333FCB7A),
    glowStart: Color(0x554ED892),
    glowEnd: Color(0x004ED892),
    bars: Color(0xFF4ED892),
    eyebrow: Color(0xFF6FCB93),
    headline: Color(0xFFF5FFF8),
    description: Color(0xFFAEC2B3),
    pill: Color(0xFF1E3B29),
    pillText: Color(0xFFEDF5EE),
    arrowFill: Color(0x1FFFFFFF),
    pager: Color(0xFF8FA396),
  );
}
