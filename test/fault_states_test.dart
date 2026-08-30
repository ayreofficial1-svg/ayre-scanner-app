import 'package:ayre_scanner/screens/equity_detail_screen.dart';
import 'package:ayre_scanner/screens/home_shell.dart';
import 'package:ayre_scanner/screens/index_detail_screen.dart';
import 'package:ayre_scanner/services/fault_injection.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_icons.dart';
import 'package:ayre_scanner/widgets/fold_nav.dart';
import 'package:ayre_scanner/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

/// §9.3 / §9.4 — every failure condition is triggered deliberately and the
/// resulting UI is inspected, rather than designed on paper and assumed.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    FaultInjector.instance.clear();
    FaultInjector.instance.enabled = false;
  });

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: child,
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  group('the injector', () {
    test('exposes all seven conditions the brief requires', () {
      expect(FaultKind.values, hasLength(7));
      for (final required in [
        FaultKind.apiError,
        FaultKind.emptyResponse,
        FaultKind.malformed,
        FaultKind.networkFailure,
        FaultKind.timeout,
        FaultKind.staleData,
        FaultKind.sessionExpired,
      ]) {
        expect(FaultKind.values, contains(required));
      }
    });

    test('covers every independently-failing surface', () {
      // One entry per section that must be able to fail on its own.
      for (final required in [
        DataSurface.indexBoard,
        DataSurface.indexDetail,
        DataSurface.indexConstituents,
        DataSurface.equityDetail,
        DataSurface.signals,
        DataSurface.sentiment,
        DataSurface.gainers,
        DataSurface.losers,
        DataSurface.mostActive,
        DataSurface.courses,
      ]) {
        expect(DataSurface.values, contains(required));
      }
    });

    test('is inert until explicitly enabled', () {
      FaultInjector.instance.set(DataSurface.signals, FaultKind.apiError);
      expect(FaultInjector.instance.enabled, isFalse);
      expect(FaultInjector.instance.faultFor(DataSurface.signals), isNull);

      FaultInjector.instance.enabled = true;
      expect(
        FaultInjector.instance.faultFor(DataSurface.signals),
        FaultKind.apiError,
      );
    });

    test('a session failure is the one condition that changes behaviour', () {
      expect(const DataFailure.session().requiresReauth, isTrue);
      for (final other in [
        const DataFailure.api(statusCode: 500),
        const DataFailure.offline(),
        const DataFailure.timeout(),
        const DataFailure.malformed(),
      ]) {
        expect(other.requiresReauth, isFalse);
      }
    });

    test('a failure never surfaces a status code to the user', () {
      // The taxonomy carries the code for logging; nothing user-facing reads it.
      const failure = DataFailure.api(statusCode: 503);
      expect(failure.statusCode, 503);
      expect(failure.message, isNull);
    });
  });

  group('empty and failed are visually distinct', () {
    testWidgets('empty uses the calm glyph, failed uses the broken one', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: Column(
              children: [
                StatePanel.empty(headline: 'Nothing here', message: 'Calm.'),
                StatePanel.failed(headline: 'Broke', message: 'Not calm.'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final glyphs = tester
          .widgetList<AyreIcon>(find.byType(AyreIcon))
          .map((icon) => icon.glyph)
          .toList();

      expect(glyphs, contains(AyreGlyph.empty));
      expect(glyphs, contains(AyreGlyph.disconnected));
      // The distinction has to survive without reading the copy.
      expect(AyreGlyph.empty, isNot(AyreGlyph.disconnected));
    });

    testWidgets('a failure is never dominated by the loss colour', (
      tester,
    ) async {
      // Red means "the market went down", never "the app broke".
      late AppThemeTokens tokens;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              tokens = context.tokens;
              return const Scaffold(
                body: StatePanel.failed(
                  headline: 'Feed unavailable',
                  message: 'Pull down to try again.',
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      final icon = tester.widget<AyreIcon>(find.byType(AyreIcon));
      expect(icon.color, isNot(tokens.garnet));
      expect(icon.color, tokens.textSecondary);
    });
  });

  group('per-surface independence', () {
    testWidgets('a failed movers list leaves the sentiment reading alone', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          HomeShell(
            marketData: FakeMarketData(
              overrides: const {
                DataSurface.gainers: DataPhaseSnapshot.failed,
                DataSurface.losers: DataPhaseSnapshot.failed,
              },
            ),
          ),
        ),
      );
      await settle(tester);

      // Switch to the Insights desk, where the movers live.
      await tester.tap(find.byKey(kFoldTriggerKey));
      await settle(tester);
      await tester.tap(find.byKey(foldDestinationKey('Insights')));
      await settle(tester);

      expect(find.textContaining("Top Gainers didn't load"), findsOneWidget);
      expect(find.textContaining("Top Losers didn't load"), findsOneWidget);
      // Most Active and the sentiment reading are untouched.
      expect(find.textContaining("Most Active didn't load"), findsNothing);
      expect(find.text('71'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('constituents can fail while the index reading succeeds', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          IndexDetailScreen(
            index: IndexId.nifty50,
            marketData: FakeMarketData(
              overrides: const {
                DataSurface.indexConstituents: DataPhaseSnapshot.failed,
              },
            ),
          ),
        ),
      );
      await settle(tester);

      expect(
        find.textContaining("Couldn't load the constituent list"),
        findsOneWidget,
      );
      // The header still shows its reading, and says so.
      expect(
        find.textContaining('The index reading above is still current'),
        findsOneWidget,
      );
      expect(find.text('NIFTY 50'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a stale section keeps its values and flags the delay', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(HomeShell(marketData: FakeMarketData(stale: true))),
      );
      await settle(tester);

      expect(find.text('DELAYED'), findsWidgets);
      // Degraded-but-shown: the level is still on screen.
      expect(find.text('24,518.40'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('pushed screens get an explicit retry', () {
    testWidgets('equity detail offers Retry, not a pull-down hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          EquityDetailScreen(
            symbol: 'RELIANCE',
            marketData: FakeMarketData(phase: DataPhaseSnapshot.failed),
          ),
        ),
      );
      await settle(tester);

      expect(
        find.textContaining("This company's data didn't come through"),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Pull down to try again'), findsNothing);
    });

    testWidgets('a partial failure keeps the values it already had', (
      tester,
    ) async {
      final seed = Quote(
        symbol: 'RELIANCE',
        name: 'Reliance',
        lastPrice: 2984.55,
        change: 53.9,
        percentChange: 1.84,
        asOf: DateTime(2026, 8, 30, 15, 31),
      );
      await tester.pumpWidget(
        app(
          EquityDetailScreen(
            symbol: 'RELIANCE',
            marketData: FakeMarketData(phase: DataPhaseSnapshot.failed),
            seed: seed,
          ),
        ),
      );
      await settle(tester);

      // The tapped row's price is still visible, with an honest note about the
      // refresh rather than a blank screen.
      expect(find.text('2,984.55'), findsOneWidget);
      expect(
        find.textContaining("Couldn't refresh this company"),
        findsOneWidget,
      );
    });
  });

  group('copy discipline', () {
    testWidgets('no raw exception text or status code reaches the UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(HomeShell(marketData: FakeMarketData(phase: DataPhaseSnapshot.failed))),
      );
      await settle(tester);

      for (final banned in [
        'Exception',
        'DataFailure',
        'null',
        '503',
        '500',
        '401',
        'Something went wrong',
        'Error:',
      ]) {
        expect(
          find.textContaining(banned),
          findsNothing,
          reason: '"$banned" must never appear in shipped copy',
        );
      }
    });
  });
}
