import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

/// The destination behind a lesson card's arrow. The list truncates a lesson's
/// body to keep cards scannable; this shows it in full, which is what the arrow
/// has always implied.
class LessonScreen extends StatelessWidget {
  const LessonScreen({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.body,
    required this.icon,
  });

  final String title;
  final String eyebrow;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(title: Text(eyebrow)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: tokens.accentCool),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  eyebrow.toUpperCase(),
                  style: AppTypo.microLabel(tokens),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypo.pageTitle(tokens)),
            const SizedBox(height: AppSpacing.lg),
            const HairlineDivider(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              body.isEmpty
                  ? 'This lesson has no written body yet.'
                  : body,
              style: AppTypo.body(tokens).copyWith(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
