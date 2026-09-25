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

  /// If this result is a failure and [previous] holds good data, keep the good
  /// data instead. A transient failure (e.g. reconnecting after the app was
  /// backgrounded) must not wipe what is already on screen; the failed state
  /// only shows when there is nothing to show. Session failures always pass
  /// through, since those change what the app does.
  DataResult<T> keepingLastGood(DataResult<T>? previous) {
    if (!isFailed) return this;
    if (failure!.requiresReauth) return this;
    if (previous == null || !previous.isReady) return this;
    return previous;
  }

  DataPhaseSnapshot get phase {
    if (isFailed) return DataPhaseSnapshot.failed;
    if (isEmpty) return DataPhaseSnapshot.empty;
    if (isReady) return DataPhaseSnapshot.ready;
    return DataPhaseSnapshot.empty;
  }
}

enum DataPhaseSnapshot { ready, empty, failed }

/// How often screens showing live market data should poll.
///
/// The backend serves this from a single, always-open Fyers WebSocket
/// connection (see BACKEND_ANALYSIS.md / the Fyers-stream work) plus a
/// threaded dev server that can now actually handle concurrent requests, so
/// polling doesn't create extra Fyers or NSE requests — it only reads memory
/// the backend already has. 10 seconds is the agreed cadence for every
/// live-refreshing screen; this constant is the one place to change it.
const Duration liveMarketRefreshInterval = Duration(seconds: 10);

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

  /// Full Nifty-500 breadth (`GET /api/breadth/full`) — Home's donut source.
  /// Refreshes on its own fixed hourly schedule server-side, independent of
  /// [getSentiment]'s ~140-stock live-tick count.
  Future<DataResult<FullBreadth>> getFullBreadth();

  /// ATR% distribution across the tracked universe, for Insights.
  Future<DataResult<VolatilityHistogram>> getVolatility();

  /// Bullish/bearish MACD tilt across the tracked universe, for Insights.
  Future<DataResult<MomentumTilt>> getMomentum();

  /// Top stocks by today's-volume ÷ 20-day-average, descending, for Insights.
  Future<DataResult<VolumeSurgeBoard>> getVolumeSurge({int limit = 15});
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
///  * **Movers have dedicated endpoints, backed by Fyers only.** `/api/market/
///    gainers`, `/losers` and `/most-active` each return the top 10 from
///    `_fyers_stream.movers()` — one live-tick read across the full
///    deduplicated Nifty 50 + Sensex 30 + Bank Nifty universe (~140 symbols),
///    all from a single source. This intentionally does NOT reuse
///    `_fetchConstituents()`: that endpoint is capped at 50 stocks per index
///    and, because each index's constituents call picks its own source
///    independently, three concurrent constituent fetches can silently blend
///    live Fyers rows for one index with NSE/hardcoded-fallback rows for
///    another — exactly the "which source is this actually from" problem a
///    movers list must not have.
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
  static const _gainers = '/api/market/gainers';
  static const _losers = '/api/market/losers';
  static const _mostActive = '/api/market/most-active';
  static String _constituents(IndexId i) =>
      '/api/market/${i.apiKey}/constituents';

  /// Cache-only reads — the backend never touches Fyers on these requests
  /// (see main.py's docstrings for `/api/breadth/full` and the three
  /// `/api/insights/*` routes). Safe to poll at the same cadence as anything
  /// else on these screens; there's no per-request cost on the other end.
  static const _breadthFull = '/api/breadth/full';
  static const _insightsVolatility = '/api/insights/volatility';
  static const _insightsMomentum = '/api/insights/momentum';
  static const _insightsVolumeSurge = '/api/insights/volume-surge';

  /// Constituent lists are the source for movers, breadth and equity lookups.
  /// Cached only very briefly — just long enough to de-duplicate the several
  /// calls one screen's own load can make to the same index in one pass
  /// (e.g. Insights checking all three indices, or Equity Detail searching
  /// each one for a symbol) — not to throttle refreshes across polling
  /// ticks. The backend now answers this from a live WebSocket feed with no
  /// extra cost per request, so there is no reason to hold onto a stale
  /// answer for longer than that.
  static const _cacheTtl = Duration(seconds: 3);
  final Map<IndexId, (DateTime, List<Quote>)> _constituentCache = {};

  /// Whether each index's last constituents response was the backend's saved
  /// closing reading (`market_closed: true`), so a closed market's values are
  /// not flagged "live" during the minutes right after the bell.
  final Map<IndexId, bool> _constituentsClosed = {};

  /// In-flight request per index, so concurrent callers within the same
  /// refresh tick share one HTTP round trip instead of each firing their
  /// own. Without this, one `_refreshLive()` tick on Insights alone starts
  /// gainers + losers + most-active + sentiment essentially simultaneously
  /// (`Future.wait`), and each independently finds the 3s cache empty or
  /// expired and fetches all three indices itself — up to a dozen duplicate
  /// requests for the same three URLs on a single tick, worse still once
  /// Home's own tick lands nearby. This doesn't change what any caller sees
  /// (every caller still gets the same fresh rows once the shared fetch
  /// resolves) — it only removes the duplicate network round trips.
  final Map<IndexId, Future<List<Quote>>> _constituentFetchesInFlight = {};

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
        stale: _isStale(
          asOf,
          DataSurface.indexBoard,
          closed: decoded['market_closed'] == true,
        ),
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
        stale: _isStale(
          _newest(rows),
          DataSurface.indexConstituents,
          closed: _constituentsClosed[index] ?? false,
        ),
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
            stale: _isStale(
              match.first.asOf,
              DataSurface.equityDetail,
              closed: _constituentsClosed[index] ?? false,
            ),
          );
        }
      }
      return const DataResult<Quote>.empty();
    }, onEmpty: () => const DataResult<Quote>.empty());
  }

  @override
  Future<DataResult<List<Quote>>> getTopGainers() => _movers(
    DataSurface.gainers,
    _gainers,
    (a, b) => b.percentChange.compareTo(a.percentChange),
    keep: (q) => q.percentChange > 0,
  );

  @override
  Future<DataResult<List<Quote>>> getTopLosers() => _movers(
    DataSurface.losers,
    _losers,
    (a, b) => a.percentChange.compareTo(b.percentChange),
    keep: (q) => q.percentChange < 0,
  );

  @override
  Future<DataResult<List<Quote>>> getMostActive() => _movers(
    DataSurface.mostActive,
    _mostActive,
    (a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0),
    keep: (q) => q.volume != null && q.volume! > 0,
  );

  /// Fetches one mover list straight from its dedicated backend endpoint —
  /// a single, homogeneous read from `_fyers_stream.movers()`, never a blend
  /// of per-index sources. `keep` re-applies the gainer/loser/volume
  /// condition locally (the backend's top-10-by-metric ranking doesn't
  /// itself guarantee every row is strictly positive/negative/traded, e.g.
  /// on a day where the whole market is red), and the result is re-sorted
  /// locally so a stale-but-still-served response can't show out-of-order
  /// rows.
  Future<DataResult<List<Quote>>> _movers(
    DataSurface surface,
    String path,
    Comparator<Quote> order, {
    required bool Function(Quote) keep,
  }) {
    return _run(surface, () async {
      final decoded = jsonDecode(await _get(path));
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

      final eligible = rows.where(keep).toList()..sort(order);
      if (eligible.isEmpty) return const DataResult<List<Quote>>.empty();
      return DataResult.ready(
        eligible.take(10).toList(),
        stale: _isStale(
          asOf,
          surface,
          closed: decoded['market_closed'] == true,
        ),
      );
    }, onEmpty: () => const DataResult<List<Quote>>.empty());
  }

  @override
  Future<DataResult<Sentiment>> getSentiment({required bool monthly}) {
    return _run(DataSurface.sentiment, () async {
      final decoded = jsonDecode(await _get(_sentiment));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = Sentiment.tryParse(decoded);
      // A null score is a legitimate reading now, not malformed data: the
      // backend's automatic breadth-derived sentiment (Phase 2) returns
      // `sentiment: null` on a cold start (no breadth snapshot yet) or when
      // coverage is too thin to trust, per `compute_sentiment`'s no-snapshot/
      // low-coverage handling. Treating that as `DataFailure.malformed()`
      // routed it into the error/retry branch instead of `_SentimentCard`'s
      // existing "No sentiment reading yet" empty state, which is what this
      // case is actually meant to show.
      if (parsed == null) return const DataResult<Sentiment>.empty();

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

  @override
  Future<DataResult<FullBreadth>> getFullBreadth() {
    return _run(DataSurface.fullBreadth, () async {
      final decoded = jsonDecode(await _get(_breadthFull));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = FullBreadth.tryParse(decoded);
      if (parsed == null) return const DataResult<FullBreadth>.empty();
      return DataResult.ready(
        parsed,
        stale:
            parsed.asOf != null &&
            _isStale(parsed.asOf!, DataSurface.fullBreadth),
      );
    }, onEmpty: () => const DataResult<FullBreadth>.empty());
  }

  @override
  Future<DataResult<VolatilityHistogram>> getVolatility() {
    return _run(DataSurface.volatility, () async {
      final decoded = jsonDecode(await _get(_insightsVolatility));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = VolatilityHistogram.tryParse(decoded);
      if (parsed == null || parsed.total == 0) {
        return const DataResult<VolatilityHistogram>.empty();
      }
      return DataResult.ready(
        parsed,
        stale:
            parsed.asOf != null &&
            _isStale(parsed.asOf!, DataSurface.volatility),
      );
    }, onEmpty: () => const DataResult<VolatilityHistogram>.empty());
  }

  @override
  Future<DataResult<MomentumTilt>> getMomentum() {
    return _run(DataSurface.momentum, () async {
      final decoded = jsonDecode(await _get(_insightsMomentum));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = MomentumTilt.tryParse(decoded);
      if (parsed == null || parsed.total == 0) {
        return const DataResult<MomentumTilt>.empty();
      }
      return DataResult.ready(
        parsed,
        stale:
            parsed.asOf != null && _isStale(parsed.asOf!, DataSurface.momentum),
      );
    }, onEmpty: () => const DataResult<MomentumTilt>.empty());
  }

  @override
  Future<DataResult<VolumeSurgeBoard>> getVolumeSurge({int limit = 15}) {
    return _run(DataSurface.volumeSurge, () async {
      final decoded = jsonDecode(
        await _get('$_insightsVolumeSurge?limit=$limit'),
      );
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = VolumeSurgeBoard.tryParse(decoded);
      if (parsed == null || parsed.rows.isEmpty) {
        return const DataResult<VolumeSurgeBoard>.empty();
      }
      return DataResult.ready(
        parsed,
        stale:
            parsed.asOf != null &&
            _isStale(parsed.asOf!, DataSurface.volumeSurge),
      );
    }, onEmpty: () => const DataResult<VolumeSurgeBoard>.empty());
  }

  // ── Plumbing ─────────────────────────────────────────────────────────────

  Future<List<Quote>> _fetchConstituents(IndexId index) {
    final cached = _constituentCache[index];
    if (cached != null && DateTime.now().difference(cached.$1) < _cacheTtl) {
      return Future.value(cached.$2);
    }

    // Join an already-running fetch for this index rather than starting a
    // second one — see the field doc on `_constituentFetchesInFlight`.
    final inFlight = _constituentFetchesInFlight[index];
    if (inFlight != null) return inFlight;

    final future = _fetchConstituentsNow(index).whenComplete(() {
      _constituentFetchesInFlight.remove(index);
    });
    _constituentFetchesInFlight[index] = future;
    return future;
  }

  Future<List<Quote>> _fetchConstituentsNow(IndexId index) async {
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
    _constituentsClosed[index] = decoded['market_closed'] == true;
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

  /// Retry policy for [_get]: up to [_maxAttempts] tries with these delays.
  static const int _maxAttempts = 3;
  static const List<Duration> _retryDelays = [
    Duration(milliseconds: 700),
    Duration(milliseconds: 1500),
  ];

  static bool _isTransientStatus(int code) =>
      code == 502 || code == 503 || code == 504;

  /// Every HTTP concern lives here: the session cookie, the timeout, retries,
  /// and the mapping from transport outcomes onto [DataFailure].
  ///
  /// Transient failures (socket/DNS errors while the network comes back after
  /// the app was backgrounded, gateway 502/503/504, one timeout) are retried
  /// with a short backoff. The app is only reported offline once every attempt
  /// has failed.
  Future<String> _get(String path) async {
    DataFailure? lastFailure;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(_retryDelays[attempt - 1]);
      try {
        final response = await http
            .get(Uri.parse('$baseUrl$path'), headers: ApiService.authHeaders())
            .timeout(timeout);
        if (response.statusCode == 401 || response.statusCode == 403) {
          ApiService.notifySessionExpired();
          throw const DataFailure.session();
        }
        if (_isTransientStatus(response.statusCode)) {
          lastFailure = DataFailure.api(statusCode: response.statusCode);
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw DataFailure.api(statusCode: response.statusCode);
        }
        ApiService.notifyReachable(true);
        return response.body;
      } on DataFailure {
        rethrow;
      } on TimeoutException {
        lastFailure = const DataFailure.timeout();
        // A timeout already cost `timeout` seconds; allow only one retry.
        if (attempt >= 1) break;
      } catch (_) {
        // DNS failure, socket error, malformed URL — "we couldn't reach it".
        lastFailure = const DataFailure.offline();
      }
    }
    final failure = lastFailure ?? const DataFailure.offline();
    if (failure.reason == DataFailureReason.offline) {
      ApiService.notifyReachable(false);
    }
    throw failure;
  }

  /// [closed] is the backend's `market_closed` flag: the reading is the saved
  /// closing value, which is by definition no longer live, so it is flagged as
  /// such straight away rather than only once it is older than [cadence].
  /// The values themselves are still shown — see the closing snapshot in the
  /// backend's main.py.
  bool _isStale(DateTime asOf, DataSurface surface, {bool closed = false}) {
    if (FaultInjector.instance.forcesStale(surface)) return true;
    if (closed) return true;
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
