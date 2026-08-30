import 'dart:async';

import 'package:flutter/foundation.dart';

/// The seven conditions every data-driven surface must be able to render.
///
/// These exist so QA can walk every screen through every state deterministically
/// instead of waiting for a real backend to misbehave. From the user's point of
/// view several of these are indistinguishable on purpose (a timeout reads the
/// same as a network failure) — the distinction matters here, not in the copy.
enum FaultKind {
  /// Non-2xx response.
  apiError,

  /// Valid response, zero items.
  emptyResponse,

  /// Valid HTTP response, unexpected or missing fields.
  malformed,

  /// No connectivity.
  networkFailure,

  /// Artificially delayed / never-resolving response.
  timeout,

  /// A timestamp older than the freshness threshold.
  staleData,

  /// Expired or invalid session on an authenticated call.
  sessionExpired,
}

/// Named data surfaces a fault can be pinned to. One per independently-failing
/// section, because the whole point is that a failed movers list doesn't take the
/// sentiment reading down with it.
enum DataSurface {
  indexBoard,
  indexDetail,
  indexConstituents,
  equityDetail,
  signals,
  sentiment,
  gainers,
  losers,
  mostActive,
  courses,
  insightNotes,
  account,
}

/// Debug-only fault injection.
///
/// Compiled behaviour is gated on [kDebugMode] as well as an explicit opt-in, so
/// nothing can be forced in a release build even if a flag is left set. No test
/// UI ships to end users — this is a development and QA capability only.
class FaultInjector extends ChangeNotifier {
  FaultInjector._();

  static final FaultInjector instance = FaultInjector._();

  final Map<DataSurface, FaultKind> _faults = {};
  bool _enabled = false;

  /// Master switch. Ignored entirely outside debug builds.
  bool get enabled => _enabled && kDebugMode;

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  Map<DataSurface, FaultKind> get active =>
      enabled ? Map.unmodifiable(_faults) : const {};

  FaultKind? faultFor(DataSurface surface) =>
      enabled ? _faults[surface] : null;

  void set(DataSurface surface, FaultKind? kind) {
    if (kind == null) {
      _faults.remove(surface);
    } else {
      _faults[surface] = kind;
    }
    notifyListeners();
  }

  /// Applies one fault to every surface at once — the fastest way to sweep the
  /// whole app through a single condition.
  void setAll(FaultKind? kind) {
    _faults.clear();
    if (kind != null) {
      for (final surface in DataSurface.values) {
        _faults[surface] = kind;
      }
    }
    notifyListeners();
  }

  void clear() {
    _faults.clear();
    notifyListeners();
  }

  /// Wraps a real fetch. When a fault is pinned to [surface] the fetch is
  /// replaced by that condition; otherwise the real call runs untouched.
  ///
  /// [onEmpty] and [onMalformed] let a caller describe what those conditions look
  /// like for its own shape, since "empty" means different things to a list and
  /// to a single quote.
  Future<T> guard<T>(
    DataSurface surface,
    Future<T> Function() fetch, {
    T Function()? onEmpty,
    T Function()? onMalformed,
  }) async {
    final fault = faultFor(surface);
    if (fault == null) return fetch();

    switch (fault) {
      case FaultKind.apiError:
        throw const DataFailure.api(statusCode: 503);
      case FaultKind.networkFailure:
        throw const DataFailure.offline();
      case FaultKind.timeout:
        // Long enough that the caller's own timeout is the thing that fires,
        // which is exactly the path we want to exercise.
        await Future<void>.delayed(const Duration(seconds: 30));
        throw const DataFailure.timeout();
      case FaultKind.sessionExpired:
        throw const DataFailure.session();
      case FaultKind.emptyResponse:
        if (onEmpty != null) return onEmpty();
        throw const DataFailure.malformed();
      case FaultKind.malformed:
        if (onMalformed != null) return onMalformed();
        throw const DataFailure.malformed();
      case FaultKind.staleData:
        // Handled by the caller, which re-stamps the result as old.
        return fetch();
    }
  }

  /// True when [surface] should present its data as behind the feed.
  bool forcesStale(DataSurface surface) =>
      faultFor(surface) == FaultKind.staleData;
}

/// Why a fetch didn't produce usable data.
///
/// Every variant except [DataFailure.session] presents identically to the user —
/// a retry affordance and plain-language copy, never a status code.
class DataFailure implements Exception {
  const DataFailure.api({this.statusCode})
    : reason = DataFailureReason.api,
      message = null;
  const DataFailure.offline()
    : reason = DataFailureReason.offline,
      statusCode = null,
      message = null;
  const DataFailure.timeout()
    : reason = DataFailureReason.timeout,
      statusCode = null,
      message = null;
  const DataFailure.malformed()
    : reason = DataFailureReason.malformed,
      statusCode = null,
      message = null;
  const DataFailure.session()
    : reason = DataFailureReason.session,
      statusCode = null,
      message = null;

  final DataFailureReason reason;
  final int? statusCode;
  final String? message;

  /// A session failure is the one case that changes what the app does rather
  /// than only what it shows.
  bool get requiresReauth => reason == DataFailureReason.session;

  @override
  String toString() =>
      'DataFailure(${reason.name}${statusCode != null ? ' $statusCode' : ''})';
}

enum DataFailureReason { api, offline, timeout, malformed, session }
