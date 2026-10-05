import 'package:flutter/material.dart';

import '../legal/legal_content.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// FAQ. Questions and answers live in `lib/legal/legal_content.dart`
/// ([kLegalFaqs]); this screen only lays them out as expandable rows.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('FAQ'),
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
            Text(
              'Answers to the questions we hear most often.',
              style: AppTypo.body(t),
            ),
            const SizedBox(height: AppSpace.xl),
            RowGroup(
              children: [
                for (final entry in kLegalFaqs) _FaqTile(entry: entry),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One expandable question; tapping reveals or hides the answer.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.entry});

  final LegalFaq entry;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.entry.question,
                    style: AppTypo.rowLabel(t),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: AyreIcon(
                    AyreGlyph.forward,
                    size: 14,
                    color: t.foregroundSubtle,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs),
                child: Text(widget.entry.answer, style: AppTypo.caption(t)),
              ),
              crossFadeState: _open
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.topLeft,
            ),
          ],
        ),
      ),
    );
  }
}
