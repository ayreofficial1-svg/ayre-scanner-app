import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_models.dart' show InsightNote;
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'finance_icons.dart';

class AyreInsightCarousel extends StatefulWidget {
  const AyreInsightCarousel({
    super.key,
    required this.notes,
    required this.onReadMore,
  });

  final List<InsightNote> notes;
  final ValueChanged<InsightNote> onReadMore;
  static const int maxNotes = 5;

  @override
  State<AyreInsightCarousel> createState() => _AyreInsightCarouselState();
}

class _AyreInsightCarouselState extends State<AyreInsightCarousel> {
  int _index = 0;

  int _resolved(int count) => _index < count ? _index : 0;

  void _step(int delta, int count) {
    HapticFeedback.selectionClick();
    setState(() => _index = (_resolved(count) + delta + count) % count);
  }

  @override
  Widget build(BuildContext context) {
    final notes = [
      ...widget.notes.where((note) => note.featured),
      ...widget.notes.where((note) => !note.featured),
    ].take(AyreInsightCarousel.maxNotes).toList();
    if (notes.isEmpty) return const SizedBox.shrink();

    final t = context.tokens;
    final count = notes.length;
    final index = _resolved(count);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.expand;

    return AyreCard(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onHorizontalDragEnd: count < 2
            ? null
            : (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() > 200) _step(velocity < 0 ? 1 : -1, count);
              },
        child: Stack(
          children: [
            PositionedDirectional(
              end: -12,
              bottom: 0,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(105, 74),
                  painter: _DeskMotif(t.accent.withValues(alpha: 0.08)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      for (var i = 0; i < count; i++)
                        AnimatedOpacity(
                          duration: duration,
                          curve: AppMotion.easeInOut,
                          opacity: i == index ? 1 : 0,
                          child: ExcludeFocus(
                            excluding: i != index,
                            child: ExcludeSemantics(
                              excluding: i != index,
                              child: IgnorePointer(
                                ignoring: i != index,
                                child: _Page(
                                  note: notes[i],
                                  onReadMore: () => widget.onReadMore(notes[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (count > 1) ...[
                    const SizedBox(height: AppSpace.s8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: AppSpace.s8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Semantics(
                          liveRegion: true,
                          label: 'Note ${index + 1} of $count',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < count; i++)
                                AnimatedContainer(
                                  duration: duration,
                                  curve: AppMotion.easeInOut,
                                  width: i == index ? 34 : 8,
                                  height: 8,
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: i == index ? t.accent : t.hairline,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Previous note',
                              onPressed: () => _step(-1, count),
                              icon: const FinanceIcon(
                                FinanceGlyph.chevron,
                                quarterTurns: 2,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next note',
                              onPressed: () => _step(1, count),
                              icon: const FinanceIcon(
                                FinanceGlyph.chevron,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.note, required this.onReadMore});

  final InsightNote note;
  final VoidCallback onReadMore;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final body = note.body.trim();
    final category = note.category?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty) ...[
          TagPill(label: category),
          const SizedBox(height: AppSpace.s8),
        ],
        Text(note.title, style: AppTypo.sectionTitle(t)),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s8),
          Text(
            body,
            style: AppTypo.body(t),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.s13),
          AyreButton(
            label: 'Read more',
            onPressed: onReadMore,
            expand: false,
            kind: AyreButtonKind.outline,
          ),
        ],
      ],
    );
  }
}

class _DeskMotif extends CustomPainter {
  const _DeskMotif(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.14)
        ..lineTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(w * 0.66, h)
        ..lineTo(w * 0.66, h * 0.47)
        ..lineTo(w * 0.36, h * 0.47)
        ..lineTo(w * 0.36, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_DeskMotif oldDelegate) => color != oldDelegate.color;
}

class AyreInsightSkeleton extends StatelessWidget {
  const AyreInsightSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 90, height: 22),
          SizedBox(height: AppSpace.s8),
          SkeletonBlock(width: 184, height: 21),
          SizedBox(height: AppSpace.s8),
          SkeletonBlock(height: 13),
          SizedBox(height: AppSpace.s13),
          SkeletonBlock(width: 120, height: AppShape.controlHeight),
        ],
      ),
    );
  }
}
