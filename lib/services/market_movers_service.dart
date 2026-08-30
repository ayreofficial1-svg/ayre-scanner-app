import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// One row of market-mover data.
///
/// `symbol`, `lastPrice`, `change`, `percentChange` and `asOf` are always
/// required — a row missing any of them is dropped and the section falls back
/// to its error/empty treatment rather than rendering a broken card.
/// `companyName` falls back to `symbol`; `volumeOrValue` is required for Most
/// Active and optional elsewhere, and its UI degrades gracefully when absent.
class MarketMover {
  const MarketMover({
    required this.symbol,
    required this.companyName,
    required this.lastPrice,
    required this.change,
    required this.percentChange,
    required this.asOf,
    this.volumeOrValue,
  });

  final String symbol;
  final String companyName;
  final num lastPrice;

  /// Absolute change; may be negative. Drives the sign.
  final num change;

  /// Headline figure for ranking and display.
  final num percentChange;
  final DateTime asOf;
  final num? volumeOrValue;

  /// Returns null when a required field is missing or unparseable, so callers
  /// can drop the row instead of shipping a half-rendered one.
  static MarketMover? tryParse(Map<String, dynamic> json) {
    final symbol = _string(json, const ['symbol', 'ticker', 'scrip']);
    final lastPrice = _num(json, const ['lastPrice', 'last_price', 'ltp', 'price']);
    final change = _num(json, const ['change', 'net_change', 'netChange']);
    final percent = _num(json, const [
      'percentChange',
      'percent_change',
      'change_pct',
      'pChange',
    ]);
    final asOf = _time(json, const ['asOf', 'as_of', 'updated_at', 'timestamp']);

    if (symbol == null ||
        symbol.isEmpty ||
        lastPrice == null ||
        change == null ||
        percent == null ||
        asOf == null) {
      return null;
    }

    return MarketMover(
      symbol: symbol,
      companyName:
          _string(json, const ['companyName', 'company_name', 'name']) ?? symbol,
      lastPrice: lastPrice,
      change: change,
      percentChange: percent,
      asOf: asOf,
      volumeOrValue: _num(json, const [
        'volumeOrValue',
        'volume_or_value',
        'volume',
        'totalTradedValue',
        'traded_value',
      ]),
    );
  }

  static String? _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static num? _num(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value.replaceAll(',', '').trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static DateTime? _time(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is int) {
        // Accept both seconds and milliseconds since epoch.
        return DateTime.fromMillisecondsSinceEpoch(
          value < 100000000000 ? value * 1000 : value,
        );
      }
    }
    return null;
  }
}

/// A section's result: the rows plus enough context for the UI to choose
/// between its loaded / empty / stale / error treatments without knowing
/// anything about the provider.
class MarketMoversResult {
  const MarketMoversResult.data(this.rows, {this.stale = false})
    : failed = false;

  const MarketMoversResult.failure()
    : rows = const [],
      stale = false,
      failed = true;

  final List<MarketMover> rows;

  /// `asOf` is older than the provider's normal cadence. Last-known data stays
  /// visible; the UI flags it with the ember token and explicit copy.
  final bool stale;

  /// Request failed, or the provider was unreachable. Both get the same
  /// user-facing treatment — the distinction only matters for logging and
  /// retry behind this interface.
  final bool failed;

  bool get isEmpty => !failed && rows.isEmpty;
}

/// The only market-mover dependency any widget has. No widget calls a specific
/// backend, HTTP client or URL directly, so the concrete source — an NSE
/// community-library wrapper, a commercial market-data API, a backend proxy,
/// or a temporary development source — stays swappable without touching UI.
abstract interface class MarketMoversService {
  Future<MarketMoversResult> getTopGainers();
  Future<MarketMoversResult> getTopLosers();
  Future<MarketMoversResult> getMostActiveEquities();
}

/// Reads the three sections from the Ayre backend. Chosen because it keeps the
/// provider decision on the server, where it can change without an app release.
class AyreBackendMarketMoversService implements MarketMoversService {
  const AyreBackendMarketMoversService({
    this.baseUrl = ApiService.baseUrl,
    this.cadence = const Duration(minutes: 5),
  });

  final String baseUrl;

  /// How old a reading may get before the section is flagged stale.
  final Duration cadence;

  @override
  Future<MarketMoversResult> getTopGainers() => _fetch(
    '/api/market/gainers',
    'gainers',
    (a, b) => b.percentChange.compareTo(a.percentChange),
  );

  @override
  Future<MarketMoversResult> getTopLosers() => _fetch(
    '/api/market/losers',
    'losers',
    (a, b) => a.percentChange.compareTo(b.percentChange),
  );

  @override
  Future<MarketMoversResult> getMostActiveEquities() => _fetch(
    '/api/market/most-active',
    'most_active',
    (a, b) => (b.volumeOrValue ?? 0).compareTo(a.volumeOrValue ?? 0),
    requireVolume: true,
  );

  Future<MarketMoversResult> _fetch(
    String path,
    String rootKey,
    Comparator<MarketMover> order, {
    bool requireVolume = false,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const MarketMoversResult.failure();

      final decoded = jsonDecode(response.body);
      final list = switch (decoded) {
        List<dynamic> l => l,
        Map<String, dynamic> m => m[rootKey] as List<dynamic>? ?? const [],
        _ => const <dynamic>[],
      };

      final rows = <MarketMover>[];
      for (final entry in list) {
        if (entry is! Map<String, dynamic>) continue;
        final row = MarketMover.tryParse(entry);
        if (row == null) continue;
        if (requireVolume && row.volumeOrValue == null) continue;
        rows.add(row);
      }
      rows.sort(order);

      final newest = rows.isEmpty
          ? null
          : rows
                .map((r) => r.asOf)
                .reduce((a, b) => a.isAfter(b) ? a : b);
      final stale =
          newest != null && DateTime.now().difference(newest) > cadence;

      return MarketMoversResult.data(rows, stale: stale);
    } catch (_) {
      // Provider down, unreachable, or malformed: same user-facing treatment.
      return const MarketMoversResult.failure();
    }
  }
}
