import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all calls to the Ayre Scanner backend, including
/// session-cookie auth (Flask sets a cookie on login; we store it
/// and re-attach it on every request).
class ApiService {
  static const String baseUrl =
      'https://ayre-scanner-production.up.railway.app';

  static String? _cookie;

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
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      _captureCookie(response);
      return true;
    }
    return false;
  }

  /// Checks if there's a valid session and returns the user info
  /// (e.g. {username, display_name}), or null if not logged in.
  static Future<Map<String, dynamic>?> getSession() async {
    if (_cookie == null) return null;
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/session'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/api/auth/logout'), headers: _headers());
    await _saveCookie(null);
  }

  /// Fetches live Nifty & Sensex data.
  static Future<Map<String, dynamic>?> getMarket() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/market'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Fetches admin-curated signal picks with live price/% change.
  static Future<List<Map<String, dynamic>>> getSignals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/signals'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['signals'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetches the current placeholder market-sentiment value (0-100 scale)
  /// for the Insights tab gauge.
  static Future<Map<String, dynamic>?> getSentiment() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/sentiment'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}
