import 'package:ayre_scanner/main.dart';
import 'package:ayre_scanner/onboarding/onboarding_content.dart';
import 'package:ayre_scanner/screens/onboarding_screen.dart';
import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    Widget home, {
    double textScale = 1,
    bool reduceMotion = false,
    ThemeData? theme,
  }) => AppThemeController(
    themeMode: ThemeMode.dark,
    setThemeMode: (_) {},
    child: MaterialApp(
      theme: theme ?? AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: home,
    ),
  );

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.text(OnboardingLabels.next));
    await tester.pumpAndSettle();
  }

  testWidgets('Next and Back move between the two pages', (tester) async {
    await tester.pumpWidget(host(OnboardingScreen(onFinished: _ignore)));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.byTooltip(OnboardingLabels.back), findsNothing);

    await next(tester);
    expect(find.text('TRACK AND LEARN'), findsOneWidget);
    expect(find.byTooltip(OnboardingLabels.back), findsOneWidget);

    await tester.tap(find.byTooltip(OnboardingLabels.back));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME'), findsOneWidget);
  });

  testWidgets('Skip finishes once without the tutorial, even if double tapped', (
    tester,
  ) async {
    final results = <bool>[];
    await tester.pumpWidget(
      host(OnboardingScreen(onFinished: ({required startTour}) => results.add(startTour))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(OnboardingLabels.skip));
    await tester.tap(find.text(OnboardingLabels.skip), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('Get started on the last page asks for the tutorial', (
    tester,
  ) async {
    final results = <bool>[];
    await tester.pumpWidget(
      host(OnboardingScreen(onFinished: ({required startTour}) => results.add(startTour))),
    );
    await tester.pumpAndSettle();
    await next(tester);

    expect(find.text(OnboardingLabels.skip), findsNothing);
    expect(find.text(OnboardingLabels.next), findsNothing);

    await tester.tap(find.text(OnboardingLabels.getStarted));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  group('layout', () {
    Future<void> walk(WidgetTester tester) async {
      for (var i = 0; i < kOnboardingSteps.length; i++) {
        expect(tester.takeException(), isNull, reason: 'page $i');
        if (i < kOnboardingSteps.length - 1) await next(tester);
      }
    }

    testWidgets('no overflow at 320x568 with text scale 2.0', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(OnboardingScreen(onFinished: _ignore), textScale: 2.0),
      );
      await tester.pumpAndSettle();
      await walk(tester);
    });

    testWidgets('no overflow in light theme at 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(OnboardingScreen(onFinished: _ignore), theme: AppTheme.light),
      );
      await tester.pumpAndSettle();
      await walk(tester);
    });

    testWidgets('no overflow in landscape phone', (tester) async {
      tester.view.physicalSize = const Size(780, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(OnboardingScreen(onFinished: _ignore)));
      await tester.pumpAndSettle();
      await walk(tester);
    });
  });

  testWidgets('reduced motion jumps pages and finishes immediately', (
    tester,
  ) async {
    final results = <bool>[];
    await tester.pumpWidget(
      host(
        OnboardingScreen(onFinished: ({required startTour}) => results.add(startTour)),
        reduceMotion: true,
      ),
    );
    await tester.pump();

    await tester.tap(find.text(OnboardingLabels.next));
    await tester.pump();
    await tester.pump();
    expect(find.text('TRACK AND LEARN'), findsOneWidget);

    await tester.tap(find.text(OnboardingLabels.getStarted));
    await tester.pump();
    expect(results, [true]);
  });
}

void _ignore({required bool startTour}) {}
