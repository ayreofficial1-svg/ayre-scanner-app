import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// The destination behind Home's Market Insight "Read more": one desk note in
/// full. The carousel clamps the body to two lines; this shows all of it.
///
/// Same shape as [LessonScreen] — an app bar, a category tag, the title, a
/// hairline, the body — so the two reading surfaces feel like one family.
class InsightNoteScreen extends StatelessWidget {
  const InsightNoteScreen({super.key, required this.note});

  final InsightNote note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final category = note.category?.trim() ?? '';
    final body = note.body.trim();

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('Market insight'),
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
            if (category.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TagPill(label: category),
              ),
              const SizedBox(height: AppSpace.md),
            ],
            Text(note.title, style: AppTypo.pageTitle(t)),
            const SizedBox(height: AppSpace.lg),
            const HairlineDivider(),
            const SizedBox(height: AppSpace.lg),
            Text(
              body.isEmpty ? 'This note has no written body yet.' : body,
              style: AppTypo.body(t).copyWith(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
