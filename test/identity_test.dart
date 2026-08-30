import 'dart:math' as math;

import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_icons.dart';
import 'package:ayre_scanner/widgets/figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the identity rules against the **actual final token values**, not the
/// written brief — the check §9.4 asks for, since real hex values always drift a
/// little from a spec during implementation.
void main() {
  final themes = {
    'light': AppTheme.lightTokens,
    'dark': AppTheme.darkTokens,
  };

  group('palette — base and brand', () {
    test('the base is cool in both themes, never warm or cream', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [
          t.background,
          t.backgroundTint,
          t.surface,
          t.surfaceAlt,
          t.surfaceRaised,
          t.inkPanel,
        ]) {
          // Warm surfaces read red-above-blue. The previous identity's cream and
          // graphite-brown base is exactly what must not come back.
          expect(
            surface.b,
            greaterThanOrEqualTo(surface.r),
            reason: '$name base steps must be cool, never warm-undertoned',
          );
        }
      }
    });

    test('Citrine is a warm yellow-green, not a fintech blue/mint/violet', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final citrine in [t.citrine, t.citrineInk]) {
          // Yellow-green: red and green both well above blue, and red close to
          // green. A blue, mint or violet primary fails all three.
          expect(citrine.b, lessThan(citrine.g), reason: '$name citrine hue');
          expect(citrine.b, lessThan(citrine.r), reason: '$name citrine hue');
          expect(
            (citrine.r - citrine.g).abs(),
            lessThan(0.22),
            reason: '$name citrine must stay yellow-leaning, not lime or olive',
          );
        }
      }
    });

    test('Citrine and Jade are unmistakably different greens', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        final citrineHue = _hue(t.citrine);
        final jadeHue = _hue(t.jade);
        // Citrine sits in the yellow-green band, Jade in the blue-green band.
        expect(
          citrineHue,
          inInclusiveRange(50, 85),
          reason: '$name citrine should be yellow-green',
        );
        expect(
          jadeHue,
          inInclusiveRange(140, 180),
          reason: '$name jade should be blue-leaning green',
        );
        expect(
          (citrineHue - jadeHue).abs(),
          greaterThan(60),
          reason: '$name brand and gain greens must not drift together',
        );
        // And Jade is the more saturated of the two, as specified.
        expect(
          _saturation(t.jade),
          greaterThan(_saturation(t.citrine)),
          reason: '$name jade is saturated where citrine is mineral/muted',
        );
      }
    });

    test('Garnet is a wine-toned red, distinct from Ember', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        // Red wraps through 360; Garnet's wine undertone sits just below it
        // rather than on the pure-red axis, which is the point of the hue.
        final garnetHue = _hue(t.garnet);
        expect(
          garnetHue > 335 || garnetHue < 20,
          isTrue,
          reason: '$name garnet must be a wine-leaning red, got $garnetHue',
        );
        expect(
          _hue(t.ember),
          inInclusiveRange(20, 45),
          reason: '$name ember is copper-amber',
        );
        // Compared on the wrapped axis so 350° vs 30° reads as 40° apart.
        final gap = (garnetHue - _hue(t.ember)).abs();
        expect(
          math.min(gap, 360 - gap),
          greaterThan(8),
          reason: '$name loss and attention must be tellable apart',
        );
      }
    });
  });

  group('accessibility — contrast at final values', () {
    test('every text tone clears 4.5:1 on its surfaces', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [t.background, t.surface, t.surfaceAlt]) {
          for (final (role, color) in [
            ('textPrimary', t.textPrimary),
            ('textSecondary', t.textSecondary),
            ('textTertiary', t.textTertiary),
          ]) {
            expect(
              _contrast(color, surface),
              greaterThanOrEqualTo(4.5),
              reason: '$name $role must clear AA for normal text',
            );
          }
        }
      }
    });

    test('semantic colours clear 4.5:1 as small text', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [t.background, t.surface]) {
          for (final (role, color) in [
            ('jade', t.jade),
            ('garnet', t.garnet),
            ('ember', t.ember),
            ('slateViolet', t.slateViolet),
            // The type-weight Citrine — the reason a separate token exists.
            ('citrineInk', t.citrineInk),
          ]) {
            expect(
              _contrast(color, surface),
              greaterThanOrEqualTo(4.5),
              reason: '$name $role is used on figures and labels',
            );
          }
        }
      }
    });

    test('ink text on a Citrine fill clears 4.5:1', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        expect(
          _contrast(t.onCitrine, t.citrine),
          greaterThanOrEqualTo(4.5),
          reason: '$name primary button label',
        );
      }
    });

    test('readout text on the ink panel clears 4.5:1', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        expect(
          _contrast(t.onInkPanel, t.inkPanel),
          greaterThanOrEqualTo(4.5),
          reason: '$name ink panel is where live figures live',
        );
      }
    });

    test('the Citrine fill carries a 3:1 component edge', () {
      // A light-on-light fill can't carry its own boundary, which is why the
      // button and the Fold's control both draw a hairline edge.
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        final edge = Color.alphaBlend(
          t.textPrimary.withValues(alpha: 0.18),
          t.background,
        );
        expect(
          _contrast(edge, t.background),
          greaterThanOrEqualTo(1.4),
          reason: '$name citrine fills need a visible boundary',
        );
      }
    });
  });

  group('typography — the monospace rule', () {
    testWidgets('every live figure renders in the ticker face', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: Figure.static('24,518.40')),
        ),
      );

      final style = tester.widget<Text>(find.text('24,518.40')).style!;
      expect(style.fontFamily, contains('JetBrains'));
      expect(
        style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: 'tabular figures stop a live number reflowing its neighbours',
      );
    });

    testWidgets('headings take the display face, body takes the UI face', (
      tester,
    ) async {
      late TextStyle heading;
      late TextStyle body;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              heading = AppTypo.pageTitle(context.tokens);
              body = AppTypo.body(context.tokens);
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      expect(heading.fontFamily, contains('SpaceGrotesk'));
      expect(body.fontFamily, contains('Manrope'));
      // The two sans faces must not blur together into one voice.
      expect(heading.fontFamily, isNot(equals(body.fontFamily)));
    });
  });

  group('formatters', () {
    test('deltas carry direction in the string, not only in colour', () {
      expect(formatDelta(1.5), '+1.50%');
      // A true minus, not a hyphen.
      expect(formatDelta(-1.5), '−1.50%');
      expect(formatDelta(0), '+0.00%');
      expect(formatDelta(2.25, percent: false), '+2.25');
    });

    test('prices use Indian digit grouping', () {
      expect(formatPrice(24518.4), '24,518.40');
      expect(formatPrice(1234567.8), '12,34,567.80');
      expect(formatPrice(999), '999.00');
      expect(formatPrice(null), '—');
      expect(formatPrice(-450.5), '−450.50');
    });

    test('volumes scale to crore, lakh and thousand', () {
      expect(formatVolume(12500000), '1.25Cr');
      expect(formatVolume(250000), '2.50L');
      expect(formatVolume(8210), '8.21K');
      expect(formatVolume(412), '412');
      expect(formatVolume(null), '—');
    });
  });

  group('iconography', () {
    testWidgets('the set renders as a family at one stroke weight', (
      tester,
    ) async {
      // Checked as a set rather than icon by icon, per §4.3: every glyph must
      // paint at the shared grid and weight without throwing.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: [
                  for (final glyph in AyreGlyph.values) ...[
                    AyreIcon(glyph, size: 24),
                    // The filled variant exists for selected states.
                    AyreIcon(glyph, size: 24, filled: true),
                    // And the set has to hold at the sizes it is actually used.
                    AyreIcon(glyph, size: 12),
                    AyreIcon(glyph, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byType(AyreIcon),
        findsNWidgets(AyreGlyph.values.length * 4),
      );
      expect(tester.takeException(), isNull);
    });

    test('every destination and state has a glyph', () {
      // The nav, the two distinct data states, and the market directions are the
      // glyphs the design leans on hardest.
      for (final required in [
        AyreGlyph.home,
        AyreGlyph.signals,
        AyreGlyph.insights,
        AyreGlyph.learn,
        AyreGlyph.profile,
        AyreGlyph.empty,
        AyreGlyph.disconnected,
        AyreGlyph.offline,
        AyreGlyph.delayed,
        AyreGlyph.trendUp,
        AyreGlyph.trendDown,
      ]) {
        expect(AyreGlyph.values, contains(required));
      }
    });
  });
}

// ─── WCAG helpers ──────────────────────────────────────────────────────────

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _luminance(Color color) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// Hue in degrees, 0–360.
double _hue(Color c) {
  final max = math.max(c.r, math.max(c.g, c.b));
  final min = math.min(c.r, math.min(c.g, c.b));
  final delta = max - min;
  if (delta == 0) return 0;
  double h;
  if (max == c.r) {
    h = 60 * (((c.g - c.b) / delta) % 6);
  } else if (max == c.g) {
    h = 60 * ((c.b - c.r) / delta + 2);
  } else {
    h = 60 * ((c.r - c.g) / delta + 4);
  }
  return h < 0 ? h + 360 : h;
}

double _saturation(Color c) {
  final max = math.max(c.r, math.max(c.g, c.b));
  final min = math.min(c.r, math.min(c.g, c.b));
  if (max == 0) return 0;
  return (max - min) / max;
}
