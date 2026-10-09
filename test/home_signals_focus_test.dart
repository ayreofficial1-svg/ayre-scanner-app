import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/screens/home_tab.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

Widget _host(FakeMarketData data, int token) => AppThemeController(
  themeMode: ThemeMode.light,
  setThemeMode: (_) {},
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: HomeTab(marketData: data, signalsFocusToken: token)),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

double _pixels(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical)
          .first,
    )
    .position
    .pixels;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a changed signalsFocusToken scrolls Signals into view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final data = FakeMarketData();
    await tester.pumpWidget(_host(data, 0));
    await _settle(tester);
    expect(_pixels(tester), 0);

    await tester.pumpWidget(_host(data, 1));
    await _settle(tester);
    expect(_pixels(tester), greaterThan(0));
  });

  testWidgets('bumping the token again is harmless', (tester) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final data = FakeMarketData();
    await tester.pumpWidget(_host(data, 0));
    await _settle(tester);
    for (final token in [1, 2, 3]) {
      await tester.pumpWidget(_host(data, token));
      await _settle(tester);
    }
    expect(tester.takeException(), isNull);
    expect(_pixels(tester), greaterThan(0));
  });

  testWidgets('a token set at first build (cold-start tap) focuses Signals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(FakeMarketData(), 1));
    await _settle(tester);
    expect(_pixels(tester), greaterThan(0));
  });

  testWidgets('without a token Home stays at the top', (tester) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(FakeMarketData(), 0));
    await _settle(tester);
    expect(_pixels(tester), 0);
  });
}
