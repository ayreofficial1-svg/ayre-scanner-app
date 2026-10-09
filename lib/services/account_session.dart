import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'email_verification.dart';
import 'push_service.dart';
import 'settings_store.dart';

/// Ties sign-in and sign-out to the things that must happen around them, so one
/// account's data never shows up under another.
class AccountSession {
  const AccountSession._();

  static const _ownerKey = 'data_owner_uid';

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

  /// Permanently deletes the signed-in account.
  ///
  /// The password is checked first, so a wrong one changes nothing. The
  /// backend then deletes the login and every push device registered to the
  /// account (all of its phones), and only after that is the local session
  /// ended. Local clean-up runs when the signed-out state arrives, as for sign
  /// out.
  ///
  /// Throws [AuthFailure] with a reader-ready message.
  static Future<void> deleteAccount({required String password}) async {
    await AuthService.instance.reauthenticate(password: password);
    final problem = await ApiService.deleteAccount();
    if (problem != null) {
      throw AuthFailure(AuthFailureKind.unknown, problem);
    }
    await AuthService.instance.endSessionAfterDeletion();
  }

  /// Called whenever someone is signed in. If the data on this device was left
  /// by a different account — or by no known account, such as an older build,
  /// or a sign-out that was cut short — it is cleared before use.
  static Future<void> onSignedIn(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_ownerKey) != uid) {
      await clearLocalData();
    }
    await prefs.setString(_ownerKey, uid);
  }

  /// Removes data that belongs to the previous account: cached content, the
  /// alert log, the seen-signals list and verification state. Device
  /// preferences (theme, text size, alert switches) are kept.
  static Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ownerKey);
    await ApiService.clearContentCaches();
    await NotificationLog.instance.clear();
    await SeenSignalsStore.clear();
    EmailVerificationService.instance.reset();
  }
}
