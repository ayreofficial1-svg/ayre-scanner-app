import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/app_states.dart';
import '../widgets/numeral.dart';
import '../widgets/premium_widgets.dart';
import 'profile_tab.dart' show ProfileRow;

/// Keep in step with `pubspec.yaml`'s `version:` field. Held here rather than
/// read at runtime so the app doesn't take a plugin dependency just to show a
/// version string.
const String kAppVersion = '1.0.0';
const String kAppBuild = '1';
const String kSupportAddress = 'support@ayrescanner.app';

/// A real destination for Help and Support: the address to write to, copyable
/// without leaving the app, plus the build details a support reply will ask for.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(title: const Text('Help and support')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              'Write to the team with what you were doing and what you '
              'expected instead. Including the version below usually saves a '
              'round trip.',
              style: AppTypo.body(tokens),
            ),
            const SizedBox(height: AppSpacing.xl),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ProfileRow(
                    icon: Icons.mail_outline_rounded,
                    title: kSupportAddress,
                    subtitle: 'Tap to copy the support address',
                    trailing: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: tokens.textTertiary,
                    ),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await Clipboard.setData(
                        const ClipboardData(text: kSupportAddress),
                      );
                      if (!context.mounted) return;
                      ConfirmationBanner.show(context, 'Address copied');
                    },
                  ),
                  const HairlineDivider(indent: 60),
                  ProfileRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    subtitle: 'Include this when you write in',
                    trailing: Numeral.static(
                      '$kAppVersion ($kAppBuild)',
                      fontSize: 13,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
