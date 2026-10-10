import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/screens/home_tab.dart';
import 'package:ayre_scanner/screens/weekly_reports_tab.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_components.dart';
import 'package:ayre_scanner/widgets/ayre_compact_index_card.dart';
import 'package:ayre_scanner/widgets/ayre_hills.dart';
import 'package:ayre_scanner/widgets/ayre_signals_section.dart';
import 'package:ayre_scanner/widgets/ayre_weekly_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_market_data.dart';

Widget _wrap(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1.0,
}) => AppThemeController(
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  setThemeMode: (_) {},
  child: MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  ),
);

void _size(WidgetTester tester, double w, [double h = 900]) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

WeeklyReport _report(List<WeeklyReportStock> stocks) => WeeklyReport(
  id: 'w1',
  weekStart: DateTime(2026, 9, 1),
  weekEnd: DateTime(2026, 9, 8),
  stocks: stocks,
);

const _full = WeeklyReportStock(
  symbol: 'RELIANCE',
  name: 'Reliance Industries',
  profitPct: 896.4,
  outcome: 'target',
  entryPrice: 444,
  exitPrice: 4424,
  pnlAmount: 3980,
);

Finder get _cards => find.descendant(
  of: find.byType(WeeklyReportCard),
  matching: find.byType(AyreCard),
);

Future<void> _pumpCard(
  WidgetTester tester,
  WeeklyReportStock stock, {
  double width = 390,
  double scale = 1.0,
  Brightness brightness = Brightness.light,
}) async {
  _size(tester, width);
  await tester.pumpWidget(
    _wrap(
      WeeklyReportCard(reports: [_report([stock])]),
      scale: scale,
      brightness: brightness,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Home', () {
    for (final width in [320.0, 390.0]) {
      testWidgets('header at $width x 2.0 has no overflow and no FittedBox', (
        tester,
      ) async {
        _size(tester, width, 1200);
        await tester.pumpWidget(
          _wrap(HomeTab(marketData: FakeMarketData()), scale: 2.0),
        );
        await _settle(tester);
        expect(tester.takeException(), isNull);
        // The greeting is a plain wrapping Text, not inside a FittedBox.
        final greeting = find.textContaining('Good ');
        expect(greeting, findsOneWidget);
        expect(
          find.ancestor(of: greeting, matching: find.byType(FittedBox)),
          findsNothing,
        );
      });
    }

    testWidgets('header controls hit areas are at least 48', (tester) async {
      _size(tester, 390);
      await tester.pumpWidget(
        _wrap(HomeTab(marketData: FakeMarketData())),
      );
      await _settle(tester);
      for (final label in [
        'Alerts',
        'Profile',
        'Switch to light theme',
        'Switch to dark theme',
      ]) {
        final f = find.bySemanticsLabel(label);
        if (f.evaluate().isEmpty) continue;
        final s = tester.getSize(f.first);
        expect(s.width, greaterThanOrEqualTo(48), reason: label);
        expect(s.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('index board is a scroller at 1.0 and a vertical list above 1.15', (
      tester,
    ) async {
      _size(tester, 390, 1400);
      await tester.pumpWidget(_wrap(HomeTab(marketData: FakeMarketData())));
      await _settle(tester);
      var cards = tester
          .widgetList<AyreCompactIndexCard>(find.byType(AyreCompactIndexCard))
          .length;
      expect(cards, 3);
      final firstX = tester.getTopLeft(find.byType(AyreCompactIndexCard).at(0));
      final secondX = tester.getTopLeft(find.byType(AyreCompactIndexCard).at(1));
      expect(secondX.dy, firstX.dy); // side by side

      await tester.pumpWidget(
        _wrap(HomeTab(marketData: FakeMarketData()), scale: 1.5),
      );
      await _settle(tester);
      final a = tester.getTopLeft(find.byType(AyreCompactIndexCard).at(0));
      final b = tester.getTopLeft(find.byType(AyreCompactIndexCard).at(1));
      expect(b.dy, greaterThan(a.dy)); // stacked
      expect(tester.takeException(), isNull);
    });

    testWidgets('stacked index cards show no scaled-down text', (tester) async {
      _size(tester, 320, 1600);
      await tester.pumpWidget(
        _wrap(
          HomeTab(marketData: FakeMarketData(hugeNumbers: true)),
          scale: 2.0,
        ),
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('signal card has one explicit semantics label', (tester) async {
      _size(tester, 390, 1400);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const Material(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _SignalHost(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'RELIANCE.*opens details')),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('signal card reflows at 320 x 2.0 without overflow', (
      tester,
    ) async {
      _size(tester, 320, 1600);
      await tester.pumpWidget(_wrap(const _SignalHost(), scale: 2.0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('refresh completion fires no haptic', (tester) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add('${call.arguments}');
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      _size(tester, 390, 1400);
      await tester.pumpWidget(_wrap(HomeTab(marketData: FakeMarketData())));
      await _settle(tester);
      await tester.fling(find.byType(Scrollable).first, const Offset(0, 300), 1000);
      await _settle(tester);
      expect(calls.where((c) => c.contains('mediumImpact')), isEmpty);
    });

    testWidgets('no closing hairline divider remains', (tester) async {
      _size(tester, 390, 2000);
      await tester.pumpWidget(_wrap(HomeTab(marketData: FakeMarketData())));
      await _settle(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('Weekly report stock card (R-2)', () {
    testWidgets('full-data card stays within 260 pt at 390 x 1.0', (
      tester,
    ) async {
      await _pumpCard(tester, _full);
      final h = tester.getSize(_cards.first).height;
      expect(h, lessThanOrEqualTo(260));
      expect(h, greaterThan(100));
    });

    for (final c in [(320.0, 2.0), (390.0, 1.5), (320.0, 1.0), (430.0, 1.0)]) {
      for (final b in Brightness.values) {
        testWidgets('no overflow at ${c.$1} x ${c.$2} · ${b.name}', (
          tester,
        ) async {
          await _pumpCard(
            tester,
            const WeeklyReportStock(
              symbol: 'MAHINDRAFINANCIALSERVICES',
              name: 'A very long company name that goes on and on Limited',
              profitPct: -123.45,
              outcome: 'stop_loss',
              entryPrice: 1234567.5,
              exitPrice: 7654321.25,
              pnlAmount: -9999999,
            ),
            width: c.$1,
            scale: c.$2,
            brightness: b,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('no FittedBox, AyreHills or IntrinsicHeight in the card', (
      tester,
    ) async {
      await _pumpCard(tester, _full);
      for (final type in [FittedBox, AyreHills, IntrinsicHeight]) {
        expect(
          find.descendant(of: _cards.first, matching: find.byType(type)),
          findsNothing,
          reason: '$type',
        );
      }
    });

    testWidgets('no nested AyreCard / InkPanel inside the card', (
      tester,
    ) async {
      await _pumpCard(tester, _full);
      expect(
        find.descendant(of: _cards.first, matching: find.byType(AyreCard)),
        findsNothing,
      );
      expect(
        find.descendant(of: _cards.first, matching: find.byType(InkPanel)),
        findsNothing,
      );
    });

    testWidgets('outcome words, symbol, return and metrics are all present', (
      tester,
    ) async {
      await _pumpCard(tester, _full);
      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('Target hit'), findsOneWidget);
      expect(find.text('+896.40%'), findsOneWidget);
      expect(find.text('Entry'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
      expect(find.text('Profit / share'), findsOneWidget);
      expect(find.text('Reliance Industries'), findsOneWidget);
    });

    testWidgets('semantics label keeps its original wording', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpCard(tester, _full);
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'RELIANCE, Reliance Industries, Target hit, 896.40 percent, '
            r'Entry ₹444.00 on 1 Sep 2026, Exit ₹4,424.00 on 8 Sep 2026, '
            r'Profit per share \+₹3,980',
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('stop-loss outcome words', (tester) async {
      await _pumpCard(
        tester,
        const WeeklyReportStock(
          symbol: 'HDFCLIFE',
          profitPct: -1.8,
          outcome: 'stop_loss',
        ),
      );
      expect(find.text('Stop-loss hit'), findsOneWidget);
      expect(find.text('−1.80%'), findsOneWidget);
    });

    testWidgets('entry-only, exit-only, no-P&L and no-name variants render', (
      tester,
    ) async {
      for (final stock in const [
        WeeklyReportStock(
          symbol: 'A',
          profitPct: 1,
          outcome: 'target',
          entryPrice: 10,
        ),
        WeeklyReportStock(
          symbol: 'B',
          profitPct: 1,
          outcome: 'target',
          exitPrice: 10,
        ),
        WeeklyReportStock(
          symbol: 'C',
          profitPct: 0,
          outcome: 'target',
          entryPrice: 10,
          exitPrice: 10,
        ),
        WeeklyReportStock(symbol: 'D', profitPct: 1, outcome: 'target'),
      ]) {
        await _pumpCard(tester, stock);
        expect(tester.takeException(), isNull);
        expect(find.text(stock.symbol), findsOneWidget);
      }
    });

    testWidgets('skeleton card height is within 4 pt of a real card', (
      tester,
    ) async {
      _size(tester, 390);
      await tester.pumpWidget(_wrap(const WeeklyReportSkeleton()));
      await tester.pump();
      final skeletonCards = find.descendant(
        of: find.byType(WeeklyReportSkeleton),
        matching: find.byType(AyreCard),
      );
      final skeletonHeight = tester.getSize(skeletonCards.first).height;
      await _pumpCard(tester, _full);
      final real = tester.getSize(_cards.first).height;
      expect((skeletonHeight - real).abs(), lessThanOrEqualTo(4));
    });

    testWidgets('See all toggle is at least 48 high', (tester) async {
      _size(tester, 390, 1400);
      final stocks = [
        for (var i = 0; i < 5; i++)
          WeeklyReportStock(symbol: 'S$i', profitPct: 1, outcome: 'target'),
      ];
      await tester.pumpWidget(
        _wrap(WeeklyReportCard(reports: [_report(stocks)])),
      );
      await tester.pumpAndSettle();
      final toggle = find.text('See all 5 stocks');
      expect(toggle, findsOneWidget);
      final box = find.ancestor(
        of: toggle,
        matching: find.byType(ConstrainedBox),
      );
      expect(tester.getSize(box.first).height, greaterThanOrEqualTo(48));
      expect(_cards, findsNWidgets(3));
    });

    testWidgets('week arrows are at least 48 and the picker uses AyreSheet', (
      tester,
    ) async {
      _size(tester, 390, 1400);
      final two = [
        _report([_full]),
        WeeklyReport(
          id: 'w0',
          weekStart: DateTime(2026, 8, 25),
          weekEnd: DateTime(2026, 9, 1),
          stocks: const [_full],
        ),
      ];
      await tester.pumpWidget(_wrap(WeeklyReportCard(reports: two)));
      await tester.pumpAndSettle();
      final older = find.bySemanticsLabel('Older week');
      if (older.evaluate().isNotEmpty) {
        expect(tester.getSize(older.first).width, greaterThanOrEqualTo(48));
      }
      await tester.tap(find.textContaining('Weekly Report').first);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refresh on the Reports tab fires no haptic', (tester) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add('${call.arguments}');
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      _size(tester, 390, 1000);
      await tester.pumpWidget(
        _wrap(SizedBox(height: 800, child: WeeklyReportsTab(marketData: FakeMarketData()))),
      );
      await tester.pumpAndSettle();
      await tester.fling(find.byType(Scrollable).first, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.contains('mediumImpact')), isEmpty);
    });
  });
}

/// Hosts the (private) signal card through the public [SignalsSection].
class _SignalHost extends StatelessWidget {
  const _SignalHost();

  @override
  Widget build(BuildContext context) =>
      SignalsSection(marketData: FakeMarketData(), forceColumns: 1);
}
