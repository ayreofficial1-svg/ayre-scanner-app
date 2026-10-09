import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/screens/home_tab.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_compact_index_card.dart';
import 'package:ayre_scanner/widgets/ayre_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

Widget _wrap(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1.0,
}) {
  return AppThemeController(
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    setThemeMode: (_) {},
    child: MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the three indices in order: Nifty 50, Bank Nifty, Sensex', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final data = FakeMarketData();
    await tester.pumpWidget(_wrap(HomeTab(marketData: data)));
    await _settle(tester);

    final cards = tester
        .widgetList<AyreCompactIndexCard>(find.byType(AyreCompactIndexCard))
        .toList();
    expect(cards.map((c) => c.indexId), [
      IndexId.nifty50,
      IndexId.bankNifty,
      IndexId.sensex,
    ]);
    final board = (await data.getIndexBoard()).value!;
    expect(cards.map((c) => c.quote.name), board.map((q) => q.name));
  });

  testWidgets('a live feed shows the live dot; a stale feed does not', (
    tester,
  ) async {
    final quote = (await FakeMarketData().getIndexBoard()).value!.first;

    Widget card(bool stale) => _wrap(
      Center(
        child: SizedBox(
          width: 160,
          height: 104,
          child: AyreCompactIndexCard(
            quote: quote,
            indexId: IndexId.nifty50,
            stale: stale,
            onTap: () {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(card(false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LivePulseDot), findsOneWidget);

    await tester.pumpWidget(card(true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LivePulseDot), findsNothing);
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    final quote = (await FakeMarketData().getIndexBoard()).value!.first;
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        Center(
          child: SizedBox(
            width: 160,
            height: 104,
            child: AyreCompactIndexCard(
              quote: quote,
              indexId: IndexId.nifty50,
              stale: false,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(AyreCompactIndexCard));
    await tester.pump();
    expect(taps, 1);
  });

  // Overflow sweep: Home's index row at the widths and text scales we ship to,
  // in both themes, with five-figure levels.
  const widths = <double>[320, 390, 768];
  const scales = <double>[1.0, 1.3, 2.0];
  for (final width in widths) {
    for (final brightness in Brightness.values) {
      for (final scale in scales) {
        testWidgets(
          'index row has no overflow · ${width.toInt()} · ${brightness.name} · x$scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              _wrap(
                HomeTab(marketData: FakeMarketData(hugeNumbers: true)),
                brightness: brightness,
                scale: scale,
              ),
            );
            await _settle(tester);

            expect(find.byType(AyreCompactIndexCard), findsWidgets);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('loading shows three skeleton cards', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(HomeTab(marketData: FakeMarketData())));
    await tester.pump();
    expect(find.byType(AyreCompactIndexCardSkeleton), findsNWidgets(3));
    await _settle(tester);
    expect(find.byType(AyreCompactIndexCardSkeleton), findsNothing);
  });
}
