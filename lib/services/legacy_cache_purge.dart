import 'package:shared_preferences/shared_preferences.dart';

import 'market_data_cache.dart';

/// One-time removal of market data that older builds persisted on the device.
///
/// Earlier versions cached index levels, constituent prices, equity quotes,
/// sentiment, movers, breadth and the signals feed (which carried last price,
/// percent change and "entry reached" facts) under `market_cache::`. None of
/// that is shown any more, so an updated install must not keep it.
///
/// Idempotent and best-effort: guarded by a version flag so it runs once per
/// install, and a storage failure is swallowed (the next launch retries).
///
/// Stored alerts of the retired "entry reached" kind need no work here: the
/// kind no longer exists, so `Notice.tryParse` drops them on load.
class LegacyCachePurge {
  const LegacyCachePurge._();

  static const doneFlagKey = 'compliance_purge_v1';

  /// Exact `market_cache::` keys to remove.
  static const exactKeys = <String>[
    'index_board',
    'gainers',
    'losers',
    'most_active',
    'full_breadth',
    'volatility',
    'momentum',
    'signals',
  ];

  /// `market_cache::` key prefixes to remove.
  static const prefixes = <String>[
    'index_',
    'constituents_',
    'equity_',
    'sentiment_',
    'volume_surge_',
  ];

  static Future<void> run() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(doneFlagKey) == true) return;
      for (final key in exactKeys) {
        await MarketDataCache.clear(key);
      }
      for (final prefix in prefixes) {
        await MarketDataCache.clearPrefix(prefix);
      }
      await prefs.setBool(doneFlagKey, true);
    } catch (_) {
      // Best-effort: retried on the next launch.
    }
  }
}
