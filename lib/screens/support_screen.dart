import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import 'settings_screen.dart';
// TEMPORARY (testing) — remove before production
import 'testing/replay_onboarding_row.dart';

/// Keep in step with `pubspec.yaml`'s `version:` field. Held here rather than
/// read at runtime so the app doesn't take a plugin dependency for a string.
const String kAppVersion = '2.1.0';
const String kAppBuild = '2';
const String kSupportAddress = 'support@ayrescanner.app';

/// A real destination for Help and Support: the address to write to, copyable
/// without leaving the app, the build details a reply will ask for, and the
/// tutorials (app and Settings).
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _copy(
    BuildContext context,
    String text,
    String confirmation,
  ) async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(confirmation)),
      snackBarAnimationStyle: AppMotion.snackBarStyleOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyrePageScaffold(
      title: 'Help and support',
      children: [
        Text(
          'Write to the team with what you were doing and what you expected '
          'instead. Including the version below usually saves a round trip.',
          style: AppTypo.reading(t),
        ),
        const SizedBox(height: AppSpace.sectionGap),
        const SectionLabel(label: 'Tutorials', eyebrow: true),
        RowGroup(
          children: [
            SettingRow(
              glyph: AyreGlyph.course,
              title: 'App tutorial',
              subtitle: 'The four tabs and the Home controls.',
              onTap: () {
                HapticFeedback.selectionClick();
                // The tutorial switches tabs, which only the shell can
                // do, so go back to it and ask.
                Navigator.of(context).popUntil((r) => r.isFirst);
                TourService.instance.requestAppTour();
              },
            ),
            SettingRow(
              glyph: AyreGlyph.profile,
              title: 'Profile tutorial',
              subtitle: 'What each option on Profile does.',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).popUntil((r) => r.isFirst);
                TourService.instance.requestProfileTour();
              },
            ),
            SettingRow(
              glyph: AyreGlyph.sliders,
              title: 'Settings tutorial',
              subtitle: 'Where to find each option in Settings.',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  terminalRoute(
                    builder: (_) => const SettingsScreen(startTour: true),
                  ),
                );
              },
            ),
            // TEMPORARY (testing) — remove before production
            if (kDebugMode) const ReplayOnboardingRow(),
          ],
        ),
        const SizedBox(height: AppSpace.sectionGap),
        const SectionLabel(label: 'Contact', eyebrow: true),
        RowGroup(
          children: [
            SettingRow(
              glyph: AyreGlyph.mail,
              title: kSupportAddress,
              subtitle: 'Tap to copy the support address',
              trailing: AyreIcon(
                AyreGlyph.copy,
                size: 16,
                color: t.foregroundSubtle,
              ),
              onTap: () => _copy(context, kSupportAddress, 'Address copied'),
            ),
            SettingRow(
              glyph: AyreGlyph.about,
              title: 'Version',
              subtitle: '$kAppVersion ($kAppBuild) · Tap to copy',
              trailing: AyreIcon(
                AyreGlyph.copy,
                size: 16,
                color: t.foregroundMuted,
              ),
              onTap: () =>
                  _copy(context, '$kAppVersion ($kAppBuild)', 'Version copied'),
            ),
          ],
        ),
      ],
    );
  }
}
