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
/// The endpoint map below was verified against the backend source rather than
/// assumed. Three consequences shaped this class:
///
///  * **`/api/market` reports change as a percentage.** Its `change` field is
///    `percentChange` and `points` is the absolute move — the opposite of the
///    conventional naming. Read the wrong way round, the app showed a percentage
///    where an absolute belonged and then derived a nonsense percentage from it.
///
///  * **There are no movers endpoints.** No `/gainers`, `/losers` or
///    `/most-active` exists anywhere in the backend. They are derived here from
///    the constituents endpoint, which returns 50 stocks with `change_pct` and
///    `volume` — so Insights works end to end with no backend change.
///
///  * **`/api/sentiment` has no advance/decline counts.** It returns a single
///    stored number. Since v3's Home leads with Advances and Declines, those are
///    counted from the constituents data — which is what market breadth actually
///    is — rather than left permanently unavailable.
///
/// Derived values are cached briefly so one screen doesn't fetch the same
/// constituent list several times over.
class RemoteMarketDataService implements MarketDataService {
  RemoteMarketDataService({
    this.baseUrl = ApiService.baseUrl,
    this.timeout = const Duration(seconds: 12),
    this.cadence = const Duration(minutes: 5),
  });

  final String baseUrl;
  final Duration timeout;

  /// How old a reading may be before its section is flagged as delayed.
  final Duration cadence;

  // ── Endpoint contract, as the backend actually exposes it ────────────────
  static const _market = '/api/market';
  static const _sentiment = '/api/sentiment';
  static const _signals = '/api/signals';
  static const _courses = '/api/learn';
  static const _insightNotes = '/api/insights';
  static String _constituents(IndexId i) =>
      '/api/market/${i.apiKey}/constituents';

  /// Constituent lists are the source for movers, breadth and equity lookups,
  /// so they are cached for a short window to keep one screen to one fetch.
  static const _cacheTtl = Duration(seconds: 45);
  final Map<IndexId, (DateTime, List<Quote>)> _constituentCache = {};

  @override
  Future<DataResult<List<Quote>>> getIndexBoard() {
    return _run(DataSurface.indexBoard, () async {
      final decoded = jsonDecode(await _get(_market));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final raw = decoded['markets'];
      if (raw is! List) throw const DataFailure.malformed();

      final asOf =
          DateTime.tryParse(decoded['updated_at']?.toString() ?? '') ??
          DateTime.now();

      final byKey = <String, Quote>{};
      for (final entry in raw) {
        if (entry is! Map) continue;
        final quote = _parseMarketRow(entry.cast<String, dynamic>(), asOf);
        if (quote != null) byKey[quote.symbol] = quote;
      }

      // Fixed display order, and only the three instruments Home shows.
      final rows = [
        for (final index in IndexId.values)
          if (byKey[index.id] != null) byKey[index.id]!,
      ];
      if (rows.isEmpty) return const DataResult<List<Quote>>.empty();
      return DataResult.ready(
        rows,
        stale: _isStale(asOf, DataSurface.indexBoard),
      );
    }, onEmpty: () => const DataResult<List<Quote>>.empty());
  }

  /// One row of `/api/market`'s `markets` list.
  ///
  /// `change` is a percentage and `points` is the absolute move. Handled here
  /// explicitly so the inversion can't be reintroduced by a generic parser.
  Quote? _parseMarketRow(Map<String, dynamic> json, DateTime asOf) {
    final key = json['key']?.toString();
    final level = _asNum(json['value']);
    if (key == null || level == null) return null;

    final index = IndexId.values
        .where((i) => i.apiKey == key)
        .cast<IndexId?>()
        .firstWhere((_) => true, orElse: () => null);

    final percent = _asNum(json['change']) ?? 0;
    final points = _asNum(json['points']) ?? (level * percent / 100);

    return Quote(
      symbol: index?.id ?? key.toUpperCase(),
      // Prefer our own label so the board reads consistently with the rest of
      // the app, and fall back to whatever the feed called it.
      name: index?.label ?? (json['name']?.toString() ?? key),
      lastPrice: level,
      change: points,
      percentChange: percent,
      asOf: asOf,
    );
  }

  @override
  Future<DataResult<Quote>> getIndex(IndexId index) async {
    // There is no per-index endpoint; the board carries every index's reading.
    final board = await getIndexBoard();
    if (board.isFailed) return DataResult.failed(board.failure!);
    final match = board.value?.where((q) => q.symbol == index.id);
    if (match == null || match.isEmpty) return const DataResult<Quote>.empty();
    return DataResult.ready(match.first, stale: board.stale);
  }

  @override
  Future<DataResult<List<Quote>>> getConstituents(IndexId index) {
    return _run(DataSurface.indexConstituents, () async {
      final rows = await _fetchConstituents(index);
      if (rows.isEmpty) return const DataResult<List<Quote>>.empty();
      return DataResult.ready(
        rows,
        stale: _isStale(_newest(rows), DataSurface.indexConstituents),
      );
    }, onEmpty: () => const DataResult<List<Quote>>.empty());
  }

  @override
  Future<DataResult<Quote>> getEquity(String symbol) {
    return _run(DataSurface.equityDetail, () async {
      // No per-equity endpoint exists. `/api/quotes` carries only a last price
      // for signal/watchlist symbols, which isn't enough for the stats block, so
      // the constituent rows — which do carry name, range and volume — are the
      // source instead.
      final wanted = symbol.toUpperCase();
      for (final index in IndexId.values) {
        final rows = await _fetchConstituents(index);
        final match = rows.where((q) => q.symbol.toUpperCase() == wanted);
        if (match.isNotEmpty) {
          return DataResult.ready(
            match.first,
            stale: _isStale(match.first.asOf, DataSurface.equityDetail),
          );
        }
      }
      return const DataResult<Quote>.empty();
    }, onEmpty: () => const DataResult<Quote>.empty());
  }

  @override
  Future<DataResult<List<Quote>>> getTopGainers() => _movers(
    DataSurface.gainers,
    (a, b) => b.percentChange.compareTo(a.percentChange),
    keep: (q) => q.percentChange > 0,
  );

  @override
  Future<DataResult<List<Quote>>> getTopLosers() => _movers(
    DataSurface.losers,
    (a, b) => a.percentChange.compareTo(b.percentChange),
    keep: (q) => q.percentChange < 0,
  );

  @override
  Future<DataResult<List<Quote>>> getMostActive() => _movers(
    DataSurface.mostActive,
    (a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0),
    keep: (q) => q.volume != null && q.volume! > 0,
  );

  /// Movers are ranked across every index's constituents, de-duplicated by
  /// symbol, because no movers endpoint exists to ask.
  Future<DataResult<List<Quote>>> _movers(
    DataSurface surface,
    Comparator<Quote> order, {
    required bool Function(Quote) keep,
  }) {
    return _run(surface, () async {
      final rows = await _allConstituents();
      final eligible = rows.where(keep).toList()..sort(order);
      if (eligible.isEmpty) return const DataResult<List<Quote>>.empty();
      return DataResult.ready(
        eligible.take(10).toList(),
        stale: _isStale(_newest(rows), surface),
      );
    }, onEmpty: () => const DataResult<List<Quote>>.empty());
  }

  @override
  Future<DataResult<Sentiment>> getSentiment({required bool monthly}) {
    return _run(DataSurface.sentiment, () async {
      final decoded = jsonDecode(await _get(_sentiment));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = Sentiment.tryParse(decoded);
      if (parsed == null) throw const DataFailure.malformed();

      // The endpoint carries no advance/decline counts, so they are counted
      // from real per-stock changes rather than shown as unavailable. If the
      // constituent fetch fails, the score still renders on its own.
      int? advances;
      int? declines;
      int? unchanged;
      try {
        final rows = await _allConstituents();
        if (rows.isNotEmpty) {
          advances = rows.where((q) => q.percentChange > 0).length;
          declines = rows.where((q) => q.percentChange < 0).length;
          unchanged = rows.where((q) => q.percentChange == 0).length;
        }
      } on DataFailure {
        // Breadth is a bonus here; a failed count must not fail the reading.
      }

      return DataResult.ready(
        Sentiment(
          score: parsed.score,
          asOf: parsed.asOf,
          note: parsed.note,
          advances: advances ?? parsed.advances,
          declines: declines ?? parsed.declines,
          unchanged: unchanged ?? parsed.unchanged,
        ),
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

  Future<List<Quote>> _fetchConstituents(IndexId index) async {
    final cached = _constituentCache[index];
    if (cached != null && DateTime.now().difference(cached.$1) < _cacheTtl) {
      return cached.$2;
    }

    final decoded = jsonDecode(await _get(_constituents(index)));
    if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
    final raw = decoded['stocks'];
    if (raw is! List) throw const DataFailure.malformed();

    final asOf =
        DateTime.tryParse(decoded['updated_at']?.toString() ?? '') ??
        DateTime.now();

    final rows = <Quote>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = entry.cast<String, dynamic>();
      final quote = Quote.tryParse({...json, 'asOf': asOf.toIso8601String()});
      if (quote != null) rows.add(quote);
    }
    _constituentCache[index] = (DateTime.now(), rows);
    return rows;
  }

  /// Every index's constituents, de-duplicated by symbol. A single index failing
  /// does not sink the whole set.
  Future<List<Quote>> _allConstituents() async {
    final bySymbol = <String, Quote>{};
    var failures = 0;
    for (final index in IndexId.values) {
      try {
        for (final quote in await _fetchConstituents(index)) {
          bySymbol.putIfAbsent(quote.symbol.toUpperCase(), () => quote);
        }
      } on DataFailure {
        failures++;
      }
    }
    if (bySymbol.isEmpty && failures > 0) throw const DataFailure.api();
    return bySymbol.values.toList();
  }

  static num? _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.replaceAll(',', '').trim());
    return null;
  }

  /// Every HTTP concern lives here: the session cookie, the timeout, and the
  /// mapping from transport outcomes onto [DataFailure].
  Future<String> _get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: ApiService.authHeaders())
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        ApiService.notifySessionExpired();
        throw const DataFailure.session();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DataFailure.api(statusCode: response.statusCode);
      }
      ApiService.notifyReachable(true);
      return response.body;
    } on DataFailure {
      rethrow;
    } on TimeoutException {
      throw const DataFailure.timeout();
    } catch (_) {
      // DNS failure, socket error, malformed URL — all "we couldn't reach it".
      ApiService.notifyReachable(false);
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

  Future<DataResult<List<T>>> _parsedList<T>({
    required DataSurface surface,
    required String path,
    required List<String> rootKeys,
    required T? Function(Map<String, dynamic> json) parse,
  }) {
    return _run(surface, () async {
      final decoded = jsonDecode(await _get(path));
      List<dynamic>? list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        for (final key in rootKeys) {
          if (decoded[key] is List) {
            list = decoded[key] as List;
            break;
          }
        }
      }
      if (list == null) throw const DataFailure.malformed();

      final rows = <T>[];
      for (final entry in list) {
        if (entry is! Map) continue;
        final parsed = parse(entry.cast<String, dynamic>());
        if (parsed != null) rows.add(parsed);
      }
      if (rows.isEmpty) return DataResult<List<T>>.empty();
      return DataResult.ready(rows);
    }, onEmpty: () => DataResult<List<T>>.empty());
  }

  DateTime _newest(List<Quote> rows) =>
      rows.map((r) => r.asOf).reduce((a, b) => a.isAfter(b) ? a : b);
}
