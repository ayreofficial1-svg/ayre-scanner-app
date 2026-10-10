import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// What the app shows: the single source of truth for the startup gate.
enum AuthPhase { initializing, unavailable, signedOut, signedIn }

/// A signed-in account, independent of any auth provider.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final String displayName;
  final bool emailVerified;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.emailVerified == emailVerified;

  @override
  int get hashCode => Object.hash(uid, email, displayName, emailVerified);

  /// A name to show: the account name, else the part of the email before '@'.
  String get shownName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }
}

enum AuthFailureKind {
  emailInUse,
  invalidEmail,
  weakPassword,
  invalidCredentials,
  userDisabled,
  tooManyRequests,
  network,
  notConfigured,
  unknown,
}

/// A failure already translated into plain words for the reader.
class AuthFailure implements Exception {
  const AuthFailure(this.kind, this.message);

  final AuthFailureKind kind;
  final String message;

  @override
  String toString() => 'AuthFailure($kind)';
}

/// The only contract the rest of the app depends on. Screens and `ApiService`
/// never import Firebase; another provider can implement this later.
abstract class AuthService {
  static AuthService instance = FirebaseAuthService();

  ValueListenable<AuthPhase> get phase;

  /// A calm one-line reason the user was returned to Sign in (for example a
  /// session that ended elsewhere). Null when there is nothing to say.
  ValueListenable<String?> get notice;

  /// The signed-in account, or null.
  AuthUser? get currentUser;

  /// The signed-in account as a listenable, so the name and verification
  /// status update on screen the moment they change.
  ValueListenable<AuthUser?> get user;

  /// Starts (or restarts, for Retry) the service.
  Future<void> init();

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  /// Sends a reset email. Succeeds quietly when the address has no account.
  Future<void> sendPasswordReset(String email);

  /// Changes the signed-in account's password. The current password is
  /// confirmed first, so a wrong one changes nothing. The caller is
  /// responsible for having the reader type [newPassword] twice and checking
  /// the entries match before calling this.
  ///
  /// Throws [AuthFailure] with a reader-ready message.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> sendEmailVerification();

  /// Reloads the account from the server (verification flag, name).
  Future<void> reloadUser();

  Future<void> updateDisplayName(String name);

  /// A current ID token for the backend, or null when signed out. Throws
  /// [AuthFailure] with [AuthFailureKind.network] when it cannot be renewed
  /// because the device is offline.
  Future<String?> getIdToken({bool forceRefresh = false});

  Future<void> signOut({String? notice});

  /// Confirms the signed-in account's password again before a sensitive
  /// action. Throws [AuthFailure] when the password is wrong or the check
  /// cannot be made.
  Future<void> reauthenticate({required String password});

  /// Ends the local session after the server has deleted the account, with a
  /// notice on Sign in saying so. The deletion itself happens on the backend
  /// (`POST /api/account/delete`), which also clears the account's push
  /// devices; see `AccountSession.deleteAccount`.
  Future<void> endSessionAfterDeletion();

  void clearNotice();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService();

  final ValueNotifier<AuthPhase> _phase = ValueNotifier(
    AuthPhase.initializing,
  );
  final ValueNotifier<String?> _notice = ValueNotifier(null);

  final ValueNotifier<AuthUser?> _userNotifier = ValueNotifier(null);

  StreamSubscription<fb.User?>? _sub;
  bool _explicitSignOut = false;
  bool _holdPublish = false;
  bool _seenFirstEvent = false;

  @override
  ValueListenable<AuthPhase> get phase => _phase;

  @override
  ValueListenable<String?> get notice => _notice;

  fb.FirebaseAuth? get _auth =>
      FirebaseBootstrap.isInitialised ? fb.FirebaseAuth.instance : null;

  @override
  ValueListenable<AuthUser?> get user => _userNotifier;

  void _publishUser() {
    final u = _auth?.currentUser;
    _userNotifier.value = u == null ? null : _map(u);
  }

  @override
  AuthUser? get currentUser {
    final user = _auth?.currentUser;
    return user == null ? null : _map(user);
  }

  static AuthUser _map(fb.User u) => AuthUser(
    uid: u.uid,
    email: u.email ?? '',
    displayName: u.displayName ?? '',
    emailVerified: u.emailVerified,
  );

  @override
  Future<void> init() async {
    await _sub?.cancel();
    _sub = null;
    _seenFirstEvent = false;
    _phase.value = AuthPhase.initializing;

    final ok = await FirebaseBootstrap.ensureInitialised();
    if (!ok) {
      _phase.value = AuthPhase.unavailable;
      return;
    }
    _sub = fb.FirebaseAuth.instance.userChanges().listen(
      _onUser,
      onError: (Object e) => debugPrint('Auth stream error: $e'),
    );
  }

  void _onUser(fb.User? user) {
    final first = !_seenFirstEvent;
    _seenFirstEvent = true;
    _userNotifier.value = user == null ? null : _map(user);
    if (_holdPublish) return;

    if (user != null) {
      _notice.value = null;
      _phase.value = AuthPhase.signedIn;
      return;
    }
    final wasSignedIn = _phase.value == AuthPhase.signedIn;
    if (wasSignedIn && !_explicitSignOut && !first) {
      // Disabled, deleted, or password changed elsewhere.
      _notice.value = 'Your session ended. Please sign in again.';
    }
    _explicitSignOut = false;
    _phase.value = AuthPhase.signedOut;
  }

  fb.FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (auth == null) {
      throw const AuthFailure(
        AuthFailureKind.notConfigured,
        'Sign-in is unavailable right now. Please try again shortly.',
      );
    }
    return auth;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = _requireAuth();
    _holdPublish = true;
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user != null) {
        // Neither step may undo or block a created account.
        try {
          await user.updateDisplayName(name.trim());
        } catch (e) {
          debugPrint('Could not set display name: $e');
        }
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('Could not send verification email: $e');
        }
        try {
          await user.reload();
        } catch (_) {}
      }
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    } finally {
      _holdPublish = false;
      _onUser(auth.currentUser);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final auth = _requireAuth();
    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final auth = _requireAuth();
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      // Same neutral outcome whether or not the account exists.
      if (e.code == 'user-not-found') return;
      throw _translate(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth?.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth?.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      await user.getIdToken(true);
      _publishUser();
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _auth?.currentUser;
    if (user == null) return;
    try {
      await user.updateDisplayName(name.trim());
      await user.reload();
      _publishUser();
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth?.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthFailure(
          AuthFailureKind.network,
          'No connection. Check your internet and try again.',
        );
      }
      // user-token-expired / user-disabled: the SDK signs the user out and the
      // stream reports it; there is no token to give meanwhile.
      return null;
    }
  }

  @override
  Future<void> signOut({String? notice}) async {
    final auth = _auth;
    if (auth == null) return;
    _explicitSignOut = true;
    _notice.value = notice;
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Sign out failed: $e');
      _explicitSignOut = false;
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await reauthenticate(password: currentPassword);
    final user = _auth?.currentUser;
    if (user == null) {
      throw const AuthFailure(
        AuthFailureKind.unknown,
        'You need to be signed in to do this.',
      );
    }
    try {
      await user.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> reauthenticate({required String password}) async {
    final user = _auth?.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const AuthFailure(
        AuthFailureKind.unknown,
        'You need to be signed in to do this.',
      );
    }
    try {
      await user.reauthenticateWithCredential(
        fb.EmailAuthProvider.credential(email: email, password: password),
      );
    } on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw const AuthFailure(
            AuthFailureKind.invalidCredentials,
            'That password is incorrect.',
          );
        default:
          throw _translate(e);
      }
    }
  }

  @override
  Future<void> endSessionAfterDeletion() async {
    final auth = _auth;
    if (auth == null) return;
    // A deliberate exit, so Sign in says the account was deleted rather than
    // that a session ended unexpectedly.
    _explicitSignOut = true;
    _notice.value = 'Your account has been deleted.';
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Sign out after deletion failed: $e');
      _explicitSignOut = false;
    }
  }

  @override
  void clearNotice() => _notice.value = null;

  AuthFailure _translate(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const AuthFailure(
          AuthFailureKind.emailInUse,
          'An account with this email already exists. Try signing in or '
          'resetting your password.',
        );
      case 'invalid-email':
        return const AuthFailure(
          AuthFailureKind.invalidEmail,
          'Enter a valid email address.',
        );
      case 'weak-password':
        return const AuthFailure(
          AuthFailureKind.weakPassword,
          'Choose a stronger password. Use the checklist below as a guide.',
        );
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return const AuthFailure(
          AuthFailureKind.invalidCredentials,
          'Email or password is incorrect.',
        );
      case 'user-disabled':
        return const AuthFailure(
          AuthFailureKind.userDisabled,
          'This account has been disabled. Contact support for help.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          AuthFailureKind.tooManyRequests,
          'Too many attempts. Please wait a few minutes.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          AuthFailureKind.network,
          'No connection. Check your internet and try again.',
        );
      case 'requires-recent-login':
        return const AuthFailure(
          AuthFailureKind.invalidCredentials,
          'For your security, please sign in again and retry.',
        );
      case 'operation-not-allowed':
        debugPrint(
          'Auth config error: enable Email/Password in Firebase Console '
          '(Authentication → Sign-in method).',
        );
        return const AuthFailure(
          AuthFailureKind.notConfigured,
          'Sign-in is unavailable right now. Please try again later.',
        );
      default:
        debugPrint('Auth error: ${e.code}');
        return const AuthFailure(
          AuthFailureKind.unknown,
          'Something went wrong. Please try again.',
        );
    }
  }
}
