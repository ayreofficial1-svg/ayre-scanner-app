import 'package:ayre_scanner/screens/insights_tab.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_charts.dart';
import 'package:ayre_scanner/widgets/ayre_components.dart';
import 'package:ayre_scanner/widgets/ayre_instrument_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_market_data.dart';

/// Phase 4: the Insights tab — movers row grammar, the "See all" control, and
/// the section-heading "i" explanations.
void main() {
  final at = DateTime(2026, 9, 18, 15, 31);

  Widget host(
    MarketDataService data, {
    Brightness brightness = Brightness.dark,
    double scale = 1.0,
  }) => MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: InsightsTab(marketData: data)),
      ),
    ),
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

  group('AyreInstrumentTile.monogram', () {
    test('takes up to two letters or digits, upper-cased', () {
      expect(AyreInstrumentTile.monogram('RELIANCE'), 'RE');
      expect(AyreInstrumentTile.monogram('m&m'), 'MM');
      expect(AyreInstrumentTile.monogram('BAJAJ-AUTO'), 'BA');
      expect(AyreInstrumentTile.monogram('X'), 'X');
    });

    test('is never blank', () {
      expect(AyreInstrumentTile.monogram(''), '—');
      expect(AyreInstrumentTile.monogram('&-'), '—');
    });
  });

  group('sections', () {
    testWidgets('the Market Sentiment section is gone', (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(FakeMarketData()));
      await settle(tester);

      expect(find.byType(SentimentGauge), findsNothing);
      expect(find.text('MARKET SENTIMENT'), findsNothing);
      expect(find.text('How the market feels'), findsNothing);
      // The desk now opens straight on the first movers list.
      expect(find.text('TOP GAINERS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a heading\'s "i" icon opens a plain explanation', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(FakeMarketData()));
      await settle(tester);

      // Top gainers is the first section, so its icon is the first one.
      expect(find.byType(SectionInfoButton), findsWidgets);
      await tester.tap(find.byType(SectionInfoButton).first);
      await settle(tester);

      expect(
        find.textContaining('gone up the most today'),
        findsOneWidget,
      );

      await tester.tap(find.text('Got it'));
      await settle(tester);
      expect(find.textContaining('gone up the most today'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('movers lists', () {
    testWidgets('"See all" appears past five rows and expands in place', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(_ManyGainers(at)));
      await settle(tester);

      // Collapsed to five rows. Losers and Most active have fewer than six, so
      // only the gainers list offers the control.
      expect(find.text('GAIN5'), findsOneWidget);
      expect(find.text('GAIN6'), findsNothing);
      expect(find.text('See all'), findsOneWidget);

      await tester.ensureVisible(find.text('See all'));
      await tester.tap(find.text('See all'));
      await settle(tester);

      expect(find.text('GAIN8'), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);
      expect(find.text('See all'), findsNothing);

      await tester.tap(find.text('Show less'));
      await settle(tester);

      expect(find.text('GAIN6'), findsNothing);
      expect(find.text('See all'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short list offers no "See all"', (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(FakeMarketData()));
      await settle(tester);

      expect(find.text('See all'), findsNothing);
    });

    testWidgets('every row leads with its instrument tile', (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(_ManyGainers(at)));
      await settle(tester);

      // At least the five collapsed gainers, each with its monogram ("GA" for
      // every GAINn).
      expect(find.byType(AyreInstrumentTile), findsAtLeastNWidgets(5));
      expect(find.text('GA'), findsAtLeastNWidgets(5));
    });
  });

  group('layout holds with an expandable list', () {
    const sizes = <String, Size>{
      'small-phone': Size(320, 568),
      'phone': Size(390, 844),
      'tablet': Size(768, 1024),
    };
    for (final entry in sizes.entries) {
      for (final brightness in Brightness.values) {
        for (final scale in const [1.0, 2.0]) {
          testWidgets(
            '${entry.key} · ${brightness.name} · x$scale',
            (tester) async {
              useSize(tester, entry.value);
              await tester.pumpWidget(
                host(_ManyGainers(at), brightness: brightness, scale: scale),
              );
              await settle(tester);
              expect(tester.takeException(), isNull);

              await tester.scrollUntilVisible(
                find.text('See all'),
                300,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.tap(find.text('See all'));
              await settle(tester);

              expect(find.text('GAIN8'), findsOneWidget);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}

/// Eight gainers — more than the five a collapsed list shows.
class _ManyGainers extends FakeMarketData {
  _ManyGainers(this._at);

  final DateTime _at;

  @override
  Future<DataResult<List<Quote>>> getTopGainers() async {
    return DataResult.ready([
      for (var i = 1; i <= 8; i++)
        Quote(
          symbol: 'GAIN$i',
          name: 'GAIN$i',
          lastPrice: 1000.0 + i,
          change: 10.0 - i,
          percentChange: 10.0 - i,
          asOf: _at,
        ),
    ]);
  }
}
