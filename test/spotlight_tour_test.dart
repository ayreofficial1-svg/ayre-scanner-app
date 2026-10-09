import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/spotlight_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const keyA = ValueKey<String>('spot-a');
  const keyB = ValueKey<String>('spot-b');

  Widget host(void Function(BuildContext) onGo) => AppThemeController(
    themeMode: ThemeMode.dark,
    setThemeMode: (_) {},
    child: MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 80),
              const SizedBox(key: keyA, width: 100, height: 40),
              const SizedBox(key: keyB, width: 100, height: 40),
              TextButton(onPressed: () => onGo(context), child: const Text('go')),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    // The overlay's ticker never stops, so pumpAndSettle would time out.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  tearDown(SpotlightTour.dismiss);

  testWidgets('walks the steps and reports completion on Finish', (
    tester,
  ) async {
    bool? completed;
    await tester.pumpWidget(
      host(
        (context) => SpotlightTour.show(
          context,
          steps: const [
            SpotlightStep(target: keyA, title: 'First', body: 'One'),
            SpotlightStep(target: keyB, title: 'Second', body: 'Two'),
          ],
          onClosed: (c) => completed = c,
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await settle(tester);
    expect(SpotlightTour.isActive, isTrue);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Back'), findsNothing);

    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.text('Finish'));
    await tester.pump();
    expect(completed, isTrue);
    expect(SpotlightTour.isActive, isFalse);
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('Skip closes with completed = false', (tester) async {
    bool? completed;
    await tester.pumpWidget(
      host(
        (context) => SpotlightTour.show(
          context,
          steps: const [
            SpotlightStep(target: keyA, title: 'First', body: 'One'),
            SpotlightStep(target: keyB, title: 'Second', body: 'Two'),
          ],
          onClosed: (c) => completed = c,
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await settle(tester);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(completed, isFalse);
    expect(SpotlightTour.isActive, isFalse);
  });

  testWidgets('a missing target still explains the step', (tester) async {
    await tester.pumpWidget(
      host(
        (context) => SpotlightTour.show(
          context,
          steps: const [
            SpotlightStep(
              target: ValueKey<String>('nope'),
              title: 'Lonely',
              body: 'No target',
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Lonely'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
