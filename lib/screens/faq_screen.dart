import 'package:flutter/material.dart';

import '../legal/legal_content.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import '../widgets/pressable_scale.dart';

/// FAQ. Questions and answers live in `lib/legal/legal_content.dart`
/// ([kLegalFaqs]); this screen only lays them out as expandable rows.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyrePageScaffold(
      title: 'FAQ',
      children: [
        Text(
          'Answers to the questions we hear most often.',
          style: AppTypo.reading(t),
        ),
        const SizedBox(height: AppSpace.sectionGap),
        RowGroup(
          children: [for (final entry in kLegalFaqs) _FaqTile(entry: entry)],
        ),
      ],
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
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.buttonPress;
    void toggle() => setState(() => _open = !_open);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: widget.entry.question,
          button: true,
          expanded: _open,
          onTap: toggle,
          excludeSemantics: true,
          child: PressableScaleRow(
            onTap: toggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s21,
                  vertical: AppSpace.hairlineRowPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.entry.question,
                        style: AppTypo.rowLabel(t),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s13),
                    AnimatedRotation(
                      turns: _open ? 0.75 : 0.25,
                      duration: duration,
                      curve: AppMotion.ease,
                      child: AyreIcon(
                        AyreGlyph.forward,
                        size: 16,
                        color: t.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s21,
              0,
              AppSpace.s21,
              AppSpace.s13,
            ),
            child: Text(widget.entry.answer, style: AppTypo.reading(t)),
          ),
          crossFadeState: _open
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: duration,
          sizeCurve: AppMotion.ease,
          alignment: Alignment.topLeft,
        ),
      ],
    );
  }
}
