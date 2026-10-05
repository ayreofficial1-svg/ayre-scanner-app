import 'package:flutter/material.dart';

import '../legal/legal_config.dart';
import '../legal/legal_content.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

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
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(document.title),
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
            LegalDocumentBody(document: document),
            ...?footer,
          ],
        ),
      ),
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
          SelectableText(document.intro!, style: AppTypo.body(t)),
        ],
        for (final section in document.sections) ...[
          const SizedBox(height: AppSpace.xl),
          if (section.heading != null) ...[
            Text(section.heading!, style: AppTypo.sectionTitle(t)),
            const SizedBox(height: AppSpace.sm),
          ],
          for (final p in section.paragraphs) ...[
            SelectableText(p, style: AppTypo.body(t)),
            const SizedBox(height: AppSpace.sm),
          ],
          for (final b in section.bullets) _Bullet(text: b),
          for (final p in section.closing) ...[
            const SizedBox(height: AppSpace.xs),
            SelectableText(p, style: AppTypo.body(t)),
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
              child: Text('•', style: AppTypo.body(t)),
            ),
          Expanded(child: SelectableText(text, style: AppTypo.body(t))),
        ],
      ),
    );
  }
}