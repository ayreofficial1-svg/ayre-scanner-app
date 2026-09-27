import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves a real company logo image URL for a stock symbol, so
/// `AyreInstrumentTile` can show one wherever a stock's symbol/name is
/// displayed — falling back to its existing offline monogram whenever a
/// logo can't be found, confirmed, or reached.
///
/// ## Why this exists
/// Neither the backend nor NSE's public feeds carry company logo imagery.
/// This resolves logos entirely on-device from free, keyless third-party
/// lookups, in priority order:
///
/// 1. **Ticker Logos by AllInvestView** (primary) — a free, keyless search
///    endpoint (`/api/logo-search/`) maps a ticker or company name to the
///    company's website domain; a keyless CDN
///    (`cdn.tickerlogos.com/{domain}`) then serves the logo image itself.
///    No account, no API key, no signup — see
///    https://www.allinvestview.com/tools/ticker-logos/docs/.
/// 2. **Logo.dev** (secondary, opt-in) — its ticker route
///    (`img.logo.dev/ticker/{SYMBOL}.NS`) understands NSE's `.NS` suffix
///    directly, but requires a free publishable key from
///    https://www.logo.dev. This project ships without one (there is no
///    universal free key to hardcode), so this step only activates if the
///    app is built with
///    `--dart-define=LOGO_DEV_PUBLISHABLE_KEY=pk_your_key_here`. Without
///    that define, this step is skipped and step 3 runs immediately.
/// 3. **Monogram tile** — `AyreInstrumentTile`'s existing offline fallback.
///    Used whenever neither service has a confident match, both fail to
///    load, or the device is offline. A row never shows a broken image or
///    blocks on a logo.
///
/// ## Correctness over coverage
/// A wrong logo (a same-named or same-tickered but unrelated foreign
/// company) is worse than no logo, so [_pickBestMatch] would rather return
/// nothing than guess: it requires either a real word-overlap with the
/// known company name or an India-tagged exchange on an exact symbol match
/// before accepting a result. Everything it declines to match falls through
/// to the monogram tile, same as a service outage would.
///
/// ## Caching
/// Every resolution — a hit, a confident miss, or a broken image reported
/// later by the widget via [reportBroken] — is cached both in memory for
/// the running session and on-device (`shared_preferences`, the same store
/// `MarketDataCache` already uses elsewhere in this app) so a symbol is
/// looked up across the network at most once per cache window, not once
/// per row per rebuild.
///
/// ## Rate-limiting
/// AllInvestView's free tier allows 60 search requests/minute/IP and 30 CDN
/// requests/10s/IP. A single screen can mount dozens of tiles at once (a
/// Nifty 500 constituent list, say), so lookups run through a small
/// concurrency gate ([_gate]) instead of firing all at once.
class StockLogoService {
  const StockLogoService._();

  // ── Tuning ───────────────────────────────────────────────────────────────

  /// How long a *successful* resolution is trusted before being looked up
  /// again. A company's logo/domain essentially never changes, so this is
  /// generous.
  static const Duration _foundTtl = Duration(days: 30);

  /// How long a *miss* (no confident match, or a load failure) is trusted
  /// before being retried. Shorter than [_foundTtl] so a stock added to the
  /// lookup services later, or a transient failure, is retried eventually
  /// rather than treated as permanent.
  static const Duration _missTtl = Duration(days: 14);

  /// Network timeout for a single lookup call. Short enough that a stalled
  /// request can't hold up a whole list's tiles.
  static const Duration _timeout = Duration(seconds: 8);

  /// Max simultaneous network lookups. Keeps a big list's first render well
  /// under AllInvestView's free-tier burst limits.
  static final _gate = _Semaphore(4);

  static const _prefsPrefix = 'stock_logo::';

  /// Optional Logo.dev publishable key. Empty (the default) disables the
  /// Logo.dev fallback entirely — see the class doc's step 2. Provide one
  /// with `flutter build ... --dart-define=LOGO_DEV_PUBLISHABLE_KEY=pk_...`.
  static const String _logoDevKey = String.fromEnvironment(
    'LOGO_DEV_PUBLISHABLE_KEY',
  );

  // ── In-memory state (this running session only) ─────────────────────────

  /// Resolved this session: `''` means "confidently no logo", anything else
  /// is a display URL. A symbol absent from this map hasn't been resolved
  /// yet this session (on-device cache may still have an answer).
  static final Map<String, String> _memory = {};

  /// De-dupes concurrent resolutions of the same symbol (e.g. the same
  /// stock appearing in two lists on screen at once).
  static final Map<String, Future<String>> _inFlight = {};

  static String _key(String symbol) => symbol.trim().toUpperCase();

  // ── Public API ───────────────────────────────────────────────────────────

  /// Whatever is already known about [symbol] *without* making a network or
  /// disk call: a display URL, `''` if this session already found nothing
  /// usable, or null if [resolve] hasn't been called (or hasn't finished)
  /// for this symbol yet this session.
  ///
  /// `AyreInstrumentTile` checks this first so a symbol resolved earlier in
  /// the session (e.g. on Home) shows its logo immediately, with no loading
  /// flicker, when the same symbol appears again elsewhere.
  static String? peek(String symbol) => _memory[_key(symbol)];

  /// Resolves [symbol] to a logo display URL, or `''` if none can be found.
  /// [name] (the company name, when the caller has it) sharply improves
  /// match confidence — see the class doc — and should be passed whenever
  /// available.
  ///
  /// Safe to call repeatedly for the same symbol from many widgets at once:
  /// concurrent calls share one lookup ([_inFlight]), and a resolved answer
  /// is reused from memory/disk long after.
  static Future<String> resolve(String symbol, {String? name}) async {
    final key = _key(symbol);
    final cached = _memory[key];
    if (cached != null) return cached;

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _resolveUncached(symbol: symbol, key: key, name: name);
    _inFlight[key] = future;
    try {
      final result = await future;
      _memory[key] = result;
      return result;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Called by `AyreInstrumentTile` when a previously-resolved logo URL
  /// fails to actually load (a stale domain, a since-removed image, a
  /// transient CDN error indistinguishable from a permanent one). Downgrades
  /// the cached answer to "no logo" so the tile falls back to its monogram
  /// immediately and stops retrying the same broken URL on every rebuild.
  static void reportBroken(String symbol) {
    final key = _key(symbol);
    _memory[key] = '';
    unawaited(_savePersisted(key, ''));
  }

  // ── Resolution pipeline ──────────────────────────────────────────────────

  static Future<String> _resolveUncached({
    required String symbol,
    required String key,
    String? name,
  }) async {
    final persisted = await _loadPersisted(key);
    if (persisted != null) return persisted;

    await _gate.acquire();
    try {
      final fromAllInvestView = await _lookupAllInvestView(
        symbol: symbol,
        name: name,
      );
      final logo = fromAllInvestView ?? _logoDevFallbackUrl(symbol);
      await _savePersisted(key, logo ?? '');
      return logo ?? '';
    } catch (_) {
      // Never let a lookup failure surface past this service — the tile
      // must always be able to fall back to its monogram.
      await _savePersisted(key, '');
      return '';
    } finally {
      _gate.release();
    }
  }

  /// Queries AllInvestView's free search API, first by company [name] (far
  /// less ambiguous — e.g. "Tata Consultancy Services" vs. the bare ticker
  /// `TCS`, which collides with a US-listed retailer), then by [symbol] if
  /// that yields nothing usable. Returns a `cdn.tickerlogos.com` display URL
  /// on a confident match, or null.
  static Future<String?> _lookupAllInvestView({
    required String symbol,
    String? name,
  }) async {
    final queries = <String>{
      if (name != null && name.trim().length >= 3) name.trim(),
      symbol.trim(),
    };

    for (final query in queries) {
      final results = await _searchAllInvestView(query);
      if (results.isEmpty) continue;
      final match = _pickBestMatch(results: results, symbol: symbol, name: name);
      final website = match?['website'] as String?;
      if (website != null && website.trim().isNotEmpty) {
        return 'https://cdn.tickerlogos.com/${website.trim()}';
      }
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> _searchAllInvestView(
    String query,
  ) async {
    try {
      final uri = Uri.https(
        'www.allinvestview.com',
        '/api/logo-search/',
        {'q': query},
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return const [];
      final results = body['results'];
      if (results is! List) return const [];
      return results.whereType<Map>().map((r) => r.cast<String, dynamic>()).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Picks the safest match from a search result set, or null if none is
  /// confident enough to trust — see the class doc's "Correctness over
  /// coverage". Never guesses from symbol alone unless the result is also
  /// tagged to an Indian exchange, since a bare NSE ticker can collide with
  /// an unrelated ticker on a global exchange (e.g. `TCS` on NYSE).
  static Map<String, dynamic>? _pickBestMatch({
    required List<Map<String, dynamic>> results,
    required String symbol,
    String? name,
  }) {
    final indianTagged = results.where(_isIndianExchange).toList();
    final pool = indianTagged.isNotEmpty ? indianTagged : results;

    if (name != null && name.trim().isNotEmpty) {
      final nameTokens = _significantTokens(name);
      Map<String, dynamic>? best;
      var bestOverlap = 0;
      for (final result in pool) {
        final candidateTokens = _significantTokens(
          (result['name'] as String?) ?? '',
        );
        final overlap = nameTokens.intersection(candidateTokens).length;
        if (overlap > bestOverlap) {
          bestOverlap = overlap;
          best = result;
        }
      }
      if (best != null && bestOverlap > 0) return best;
    }

    // No usable company name, or no result shared a real word with it:
    // only trust an exact symbol match that's also tagged to an Indian
    // exchange.
    for (final result in indianTagged) {
      final resultSymbol = (result['symbol'] as String?)?.toUpperCase();
      if (resultSymbol == symbol.trim().toUpperCase()) return result;
    }
    return null;
  }

  static bool _isIndianExchange(Map<String, dynamic> result) {
    final exchange = (result['exchange'] as String?)?.toUpperCase() ?? '';
    return exchange.contains('NSE') ||
        exchange.contains('BSE') ||
        exchange.contains('BOM') ||
        exchange.contains('NATIONAL STOCK EXCHANGE') ||
        exchange.contains('BOMBAY');
  }

  /// Common corporate suffixes stripped before comparing names, so
  /// "Reliance Industries Ltd" and "Reliance Industries Limited" still
  /// overlap fully.
  static const _genericWords = {
    'ltd',
    'limited',
    'inc',
    'incorporated',
    'corp',
    'corporation',
    'plc',
    'co',
    'company',
  };

  static Set<String> _significantTokens(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    return cleaned
        .split(' ')
        .where((w) => w.length >= 3 && !_genericWords.contains(w))
        .toSet();
  }

  /// Builds a Logo.dev ticker-route URL for [symbol] on NSE (`.NS` suffix),
  /// or null when no publishable key is configured (see [_logoDevKey]).
  /// `fallback=404` asks Logo.dev for a real 404 instead of its default
  /// generated monogram, so a miss here reaches `AyreInstrumentTile`'s own
  /// monogram instead of showing two different placeholder styles.
  static String? _logoDevFallbackUrl(String symbol) {
    if (_logoDevKey.isEmpty) return null;
    final uri = Uri.https('img.logo.dev', '/ticker/${symbol.trim()}.NS', {
      'token': _logoDevKey,
      'fallback': '404',
      'size': '64',
    });
    return uri.toString();
  }

  // ── On-device cache ──────────────────────────────────────────────────────

  static Future<String?> _loadPersisted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsPrefix$key');
      if (raw == null) return null;
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return null;
      final url = envelope['url'] as String?;
      final cachedAtRaw = envelope['cachedAt'] as String?;
      if (url == null || cachedAtRaw == null) return null;
      final cachedAt = DateTime.tryParse(cachedAtRaw);
      if (cachedAt == null) return null;
      final ttl = url.isEmpty ? _missTtl : _foundTtl;
      if (DateTime.now().difference(cachedAt) > ttl) return null;
      return url;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _savePersisted(String key, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefsPrefix$key',
        jsonEncode({
          'url': url,
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {
      // Best-effort — a missed persist just means this symbol is looked up
      // again next session, same as a cold start.
    }
  }
}

/// A tiny counting semaphore so at most [max] lookups run at once. There is
/// no `package:async`/`pool` dependency in this project, so this is
/// deliberately self-contained rather than pulling one in for four lines of
/// logic.
class _Semaphore {
  _Semaphore(this.max);

  final int max;
  int _current = 0;
  final List<Completer<void>> _waiting = [];

  Future<void> acquire() async {
    if (_current < max) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    await completer.future;
    _current++;
  }

  void release() {
    _current--;
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    }
  }
}
