import 'dart:math';

/// The wording for every notification the app writes itself.
///
/// Matches the backend copy for notices the app records itself or receives
/// without the notification text.
///
/// Language rule: plain words only. A heading is two or three words, followed
/// by the stock, then one short line.
class NotificationCopy {
  const NotificationCopy._();

  static final Random _random = Random();
  static final Map<String, int> _last = {};

  // ── Pools ────────────────────────────────────────────────────────────────

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

  static ({String title, String body}) signal({
    required String stock,
    bool revised = false,
    num? potentialReturnPct,
  }) {
    final heading = revised ? 'Pick Updated' : 'Fresh Pick';
    final body = potentialReturnPct != null && potentialReturnPct.isFinite
        ? 'Potential return: ${potentialReturnPct.toStringAsFixed(2)}%.'
        : 'Open Signals for details.';
    return (title: '$heading: $stock', body: body);
  }

  /// An exit call, with the profit or loss in the body.
  static ({String title, String body}) exitSignal({
    required String stock,
    required num profit,
  }) {
    final loss = profit < 0;
    final pool = loss ? _exitLoss : _exitProfit;
    final heading = pool[_pick(loss ? 'exit-loss' : 'exit', pool.length)];
    final label = loss ? 'Loss' : 'Profit';
    return (
      title: '$heading: $stock',
      body: '$label ${formatRupees(profit.abs())}. Open Alerts for details.',
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

  /// Random index that never repeats the previous one for the same [key].
  static int _pick(String key, int length) {
    if (length <= 1) return 0;
    var index = _random.nextInt(length);
    if (index == _last[key]) index = (index + 1 + _random.nextInt(length - 1)) % length;
    _last[key] = index;
    return index;
  }
}
