import 'package:flutter/material.dart';

import '../services/market_data_service.dart';
import '../services/recommendation_access.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_signals_section.dart';
import 'explore_reports_card.dart';
import 'locked_recommendations.dart';

/// Chooses what Home shows in the Recommendations area:
///
///  * **unlocked** — the existing [SignalsSection], unchanged;
///  * **resolving** — a loading skeleton (never the locked panel while the
///    answer is still being worked out);
///  * **locked** — [LockedRecommendationsSection].
///
/// Takes the same inputs Home used to give [SignalsSection]. When the access
/// changes, the section is mounted or disposed here, so a locked device never
/// holds a live section (or its data) in memory.
class RecommendationsGate extends StatelessWidget {
  const RecommendationsGate({
    super.key,
    required this.marketData,
    this.active = true,
    this.controller,
    this.forceColumns,
    this.onOpenReports,
  });

  final MarketDataService marketData;
  final bool active;
  final SignalsSectionController? controller;
  final int? forceColumns;

  /// Switches the shell to the Reports tab. Used by the "Explore our past
  /// recommendations" card, which appears only while locked.
  final VoidCallback? onOpenReports;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RecommendationAccess.instance,
      builder: (context, _) {
        return switch (RecommendationAccess.instance.access) {
          RecommendationAccessState.unlocked => SignalsSection(
            key: const ValueKey('recommendations-unlocked'),
            marketData: marketData,
            active: active,
            controller: controller,
            forceColumns: forceColumns,
          ),
          RecommendationAccessState.resolving => const _ResolvingSkeleton(
            key: ValueKey('recommendations-resolving'),
          ),
          RecommendationAccessState.locked => Column(
            key: const ValueKey('recommendations-locked'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LockedRecommendationsSection(),
              const SizedBox(height: AppSpace.cardGap),
              ExploreReportsCard(onOpen: onOpenReports),
            ],
          ),
        };
      },
    );
  }
}

/// Same look as the signals loading state (that class is private to its own
/// file, so it is rebuilt here from the same pieces).
class _ResolvingSkeleton extends StatelessWidget {
  const _ResolvingSkeleton({super.key});

  static const _card = AyreCard(
    padding: EdgeInsets.all(AppSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBlock(width: 160, height: 24),
        SizedBox(height: AppSpace.xs),
        SkeletonBlock(height: 12),
        SizedBox(height: AppSpace.xxs),
        SkeletonBlock(width: 220, height: 12),
        SizedBox(height: AppSpace.md),
        SkeletonBlock(height: 48, radius: AppRadius.inset),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(
          label: 'Recommendations',
          padding: EdgeInsets.only(bottom: AppSpace.sm),
        ),
        Semantics(
          label: 'Loading recommendations',
          liveRegion: true,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card,
              SizedBox(height: AppSpace.cardGap),
              _card,
              SizedBox(height: AppSpace.cardGap),
              _card,
            ],
          ),
        ),
      ],
    );
  }
}
