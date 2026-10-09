import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import 'settings_screen.dart';
// TEMPORARY (testing) — remove before production
import 'testing/replay_onboarding_row.dart';

/// Keep in step with `pubspec.yaml`'s `version:` field. Held here rather than
/// read at runtime so the app doesn't take a plugin dependency for a string.
const String kAppVersion = '2.0.0';
const String kAppBuild = '1';
const String kSupportAddress = 'support@ayrescanner.app';

/// A real destination for Help and Support: the address to write to, copyable
/// without leaving the app, the build details a reply will ask for, and the
/// tutorials (app and Settings).
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
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          children: [
            Text(
              'Write to the team with what you were doing and what you expected '
              'instead. Including the version below usually saves a round trip.',
              style: AppTypo.body(t),
            ),
            const SizedBox(height: AppSpace.xl),
            const SectionLabel(label: 'Tutorials'),
            RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.course,
                  title: 'App tutorial',
                  subtitle: 'The five tabs and the Home controls.',
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
                  glyph: AyreGlyph.appearance,
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
                const ReplayOnboardingRow(),
              ],
            ),
            const SizedBox(height: AppSpace.sectionGap),
            const SectionLabel(label: 'Contact'),
            RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.support,
                  title: kSupportAddress,
                  subtitle: 'Tap to copy the support address',
                  trailing: AyreIcon(
                    AyreGlyph.copy,
                    size: 16,
                    color: t.foregroundSubtle,
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
                    color: t.foregroundMuted,
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