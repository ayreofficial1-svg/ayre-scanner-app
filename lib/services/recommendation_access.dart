import 'dart:async';

import 'package:flutter/foundation.dart';

// TEMPORARY (paywall test toggle) — remove before production
import 'paywall_test_switch.dart';
import 'subscription_config.dart';
import 'subscription_models.dart';
import 'subscription_service.dart';

/// Whether recommendations may be shown on this device right now.
enum RecommendationAccessState {
  /// The entitlement is not known yet. Show the loading skeleton.
  resolving,

  /// Show the locked panel.
  locked,

  /// Show recommendations.
  unlocked,
}

/// Derives [access] from the subscription entitlement (and, until launch, the
/// temporary paywall switch).
///
/// | Paywall switch | Entitlement      | Access                        |
/// |----------------|------------------|-------------------------------|
/// | OFF            | anything         | unlocked                      |
/// | ON             | active           | unlocked                      |
/// | ON             | inactive/pending | locked                        |
/// | ON             | unknown          | resolving, then (timeout) the |
/// |                |                  | cached entitlement, else lock |
class RecommendationAccess extends ChangeNotifier {
  RecommendationAccess._() {
    // TEMPORARY (paywall test toggle) — remove before production
    PaywallTestSwitch.instance.addListener(_onInputsChanged);
    SubscriptionService.instance.addListener(_onInputsChanged);
    _last = access;
    _syncTimer();
  }

  static final RecommendationAccess instance = RecommendationAccess._();

  Timer? _timer;
  bool _timedOut = false;
  late RecommendationAccessState _last;

  /// TEMPORARY (paywall test toggle) — remove before production.
  /// The only place the temporary switch is read. At launch this becomes
  /// constant `true`.
  bool get _paywallEnforced => PaywallTestSwitch.instance.enabled;

  RecommendationAccessState get access {
    if (!_paywallEnforced) return RecommendationAccessState.unlocked;
    final service = SubscriptionService.instance;
    return switch (service.entitlement) {
      EntitlementState.active => RecommendationAccessState.unlocked,
      EntitlementState.inactive ||
      EntitlementState.pending => RecommendationAccessState.locked,
      EntitlementState.unknown =>
        !_timedOut
            ? RecommendationAccessState.resolving
            : service.cachedEntitlement == EntitlementState.active
            ? RecommendationAccessState.unlocked
            : RecommendationAccessState.locked,
    };
  }

  bool get isLocked => access == RecommendationAccessState.locked;
  bool get isUnlocked => access == RecommendationAccessState.unlocked;
  bool get isResolving => access == RecommendationAccessState.resolving;

  void _onInputsChanged() {
    _syncTimer();
    final next = access;
    if (next == _last) return;
    _last = next;
    notifyListeners();
  }

  /// The resolve timeout runs only while the answer is genuinely awaited.
  void _syncTimer() {
    final waiting =
        _paywallEnforced &&
        SubscriptionService.instance.entitlement == EntitlementState.unknown;
    if (!waiting) {
      _timer?.cancel();
      _timer = null;
      _timedOut = false;
      return;
    }
    if (_timer != null || _timedOut) return;
    _timer = Timer(kEntitlementResolveTimeout, () {
      _timer = null;
      _timedOut = true;
      _onInputsChanged();
    });
  }
}
