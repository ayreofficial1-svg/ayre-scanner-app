import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// Placeholder only — the app's real Privacy Policy has not been supplied
/// yet. This constant is the one place to drop the final legal text in;
/// nothing here is invented legal wording standing in for it.
const String kPrivacyPolicyText = 'Privacy Policy text to be added.';

/// Phase 5 — a `SupportScreen`-style destination for the Profile tab's new
/// "Legal" section. Holds no real content of its own yet; see
/// [kPrivacyPolicyText].
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text('Privacy Policy'),
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
            Text(kPrivacyPolicyText, style: AppTypo.body(t)),
          ],
        ),
      ),
    );
  }
}
