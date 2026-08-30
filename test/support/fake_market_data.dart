import 'package:ayre_scanner/services/fault_injection.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/services/market_models.dart';

/// A deterministic [MarketDataService] for tests.
///
/// Screens take their data source by injection, which is what lets the layout
/// matrix render every screen *populated* — the state where overflow bugs
/// actually live — instead of only in its empty/failure states.
///
/// Every surface can be independently forced into any phase, mirroring the
/// production requirement that one failed section never takes another down.
class FakeMarketData implements MarketDataService {
  FakeMarketData({
    this.phase = DataPhaseSnapshot.ready,
    this.stale = false,
    this.overrides = const {},
    this.longNames = false,
    this.hugeNumbers = false,
  });

  /// Default phase for every surface.
  final DataPhaseSnapshot phase;
  final bool stale;

  /// Per-surface overrides, so one list can fail while the rest succeed.
  final Map<DataSurface, DataPhaseSnapshot> overrides;

  /// Realistically long listed-company names, for truncation checks.
  final bool longNames;

  /// Index levels and volumes at the top of their plausible range, for width
  /// checks at large text scales.
  final bool hugeNumbers;

  static final DateTime _at = DateTime(2026, 8, 30, 15, 31, 42);

  DataPhaseSnapshot _phase(DataSurface surface) => overrides[surface] ?? phase;

  DataResult<T> _wrap<T>(DataSurface surface, T Function() build) {
    return switch (_phase(surface)) {
      DataPhaseSnapshot.ready => DataResult.ready(build(), stale: stale),
      DataPhaseSnapshot.empty => DataResult<T>.empty(),
      DataPhaseSnapshot.failed =>
        const DataResult.failed(DataFailure.api(statusCode: 503)),
    };
  }

  Quote _quote(String symbol, String name, num price, num pct, {num? volume}) {
    final level = hugeNumbers ? price * 1000 : price;
    return Quote(
      symbol: symbol,
      name: longNames ? '$name Industries and Holdings Limited' : name,
      lastPrice: level,
      change: level * pct / 100,
      percentChange: pct,
      asOf: _at,
      previousClose: level - (level * pct / 100),
      dayLow: level * 0.985,
      dayHigh: level * 1.012,
      volume: volume ?? (hugeNumbers ? 98765432100 : 14825000),
      trace: [
        for (var i = 0; i < 24; i++)
          level * (1 + (pct / 100) * (i / 23) + (i % 5 - 2) * 0.0009),
      ],
    );
  }

  @override
  Future<DataResult<List<Quote>>> getIndexBoard() async {
    return _wrap(DataSurface.indexBoard, () => [
      _quote('NIFTY50', 'NIFTY 50', 24518.4, 0.62),
      _quote('SENSEX', 'SENSEX', 80412.15, 0.48),
      _quote('BANKNIFTY', 'BANK NIFTY', 52140.9, -0.31),
    ]);
  }

  @override
  Future<DataResult<Quote>> getIndex(IndexId index) async {
    return _wrap(
      DataSurface.indexDetail,
      () => _quote(index.id, index.label, 24518.4, 0.62),
    );
  }

  @override
  Future<DataResult<List<Quote>>> getConstituents(IndexId index) async {
    return _wrap(DataSurface.indexConstituents, () => [
      _quote('RELIANCE', 'Reliance', 2984.55, 1.84),
      _quote('HDFCBANK', 'HDFC Bank', 1712.3, -0.42),
      _quote('BAJFINANCE', 'Bajaj Finance', 7218.9, 3.12),
      _quote('HDFCLIFE', 'HDFC Life Insurance Company', 642.15, -2.08),
      _quote('ADANIENT', 'Adani Enterprises', 3140.75, 11.4),
    ]);
  }

  @override
  Future<DataResult<Quote>> getEquity(String symbol) async {
    return _wrap(
      DataSurface.equityDetail,
      () => _quote(symbol, 'Reliance', 2984.55, 1.84),
    );
  }

  @override
  Future<DataResult<Sentiment>> getSentiment({required bool monthly}) async {
    return _wrap(
      DataSurface.sentiment,
      () => Sentiment(
        score: monthly ? 54 : 71,
        asOf: _at,
        note: 'Breadth is constructive with leadership narrowing into '
            'large-cap financials.',
        advances: 1284,
        declines: 742,
        unchanged: 96,
      ),
    );
  }

  @override
  Future<DataResult<List<Quote>>> getTopGainers() async {
    return _wrap(DataSurface.gainers, () => [
      _quote('ADANIENT', 'Adani Enterprises', 3140.75, 11.4),
      _quote('BAJFINANCE', 'Bajaj Finance', 7218.9, 3.12),
      _quote('RELIANCE', 'Reliance', 2984.55, 1.84),
    ]);
  }

  @override
  Future<DataResult<List<Quote>>> getTopLosers() async {
    return _wrap(DataSurface.losers, () => [
      _quote('HDFCLIFE', 'HDFC Life Insurance Company', 642.15, -2.08),
      _quote('HDFCBANK', 'HDFC Bank', 1712.3, -0.42),
    ]);
  }

  @override
  Future<DataResult<List<Quote>>> getMostActive() async {
    return _wrap(DataSurface.mostActive, () => [
      _quote('RELIANCE', 'Reliance', 2984.55, 1.84, volume: 128450000),
      _quote('HDFCBANK', 'HDFC Bank', 1712.3, -0.42, volume: 96210000),
    ]);
  }

  @override
  Future<DataResult<List<Signal>>> getSignals() async {
    return _wrap(DataSurface.signals, () => [
      Signal(
        symbol: 'RELIANCE',
        name: longNames ? 'Reliance Industries and Holdings Limited' : 'Reliance',
        rationale: 'Reclaimed the 20-day mean on expanding volume with the '
            'sector breadth confirming.',
        lastPrice: 2984.55,
        percentChange: 1.84,
        entry: 2960,
        target: 3120,
        stop: 2895,
        strength: 3,
        addedOn: '28 Aug',
      ),
      const Signal(
        symbol: 'HDFCLIFE',
        rationale: 'Lower high against a falling 50-day mean.',
        lastPrice: 642.15,
        percentChange: -2.08,
        strength: 2,
        bullish: false,
      ),
    ]);
  }

  @override
  Future<DataResult<List<Course>>> getCourses() async {
    return _wrap(DataSurface.courses, () => [
      const Course(
        title: 'Position sizing and portfolio heat management',
        category: 'Risk management',
        body: 'How much to commit per setup, and why the answer changes with '
            'volatility rather than with conviction.',
        lessonsTotal: 12,
        lessonsDone: 3,
      ),
      const Course(
        title: 'Reading market breadth',
        category: 'Market structure',
        body: 'Advances, declines, and what they tell you that an index level '
            'cannot.',
      ),
    ]);
  }

  @override
  Future<DataResult<List<InsightNote>>> getInsightNotes() async {
    return _wrap(DataSurface.insightNotes, () => [
      const InsightNote(
        title: 'Financials carrying the tape',
        body: 'Breadth is narrowing into large-cap lenders while mid-cap '
            'industrials lag.',
        category: 'Breadth',
        featured: true,
      ),
    ]);
  }
}
