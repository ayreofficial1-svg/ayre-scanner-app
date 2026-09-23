import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/reachability.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';
import 'widgets/ayre_components.dart';
import 'widgets/state_views.dart';

/// The single switch for the client-side sign-in gate.
///
/// `false` (current): startup skips `ApiService.loadSavedCookie()` /
/// `getSession()` and goes straight to `HomeShell`. Set to `true` to restore
/// the login gate; nothing else needs to change — `LoginScreen`,
/// `ApiService.login/logout/getSession` and `SessionExpiredScreen` are all
/// still wired.
///
/// This flag only controls the app. The backend enforces sign-in on its own
/// (`_require_authentication`, an `@app.before_request` hook in the scanner's
/// `main.py`), so while that hook is active, unauthenticated `/api/*` calls
/// still return 401 and the app routes to `SessionExpiredScreen`.
const bool kEnableAuthStartupGate = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AyreScannerApp());
}

class AyreScannerApp extends StatefulWidget {
  const AyreScannerApp({super.key});

  @override
  State<AyreScannerApp> createState() => _AyreScannerAppState();
}

class _AyreScannerAppState extends State<AyreScannerApp> {
  static const _themeModeKey = 'theme_mode';

  final _navigatorKey = GlobalKey<NavigatorState>();

  // Phase 1A (HIG alignment): `system` is a valid, selectable third option
  // again (Settings' Appearance tiles). Default for a fresh install stays
  // `dark`, unchanged, so existing users see no silent shift — `system` is
  // only ever reached by an explicit user choice now.
  ThemeMode _themeMode = ThemeMode.dark;
  bool _splashComplete = false;
  bool _sessionExpired = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    // A session dying mid-use routes to a calm re-auth prompt rather than
    // leaving the user on a screen that will never load.
    ApiService.onSessionExpired = () {
      if (!mounted || _sessionExpired) return;
      setState(() => _sessionExpired = true);
    };
    // Scoped to its own ChangeNotifier rather than this widget's setState —
    // see ReachabilityStore's doc for why a root-level setState here was a
    // problem.
    ApiService.onReachabilityChanged = ReachabilityStore.instance.setReachable;
  }

  @override
  void dispose() {
    ApiService.onSessionExpired = null;
    ApiService.onReachabilityChanged = null;
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadThemeMode(),
      SettingsStore.instance.load(),
      NotificationLog.instance.load(),
    ]);
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
        navigatorKey: _navigatorKey,
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
        home: _sessionExpired
            ? SessionExpiredScreen(
                onSignIn: () => setState(() => _sessionExpired = false),
              )
            : _StartupGate(
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

/// Shown when an authenticated call is rejected. Deliberately calm and plain: no
/// status code, no crash, one clear action.
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

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
                // Phase 4: the headline, message, glyph and verb all come
                // from the preset now — the literal 'Sign in' label this used
                // to pass by hand is exactly the §14.5 drift the preset
                // exists to stop ("Sign in again" is the verb for an expired
                // session; "Sign in" is the verb for a login screen).
                StatePanel.sessionExpired(
                  onRetry: () {
                    onSignIn();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs the splash, then checks for a session.
class _StartupGate extends StatefulWidget {
  const _StartupGate({
    required this.onSplashComplete,
    required this.splashComplete,
  });

  final VoidCallback onSplashComplete;
  final bool splashComplete;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (!widget.splashComplete) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    if (!kEnableAuthStartupGate) {
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _checking = false;
      });
      return;
    }

    await ApiService.loadSavedCookie();
    final session = await ApiService.getSession();
    if (!mounted) return;
    setState(() {
      _loggedIn = session != null;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !widget.splashComplete) {
      return AyreSplashScreen(onFinished: widget.onSplashComplete);
    }
    return _loggedIn ? HomeShell() : const LoginScreen();
  }
}