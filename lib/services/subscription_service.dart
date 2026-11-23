import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_lifecycle.dart';
import 'entitlement_cache.dart';
import 'reachability.dart';
import 'subscription_config.dart';
import 'subscription_gateway.dart';
import 'subscription_models.dart';

/// The app's single source of truth for the subscription: entitlement, plans,
/// what operation is running, and the last failure.
///
/// Entitlement is cached per signed-in account so a start without the store
/// still knows. Going offline never downgrades a cached subscriber: only a
/// successful store answer (or a store update) changes a known state.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  /// Away at least this long, and a return to the app refreshes the
  /// entitlement (same threshold as the signals list).
  static const Duration _resumeThreshold = Duration(seconds: 30);

  SubscriptionGateway _gateway = const NoStoreSubscriptionGateway();
  StreamSubscription<GatewayUpdate>? _updates;
  bool _initialised = false;
  bool _refreshing = false;

  String? _uid;
  EntitlementState _entitlement = EntitlementState.unknown;
  EntitlementState? _cachedEntitlement;
  String? _productId;
  DateTime? _expiresAt;
  List<SubscriptionPlan> _plans = const [];
  SubscriptionOperation _operation = SubscriptionOperation.idle;
  SubscriptionFailure? _lastFailure;
  final List<GatewayUpdate> _held = [];

  EntitlementState get entitlement => _entitlement;

  /// The entitlement remembered for the signed-in account, if any. Used only as
  /// the fallback when resolving takes too long.
  EntitlementState? get cachedEntitlement => _cachedEntitlement;

  /// The product behind an active subscription, when known.
  String? get activeProductId => _productId;

  /// Only when the platform provides it reliably.
  DateTime? get expiresAt => _expiresAt;

  List<SubscriptionPlan> get plans => _plans;
  SubscriptionOperation get operation => _operation;
  bool get busy => _operation != SubscriptionOperation.idle;
  SubscriptionFailure? get lastFailure => _lastFailure;
  bool get hasUser => _uid != null;

  /// Swaps the store provider. Call before [init].
  void useGateway(SubscriptionGateway gateway) {
    if (_initialised) return;
    _gateway = gateway;
  }

  /// Starts listening to store updates and app resumes. Idempotent; needs no
  /// signed-in user. Failures are contained here.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    try {
      _updates = _gateway.updates.listen(_onUpdate, onError: (Object _) {});
    } catch (_) {
      // The app must start without a store.
    }
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  void _onAppResumed() {
    if (_uid == null) return;
    if (AppLifecycleService.instance.lastAway < _resumeThreshold) return;
    unawaited(refresh());
  }

  /// Called when an account signs in: shows that account's cached entitlement
  /// at once, then confirms it with the store.
  Future<void> attachUser(String uid) async {
    _uid = uid;
    _entitlement = EntitlementState.unknown;
    _cachedEntitlement = null;
    _productId = null;
    _expiresAt = null;
    _plans = const [];
    _lastFailure = null;
    notifyListeners();

    final cached = await EntitlementCache.read(uid);
    if (uid != _uid) return;
    if (cached != null) {
      _cachedEntitlement = cached.state;
      // Only if nothing newer arrived while the cache was being read.
      if (_entitlement == EntitlementState.unknown) {
        _entitlement = cached.state;
        _productId = cached.productId;
        _expiresAt = cached.expiresAt;
      }
      notifyListeners();
    }

    final held = List<GatewayUpdate>.of(_held);
    _held.clear();
    for (final update in held) {
      _applyUpdate(update);
    }
    await refresh();
  }

  /// Called when the account signs out or changes. Clears this account's
  /// in-memory state and cached entitlement.
  void detachUser() {
    final leaving = _uid;
    _uid = null;
    _entitlement = EntitlementState.unknown;
    _cachedEntitlement = null;
    _productId = null;
    _expiresAt = null;
    _plans = const [];
    _lastFailure = null;
    _held.clear();
    _operation = SubscriptionOperation.idle;
    notifyListeners();
    if (leaving != null) unawaited(EntitlementCache.clear(leaving));
    unawaited(EntitlementCache.clearAll());
  }

  /// Loads plans from the store.
  Future<void> loadPlans() async {
    if (_operation != SubscriptionOperation.idle) return;
    _operation = SubscriptionOperation.loadingPlans;
    _lastFailure = null;
    notifyListeners();
    PlanLoadResult result;
    try {
      result = await _gateway.loadPlans(kSubscriptionProductIds);
    } catch (_) {
      result = PlanLoadResult.failed(SubscriptionFailureKind.unknown);
    }
    _plans = result.plans;
    _lastFailure = _adapt(result.failure);
    _operation = SubscriptionOperation.idle;
    notifyListeners();
  }

  /// Buys [plan]. Ignored while a purchase or restore is running.
  Future<SubscriptionOutcome> purchase(SubscriptionPlan plan) async {
    if (_operation == SubscriptionOperation.purchasing ||
        _operation == SubscriptionOperation.restoring) {
      return const SubscriptionOutcome(SubscriptionOutcomeKind.ignored);
    }
    _operation = SubscriptionOperation.purchasing;
    _lastFailure = null;
    notifyListeners();
    SubscriptionOutcome outcome;
    try {
      // The Firebase uid is opaque; no email goes to either store (D-9).
      outcome = await _gateway.purchase(plan, accountId: _uid);
    } catch (_) {
      outcome = SubscriptionOutcome.failed(SubscriptionFailureKind.unknown);
    }
    return _finish(outcome, productId: plan.productId);
  }

  /// Restores purchases. Runs only on explicit user action; ignored while a
  /// purchase or restore is running.
  Future<SubscriptionOutcome> restore() async {
    if (_operation == SubscriptionOperation.purchasing ||
        _operation == SubscriptionOperation.restoring) {
      return const SubscriptionOutcome(SubscriptionOutcomeKind.ignored);
    }
    _operation = SubscriptionOperation.restoring;
    _lastFailure = null;
    notifyListeners();
    SubscriptionOutcome outcome;
    try {
      outcome = await _gateway.restore();
    } catch (_) {
      outcome = SubscriptionOutcome.failed(SubscriptionFailureKind.unknown);
    }
    return _finish(outcome);
  }

  SubscriptionOutcome _finish(SubscriptionOutcome outcome, {String? productId}) {
    _operation = SubscriptionOperation.idle;
    switch (outcome.kind) {
      case SubscriptionOutcomeKind.success:
        _setEntitlement(EntitlementState.active, productId: productId);
      case SubscriptionOutcomeKind.pending:
        _setEntitlement(EntitlementState.pending, productId: productId);
      case SubscriptionOutcomeKind.failed:
        _lastFailure = _adapt(outcome.failure);
      case SubscriptionOutcomeKind.nothingFound:
        // A restore that finds nothing proves nothing about a pending or
        // cached state; it only reports "nothing found".
        break;
      case SubscriptionOutcomeKind.cancelled:
      case SubscriptionOutcomeKind.ignored:
        break;
    }
    notifyListeners();
    return outcome;
  }

  /// Asks the store what is owned now and updates the entitlement. A store that
  /// cannot be reached leaves a known state alone.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null || _refreshing) return;
    _refreshing = true;
    try {
      final available = await _gateway.isAvailable();
      if (uid != _uid) return;
      if (!available) {
        _settleUnknown();
        return;
      }
      final owned = await _gateway.ownedSubscriptions();
      if (uid != _uid) return;
      if (owned == null) {
        // Not readable passively (iOS) or the store did not answer: keep what
        // is known.
        _settleUnknown();
        return;
      }
      if (owned.isEmpty) {
        // Refund, expiry or revoke: an empty answer after active flips to
        // inactive at once. A pending purchase stays pending.
        if (_entitlement != EntitlementState.pending) {
          _setEntitlement(EntitlementState.inactive);
        }
        return;
      }
      _setEntitlement(
        EntitlementState.active,
        productId: owned.first.productId,
        expiresAt: owned.first.expiresAt,
      );
    } catch (_) {
      // Contained: a failed check never changes what is already known.
    } finally {
      _refreshing = false;
    }
  }

  /// Nothing could be learned from the store. A state already known (including
  /// one from the cache) is kept; an unknown one becomes inactive, since
  /// nothing says the person owns anything.
  void _settleUnknown() {
    if (_entitlement == EntitlementState.unknown) {
      _setEntitlement(EntitlementState.inactive);
    }
  }

  void _onUpdate(GatewayUpdate update) {
    if (_uid == null) {
      _held.add(update);
      return;
    }
    _applyUpdate(update);
  }

  void _applyUpdate(GatewayUpdate update) {
    if (update.failure != null) _lastFailure = _adapt(update.failure);
    _setEntitlement(
      update.state,
      productId: update.productId,
      expiresAt: update.expiresAt,
    );
  }

  /// Offline is reported as offline, not as a store error.
  SubscriptionFailure? _adapt(SubscriptionFailure? failure) {
    if (failure == null) return null;
    final generic =
        failure.kind == SubscriptionFailureKind.unknown ||
        failure.kind == SubscriptionFailureKind.noProducts;
    if (generic && ReachabilityStore.instance.offline) {
      return SubscriptionFailure.of(SubscriptionFailureKind.offline);
    }
    return failure;
  }

  /// Applies a store-derived state, writes the cache, and notifies listeners
  /// only when something changed.
  void _setEntitlement(
    EntitlementState state, {
    String? productId,
    DateTime? expiresAt,
  }) {
    final keepsProduct =
        state == EntitlementState.active || state == EntitlementState.pending;
    final nextProduct = keepsProduct ? (productId ?? _productId) : null;
    final nextExpiry = state == EntitlementState.active ? expiresAt : null;
    final changed =
        _entitlement != state ||
        _productId != nextProduct ||
        _expiresAt != nextExpiry;
    _entitlement = state;
    _productId = nextProduct;
    _expiresAt = nextExpiry;
    _persist();
    if (changed) notifyListeners();
  }

  void _persist() {
    final uid = _uid;
    if (uid == null || _entitlement == EntitlementState.unknown) return;
    _cachedEntitlement = _entitlement;
    unawaited(
      EntitlementCache.write(
        uid,
        CachedEntitlement(
          state: _entitlement,
          verifiedAt: DateTime.now(),
          productId: _productId,
          expiresAt: _expiresAt,
        ),
      ),
    );
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    unawaited(_updates?.cancel());
    unawaited(_gateway.dispose());
    super.dispose();
  }
}
