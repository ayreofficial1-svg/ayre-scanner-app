import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'app_lifecycle.dart';
import 'auth_service.dart';

enum VerifyCheck { verified, notYet, failed }

/// Tracks the account's email-verification status. Nothing is blocked by it:
/// this only drives the banner and the Profile row, and keeps them current.
///
/// The status is re-checked when someone signs in unverified and each time the
/// app returns to the foreground (the usual moment after tapping the link in
/// an email), then the token is refreshed so the backend sees the new flag.
class EmailVerificationService extends ChangeNotifier {
  EmailVerificationService._();

  static final EmailVerificationService instance =
      EmailVerificationService._();

  static const int cooldownSeconds = 60;

  bool _started = false;
  bool _checking = false;
  bool _sending = false;
  String? _uid;
  String? _dismissedUid;
  int _cooldown = 0;
  Timer? _timer;

  bool get checking => _checking;
  bool get sending => _sending;

  /// Seconds until Resend is allowed again; 0 when it is.
  int get cooldown => _cooldown;
  bool get canResend => !_sending && _cooldown <= 0;

  /// Whether the banner should show right now.
  bool get bannerVisible {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;
    if (ApiService.verificationRequired.value) return true;
    return !user.emailVerified && _dismissedUid != user.uid;
  }

  /// The server insists, so the banner cannot be dismissed.
  bool get isRequired => ApiService.verificationRequired.value;

  void init() {
    if (_started) return;
    _started = true;
    AuthService.instance.user.addListener(_onUser);
    AuthService.instance.phase.addListener(_onPhase);
    ApiService.verificationRequired.addListener(notifyListeners);
    AppLifecycleService.instance.addListener(_onResumed);
  }

  void _onUser() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != _uid) {
      _uid = uid;
      _dismissedUid = null;
      _stopCooldown();
    }
    notifyListeners();
  }

  void _onPhase() {
    if (AuthService.instance.phase.value == AuthPhase.signedIn) {
      unawaited(_recheckIfUnverified());
    }
  }

  void _onResumed() => unawaited(_recheckIfUnverified());

  Future<void> _recheckIfUnverified() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    if (user.emailVerified && !ApiService.verificationRequired.value) return;
    await recheck();
  }

  void dismiss() {
    _dismissedUid = AuthService.instance.currentUser?.uid;
    notifyListeners();
  }

  /// Reloads the account, then confirms with the server. Never throws.
  Future<VerifyCheck> recheck() async {
    if (_checking) return VerifyCheck.failed;
    _checking = true;
    notifyListeners();
    try {
      await AuthService.instance.reloadUser();
      final user = AuthService.instance.currentUser;
      if (user == null) return VerifyCheck.failed;
      if (!user.emailVerified) return VerifyCheck.notYet;

      // Verified locally. Make sure the server sees it too; a stale token is
      // the usual reason it might not, and reloadUser already refreshed it.
      final me = await ApiService.getAppMe();
      if (me == null || me.emailVerified) {
        ApiService.verificationRequired.value = false;
      }
      return VerifyCheck.verified;
    } on AuthFailure {
      return VerifyCheck.failed;
    } catch (_) {
      return VerifyCheck.failed;
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  /// Sends the verification email again. Returns the failure, or null on
  /// success. Starts the cooldown only on success.
  Future<AuthFailure?> resend() async {
    if (!canResend) return null;
    _sending = true;
    notifyListeners();
    try {
      await AuthService.instance.sendEmailVerification();
      _startCooldown();
      return null;
    } on AuthFailure catch (e) {
      return e;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldown = cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cooldown--;
      if (_cooldown <= 0) {
        _cooldown = 0;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  void _stopCooldown() {
    _timer?.cancel();
    _timer = null;
    _cooldown = 0;
  }

  /// Forgets everything about the previous account.
  void reset() {
    _uid = null;
    _dismissedUid = null;
    _stopCooldown();
    ApiService.verificationRequired.value = false;
    notifyListeners();
  }
}
