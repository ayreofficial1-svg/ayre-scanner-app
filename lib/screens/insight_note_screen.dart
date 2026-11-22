import 'package:flutter/material.dart';

import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_page_header.dart';

class InsightNoteScreen extends StatelessWidget {
  const InsightNoteScreen({super.key, required this.note});

  final InsightNote note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final category = note.category?.trim() ?? '';
    final body = note.body.trim();

    return AyrePageScaffold(
      title: 'Market insight',
      children: [
        if (category.isNotEmpty) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TagPill(label: category),
          ),
          const SizedBox(height: AppSpace.s13),
        ],
        Semantics(
          header: true,
          child: Text(
            note.title,
            style: note.title.length > 65
                ? AppTypo.sectionTitle(t)
                : AppTypo.pageTitle(t),
          ),
        ),
        const SizedBox(height: AppSpace.s21),
        const HairlineDivider(),
        const SizedBox(height: AppSpace.s21),
        Text(
          body.isEmpty ? 'This note has no written body yet.' : body,
          style: AppTypo.reading(t),
        ),
      ],
    );
  }
}
