import 'package:ayre_scanner/screens/insight_note_screen.dart';
import 'package:ayre_scanner/services/market_models.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_icons.dart';
import 'package:ayre_scanner/widgets/ayre_index_art.dart';
import 'package:ayre_scanner/widgets/ayre_insight_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3: the Market Insight carousel and the index-card identity art.
void main() {
  const notes = [
    InsightNote(
      title: 'Second note, not featured',
      body: 'Body of the second note.',
      category: 'Volume',
    ),
    InsightNote(
      title: 'Lead note, featured',
      body: 'Body of the lead note.',
      category: 'Breadth',
      featured: true,
    ),
    InsightNote(title: 'Third note, no body'),
  ];

  Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? AppTheme.dark,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  group('AyreInsightCarousel', () {
    testWidgets('leads with the featured note and shows 01/03', (tester) async {
      await tester.pumpWidget(
        host(AyreInsightCarousel(notes: notes, onReadMore: (_) {})),
      );
      await settle(tester);

      expect(find.text('01/03'), findsOneWidget);
      expect(find.text('BREADTH'), findsOneWidget);
      expect(find.text('Lead note, featured'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('next and previous wrap around', (tester) async {
      await tester.pumpWidget(
        host(AyreInsightCarousel(notes: notes, onReadMore: (_) {})),
      );
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('insight-next')));
      await settle(tester);
      expect(find.text('02/03'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('insight-prev')));
      await tester.tap(find.byKey(const ValueKey('insight-prev')));
      await settle(tester);
      expect(find.text('03/03'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Read more reports the current note', (tester) async {
      InsightNote? opened;
      await tester.pumpWidget(
        host(AyreInsightCarousel(notes: notes, onReadMore: (n) => opened = n)),
      );
      await settle(tester);

      await tester.tap(find.text('Read more').first);
      await settle(tester);
      expect(opened?.title, 'Lead note, featured');
    });

    testWidgets('a single note hides the pager', (tester) async {
      await tester.pumpWidget(
        host(AyreInsightCarousel(notes: [notes[1]], onReadMore: (_) {})),
      );
      await settle(tester);

      expect(find.byKey(const ValueKey('insight-next')), findsNothing);
      expect(find.text('01/01'), findsNothing);
    });

    testWidgets('holds in both themes at 2x text on a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AyreInsightCarousel(notes: notes, onReadMore: (_) {}),
              ),
            ),
            theme: theme,
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('InsightNoteScreen', () {
    testWidgets('shows the full note', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: InsightNoteScreen(note: notes[1]),
        ),
      );
      await settle(tester);

      expect(find.text('Lead note, featured'), findsOneWidget);
      expect(find.text('Body of the lead note.'), findsOneWidget);
      expect(find.text('BREADTH'), findsOneWidget);
    });
  });

  group('AyreIndexIdentity', () {
    testWidgets('each index resolves to its own tint, glyph and exchange', (
      tester,
    ) async {
      late AyreIndexIdentity nifty;
      late AyreIndexIdentity sensex;
      late AyreIndexIdentity bank;
      late AyreIndexIdentity unknown;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              nifty = AyreIndexIdentity.of(context, IndexId.nifty50);
              sensex = AyreIndexIdentity.of(context, IndexId.sensex);
              bank = AyreIndexIdentity.of(context, IndexId.bankNifty);
              unknown = AyreIndexIdentity.of(context, null);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(nifty.exchange, 'NSE');
      expect(sensex.exchange, 'BSE');
      expect(bank.exchange, 'NSE');
      expect(bank.glyph, AyreGlyph.bank);
      expect(unknown.exchange, isNull);

      // §2A light card backgrounds, and no two indices sharing a tint.
      expect(nifty.tint.cardBackground, const Color(0xFFE7F3E8));
      expect(sensex.tint.cardBackground, const Color(0xFFFBEAE4));
      expect(bank.tint.cardBackground, const Color(0xFFE6EEF7));
    });

    testWidgets('the flourish paints behind its child without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: AyreIndexFlourish(
              color: Color(0xFF4ED892),
              child: SizedBox(height: 60),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AyreIndexFlourish), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
