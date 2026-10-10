import 'dart:async';

import 'market_data_cache.dart';
import 'market_data_service.dart';
import 'market_models.dart';

/// Wraps any [MarketDataService] with on-device persistence, so every
/// surface — index board, index detail, constituents, equities, sentiment,
/// movers, signals, courses, insight notes, full breadth,
/// weekly reports, compliance info — falls back to
/// the most recently seen good reading instead of an empty or failed state.
/// That applies whether the market is simply closed, the backend is
/// temporarily unreachable, the device is offline, or the app was
/// force-quit and relaunched — anything that would otherwise leave a screen
/// with nothing to show before the network has had a chance to answer.
///
/// How it works: every call runs against [inner] first, unchanged.
///
///  * A **ready** result is cached to disk under a key for that surface
///    (fire-and-forget — this never delays returning the fresh data to the
///    caller) and returned as-is. New data always replaces what was saved
///    before, so the cache never lags behind the last good reading the app
///    actually saw.
///  * An **empty or failed** result is instead served from that surface's
///    saved cache, if any, re-stamped `stale: true` so it renders through
///    the UI's existing "delayed" treatment — the same visual language
///    already used for an aging live reading, not a new one.
///  * If nothing was ever cached for that surface (a genuinely first-ever
///    launch with no connectivity), the original empty/failed result passes
///    through unchanged — there is nothing to fall back to yet.
///  * A **session failure** (`DataFailure.requiresReauth`) always passes
///    through untouched, exactly like the existing in-memory
///    `DataResult.keepingLastGood` already carves out: that failure changes
///    what the app does (routes to sign-in), not just what a screen shows,
///    so it must never be masked by cached data.
///
/// This sits entirely behind the [MarketDataService] interface. No screen or
/// widget changes, and the existing in-memory `keepingLastGood` pattern each
/// screen already applies on top of its result keeps working exactly as
/// before — it now simply has less to ever paper over, because a cold start
/// or a dead backend rarely reaches it as `empty`/`failed` at all.
class PersistentMarketDataService implements MarketDataService {
  PersistentMarketDataService(this.inner) {
    unawaited(purgeRetiredCache());
  }

  /// R-1: Volatility, Momentum and Volume Surge were removed from the app.
  /// Existing installs still hold their last good readings under
  /// `market_cache::volatility`, `::momentum` and `::volume_surge_<limit>`;
  /// this removes them (idempotent, best-effort, runs once per start).
  static Future<void> purgeRetiredCache() async {
    await MarketDataCache.clear('volatility');
    await MarketDataCache.clear('momentum');
    await MarketDataCache.clearPrefix('volume_surge_');
  }

  final MarketDataService inner;

  // ── cache keys — one per independently-persisted surface ────────────────
  static const _kIndexBoard = 'index_board';
  static String _kIndex(IndexId i) => 'index_${i.id}';
  static String _kConstituents(IndexId i) => 'constituents_${i.id}';
  static String _kEquity(String symbol) => 'equity_${symbol.toUpperCase()}';
  static String _kSentiment(bool monthly) => 'sentiment_$monthly';
  static const _kGainers = 'gainers';
  static const _kLosers = 'losers';
  static const _kMostActive = 'most_active';
  static const _kSignals = 'signals';
  static const _kCourses = 'courses';
  static const _kInsightNotes = 'insight_notes';
  static const _kFullBreadth = 'full_breadth';
  static const _kWeeklyReports = 'weekly_reports';
  static const _kCompliance = 'compliance';

  // ── generic plumbing ─────────────────────────────────────────────────────

  /// Runs [fetch]. A ready result is saved under [key] and returned as-is.
  /// An empty/failed result (other than a session failure) is instead served
  /// from [key]'s saved value, marked stale, when one exists.
  Future<DataResult<T>> _persisted<T>(
    String key,
    Future<DataResult<T>> Function() fetch,
    Object? Function(T value) encode,
    T? Function(dynamic json) decode,
  ) async {
    final result = await fetch();

    if (result.isReady) {
      unawaited(MarketDataCache.save(key, encode(result.value as T)));
      return result;
    }

    // Changes what the app does (sign-in redirect), not just what this
    // screen shows — must never be masked by a cached reading.
    if (result.isFailed && result.failure!.requiresReauth) return result;

    final cached = await MarketDataCache.load<T>(key, decode);
    if (cached != null) return DataResult<T>.ready(cached, stale: true);
    return result;
  }

  /// Same as [_persisted], for the list-returning surfaces — nearly all of
  /// them. Kept as a thin wrapper around [_persisted] rather than a
  /// parallel implementation, so both share one fallback/session-failure
  /// rule.
  Future<DataResult<List<T>>> _persistedList<T>(
    String key,
    Future<DataResult<List<T>>> Function() fetch,
    Object? Function(T value) encodeItem,
    T? Function(dynamic json) decodeItem,
  ) {
    return _persisted<List<T>>(
      key,
      fetch,
      (list) => list.map(encodeItem).toList(),
      (data) {
        if (data is! List) return null;
        final out = <T>[];
        for (final entry in data) {
          final item = decodeItem(entry);
          if (item != null) out.add(item);
        }
        return out.isEmpty ? null : out;
      },
    );
  }

  static Quote? _decodeQuote(dynamic json) =>
      json is Map ? Quote.tryParse(json.cast<String, dynamic>()) : null;

  // ── MarketDataService ────────────────────────────────────────────────────

  @override
  Future<DataResult<List<Quote>>> getIndexBoard() => _persistedList(
    _kIndexBoard,
    inner.getIndexBoard,
    (q) => q.toJson(),
    _decodeQuote,
  );

  @override
  Future<DataResult<Quote>> getIndex(IndexId index) => _persisted(
    _kIndex(index),
    () => inner.getIndex(index),
    (q) => q.toJson(),
    _decodeQuote,
  );

  @override
  Future<DataResult<List<Quote>>> getConstituents(IndexId index) =>
      _persistedList(
        _kConstituents(index),
        () => inner.getConstituents(index),
        (q) => q.toJson(),
        _decodeQuote,
      );

  @override
  Future<DataResult<Quote>> getEquity(String symbol) => _persisted(
    _kEquity(symbol),
    () => inner.getEquity(symbol),
    (q) => q.toJson(),
    _decodeQuote,
  );

  @override
  Future<DataResult<Sentiment>> getSentiment({required bool monthly}) =>
      _persisted(
        _kSentiment(monthly),
        () => inner.getSentiment(monthly: monthly),
        (s) => s.toJson(),
        (j) => j is Map ? Sentiment.tryParse(j.cast<String, dynamic>()) : null,
      );

  @override
  Future<DataResult<List<Quote>>> getTopGainers() => _persistedList(
    _kGainers,
    inner.getTopGainers,
    (q) => q.toJson(),
    _decodeQuote,
  );

  @override
  Future<DataResult<List<Quote>>> getTopLosers() => _persistedList(
    _kLosers,
    inner.getTopLosers,
    (q) => q.toJson(),
    _decodeQuote,
  );

  @override
  Future<DataResult<List<Quote>>> getMostActive() => _persistedList(
    _kMostActive,
    inner.getMostActive,
    (q) => q.toJson(),
    _decodeQuote,
  );

  @override
  Future<DataResult<List<Signal>>> getSignals() => _persistedList(
    _kSignals,
    inner.getSignals,
    (s) => s.toJson(),
    (j) => j is Map ? Signal.tryParse(j.cast<String, dynamic>()) : null,
  );

  @override
  Future<DataResult<List<Course>>> getCourses() => _persistedList(
    _kCourses,
    inner.getCourses,
    (c) => c.toJson(),
    (j) => j is Map ? Course.tryParse(j.cast<String, dynamic>()) : null,
  );

  @override
  Future<DataResult<List<InsightNote>>> getInsightNotes() => _persistedList(
    _kInsightNotes,
    inner.getInsightNotes,
    (n) => n.toJson(),
    (j) => j is Map ? InsightNote.tryParse(j.cast<String, dynamic>()) : null,
  );

  @override
  Future<DataResult<FullBreadth>> getFullBreadth() => _persisted(
    _kFullBreadth,
    inner.getFullBreadth,
    (b) => b.toJson(),
    (j) => j is Map ? FullBreadth.tryParse(j.cast<String, dynamic>()) : null,
  );

  @override
  Future<DataResult<List<WeeklyReport>>> getWeeklyReports() => _persistedList(
    _kWeeklyReports,
    inner.getWeeklyReports,
    (w) => w.toJson(),
    (j) => j is Map ? WeeklyReport.tryParse(j.cast<String, dynamic>()) : null,
  );

  @override
  Future<DataResult<ComplianceInfo>> getComplianceInfo() => _persisted(
    _kCompliance,
    inner.getComplianceInfo,
    (c) => c.toJson(),
    (j) =>
        j is Map ? ComplianceInfo.tryParse(j.cast<String, dynamic>()) : null,
  );
}
