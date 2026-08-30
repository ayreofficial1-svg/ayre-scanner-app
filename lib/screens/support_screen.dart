import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';

/// Keep in step with `pubspec.yaml`'s `version:` field. Held here rather than
/// read at runtime so the app doesn't take a plugin dependency for a string.
const String kAppVersion = '2.0.0';
const String kAppBuild = '1';
const String kSupportAddress = 'support@ayrescanner.app';

/// A real destination for Help and Support: the address to write to, copyable
/// without leaving the app, plus the build details a reply will ask for.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
        title: const Text('Help and support'),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          children: [
            Text(
              'Write to the team with what you were doing and what you expected '
              'instead. Including the version below usually saves a round trip.',
              style: AppTypo.body(t),
            ),
            const SizedBox(height: AppSpacing.xl),
            RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.support,
                  title: kSupportAddress,
                  subtitle: 'Tap to copy the support address',
                  trailing: AyreIcon(
                    AyreGlyph.copy,
                    size: 16,
                    color: t.textTertiary,
                  ),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await Clipboard.setData(
                      const ClipboardData(text: kSupportAddress),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                ),
                SettingRow(
                  glyph: AyreGlyph.about,
                  title: 'Version',
                  subtitle: 'Include this when you write in',
                  trailing: Figure.static(
                    '$kAppVersion ($kAppBuild)',
                    fontSize: 13,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
