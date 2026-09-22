import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all calls to the Ayre Scanner backend, including
/// session-cookie auth (Flask sets a cookie on login; we store it
/// and re-attach it on every request).
class ApiService {
  static const String baseUrl =
      'https://ayre-scanner-production.up.railway.app';

  static String? _cookie;
  static const Duration _contentCacheTtl = Duration(minutes: 10);

  /// Every call in this file goes through this timeout. Without it, a
  /// stalled request (a slow cold-start on the hosted backend, a dropped
  /// connection, anything) leaves its `await` hanging forever — no error,
  /// no fallback, just a screen stuck on its loading skeleton for good.
  /// `market_data_service.dart`'s own `_get()` already guards this way;
  /// this file didn't, and every method below called through it went
  /// unprotected — most importantly `getSession()`, which `HomeTab._load()`
  /// awaits first, before anything else on Home has a chance to load.
  static const Duration _timeout = Duration(seconds: 12);

  /// Load any saved cookie from disk (call this once at app startup).
  static Future<void> loadSavedCookie() async {
    final prefs = await SharedPreferences.getInstance();
    _cookie = prefs.getString('session_cookie');
  }

  static Future<void> _saveCookie(String? cookie) async {
    _cookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    if (cookie == null) {
      await prefs.remove('session_cookie');
    } else {
      await prefs.setString('session_cookie', cookie);
    }
  }

  /// Headers other services need in order to reuse this session. Exposed so the
  /// market data layer can attach the cookie without owning auth itself.
  static Map<String, String> authHeaders({bool json = false}) =>
      _headers(json: json);

  /// Fires when an authenticated call comes back 401/403, so the app can route to
  /// re-authentication instead of leaving the user on a screen that will never
  /// load. Set by the app shell.
  static VoidCallback? onSessionExpired;

  static void notifySessionExpired() => onSessionExpired?.call();

  /// Fires when a request succeeds or fails to reach the host at all, so the app
  /// can show or clear its offline banner without polling.
  static ValueChanged<bool>? onReachabilityChanged;

  static void notifyReachable(bool reachable) =>
      onReachabilityChanged?.call(reachable);

  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (_cookie != null) headers['Cookie'] = _cookie!;
    return headers;
  }

  /// Extracts the cookie value from a response's Set-Cookie header, if present.
  static void _captureCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      // Keep only the "key=value" part before the first ';'
      final cookieValue = setCookie.split(';').first;
      _saveCookie(cookieValue);
    }
  }

  /// Logs in with username/password. Returns true on success.
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: _headers(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        _captureCookie(response);
        notifyReachable(true);
        return true;
      }
      return false;
    } catch (_) {
      notifyReachable(false);
      return false;
    }
  }

  /// Checks if there's a valid session and returns the user info
  /// (e.g. {username, display_name}), or null if not logged in.
  static Future<Map<String, dynamic>?> getSession() async {
    if (_cookie == null) return null;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/auth/session'), headers: _headers())
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // The endpoint answers 200 with `authenticated: false` when there is no
        // session, so a successful status alone does not mean signed in. Treating
        // it that way let an unauthenticated user straight past the startup gate.
        notifyReachable(true);
        if (body['authenticated'] == true) return body;
        return null;
      }
      return null;
    } catch (_) {
      // A stalled/failed session check must not block the caller forever
      // (see [_timeout]'s doc) — treat it the same as "not logged in" and
      // let the rest of the load proceed rather than hang on it.
      notifyReachable(false);
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await http
          .post(Uri.parse('$baseUrl/api/auth/logout'), headers: _headers())
          .timeout(_timeout);
    } catch (_) {
      // Best-effort: the server-side session may outlive the client, but
      // clearing the local cookie below still signs this device out.
    }
    await _saveCookie(null);
  }

  /// Fetches live Nifty & Sensex data.
  static Future<Map<String, dynamic>?> getMarket() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/market'), headers: _headers())
          .timeout(_timeout);
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
      final response = await http
          .get(Uri.parse('$baseUrl/api/signals'), headers: _headers())
          .timeout(_timeout);
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

  /// Fetches the current placeholder market-sentiment value (0-100 scale)
  /// for the Insights tab gauge.
  static Future<Map<String, dynamic>?> getSentiment() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/sentiment'), headers: _headers())
          .timeout(_timeout);
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
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers())
          .timeout(_timeout);
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
