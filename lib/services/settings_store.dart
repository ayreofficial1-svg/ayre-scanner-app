import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user preferences.
///
/// Every value here changes something the app actually does, and every Settings
/// row is backed by one of them. Toggles for capability the app doesn't have
/// yet (push delivery, price alerts on a watchlist, a weekly digest) are
/// deliberately absent rather than shipped inert — a switch that flips and
/// changes nothing is worse than a shorter Settings screen.
class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  static const _kInAppAlerts = 'alerts_in_app';
  static const _kNewSignals = 'alerts_new_signals';
  static const _kStaleData = 'alerts_stale_data';
  static const _kDisplayName = 'profile_display_name';

  bool _inAppAlerts = true;
  bool _newSignalAlerts = true;
  bool _staleDataWarnings = true;
  String? _displayNameOverride;

  /// The name shown across the app. The backend exposes session identity but no
  /// profile-update endpoint, so this is stored on the device — which is why
  /// Edit Profile offers this field and nothing else.
  String? get displayNameOverride => _displayNameOverride;

  /// The master gate on the in-app alerts list.
  bool get inAppAlerts => _inAppAlerts;

  /// Records an entry when the scanner returns a pick you haven't seen.
  bool get newSignalAlerts => _newSignalAlerts;

  /// Records an entry when market data falls behind its normal update cadence.
  bool get staleDataWarnings => _staleDataWarnings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _inAppAlerts = prefs.getBool(_kInAppAlerts) ?? true;
    _newSignalAlerts = prefs.getBool(_kNewSignals) ?? true;
    _staleDataWarnings = prefs.getBool(_kStaleData) ?? true;
    _displayNameOverride = prefs.getString(_kDisplayName);
    notifyListeners();
  }

  Future<void> setDisplayName(String? value) async {
    final trimmed = value?.trim();
    _displayNameOverride = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_displayNameOverride == null) {
      await prefs.remove(_kDisplayName);
    } else {
      await prefs.setString(_kDisplayName, _displayNameOverride!);
    }
  }

  Future<void> setInAppAlerts(bool value) =>
      _set(_kInAppAlerts, value, () => _inAppAlerts = value);

  Future<void> setNewSignalAlerts(bool value) =>
      _set(_kNewSignals, value, () => _newSignalAlerts = value);

  Future<void> setStaleDataWarnings(bool value) =>
      _set(_kStaleData, value, () => _staleDataWarnings = value);

  Future<void> _set(String key, bool value, VoidCallback apply) async {
    apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

enum NoticeKind { signal, staleData }

/// One entry in the alerts list.
class Notice {
  const Notice({
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
  });

  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'title': title,
    'body': body,
    'at': at.toIso8601String(),
  };

  static Notice? tryParse(Map<String, dynamic> json) {
    final at = DateTime.tryParse(json['at']?.toString() ?? '');
    final kindName = json['kind']?.toString();
    NoticeKind? kind;
    for (final candidate in NoticeKind.values) {
      if (candidate.name == kindName) kind = candidate;
    }
    if (at == null || kind == null) return null;
    return Notice(
      kind: kind,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      at: at,
    );
  }
}

/// The reverse-chronological list behind the header's notification bell.
///
/// Entries come from things that genuinely happened while you were using the
/// app — a scanner pick you hadn't seen, a data source falling behind — and
/// each class is gated by its matching switch in Settings, so turning one off
/// visibly stops that kind of entry. Nothing here is seeded or sample data.
class NotificationLog extends ChangeNotifier {
  NotificationLog._();

  static final NotificationLog instance = NotificationLog._();

  static const _key = 'alerts_log';
  static const _seenKey = 'alerts_log_seen';
  static const _maxEntries = 40;
  static const _dedupeWindow = Duration(minutes: 10);

  List<Notice> _entries = const [];
  DateTime? _lastSeen;

  List<Notice> get entries => _entries;

  /// Drives the bell's "new" dot.
  bool get hasUnread =>
      _entries.isNotEmpty &&
      (_lastSeen == null || _entries.first.at.isAfter(_lastSeen!));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getString(_seenKey);
    _lastSeen = seen == null ? null : DateTime.tryParse(seen);

    final raw = prefs.getString(_key);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _entries = decoded
            .whereType<Map<String, dynamic>>()
            .map(Notice.tryParse)
            .whereType<Notice>()
            .toList();
      }
    }
    notifyListeners();
  }

  bool _allows(NoticeKind kind) {
    final settings = SettingsStore.instance;
    if (!settings.inAppAlerts) return false;
    return switch (kind) {
      NoticeKind.signal => settings.newSignalAlerts,
      NoticeKind.staleData => settings.staleDataWarnings,
    };
  }

  Future<void> add(Notice notice) async {
    if (!_allows(notice.kind)) return;

    // Collapse a repeat of the same entry inside a short window, so a couple of
    // refreshes in a row don't read as several separate events.
    final latest = _entries.isEmpty ? null : _entries.first;
    if (latest != null &&
        latest.title == notice.title &&
        notice.at.difference(latest.at).abs() < _dedupeWindow) {
      return;
    }

    _entries = [notice, ..._entries].take(_maxEntries).toList();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> markAllSeen() async {
    if (_entries.isEmpty) return;
    _lastSeen = _entries.first.at;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenKey, _lastSeen!.toIso8601String());
  }
}

/// Remembers which signal symbols have already been seen, so "new pick" alerts
/// fire on genuinely new entries rather than on every refresh.
class SeenSignalsStore {
  const SeenSignalsStore._();

  static const _key = 'seen_signal_symbols';

  /// Returns the symbols in [symbols] that hadn't been seen before, and records
  /// all of them as seen.
  static Future<List<String>> diffAndRecord(Iterable<String> symbols) async {
    final prefs = await SharedPreferences.getInstance();
    final known = prefs.getStringList(_key)?.toSet() ?? <String>{};

    // First run just establishes the baseline — the whole existing board isn't
    // "new" the first time the app opens.
    final baseline = known.isEmpty;
    final fresh = symbols.where((s) => !known.contains(s)).toList();

    await prefs.setStringList(_key, {...known, ...symbols}.toList());
    return baseline ? const [] : fresh;
  }
}
