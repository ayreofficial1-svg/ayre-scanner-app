import 'package:ayre_scanner/screens/equity_detail_screen.dart';
import 'package:ayre_scanner/screens/index_detail_screen.dart';
import 'package:ayre_scanner/screens/insights_tab.dart';
import 'package:ayre_scanner/services/fault_injection.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/services/persistent_market_data_service.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_charts.dart';
import 'package:ayre_scanner/widgets/figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

/// Phase 5: R-1 (Volatility / Momentum / Volume Surge removed from the app),
/// D-5 count-up, D-6 neutral change, chart semantics, A5 (no completion
/// haptic) and the index / equity detail headers.
void main() {
  Widget host(
    Widget child, {
    Brightness brightness = Brightness.dark,
    double scale = 1.0,
  }) => MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    ),
  );

  Widget insights(
    MarketDataService data, {
    Brightness brightness = Brightness.dark,
    double scale = 1.0,
  }) => host(
    Scaffold(body: InsightsTab(marketData: data)),
    brightness: brightness,
    scale: scale,
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('R-1: the three readings are gone', () {
    testWidgets('Insights shows only the movers and (when present) notes', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(insights(FakeMarketData()));
      await settle(tester);

      expect(find.text('Top gainers'), findsOneWidget);
      expect(find.text('Top losers'), findsOneWidget);
      expect(find.text('Most active'), findsOneWidget);

      final retired = RegExp(
        r'volatility|momentum|volume surge',
        caseSensitive: false,
      );
      expect(find.textContaining(retired), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desk notes still render after the three sections', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(insights(FakeMarketData()));
      await settle(tester);

      await tester.scrollUntilVisible(
        find.text('Desk notes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Desk notes'), findsOneWidget);
      expect(find.text('Financials carrying the tape'), findsOneWidget);
    });

    testWidgets('with no desk notes the page is just the three lists', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        insights(
          FakeMarketData(
            overrides: {DataSurface.insightNotes: DataPhaseSnapshot.failed},
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Desk notes'), findsNothing);
      expect(find.text('Most active'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('DataSurface has none of the three retired values', () {
      final names = DataSurface.values.map((s) => s.name).toSet();
      expect(names.contains('volatility'), isFalse);
      expect(names.contains('momentum'), isFalse);
      expect(names.contains('volumeSurge'), isFalse);
    });

    test('the three persisted cache entries are removed', () async {
      SharedPreferences.setMockInitialValues({
        'market_cache::volatility': '{}',
        'market_cache::momentum': '{}',
        'market_cache::volume_surge_15': '{}',
        'market_cache::volume_surge_30': '{}',
        'market_cache::gainers': '{"cachedAt":"x","data":[]}',
        'theme_mode': 'dark',
      });
      await PersistentMarketDataService.purgeRetiredCache();
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.containsKey('market_cache::volatility'), isFalse);
      expect(prefs.containsKey('market_cache::momentum'), isFalse);
      expect(prefs.containsKey('market_cache::volume_surge_15'), isFalse);
      expect(prefs.containsKey('market_cache::volume_surge_30'), isFalse);
      // Unrelated entries are untouched.
      expect(prefs.containsKey('market_cache::gainers'), isTrue);
      expect(prefs.containsKey('theme_mode'), isTrue);
    });

    testWidgets('one failed mover list does not affect the others', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        insights(
          FakeMarketData(
            overrides: {DataSurface.gainers: DataPhaseSnapshot.failed},
          ),
        ),
      );
      await settle(tester);

      expect(find.textContaining("Top Gainers didn't load"), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('HDFCLIFE'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('HDFCLIFE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('A5: no completion haptic after pull-to-refresh', () {
    testWidgets('Insights refresh makes no impact haptic', (tester) async {
      useSize(tester, const Size(390, 844));
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add('${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(insights(FakeMarketData()));
      await settle(tester);
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 400),
        1000,
      );
      await settle(tester);

      expect(haptics.where((h) => h.contains('mediumImpact')), isEmpty);
    });
  });

  group('D-5: count-up animates the first reveal only', () {
    testWidgets('a later value swaps instantly', (tester) async {
      Widget build(double v) => host(
        Scaffold(
          body: CountUpFigure(value: v, format: (x) => x.round().toString()),
        ),
      );

      await tester.pumpWidget(build(100));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('100'), findsOneWidget);

      await tester.pumpWidget(build(200));
      await tester.pump();
      expect(find.text('200'), findsOneWidget);
    });

    test('the count-up duration is within the 400 ms budget', () {
      expect(AppMotion.countUp.inMilliseconds, lessThanOrEqualTo(400));
      expect(AppMotion.chartDraw.inMilliseconds, lessThanOrEqualTo(700));
    });
  });

  group('D-6: a zero change is neutral', () {
    testWidgets('renders 0.00% in the muted tone with "unchanged" spoken', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const Scaffold(body: DeltaFigure(change: 0)),
          brightness: Brightness.light,
        ),
      );
      await tester.pump();

      expect(find.text('0.00%'), findsOneWidget);
      expect(find.text('+0.00%'), findsNothing);
      final text = tester.widget<Text>(find.text('0.00%'));
      expect(text.style?.color, AppTheme.lightTokens.foregroundMuted);
      expect(find.bySemanticsLabel('unchanged'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a value that rounds to zero is also neutral', (tester) async {
      await tester.pumpWidget(
        host(const Scaffold(body: DeltaFigure(change: 0.002))),
      );
      await tester.pump();
      expect(find.text('0.00%'), findsOneWidget);
    });

    testWidgets('null stays an em dash, never zero', (tester) async {
      await tester.pumpWidget(
        host(const Scaffold(body: DeltaFigure(change: null))),
      );
      await tester.pump();
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0.00%'), findsNothing);
    });

    testWidgets('gain and loss keep their sign', (tester) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Column(
              children: [DeltaFigure(change: 1.2), DeltaFigure(change: -1.2)],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('+1.20%'), findsOneWidget);
      expect(find.text('−1.20%'), findsOneWidget);
    });
  });

  group('chart semantics', () {
    testWidgets('BreadthDonut speaks one summary', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Center(
              child: BreadthDonut(advances: 268, declines: 194, unchanged: 38),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(
        find.bySemanticsLabel(RegExp('percent advancing: 268 up, 194 down')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('SentimentGauge speaks its score and band', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Center(child: SentimentGauge(score: 72, band: 'Bullish')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(
        find.bySemanticsLabel('Sentiment 72 out of 100, Bullish'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('Insights uses a two-column grid at 768', (tester) async {
      useSize(tester, const Size(768, 1024));
      await tester.pumpWidget(insights(FakeMarketData()));
      await settle(tester);

      expect(find.byType(GridView), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    for (final brightness in Brightness.values) {
      testWidgets('Insights has no overflow at 320 x 2.0 · ${brightness.name}', (
        tester,
      ) async {
        useSize(tester, const Size(320, 568));
        await tester.pumpWidget(
          insights(
            FakeMarketData(longNames: true),
            brightness: brightness,
            scale: 2.0,
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('index detail has no overflow at 320 x 2.0 · ${brightness.name}', (
        tester,
      ) async {
        useSize(tester, const Size(320, 568));
        await tester.pumpWidget(
          host(
            IndexDetailScreen(
              index: IndexId.nifty50,
              marketData: FakeMarketData(longNames: true, hugeNumbers: true),
            ),
            brightness: brightness,
            scale: 2.0,
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('equity detail has no overflow at 320 x 2.0 · ${brightness.name}', (
        tester,
      ) async {
        useSize(tester, const Size(320, 568));
        await tester.pumpWidget(
          host(
            EquityDetailScreen(
              symbol: 'RELIANCE',
              marketData: FakeMarketData(longNames: true, hugeNumbers: true),
            ),
            brightness: brightness,
            scale: 2.0,
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('detail headers', () {
    testWidgets('index detail shows an "As of" line', (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(
          IndexDetailScreen(
            index: IndexId.nifty50,
            marketData: FakeMarketData(),
          ),
        ),
      );
      await settle(tester);
      expect(find.textContaining('As of '), findsOneWidget);
    });

    testWidgets('the sort menu marks the active choice', (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(
          IndexDetailScreen(
            index: IndexId.nifty50,
            marketData: FakeMarketData(),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.byTooltip('Sort constituents'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Losers first'), findsOneWidget);
    });
  });
}
