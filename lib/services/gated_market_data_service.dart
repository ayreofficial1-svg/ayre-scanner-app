import 'market_data_service.dart';
import 'market_models.dart';
import 'recommendation_access.dart';
import 'recommendation_purge.dart';

/// Keeps recommendations off a device that is not allowed to have them.
///
/// Wraps another [MarketDataService]. Everything is passed straight through
/// except [getSignals], which answers with an empty result and never calls the
/// wrapped service while recommendations are not unlocked.
///
/// Sits **outside** `PersistentMarketDataService`, so while locked nothing is
/// requested, read from the saved copy, or written to it.
class GatedMarketDataService implements MarketDataService {
  GatedMarketDataService(this._inner);

  final MarketDataService _inner;

  bool get _allowed => RecommendationAccess.instance.isUnlocked;

  @override
  Future<DataResult<List<Signal>>> getSignals() async {
    if (!_allowed) return const DataResult<List<Signal>>.empty();
    final result = await _inner.getSignals();
    if (!_allowed) {
      // Locked while the request was in flight: the wrapped service may have
      // just saved the answer, so remove it and hand back nothing.
      await RecommendationPurge.clearCache();
      return const DataResult<List<Signal>>.empty();
    }
    return result;
  }

  @override
  Future<DataResult<List<Course>>> getCourses() => _inner.getCourses();

  @override
  Future<DataResult<List<InsightNote>>> getInsightNotes() =>
      _inner.getInsightNotes();

  @override
  Future<DataResult<List<WeeklyReport>>> getWeeklyReports() =>
      _inner.getWeeklyReports();

  @override
  Future<DataResult<ComplianceInfo>> getComplianceInfo() =>
      _inner.getComplianceInfo();
}
