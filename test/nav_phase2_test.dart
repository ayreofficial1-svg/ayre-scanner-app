import 'dart:math' as math;

import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

double _lin(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _lum(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double _contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  Widget host(
    Widget child, {
    double scale = 1.0,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget dock({
    int selected = 0,
    ValueChanged<int>? onSelected,
    ValueChanged<int>? onReselected,
  }) => Scaffold(
    extendBody: true,
    body: const SizedBox.expand(),
    bottomNavigationBar: AyreBottomNav(
      selectedIndex: selected,
      onSelected: onSelected ?? (_) {},
      onReselected: onReselected,
    ),
  );

  group('labels never ellipsise', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('320 pt at x$scale', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(dock(), scale: scale));
        await tester.pump(const Duration(milliseconds: 300));

        for (final d in kNavDestinations) {
          final text = tester.widget<Text>(
            find.descendant(
              of: find.byKey(navDestinationKey(d.label)),
              matching: find.text(d.label),
            ),
          );
          expect(text.overflow, isNot(TextOverflow.ellipsis));
          expect(text.maxLines, 1);
          final size = tester.getSize(find.byKey(navDestinationKey(d.label)));
          expect(size.width, greaterThanOrEqualTo(44));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('one semantics node per item: label, hint, no duplicates', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(dock(selected: 1)));
    await tester.pump(const Duration(milliseconds: 300));

    for (var i = 0; i < kNavDestinations.length; i++) {
      final label = kNavDestinations[i].label;
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      final node = tester.getSemantics(find.byKey(navDestinationKey(label)));
      expect(node.label, label);
      expect(node.hint, 'Tab ${i + 1} of ${kNavDestinations.length}');
    }
    handle.dispose();
  });

  testWidgets('keyboard: Tab to an item and Enter activates it', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(host(dock(onSelected: selected.add)));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, [1]);
  });

  testWidgets('onReselected fires only for the selected item', (tester) async {
    final selected = <int>[];
    final reselected = <int>[];
    await tester.pumpWidget(
      host(dock(onSelected: selected.add, onReselected: reselected.add)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(navDestinationKey('Learn')));
    await tester.pump();
    expect(selected, [3]);
    expect(reselected, isEmpty);

    await tester.tap(find.byKey(navDestinationKey('Home')));
    await tester.pump();
    expect(reselected, [0]);
    expect(selected, [3]);
  });

  testWidgets('the dock is at most 480 pt wide at 600 pt', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(dock()));
    await tester.pump(const Duration(milliseconds: 300));

    final clip = find.descendant(
      of: find.byType(AyreBottomNav),
      matching: find.byType(ClipRRect),
    );
    expect(tester.getSize(clip.first).width, 480);
  });

  testWidgets('the rail scrolls at 844 x 390 and x2.0 without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        Scaffold(
          body: Row(
            children: [
              AyreNavRail(selectedIndex: 2, onSelected: (_) {}),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
        scale: 2.0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(AyreNavRail),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    for (final d in kNavDestinations) {
      expect(find.byKey(navDestinationKey(d.label)), findsOneWidget);
    }
  });

  group('contrast (plan §3.3 table)', () {
    final light = AppTheme.lightTokens;
    final dark = AppTheme.darkTokens;

    test('light', () {
      expect(_contrast(light.foregroundMuted, light.navBg), greaterThanOrEqualTo(4.5));
      expect(_contrast(light.accentInk, light.navBg), greaterThanOrEqualTo(4.5));
      expect(_contrast(light.accentInk, light.accentSoft), greaterThanOrEqualTo(3.0));
    });

    test('dark', () {
      expect(_contrast(dark.foregroundSubtle, dark.navBg), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.accentInk, dark.navBg), greaterThanOrEqualTo(4.5));
      expect(_contrast(dark.accentInk, dark.accentSoft), greaterThanOrEqualTo(3.0));
    });
  });
}
