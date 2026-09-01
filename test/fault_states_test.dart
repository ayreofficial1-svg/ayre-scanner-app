import 'package:ayre_scanner/screens/equity_detail_screen.dart';
import 'package:ayre_scanner/screens/home_shell.dart';
import 'package:ayre_scanner/screens/index_detail_screen.dart';
import 'package:ayre_scanner/services/fault_injection.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_icons.dart';
import 'package:ayre_scanner/widgets/curved_nav_bar.dart';
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
      expect(icon.color, isNot(tokens.loss));
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

      // Switch to the Insights desk, where the movers live. The bar is always
      // visible now, so a destination is one tap away with nothing to open.
      await tester.tap(find.byKey(navDestinationKey('Insights')));
      await settle(tester);

      // The sentiment reading is at the top of the desk and unaffected.
      expect(find.text('71'), findsOneWidget);
      expect(find.textContaining("Top Gainers didn't load"), findsOneWidget);

      // The desk is a long feed, so the lower sections are built as they scroll
      // into view rather than all at once.
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await settle(tester);
      expect(find.textContaining("Top Losers didn't load"), findsOneWidget);

      // Most Active was never told to fail, and didn't.
      expect(find.textContaining("Most Active didn't load"), findsNothing);
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

  group('§9 coverage — every listed surface, every phase', () {
    // The brief names the surfaces that must be checked against their
    // failure/empty paths rather than assumed to work because DataResult exists.
    // This walks each one through both phases and confirms the right panel
    // appears, with no exception and no technical copy.
    final surfaces = <String, DataSurface>{
      'index board': DataSurface.indexBoard,
      'sentiment': DataSurface.sentiment,
      'gainers': DataSurface.gainers,
      'losers': DataSurface.losers,
      'most active': DataSurface.mostActive,
      'signals': DataSurface.signals,
      'courses': DataSurface.courses,
    };

    for (final entry in surfaces.entries) {
      for (final phase in [DataPhaseSnapshot.failed, DataPhaseSnapshot.empty]) {
        testWidgets('${entry.key} · ${phase.name}', (tester) async {
          await tester.pumpWidget(
            app(
              HomeShell(
                marketData: FakeMarketData(overrides: {entry.value: phase}),
              ),
            ),
          );
          await settle(tester);

          // Walk every tab so each surface actually gets built.
          for (final destination in ['Signals', 'Insights', 'Learn', 'Home']) {
            await tester.tap(find.byKey(navDestinationKey(destination)));
            await settle(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} ${phase.name} broke the $destination tab',
            );
          }
        });
      }
    }

    testWidgets('index and equity detail render both phases', (tester) async {
      for (final phase in [DataPhaseSnapshot.failed, DataPhaseSnapshot.empty]) {
        await tester.pumpWidget(
          app(
            IndexDetailScreen(
              index: IndexId.sensex,
              marketData: FakeMarketData(phase: phase),
            ),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'index ${phase.name}');

        await tester.pumpWidget(
          app(
            EquityDetailScreen(
              symbol: 'HDFCBANK',
              marketData: FakeMarketData(phase: phase),
            ),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'equity ${phase.name}');
      }
    });

    testWidgets('every fault kind is renderable end to end', (tester) async {
      // Timeout is excluded here only because it deliberately never resolves
      // inside the test's own clock; it is exercised by the injector unit tests.
      for (final kind in FaultKind.values.where(
        (k) => k != FaultKind.timeout,
      )) {
        FaultInjector.instance.enabled = true;
        FaultInjector.instance.setAll(kind);

        await tester.pumpWidget(
          app(HomeShell(marketData: FakeMarketData())),
        );
        await settle(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: '${kind.name} must render a designed state, not throw',
        );

        FaultInjector.instance.clear();
        FaultInjector.instance.enabled = false;
      }
    });
  });
}
