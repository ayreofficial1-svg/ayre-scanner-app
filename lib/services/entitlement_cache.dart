import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_config.dart';
import 'subscription_models.dart';

/// What was last confirmed about one account's subscription.
class CachedEntitlement {
  const CachedEntitlement({
    required this.state,
    required this.verifiedAt,
    this.productId,
    this.expiresAt,
  });

  final EntitlementState state;
  final DateTime verifiedAt;
  final String? productId;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'verifiedAt': verifiedAt.toIso8601String(),
    if (productId != null) 'productId': productId,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };

  static CachedEntitlement? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final verifiedAt = DateTime.tryParse(raw['verifiedAt']?.toString() ?? '');
    final stateName = raw['state']?.toString();
    EntitlementState? state;
    for (final candidate in EntitlementState.values) {
      if (candidate.name == stateName) state = candidate;
    }
    if (verifiedAt == null || state == null) return null;
    if (state == EntitlementState.unknown) return null;
    return CachedEntitlement(
      state: state,
      verifiedAt: verifiedAt,
      productId: raw['productId']?.toString(),
      expiresAt: DateTime.tryParse(raw['expiresAt']?.toString() ?? ''),
    );
  }
}

/// Per-account store of the last confirmed entitlement, so a start without the
/// store (offline) still knows. Holds no receipts, purchase tokens or personal
/// data, and the key is prefixed with the opaque account id so one account never
/// reads another's.
class EntitlementCache {
  const EntitlementCache._();

  static const _suffix = '::subscription_entitlement';

  static String _key(String uid) => '$uid$_suffix';

  /// The cached entitlement for [uid], or null when none exists or it is no
  /// longer trustworthy (past its own expiry, or older than the offline grace
  /// when the owner has set one).
  static Future<CachedEntitlement?> read(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_key(uid));
      if (text == null) return null;
      final cached = CachedEntitlement.tryParse(jsonDecode(text));
      if (cached == null) return null;
      if (cached.state == EntitlementState.active) {
        final now = DateTime.now();
        final expiry = cached.expiresAt;
        if (expiry != null && expiry.isBefore(now)) return null;
        final grace = kEntitlementOfflineGrace;
        if (grace != null && now.difference(cached.verifiedAt) > grace) {
          return null;
        }
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String uid, CachedEntitlement value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(uid), jsonEncode(value.toJson()));
    } catch (_) {
      // Best-effort.
    }
  }

  static Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }

  /// Removes every account's cached entitlement.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (key.endsWith(_suffix)) await prefs.remove(key);
      }
    } catch (_) {}
  }
}
