import 'package:flutter/material.dart';

import '../services/market_models.dart' show IndexId;
import '../theme/app_theme.dart';
import 'ayre_icons.dart';

/// What makes an index card *that* index's card: its identity tint (v5 §2A,
/// "Index-card identity tints"), its glyph, and the exchange it trades on.
///
/// The tint table itself lives in [AppIndexTints] (`app_theme.dart`) — this
/// only joins it to the app's [IndexId] and to the other two per-index facts
/// a card needs, so `home_tab.dart` (Phase 3) and `index_detail_screen.dart`
/// (Phase 7) resolve an index the same way instead of each keeping its own
/// switch.
///
/// The tint is **decorative identity, never gain/loss** — see
/// [AppIndexTint].
@immutable
class AyreIndexIdentity {
  const AyreIndexIdentity({
    required this.tint,
    required this.glyph,
    this.exchange,
  });

  final AppIndexTint tint;

  /// NIFTY 50 → up-trend, SENSEX → bar chart, BANK NIFTY → bank facade
  /// (matched to the reference).
  final AyreGlyph glyph;

  /// The listing exchange — a static fact about the index, not market data.
  /// Null for an index this table doesn't know.
  final String? exchange;

  /// Resolves [index] for the current theme brightness.
  ///
  /// An index that isn't in [IndexId] (null) gets a neutral identity built
  /// from the theme's own tokens rather than borrowing another index's tint:
  /// a wrong identity colour would be worse than none.
  static AyreIndexIdentity of(BuildContext context, IndexId? index) {
    if (index == null) {
      final t = context.tokens;
      return AyreIndexIdentity(
        tint: AppIndexTint(
          cardBackground: t.surface,
          iconGradientCenter: t.surfaceRaised,
          iconGradientEdge: t.surfaceSunken,
          trace: t.accent,
          activePeriodTabFill: t.accentSoft,
        ),
        glyph: AyreGlyph.instrument,
      );
    }

    final (AppIndexId id, AyreGlyph glyph, String exchange) = switch (index) {
      IndexId.nifty50 => (AppIndexId.nifty50, AyreGlyph.trendUp, 'NSE'),
      IndexId.sensex => (AppIndexId.sensex, AyreGlyph.instrument, 'BSE'),
      IndexId.bankNifty => (AppIndexId.bankNifty, AyreGlyph.bank, 'NSE'),
    };

    return AyreIndexIdentity(
      tint: AppIndexTints.of(id, Theme.of(context).brightness),
      glyph: glyph,
      exchange: exchange,
    );
  }
}

/// The index card's icon tile (v5 §2A, "Icon-tile shape override"): a
/// **circle** filled with the tint's two-stop radial gradient — lighter at
/// the centre, darker at the edge — with the glyph in the tint's trace
/// colour.
///
/// This is the one icon tile in the app that isn't an
/// [AppRadius.iconTile] rounded square; don't carry the circle anywhere
/// else. Decorative and excluded from semantics — the card's own label names
/// the index.
class AyreIndexIconTile extends StatelessWidget {
  const AyreIndexIconTile({
    super.key,
    required this.glyph,
    required this.tint,
    this.size = 44,
  });

  final AyreGlyph glyph;
  final AppIndexTint tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [tint.iconGradientCenter, tint.iconGradientEdge],
          ),
        ),
        child: AyreIcon(glyph, size: size * 0.46, color: tint.trace),
      ),
    );
  }
}

/// Decorative flourish behind an index card's figures (plan §5 Phase 3
/// step 2): three soft, overlapping, translucent domes rising from the
/// bottom-right, in the card's own tint.
///
/// **Ornament, not a chart.** The backend supplies no per-index series
/// (plan §3), so the reference's sparkline slot is filled with this instead
/// — it carries no data, is excluded from semantics, ignores pointers, and
/// is drawn *behind* [child] so figures stay on top. It only takes a card's
/// empty-trace branch; when a real `Quote.trace` arrives the card draws the
/// sparkline instead and never builds this.
///
/// It is a `Stack` backdrop, so it adds no layout of its own: [child]
/// alone decides the height, and a hero figure at a large text scale is
/// never squeezed to make room for it. Deliberately no `LayoutBuilder` —
/// Home wraps the wide-layout card row in an `IntrinsicHeight`, which a
/// `LayoutBuilder` would throw on.
///
/// The dome alphas are derived washes of the tint's trace colour (Phase 0
/// step 5: no new hues), a little stronger in dark so they still read
/// against the darker card.
class AyreIndexFlourish extends StatelessWidget {
  const AyreIndexFlourish({super.key, required this.color, required this.child});

  /// The tint's `trace` colour.
  final Color color;

  /// The figures the flourish sits behind. Its height sets the flourish's.
  final Widget child;

  /// Width of the ornament's box; the domes bleed off its right edge.
  static const double width = 104;

  // Back → front.
  static const List<double> _lightAlphas = [0.10, 0.16, 0.24];
  static const List<double> _darkAlphas = [0.12, 0.20, 0.30];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Full width, so `right: 0` means the card's right edge rather than the
    // right edge of whatever narrower box [child] happens to size to.
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: width,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _FlourishPainter(
                    color: color,
                    alphas: dark ? _darkAlphas : _lightAlphas,
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _FlourishPainter extends CustomPainter {
  const _FlourishPainter({required this.color, required this.alphas});

  final Color color;

  /// Back → front, one per dome.
  final List<double> alphas;

  // Centre x/y and radius x/y as fractions of the box, back → front. Centres
  // sit just below the bottom edge and step right, so each dome peaks a
  // little lower than the one behind it and the three read as layered hills
  // rising toward the card's right edge.
  static const List<(double, double, double, double)> _domes = [
    (0.60, 1.10, 0.60, 0.95),
    (0.82, 1.12, 0.48, 0.72),
    (1.00, 1.14, 0.36, 0.52),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < _domes.length; i++) {
      final (cx, cy, rx, ry) = _domes[i];
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * cx, size.height * cy),
          width: size.width * rx * 2,
          height: size.height * ry * 2,
        ),
        Paint()..color = color.withValues(alpha: alphas[i]),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlourishPainter old) =>
      old.color != color || old.alphas != alphas;
}
