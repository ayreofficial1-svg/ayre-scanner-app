/// Wire models for the research content the app shows: the analyst's
/// recommendations, Learn courses, desk notes, weekly reports and the
/// registration details.
///
/// Each `tryParse` returns null when a field the UI genuinely cannot render
/// without is missing or unparseable, so a malformed row is dropped rather than
/// producing a half-drawn card. Optional fields degrade the UI locally instead
/// of failing the whole section.
library;

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

  /// Round-trips through [tryParse]; see [Signal.toJson].
  Map<String, dynamic> toJson() => {
    'ra_registration_number': registrationNumber,
    'disclaimer': disclaimer,
  };
}

/// An analyst recommendation (`GET /api/signals`). Every field is typed by the
/// research analyst: symbol, name, rationale and the three levels. Nothing
/// here is sourced from an exchange feed, and any such field that an older
/// payload might still carry (last price, percent change, "entry reached"
/// facts) is deliberately ignored by [tryParse] and never written by [toJson].
class Signal {
  const Signal({
    required this.symbol,
    this.rationale = '',
    this.name,
    this.entry,
    this.exitPrice,
    this.stop,
    this.addedOn,
  });

  final String symbol;
  final String rationale;
  final String? name;
  final num? entry;
  final num? exitPrice;
  final num? stop;
  final String? addedOn;

  static Signal? tryParse(Map<String, dynamic> json) {
    final symbol = _str(json, const ['symbol', 'ticker', 'scrip']);
    if (symbol == null || symbol.isEmpty) return null;
    return Signal(
      symbol: symbol,
      rationale:
          _str(json, const ['rationale', 'reason', 'note', 'body']) ?? '',
      name: _str(json, const ['name', 'companyName', 'company_name']),
      entry: _num(json, const ['entry_price', 'entry']),
      exitPrice: _num(json, const ['exit_price', 'exitPrice']),
      stop: _num(json, const ['stop_loss', 'stoploss', 'stop']),
      addedOn: _str(json, const ['date_added', 'added_on', 'created_at']),
    );
  }

  /// Round-trips through [tryParse]. Writes analyst-typed fields only, so the
  /// persistent cache never holds anything derived from market data.
  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'rationale': rationale,
    if (name != null) 'name': name,
    if (entry != null) 'entry_price': entry,
    if (exitPrice != null) 'exit_price': exitPrice,
    if (stop != null) 'stop_loss': stop,
    if (addedOn != null) 'date_added': addedOn,
  };
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

  /// Round-trips through [tryParse]; see [Signal.toJson].
  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'body': body,
    if (lessonsTotal != null) 'lessons': lessonsTotal,
    if (lessonsDone != null) 'completed': lessonsDone,
  };
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

  /// Round-trips through [tryParse]; see [Signal.toJson].
  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    if (category != null) 'category': category,
    'featured': featured,
  };
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

  /// Optional bullish/bearish flag (Phase 6). No longer rendered anywhere —
  /// the website's admin panel has no field for it and neither the Weekly
  /// Report card nor the Signals cards show a bullish/bearish tag anymore —
  /// kept only so old admin-entered rows still round-trip through parsing.
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

  /// Round-trips through [tryParse]; see [Signal.toJson].
  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'profit_pct': profitPct,
    'outcome': outcome,
    if (name != null) 'name': name,
    'bullish': bullish,
    if (tradeLabel != null) 'trade_label': tradeLabel,
    if (entryPrice != null) 'entry_price': entryPrice,
    if (exitPrice != null) 'exit_price': exitPrice,
    if (pnlAmount != null) 'pnl_amount': pnlAmount,
    if (dateOfRecommendation != null)
      'date_of_recommendation': dateOfRecommendation!.toIso8601String(),
    if (exitDate != null) 'exit_date': exitDate!.toIso8601String(),
    if (durationDays != null) 'duration_days': durationDays,
  };
}

/// One week's admin-entered performance record (`GET /api/weekly-report`),
/// shown on the Reports tab. Purely
/// historical and hand-entered by the admin on the website — there is no
/// automatic target/stop-loss detection anywhere in this app or the backend
/// (§A.4). [weekStart]/[weekEnd] arrive as plain ISO dates; the "6th
/// September to 12th September" display format is computed client-side (see
/// `ayre_weekly_report.dart`'s date-range formatter), not sent pre-formatted by the
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

  /// Round-trips through [tryParse]; see [Signal.toJson].
  Map<String, dynamic> toJson() => {
    'id': id,
    'week_start': weekStart.toIso8601String(),
    'week_end': weekEnd.toIso8601String(),
    'stocks': stocks.map((s) => s.toJson()).toList(),
  };
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
