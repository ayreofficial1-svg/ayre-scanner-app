import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/onboarding/onboarding_content.dart';
import 'package:ayre_scanner/screens/onboarding_screen.dart';
import 'package:ayre_scanner/screens/settings_screen.dart';
import 'package:ayre_scanner/screens/support_screen.dart';
import 'package:ayre_scanner/services/onboarding_store.dart';
import 'package:ayre_scanner/services/tour_service.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget home) => AppThemeController(
  themeMode: ThemeMode.light,
  setThemeMode: (_) {},
  child: MaterialApp(theme: AppTheme.light, home: home),
);

/// A first route that pushes [SupportScreen], so `popUntil(isFirst)` has a
/// real shell-like root to return to.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SupportScreen())),
        child: const Text('open support'),
      ),
    ),
  );
}

Future<void> _openSupport(WidgetTester tester) async {
  await tester.pumpWidget(_host(const _Root()));
  await tester.tap(find.text('open support'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Support lists the three tutorial rows', (tester) async {
    await _openSupport(tester);
    expect(find.text('App tutorial'), findsOneWidget);
    expect(find.text('Profile tutorial'), findsOneWidget);
    expect(find.text('Settings tutorial'), findsOneWidget);
    // TEMPORARY (testing): remove with the replay row.
    expect(find.text('Replay onboarding'), findsOneWidget);
  });

  testWidgets('Settings no longer has tutorial rows', (tester) async {
    await tester.pumpWidget(_host(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Help and tutorials'), findsNothing);
    expect(find.text('App tutorial'), findsNothing);
    expect(find.text('Settings tutorial'), findsNothing);
  });

  testWidgets('App tutorial bumps the request and returns to the root', (
    tester,
  ) async {
    await _openSupport(tester);
    final before = TourService.instance.appTourRequests.value;
    await tester.tap(find.text('App tutorial'));
    await tester.pumpAndSettle();
    expect(TourService.instance.appTourRequests.value, before + 1);
    expect(find.byType(SupportScreen), findsNothing);
    expect(find.text('open support'), findsOneWidget);
  });

  testWidgets('Profile tutorial bumps its request and returns to the root', (
    tester,
  ) async {
    await _openSupport(tester);
    final before = TourService.instance.profileTourRequests.value;
    await tester.tap(find.text('Profile tutorial'));
    await tester.pumpAndSettle();
    expect(TourService.instance.profileTourRequests.value, before + 1);
    expect(find.byType(SupportScreen), findsNothing);
  });

  testWidgets('Settings tutorial opens Settings', (tester) async {
    await _openSupport(tester);
    await tester.tap(find.text('Settings tutorial'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });

  // TEMPORARY (testing): delete these cases with the replay row.
  testWidgets('Replay onboarding: Skip pops without touching the store', (
    tester,
  ) async {
    await _openSupport(tester);
    final store = OnboardingStore.forTest();
    final before = TourService.instance.appTourRequests.value;

    await tester.tap(find.text('Replay onboarding'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text(OnboardingLabels.skip));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(SupportScreen), findsOneWidget);
    expect(store.completed, isFalse);
    expect(TourService.instance.appTourRequests.value, before);
  });

  testWidgets('Replay onboarding: Get started requests the app tutorial', (
    tester,
  ) async {
    await _openSupport(tester);
    final before = TourService.instance.appTourRequests.value;

    await tester.tap(find.text('Replay onboarding'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingLabels.next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(OnboardingLabels.getStarted));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(TourService.instance.appTourRequests.value, before + 1);
    expect(find.text('open support'), findsOneWidget);
  });
}
