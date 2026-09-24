import 'dart:async';

import 'package:flutter/widgets.dart';

/// App-wide foreground/background tracking.
///
/// Android suspends the app's network access in the background. Without this,
/// the 10s live-refresh timers kept firing, and the first requests after
/// returning to the app raced the radio/DNS coming back and were reported as
/// "offline" / "couldn't load".
///
/// Screens use it to:
///  * skip polling while backgrounded or still settling after resume
///    ([canFetch]);
///  * refresh once, after a short settle delay, when the app returns
///    (listen to this notifier; it fires once per resume).
class AppLifecycleService extends ChangeNotifier with WidgetsBindingObserver {
  AppLifecycleService._();

  static final AppLifecycleService instance = AppLifecycleService._();

  /// Time given to the network stack to reconnect before the resume refresh.
  static const Duration resumeSettleDelay = Duration(milliseconds: 1200);

  bool _initialised = false;
  bool _foreground = true;
  bool _settling = false;
  DateTime? _pausedAt;
  Duration _lastAway = Duration.zero;
  Timer? _settleTimer;

  /// True while the app is in the foreground and past its post-resume settle.
  bool get canFetch => _foreground && !_settling;

  /// How long the app was in the background before the latest resume.
  Duration get lastAway => _lastAway;

  /// Call once from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  void init() {
    if (_initialised) return;
    _initialised = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_foreground) _pausedAt = DateTime.now();
        _foreground = false;
        _settling = false;
        _settleTimer?.cancel();
      case AppLifecycleState.resumed:
        if (_foreground) return;
        _foreground = true;
        _settling = true;
        final pausedAt = _pausedAt;
        _lastAway = pausedAt == null
            ? Duration.zero
            : DateTime.now().difference(pausedAt);
        _settleTimer?.cancel();
        _settleTimer = Timer(resumeSettleDelay, () {
          _settling = false;
          notifyListeners();
        });
      case AppLifecycleState.inactive:
        // Transient (notification shade, permission dialog). Not a background.
        break;
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
