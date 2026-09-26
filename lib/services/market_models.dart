/// Wire models for every market surface in the app.
///
/// Each `tryParse` returns null when a field the UI genuinely cannot render
/// without is missing or unparseable, so a malformed row is dropped rather than
/// producing a half-drawn card. Optional fields degrade the UI locally instead
/// of failing the whole section.
library;

/// The three instruments Home treats as primary gateways.
enum IndexId {
  nifty50(id: 'NIFTY50', label: 'NIFTY 50', apiKey: 'nifty'),
  bankNifty(id: 'BANKNIFTY', label: 'BANK NIFTY', apiKey: 'bank_nifty'),
  sensex(id: 'SENSEX', label: 'SENSEX', apiKey: 'sensex');

  const IndexId({required this.id, required this.label, required this.apiKey});

  final String id;
  final String label;

  /// Key this index is expected under in a market payload.
  final String apiKey;

  static IndexId? fromId(String value) {
    for (final candidate in IndexId.values) {
      if (candidate.id.toUpperCase() == value.toUpperCase()) return candidate;
    }
    return null;
  }
}

/// A tradeable instrument's current reading — used for both indices and
/// equities, because the shape a readout needs is the same for either.
class Quote {
  const Quote({
    required this.symbol,
    required this.name,
    required this.lastPrice,
    required this.change,
    required this.percentChange,
    required this.asOf,
    this.previousClose,
    this.dayLow,
    this.dayHigh,
    this.volume,
    this.trace = const [],
  });

  final String symbol;
  final String name;
  final num lastPrice;

  /// Absolute change; may be negative. Drives the sign.
  final num change;
  final num percentChange;
  final DateTime asOf;

  final num? previousClose;
  final num? dayLow;
  final num? dayHigh;
  final num? volume;

  /// Intraday samples, oldest first. Empty means the trace is simply not drawn —
  /// the readout never invents a shape it wasn't given.
  final List<num> trace;

  bool get isUp => change >= 0;

  static Quote? tryParse(Map<String, dynamic> json, {String? fallbackSymbol}) {
    final symbol =
        _str(json, const ['symbol', 'ticker', 'scrip', 'id']) ?? fallbackSymbol;
    final last = _num(json, const [
      'lastPrice',
      'last_price',
      'ltp',
      'price',
      'value',
      'level',
    ]);
    if (symbol == null || symbol.isEmpty || last == null) return null;

    // `change_points` is what the backend calls the absolute change on a
    // constituent row; its `change` field is the *percentage*, so it must not be
    // read as an absolute here.
    final change = _num(json, const [
      'change_points',
      'changePoints',
      'points',
      'net_change',
      'netChange',
    ]);
    final percent = _num(json, const [
      'percentChange',
      'percent_change',
      'change_pct',
      'pChange',
    ]);
    // A readout with no direction is not a readout; require at least one of the
    // two change figures and derive the other where possible.
    if (change == null && percent == null) return null;
    final previous = _num(json, const [
      'previousClose',
      'previous_close',
      'prevClose',
    ]);
    final resolvedChange =
        change ??
        (previous != null ? last - previous : (last * percent! / 100));
    final resolvedPercent =
        percent ??
        (previous != null && previous != 0
            ? (resolvedChange / previous) * 100
            : 0);

    return Quote(
      symbol: symbol,
      name:
          _str(json, const ['name', 'companyName', 'company_name', 'label']) ??
          symbol,
      lastPrice: last,
      change: resolvedChange,
      percentChange: resolvedPercent,
      asOf:
          _time(json, const ['asOf', 'as_of', 'updated_at', 'timestamp']) ??
          DateTime.now(),
      previousClose: previous,
      dayLow: _num(json, const ['dayLow', 'day_low', 'low']),
      dayHigh: _num(json, const ['dayHigh', 'day_high', 'high']),
      volume: _num(json, const [
        'volume',
        'totalTradedVolume',
        'traded_value',
        'totalTradedValue',
      ]),
      trace: _numList(json, const ['trace', 'intraday', 'series', 'points']),
    );
  }
}

/// A market sentiment/breadth reading.
class Sentiment {
  const Sentiment({
    required this.score,
    required this.asOf,
    this.note,
    this.advances,
    this.declines,
    this.unchanged,
  });

  /// 0..100
  final int score;
  final DateTime asOf;
  final String? note;

  /// Breadth counts, shown as a readout row when the feed provides them.
  final int? advances;
  final int? declines;
  final int? unchanged;

  String get band {
    if (score < 35) return 'Caution';
    if (score < 65) return 'Neutral';
    return 'Strong';
  }

  static Sentiment? tryParse(Map<String, dynamic> json) {
    final score = _num(json, const ['sentiment', 'score', 'value', 'breadth']);
    if (score == null) return null;
    return Sentiment(
      score: score.round().clamp(0, 100),
      asOf:
          _time(json, const ['asOf', 'as_of', 'updated_at', 'timestamp']) ??
          DateTime.now(),
      note: _str(json, const ['note', 'summary', 'commentary']),
      advances: _num(json, const ['advances', 'advancing'])?.round(),
      declines: _num(json, const ['declines', 'declining'])?.round(),
      unchanged: _num(json, const ['unchanged', 'flat'])?.round(),
    );
  }
}

/// Full Nifty-500 market breadth (`GET /api/breadth/full`) — a separate,
/// complete breadth reading from [Sentiment]'s ~140-stock live-tick count.
/// Refreshes on its own fixed hourly schedule (backend spec §4), not
/// tick-by-tick, which is why it carries its own [asOf] rather than reusing
/// the live-refresh cadence the rest of Home polls on.
class FullBreadth {
  const FullBreadth({
    required this.advances,
    required this.declines,
    required this.unchanged,
    required this.avgChangePct,
    required this.coverage,
    this.asOf,
  });

  final int advances;
  final int declines;
  final int unchanged;
  final num avgChangePct;

  /// How many of the ~500 constituents this reading actually covers — shown
  /// so a partial batch (a few symbols the poller's Fyers call missed) isn't
  /// silently presented as full-universe breadth.
  final int coverage;
  final DateTime? asOf;

  static FullBreadth? tryParse(Map<String, dynamic> json) {
    final coverage = _num(json, const ['coverage'])?.round();
    if (coverage == null || coverage <= 0) return null;
    return FullBreadth(
      advances: _num(json, const ['advances'])?.round() ?? 0,
      declines: _num(json, const ['declines'])?.round() ?? 0,
      unchanged: _num(json, const ['unchanged'])?.round() ?? 0,
      avgChangePct: _num(json, const ['avg_change_pct']) ?? 0,
      coverage: coverage,
      asOf: _asOfStamp(json),
    );
  }
}

/// The SEBI Research Analyst registration number and its accompanying
/// disclaimer (`GET /api/compliance`) — Phase 6. Both values live in the
/// backend's `config/settings.py` and are shown as-is on the Research
/// Analyst information screen; there is nothing to compute here, only two
/// strings to carry.
class ComplianceInfo {
  const ComplianceInfo({
    required this.registrationNumber,
    required this.disclaimer,
  });

  final String registrationNumber;
  final String disclaimer;

  static ComplianceInfo? tryParse(Map<String, dynamic> json) {
    final registrationNumber = _str(json, const [
      'ra_registration_number',
      'registration_number',
    ]);
    final disclaimer = _str(json, const ['disclaimer']);
    if (registrationNumber == null || disclaimer == null) return null;
    return ComplianceInfo(
      registrationNumber: registrationNumber,
      disclaimer: disclaimer,
    );
  }
}

/// ATR% distribution across the tracked universe (`GET
/// /api/insights/volatility`) — how spread-out today's daily ranges are,
/// bucketed. Refreshes at scan cadence (up to 7×/day), like [MomentumTilt]
/// and [VolumeSurgeBoard] below — all three are byproducts of the same scan.
class VolatilityHistogram {
  const VolatilityHistogram({required this.buckets, this.asOf});

  /// Ordered bucket label → stock count, e.g. {"0-1%": 120, "1-2%": 90, ...}.
  /// Insertion order is preserved from the backend response, which already
  /// orders buckets low-to-high.
  final Map<String, int> buckets;
  final DateTime? asOf;

  int get total => buckets.values.fold(0, (a, b) => a + b);

  static VolatilityHistogram? tryParse(Map<String, dynamic> json) {
    final raw = json['buckets'];
    if (raw is! Map) return null;
    final buckets = <String, int>{};
    raw.forEach((key, value) {
      final n = _num({'v': value}, const ['v']);
      if (n != null) buckets[key.toString()] = n.round();
    });
    if (buckets.isEmpty) return null;
    return VolatilityHistogram(buckets: buckets, asOf: _asOfStamp(json));
  }
}

/// Bullish/bearish MACD tilt across the tracked universe (`GET
/// /api/insights/momentum`).
class MomentumTilt {
  const MomentumTilt({
    required this.bullish,
    required this.bearish,
    this.asOf,
  });

  final int bullish;
  final int bearish;
  final DateTime? asOf;

  int get total => bullish + bearish;

  static MomentumTilt? tryParse(Map<String, dynamic> json) {
    final bullish = _num(json, const ['bullish'])?.round();
    final bearish = _num(json, const ['bearish'])?.round();
    if (bullish == null && bearish == null) return null;
    return MomentumTilt(
      bullish: bullish ?? 0,
      bearish: bearish ?? 0,
      asOf: _asOfStamp(json),
    );
  }
}

/// One row of the volume-surge leaderboard (`GET
/// /api/insights/volume-surge`) — today's volume as a multiple of the
/// 20-day average.
class VolumeSurgeRow {
  const VolumeSurgeRow({
    required this.symbol,
    required this.surge,
    this.close,
  });

  final String symbol;

  /// Multiple of the 20-day average volume — 2.4 means 2.4× normal volume.
  final num surge;
  final num? close;

  static VolumeSurgeRow? tryParse(Map<String, dynamic> json) {
    final symbol = _str(json, const ['symbol']);
    final surge = _num(json, const ['volume_surge', 'surge']);
    if (symbol == null || surge == null) return null;
    return VolumeSurgeRow(
      symbol: symbol,
      surge: surge,
      close: _num(json, const ['close']),
    );
  }
}

/// The volume-surge leaderboard as a whole: the ranked rows plus the batch's
/// own `as_of` reading. Kept as one wrapper rather than folding `asOf` into
/// each row — the list has a single timestamp, not a per-row one.
class VolumeSurgeBoard {
  const VolumeSurgeBoard({required this.rows, this.asOf});

  final List<VolumeSurgeRow> rows;
  final DateTime? asOf;

  static VolumeSurgeBoard? tryParse(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) return null;
    final rows = <VolumeSurgeRow>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final row = VolumeSurgeRow.tryParse(entry.cast<String, dynamic>());
      if (row != null) rows.add(row);
    }
    return VolumeSurgeBoard(rows: rows, asOf: _asOfStamp(json));
  }
}

/// A scanner setup on the Signals board.
class Signal {
  const Signal({
    required this.symbol,
    required this.rationale,
    this.name,
    this.lastPrice,
    this.percentChange,
    this.entry,
    this.target,
    this.stop,
    this.strength,
    this.bullish = true,
    this.addedOn,
  });

  final String symbol;
  final String rationale;
  final String? name;
  final num? lastPrice;
  final num? percentChange;
  final num? entry;
  final num? target;
  final num? stop;

  /// 0..4 — rendered as filled/unfilled ticks, never a dial.
  final int? strength;
  final bool bullish;
  final String? addedOn;

  static Signal? tryParse(Map<String, dynamic> json) {
    final symbol = _str(json, const ['symbol', 'ticker', 'scrip']);
    if (symbol == null || symbol.isEmpty) return null;
    final percent = _num(json, const [
      'change_pct',
      'percentChange',
      'percent_change',
    ]);
    final bias = _str(json, const ['bias', 'direction', 'side'])?.toLowerCase();
    return Signal(
      symbol: symbol,
      rationale:
          _str(json, const ['rationale', 'reason', 'note', 'body']) ?? '',
      name: _str(json, const ['name', 'companyName', 'company_name']),
      lastPrice: _num(json, const ['last_price', 'lastPrice', 'ltp', 'price']),
      percentChange: percent,
      entry: _num(json, const ['entry', 'entry_price']),
      target: _num(json, const ['target', 'target_price']),
      stop: _num(json, const ['stop', 'stop_loss', 'stoploss']),
      strength: _num(json, const [
        'strength',
        'score',
        'conviction',
      ])?.round().clamp(0, 4),
      bullish: bias != null
          ? (bias == 'long' || bias == 'buy' || bias == 'bullish')
          : (percent ?? 0) >= 0,
      addedOn: _str(json, const ['date_added', 'added_on', 'created_at']),
    );
  }
}

/// A Learn course/lesson entry.
class Course {
  const Course({
    required this.title,
    required this.category,
    required this.body,
    this.lessonsTotal,
    this.lessonsDone,
  });

  final String title;
  final String category;
  final String body;
  final int? lessonsTotal;
  final int? lessonsDone;

  double? get progress {
    final total = lessonsTotal;
    final done = lessonsDone;
    if (total == null || done == null || total <= 0) return null;
    return (done / total).clamp(0.0, 1.0);
  }

  static Course? tryParse(Map<String, dynamic> json) {
    final title = _str(json, const ['title', 'name']);
    if (title == null || title.isEmpty) return null;
    return Course(
      title: title,
      category:
          _str(json, const ['category', 'eyebrow', 'subject']) ?? 'Lesson',
      body: _str(json, const ['body', 'description', 'summary']) ?? '',
      lessonsTotal: _num(json, const [
        'lessons',
        'lessons_total',
        'total',
      ])?.round(),
      lessonsDone: _num(json, const [
        'completed',
        'lessons_done',
        'done',
      ])?.round(),
    );
  }
}

/// A written insight on the Insights desk.
class InsightNote {
  const InsightNote({
    required this.title,
    required this.body,
    this.category,
    this.featured = false,
  });

  final String title;
  final String body;
  final String? category;
  final bool featured;

  static InsightNote? tryParse(Map<String, dynamic> json) {
    final title = _str(json, const ['title', 'headline']);
    if (title == null || title.isEmpty) return null;
    return InsightNote(
      title: title,
      body: _str(json, const ['body', 'summary', 'description']) ?? '',
      category: _str(json, const ['category', 'tag']),
      featured: json['featured'] == true || json['pinned'] == true,
    );
  }
}

/// One stock row inside a [WeeklyReport] — an admin-confirmed outcome for a
/// past week, never computed by the app or the backend (see
/// IMPLEMENTATION_SPEC_weekly_report_and_sentiment.md §A.4). [outcome] is
/// exactly `"target"` or `"stop_loss"` — the same two spellings the backend
/// validates on write, so a row that doesn't match either is dropped by
/// [tryParse] rather than shown with a guessed meaning.
class WeeklyReportStock {
  const WeeklyReportStock({
    required this.symbol,
    required this.profitPct,
    required this.outcome,
    this.name,
    this.bullish = true,
    this.tradeLabel,
    this.entryPrice,
    this.exitPrice,
    this.pnlAmount,
    this.dateOfRecommendation,
    this.exitDate,
    this.durationDays,
  });

  final String symbol;
  final num profitPct;

  /// `"target"` or `"stop_loss"` — see [targetHit].
  final String outcome;

  /// Optional company name shown under the symbol (Phase 6). Never required
  /// — older admin-entered rows simply have this null.
  final String? name;

  /// Optional bullish/bearish tag (Phase 6), rendered with the same
  /// [DirectionBadge] `Signal.bullish` already uses on the Signals tab.
  /// Defaults to `true` (bullish) when the admin hasn't set it, matching
  /// [Signal]'s own default direction.
  final bool bullish;

  /// Optional trade description, e.g. "BUY SEP 3850 CE" (Phase 6).
  final String? tradeLabel;

  /// Optional entry/exit prices (Phase 6), shown beside [tradeLabel].
  final num? entryPrice;
  final num? exitPrice;

  /// Optional profit/loss amount in rupees (Phase 6). When present, the card
  /// shows a Profit/Loss ₹ row plus a separate % Return row; when absent, the
  /// card falls back to Phase 3's single ₹-less % headline.
  final num? pnlAmount;

  /// Optional per-stock dates (Phase 6). When either is missing, the card
  /// falls back to the report's own `weekStart`/`weekEnd`.
  final DateTime? dateOfRecommendation;
  final DateTime? exitDate;

  /// Optional explicit duration in days (Phase 6). When absent, the card
  /// computes it from [dateOfRecommendation]/[exitDate] (or their week-level
  /// fallbacks) instead.
  final int? durationDays;

  bool get targetHit => outcome == 'target';

  static WeeklyReportStock? tryParse(Map<String, dynamic> json) {
    final symbol = _str(json, const ['symbol']);
    if (symbol == null) return null;
    // `_str(...)?.toLowerCase()` is `String?` — even after the guard below
    // only lets 'target'/'stop_loss' through, Dart doesn't type-promote a
    // nullable local from a value-equality check (only from a `== null`
    // check), so passing it straight to `outcome` (a non-nullable `String`
    // field) doesn't typecheck. Resolving to a definite literal here avoids
    // that without a null-assertion (`!`), which the rest of this file's
    // `tryParse` methods never use.
    final rawOutcome = _str(json, const ['outcome'])?.toLowerCase();
    if (rawOutcome != 'target' && rawOutcome != 'stop_loss') return null;
    final String outcome = rawOutcome == 'target' ? 'target' : 'stop_loss';
    final rawBullish = json['bullish'];
    return WeeklyReportStock(
      symbol: symbol,
      profitPct: _num(json, const ['profit_pct', 'profitPct']) ?? 0,
      outcome: outcome,
      name: _str(json, const ['name', 'company_name', 'companyName']),
      bullish: rawBullish is bool ? rawBullish : true,
      tradeLabel: _str(json, const ['trade_label', 'tradeLabel']),
      entryPrice: _num(json, const ['entry_price', 'entryPrice']),
      exitPrice: _num(json, const ['exit_price', 'exitPrice']),
      pnlAmount: _num(json, const ['pnl_amount', 'pnlAmount']),
      dateOfRecommendation: _time(json, const [
        'date_of_recommendation',
        'dateOfRecommendation',
      ]),
      exitDate: _time(json, const ['exit_date', 'exitDate']),
      durationDays: _num(json, const [
        'duration_days',
        'durationDays',
      ])?.round(),
    );
  }
}

/// One week's admin-entered performance record (`GET /api/weekly-report`),
/// shown on the Signals tab directly below the Signal board. Purely
/// historical and hand-entered by the admin on the website — there is no
/// automatic target/stop-loss detection anywhere in this app or the backend
/// (§A.4). [weekStart]/[weekEnd] arrive as plain ISO dates; the "6th
/// September to 12th September" display format is computed client-side (see
/// `signals_tab.dart`'s date-range formatter), not sent pre-formatted by the
/// backend, so it can be redisplayed differently later without a data
/// migration.
class WeeklyReport {
  const WeeklyReport({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.stocks,
  });

  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;

  /// Never empty — [tryParse] drops a report with no valid rows, since an
  /// empty report has nothing to show.
  final List<WeeklyReportStock> stocks;

  static WeeklyReport? tryParse(Map<String, dynamic> json) {
    final id = _str(json, const ['id']);
    final weekStart = _time(json, const ['week_start', 'weekStart']);
    final weekEnd = _time(json, const ['week_end', 'weekEnd']);
    if (id == null || weekStart == null || weekEnd == null) return null;

    final rawStocks = json['stocks'];
    final stocks = <WeeklyReportStock>[];
    if (rawStocks is List) {
      for (final entry in rawStocks) {
        if (entry is Map) {
          final parsed = WeeklyReportStock.tryParse(
            entry.cast<String, dynamic>(),
          );
          if (parsed != null) stocks.add(parsed);
        }
      }
    }
    if (stocks.isEmpty) return null;

    return WeeklyReport(
      id: id,
      weekStart: weekStart,
      weekEnd: weekEnd,
      stocks: stocks,
    );
  }
}

/// Parses the scanner backend's "18 Sep 2026 11:45:12" IST wall-clock
/// stamps — used by `/api/breadth/full`'s and the `/api/insights/*`
/// endpoints' `as_of` fields — into a proper [DateTime].
///
/// Public (unlike the other parsing helpers below, which are private to this
/// file) because `market_data_service.dart` needs it too, for
/// [VolumeSurgeBoard]'s top-level `as_of` — the one case here where a
/// timestamp sits beside a list rather than inside a model with its own
/// `tryParse`. Returns null (never throws) for anything that isn't exactly
/// this format; an ISO-8601 stamp should go through [DateTime.tryParse]
/// instead, as every other model in this file already does.
DateTime? parseIstStamp(String raw) {
  final match = RegExp(
    r'^(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})$',
  ).firstMatch(raw.trim());
  if (match == null) return null;
  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  final month = months[match.group(2)];
  final day = int.tryParse(match.group(1)!);
  final year = int.tryParse(match.group(3)!);
  final hour = int.tryParse(match.group(4)!);
  final minute = int.tryParse(match.group(5)!);
  final second = int.tryParse(match.group(6)!);
  if (month == null ||
      day == null ||
      year == null ||
      hour == null ||
      minute == null ||
      second == null) {
    return null;
  }
  // The backend's stamp is IST wall-clock (UTC+5:30) with no offset suffix —
  // build the matching UTC instant so `.toLocal()` downstream
  // (`FreshnessStamp`) shows the correct clock time on any device.
  return DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
  ).subtract(const Duration(hours: 5, minutes: 30));
}

/// `as_of` reader shared by [FullBreadth], [VolatilityHistogram],
/// [MomentumTilt] and [VolumeSurgeBoard]'s `tryParse` methods.
DateTime? _asOfStamp(Map<String, dynamic> json) {
  final raw = json['as_of'];
  if (raw is! String) return null;
  return parseIstStamp(raw) ?? DateTime.tryParse(raw);
}

// ─── Shared parsing helpers ────────────────────────────────────────────────

String? _str(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

num? _num(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(
        value.replaceAll(',', '').replaceAll('%', '').trim(),
      );
      if (parsed != null) return parsed;
    }
  }
  return null;
}

List<num> _numList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      final out = <num>[];
      for (final entry in value) {
        if (entry is num) {
          out.add(entry);
        } else if (entry is String) {
          final parsed = num.tryParse(entry);
          if (parsed != null) out.add(parsed);
        } else if (entry is Map) {
          final nested = _num(entry.cast<String, dynamic>(), const [
            'value',
            'price',
            'close',
            'ltp',
          ]);
          if (nested != null) out.add(nested);
        }
      }
      if (out.length >= 2) return out;
    }
  }
  return const [];
}

DateTime? _time(Map<String, dynamic> json, List<String> keys) {
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
