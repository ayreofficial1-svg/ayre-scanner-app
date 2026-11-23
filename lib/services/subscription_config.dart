// Every owner decision for subscriptions lives here, so a real value is a
// one-line change. Nothing in this file is a final value unless it says so.

/// [DECISION D-4] Store product IDs, one per plan. PLACEHOLDER: replace with
/// the IDs created in Play Console and App Store Connect. The UI renders
/// whatever the store returns and does not assume how many plans exist.
const Set<String> kSubscriptionProductIds = {'REPLACE_WITH_PRODUCT_ID'};

/// How long Recommendations stay in the "resolving" skeleton while the store
/// answer is awaited. After this, the cached entitlement for the signed-in
/// account is used if there is one, otherwise recommendations are locked.
/// Engineer's choice (Phase 1): 6 seconds.
const Duration kEntitlementResolveTimeout = Duration(seconds: 6);

/// [DECISION D-10] The longest a cached "subscribed" state is trusted when the
/// store cannot be queried. PLACEHOLDER: null means the cached state is
/// trusted until the next successful store check.
const Duration? kEntitlementOfflineGrace = null;

/// Store pages where a subscriber manages the plan (Phase 3 status screen).
const String kAndroidManageSubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions';
const String kIosManageSubscriptionsUrl =
    'https://apps.apple.com/account/subscriptions';

/// [DECISION D-6] Whether the temporary "Testing" group with the Paywall
/// switch is shown. `true` shows it in all builds until launch. To show it in
/// debug builds only, change the value to `kDebugMode` and add
/// `import 'package:flutter/foundation.dart';` at the top of this file.
/// TEMPORARY (paywall test toggle) — remove before production
const bool kShowPaywallTestToggle = true;