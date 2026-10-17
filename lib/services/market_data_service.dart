import 'dart:async';
import 'dart:convert';


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

/// Everything the app needs from the Ayre backend: the analyst's published
/// work. Screens depend on this interface only, so the concrete source (the
/// Ayre backend or a QA double) is swappable without touching a widget.
abstract interface class MarketDataService {
  Future<DataResult<List<Signal>>> getSignals();
  Future<DataResult<List<Course>>> getCourses();
  Future<DataResult<List<InsightNote>>> getInsightNotes();

  /// Admin-entered weekly performance reports (`GET /api/weekly-report`),
  /// newest week first, shown on the Reports tab.
  Future<DataResult<List<WeeklyReport>>> getWeeklyReports();

  /// The SEBI Research Analyst registration number and its disclaimer, for
  /// the Research Analyst information screen (`GET /api/compliance`).
  Future<DataResult<ComplianceInfo>> getComplianceInfo();
}

/// Reads every surface from the Ayre backend. All of it is analyst-published
/// content: recommendations, Learn lessons, desk notes, weekly reports and the
/// registration details.
class RemoteMarketDataService implements MarketDataService {
  RemoteMarketDataService({
    this.baseUrl = ApiService.baseUrl,
    this.timeout = const Duration(seconds: 12),
  });

  final String baseUrl;
  final Duration timeout;

  // ── Endpoint contract, as the backend actually exposes it ────────────────
  static const _signals = '/api/signals';
  static const _courses = '/api/learn';
  static const _insightNotes = '/api/insights';

  /// Admin-entered, read-only from this app's point of view — the website
  /// writes it via POST/DELETE (Phase 4); the app only ever GETs it.
  static const _weeklyReport = '/api/weekly-report';

  /// Cache-only, same shape as `_breadthFull` above —
  /// two already-in-memory config strings, nothing computed per request.
  static const _compliance = '/api/compliance';

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

  /// Retry policy for [_get]: up to [_maxAttempts] tries with these delays.
  static const int _maxAttempts = 3;
  static const List<Duration> _retryDelays = [
    Duration(milliseconds: 700),
    Duration(milliseconds: 1500),
  ];

  static bool _isTransientStatus(int code) =>
      code == 502 || code == 503 || code == 504;

  /// Every HTTP concern lives here: the bearer token, the timeout, retries,
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
        final response = await ApiService.authedGet(
          Uri.parse('$baseUrl$path'),
          timeout: timeout,
        );
        // ApiService has already refreshed the token once and, if the server
        // still refuses it, returned the user to Sign in.
        if (response.statusCode == 401) {
          throw const DataFailure.session();
        }
        // 403 means "not allowed here", never "signed out".
        if (response.statusCode == 403) {
          throw const DataFailure.api(statusCode: 403);
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

  @override
  Future<DataResult<List<WeeklyReport>>> getWeeklyReports() {
    return _parsedList(
      surface: DataSurface.weeklyReport,
      path: _weeklyReport,
      rootKeys: const ['reports', 'data'],
      parse: WeeklyReport.tryParse,
    );
  }

  @override
  Future<DataResult<ComplianceInfo>> getComplianceInfo() {
    return _run(DataSurface.compliance, () async {
      final decoded = jsonDecode(await _get(_compliance));
      if (decoded is! Map<String, dynamic>) throw const DataFailure.malformed();
      final parsed = ComplianceInfo.tryParse(decoded);
      if (parsed == null) return const DataResult<ComplianceInfo>.empty();
      return DataResult.ready(parsed);
    }, onEmpty: () => const DataResult<ComplianceInfo>.empty());
  }
}
