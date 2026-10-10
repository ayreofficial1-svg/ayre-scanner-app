import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'api_service.dart';
import 'app_lifecycle.dart';
import 'auth_service.dart';
import 'firebase_bootstrap.dart';
import 'notification_copy.dart';
import 'settings_store.dart';

/// Push notifications (Firebase Cloud Messaging).
///
/// This plugs into the app's existing alert system rather than running a
/// second one:
///
///  * **Background / terminated** — the OS shows the notification itself (the
///    backend sends an FCM `notification` payload). Three kinds arrive, told
///    apart by the `type` in the message data:
///      - `signal`        a new pick → tap opens Home, scrolled to Signals. The Alerts
///                        list fills in through the [SeenSignalsStore] diff
///                        when Signals loads, so there is no duplicate entry.
///      - `signal_update` an already-announced pick that changed → tap opens
///                        Home (Signals) and the change is added to Alerts.
///      - `entry_reached` a published pick reached its entry level → tap
///                        records it in Alerts and opens Home (Signals).
///      - `exit`          a call to exit a pick (`symbol`, `profit`,
///                        `exit_price`) → tap opens the Alerts screen, where
///                        the entry is added.
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

  /// Bumps when the user taps a notification that should land on the Alerts
  /// screen (exit calls). `HomeShell` listens and opens it.
  final ValueNotifier<int> openAlertsRequests = ValueNotifier<int>(0);

  /// Bumps when Signals should reload now (an entry-reached message arrived
  /// or was tapped). `SignalsSection` listens. No timer; this is event-driven.
  final ValueNotifier<int> refreshSignalsRequests = ValueNotifier<int>(0);

  bool _started = false;
  bool _available = false;
  bool _permissionChecked = false;
  bool _denied = false;
  bool _pendingOpenSignals = false;
  bool _pendingOpenAlerts = false;
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

  /// Same as [consumePendingOpenSignals], for the Alerts screen.
  bool consumePendingOpenAlerts() {
    final pending = _pendingOpenAlerts;
    _pendingOpenAlerts = false;
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

    // Firebase is normally already initialised by authentication at startup;
    // this is idempotent.
    if (!await FirebaseBootstrap.ensureInitialised()) {
      // No Firebase config in this build. Push stays off; nothing else cares.
      debugPrint('Push disabled — Firebase is not configured.');
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

    // Push registration only happens while someone is signed in.
    AuthService.instance.phase.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  bool get _signedIn => AuthService.instance.phase.value == AuthPhase.signedIn;

  void _onAuthChanged() {
    if (!_signedIn) return;
    // A different account may now own this device: register again.
    _lastSynced = null;
    if (SettingsStore.instance.pushEnabled && !_permissionChecked) {
      unawaited(_enable());
    } else {
      unawaited(_sync());
    }
  }

  /// Best-effort removal of this device's token, called just before sign out
  /// (while the sign-in is still valid).
  Future<void> unregisterForSignOut() async {
    final token = _token;
    if (!_available || token == null) return;
    final ok = await ApiService.unregisterDevice(token);
    if (ok) _lastSynced = 'off|$token';
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
    if (!_signedIn) return;
    final settings = SettingsStore.instance;
    if (settings.pushEnabled && !_permissionChecked) {
      unawaited(_enable());
    } else {
      unawaited(_sync());
    }
  }

  void _onResumed() {
    if (_signedIn) unawaited(_sync());
  }

  /// Brings the backend's record of this device in line with Settings. Cheap
  /// to call repeatedly: it does nothing unless something actually changed
  /// since the last successful sync.
  Future<void> _sync() async {
    final token = _token;
    if (!_available || token == null || !_signedIn) return;

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

  static const _typeSignal = 'signal';
  static const _typeRevised = 'signal_update';
  static const _typeExit = 'exit';
  static const _typeEntryReached = 'entry_reached';

  /// Turns a push into an Alerts entry. The wording the backend put in the
  /// notification is used as-is, so the list matches what the phone showed;
  /// the app's own copy only fills in if that text is missing.
  Notice? _noticeFrom(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString();
    final title = message.notification?.title?.trim() ?? '';
    final body = message.notification?.body?.trim() ?? '';
    final symbol = (data['symbol'] ?? '').toString().trim().toUpperCase();

    switch (type) {
      case _typeSignal:
      case _typeRevised:
        if (symbol.isEmpty) return null;
        final fallback = type == _typeSignal
            ? NotificationCopy.newSignal(symbol)
            : NotificationCopy.revisedSignal(symbol);
        return Notice(
          kind: type == _typeSignal ? NoticeKind.signal : NoticeKind.revised,
          title: title.isNotEmpty ? title : fallback.title,
          body: body.isNotEmpty ? body : fallback.body,
          at: DateTime.now(),
        );

      case _typeEntryReached:
        if (symbol.isEmpty && title.isEmpty) return null;
        final copy = symbol.isEmpty ? null : NotificationCopy.entryReached(symbol);
        return Notice(
          kind: NoticeKind.entryReached,
          title: title.isNotEmpty ? title : copy!.title,
          body: body.isNotEmpty ? body : (copy?.body ?? ''),
          at: DateTime.now(),
        );

      case _typeExit:
        if (title.isNotEmpty && body.isNotEmpty) {
          return Notice(
            kind: NoticeKind.exit,
            title: title,
            body: body,
            at: DateTime.now(),
          );
        }
        final profit = NotificationCopy.parseAmount(data['profit']);
        final exitPrice = NotificationCopy.parseAmount(data['exit_price']);
        if (symbol.isEmpty || profit == null || exitPrice == null) return null;
        final copy = NotificationCopy.exitSignal(
          stock: symbol,
          profit: profit,
          exitPrice: exitPrice,
        );
        return Notice(
          kind: NoticeKind.exit,
          title: copy.title,
          body: copy.body,
          at: DateTime.now(),
        );
    }

    if (title.isEmpty) return null;
    return Notice(
      kind: NoticeKind.general,
      title: title,
      body: body,
      at: DateTime.now(),
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notice = _noticeFrom(message);
    if (notice == null) return;

    final settings = SettingsStore.instance;
    if (!settings.pushEnabled) return;
    final isSignalKind = notice.kind == NoticeKind.signal ||
        notice.kind == NoticeKind.revised ||
        notice.kind == NoticeKind.entryReached;
    if (isSignalKind && !settings.newSignalAlerts) return;

    await NotificationLog.instance.add(notice);
    if (notice.kind == NoticeKind.signal) {
      // Already recorded above; stop Signals from recording it a second time
      // when it next loads.
      await SeenSignalsStore.markSeen([
        (message.data['symbol'] ?? '').toString().trim().toUpperCase(),
      ]);
    }
    if (notice.kind == NoticeKind.entryReached) {
      // The published fact is on the Signals card; load it now.
      refreshSignalsRequests.value++;
    }
    _showBanner(notice);
  }

  /// A notification was tapped while the app was closed or in the background.
  void _onMessageOpened(RemoteMessage message) {
    switch (message.data['type']?.toString()) {
      case _typeSignal:
        // Signals records this one itself when it loads (see class doc).
        _requestOpenSignals();
      case _typeRevised:
        // Signals can't tell a revision from a pick it already knows, so the
        // entry is recorded here, from the tap.
        _recordFromTap(message);
        _requestOpenSignals();
      case _typeEntryReached:
        // Signals can't tell this from a pick it already knows, so the entry
        // is recorded here, from the tap.
        _recordFromTap(message);
        refreshSignalsRequests.value++;
        _requestOpenSignals();
      case _typeExit:
        _recordFromTap(message);
        _requestOpenAlerts();
      default:
        // A custom message (`general`, or any type this build doesn't know)
        // tapped from the background or a closed app: record it and show it
        // in Alerts, the same as an exit call.
        final notice = _noticeFrom(message);
        if (notice == null) return;
        _recordFromTap(message);
        _requestOpenAlerts();
    }
  }

  void _recordFromTap(RemoteMessage message) {
    final notice = _noticeFrom(message);
    if (notice == null || !SettingsStore.instance.pushEnabled) return;
    unawaited(NotificationLog.instance.add(notice));
  }

  void _requestOpenSignals() {
    _pendingOpenSignals = true;
    openSignalsRequests.value++;
    // Clears whatever sits on the *root* navigator (sheets, dialogs). Details
    // pushed inside a tab live on that tab's own navigator; `HomeShell`
    // selects Home and pops its stack when it handles the request (A3).
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void _requestOpenAlerts() {
    _pendingOpenAlerts = true;
    openAlertsRequests.value++;
    // Root-level overlays only; `HomeShell` opens Alerts on Home's navigator.
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void _showBanner(Notice notice) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    final context = navigatorKey.currentContext;
    final tokens = context?.tokens;

    final VoidCallback? onView = switch (notice.kind) {
      NoticeKind.signal ||
      NoticeKind.revised ||
      NoticeKind.entryReached => _requestOpenSignals,
      NoticeKind.exit => _requestOpenAlerts,
      NoticeKind.general => null,
    };

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
          action: onView == null
              ? null
              : SnackBarAction(
                  label: 'View',
                  textColor: tokens?.accentInk,
                  onPressed: onView,
                ),
        ),
      );
  }
}
