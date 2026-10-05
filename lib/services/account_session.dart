import 'dart:async';

import 'api_service.dart';
import 'auth_service.dart';
import 'push_service.dart';
import 'settings_store.dart';

/// Ties sign-out to the things that must happen around it.
class AccountSession {
  const AccountSession._();

  /// User-initiated sign out. Order matters: the device's push token is removed
  /// from the backend first (it needs a still-valid sign-in), then the account
  /// is signed out. Local clean-up runs when the signed-out state arrives
  /// (see [clearLocalData]), so it also covers sessions ended elsewhere.
  static Future<void> signOut() async {
    try {
      await PushService.instance.unregisterForSignOut().timeout(
        const Duration(seconds: 6),
      );
    } catch (_) {
      // Best-effort: a failure here must never keep the user signed in.
    }
    await AuthService.instance.signOut();
  }

  /// Removes data that belongs to the previous account. Device preferences
  /// (theme, text size) are kept.
  static Future<void> clearLocalData() async {
    await SettingsStore.instance.setDisplayName(null);
    await ApiService.clearContentCaches();
  }
}
