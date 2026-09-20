import 'package:ayre_scanner/screens/learn_tab.dart';
import 'package:ayre_scanner/services/market_data_service.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_components.dart';
import 'package:ayre_scanner/widgets/ayre_icons.dart';
import 'package:ayre_scanner/widgets/ayre_stat_tile.dart';
import 'package:ayre_scanner/widgets/pressable_scale.dart';
import 'package:ayre_scanner/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_market_data.dart';

/// Phase 5: the Learn tab — header, shared stat tiles, subject filter, calm
/// empty/failed states and footer card.
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
        child: Scaffold(body: child),
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

  const positionSizing = 'Position sizing and portfolio heat management';

  group('AyreStatTile', () {
    testWidgets('shows its figure over its label, with or without a glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: AyreStatTile(value: '12', label: 'Courses')),
                SizedBox(width: 12),
                Expanded(
                  child: AyreStatTile(
                    value: '3',
                    label: 'Alerts',
                    glyph: AyreGlyph.alerts,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      // Only the second tile carries a glyph.
      expect(find.byType(AyreIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scales down instead of overflowing at 2x on a small phone', (
      tester,
    ) async {
      useSize(tester, const Size(320, 568));
      await tester.pumpWidget(
        host(
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: AyreStatTile(value: '1,284', label: 'Subjects')),
                SizedBox(width: 12),
                Expanded(
                  child: AyreStatTile(
                    value: '98,765',
                    label: 'Courses completed',
                    glyph: AyreGlyph.course,
                  ),
                ),
              ],
            ),
          ),
          scale: 2.0,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Learn tab', () {
    testWidgets('stat tiles count the real subjects and courses', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(LearnTab(marketData: FakeMarketData())),
      );
      await settle(tester);

      final tiles = tester
          .widgetList<AyreStatTile>(find.byType(AyreStatTile))
          .toList();
      expect(tiles.map((t) => t.label), ['Subjects', 'Courses']);
      // The fake library has two courses in two subjects.
      expect(tiles.map((t) => t.value), ['2', '2']);
      expect(find.text('TRADING LIBRARY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the filter row is built from the feed and narrows the list', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(LearnTab(marketData: FakeMarketData())),
      );
      await settle(tester);

      // "All" plus one pill per subject in the library.
      expect(find.byType(AyreFilterChip), findsNWidgets(3));
      // The in-progress course shows on the continue card as well as its row.
      expect(find.text(positionSizing), findsNWidgets(2));
      expect(find.text('Reading market breadth'), findsOneWidget);

      await tester.tap(find.text('Market structure'));
      await settle(tester);
      expect(find.text(positionSizing), findsOneWidget); // continue card only
      expect(find.text('Reading market breadth'), findsOneWidget);

      await tester.tap(find.text('Risk management'));
      await settle(tester);
      expect(find.text('Reading market breadth'), findsNothing);
      expect(find.text(positionSizing), findsNWidgets(2));

      await tester.tap(find.text('All'));
      await settle(tester);
      expect(find.text('Reading market breadth'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a single subject offers nothing to filter', (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(LearnTab(marketData: _OneSubject())));
      await settle(tester);

      expect(find.byType(AyreFilterChip), findsNothing);
      expect(find.text('Reading market breadth'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty library shows the calm panel and its refresh works', (
      tester,
    ) async {
      useSize(tester, const Size(390, 844));
      final data = _CountingCourses(phase: DataPhaseSnapshot.empty);
      await tester.pumpWidget(host(LearnTab(marketData: data)));
      await settle(tester);

      expect(find.byType(CalmStatePanel), findsOneWidget);
      expect(find.text('No lessons yet'), findsOneWidget);
      // Nothing failed, so the counts are a true zero rather than a dash.
      final values = tester
          .widgetList<AyreStatTile>(find.byType(AyreStatTile))
          .map((t) => t.value);
      expect(values, ['0', '0']);
      // The footer card is static and is there whatever the library holds.
      expect(find.text('For learning, not advice'), findsOneWidget);
      expect(data.courseCalls, 1);

      await tester.tap(
        find.descendant(
          of: find.byType(CalmStatePanel),
          matching: find.byType(PressableScale),
        ),
      );
      await settle(tester);
      expect(data.courseCalls, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed library shows dashes, not zeros', (tester) async {
      useSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(
          LearnTab(
            marketData: FakeMarketData(phase: DataPhaseSnapshot.failed),
          ),
        ),
      );
      await settle(tester);

      expect(find.byType(CalmStatePanel), findsOneWidget);
      expect(find.text("Your library didn't load"), findsOneWidget);
      final values = tester
          .widgetList<AyreStatTile>(find.byType(AyreStatTile))
          .map((t) => t.value);
      expect(values, ['—', '—']);
      expect(tester.takeException(), isNull);
    });
  });

  // Single-column widths only: the two/three-column course grid is untouched
  // by this phase (it only receives the filtered list), and its fixed aspect
  // ratio is covered by the existing HomeShell sweeps.
  group('layout holds with many, long-named subjects', () {
    const sizes = <String, Size>{
      'small-phone': Size(320, 568),
      'phone': Size(390, 844),
    };
    for (final entry in sizes.entries) {
      for (final brightness in Brightness.values) {
        for (final scale in const [1.0, 2.0]) {
          testWidgets(
            '${entry.key} · ${brightness.name} · x$scale',
            (tester) async {
              useSize(tester, entry.value);
              await tester.pumpWidget(
                host(
                  LearnTab(marketData: _ManySubjects()),
                  brightness: brightness,
                  scale: scale,
                ),
              );
              await settle(tester);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}

/// Two courses sharing one subject.
class _OneSubject extends FakeMarketData {
  @override
  Future<DataResult<List<Course>>> getCourses() async {
    return DataResult.ready(const [
      Course(
        title: 'Reading market breadth',
        category: 'Market structure',
        body: 'Advances, declines, and what they tell you.',
      ),
      Course(
        title: 'Reading a volume profile',
        category: 'Market structure',
        body: 'Where the trading actually happened.',
      ),
    ]);
  }
}

/// Counts how many times the library was requested.
class _CountingCourses extends FakeMarketData {
  _CountingCourses({super.phase});

  int courseCalls = 0;

  @override
  Future<DataResult<List<Course>>> getCourses() {
    courseCalls++;
    return super.getCourses();
  }
}

/// Five subjects, several with names long enough to stress the pill row.
class _ManySubjects extends FakeMarketData {
  @override
  Future<DataResult<List<Course>>> getCourses() async {
    return DataResult.ready(const [
      Course(
        title: 'Position sizing and portfolio heat management',
        category: 'Risk management and capital preservation',
        body: 'How much to commit per setup.',
        lessonsTotal: 12,
        lessonsDone: 3,
      ),
      Course(
        title: 'Reading market breadth',
        category: 'Market structure',
        body: 'Advances, declines, and what they tell you.',
      ),
      Course(
        title: 'Candlestick basics',
        category: 'Technical analysis',
        body: '',
        lessonsTotal: 8,
        lessonsDone: 8,
      ),
      Course(
        title: 'Reading a balance sheet',
        category: 'Fundamental analysis',
        body: 'Assets, liabilities and what changed.',
      ),
      Course(
        title: 'Managing fear and greed',
        category: 'Trading psychology',
        body: 'Why sizing up after a win is a trap.',
      ),
    ]);
  }
}
