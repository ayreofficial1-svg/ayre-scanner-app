import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

const bool kEnableAuthStartupGate = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AyreScannerApp());
}

class AyreScannerApp extends StatefulWidget {
  const AyreScannerApp({super.key});

  @override
  State<AyreScannerApp> createState() => _AyreScannerAppState();
}

class _AyreScannerAppState extends State<AyreScannerApp> {
  static const _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (!mounted || value == null) return;
    setState(() {
      _themeMode = value == ThemeMode.light.name
          ? ThemeMode.light
          : ThemeMode.dark;
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
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        themeAnimationDuration: AppMotion.medium,
        themeAnimationCurve: AppMotion.ease,
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

/// Replaces the old _StartupGate. Runs splash then checks auth session.
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
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
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
