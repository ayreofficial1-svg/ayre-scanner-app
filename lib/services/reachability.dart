import 'package:flutter/foundation.dart';

/// Tracks whether the last API call reached the backend, for the app-wide
/// offline banner.
///
/// This used to be plain state on `_AyreScannerAppState` (the app's root
/// widget), updated via `ApiService.onReachabilityChanged` from `main.dart`.
/// Every successful API response calls `ApiService.notifyReachable(true)`
/// (see `market_data_service.dart`'s `_get()`), and with four tabs each
/// independently polling every 10s (`HomeTab`, `InsightsTab`, `SignalsTab`,
/// `LearnTab` — all kept mounted forever by `HomeShell`'s `IndexedStack`),
/// that meant a `setState` on the root widget roughly every 1–3 seconds for
/// the entire session, cascading a rebuild through the whole tree
/// (`MaterialApp` → the text-scale `MediaQuery` wrap → `IndexedStack` → all
/// five tabs) every time — compounding the longer the app stayed open.
///
/// Moving this into its own `ChangeNotifier` means only the offline banner
/// (via a `ListenableBuilder` scoped to just that widget) rebuilds when
/// reachability changes; nothing above it does.
class ReachabilityStore extends ChangeNotifier {
  ReachabilityStore._();

  static final ReachabilityStore instance = ReachabilityStore._();

  bool _offline = false;
  bool _dismissed = false;

  bool get offline => _offline;
  bool get dismissed => _dismissed;

  /// Mirrors the old `ApiService.onReachabilityChanged` callback signature,
  /// so it can be assigned directly: `ApiService.onReachabilityChanged =
  /// ReachabilityStore.instance.setReachable;`
  void setReachable(bool reachable) {
    final nowOffline = !reachable;
    if (nowOffline == _offline) return;
    _offline = nowOffline;
    // A fresh disconnection earns a fresh banner.
    if (nowOffline) _dismissed = false;
    notifyListeners();
  }

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    notifyListeners();
  }
}
