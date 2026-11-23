import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'subscription_config.dart';
import 'subscription_gateway.dart';
import 'subscription_models.dart';

/// [SubscriptionGateway] on Flutter's official `in_app_purchase` plugin (D-1).
///
/// Uses only the plugin's platform-agnostic API. Every text field of a plan
/// comes from the store's own product data.
///
/// Platform notes:
///  * Android: owned subscriptions are read by asking the store to restore
///    (silent, no prompt); the result arrives on the purchase stream.
///  * iOS: owned subscriptions cannot be read passively. Restore runs only when
///    the person taps it, because it may prompt for the Apple ID. Passive
///    resolution relies on the transaction updates delivered at start-up.
class StoreSubscriptionGateway implements SubscriptionGateway {
  StoreSubscriptionGateway();

  /// Synchronous so the service has applied an update before the purchase is
  /// completed with the store.
  final StreamController<GatewayUpdate> _updates =
      StreamController<GatewayUpdate>.broadcast(sync: true);

  StreamSubscription<List<PurchaseDetails>>? _storeSub;
  bool _started = false;

  Completer<List<PurchaseDetails>>? _batchWaiter;
  Completer<SubscriptionOutcome>? _purchaseWaiter;
  String? _purchaseProductId;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Subscribing here (the service reads this at start-up) means purchases that
  /// finish while the app was closed, pending approvals and renewals are
  /// received, not only those made while the paywall is open.
  @override
  Stream<GatewayUpdate> get updates {
    _start();
    return _updates.stream;
  }

  void _start() {
    if (_started || !_supported) return;
    _started = true;
    try {
      _storeSub = InAppPurchase.instance.purchaseStream.listen(
        _onPurchases,
        onError: (Object error) {
          debugPrint('Store purchase stream error.');
        },
      );
    } catch (_) {
      _started = false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!_supported) return false;
    try {
      return await InAppPurchase.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PlanLoadResult> loadPlans(Set<String> productIds) async {
    if (!await isAvailable()) {
      return PlanLoadResult.failed(SubscriptionFailureKind.storeUnavailable);
    }
    try {
      final response = await InAppPurchase.instance.queryProductDetails(
        productIds,
      );
      if (response.notFoundIDs.isNotEmpty) {
        // Product IDs only: no personal data.
        debugPrint('Store products not found: ${response.notFoundIDs}');
      }
      if (response.productDetails.isEmpty) {
        return PlanLoadResult.failed(
          response.error == null
              ? SubscriptionFailureKind.noProducts
              : SubscriptionFailureKind.unknown,
        );
      }
      // The first (default) offer for each product. One tile per product even
      // when the store reports several offers.
      final seen = <String>{};
      final plans = <SubscriptionPlan>[];
      for (final details in response.productDetails) {
        if (!seen.add(details.id)) continue;
        plans.add(
          SubscriptionPlan(
            productId: details.id,
            title: details.title,
            price: details.price,
            platformProduct: details,
          ),
        );
      }
      return PlanLoadResult.plans(plans);
    } catch (_) {
      return PlanLoadResult.failed(SubscriptionFailureKind.unknown);
    }
  }

  @override
  Future<SubscriptionOutcome> purchase(
    SubscriptionPlan plan, {
    String? accountId,
  }) async {
    final product = plan.platformProduct;
    if (product is! ProductDetails) {
      return SubscriptionOutcome.failed(
        SubscriptionFailureKind.itemUnavailable,
      );
    }
    if (!await isAvailable()) {
      return SubscriptionOutcome.failed(SubscriptionFailureKind.storeUnavailable);
    }
    if (_purchaseWaiter != null) {
      return const SubscriptionOutcome(SubscriptionOutcomeKind.ignored);
    }
    _start();
    final waiter = Completer<SubscriptionOutcome>();
    _purchaseWaiter = waiter;
    _purchaseProductId = plan.productId;
    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        // An opaque id only; never an email.
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: accountId,
        ),
      );
      if (!started && !waiter.isCompleted) {
        waiter.complete(
          SubscriptionOutcome.failed(SubscriptionFailureKind.itemUnavailable),
        );
      }
    } catch (_) {
      if (!waiter.isCompleted) {
        waiter.complete(
          SubscriptionOutcome.failed(SubscriptionFailureKind.unknown),
        );
      }
    }
    final outcome = await waiter.future;
    _purchaseWaiter = null;
    _purchaseProductId = null;
    return outcome;
  }

  @override
  Future<SubscriptionOutcome> restore() async {
    if (!await isAvailable()) {
      return SubscriptionOutcome.failed(SubscriptionFailureKind.storeUnavailable);
    }
    final batch = await _restoreBatch(const Duration(seconds: 30));
    if (batch == null) {
      return SubscriptionOutcome.failed(SubscriptionFailureKind.unknown);
    }
    final owned = _owned(batch);
    return SubscriptionOutcome(
      owned.isEmpty
          ? SubscriptionOutcomeKind.nothingFound
          : SubscriptionOutcomeKind.success,
    );
  }

  @override
  Future<List<OwnedSubscription>?> ownedSubscriptions() async {
    // iOS: never restored silently (it can raise an Apple ID prompt).
    if (!_isAndroid) return null;
    final batch = await _restoreBatch(const Duration(seconds: 8));
    if (batch == null) return null;
    return _owned(batch)
        .map((d) => OwnedSubscription(productId: d.productID))
        .toList();
  }

  /// Asks the store to restore and waits for the batch that answers.
  Future<List<PurchaseDetails>?> _restoreBatch(Duration timeout) async {
    if (!_supported) return null;
    _start();
    if (_batchWaiter != null) {
      try {
        return await _batchWaiter!.future.timeout(timeout);
      } catch (_) {
        return null;
      }
    }
    final waiter = Completer<List<PurchaseDetails>>();
    _batchWaiter = waiter;
    try {
      await InAppPurchase.instance.restorePurchases();
      return await waiter.future.timeout(timeout);
    } catch (_) {
      return null;
    } finally {
      if (identical(_batchWaiter, waiter)) _batchWaiter = null;
    }
  }

  List<PurchaseDetails> _owned(List<PurchaseDetails> batch) => batch
      .where(
        (d) =>
            kSubscriptionProductIds.contains(d.productID) &&
            (d.status == PurchaseStatus.purchased ||
                d.status == PurchaseStatus.restored),
      )
      .toList();

  Future<void> _onPurchases(List<PurchaseDetails> batch) async {
    for (final details in batch) {
      final configured = kSubscriptionProductIds.contains(details.productID);
      final forPurchase =
          _purchaseWaiter != null && details.productID == _purchaseProductId;
      SubscriptionOutcome? outcome;

      switch (details.status) {
        case PurchaseStatus.pending:
          if (configured) {
            _updates.add(
              GatewayUpdate(
                state: EntitlementState.pending,
                productId: details.productID,
              ),
            );
          }
          if (forPurchase) {
            outcome = const SubscriptionOutcome(SubscriptionOutcomeKind.pending);
          }
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (configured) {
            // Applied (synchronously) before the purchase is completed below.
            _updates.add(
              GatewayUpdate(
                state: EntitlementState.active,
                productId: details.productID,
              ),
            );
          }
          if (forPurchase) {
            outcome = const SubscriptionOutcome(SubscriptionOutcomeKind.success);
          }
        case PurchaseStatus.canceled:
          if (forPurchase) {
            outcome = const SubscriptionOutcome(
              SubscriptionOutcomeKind.cancelled,
            );
          }
        case PurchaseStatus.error:
          if (forPurchase) {
            outcome = SubscriptionOutcome.failed(_kindOf(details.error));
          }
      }

      // Completing also acknowledges Android purchases; an unacknowledged
      // Android purchase is refunded by Google after a few days.
      if (details.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(details);
        } catch (_) {
          debugPrint('Could not complete a store purchase.');
        }
      }

      if (outcome != null && !(_purchaseWaiter?.isCompleted ?? true)) {
        _purchaseWaiter!.complete(outcome);
      }
    }

    final waiter = _batchWaiter;
    if (waiter != null && !waiter.isCompleted) waiter.complete(batch);
  }

  SubscriptionFailureKind _kindOf(IAPError? error) {
    final text = '${error?.code ?? ''} ${error?.message ?? ''}'.toLowerCase();
    if (text.contains('unavailable')) {
      return SubscriptionFailureKind.itemUnavailable;
    }
    if (text.contains('declin') || text.contains('payment')) {
      return SubscriptionFailureKind.declined;
    }
    return SubscriptionFailureKind.unknown;
  }

  @override
  Future<void> dispose() async {
    await _storeSub?.cancel();
    _storeSub = null;
    _started = false;
    await _updates.close();
  }
}
