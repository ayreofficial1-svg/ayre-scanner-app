import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/screens/weekly_reports_tab.dart';
import 'package:ayre_scanner/services/fault_injection.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_weekly_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

Widget _host(Widget child) => AppThemeController(
  themeMode: ThemeMode.light,
  setThemeMode: (_) {},
  child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => FaultInjector.instance.clear());

  testWidgets('ready: shows the Weekly Report card', (tester) async {
    await tester.pumpWidget(
      _host(WeeklyReportsTab(marketData: FakeMarketData())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyReportCard), findsOneWidget);
    expect(find.text('Weekly Report'), findsOneWidget);
  });

  testWidgets('loading: shows the skeleton before data lands', (tester) async {
    await tester.pumpWidget(
      _host(WeeklyReportsTab(marketData: FakeMarketData())),
    );
    expect(find.byType(WeeklyReportSkeleton), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyReportSkeleton), findsNothing);
  });

  testWidgets('failed: shows the failed panel', (tester) async {
    await tester.pumpWidget(
      _host(
        WeeklyReportsTab(
          marketData: FakeMarketData(phase: DataPhaseSnapshot.failed),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Weekly report didn't load"), findsOneWidget);
    expect(find.byType(WeeklyReportCard), findsNothing);
  });

  testWidgets('empty: shows an explicit empty state', (tester) async {
    await tester.pumpWidget(
      _host(
        WeeklyReportsTab(
          marketData: FakeMarketData(phase: DataPhaseSnapshot.empty),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No weekly reports yet'), findsOneWidget);
  });

  testWidgets('inactive tab does not load until selected', (tester) async {
    Widget build(bool active) => _host(
      WeeklyReportsTab(marketData: FakeMarketData(), active: active),
    );
    await tester.pumpWidget(build(false));
    await tester.pump();
    expect(find.byType(WeeklyReportCard), findsNothing);

    await tester.pumpWidget(build(true));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyReportCard), findsOneWidget);
  });
}
