import 'dart:math';

/// The wording for every notification the app writes itself.
///
/// Each kind has a pool of short variations and a pick is shuffled so the same
/// line doesn't show up twice in a row. The backend (`alerts/push.py`) keeps a
/// matching pool for the notification the phone shows while the app is closed;
/// this copy is used for anything the app records on its own (the Signals
/// board spotting a new pick, a message that arrives with the app open).
///
/// Language rule: plain words only. A heading is two or three words, followed
/// by the stock, then one short line.
class NotificationCopy {
  const NotificationCopy._();

  static final Random _random = Random();
  static final Map<String, int> _last = {};

  // ── Pools ────────────────────────────────────────────────────────────────

  static const _newPick = <(String, String)>[
    ('New Pick', 'A fresh pick is ready.'),
    ('New Signal', 'Check Signals on Home.'),
    ('Fresh Setup', 'A new setup is available.'),
    ('New Opportunity', 'See Signals on Home.'),
    ('Buy Setup', 'A new setup is ready.'),
    ('Fresh Pick', 'Take a look in Signals.'),
    ('Buy Signal', 'Open Signals on Home.'),
  ];

  static const _revised = <(String, String)>[
    ('Signal Updated', 'The signal has been updated.'),
    ('Pick Revised', 'The existing pick has changed.'),
    ('Updated Signal', 'Check the latest details.'),
    ('Setup Updated', 'The setup has been updated.'),
    ('Pick Updated', 'Open Signals for the change.'),
  ];

  static const _entryReached = <(String, String)>[
    ('Level Reached', 'has reached its entry level.'),
    ('Entry Level Reached', 'touched its entry level.'),
    ('Entry Update', 'reached its entry level.'),
  ];

  static const _exitProfit = <String>[
    'Book Profit',
    'Exit Signal',
    'Time to Exit',
    'Sell Signal',
    'Take Profit',
  ];

  // Used when the exit is at a loss: "Book Profit" would be wrong there.
  static const _exitLoss = <String>['Exit Signal', 'Time to Exit', 'Sell Signal'];

  // ── Public ───────────────────────────────────────────────────────────────

  /// A new pick, e.g. `New Pick: RELIANCE` / `A fresh pick is ready.`
  static ({String title, String body}) newSignal(String stock) =>
      _fromPairs('new', _newPick, stock);

  /// An already-announced pick that has changed.
  static ({String title, String body}) revisedSignal(String stock) =>
      _fromPairs('revised', _revised, stock);

  /// A published pick reached its entry level. Informational only.
  static ({String title, String body}) entryReached(String stock) {
    final (heading, line) =
        _entryReached[_pick('entry-reached', _entryReached.length)];
    return (
      title: '$heading: $stock',
      body: '$stock $line Open Signals for details.',
    );
  }

  /// An exit call: `Book Profit: RELIANCE` / `Profit ₹120 | Exit ₹2,850`.
  static ({String title, String body}) exitSignal({
    required String stock,
    required num profit,
    required num exitPrice,
  }) {
    final loss = profit < 0;
    final pool = loss ? _exitLoss : _exitProfit;
    final heading = pool[_pick(loss ? 'exit-loss' : 'exit', pool.length)];
    final label = loss ? 'Loss' : 'Profit';
    return (
      title: '$heading: $stock',
      body: '$label ${formatRupees(profit.abs())} | '
          'Exit ${formatRupees(exitPrice)}',
    );
  }

  /// `₹2,850`, `₹120.50`, `₹1,23,456` — Indian grouping, decimals only when
  /// the amount actually has paise.
  static String formatRupees(num value) {
    final negative = value < 0;
    final abs = value.abs();
    final whole = abs.truncate();
    final paise = ((abs - whole) * 100).round();
    var rupees = whole;
    var p = paise;
    if (p == 100) {
      rupees += 1;
      p = 0;
    }
    final digits = rupees.toString();
    String grouped;
    if (digits.length <= 3) {
      grouped = digits;
    } else {
      final head = digits.substring(0, digits.length - 3);
      final tail = digits.substring(digits.length - 3);
      final pairs = RegExp(r'(\d)(?=(\d\d)+$)');
      grouped = '${head.replaceAllMapped(pairs, (m) => '${m[1]},')},$tail';
    }
    final decimals = p == 0 ? '' : '.${p.toString().padLeft(2, '0')}';
    return '${negative ? '−' : ''}₹$grouped$decimals';
  }

  /// Reads a number out of a push `data` value (always a string there).
  static num? parseAmount(Object? raw) {
    if (raw == null) return null;
    return num.tryParse(raw.toString().replaceAll(',', '').trim());
  }

  // ── Internals ────────────────────────────────────────────────────────────

  static ({String title, String body}) _fromPairs(
    String key,
    List<(String, String)> pool,
    String stock,
  ) {
    final (heading, line) = pool[_pick(key, pool.length)];
    return (title: '$heading: $stock', body: line);
  }

  /// Random index that never repeats the previous one for the same [key].
  static int _pick(String key, int length) {
    if (length <= 1) return 0;
    var index = _random.nextInt(length);
    if (index == _last[key]) index = (index + 1 + _random.nextInt(length - 1)) % length;
    _last[key] = index;
    return index;
  }
}
