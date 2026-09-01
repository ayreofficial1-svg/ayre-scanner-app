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
  sensex(id: 'SENSEX', label: 'SENSEX', apiKey: 'sensex'),
  bankNifty(id: 'BANKNIFTY', label: 'BANK NIFTY', apiKey: 'bank_nifty');

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
