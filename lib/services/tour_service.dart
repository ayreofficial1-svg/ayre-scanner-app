import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coordinates the spotlight tutorials across screens that cannot see each
/// other.
///
/// Two jobs:
/// * **First run.** Finishing the welcome pages with "Get started" leaves a
///   one-shot "tour pending" flag; the first `HomeShell` that builds takes it
///   and starts the tutorial. Skipping the welcome pages leaves no flag, so a
///   person who skipped is never nagged.
/// * **Replay.** Help and support asks for the app tutorial through [appTourRequests]
///   (it cannot start it itself: the tutorial switches tabs, which only the
///   shell can do).
///
/// Like the welcome flag this is device-level and is not cleared on sign-out.
class TourService {
  TourService._();

  static final TourService instance = TourService._();

  static const _pendingKey = 'app_tour_pending';

  /// Bumped to ask the shell to start the app tutorial.
  final ValueNotifier<int> appTourRequests = ValueNotifier<int>(0);

  void requestAppTour() => appTourRequests.value++;

  /// Bumped to ask the shell to start the Profile tutorial (it must switch to
  /// the Profile tab first, which only the shell can do).
  final ValueNotifier<int> profileTourRequests = ValueNotifier<int>(0);

  void requestProfileTour() => profileTourRequests.value++;

  /// Remembers that the app tutorial should start at the next opportunity.
  Future<void> markPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pendingKey, true);
    } catch (e) {
      debugPrint('TourService.markPending failed: $e');
    }
  }

  /// Returns true once, then clears the flag. Fails closed: a storage fault
  /// means no automatic tutorial, never a repeating one.
  Future<bool> takePending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_pendingKey) ?? false)) return false;
      await prefs.remove(_pendingKey);
      return true;
    } catch (e) {
      debugPrint('TourService.takePending failed: $e');
      return false;
    }
  }
}
