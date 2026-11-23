import 'market_data_cache.dart';
import 'settings_store.dart';

/// Removes every local trace of recommendations from this device.
///
/// Run whenever access to recommendations becomes locked, so a device without
/// a subscription holds no recommendation data: not the saved signals list,
/// not the seen-symbols list, and not the alerts that name a pick, its levels
/// or an exit. `general` alerts (messages from the team) are left alone.
///
/// Idempotent and best-effort, like the other cache helpers: a storage failure
/// is swallowed and never reaches the UI.
class RecommendationPurge {
  const RecommendationPurge._();

  /// Same key `PersistentMarketDataService` saves the signals list under.
  static const _signalsCacheKey = 'signals';

  /// Clears the saved signals list only.
  static Future<void> clearCache() async {
    try {
      await MarketDataCache.clear(_signalsCacheKey);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Clears the saved signals list, the seen-symbols list and the
  /// recommendation entries in the alerts list.
  static Future<void> run() async {
    await clearCache();
    try {
      await SeenSignalsStore.clear();
    } catch (_) {
      // Best-effort.
    }
    try {
      await NotificationLog.instance.removeKinds(
        NotificationLog.recommendationKinds,
      );
    } catch (_) {
      // Best-effort.
    }
  }
}
