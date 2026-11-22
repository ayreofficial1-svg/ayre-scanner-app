import 'package:flutter/material.dart';

import '../onboarding/onboarding_content.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'finance_icons.dart';

/// Page indicators for the onboarding flow (and the spotlight tour): the
/// selected page is a 34×8 pill, the others 8×8 dots, 8 apart, radius 4. The
/// dots are decoration; the page position is announced once as "Step N of M"
/// on the wrapper.
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.page,
    required this.total,
    this.activeColor,
  });

  final int page;
  final int total;

  /// Overrides the selected pill's colour (default: the brand accent). The
  /// spotlight tour passes a non-saffron colour because its highlight ring
  /// already is saffron.
  final Color? activeColor;

  static const double _dot = 8;
  static const double _activeWidth = 34;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: OnboardingLabels.step(page + 1, total),
      excludeSemantics: true,
      child: Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: reduce ? Duration.zero : AppMotion.buttonPress,
              curve: AppMotion.ease,
              width: i == page ? _activeWidth : _dot,
              height: _dot,
              decoration: BoxDecoration(
                color: i == page
                    ? (activeColor ?? t.accent)
                    : t.foregroundSubtle.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Welcome illustration: three rectangular bars (89 wide, radius 8, 13 apart;
/// heights 89, 144, 233 on a shared baseline) with a 34×13 saffron block above
/// the first. Purely decorative — no axis, numbers or interaction. Designed on
/// a 293×246 canvas and scaled as a whole to [height].
class OnboardingBars extends StatelessWidget {
  const OnboardingBars({super.key, this.height = 246});

  final double height;

  static const double _w = 293;
  static const double _h = 246;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget bar(double h, Color color) => Container(
      width: 89,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _w,
            height: _h,
            child: Stack(
              children: [
                Positioned(left: 0, bottom: 0, child: bar(89, t.surfaceRaised)),
                Positioned(
                  left: 0,
                  bottom: 89 + 8,
                  child: Container(
                    width: 34,
                    height: 13,
                    decoration: BoxDecoration(
                      color: t.highlight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(left: 102, bottom: 0, child: bar(144, t.positive)),
                Positioned(
                  left: 204,
                  bottom: 0,
                  child: bar(233, t.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page 2: where Weekly Report and Learn live. A notched card of two
/// information rows (44 tile, 15/700 label, 13/500 description) — they have no
/// `onTap`, so they read as information rather than navigation.
class OnboardingFeatureRows extends StatelessWidget {
  const OnboardingFeatureRows({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyreCard(
      notch: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s21,
        vertical: AppSpace.s8,
      ),
      child: Column(
        children: [
          for (var i = 0; i < kOnboardingFeatures.length; i++) ...[
            if (i > 0) const HairlineDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpace.hairlineRowPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppShape.iconTileSize,
                    height: AppShape.iconTileSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surfaceRaised,
                      borderRadius: AppShape.field,
                    ),
                    child: FinanceIcon(
                      kOnboardingFeatures[i].glyph,
                      size: 22,
                      color: t.accentInk,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kOnboardingFeatures[i].title,
                          style: AppTypo.rowLabel(t),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kOnboardingFeatures[i].subtitle,
                          style: AppTypo.hint(t),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The two explanatory "Reports tab" / "Learn tab" pills below the card. They
/// say where a feature lives; they are not navigation.
class OnboardingLocationPills extends StatelessWidget {
  const OnboardingLocationPills({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s8,
      runSpacing: AppSpace.s8,
      children: [
        for (final f in kOnboardingFeatures)
          AyreChip(label: f.location, tone: ChipTone.success),
      ],
    );
  }
}
