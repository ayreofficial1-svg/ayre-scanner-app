import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/screens/edit_profile_screen.dart';
import 'package:ayre_scanner/screens/home_shell.dart';
import 'package:ayre_scanner/screens/lesson_screen.dart';
import 'package:ayre_scanner/screens/login_screen.dart';
import 'package:ayre_scanner/screens/notifications_screen.dart';
import 'package:ayre_scanner/screens/settings_screen.dart';
import 'package:ayre_scanner/screens/splash_screen.dart';
import 'package:ayre_scanner/screens/support_screen.dart';
import 'package:ayre_scanner/services/market_movers_service.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/app_states.dart';
import 'package:ayre_scanner/widgets/instrument_marks.dart';
import 'package:ayre_scanner/widgets/market_movers_section.dart';
import 'package:ayre_scanner/widgets/numeral.dart';
import 'package:ayre_scanner/widgets/premium_widgets.dart';
import 'package:ayre_scanner/widgets/sentiment_gauge.dart';
import 'package:ayre_scanner/widgets/spring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// These pump the redesigned surfaces in both themes so a paint or layout
/// assertion shows up here rather than on a device. Custom painters and the
/// gauge/sparkline/needle work are the parts static analysis can't check.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Mirrors the real app: the theme controller sits above MaterialApp, so any
  /// screen that reads it (Settings' appearance selector) finds it here too.
  Widget app(Widget child, {Brightness? mode, ThemeMode themeMode = ThemeMode.dark}) {
    return AppThemeController(
      themeMode: themeMode,
      setThemeMode: (_) {},
      child: MaterialApp(
        theme: mode == Brightness.light ? AppTheme.light : AppTheme.dark,
        home: child,
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget child, {Brightness? mode}) async {
    await tester.pumpWidget(app(child, mode: mode));
    await tester.pumpAndSettle();
  }

  group('instrument drawing', () {
    for (final brightness in Brightness.values) {
      testWidgets('sentiment gauge paints and sweeps (${brightness.name})', (
        tester,
      ) async {
        await pump(
          tester,
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: GaugeHousing(
                child: SentimentGauge(value: 18, label: 'Caution'),
              ),
            ),
          ),
          mode: brightness,
        );
        expect(find.byType(SentimentGauge), findsOneWidget);

        // Re-target mid-flight: the needle should follow without throwing.
        await pump(
          tester,
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: GaugeHousing(
                child: SentimentGauge(value: 91, label: 'Strong'),
              ),
            ),
          ),
          mode: brightness,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sparkline morphs to a new trace', (tester) async {
      await pump(
        tester,
        const Scaffold(body: Sparkline(points: [0.1, 0.4, 0.2, 0.8])),
      );
      await pump(
        tester,
        const Scaffold(body: Sparkline(points: [0.9, 0.3, 0.7, 0.2])),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('engraved marks and the chamfer voice paint', (tester) async {
      await pump(
        tester,
        Scaffold(
          body: Column(
            children: [
              const SizedBox(
                height: 12,
                child: TickMarks(color: Colors.black, count: 40),
              ),
              const SizedBox(
                height: 60,
                child: ContourLines(color: Colors.black),
              ),
              const BearingMark(color: Colors.black, size: 80),
              Material(
                shape: const ChamferedBorder(
                  side: BorderSide(),
                  corners: {ChamferCorner.topRight, ChamferCorner.bottomLeft},
                ),
                child: const SizedBox(height: 40, width: 120),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('numerals', () {
    testWidgets('a changed value rolls to its new reading', (tester) async {
      await pump(
        tester,
        Scaffold(
          body: Numeral(
            '10.00',
            value: 10,
            format: (v) => v.toStringAsFixed(2),
          ),
        ),
      );
      expect(find.text('10.00'), findsOneWidget);

      await pump(
        tester,
        Scaffold(
          body: Numeral(
            '20.00',
            value: 20,
            format: (v) => v.toStringAsFixed(2),
          ),
        ),
      );
      expect(find.text('20.00'), findsOneWidget);
    });

    testWidgets('a delta shows sign, glyph and color together', (tester) async {
      await pump(
        tester,
        const Scaffold(body: DeltaFigure(change: -2.5, roll: false)),
      );
      expect(find.text('−2.50%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });
  });

  group('market mover sections', () {
    MarketMover row(String symbol, num pct) => MarketMover(
      symbol: symbol,
      companyName: '$symbol Industries Limited',
      lastPrice: 1234.5,
      change: pct * 12,
      percentChange: pct,
      asOf: DateTime(2026, 8, 29, 15, 31),
      volumeOrValue: 12500000,
    );

    testWidgets('loading shows shape-matched skeletons', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: MarketMoversSection(
            title: 'Top gainers',
            result: null,
            loading: true,
          ),
        ),
      );
      expect(find.byType(SkeletonRow), findsWidgets);
    });

    testWidgets('rows render with every figure in the readout face', (
      tester,
    ) async {
      await pump(
        tester,
        Scaffold(
          body: MarketMoversSection(
            title: 'Most active equities',
            showVolume: true,
            loading: false,
            result: MarketMoversResult.data([row('AYRE', 4.2), row('SCAN', 1.1)]),
          ),
        ),
      );
      expect(find.text('AYRE'), findsOneWidget);
      expect(find.text('1,234.50'), findsNWidgets(2));
      expect(find.text('1.3Cr'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a stale section keeps its values and flags the delay', (
      tester,
    ) async {
      await pump(
        tester,
        Scaffold(
          body: MarketMoversSection(
            title: 'Top losers',
            loading: false,
            result: MarketMoversResult.data([row('AYRE', -3.0)], stale: true),
          ),
        ),
      );
      expect(find.text('AYRE'), findsOneWidget);
      expect(find.text('Data may be delayed'), findsOneWidget);
    });

    testWidgets('a failed section scopes its error and stays calm', (
      tester,
    ) async {
      await pump(
        tester,
        const Scaffold(
          body: MarketMoversSection(
            title: 'Top gainers',
            loading: false,
            result: MarketMoversResult.failure(),
          ),
        ),
      );
      expect(find.text('Could not load this list'), findsOneWidget);
    });

    testWidgets('an empty section uses the shared template', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: MarketMoversSection(
            title: 'Top gainers',
            loading: false,
            result: MarketMoversResult.data([]),
            emptyMessage: 'Nothing yet.',
          ),
        ),
      );
      expect(find.byType(AppStateMessage), findsOneWidget);
      expect(find.text('Nothing yet.'), findsOneWidget);
    });
  });

  group('pushed screens', () {
    testWidgets('settings renders its three real sections', (tester) async {
      await pump(tester, const SettingsScreen());
      expect(find.text('In-app alerts'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      // No inert controls: the retired placeholder rows must not be back.
      expect(find.text('Price Alerts'), findsNothing);
      expect(find.text('Weekly Digest'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edit profile disables Save until a field changes', (
      tester,
    ) async {
      await pump(
        tester,
        const EditProfileScreen(displayName: 'Raghav', handle: 'raghav'),
      );
      TextButton save() => tester.widget<TextButton>(
        find.ancestor(of: find.text('Save'), matching: find.byType(TextButton)),
      );
      expect(save().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Raghav S');
      await tester.pumpAndSettle();
      expect(save().onPressed, isNotNull);
    });

    testWidgets('an untouched alerts list shows the empty state', (
      tester,
    ) async {
      await pump(tester, const NotificationsScreen());
      expect(find.text('Nothing recorded yet'), findsOneWidget);
    });

    testWidgets('support, lesson, login and splash all render', (tester) async {
      await pump(tester, const SupportScreen());
      expect(find.text(kSupportAddress), findsOneWidget);

      await pump(
        tester,
        const LessonScreen(
          title: 'Position sizing',
          eyebrow: 'Risk',
          body: 'How much to commit per setup.',
          icon: Icons.shield_outlined,
        ),
      );
      expect(find.text('Position sizing'), findsOneWidget);

      await pump(tester, const LoginScreen());
      expect(find.text('Welcome back'), findsOneWidget);

      await tester.pumpWidget(app(AyreSplashScreen(onFinished: () {})));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ayre Scanner'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });

  group('shell and navigation', () {
    // flutter_test answers every HTTP request with an empty 400, so the tabs
    // land in their error/empty states — which is exactly what we want to
    // render here: the calm templates plus the rebuilt nav bar.
    testWidgets('five peer tabs, and switching preserves each tab', (
      tester,
    ) async {
      await tester.pumpWidget(app(const HomeShell()));
      await tester.pumpAndSettle();

      // Inactive segments are icon-only by design, so the semantics label is
      // the addressable handle — which is also what a screen reader gets.
      for (final label in ['Signals', 'Insights', 'Learn', 'Profile', 'Home']) {
        await tester.tap(find.byKey(navSegmentKey(label)), warnIfMissed: false);
        await tester.pumpAndSettle();
        // Selecting a segment reveals its label beside the icon.
        expect(find.text(label), findsWidgets, reason: '$label label revealed');
        expect(tester.takeException(), isNull);
      }

      // Profile is a real tab, not a modal: going back to it shows its own
      // content, still built, with no modal sheet involved.
      await tester.tap(find.byKey(navSegmentKey('Profile')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.byType(NavAvatar), findsWidgets);
    });

    testWidgets('a wide viewport swaps the bottom bar for a side rail', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(const HomeShell()));
      await tester.pumpAndSettle();

      // Every label is visible at once on the rail, unlike the bottom bar.
      for (final label in ['Home', 'Signals', 'Insights', 'Learn', 'Profile']) {
        expect(find.text(label), findsWidgets, reason: '$label on the rail');
      }
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the live-data pulse plays once and leaves no residue', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        body: LiveDataPulse(trigger: 1, child: SizedBox(height: 80, width: 80)),
      ),
    );
    await pump(
      tester,
      const Scaffold(
        body: LiveDataPulse(trigger: 2, child: SizedBox(height: 80, width: 80)),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion collapses animated readings to a snap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: app(
          const Scaffold(body: SentimentGauge(value: 70, label: 'Strong')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
