import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, debugPrint, kIsWeb;

/// One idempotent place that initialises Firebase, shared by authentication and
/// push so neither depends on the other having run first.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<bool>? _pending;

  /// True when this platform can use Firebase at all (Android now; iOS later).
  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// True once the default Firebase app exists.
  static bool get isInitialised => Firebase.apps.isNotEmpty;

  /// Initialises the default Firebase app if needed. Returns false when Firebase
  /// is not configured for this build (for example `google-services.json` is
  /// missing). A failed attempt is not cached, so Retry can try again.
  static Future<bool> ensureInitialised() {
    if (isInitialised) return Future.value(true);
    if (!platformSupported) return Future.value(false);
    return _pending ??= _initialise().whenComplete(() => _pending = null);
  }

  static Future<bool> _initialise() async {
    try {
      await Firebase.initializeApp();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') return true;
      debugPrint('Firebase unavailable: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Firebase unavailable: $e');
      return false;
    }
  }
}
