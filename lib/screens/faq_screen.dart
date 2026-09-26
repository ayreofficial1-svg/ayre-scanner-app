import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// One question/answer pair.
class FaqEntry {
  const FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// Placeholder only — the app's real FAQ content has not been supplied yet.
/// This list is the one place to drop the final questions and answers in;
/// nothing here is an invented question standing in for a real one. The
/// screen renders however many entries this list holds, so adding the real
/// set later needs no other change.
const List<FaqEntry> kFaqEntries = [
  FaqEntry(
    question: 'Question to be added.',
    answer: 'Answer to be added.',
  ),
  FaqEntry(
    question: 'Question to be added.',
    answer: 'Answer to be added.',
  ),
  FaqEntry(
    question: 'Question to be added.',
    answer: 'Answer to be added.',
  ),
];

/// Phase 5 — a `SupportScreen`-style destination for the Profile tab's new
/// "Legal" section. There is no existing expansion-tile pattern anywhere in
/// this codebase (checked `ayre_components.dart`), so this screen brings its
/// own small expand/collapse row rather than a plain wall of text, since an
/// FAQ reads naturally as a list of questions the reader opens one at a
/// time. See [kFaqEntries] for the placeholder content awaiting the real
/// questions and answers.
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
                for (final entry in kFaqEntries) _FaqTile(entry: entry),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One expandable question. Tapping the row reveals its answer beneath it;
/// tapping again closes it. Built from a plain [StatefulWidget] rather than
/// a Material `ExpansionTile` so it keeps this screen's rows on the same
/// `RowGroup`/hairline grammar every other list in the app already uses.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.entry});

  final FaqEntry entry;

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
