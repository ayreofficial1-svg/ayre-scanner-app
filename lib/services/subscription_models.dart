// Plain data types for the subscription layer. Pure Dart, no widgets.

/// What the store says about the person's subscription.
enum EntitlementState {
  /// Not resolved yet.
  unknown,

  /// No active subscription.
  inactive,

  /// An active subscription.
  active,

  /// A purchase is waiting for approval (Ask to Buy, pending payment).
  pending,
}

/// What the subscription service is busy doing. Separate from
/// [EntitlementState].
enum SubscriptionOperation { idle, loadingPlans, purchasing, restoring }

/// Why a store operation did not work.
enum SubscriptionFailureKind {
  storeUnavailable,
  noProducts,
  offline,
  declined,
  itemUnavailable,
  cancelled,
  unknown,
}

/// A failure with a message that is ready to show.
class SubscriptionFailure {
  const SubscriptionFailure(this.kind, this.message);

  /// The failure with its standard plain-words message.
  factory SubscriptionFailure.of(SubscriptionFailureKind kind) =>
      SubscriptionFailure(kind, _messageFor(kind));

  final SubscriptionFailureKind kind;
  final String message;

  /// A person-cancelled purchase is not an error and is never shown.
  bool get silent => kind == SubscriptionFailureKind.cancelled;

  static String _messageFor(SubscriptionFailureKind kind) => switch (kind) {
    SubscriptionFailureKind.storeUnavailable =>
      "Purchases aren't available on this device.",
    SubscriptionFailureKind.noProducts => "Plans couldn't load.",
    SubscriptionFailureKind.offline =>
      "You're offline. Check your connection and try again.",
    SubscriptionFailureKind.declined =>
      "The payment didn't go through. Try again or use another payment "
          'method.',
    SubscriptionFailureKind.itemUnavailable =>
      "This plan isn't available right now. Try again later.",
    SubscriptionFailureKind.cancelled => 'Purchase cancelled.',
    SubscriptionFailureKind.unknown => 'Something went wrong. Try again.',
  };
}

/// One plan as the store reports it. Every text field comes from store data;
/// nothing here is written by hand.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.productId,
    required this.title,
    required this.price,
    this.period,
    this.trial,
    this.platformProduct,
  });

  final String productId;

  /// The store's title for the plan.
  final String title;

  /// The store's localised price string.
  final String price;

  /// The billing period in words, when the store reports it.
  final String? period;

  /// A trial or introductory offer line, only when the store reports one.
  final String? trial;

  /// Opaque reference to the platform product, used at purchase time.
  final Object? platformProduct;
}

/// The result of asking the store for plans.
class PlanLoadResult {
  const PlanLoadResult.plans(this.plans) : failure = null;

  PlanLoadResult.failed(SubscriptionFailureKind kind)
    : plans = const [],
      failure = SubscriptionFailure.of(kind);

  final List<SubscriptionPlan> plans;
  final SubscriptionFailure? failure;
}

/// A subscription the store says is currently owned.
class OwnedSubscription {
  const OwnedSubscription({required this.productId, this.expiresAt});

  final String productId;

  /// Only when the platform provides it reliably.
  final DateTime? expiresAt;
}

enum SubscriptionOutcomeKind {
  /// Purchase or restore worked and a subscription is active.
  success,

  /// Waiting for approval.
  pending,

  /// The person backed out. Silent.
  cancelled,

  /// Restore found nothing.
  nothingFound,

  /// See [SubscriptionOutcome.failure].
  failed,

  /// Another operation was already running; nothing was started.
  ignored,
}

/// The result of a purchase or restore.
class SubscriptionOutcome {
  const SubscriptionOutcome(this.kind, {this.failure});

  factory SubscriptionOutcome.failed(SubscriptionFailureKind kind) =>
      SubscriptionOutcome(
        SubscriptionOutcomeKind.failed,
        failure: SubscriptionFailure.of(kind),
      );

  final SubscriptionOutcomeKind kind;
  final SubscriptionFailure? failure;
}

/// A change the store pushed on its own (a purchase finished while the app was
/// closed, a renewal, a refund).
class GatewayUpdate {
  const GatewayUpdate({
    required this.state,
    this.productId,
    this.expiresAt,
    this.failure,
  });

  final EntitlementState state;
  final String? productId;
  final DateTime? expiresAt;
  final SubscriptionFailure? failure;
}