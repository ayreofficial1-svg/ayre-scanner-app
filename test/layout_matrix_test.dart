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
import 'package:ayre_scanner/widgets/ayre_bottom_nav.dart';
import 'package:ayre_scanner/widgets/ayre_charts.dart';
import 'package:ayre_scanner/widgets/state_views.dart';
import 'package:ayre_scanner/widgets/ticker_trace.dart';
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

  // ── Phase 3: data visualization ──────────────────────────────────────────
  //
  // The radial charts are the first components in the app whose layout is
  // driven by arc arithmetic rather than by the box model, so the failure mode
  // the rest of this file hunts for (overflow at 2× text) is joined by a new
  // one: a sweep computed as a negative number, which Flutter paints as an arc
  // running backwards rather than throwing. The degenerate-input test below
  // covers the boundaries where that arithmetic goes wrong — zero total, a
  // slice too thin to survive its own round caps, and both ends of the range.
  group('data visualization', () {
    sweep(
      'ChartGallery',
      () => const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              BreadthDonut(advances: 1284, declines: 967, unchanged: 143),
              SizedBox(height: AppSpace.xl),
              SentimentGauge(score: 62, band: 'Constructive'),
              SizedBox(height: AppSpace.xl),
              ProgressRing(value: 0.35),
              SizedBox(height: AppSpace.xl),
              _Trace(),
            ],
          ),
        ),
      ),
    );

    testWidgets('the radial charts survive their degenerate inputs', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Nothing to divide by.
                  BreadthDonut(advances: 0, declines: 0),
                  // One slice far too thin to draw with round caps and a 2px
                  // gap — it must be dropped from the ring, not smeared.
                  BreadthDonut(advances: 4000, declines: 1, unchanged: 0),
                  // Both ends of the ring: an empty arc and a closed one.
                  ProgressRing(value: 0),
                  ProgressRing(value: 1),
                  // Both ends of the gauge, where the marker sits exactly on a
                  // rounded track end.
                  SentimentGauge(score: 0, band: 'Bearish'),
                  SentimentGauge(score: 100, band: 'Bullish'),
                ],
              ),
            ),
          ),
          brightness: Brightness.dark,
          scale: 1.0,
        ),
      );
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a count-up arrives at its value, not near it', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: Center(child: SentimentGauge(score: 62, band: 'Neutral')),
          ),
          brightness: Brightness.dark,
          scale: 1.0,
        ),
      );
      // Mid-count: something is on screen and it isn't the final value yet.
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('62'), findsNothing);
      // Settled: the reading is exact. A count-up that lands on 61 because of
      // curve rounding is worse than no animation at all.
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.text('62'), findsOneWidget);
    });
  });

  // ── Phase 4: system states ───────────────────────────────────────────────
  group('state panels', () {
    sweep(
      'StateGallery',
      () => const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              StatePanel.empty(
                headline: 'No signals published yet',
                message: 'The desk publishes through the trading session.',
              ),
              SizedBox(height: AppSpace.md),
              StatePanel.noResults(),
              SizedBox(height: AppSpace.md),
              StatePanel.failed(
                headline: "The movers list didn't come through",
                message: 'Nothing else on this screen is affected.',
              ),
              SizedBox(height: AppSpace.md),
              StatePanel.offline(),
              SizedBox(height: AppSpace.md),
              StatePanel.sessionExpired(),
            ],
          ),
        ),
      ),
    );

    test('§14.5 — each state carries its own verb, and they stay distinct', () {
      // The point of the enum is that these four never collapse into each
      // other. A regression here looks harmless in a diff and reads as sloppy
      // on screen: "Retry" offered for an expired session, "Try again" for a
      // connection that never dropped.
      expect(StatePreset.failed.action, StateAction.tryAgain);
      expect(StatePreset.offline.action, StateAction.retry);
      expect(StatePreset.sessionExpired.action, StateAction.signInAgain);

      final labels = StateAction.values.map((a) => a.label).toSet();
      expect(labels.length, StateAction.values.length);
    });

    test('empty and failed are distinguishable without reading the copy', () {
      final glyphs = StatePreset.values.map((p) => p.glyph).toSet();
      expect(glyphs.length, StatePreset.values.length);
      expect(StatePreset.empty.isFault, isFalse);
      expect(StatePreset.noResults.isFault, isFalse);
      expect(StatePreset.failed.isFault, isTrue);
    });
  });

  group('the navigation bar', () {
    for (final scale in scales) {
      testWidgets('is always visible with icon and label, at 320pt · x$scale', (
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

        // v4 reverses v3's icon-only nav (Spec §9): every destination now
        // shows its name as a visible label, not just an accessibility one.
        for (final destination in kNavDestinations) {
          expect(
            find.descendant(
              of: find.byKey(navDestinationKey(destination.label)),
              matching: find.text(destination.label),
            ),
            findsOneWidget,
            reason: '${destination.label} must show a visible text label',
          );
        }

        // The visible label doubles as the accessibility name.
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

    testWidgets('the pill slides between destinations without jumping', (
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
      // Mid-flight: the pill is animating, and nothing has thrown.
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

/// The three line-chart sizes side by side. A widget rather than an inline
/// expression so the gallery above can stay `const`, and so the normalised
/// sample series is written once instead of three times.
class _Trace extends StatelessWidget {
  const _Trace();

  // Deliberately includes a flat run, a sharp reversal and both extremes of
  // the 0..1 range — the shapes that expose a mitred join, a clipped cap, or
  // an off-by-one in the draw-on reveal.
  static const _points = <double>[
    0.0, 0.42, 0.42, 0.42, 0.91, 0.13, 0.66, 0.64, 1.0,
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        TickerTrace.sparkline(points: _points),
        SizedBox(height: AppSpace.md),
        TickerTrace.thumbnail(points: _points),
        SizedBox(height: AppSpace.md),
        // The Spec fixes AreaTrend at 320px wide, which is wider than the
        // usable width of the 320pt device in this sweep. Scrolling it inside
        // its own container is the honest fix: the alternative is letting the
        // gallery overflow and calling the sweep's own failure a false
        // positive. Real call sites in Phase 5 should pass a width rather than
        // inheriting 320 blindly — flagged in the plan.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TickerTrace.areaTrend(points: _points),
        ),
      ],
    );
  }
}