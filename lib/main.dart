import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/account_session.dart';
import 'services/api_service.dart';
import 'services/app_lifecycle.dart';
import 'services/auth_service.dart';
import 'services/email_verification.dart';
import 'services/legacy_cache_purge.dart';
import 'services/onboarding_store.dart';
// TEMPORARY (paywall test toggle) — remove before production
import 'services/paywall_test_switch.dart';
import 'services/push_service.dart';
import 'services/reachability.dart';
import 'services/settings_store.dart';
import 'services/store_subscription_gateway.dart';
import 'services/subscription_service.dart';
import 'services/tour_service.dart';
import 'theme/app_theme.dart';
import 'widgets/ayre_components.dart';
import 'widgets/ayre_logo.dart';
import 'widgets/finance_icons.dart';
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

  ThemeMode _themeMode = ThemeMode.light;
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
    // Anyone who reaches the app signed in has no use for the first-run tour.
    // This also covers an updated install whose user was already signed in, so
    // a later sign-out lands on Login rather than the tour.
    if (phase == AuthPhase.signedIn) {
      unawaited(OnboardingStore.instance.markCompleted());
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
      OnboardingStore.instance.load(),
      NotificationLog.instance.load(),
      ApiService.purgeLegacyCookie(),
      LegacyCachePurge.run(),
      // TEMPORARY (paywall test toggle) — remove before production
      PaywallTestSwitch.instance.load(),
    ]);
    // Subscribed at start-up, not when the paywall opens, so purchases that
    // finish while the app was closed, pending approvals and renewals are
    // received. Not awaited: first paint never waits on the store, and
    // failures are contained inside the service.
    SubscriptionService.instance.useGateway(StoreSubscriptionGateway());
    unawaited(SubscriptionService.instance.init());
    await authReady;
    // Deliberately not awaited into the UI path: the permission prompt and
    // token fetch must never hold up first paint. Failures are contained
    // inside PushService.
    unawaited(PushService.instance.init());
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = switch (prefs.getString(_themeModeKey)) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    if (!mounted || mode == _themeMode) return;
    setState(() => _themeMode = mode);
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
        title: 'Investee',
        debugShowCheckedModeBanner: false,
        // Owned by PushService so a notification tap can return to the tab
        // shell, and a foreground push can show its banner.
        navigatorKey: PushService.instance.navigatorKey,
        scaffoldMessengerKey: PushService.instance.messengerKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        // Colours (including the mast palettes) interpolate via
        // AppThemeTokens.lerp; calm, non-bouncing ease.
        themeAnimationDuration:
            MediaQuery.maybeOf(context)?.disableAnimations == true
            ? Duration.zero
            : AppMotion.themeSwitch,
        themeAnimationCurve: AppMotion.ease,
        builder: (context, child) {
          // Two pieces of app-wide chrome, applied once here rather than
          // re-implemented per screen: the offline notice, and the user's chosen
          // text size as a scale over everything (including Material's own
          // widgets, which theme tokens alone would miss).
          final settings = SettingsStore.instance;
          final reachability = ReachabilityStore.instance;
          return ListenableBuilder(
            listenable: Listenable.merge([settings, reachability]),
            builder: (context, _) {
              final media = MediaQuery.of(context);
              final textScale = settings.textSize.scale;
              final showOffline =
                  reachability.offline && !reachability.dismissed;
              // The *effective* brightness: the in-app choice, or the phone's
              // when the mode is System. System bars follow it, not the phone
              // theme alone (N-14).
              final brightness = switch (_themeMode) {
                ThemeMode.light => Brightness.light,
                ThemeMode.dark => Brightness.dark,
                ThemeMode.system => media.platformBrightness,
              };
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.overlayStyle(brightness),
                child: MediaQuery(
                  data: media.copyWith(
                    textScaler: textScale == 1
                        ? media.textScaler
                        : _AppTextScaler(media.textScaler, textScale),
                  ),
                  child: Column(
                    children: [
                      if (showOffline)
                        OfflineBanner(onDismiss: reachability.dismiss)
                      else
                        const SizedBox.shrink(),
                      Expanded(
                        child: Builder(
                          builder: (context) => MediaQuery.removePadding(
                            context: context,
                            removeTop: showOffline,
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
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

/// Applies the in-app preference to each size the OS has already scaled.
class _AppTextScaler extends TextScaler {
  const _AppTextScaler(this.platform, this.multiplier);

  final TextScaler platform;
  final double multiplier;

  @override
  double scale(double fontSize) => platform.scale(fontSize) * multiplier;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _AppTextScaler &&
      platform == other.platform &&
      multiplier == other.multiplier;

  @override
  int get hashCode => Object.hash(platform, multiplier);
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpace.gutterOf(context)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const LogoMark(placement: LogoPlacement.auth),
                  const SizedBox(height: AppSpace.s34),
                  Container(
                    width: AppShape.prominentTileSize,
                    height: AppShape.prominentTileSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surfaceRaised,
                      borderRadius: AppShape.field,
                    ),
                    child: FinanceIcon(
                      FinanceGlyph.info,
                      size: 24,
                      color: t.foregroundMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s21),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      'Sign-in unavailable',
                      textAlign: TextAlign.center,
                      style: AppTypo.sectionTitle(t),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    "We couldn't start sign-in. Check your connection and "
                    'try again.',
                    textAlign: TextAlign.center,
                    style: AppTypo.body(t),
                  ),
                  const SizedBox(height: AppSpace.s21),
                  AyreButton(label: 'Try again', onPressed: onRetry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs the splash, then shows whichever screen the auth state calls for:
/// initialising → splash, unavailable → blocking error, signed out → the
/// first-run tour, then sign in,
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
    return ListenableBuilder(
      listenable: OnboardingStore.instance,
      builder: (context, _) => ValueListenableBuilder<AuthPhase>(
        valueListenable: AuthService.instance.phase,
        builder: (context, phase, _) {
          if (!splashComplete) {
            return AyreSplashScreen(onFinished: onSplashComplete);
          }
          final store = OnboardingStore.instance;
          return switch (phase) {
            AuthPhase.initializing => AyreSplashScreen(
              onFinished: onSplashComplete,
            ),
            AuthPhase.unavailable => AuthUnavailableScreen(
              onRetry: () => unawaited(AuthService.instance.init()),
            ),
            // The flag is read during bootstrap, so this wait is normally
            // imperceptible; the plain canvas matches where the splash fades.
            AuthPhase.signedOut when !store.loaded => Scaffold(
              backgroundColor: context.tokens.background,
            ),
            AuthPhase.signedOut
                when shouldShowOnboarding(
                  phase: phase,
                  loaded: store.loaded,
                  completed: store.completed,
                ) =>
              OnboardingScreen(
                onFinished: ({required bool startTour}) {
                  // Only "Get started" offers the spotlight tutorial after
                  // sign-in; Skip leaves nothing pending.
                  if (startTour) unawaited(TourService.instance.markPending());
                  unawaited(store.markCompleted());
                },
              ),
            AuthPhase.signedOut => const LoginScreen(),
            AuthPhase.signedIn => HomeShell(),
          };
        },
      ),
    );
  }
}
