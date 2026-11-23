import 'subscription_models.dart';

/// What the subscription service needs from a store. The provider behind it is
/// swappable (D-1).
abstract class SubscriptionGateway {
  /// Whether the store can be used on this device.
  Future<bool> isAvailable();

  /// Loads plans for [productIds] from the store.
  Future<PlanLoadResult> loadPlans(Set<String> productIds);

  /// Starts a purchase of [plan]. [accountId] is an opaque identifier, never an
  /// email.
  Future<SubscriptionOutcome> purchase(
    SubscriptionPlan plan, {
    String? accountId,
  });

  /// Restores purchases. Runs only on explicit user action.
  Future<SubscriptionOutcome> restore();

  /// The subscriptions the store says are owned now, or null when the store
  /// could not be queried.
  Future<List<OwnedSubscription>?> ownedSubscriptions();

  /// Changes the store pushes on its own.
  Stream<GatewayUpdate> get updates;

  Future<void> dispose();
}

/// Reports "store unavailable" for everything, so the app runs correctly before
/// a real store is wired in.
class NoStoreSubscriptionGateway implements SubscriptionGateway {
  const NoStoreSubscriptionGateway();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<PlanLoadResult> loadPlans(Set<String> productIds) async =>
      PlanLoadResult.failed(SubscriptionFailureKind.storeUnavailable);

  @override
  Future<SubscriptionOutcome> purchase(
    SubscriptionPlan plan, {
    String? accountId,
  }) async =>
      SubscriptionOutcome.failed(SubscriptionFailureKind.storeUnavailable);

  @override
  Future<SubscriptionOutcome> restore() async =>
      SubscriptionOutcome.failed(SubscriptionFailureKind.storeUnavailable);

  @override
  Future<List<OwnedSubscription>?> ownedSubscriptions() async => null;

  @override
  Stream<GatewayUpdate> get updates => const Stream<GatewayUpdate>.empty();

  @override
  Future<void> dispose() async {}
}
