import 'package:flutter/material.dart';

import '../onboarding/onboarding_content.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';

/// Page dots for the onboarding flow: the active page is a 22px pill in
/// `accent`, the others 6px circles. The dots are decoration; the page
/// position is announced once as "Step N of M" on the wrapper.
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.page,
    required this.total,
  });

  final int page;
  final int total;

  static const double _dot = 6;
  static const double _activeWidth = 22;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: OnboardingLabels.step(page + 1, total),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpace.xs),
              child: AnimatedContainer(
                // No `AppMotion.fast` exists; `buttonPress` (150ms) is the
                // shortest token and fits a small state change.
                duration: reduce ? Duration.zero : AppMotion.buttonPress,
                curve: AppMotion.ease,
                width: i == page ? _activeWidth : _dot,
                height: _dot,
                decoration: BoxDecoration(
                  color: i == page
                      ? t.accent
                      : t.foregroundSubtle.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A soft radial wash of `accent` behind the illustration. Same alphas the
/// hills already use; no new colour.
class OnboardingWash extends StatelessWidget {
  const OnboardingWash({super.key, this.size = 320});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  t.accent.withValues(alpha: dark ? 0.14 : 0.10),
                  t.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 2: where Weekly Report and Learn live. Rows have no
/// `onTap`, so they read as information rather than navigation.
class OnboardingFeatureRows extends StatelessWidget {
  const OnboardingFeatureRows({super.key});

  @override
  Widget build(BuildContext context) {
    return RowGroup(
      children: [
        for (final f in kOnboardingFeatures)
          SettingRow(
            glyph: f.glyph,
            title: f.title,
            subtitle: f.subtitle,
            trailing: AyreChip(label: f.location),
          ),
      ],
    );
  }
}
