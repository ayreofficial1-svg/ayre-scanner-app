import 'dart:math' as math;

import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/numeral.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brass is the brand hue and the base is warm in both themes', () {
    for (final tokens in [AppTheme.lightTokens, AppTheme.darkTokens]) {
      // Brass: red above green above blue, with a real spread — not teal, not
      // blue, not a neutral.
      expect(tokens.primary.r, greaterThan(tokens.primary.g));
      expect(tokens.primary.g, greaterThan(tokens.primary.b));

      // The canvas is warm at every step: red channel above blue.
      for (final surface in [
        tokens.background,
        tokens.backgroundTint,
        tokens.surface,
        tokens.surfaceAlt,
        tokens.surfaceRaised,
      ]) {
        expect(
          surface.r,
          greaterThan(surface.b),
          reason: 'every base step must be warm, never blue-tinted',
        );
      }
    }
  });

  test('text tones clear WCAG AA against their typical surfaces', () {
    for (final (name, tokens) in [
      ('light', AppTheme.lightTokens),
      ('dark', AppTheme.darkTokens),
    ]) {
      for (final surface in [tokens.background, tokens.surface]) {
        for (final (role, color) in [
          ('textPrimary', tokens.textPrimary),
          ('textSecondary', tokens.textSecondary),
          // textTertiary used to fail this in both themes.
          ('textTertiary', tokens.textTertiary),
        ]) {
          expect(
            _contrast(color, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name $role must clear 4.5:1 for normal text',
          );
        }
      }
    }
  });

  testWidgets('theme exposes the token extension', (tester) async {
    AppThemeTokens? tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            tokens = context.tokens;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    expect(tokens, isNotNull);
    expect(tokens!.primary, AppTheme.darkTokens.primary);
  });

  test('deltas carry their direction in the string, not just in color', () {
    expect(formatDelta(1.5), '+1.50%');
    expect(formatDelta(-1.5), '−1.50%');
    expect(formatDelta(0), '+0.00%');
    expect(formatDelta(2.25, percent: false), '+2.25');
  });

  test('prices group thousands and volumes scale', () {
    expect(formatPrice(24518.4), '24,518.40');
    expect(formatPrice(999), '999.00');
    expect(formatPrice(null), '--');
    expect(formatVolume(12500000), '1.3Cr');
    expect(formatVolume(250000), '2.5L');
    expect(formatVolume(8210), '8.2K');
    expect(formatVolume(412), '412');
  });

  testWidgets('live figures render in the monospace readout face', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: Numeral.static('24,518.40')),
      ),
    );

    final style = tester.widget<Text>(find.text('24,518.40')).style!;
    expect(style.fontFamily, contains('Plex'));
    expect(
      style.fontFeatures,
      contains(const FontFeature.tabularFigures()),
      reason: 'tabular figures keep a live number from reflowing neighbours',
    );
  });
}

/// WCAG 2.x relative-luminance contrast ratio.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}
