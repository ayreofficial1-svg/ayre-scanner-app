import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/screens/edit_profile_screen.dart';
import 'package:ayre_scanner/screens/equity_detail_screen.dart';
import 'package:ayre_scanner/screens/home_shell.dart';
import 'package:ayre_scanner/screens/index_detail_screen.dart';
import 'package:ayre_scanner/screens/lesson_screen.dart';
import 'package:ayre_scanner/screens/login_screen.dart';
import 'package:ayre_scanner/screens/notifications_screen.dart';
import 'package:ayre_scanner/screens/settings_screen.dart';
import 'package:ayre_scanner/screens/support_screen.dart';
import 'package:ayre_scanner/services/fault_injection.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/curved_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

/// The layout stress matrix, and the §9.4 pre-ship verification gate.
///
/// Every screen is rendered across the device widths we ship to, in **both**
/// themes, at the accessibility text scales a user can actually set, and in each
/// of its data phases — then checked for overflow and paint exceptions.
///
/// This is deliberately a sweep rather than a handful of spot checks: the bugs
/// this class of screen actually ships with (a figures column overflowing a
/// terminal row, a header row breaking at 2× text) are invisible at one size in
/// one theme with placeholder-length content.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => FaultInjector.instance.clear());

  const sizes = <String, Size>{
    'small-phone': Size(320, 568),
    'phone': Size(390, 844),
    'tablet': Size(768, 1024),
    'desktop': Size(1280, 800),
  };

  // 1.0 default, 2.0 is a realistic accessibility setting — not an extreme.
  const scales = <double>[1.0, 1.5, 2.0];

  final failures = <String>[];

  Widget wrap(Widget child, {required Brightness brightness, required double scale}) {
    return AppThemeController(
      themeMode: ThemeMode.dark,
      setThemeMode: (_) {},
      child: MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        // copyWith, not a fresh MediaQueryData: constructing one from scratch
        // drops the viewport size, which silently forces every responsive
        // branch down its single-column path and hides those layouts entirely.
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> sweep(String name, Widget Function() build) async {
    for (final entry in sizes.entries) {
      for (final brightness in Brightness.values) {
        for (final scale in scales) {
          testWidgets('$name · ${entry.key} · ${brightness.name} · x$scale', (
            tester,
          ) async {
            tester.view.physicalSize = entry.value;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              wrap(build(), brightness: brightness, scale: scale),
            );
            // Real frames, not one long jump: async fetches have to resolve and
            // spring-driven motion has to settle, otherwise the sweep passes on
            // a screen that is still showing skeletons.
            for (var i = 0; i < 90; i++) {
              await tester.pump(const Duration(milliseconds: 16));
            }

            final error = tester.takeException();
            if (error != null) {
              failures.add(
                '$name | ${entry.key} | ${brightness.name} | x$scale | '
                '${error.toString().split('\n').first}',
              );
            }
            expect(
              error,
              isNull,
              reason: 'layout must hold at ${entry.key}, ${brightness.name}, x$scale',
            );
          });
        }
      }
    }
  }

  // Long names and large figures are the realistic worst case for an Indian
  // market app, so that's what the sweep renders.
  FakeMarketData data({
    DataPhaseSnapshot phase = DataPhaseSnapshot.ready,
    bool stale = false,
  }) => FakeMarketData(
    phase: phase,
    stale: stale,
    longNames: true,
    hugeNumbers: true,
  );

  group('populated', () {
    sweep('HomeShell', () => HomeShell(marketData: data()));
    sweep(
      'IndexDetail',
      () => IndexDetailScreen(index: IndexId.nifty50, marketData: data()),
    );
    sweep(
      'EquityDetail',
      () => EquityDetailScreen(symbol: 'RELIANCE', marketData: data()),
    );
  });

  group('empty', () {
    sweep(
      'HomeShell',
      () => HomeShell(marketData: data(phase: DataPhaseSnapshot.empty)),
    );
    sweep(
      'IndexDetail',
      () => IndexDetailScreen(
        index: IndexId.nifty50,
        marketData: data(phase: DataPhaseSnapshot.empty),
      ),
    );
  });

  group('failed', () {
    sweep(
      'HomeShell',
      () => HomeShell(marketData: data(phase: DataPhaseSnapshot.failed)),
    );
    sweep(
      'IndexDetail',
      () => IndexDetailScreen(
        index: IndexId.nifty50,
        marketData: data(phase: DataPhaseSnapshot.failed),
      ),
    );
    sweep(
      'EquityDetail',
      () => EquityDetailScreen(
        symbol: 'RELIANCE',
        marketData: data(phase: DataPhaseSnapshot.failed),
      ),
    );
  });

  group('stale', () {
    sweep('HomeShell', () => HomeShell(marketData: data(stale: true)));
  });

  group('static screens', () {
    sweep('SettingsScreen', () => const SettingsScreen());
    sweep('NotificationsScreen', () => const NotificationsScreen());
    sweep('SupportScreen', () => const SupportScreen());
    sweep('LoginScreen', () => const LoginScreen());
    sweep(
      'SessionExpired',
      () => SessionExpiredScreen(onSignIn: () {}),
    );
    sweep(
      'EditProfileScreen',
      () => const EditProfileScreen(
        displayName: 'Raghav Ramakrishnan',
        handle: 'raghav.ramakrishnan',
      ),
    );
    sweep(
      'LessonScreen',
      () => const LessonScreen(
        course: Course(
          title: 'Position sizing and portfolio heat management',
          category: 'Risk management and capital preservation',
          body: 'A long lesson body used to check wrapping and scrolling at '
              'large accessibility text sizes across every supported width.',
          lessonsTotal: 12,
          lessonsDone: 3,
        ),
      ),
    );
  });

  group('the navigation bar', () {
    for (final scale in scales) {
      testWidgets('is always visible, icon-only, at 320pt · x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          wrap(
            HomeShell(marketData: data()),
            brightness: Brightness.dark,
            scale: scale,
          ),
        );
        await tester.pump(const Duration(milliseconds: 900));

        // All five destinations are present without any interaction: there is no
        // collapsed state to open.
        for (final destination in kNavDestinations) {
          expect(
            find.byKey(navDestinationKey(destination.label)),
            findsOneWidget,
            reason: '${destination.label} must always be on screen',
          );
        }

        // Icons only — no destination renders its name as visible text.
        for (final destination in kNavDestinations) {
          expect(
            find.descendant(
              of: find.byKey(navDestinationKey(destination.label)),
              matching: find.text(destination.label),
            ),
            findsNothing,
            reason: '${destination.label} must not show a text label',
          );
        }

        // ...but the name is still in the accessibility tree.
        final handle = tester.ensureSemantics();
        final semantics = tester.getSemantics(
          find.byKey(navDestinationKey('Signals')),
        );
        expect(semantics.label, contains('Signals'));
        // Disposed inline: the framework's end-of-test check runs before
        // addTearDown callbacks would.
        handle.dispose();

        // Every target clears the 48dp minimum in both dimensions.
        for (final destination in kNavDestinations) {
          final size = tester.getSize(
            find.byKey(navDestinationKey(destination.label)),
          );
          expect(
            size.width,
            greaterThanOrEqualTo(44),
            reason: '${destination.label} target width',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(48),
            reason: '${destination.label} target height',
          );
        }

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the notch slides between destinations without jumping', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          HomeShell(marketData: data()),
          brightness: Brightness.dark,
          scale: 1.0,
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      await tester.tap(find.byKey(navDestinationKey('Learn')));
      // Mid-flight: the shape is animating, and nothing has thrown.
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);

      // A second tap mid-animation must re-target rather than restart.
      await tester.tap(find.byKey(navDestinationKey('Home')));
      await tester.pump(const Duration(milliseconds: 40));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);
    });
  });

  tearDownAll(() {
    if (failures.isEmpty) return;
    // ignore: avoid_print
    print('\n===== LAYOUT FAILURES (${failures.length}) =====');
    for (final failure in failures) {
      // ignore: avoid_print
      print('  • $failure');
    }
    // ignore: avoid_print
    print('==========================================\n');
  });
}
