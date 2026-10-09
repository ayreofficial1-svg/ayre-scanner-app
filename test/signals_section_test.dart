import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_signals_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

Widget _host(Widget child) => AppThemeController(
  themeMode: ThemeMode.light,
  setThemeMode: (_) {},
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the Signals heading and one card per signal', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _host(
        SignalsSection(
          marketData: FakeMarketData(),
          onOpenEquity: (s) => opened.add(s.symbol),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RECOMMENDATIONS'), findsWidgets);
    final signals = (await FakeMarketData().getSignals()).value!;
    for (final s in signals) {
      expect(find.text(s.symbol), findsOneWidget);
    }

    await tester.tap(find.text(signals.first.symbol));
    expect(opened, [signals.first.symbol]);
  });

  testWidgets('failed state keeps the existing copy', (tester) async {
    await tester.pumpWidget(
      _host(
        SignalsSection(
          marketData: FakeMarketData(phase: DataPhaseSnapshot.failed),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("The scanner couldn't refresh"), findsOneWidget);
  });

  testWidgets('empty state keeps the existing copy', (tester) async {
    await tester.pumpWidget(
      _host(
        SignalsSection(
          marketData: FakeMarketData(phase: DataPhaseSnapshot.empty),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No fresh setups right now'), findsOneWidget);
  });

  testWidgets('controller reload is safe before mount and after dispose', (
    tester,
  ) async {
    final controller = SignalsSectionController();
    await controller.reload();

    await tester.pumpWidget(
      _host(
        SignalsSection(marketData: FakeMarketData(), controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await controller.reload(silent: true);
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(const SizedBox()));
    await controller.reload();
  });

  testWidgets('does not load until first active', (tester) async {
    Widget build(bool active) => _host(
      SignalsSection(marketData: FakeMarketData(), active: active),
    );
    await tester.pumpWidget(build(false));
    await tester.pump();
    expect(find.text('RELIANCE'), findsNothing);

    await tester.pumpWidget(build(true));
    await tester.pumpAndSettle();
    expect(find.text('RELIANCE'), findsOneWidget);
  });
}
