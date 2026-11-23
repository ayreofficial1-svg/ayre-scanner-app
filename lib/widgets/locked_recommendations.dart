import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/paywall_screen.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';

/// The Recommendations area while the paywall applies and there is no
/// subscription.
///
/// Locked means absent, not hidden: the cards behind the overlay are fixed
/// decorative placeholders, identical for everyone on every launch. They hold
/// no symbol, name, number or count taken from real recommendations, and the
/// blur is cosmetic only — nothing real is ever drawn underneath it.
class LockedRecommendationsSection extends StatelessWidget {
  const LockedRecommendationsSection({super.key});

  /// The placeholder layer keeps this height whatever the text size, so the
  /// overlay never has to share space with it at the large text setting.
  static const double _minHeight = 330;

  static const String _headline = 'Subscribe to unlock recommendations';
  static const String _body =
      "Get the analyst's entry, exit and stop-loss levels and the reasoning "
      'behind each pick.';
  static const String _overlayLabel =
      'Recommendations are locked. Subscribe to unlock them.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(
          label: 'Recommendations',
          padding: EdgeInsets.only(bottom: AppSpace.sm),
        ),
        Stack(
          children: [
            const Positioned.fill(child: _PlaceholderLayer()),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s13,
                    vertical: AppSpace.lg,
                  ),
                  child: Semantics(
                    container: true,
                    label: _overlayLabel,
                    child: AyreCard(
                      featured: true,
                      notch: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ExcludeSemantics(child: _LockTile()),
                          const SizedBox(height: AppSpace.s13),
                          ExcludeSemantics(
                            child: Text(
                              _headline,
                              style: AppTypo.sectionTitle(context.tokens),
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          ExcludeSemantics(
                            child: Text(
                              _body,
                              style: AppTypo.body(context.tokens),
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                          AyreButton(
                            label: 'View plans',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              PaywallScreen.open(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockTile extends StatelessWidget {
  const _LockTile();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: AppShape.prominentTileSize,
      height: AppShape.prominentTileSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: AppShape.field,
      ),
      child: AyreIcon(AyreGlyph.lock, size: 24, color: t.foregroundMuted),
    );
  }
}

/// Two identical cards drawn from grey shapes and masked glyphs, blurred and
/// clipped to the area behind the overlay. Excluded from semantics and touch.
class _PlaceholderLayer extends StatelessWidget {
  const _PlaceholderLayer();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PlaceholderCard(),
                  SizedBox(height: AppSpace.cardGap),
                  _PlaceholderCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      padding: EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBlock(
                width: AppShape.iconTileSize,
                height: AppShape.iconTileSize,
                radius: AppRadius.iconTile,
              ),
              SizedBox(width: AppSpace.s13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 110, height: 18),
                    SizedBox(height: AppSpace.xxs),
                    SkeletonBlock(width: 170, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpace.md),
          SkeletonBlock(height: 8, radius: AppRadius.pill),
          SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: _MaskedLevel()),
              SizedBox(width: AppSpace.s8),
              Expanded(child: _MaskedLevel()),
              SizedBox(width: AppSpace.s8),
              Expanded(child: _MaskedLevel()),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaskedLevel extends StatelessWidget {
  const _MaskedLevel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBlock(width: 40, height: 10),
        const SizedBox(height: AppSpace.xxs),
        Text(
          '₹ ••••',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: AppTypo.levelPrice(
            context.tokens,
            color: context.tokens.foregroundMuted,
          ),
        ),
      ],
    );
  }
}
