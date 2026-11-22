import 'package:flutter/material.dart';

import '../legal/legal_config.dart';
import '../legal/legal_content.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_page_header.dart';

/// Renders any [LegalDocument] in the app's standard pushed-screen layout.
///
/// Terms, Privacy Policy, Risk Disclosure, MITC, Investor Charter and the
/// disclosures block all use this one renderer, so the text lives in
/// `lib/legal/legal_content.dart` and the layout lives here.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document, this.footer});

  final LegalDocument document;

  /// Optional widgets shown after the last section.
  final List<Widget>? footer;

  @override
  Widget build(BuildContext context) {
    return AyrePageScaffold(
      title: document.title,
      children: [
        LegalDocumentBody(document: document),
        ...?footer,
      ],
    );
  }
}

/// The scrollable content of a [LegalDocument], reusable inside other screens.
class LegalDocumentBody extends StatelessWidget {
  const LegalDocumentBody({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (document.showLastUpdated)
          Text('Last updated: $kLegalLastUpdated', style: AppTypo.caption(t)),
        if (document.intro != null) ...[
          const SizedBox(height: AppSpace.md),
          SelectableText(document.intro!, style: AppTypo.reading(t)),
        ],
        for (final section in document.sections) ...[
          const SizedBox(height: AppSpace.s21),
          if (section.heading != null) ...[
            Semantics(
              header: true,
              child: Text(section.heading!, style: AppTypo.sectionTitle(t)),
            ),
            const SizedBox(height: AppSpace.s13),
          ],
          for (final p in section.paragraphs) ...[
            SelectableText(p, style: AppTypo.reading(t)),
            const SizedBox(height: AppSpace.s13),
          ],
          for (final b in section.bullets) _Bullet(text: b),
          for (final p in section.closing) ...[
            const SizedBox(height: AppSpace.s13),
            SelectableText(p, style: AppTypo.reading(t)),
          ],
        ],
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Numbered items (MITC) already carry their own number.
    final numbered = RegExp(r'^\d+\. ').hasMatch(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!numbered)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm, top: 1),
              child: Text('•', style: AppTypo.reading(t)),
            ),
          Expanded(child: SelectableText(text, style: AppTypo.reading(t))),
        ],
      ),
    );
  }
}
