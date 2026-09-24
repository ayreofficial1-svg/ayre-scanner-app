import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'api_service.dart';
import 'app_lifecycle.dart';
import 'settings_store.dart';

/// Push notifications (Firebase Cloud Messaging).
///
/// This plugs into the app's existing alert system rather than running a
/// second one:
///
///  * **Background / terminated** — the OS shows the notification itself (the
///    backend sends an FCM `notification` payload). Tapping it opens the app on
///    the Signals tab. The Alerts list then fills in through the same
///    [SeenSignalsStore] diff that has always recorded new picks when Signals
///    loads, so there is one code path and no duplicate entry.
///  * **Foreground** — FCM shows nothing while the app is open, so the message
///    is recorded straight into [NotificationLog] (the list behind Home's
///    bell) and surfaced as an in-app banner.
///  * **Preferences** — the Settings switches decide what is registered with
///    the backend. "Push notifications" off unregisters the device; "New
///    signal alerts" off keeps the device registered but opts it out of
///    signal pushes (see `signals` in the register call).
///
/// Everything here degrades to a no-op. If Firebase isn't configured for this
/// build (no `google-services.json` / `GoogleService-Info.plist`), or the
/// platform has no FCM (desktop, web), [init] returns quietly and the rest of
/// the app behaves exactly as it did before push existed.
class PushService extends ChangeNotifier {
  PushService._();

  static final PushService instance = PushService._();

  /// Owned here (and handed to `MaterialApp` in main.dart) so a notification
  /// tap can dismiss whatever is on top of the tab shell before switching tab.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Owned here so a foreground message can show a banner without a
  /// BuildContext.
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Bumps when the user taps a notification that should land on Signals.
  /// `HomeShell` listens and switches tab.
  final ValueNotifier<int> openSignalsRequests = ValueNotifier<int>(0);

  bool _started = false;
  bool _available = false;
  bool _permissionChecked = false;
  bool _denied = false;
  bool _pendingOpenSignals = false;
  String? _token;
  String? _lastSynced;

  /// True when this build can receive push at all.
  bool get available => _available;

  /// True when push is wanted but the OS permission was refused, so Settings
  /// can point the user at the system settings instead of a dead switch.
  bool get permissionDenied => _denied;

  /// A tap that arrived before `HomeShell` existed (cold start). The shell
  /// consumes it on first build.
  bool consumePendingOpenSignals() {
    final pending = _pendingOpenSignals;
    _pendingOpenSignals = false;
    return pending;
  }

  /// Call once after [SettingsStore.load] has completed.
  Future<void> init() async {
    if (_started) return;
    _started = true;

    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      await Firebase.initializeApp();
    } catch (e) {
      // No Firebase config in this build. Push stays off; nothing else cares.
      debugPrint('Push disabled — Firebase is not configured: $e');
      return;
    }

    _available = true;
    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    messaging.onTokenRefresh.listen((token) {
      _token = token;
      unawaited(_sync());
    });

    SettingsStore.instance.addListener(_onSettingsChanged);
    // A registration that failed offline is retried whenever the app returns.
    AppLifecycleService.instance.addListener(_onResumed);

    // The notification that launched the app from a terminated state.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _onMessageOpened(initial);

    if (SettingsStore.instance.pushEnabled) {
      await _enable();
    }
  }

  // ── Registration ─────────────────────────────────────────────────────────

  Future<void> _enable() async {
    _permissionChecked = true;
    final messaging = FirebaseMessaging.instance;
    try {
      // Shows the system prompt on Android 13+ and iOS; a no-op grant on older
      // Android.
      final settings = await messaging.requestPermission();
      final denied = settings.authorizationStatus == AuthorizationStatus.denied;
      if (denied != _denied) {
        _denied = denied;
        notifyListeners();
      }
      if (denied) return;
      _token = await messaging.getToken();
    } catch (e) {
      // On iOS the APNs token can arrive after the first call; onTokenRefresh
      // covers that case, so a failure here is not fatal.
      debugPrint('Push token unavailable: $e');
    }
    await _sync();
  }

  void _onSettingsChanged() {
    final settings = SettingsStore.instance;
    if (settings.pushEnabled && !_permissionChecked) {
      unawaited(_enable());
    } else {
      unawaited(_sync());
    }
  }

  void _onResumed() => unawaited(_sync());

  /// Brings the backend's record of this device in line with Settings. Cheap
  /// to call repeatedly: it does nothing unless something actually changed
  /// since the last successful sync.
  Future<void> _sync() async {
    final token = _token;
    if (!_available || token == null) return;

    final settings = SettingsStore.instance;
    final wantPush = settings.pushEnabled && !_denied;
    final signature = wantPush ? '$token|${settings.newSignalAlerts}' : 'off|$token';
    if (signature == _lastSynced) return;

    final ok = wantPush
        ? await ApiService.registerDevice(
            token: token,
            platform: defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
            signals: settings.newSignalAlerts,
          )
        : await ApiService.unregisterDevice(token);
    if (ok) _lastSynced = signature;
  }

  // ── Incoming messages ────────────────────────────────────────────────────

  Notice? _noticeFrom(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title;
    final body = message.notification?.body;

    if (data['type'] == 'signal') {
      final symbol = (data['symbol'] ?? '').toString().trim();
      if (symbol.isEmpty) return null;
      return Notice(
        kind: NoticeKind.signal,
        // Same wording Signals uses when it detects the pick itself, so the
        // list's own repeat-collapsing treats the two as one entry.
        title: 'New scanner pick: $symbol',
        body: (body != null && body.trim().isNotEmpty)
            ? body.trim()
            : 'A new pick is on the Signals tab.',
        at: DateTime.now(),
      );
    }

    if (title == null || title.trim().isEmpty) return null;
    return Notice(
      kind: NoticeKind.general,
      title: title.trim(),
      body: body?.trim() ?? '',
      at: DateTime.now(),
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notice = _noticeFrom(message);
    if (notice == null) return;

    final settings = SettingsStore.instance;
    if (!settings.pushEnabled) return;
    if (notice.kind == NoticeKind.signal && !settings.newSignalAlerts) return;

    await NotificationLog.instance.add(notice);
    if (notice.kind == NoticeKind.signal) {
      // Already recorded above; stop Signals from recording it a second time
      // when it next loads.
      await SeenSignalsStore.markSeen([
        (message.data['symbol'] ?? '').toString().trim().toUpperCase(),
      ]);
    }
    _showBanner(notice);
  }

  void _onMessageOpened(RemoteMessage message) {
    if (message.data['type'] != 'signal') return;
    _pendingOpenSignals = true;
    openSignalsRequests.value++;
    // Anything pushed over the shell (Alerts, a detail page) would hide the
    // tab switch, so return to the shell first.
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void _showBanner(Notice notice) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    final context = navigatorKey.currentContext;
    final tokens = context == null ? null : context.tokens;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notice.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (notice.body.isNotEmpty)
                Text(
                  notice.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tokens == null ? null : AppTypo.body(tokens),
                ),
            ],
          ),
          action: notice.kind == NoticeKind.signal
              ? SnackBarAction(
                  label: 'View',
                  textColor: tokens?.accentInk,
                  onPressed: () {
                    _pendingOpenSignals = true;
                    openSignalsRequests.value++;
                    navigatorKey.currentState?.popUntil(
                      (route) => route.isFirst,
                    );
                  },
                )
              : null,
        ),
      );
  }
}
