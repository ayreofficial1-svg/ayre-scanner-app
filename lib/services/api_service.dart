import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// The server's view of the signed-in account (`GET /api/app/me`).
class AppMe {
  const AppMe({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.name,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final String name;
}

/// Handles all calls to the Ayre Scanner backend.
///
/// Authentication is a Firebase ID token sent as `Authorization: Bearer ...`.
/// The app never calls the website's `/api/auth/*` endpoints and never stores a
/// cookie, a password or a token itself — the Firebase SDK holds the session.
class ApiService {
  static const String baseUrl =
      'https://ayre-scanner-production.up.railway.app';

  static const Duration _contentCacheTtl = Duration(minutes: 10);

  static const List<String> _contentCacheKeys = [
    'content_learn_articles',
    'content_insights',
  ];

  /// Every call in this file goes through this timeout. Without it, a
  /// stalled request (a slow cold-start on the hosted backend, a dropped
  /// connection, anything) leaves its `await` hanging forever — no error,
  /// no fallback, just a screen stuck on its loading skeleton for good.
  static const Duration _timeout = Duration(seconds: 12);

  /// Removes the cookie the previous (Railway-login) build kept on the device.
  static Future<void> purgeLegacyCookie() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('session_cookie')) {
      await prefs.remove('session_cookie');
    }
  }

  /// Clears per-account cached content (called when the user signs out).
  static Future<void> clearContentCaches() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _contentCacheKeys) {
      await prefs.remove(key);
      await prefs.remove('${key}_saved_at');
    }
  }

  /// True when the server has said a verified email is required
  /// (`403 email_not_verified`). Off by default: enforcement is a backend
  /// switch that is not enabled yet. A 403 never signs the user out.
  static final ValueNotifier<bool> verificationRequired = ValueNotifier(false);

  static void _noteForbidden(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['code'] == 'email_not_verified') {
        verificationRequired.value = true;
      }
    } catch (_) {
      // Not JSON: an ordinary 403.
    }
  }

  /// Asks the server who it thinks is signed in. Returns null if the call
  /// fails for any reason; used as a cheap end-to-end check that token auth
  /// works and that the server sees the latest verification status.
  static Future<AppMe?> getAppMe() async {
    try {
      final response = await authedGet(Uri.parse('$baseUrl/api/app/me'));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      notifyReachable(true);
      return AppMe(
        uid: (body['uid'] ?? '').toString(),
        email: (body['email'] ?? '').toString(),
        emailVerified: body['email_verified'] == true,
        name: (body['name'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fires when a request succeeds or fails to reach the host at all, so the app
  /// can show or clear its offline banner without polling.
  static ValueChanged<bool>? onReachabilityChanged;

  static void notifyReachable(bool reachable) =>
      onReachabilityChanged?.call(reachable);

  static Future<Map<String, String>> _headers({
    bool json = false,
    bool forceRefresh = false,
  }) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    // Throws AuthFailure(network) when the token cannot be renewed offline;
    // callers already treat any thrown error as "could not reach the server".
    final token = await AuthService.instance.getIdToken(
      forceRefresh: forceRefresh,
    );
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Sends an authenticated request. On a 401 it forces one token refresh and
  /// retries once; if the server still says 401 the session is over and the
  /// user is returned to Sign in. A 403 never signs the user out.
  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) call, {
    bool json = false,
    Duration? timeout,
  }) async {
    final limit = timeout ?? _timeout;
    try {
      var response = await call(await _headers(json: json)).timeout(limit);
      if (response.statusCode == 401 &&
          AuthService.instance.currentUser != null) {
        response = await call(
          await _headers(json: json, forceRefresh: true),
        ).timeout(limit);
        if (response.statusCode == 401 &&
            AuthService.instance.currentUser != null) {
          await AuthService.instance.signOut(
            notice: 'Your session ended. Please sign in again.',
          );
        }
      }
      if (response.statusCode == 403) _noteForbidden(response);
      return response;
    } on AuthFailure catch (e) {
      throw http.ClientException(e.message);
    }
  }

  /// Authenticated GET used by every service that talks to the backend.
  static Future<http.Response> authedGet(Uri uri, {Duration? timeout}) =>
      _send((h) => http.get(uri, headers: h), timeout: timeout);

  /// Authenticated JSON POST.
  static Future<http.Response> authedPost(
    Uri uri,
    Object body, {
    Duration? timeout,
  }) => _send(
    (h) => http.post(uri, headers: h, body: jsonEncode(body)),
    json: true,
    timeout: timeout,
  );

  /// Fetches live Nifty & Sensex data.
  static Future<Map<String, dynamic>?> getMarket() async {
    try {
      final response = await authedGet(Uri.parse('$baseUrl/api/market'));
      if (response.statusCode == 200) {
        notifyReachable(true);
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      notifyReachable(false);
      return null;
    }
  }

  /// Fetches admin-curated signal picks with live price/% change.
  static Future<List<Map<String, dynamic>>> getSignals() async {
    try {
      final response = await authedGet(Uri.parse('$baseUrl/api/signals'));
      if (response.statusCode == 200) {
        notifyReachable(true);
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['signals'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      notifyReachable(false);
      return [];
    }
  }

  /// Registers this device's push token with the backend, along with which
  /// kinds of push it wants. Safe to call repeatedly — the backend treats the
  /// token as the identity and updates it in place. Returns true on success.
  static Future<bool> registerDevice({
    required String token,
    required String platform,
    required bool signals,
    String? appVersion,
  }) async {
    try {
      final response = await authedPost(Uri.parse('$baseUrl/api/devices/register'), {
        'token': token,
        'platform': platform,
        'signals': signals,
        'app_version': ?appVersion,
      });
      if (response.statusCode == 200) {
        notifyReachable(true);
        return true;
      }
      return false;
    } catch (_) {
      notifyReachable(false);
      return false;
    }
  }

  /// Removes this device's push token from the backend (push switched off).
  static Future<bool> unregisterDevice(String token) async {
    try {
      final response = await authedPost(Uri.parse('$baseUrl/api/devices/unregister'), {
        'token': token,
      });
      if (response.statusCode == 200) {
        notifyReachable(true);
        return true;
      }
      return false;
    } catch (_) {
      notifyReachable(false);
      return false;
    }
  }

  /// Fetches the current placeholder market-sentiment value (0-100 scale)
  /// for the Insights tab gauge.
  static Future<Map<String, dynamic>?> getSentiment() async {
    try {
      final response = await authedGet(Uri.parse('$baseUrl/api/sentiment'));
      if (response.statusCode == 200) {
        notifyReachable(true);
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      notifyReachable(false);
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getLearnArticles() async {
    return _getCachedList(
      endpoint: '/api/learn',
      rootKey: 'articles',
      cacheKey: 'content_learn_articles',
    );
  }

  static Future<List<Map<String, dynamic>>> getInsights() async {
    return _getCachedList(
      endpoint: '/api/insights',
      rootKey: 'insights',
      cacheKey: 'content_insights',
    );
  }

  static Future<List<Map<String, dynamic>>> _getCachedList({
    required String endpoint,
    required String rootKey,
    required String cacheKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheBody = prefs.getString(cacheKey);
    final cacheTime = prefs.getInt('${cacheKey}_saved_at') ?? 0;
    final isFresh =
        DateTime.now().millisecondsSinceEpoch - cacheTime <
        _contentCacheTtl.inMilliseconds;

    if (isFresh && cacheBody != null) {
      final cached = jsonDecode(cacheBody) as List<dynamic>;
      return cached.cast<Map<String, dynamic>>();
    }

    try {
      final response = await authedGet(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        notifyReachable(true);
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data[rootKey] as List<dynamic>? ?? [];
        await prefs.setString(cacheKey, jsonEncode(list));
        await prefs.setInt(
          '${cacheKey}_saved_at',
          DateTime.now().millisecondsSinceEpoch,
        );
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      notifyReachable(false);
      // Falls through to the stale-cache-or-empty return below, same as a
      // non-200 response.
    }

    if (cacheBody != null) {
      final cached = jsonDecode(cacheBody) as List<dynamic>;
      return cached.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
