import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/account_session.dart';
import 'services/api_service.dart';
import 'services/app_lifecycle.dart';
import 'services/auth_service.dart';
import 'services/email_verification.dart';
import 'services/push_service.dart';
import 'services/reachability.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';
import 'widgets/ayre_components.dart';
import 'widgets/ayre_icons.dart';
import 'widgets/state_views.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLifecycleService.instance.init();
  runApp(const AyreScannerApp());
}

class AyreScannerApp extends StatefulWidget {
  const AyreScannerApp({super.key});

  @override
  State<AyreScannerApp> createState() => _AyreScannerAppState();
}

class _AyreScannerAppState extends State<AyreScannerApp> {
  static const _themeModeKey = 'theme_mode';

  // Phase 1A (HIG alignment): `system` is a valid, selectable third option
  // again (Settings' Appearance tiles). Default for a fresh install stays
  // `dark`, unchanged, so existing users see no silent shift — `system` is
  // only ever reached by an explicit user choice now.
  ThemeMode _themeMode = ThemeMode.dark;
  bool _splashComplete = false;
  AuthPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    // Sign-in, sign-out and a session ended elsewhere all arrive here; the
    // gate below swaps screens by itself, so nothing pushes a login by hand.
    AuthService.instance.phase.addListener(_onAuthPhase);
    // Scoped to its own ChangeNotifier rather than this widget's setState —
    // see ReachabilityStore's doc for why a root-level setState here was a
    // problem.
    ApiService.onReachabilityChanged = ReachabilityStore.instance.setReachable;
  }

  @override
  void dispose() {
    AuthService.instance.phase.removeListener(_onAuthPhase);
    ApiService.onReachabilityChanged = null;
    super.dispose();
  }

  void _onAuthPhase() {
    final phase = AuthService.instance.phase.value;
    final previous = _lastPhase;
    _lastPhase = phase;
    if (phase == previous) return;

    // Anything pushed over the gate (Register, Forgot password, Profile
    // sub-pages) must not outlive the state change.
    if (phase == AuthPhase.signedIn || phase == AuthPhase.signedOut) {
      PushService.instance.navigatorKey.currentState?.popUntil(
        (route) => route.isFirst,
      );
    }
    if (phase == AuthPhase.signedOut && previous == AuthPhase.signedIn) {
      unawaited(AccountSession.clearLocalData());
    }
    // Whenever someone signs in, make sure nothing left on this device by a
    // different account (or a cut-short sign-out) is shown to them.
    final uid = AuthService.instance.currentUser?.uid;
    if (phase == AuthPhase.signedIn && uid != null) {
      unawaited(AccountSession.onSignedIn(uid));
    }
  }

  Future<void> _bootstrap() async {
    // Firebase and the auth state come first: the first screen decision
    // depends on them. Push init follows, once someone could be signed in.
    EmailVerificationService.instance.init();
    final authReady = AuthService.instance.init();
    await Future.wait([
      _loadThemeMode(),
      SettingsStore.instance.load(),
      NotificationLog.instance.load(),
      ApiService.purgeLegacyCookie(),
    ]);
    await authReady;
    // Deliberately not awaited into the UI path: the permission prompt and
    // token fetch must never hold up first paint. Failures are contained
    // inside PushService.
    unawaited(PushService.instance.init());
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (!mounted) return;

    // No stored preference yet: keep the app's existing default (`dark`)
    // rather than defaulting a fresh install to `system` — 1A widens the
    // picker, it doesn't change what a new user sees first.
    if (value == null) return;

    // Phase 1A: `system` is restored as a real, persisted choice — no more
    // migrating it away to a resolved light/dark value on load. A value
    // stored by an older build that no longer matches a known mode name
    // falls back to `dark`, same as before.
    setState(() {
      _themeMode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  void _onSplashComplete() {
    if (mounted) setState(() => _splashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeController(
      themeMode: _themeMode,
      setThemeMode: setThemeMode,
      child: MaterialApp(
        title: 'Ayre Scanner',
        debugShowCheckedModeBanner: false,
        // Owned by PushService so a notification tap can return to the tab
        // shell, and a foreground push can show its banner.
        navigatorKey: PushService.instance.navigatorKey,
        scaffoldMessengerKey: PushService.instance.messengerKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        themeAnimationDuration: AppMotion.medium,
        themeAnimationCurve: AppMotion.ease,
        builder: (context, child) {
          // Two pieces of app-wide chrome, applied once here rather than
          // re-implemented per screen: the offline notice, and the user's chosen
          // text size as a scale over everything (including Material's own
          // widgets, which theme tokens alone would miss).
          return ListenableBuilder(
            listenable: SettingsStore.instance,
            builder: (context, _) {
              final media = MediaQuery.of(context);
              // Multiply, don't clamp: clamping would silently ignore a
              // *smaller* preference whenever the OS scale already sat inside
              // the range. Measuring a known size recovers the OS's effective
              // linear factor, which the preference then scales.
              final osFactor = media.textScaler.scale(100) / 100;
              final effective =
                  (osFactor * SettingsStore.instance.textSize.scale).clamp(
                    0.8,
                    2.2,
                  );
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(effective)),
                child: Column(
                  children: [
                    // Scoped listener: only this banner rebuilds when
                    // reachability changes, not the whole app tree.
                    ListenableBuilder(
                      listenable: ReachabilityStore.instance,
                      builder: (context, _) {
                        final store = ReachabilityStore.instance;
                        if (!store.offline || store.dismissed) {
                          return const SizedBox.shrink();
                        }
                        return OfflineBanner(
                          onDismiss: ReachabilityStore.instance.dismiss,
                        );
                      },
                    ),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                ),
              );
            },
          );
        },
        home: _StartupGate(
          onSplashComplete: _onSplashComplete,
          splashComplete: _splashComplete,
        ),
      ),
    );
  }
}

class AppThemeController extends InheritedWidget {
  const AppThemeController({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
  });

  /// System / Light / Dark — the segmented selector in Settings writes here.
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> setThemeMode;

  static AppThemeController of(BuildContext context) {
    final controller = context
        .dependOnInheritedWidgetOfExactType<AppThemeController>();
    assert(controller != null, 'No AppThemeController found in context');
    return controller!;
  }

  @override
  bool updateShouldNotify(AppThemeController oldWidget) {
    return oldWidget.themeMode != themeMode ||
        oldWidget.setThemeMode != setThemeMode;
  }
}

/// Blocking screen shown when sign-in cannot start (for example Firebase is not
/// configured in this build). The app is never entered unauthenticated.
class AuthUnavailableScreen extends StatelessWidget {
  const AuthUnavailableScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 360,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatePanel.failed(
                  headline: 'Sign-in unavailable',
                  message:
                      "We couldn't start sign-in. Check your connection and "
                      'try again.',
                  glyph: AyreGlyph.lock,
                  onRetry: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs the splash, then shows whichever screen the auth state calls for:
/// initialising → splash, unavailable → blocking error, signed out → sign in,
/// signed in → the app. A cached signed-in user enters the app even offline.
class _StartupGate extends StatelessWidget {
  const _StartupGate({
    required this.onSplashComplete,
    required this.splashComplete,
  });

  final VoidCallback onSplashComplete;
  final bool splashComplete;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthPhase>(
      valueListenable: AuthService.instance.phase,
      builder: (context, phase, _) {
        if (!splashComplete) {
          return AyreSplashScreen(onFinished: onSplashComplete);
        }
        return switch (phase) {
          AuthPhase.initializing => AyreSplashScreen(
            onFinished: onSplashComplete,
          ),
          AuthPhase.unavailable => AuthUnavailableScreen(
            onRetry: () => unawaited(AuthService.instance.init()),
          ),
          AuthPhase.signedOut => const LoginScreen(),
          AuthPhase.signedIn => HomeShell(),
        };
      },
    );
  }
}
