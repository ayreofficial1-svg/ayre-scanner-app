import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// On-device persistence for the last-known-good payload behind every content
/// surface (signals, Learn, desk notes, weekly reports, compliance info).
///
/// This is what lets [PersistentMarketDataService] show real, previously
/// seen data instead of an empty or failed state when the market is closed
/// for longer than the in-memory session, the backend is unreachable, the
/// device is offline at cold start, or the app process was killed and
/// restarted — any case the existing in-memory `DataResult.keepingLastGood`
/// can't cover because it only remembers what happened earlier in the same
/// running session.
///
/// Deliberately built on `shared_preferences` — the same storage
/// [SettingsStore] and [NotificationLog] already use for on-device state —
/// rather than introducing a new persistence mechanism. Every entry is
/// namespaced under [_prefix] so it can't collide with a settings key.
///
/// Reads and writes are best-effort: a storage failure (corrupt value,
/// platform channel error) is swallowed and treated as "nothing cached"
/// rather than surfaced to the UI or allowed to block a fresh reading from
/// being shown. Persistence is a bonus on top of the live data path, never a
/// gate on it.
class MarketDataCache {
  const MarketDataCache._();

  static const _prefix = 'market_cache::';

  /// Saves [data] (anything `jsonEncode` accepts — the models' own `toJson`
  /// output) under [key], alongside the time it was written. Overwrites
  /// whatever was previously saved under that key, so the cache always holds
  /// the most recently seen good reading, never a stale one layered under an
  /// older one.
  static Future<void> save(String key, Object? data) async {
    if (data == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({
          'cachedAt': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );
    } catch (_) {
      // Best-effort — see class doc.
    }
  }

  /// Loads whatever was last saved under [key] and runs it through [decode]
  /// (typically a model's `tryParse`). Returns null when nothing was ever
  /// saved, the saved value is corrupt, or [decode] itself returns null —
  /// every case collapses to "no fallback available" for the caller.
  static Future<T?> load<T>(
    String key,
    T? Function(dynamic data) decode,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return null;
      return decode(envelope['data']);
    } catch (_) {
      return null;
    }
  }

  /// Removes a single cached surface. Used by the one-time legacy purge and
  /// by account switching.
  static Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (_) {
      // Best-effort — see class doc.
    }
  }

  /// Removes every cached surface whose key starts with [keyPrefix] (used by
  /// the legacy purge for keys that carried a suffix).
  static Future<void> clearPrefix(String keyPrefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final full = '$_prefix$keyPrefix';
      for (final k in prefs.getKeys().where((k) => k.startsWith(full)).toList()) {
        await prefs.remove(k);
      }
    } catch (_) {
      // Best-effort — see class doc.
    }
  }
}
