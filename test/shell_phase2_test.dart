import 'package:ayre_scanner/screens/home_shell.dart';
import 'package:ayre_scanner/screens/home_tab.dart';
import 'package:ayre_scanner/screens/learn_tab.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

/// A1-A3: per-tab navigators, Android Back order, re-tap.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomeShell(marketData: FakeMarketData()),
      ),
    );
    await settle(tester);
  }

  /// Pushes a marker screen on the navigator of the tab that holds [tab].
  Future<void> pushDetail(WidgetTester tester, Finder tab, String text) async {
    final nav = Navigator.of(tester.element(tab));
    nav.push(
      terminalRoute<void>(
        builder: (_) => Scaffold(body: Center(child: Text(text))),
      ),
    );
    await settle(tester);
  }

  int selectedIndex(WidgetTester tester) =>
      tester.widget<AyreBottomNav>(find.byType(AyreBottomNav)).selectedIndex;

  testWidgets('the dock stays visible on an in-tab detail screen', (
    tester,
  ) async {
    await pumpShell(tester);
    await pushDetail(tester, find.byType(HomeTab), 'DETAIL-HOME');

    expect(find.text('DETAIL-HOME'), findsOneWidget);
    for (final d in kNavDestinations) {
      expect(find.byKey(navDestinationKey(d.label)), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('each tab keeps its own stack while another is shown', (
    tester,
  ) async {
    await pumpShell(tester);
    await pushDetail(tester, find.byType(HomeTab), 'DETAIL-HOME');

    await tester.tap(find.byKey(navDestinationKey('Learn')));
    await settle(tester);
    expect(selectedIndex(tester), 3);

    await tester.tap(find.byKey(navDestinationKey('Home')));
    await settle(tester);
    expect(find.text('DETAIL-HOME'), findsOneWidget);
  });

  testWidgets('re-tapping the active tab pops it to its root', (tester) async {
    await pumpShell(tester);
    await pushDetail(tester, find.byType(HomeTab), 'DETAIL-HOME');

    await tester.tap(find.byKey(navDestinationKey('Home')));
    await settle(tester);

    expect(find.text('DETAIL-HOME'), findsNothing);
    expect(selectedIndex(tester), 0);
  });

  testWidgets('Android Back: detail, then Home, then exit', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpShell(tester);

    // Profile (root of its stack) -> Home.
    await tester.tap(find.byKey(navDestinationKey('Profile')));
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(selectedIndex(tester), 0);
    expect(calls, isNot(contains('SystemNavigator.pop')));

    // A detail on Home is unwound first.
    await pushDetail(tester, find.byType(HomeTab), 'DETAIL-HOME');
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('DETAIL-HOME'), findsNothing);
    expect(selectedIndex(tester), 0);
    expect(calls, isNot(contains('SystemNavigator.pop')));

    // Home at its root: Back leaves the app.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('Back from a detail in another tab unwinds it, then Home', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.byKey(navDestinationKey('Learn')));
    await settle(tester);
    await pushDetail(tester, find.byType(LearnTab), 'DETAIL-LEARN');
    expect(find.text('DETAIL-LEARN'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('DETAIL-LEARN'), findsNothing);
    expect(selectedIndex(tester), 3);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(selectedIndex(tester), 0);
  });
}
