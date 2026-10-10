// TEMPORARY (testing) — remove before production.
//
// Removal: delete this file, then delete the import and the single
// `ReplayOnboardingRow()` line in `support_screen.dart`.
//
// Replays the first-run welcome pages for testing. It stores nothing: it never
// calls `OnboardingStore.markCompleted()` or `TourService.markPending()`, never
// touches auth, so real first-run gating is unchanged.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/tour_service.dart';
import '../../widgets/ayre_components.dart';
import '../../widgets/ayre_icons.dart';
import '../onboarding_screen.dart';

class ReplayOnboardingRow extends StatefulWidget {
  const ReplayOnboardingRow({super.key});

  @override
  State<ReplayOnboardingRow> createState() => _ReplayOnboardingRowState();
}

class _ReplayOnboardingRowState extends State<ReplayOnboardingRow> {
  bool _open = false;

  Future<void> _replay() async {
    if (_open) return;
    _open = true;
    HapticFeedback.selectionClick();
    // Onboarding is a full-screen, root-level flow: it must cover the dock,
    // so it goes on the root navigator, not the tab's (A3).
    final navigator = Navigator.of(context, rootNavigator: true);
    await navigator.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (routeContext) => OnboardingScreen(
          onFinished: ({required bool startTour}) {
            Navigator.of(routeContext).pop();
            if (startTour) {
              navigator.popUntil((route) => route.isFirst);
              TourService.instance.requestAppTour();
            }
          },
        ),
      ),
    );
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    return SettingRow(
      glyph: AyreGlyph.learn,
      title: 'Replay onboarding',
      subtitle: 'Testing only. Shows the welcome pages again.',
      onTap: _replay,
    );
  }
}
