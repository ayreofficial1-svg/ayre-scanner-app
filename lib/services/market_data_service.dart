import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'fault_injection.dart';
import 'market_models.dart';

/// A section's result: the payload plus enough context for the UI to pick between
/// its ready / empty / failed / stale treatments without knowing anything about
/// the transport.
class DataResult<T> {
  const DataResult.ready(this.value, {this.stale = false})
    : failure = null,
      isEmpty = false;

  const DataResult.empty()
    : value = null,
      failure = null,
      stale = false,
      isEmpty = true;

  const DataResult.failed(this.failure)
    : value = null,
      stale = false,
      isEmpty = false;

  final T? value;
  final DataFailure? failure;

  /// Older than the feed's normal cadence. Last-known values stay visible and
  /// the UI flags the delay — this is degraded-but-shown, not an error.
  final bool stale;
  final bool isEmpty;

  bool get isReady => value != null;
  bool get isFailed => failure != null;

  DataPhaseSnapshot get phase {
    if (isFailed) return DataPhaseSnapshot.failed;
    if (isEmpty) return DataPhaseSnapshot.empty;
    if (isReady) return DataPhaseSnapshot.ready;
    return DataPhaseSnapshot.empty;
  }
}

enum DataPhaseSnapshot { ready, empty, failed }

/// Everything the app needs from a market feed. Screens depend on this interface
/// only, so the concrete source — the Ayre backend, a vendor API, an exchange
/// wrapper, or a QA double — is swappable without touching a widget.
abstract interface class MarketDataService {
  /// The three primary instruments on Home.
  Future<DataResult<List<Quote>>> getIndexBoard();

  /// A single index's current reading, for Index Detail's header.
  Future<DataResult<Quote>> getIndex(IndexId index);

  /// Every company in an index. Fails independently of [getIndex].
  Future<DataResult<List<Quote>>> getConstituents(IndexId index);

  /// One equity's reading and key stats.
  Future<DataResult<Quote>> getEquity(String symbol);

  Future<DataResult<Sentiment>> getSentiment({required bool monthly});

  Future<DataResult<List<Quote>>> getTopGainers();
  Future<DataResult<List<Quote>>> getTopLosers();
  Future<DataResult<List<Quote>>> getMostActive();

  Future<DataResult<List<Signal>>> getSignals();
  Future<DataResult<List<Course>>> getCourses();
  Future<DataResult<List<InsightNote>>> getInsightNotes();
}

/// Reads every surface from the Ayre backend.
///
/// Endpoint paths are declared in one place here so the backend contract is
/// legible and changeable without hunting through screens. Each call is guarded
/// by [FaultInjector] so QA can force any of the seven conditions per surface.
class RemoteMarketDataService implements MarketDataService {
  const RemoteMarketDataService({
    this.baseUrl = ApiService.baseUrl,
    this.timeout = const Duration(seconds: 12),
    this.cadence = const Duration(minutes: 5),
  });

  final String baseUrl;
  final Duration timeout;

  /// How old a reading may be before its section is flagged as delayed.
  final Duration cadence;

  // ── Endpoint contract ────────────────────────────────────────────────────
  static const _indexBoard = '/api/market';
  static const _sentiment = '/api/sentiment';
  static const _signals = '/api/signals';
  static const _courses = '/api/learn';
  static const _insightNotes = '/api/insights';
  static String _index(IndexId i) => '/api/market/indices/${i.id.toLowerCase()}';
  static String _constituents(IndexId i) =>
      '/api/market/indices/${i.id.toLowerCase()}/constituents';
  static String _equity(String symbol) =>
      '/api/market/equities/${Uri.encodeComponent(symbol.toUpperCase())}';
  static const _gainers = '/api/market/gainers';
  static const _losers = '/api/market/losers';
  static const _mostActive = '/api/market/most-active';

  @override
  Future<DataResult<List<Quote>>> getIndexBoard() {
    return _listOrQuoteMap(
      surface: DataSurface.indexBoard,
      path: _indexBoard,
      rootKeys: const ['indices', 'index_board', 'data'],
      // The board is a fixed set of instruments; when the payload is a plain map
      // keyed by index name, pull the three we show.
      fromMap: (map) {
        final out = <Quote>[];
        for (final index in IndexId.values) {
          final raw = map[index.apiKey] ??
              map[index.apiKey.toUpperCase()] ??
              map[index.id] ??
              map[index.id.toLowerCase()];
          if (raw is Map) {
            final quote = Quote.tryParse(
              raw.cast<String, dynamic>(),
              fallbackSymbol: index.id,
            );
            if (quote != null) {
              out.add(_named(quote, index.label));
            }
          }
        }
        return out;
      },
    );
  }

  @override
  Future<DataResult<Quote>> getIndex(IndexId index) {
    return _single(
      surface: DataSurface.indexDetail,
      path: _index(index),
      fallbackSymbol: index.id,
      rename: index.label,
    );
  }

  @override
  Future<DataResult<List<Quote>>> getConstituents(IndexId index) {
    return _quoteList(
      surface: DataSurface.indexConstituents,
      path: _constituents(index),
      rootKeys: const ['constituents', 'equities', 'data'],
    );
  }

  @override
  Future<DataResult<Quote>> getEquity(String symbol) {
    return _single(
      surface: DataSurface.equityDetail,
      path: _equity(symbol),
      fallbackSymbol: symbol.toUpperCase(),
    );
  }

  @override
  Future<DataResult<List<Quote>>> getTopGainers() => _quoteList(
    surface: DataSurface.gainers,
    path: _gainers,
    rootKeys: const ['gainers', 'data'],
    sort: (a, b) => b.percentChange.compareTo(a.percentChange),
  );

  @override
  Future<DataResult<List<Quote>>> getTopLosers() => _quoteList(
    surface: DataSurface.losers,
    path: _losers,
    rootKeys: const ['losers', 'data'],
    sort: (a, b) => a.percentChange.compareTo(b.percentChange),
  );

  @override
  Future<DataResult<List<Quote>>> getMostActive() => _quoteList(
    surface: DataSurface.mostActive,
    path: _mostActive,
    rootKeys: const ['most_active', 'mostActive', 'data'],
    requireVolume: true,
    sort: (a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0),
  );

  @override
  Future<DataResult<Sentiment>> getSentiment({required bool monthly}) async {
    return _run(DataSurface.sentiment, () async {
      final body = await _get('$_sentiment?window=${monthly ? 'monthly' : 'weekly'}');
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = Sentiment.tryParse(decoded);
      if (parsed == null) throw const DataFailure.malformed();
      return DataResult.ready(
        parsed,
        stale: _isStale(parsed.asOf, DataSurface.sentiment),
      );
    }, onEmpty: () => const DataResult<Sentiment>.empty());
  }

  @override
  Future<DataResult<List<Signal>>> getSignals() {
    return _parsedList(
      surface: DataSurface.signals,
      path: _signals,
      rootKeys: const ['signals', 'data'],
      parse: Signal.tryParse,
    );
  }

  @override
  Future<DataResult<List<Course>>> getCourses() {
    return _parsedList(
      surface: DataSurface.courses,
      path: _courses,
      rootKeys: const ['articles', 'courses', 'lessons', 'data'],
      parse: Course.tryParse,
    );
  }

  @override
  Future<DataResult<List<InsightNote>>> getInsightNotes() {
    return _parsedList(
      surface: DataSurface.insightNotes,
      path: _insightNotes,
      rootKeys: const ['insights', 'notes', 'data'],
      parse: InsightNote.tryParse,
    );
  }

  // ── Plumbing ─────────────────────────────────────────────────────────────

  Quote _named(Quote quote, String name) => Quote(
    symbol: quote.symbol,
    name: name,
    lastPrice: quote.lastPrice,
    change: quote.change,
    percentChange: quote.percentChange,
    asOf: quote.asOf,
    previousClose: quote.previousClose,
    dayLow: quote.dayLow,
    dayHigh: quote.dayHigh,
    volume: quote.volume,
    trace: quote.trace,
  );

  /// Every HTTP concern lives here: the session cookie, the timeout, and the
  /// mapping from transport outcomes onto [DataFailure].
  Future<String> _get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: ApiService.authHeaders())
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const DataFailure.session();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DataFailure.api(statusCode: response.statusCode);
      }
      return response.body;
    } on DataFailure {
      rethrow;
    } on TimeoutException {
      throw const DataFailure.timeout();
    } catch (_) {
      // DNS failure, socket error, malformed URL — all "we couldn't reach it".
      throw const DataFailure.offline();
    }
  }

  bool _isStale(DateTime asOf, DataSurface surface) {
    if (FaultInjector.instance.forcesStale(surface)) return true;
    return DateTime.now().difference(asOf) > cadence;
  }

  /// Wraps a fetch in fault injection and turns any [DataFailure] into a result
  /// the UI can render, so no screen ever sees a raw exception.
  Future<DataResult<T>> _run<T>(
    DataSurface surface,
    Future<DataResult<T>> Function() body, {
    DataResult<T> Function()? onEmpty,
  }) async {
    try {
      return await FaultInjector.instance.guard<DataResult<T>>(
        surface,
        body,
        onEmpty: onEmpty,
        onMalformed: () => const DataResult.failed(DataFailure.malformed()),
      );
    } on DataFailure catch (failure) {
      return DataResult.failed(failure);
    } catch (_) {
      return const DataResult.failed(DataFailure.malformed());
    }
  }

  List<dynamic> _rootList(Object? decoded, List<String> rootKeys) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in rootKeys) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    throw const DataFailure.malformed();
  }

  Future<DataResult<List<Quote>>> _quoteList({
    required DataSurface surface,
    required String path,
    required List<String> rootKeys,
    Comparator<Quote>? sort,
    bool requireVolume = false,
  }) {
    return _run(surface, () async {
      final decoded = jsonDecode(await _get(path));
      final rows = <Quote>[];
      for (final entry in _rootList(decoded, rootKeys)) {
        if (entry is! Map) continue;
        final quote = Quote.tryParse(entry.cast<String, dynamic>());
        if (quote == null) continue;
        if (requireVolume && quote.volume == null) continue;
        rows.add(quote);
      }
      if (rows.isEmpty) return const DataResult<List<Quote>>.empty();
      if (sort != null) rows.sort(sort);
      return DataResult.ready(rows, stale: _isStale(_newest(rows), surface));
    }, onEmpty: () => const DataResult<List<Quote>>.empty());
  }

  Future<DataResult<List<Quote>>> _listOrQuoteMap({
    required DataSurface surface,
    required String path,
    required List<String> rootKeys,
    required List<Quote> Function(Map<String, dynamic> map) fromMap,
  }) {
    return _run(surface, () async {
      final decoded = jsonDecode(await _get(path));

      List<Quote> rows;
      if (decoded is Map<String, dynamic> &&
          !rootKeys.any((k) => decoded[k] is List)) {
        rows = fromMap(decoded);
      } else {
        rows = [
          for (final entry in _rootList(decoded, rootKeys))
            if (entry is Map)
              ?Quote.tryParse(entry.cast<String, dynamic>()),
        ];
      }

      if (rows.isEmpty) return const DataResult<List<Quote>>.empty();
      return DataResult.ready(rows, stale: _isStale(_newest(rows), surface));
    }, onEmpty: () => const DataResult<List<Quote>>.empty());
  }

  Future<DataResult<Quote>> _single({
    required DataSurface surface,
    required String path,
    String? fallbackSymbol,
    String? rename,
  }) {
    return _run(surface, () async {
      final decoded = jsonDecode(await _get(path));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      // Accept both a bare quote and one nested under a conventional key.
      final raw = switch (decoded) {
        {'quote': final Map<String, dynamic> q} => q,
        {'data': final Map<String, dynamic> q} => q,
        _ => decoded,
      };
      var quote = Quote.tryParse(raw, fallbackSymbol: fallbackSymbol);
      if (quote == null) throw const DataFailure.malformed();
      if (rename != null) quote = _named(quote, rename);
      return DataResult.ready(quote, stale: _isStale(quote.asOf, surface));
    }, onEmpty: () => const DataResult<Quote>.empty());
  }

  Future<DataResult<List<T>>> _parsedList<T>({
    required DataSurface surface,
    required String path,
    required List<String> rootKeys,
    required T? Function(Map<String, dynamic> json) parse,
  }) {
    return _run(surface, () async {
      final decoded = jsonDecode(await _get(path));
      final rows = <T>[];
      for (final entry in _rootList(decoded, rootKeys)) {
        if (entry is! Map) continue;
        final parsed = parse(entry.cast<String, dynamic>());
        if (parsed != null) rows.add(parsed);
      }
      if (rows.isEmpty) return DataResult<List<T>>.empty();
      return DataResult.ready(rows);
    }, onEmpty: () => DataResult<List<T>>.empty());
  }

  DateTime _newest(List<Quote> rows) => rows
      .map((r) => r.asOf)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}
