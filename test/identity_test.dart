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
/// Updated for v5 (`INVESTY_IMPLEMENTATION_PLAN.md` §2A): forest-green/emerald
/// identity, mint-paper light theme, near-black-green dark theme. The v4
/// clay/sage/rose assertions this file used to hold no longer describe the
/// app and were replaced, not patched.
void main() {
  final themes = {
    'light': AppTheme.lightTokens,
    'dark': AppTheme.darkTokens,
  };

  group('palette — base and brand', () {
    test('the base carries a green cast in both themes, never neutral gray', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [
          t.background,
          t.surface,
          t.surfaceRaised,
          t.surfaceSunken,
        ]) {
          // Mint-white (light) / near-black green (dark): green is never the
          // weakest channel. Pure white satisfies this with equality.
          expect(
            surface.g,
            greaterThanOrEqualTo(surface.r),
            reason: '$name base steps must not lean red',
          );
          expect(
            surface.g,
            greaterThanOrEqualTo(surface.b),
            reason: '$name base steps must not lean blue',
          );
        }
      }
    });

    test('the accent is v5 emerald, not v4 clay', () {
      expect(AppTheme.darkTokens.accent, const Color(0xFF3FCB7A));
      // Phase 1B (HIG alignment): deepened ~2% lightness from #1F8A4B to
      // clear the onAccent contrast floor below — see that test.
      expect(AppTheme.lightTokens.accent, const Color(0xFF1E8749));
      expect(AppTheme.darkTokens.accent, isNot(const Color(0xFFD26A4C)));
      expect(AppTheme.lightTokens.accent, isNot(const Color(0xFFC75F43)));
    });

    test('the accent family is green', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final tone in [t.accent, t.accentInk, t.positive]) {
          expect(
            _hue(tone),
            inInclusiveRange(130, 165),
            reason: '$name accent family must be emerald/forest green',
          );
        }
      }
    });

    test('negative is a clear red and never confusable with positive', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        final negativeHue = _hue(t.negative);
        expect(
          negativeHue > 340 || negativeHue < 25,
          isTrue,
          reason: '$name negative must sit in the red band, got $negativeHue',
        );
        final gap = (_hue(t.positive) - negativeHue).abs();
        expect(
          math.min(gap, 360 - gap),
          greaterThan(90),
          reason: '$name positive and negative must never be confusable',
        );
      }
    });

    test('neutral is a muted gold, tellable apart from negative', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        expect(
          _hue(t.neutral),
          inInclusiveRange(30, 60),
          reason: '$name neutral is a muted gold',
        );
        final gap = (_hue(t.negative) - _hue(t.neutral)).abs();
        expect(
          math.min(gap, 360 - gap),
          greaterThan(8),
          reason: '$name negative and neutral must be tellable apart',
        );
      }
    });

    test('the avatar identity accent is lavender/plum, distinct from brand', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final tone in [t.avatarFill, t.avatarInk]) {
          expect(
            _hue(tone),
            inInclusiveRange(230, 290),
            reason: '$name avatar tones must stay in the lavender/plum family',
          );
        }
      }
      expect(AppTheme.lightTokens.avatarFill, const Color(0xFFE1DDF5));
      expect(AppTheme.darkTokens.avatarInk, const Color(0xFFC9BFEA));
    });

    test('index identity tints are distinct per index in both themes', () {
      for (final tints in [AppIndexTints.light, AppIndexTints.dark]) {
        expect(tints.keys.toSet(), AppIndexId.values.toSet());
        final backgrounds = tints.values.map((v) => v.cardBackground).toSet();
        final traces = tints.values.map((v) => v.trace).toSet();
        expect(backgrounds.length, AppIndexId.values.length);
        expect(traces.length, AppIndexId.values.length);
      }
    });
  });

  group('accessibility — contrast at final values', () {
    test('primary and muted text clear 4.5:1 on every surface step', () {
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [t.background, t.surface, t.surfaceRaised]) {
          for (final (role, color) in [
            ('textPrimary', t.textPrimary),
            ('foregroundMuted', t.foregroundMuted),
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

    test('foregroundSubtle (eyebrows/micro-labels only) holds a 2.5:1 floor', () {
      // §2A's values measure 2.68–3.07:1 in light and 3.27–3.96:1 in dark.
      // This token is micro-copy only by design; the assertion is a
      // regression guard on the canonical values, not a claim of AA.
      for (final (name, t) in themes.entries.map((e) => (e.key, e.value))) {
        for (final surface in [t.background, t.surface, t.surfaceRaised]) {
          expect(
            _contrast(t.foregroundSubtle, surface),
            greaterThanOrEqualTo(2.5),
            reason: '$name foregroundSubtle regressed below its measured floor',
          );
        }
      }
    });

    test('accentInk clears 4.5:1 as small text on its own theme\'s surfaces', () {
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

    test('dark onAccent clears 4.5:1 on accent', () {
      final t = AppTheme.darkTokens;
      expect(_contrast(t.onAccent, t.accent), greaterThanOrEqualTo(4.5));
    });

    test('light onAccent clears 4.5:1 on accent', () {
      // Phase 1B (HIG alignment): accent was deepened ~2% lightness
      // specifically to close this gap — was ~4.38:1 (below AA), now
      // ~4.55:1. Fails if the pairing regresses below the AA floor.
      final t = AppTheme.lightTokens;
      expect(_contrast(t.onAccent, t.accent), greaterThanOrEqualTo(4.5));
    });

    test('text on the identity tints keeps `muted` at or above 4.5:1', () {
      for (final entry in {
        Brightness.light: AppIndexTints.light,
        Brightness.dark: AppIndexTints.dark,
      }.entries) {
        final t = entry.key == Brightness.light
            ? AppTheme.lightTokens
            : AppTheme.darkTokens;
        for (final tint in entry.value.values) {
          expect(
            _contrast(t.foregroundMuted, tint.cardBackground),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key.name} muted text on an index card tint',
          );
        }
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