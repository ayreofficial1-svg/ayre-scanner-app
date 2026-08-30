import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';
import 'widgets/ayre_components.dart';
import 'widgets/state_views.dart';

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

  ThemeMode _themeMode = ThemeMode.system;
  bool _splashComplete = false;
  bool _offline = false;
  bool _offlineDismissed = false;
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
    ApiService.onReachabilityChanged = (reachable) {
      if (!mounted) return;
      setState(() {
        _offline = !reachable;
        // A fresh disconnection earns a fresh banner.
        if (!reachable) _offlineDismissed = false;
      });
    };
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
    if (!mounted || value == null) return;
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.system,
      );
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
          // The offline notice is app-wide chrome, above every route, so it never
          // has to be re-implemented per screen.
          return Column(
            children: [
              if (_offline && !_offlineDismissed)
                OfflineBanner(
                  onDismiss: () => setState(() => _offlineDismissed = true),
                ),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatePanel(
                  headline: 'Session expired',
                  message:
                      "Your session's expired — sign in again to continue.",
                  onRetry: () {
                    onSignIn();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  retryLabel: 'Sign in',
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
    return _loggedIn ? const HomeShell() : const LoginScreen();
  }
}
