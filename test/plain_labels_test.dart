import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_charts.dart';
import 'package:ayre_scanner/widgets/ayre_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the plain-label options: the breadth donut without its centre
/// caption or legend counts, and the section heading with a description.
void main() {
  Widget host(Widget child) => AppThemeController(
    themeMode: ThemeMode.dark,
    setThemeMode: (_) {},
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('BreadthDonut', () {
    testWidgets('keeps its caption and legend counts by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const BreadthDonut(advances: 60, declines: 30, unchanged: 10)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADVANCING'), findsOneWidget);
      expect(find.text('Up'), findsOneWidget);
      expect(find.text('Down'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('can hide the caption and the legend counts', (tester) async {
      await tester.pumpWidget(
        host(
          const BreadthDonut(
            advances: 60,
            declines: 30,
            unchanged: 10,
            centerLabel: null,
            showLegendCounts: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADVANCING'), findsNothing);
      // The coloured indicators and their labels stay.
      expect(find.text('Up'), findsOneWidget);
      expect(find.text('Down'), findsOneWidget);
      expect(find.text('Flat'), findsOneWidget);
      // The counts beside them are gone.
      expect(find.text('60'), findsNothing);
      expect(find.text('30'), findsNothing);
      expect(find.text('10'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('SectionLabel', () {
    testWidgets('shows a description under the heading when given one', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SectionLabel(
            label: 'Top gainers',
            subtitle: 'Stocks rising the most',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOP GAINERS'), findsOneWidget);
      expect(find.text('Stocks rising the most'), findsOneWidget);

      final heading = tester.getBottomLeft(find.text('TOP GAINERS')).dy;
      final description = tester.getTopLeft(
        find.text('Stocks rising the most'),
      ).dy;
      expect(description, greaterThanOrEqualTo(heading));
    });

    testWidgets('looks the same as before without a description', (
      tester,
    ) async {
      await tester.pumpWidget(host(const SectionLabel(label: 'Library')));
      await tester.pumpAndSettle();

      expect(find.text('LIBRARY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
