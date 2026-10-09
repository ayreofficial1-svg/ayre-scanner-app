import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Whether the first-run tour has been seen on this device.
///
/// Deliberately its own store rather than a [SettingsStore] field: every value
/// there changes something a Settings row does, and this is not a setting.
///
/// Device-level on purpose, like the theme and alert switches. It is **not**
/// cleared by `AccountSession.clearLocalData()`, so signing out or deleting an
/// account never brings the tour back. A different person on the same device
/// can open it from Profile → Help → App tour.
class OnboardingStore extends ChangeNotifier {
  OnboardingStore._();

  static final OnboardingStore instance = OnboardingStore._();

  /// A fresh, unloaded store so tests do not share the singleton's state.
  @visibleForTesting
  factory OnboardingStore.forTest() = OnboardingStore._;

  static const _key = 'onboarding_completed';

  bool _loaded = false;
  bool _completed = false;

  /// False until [load] has finished. The gate waits on this so a slow read
  /// can never flash the tour at someone who has already seen it.
  bool get loaded => _loaded;
  bool get completed => _completed;

  /// Reads the stored flag. Merges rather than overwrites, so a
  /// [markCompleted] that raced ahead of this read is not lost.
  ///
  /// Fails open: if storage cannot be read, the tour is treated as seen. A
  /// storage fault must never stand between a person and Sign in.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _completed = _completed || (prefs.getBool(_key) ?? false);
    } catch (e) {
      debugPrint('OnboardingStore.load failed: $e');
      _completed = true;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Records that the tour has been seen. The in-memory flag flips first so the
  /// UI advances even if the write is slow; the write is retried once and then
  /// abandoned (at worst the tour shows once more later).
  Future<void> markCompleted() async {
    if (_completed) return;
    _completed = true;
    notifyListeners();

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (await prefs.setBool(_key, true)) return;
      } catch (e) {
        debugPrint('OnboardingStore.markCompleted failed: $e');
      }
    }
  }
}

/// The tour shows only to someone who is signed out, once the flag has been
/// read, and who has not seen it. Pure so it can be tested without the gate.
bool shouldShowOnboarding({
  required AuthPhase phase,
  required bool loaded,
  required bool completed,
}) => phase == AuthPhase.signedOut && loaded && !completed;
