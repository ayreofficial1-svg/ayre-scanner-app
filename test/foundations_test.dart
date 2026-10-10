import 'dart:math' as math;

import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_nav_metrics.dart';
import 'package:ayre_scanner/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _lin(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _lum(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

double _contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  final hi = math.max(la, lb), low = math.min(la, lb);
  return (hi + 0.05) / (low + 0.05);
}

void main() {
  final light = AppTheme.lightTokens;
  final dark = AppTheme.darkTokens;

  group('palette is frozen', () {
    void expectFrozen(AppThemeTokens t, Map<String, int> frozen) {
      final actual = <String, Color>{
        'background': t.background,
        'surface': t.surface,
        'surfaceRaised': t.surfaceRaised,
        'surfaceSunken': t.surfaceSunken,
        'accent': t.accent,
        'accentInk': t.accentInk,
        'accentSoft': t.accentSoft,
        'onAccent': t.onAccent,
        'positive': t.positive,
        'positiveSoft': t.positiveSoft,
        'negative': t.negative,
        'negativeSoft': t.negativeSoft,
        'neutral': t.neutral,
        'neutralSoft': t.neutralSoft,
        'textPrimary': t.textPrimary,
        'foregroundMuted': t.foregroundMuted,
        'foregroundSubtle': t.foregroundSubtle,
        'textDisabled': t.textDisabled,
        'hairline': t.hairline,
        'navHairline': t.navHairline,
        'shadowColor': t.shadowColor,
        'navBg': t.navBg,
        'skeleton': t.skeleton,
        'avatarFill': t.avatarFill,
        'avatarInk': t.avatarInk,
      };
      expect(actual.length, 25);
      frozen.forEach((k, v) => expect(actual[k]!.toARGB32(), v, reason: k));
    }

    test('light', () {
      expectFrozen(light, {
        'background': 0xFFF1F7F1,
        'surface': 0xFFFFFFFF,
        'surfaceRaised': 0xFFE9F2E9,
        'surfaceSunken': 0xFFE1EDE1,
        'accent': 0xFF1E8749,
        'accentInk': 0xFF166B3A,
        'accentSoft': 0xFFCFE8D8,
        'onAccent': 0xFFFFFFFF,
        'positive': 0xFF1F8A4B,
        'positiveSoft': 0xFFDCEEE0,
        'negative': 0xFFD64545,
        'negativeSoft': 0xFFF7DCDC,
        'neutral': 0xFFC98A2D,
        'neutralSoft': 0x24C98A2D,
        'textPrimary': 0xFF16211B,
        'foregroundMuted': 0xFF465549,
        'foregroundSubtle': 0xFF66746A,
        'textDisabled': 0x808B968E,
        'hairline': 0x141A2E22,
        'navHairline': 0x1F1A2E22,
        'shadowColor': 0xFFB9CBBB,
        'navBg': 0xFFFFFFFF,
        'skeleton': 0xFFE7EEE8,
        'avatarFill': 0xFFE1DDF5,
        'avatarInk': 0xFF4B3F73,
      });
    });

    test('dark', () {
      expectFrozen(dark, {
        'background': 0xFF0B120D,
        'surface': 0xFF121A14,
        'surfaceRaised': 0xFF1B261E,
        'surfaceSunken': 0xFF080D09,
        'accent': 0xFF3FCB7A,
        'accentInk': 0xFF59D98C,
        'accentSoft': 0xFF1E3B29,
        'onAccent': 0xFF06130A,
        'positive': 0xFF4ED892,
        'positiveSoft': 0xFF16301F,
        'negative': 0xFFF0685F,
        'negativeSoft': 0xFF3A1917,
        'neutral': 0xFFE0B563,
        'neutralSoft': 0x24E0B563,
        'textPrimary': 0xFFEDF5EE,
        'foregroundMuted': 0xFFD0DCD3,
        'foregroundSubtle': 0xFFB4C3B9,
        'textDisabled': 0x8067766C,
        'hairline': 0x14CFE8D5,
        'navHairline': 0x1FCFE8D5,
        'shadowColor': 0xFF000000,
        'navBg': 0xFF101911,
        'skeleton': 0xFF1B261E,
        'avatarFill': 0xFF241F38,
        'avatarInk': 0xFFC9BFEA,
      });
    });
  });

  group('A4 status-text tokens', () {
    test('values match the plan', () {
      expect(light.positiveText.toARGB32(), 0xFF166B3A);
      expect(light.negativeText.toARGB32(), 0xFFB83232);
      expect(light.neutralText.toARGB32(), 0xFF855A10);
      expect(dark.positiveText, dark.positive);
      expect(dark.negativeText, dark.negative);
      expect(dark.neutralText, dark.neutral);
    });

    for (final entry in {'light': light, 'dark': dark}.entries) {
      final t = entry.value;
      test('${entry.key}: >= 4.5:1 on every surface it sits on', () {
        final surfaces = <String, Color>{
          'surface': t.surface,
          'background': t.background,
          'surfaceSunken': t.surfaceSunken,
          'surfaceRaised': t.surfaceRaised,
        };
        final texts = <String, Color>{
          'positiveText': t.positiveText,
          'negativeText': t.negativeText,
          'neutralText': t.neutralText,
        };
        texts.forEach((tn, tc) {
          surfaces.forEach((sn, sc) {
            expect(
              _contrast(tc, sc),
              greaterThanOrEqualTo(4.5),
              reason: '$tn on $sn',
            );
          });
        });
        // Text on its own soft fill (soft over surface).
        expect(
          _contrast(t.positiveText, _over(t.positiveSoft, t.surface)),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(t.negativeText, _over(t.negativeSoft, t.surface)),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(t.neutralText, _over(t.neutralSoft, t.surface)),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    test('copyWith and lerp carry the new fields', () {
      final c = light.copyWith(positiveText: const Color(0xFF000000));
      expect(c.positiveText, const Color(0xFF000000));
      final mid = light.lerp(dark, 1);
      expect(mid.negativeText, dark.negativeText);
    });
  });

  group('layout contract', () {
    test('clearance maths', () {
      for (final inset in [0.0, 24.0, 34.0, 48.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          final bar = AyreNavMetrics.barHeightFor(
            textScale: scale,
            labelSize: 12,
          );
          expect(bar, greaterThanOrEqualTo(AyreNavMetrics.minHeight));
          expect(
            AyreNavMetrics.clearanceFor(
              viewportWidth: 390,
              bottomInset: inset,
              textScale: scale,
              labelSize: 12,
            ),
            bar + AyreNavMetrics.bottomGap + inset,
          );
        }
      }
      // Label scale is capped at 1.3, so 1.3 and 2.0 produce the same bar.
      expect(
        AyreNavMetrics.barHeightFor(textScale: 2.0, labelSize: 12),
        AyreNavMetrics.barHeightFor(textScale: 1.3, labelSize: 12),
      );
    });

    test('no clearance with the rail', () {
      expect(
        AyreNavMetrics.clearanceFor(
          viewportWidth: 720,
          bottomInset: 34,
          textScale: 1,
          labelSize: 12,
        ),
        0,
      );
    });

    test('3-button inset (48) is cleared where 120 was not', () {
      final c = AyreNavMetrics.clearanceFor(
        viewportWidth: 360,
        bottomInset: 48,
        textScale: 1,
        labelSize: 12,
      );
      expect(c, greaterThan(120 - 16));
    });

    test('label size by platform', () {
      expect(AyreNavMetrics.labelSizeFor(TargetPlatform.iOS), 11);
      expect(AyreNavMetrics.labelSizeFor(TargetPlatform.macOS), 11);
      expect(AyreNavMetrics.labelSizeFor(TargetPlatform.android), 12);
    });

    testWidgets('gutterOf is 16 below 360 and 20 otherwise, window classes',
        (tester) async {
      Future<void> at(double w, void Function(BuildContext) check) async {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                check(context);
                return const SizedBox();
              },
            ),
          ),
        );
      }

      await at(320, (c) => expect(AppSpace.gutterOf(c), 16));
      await at(359, (c) => expect(AppSpace.gutterOf(c), 16));
      await at(360, (c) => expect(AppSpace.gutterOf(c), 20));
      await at(
        599,
        (c) => expect(
          AppBreakpoints.windowClassOf(c),
          AppWindowClass.compact,
        ),
      );
      await at(
        600,
        (c) =>
            expect(AppBreakpoints.windowClassOf(c), AppWindowClass.medium),
      );
      await at(
        840,
        (c) => expect(
          AppBreakpoints.windowClassOf(c),
          AppWindowClass.expanded,
        ),
      );
    });

    test('overlay style: transparent bars, no nav scrim, icons by theme', () {
      final l = AppTheme.overlayStyle(Brightness.light);
      final d = AppTheme.overlayStyle(Brightness.dark);
      expect(l.systemNavigationBarContrastEnforced, false);
      expect(l.statusBarIconBrightness, Brightness.dark);
      expect(d.statusBarIconBrightness, Brightness.light);
      expect(l.systemNavigationBarColor, AppTheme.transparent);
    });
  });
}
