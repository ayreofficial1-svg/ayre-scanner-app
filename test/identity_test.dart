import 'dart:math' as math;

import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:ayre_scanner/widgets/ayre_icons.dart';
import 'package:ayre_scanner/widgets/figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the identity rules against the **actual final token values**, not the
/// written brief — the check §9.4 asks for, since real hex values always drift a
/// little from a spec during implementation.
///
/// Updated for v4 (plan `AYRE_REDESIGN_V4_PLAN.md`) per the working agreement
/// at the top of that document: this file is maintained quietly alongside
/// each phase's own changes rather than re-surfaced as a standalone
/// deliverable. Phase 0 changed every token value and several token names;
/// Phase 1 retired `ChipTone.info`, redrew three of the five nav glyphs, and
/// made icon stroke weight state-dependent (1.7 inactive / 2.1 active,
/// Spec §10) rather than fixed — both reflected below.
void main() {
  final themes = {
    'light': AppTheme.lightTokens,
    'dark': AppTheme.darkTokens,
  };

  group('palette — base and brand', () {
    test('the base is warm in both themes, never cool/graphite', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [
          t.background,
          t.surface,
          t.surfaceRaised,
          t.surfaceSunken,
        ]) {
          // v4 is deliberately warm paper/charcoal — a red-or-neutral-above-
          // blue undertone — reversing the previous cool graphite/ink base.
          expect(
            surface.r,
            greaterThanOrEqualTo(surface.b),
            reason: '$name base steps must be warm, never cool-undertoned',
          );
        }
      }
    });

    test('the accent is v4\'s clay/terracotta, not the old brand green', () {
      // v4 retires the fixed cross-theme brand green entirely — the accent is
      // now theme-dependent (warmer/darker in light mode) and lives in the
      // clay/terracotta family, not spring-green.
      expect(AppTheme.darkTokens.accent, const Color(0xFFD26A4C));
      expect(AppTheme.lightTokens.accent, const Color(0xFFC75F43));
    });

    test('the accent is a warm, red-leaning orange (clay), not green', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final tone in [t.accent, t.accentInk]) {
          expect(
            _hue(tone),
            inInclusiveRange(0, 30),
            reason: '$name accent family must be a warm clay/terracotta',
          );
        }
      }
    });

    test('positive is sage (green-leaning), distinct from the clay accent', () {
      // v4 reverses v3's "one ownable green for brand and gain": positive is
      // now a muted sage, deliberately in a different family from the clay
      // accent, and negative (muted rose) must stay unmistakable from it.
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        final positiveHue = _hue(t.positive);
        expect(
          positiveHue,
          inInclusiveRange(90, 160),
          reason: '$name positive should read as sage green',
        );

        final negativeHue = _hue(t.negative);
        final gap = (positiveHue - negativeHue).abs();
        expect(
          math.min(gap, 360 - gap),
          greaterThan(90),
          reason: '$name positive and negative must never be confusable',
        );
      }
    });

    test('negative is a muted rose, and neutral (gold) is tellable apart', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        // Rose sits in the red/pink band, not v3's wine-red "Garnet" band.
        final negativeHue = _hue(t.negative);
        expect(
          negativeHue > 340 || negativeHue < 25,
          isTrue,
          reason: '$name negative must be a muted rose, got $negativeHue',
        );
        expect(
          _hue(t.neutral),
          inInclusiveRange(30, 60),
          reason: '$name neutral is a muted gold',
        );
        // Compared on the wrapped axis so 350° vs 40° reads as 50° apart.
        final gap = (negativeHue - _hue(t.neutral)).abs();
        expect(
          math.min(gap, 360 - gap),
          greaterThan(8),
          reason: '$name negative and neutral must be tellable apart',
        );
      }
    });

    test('no bright/saturated green or red survives from the old identity', () {
      // Hard rule carried into code (plan §3.3): the previous identity's
      // saturated market colours are explicitly excluded, not just replaced.
      const excluded = [
        Color(0xFF00C853),
        Color(0xFF16A34A),
        Color(0xFFFF1744),
        Color(0xFFEF4444),
        Color(0xFF07C58F), // the old fixed brand green itself
      ];
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final tone in [t.accent, t.positive, t.negative, t.neutral]) {
          expect(
            excluded,
            isNot(contains(tone)),
            reason: '$name must not reintroduce an excluded saturated tone',
          );
        }
      }
    });
  });

  group('accessibility — contrast at final values', () {
    test('every text tone clears 4.5:1 on its surfaces', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [t.background, t.surface, t.surfaceRaised]) {
          for (final (role, color) in [
            ('textPrimary', t.textPrimary),
            ('foregroundMuted', t.foregroundMuted),
            // foregroundSubtle is eyebrow/caption-only by design discipline
            // (plan §3.2) — checked separately at large-text (3:1) below,
            // not asserted at the 4.5:1 normal-text floor here.
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

    test('foregroundSubtle (eyebrows/captions only) clears 3:1', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [t.background, t.surface, t.surfaceRaised]) {
          expect(
            _contrast(t.foregroundSubtle, surface),
            greaterThanOrEqualTo(3.0),
            reason:
                '$name foregroundSubtle is micro-copy only, held to the '
                'large-text/non-text floor, not full body-text AA',
          );
        }
      }
    });

    test('accentInk clears 4.5:1 as small text on its own theme\'s surfaces', () {
      // Phase 0's numeric contrast pass (plan §7 open decision #5): dark
      // theme's raw accent already clears AA (accentInk == accent there);
      // light theme needed a derived, darkened accentInk. Verify both hold
      // at the tokens' actual final values, not the plan's prose claim.
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [t.background, t.surface]) {
          expect(
            _contrast(t.accentInk, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name accentInk is used on figures and labels',
          );
        }
      }
    });

    test('ink text on the accent fill clears 4.5:1', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        expect(
          _contrast(t.onAccent, t.accent),
          greaterThanOrEqualTo(4.5),
          reason: '$name primary button label',
        );
      }
    });

    test('the accent fill carries a visible component edge', () {
      // A mid-lightness fill can't always carry its own boundary, which is
      // why AyreButton draws a hairline edge around every kind.
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        final edge = Color.alphaBlend(
          t.textPrimary.withValues(alpha: 0.18),
          t.background,
        );
        expect(
          _contrast(edge, t.background),
          greaterThanOrEqualTo(1.4),
          reason: '$name accent fills need a visible boundary',
        );
      }
    });
  });

  group('typography — the tabular-numerals rule', () {
    testWidgets('every live figure renders with tabular figures', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: Figure.static('24,518.40')),
        ),
      );

      final style = tester.widget<Text>(find.text('24,518.40')).style!;
      // v4 points the numeric face at Space Grotesk (`.num`), replacing
      // JetBrains Mono — the tabular-figures discipline itself is unchanged.
      expect(style.fontFamily, contains('SpaceGrotesk'));
      expect(
        style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: 'tabular figures stop a live number reflowing its neighbours',
      );
    });

    testWidgets('headings and body share one face; numbers use a second', (
      tester,
    ) async {
      late TextStyle heading;
      late TextStyle body;
      late TextStyle number;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              heading = AppTypo.pageTitle(context.tokens);
              body = AppTypo.body(context.tokens);
              number = AppTypo.heroValue(context.tokens);
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      // v4 collapses UI+heading onto one face (Hanken Grotesk), replacing the
      // previous Manrope/Space-Grotesk split — Space Grotesk's job narrows to
      // numbers + display headings only (plan §4).
      expect(heading.fontFamily, contains('HankenGrotesk'));
      expect(body.fontFamily, contains('HankenGrotesk'));
      expect(number.fontFamily, contains('SpaceGrotesk'));
      expect(number.fontFamily, isNot(equals(heading.fontFamily)));
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
    testWidgets(
      'the set renders as a family at its default stroke weights',
      (tester) async {
        // Checked as a set rather than icon by icon, per §4.3: every glyph
        // must paint at the shared grid without throwing. v4 uses a
        // state-dependent default stroke weight (1.7 inactive / 2.1 active,
        // Spec §10) rather than one fixed weight — both states are exercised
        // here, not just one.
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
      },
    );

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