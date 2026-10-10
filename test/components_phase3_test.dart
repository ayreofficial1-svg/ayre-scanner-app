import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_components.dart';
import 'package:ayre_scanner/widgets/ayre_icons.dart';
import 'package:ayre_scanner/widgets/ayre_sheet.dart';
import 'package:ayre_scanner/widgets/figure.dart';
import 'package:ayre_scanner/widgets/pressable_scale.dart';
import 'package:ayre_scanner/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3: shared components obey the type floors, 48 pt targets, the
/// elevation ladder, sentence-case section headers, reduce-motion and the
/// A4 status-text tokens.
void main() {
  Widget host(
    Widget child, {
    Brightness brightness = Brightness.light,
    double textScale = 1.0,
    bool reduceMotion = false,
  }) => MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(320, 640),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  void size(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('SectionLabel', () {
    testWidgets('renders sentence case, not uppercase', (tester) async {
      await tester.pumpWidget(host(const SectionLabel(label: 'Top gainers')));
      expect(find.text('Top gainers'), findsOneWidget);
      expect(find.text('TOP GAINERS'), findsNothing);
      final style = tester.widget<Text>(find.text('Top gainers')).style!;
      expect(style.fontSize, AppTextScale.sectionHeading);
    });

    testWidgets('info button has a 48 pt target', (tester) async {
      await tester.pumpWidget(
        host(const SectionLabel(label: 'Breadth', info: 'Explains breadth.')),
      );
      final box = find.bySemanticsLabel('About Breadth');
      expect(box, findsOneWidget);
      final s = tester.getSize(box);
      expect(s.width, greaterThanOrEqualTo(48));
      expect(s.height, greaterThanOrEqualTo(48));
    });

    testWidgets('info opens the shared AyreSheet', (tester) async {
      await tester.pumpWidget(
        host(const SectionLabel(label: 'Breadth', info: 'Explains breadth.')),
      );
      await tester.tap(find.bySemanticsLabel('About Breadth'));
      await tester.pumpAndSettle();
      expect(find.byType(AyreSheet), findsOneWidget);
      expect(find.text('Explains breadth.'), findsOneWidget);
    });
  });

  group('AyreCard elevation', () {
    BoxDecoration decorationOf(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AyreCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return box.decoration as BoxDecoration;
    }

    testWidgets('flat by default', (tester) async {
      await tester.pumpWidget(host(const AyreCard(child: Text('x'))));
      expect(decorationOf(tester).boxShadow, isEmpty);
    });

    testWidgets('tappable and featured cards are raised in light', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AyreCard(onTap: () {}, child: const Text('x'))),
      );
      expect(decorationOf(tester).boxShadow, hasLength(1));
      await tester.pumpWidget(
        host(const AyreCard(featured: true, child: Text('x'))),
      );
      expect(decorationOf(tester).boxShadow, hasLength(1));
    });

    testWidgets('dark theme never uses a shadow', (tester) async {
      await tester.pumpWidget(
        host(
          AyreCard(onTap: () {}, child: const Text('x')),
          brightness: Brightness.dark,
        ),
      );
      expect(decorationOf(tester).boxShadow, isEmpty);
    });
  });

  group('minimum targets', () {
    testWidgets('AyreSwitch is at least 48x48', (tester) async {
      await tester.pumpWidget(
        host(
          Center(
            child: AyreSwitch(
              value: false,
              onChanged: (_) {},
              semanticLabel: 'Alerts',
            ),
          ),
        ),
      );
      final s = tester.getSize(find.byType(AyreSwitch));
      expect(s.width, greaterThanOrEqualTo(48));
      expect(s.height, greaterThanOrEqualTo(48));
    });

    testWidgets('AyreSwitch toggles on tap', (tester) async {
      var v = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => AyreSwitch(
              value: v,
              onChanged: (n) => set(() => v = n),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AyreSwitch));
      await tester.pump();
      expect(v, isTrue);
    });

    testWidgets('segments and filter chips are at least 48 high', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              AyreSegmented<int>(
                compact: true,
                segments: const [
                  AyreSegment(value: 0, label: 'Day'),
                  AyreSegment(value: 1, label: 'Week'),
                ],
                value: 0,
                onChanged: (_) {},
              ),
              AyreFilterChip(label: 'All', selected: true, onTap: () {}),
              AyreFilterChip(label: 'Equity', selected: false, onTap: () {}),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AyreFilterChip).first).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(AyreFilterChip).last).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(AyreSegmented<int>)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('selected filter chip shows more than colour', (tester) async {
      await tester.pumpWidget(
        host(AyreFilterChip(label: 'All', selected: true, onTap: () {})),
      );
      final text = tester.widget<Text>(find.text('All'));
      expect(text.style!.fontWeight, FontWeight.w700);
      expect(find.byType(CustomPaint), findsWidgets); // the check glyph
    });

    testWidgets('SettingRow with onTap is at least 48 high', (tester) async {
      await tester.pumpWidget(
        host(
          SettingRow(
            glyph: AyreGlyph.about,
            title: 'About',
            onTap: () {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(SettingRow)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('OfflineBanner dismiss target is at least 48x48', (
      tester,
    ) async {
      await tester.pumpWidget(host(OfflineBanner(onDismiss: () {})));
      final s = tester.getSize(find.bySemanticsLabel('Dismiss offline notice'));
      expect(s.width, greaterThanOrEqualTo(48));
      expect(s.height, greaterThanOrEqualTo(48));
    });
  });

  group('type floors', () {
    testWidgets('chips and badges are 11 sp or larger, never 10', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              AyreChip(label: 'Live', tone: ChipTone.live),
              AyreChip(label: 'Closed'),
              TagPill(label: 'Markets'),
              DirectionBadge(up: true, label: 'Up'),
            ],
          ),
        ),
      );
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        expect(w.style!.fontSize, greaterThanOrEqualTo(11));
      }
    });
  });

  group('A4 status text', () {
    testWidgets('DeltaFigure uses the status-text tokens in light', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              DeltaFigure(change: 1.2),
              DeltaFigure(change: -1.2),
            ],
          ),
        ),
      );
      final tokens = AppTheme.lightTokens;
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.first.style!.color, tokens.positiveText);
      expect(texts.last.style!.color, tokens.negativeText);
    });

    testWidgets('chips and badges colour text with the status-text tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              AyreChip(label: 'Live', tone: ChipTone.live),
              AyreChip(label: 'Heads up', tone: ChipTone.attention),
              DirectionBadge(up: false, label: 'Down'),
            ],
          ),
        ),
      );
      final tokens = AppTheme.lightTokens;
      Color colorOf(String s) =>
          tester.widget<Text>(find.text(s.toUpperCase())).style!.color!;
      expect(colorOf('Live'), tokens.positiveText);
      expect(colorOf('Heads up'), tokens.neutralText);
      expect(colorOf('Down'), tokens.negativeText);
    });
  });

  group('state panels', () {
    testWidgets('every preset has its own glyph', (tester) async {
      final glyphs = StatePreset.values.map((p) => p.glyph).toSet();
      expect(glyphs.length, StatePreset.values.length);
    });

    testWidgets('stale and permanent are calm / faulted correctly', (
      tester,
    ) async {
      expect(StatePreset.stale.isFault, isFalse);
      expect(StatePreset.permanent.isFault, isTrue);
      expect(StatePreset.stale.action, StateAction.refreshNow);
    });

    for (final textScale in [1.0, 2.0]) {
      testWidgets('all variants render without overflow at 320 x $textScale', (
        tester,
      ) async {
        size(tester, const Size(320, 568));
        await tester.pumpWidget(
          host(
            Column(
              children: [
                const StatePanel.empty(
                  headline: 'Nothing yet',
                  message: 'Check back later.',
                ),
                const StatePanel.noResults(),
                StatePanel.failed(
                  headline: 'Could not load',
                  message: 'Something went wrong.',
                  onRetry: () {},
                ),
                StatePanel.offline(onRetry: () {}),
                StatePanel.sessionExpired(onRetry: () {}),
                const StatePanel.stale(),
                const StatePanel.permanent(
                  headline: 'Unavailable',
                  message: 'This section is not available.',
                ),
                const CalmStatePanel.empty(
                  headline: 'Empty',
                  message: 'Nothing to show.',
                ),
                OfflineBanner(onDismiss: () {}),
                FreshnessStamp(asOf: DateTime(2026, 1, 1, 9, 30)),
              ],
            ),
            textScale: textScale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('reduce motion', () {
    testWidgets('Entrance renders its child immediately', (tester) async {
      await tester.pumpWidget(
        host(
          const Entrance(index: 3, child: Text('hello')),
          reduceMotion: true,
        ),
      );
      expect(find.text('hello'), findsOneWidget);
      final opacity = find.ancestor(
        of: find.text('hello'),
        matching: find.byType(Opacity),
      );
      expect(opacity, findsNothing);
    });

    testWidgets('skeleton is static under reduce-motion', (tester) async {
      await tester.pumpWidget(
        host(const SkeletonBlock(width: 40), reduceMotion: true),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('PressableScale does not scale under reduce-motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          PressableScale(onTap: () {}, child: const SizedBox(width: 80, height: 60)),
          reduceMotion: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableScale)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, 1);
      await gesture.up();
    });
  });
}
