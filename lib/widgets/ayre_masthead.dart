import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Which [MastPalette] a masthead uses.
enum AyreMastTone {
  /// Default sage (light) / dark-green (dark) mast.
  standard,

  /// Champagne variant (Reports, register).
  champagne,

  /// Home: deep green in light, the default dark mast in dark.
  home,
}

extension AyreMastToneX on AyreMastTone {
  MastPalette paletteOf(AppThemeTokens t) => switch (this) {
    AyreMastTone.standard => t.mast,
    AyreMastTone.champagne => t.mastChampagne,
    AyreMastTone.home => t.mastHome,
  };
}

/// The shared masthead: a flat fill clipped to the polygon
/// `(0,0) (w,0) (w,h−55) (0,h)` with a low-opacity block watermark at its
/// bottom-right. Content (title, header actions, logo) is laid out *over* it
/// and is never clipped.
///
/// [height] is the reference mast height (233 tabs, 267 Home, 322 sign-in);
/// the mast grows with the top safe inset and with [child] so text always
/// stays above the diagonal. The first overlapping card should use
/// [AyreMastScaffold] / [AyreMastOverlap] so it occupies real layout space.
class AyreMasthead extends StatelessWidget {
  const AyreMasthead({
    super.key,
    this.tone = AyreMastTone.standard,
    this.height = AppShape.mastTab,
    this.child,
    this.palette,
    this.padding,
    this.overlap = 0,
  });

  final AyreMastTone tone;

  /// How far the first card overlaps the mast bottom (34 on tabs). The mast
  /// *paints* [overlap] below its layout box, so the card that follows
  /// occupies real layout space, stays hit-testable and paints over it.
  final double overlap;

  /// Reference height at 390 width, measured from the top of the window (the
  /// safe inset is *included*, not added on top).
  final double height;

  /// Overrides [tone] with an explicit palette.
  final MastPalette? palette;

  /// Content laid over the backdrop.
  final Widget? child;

  /// Content padding; defaults to the gutter and a top that places the first
  /// line at the reference y = 55 once the safe inset is counted.
  final EdgeInsetsGeometry? padding;

  /// Reference y of the first content line (inset included).
  static const double contentTop = 55;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = palette ?? tone.paletteOf(t);
    final top = MediaQuery.paddingOf(context).top;
    final gutter = AppSpace.gutterOf(context);
    // Never add a second 55 on top of the inset: reserve what is left of 55
    // after the inset, with at least 13 of air on tall cutouts.
    final topPad = math.max(AppSpace.s13, contentTop - top);
    final resolved =
        padding ?? EdgeInsetsDirectional.fromSTEB(gutter, topPad, gutter, 0);

    return DefaultTextStyle.merge(
      style: TextStyle(color: p.ink),
      child: IconTheme.merge(
        data: IconThemeData(color: p.ink),
        child: CustomPaint(
          painter: _MastPainter(palette: p, overlap: overlap),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  height -
                  overlap +
                  math.max(0, top - contentTop + AppSpace.s13),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: top,
                // Keep content above the diagonal: it rises 55 at the right.
                bottom: math.max(0, AppShape.mastDiagonal - overlap),
              ).add(resolved),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _MastPainter extends CustomPainter {
  const _MastPainter({required this.palette, required this.overlap});

  final MastPalette palette;
  final double overlap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height + overlap;
    final shape = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - AppShape.mastDiagonal)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(shape, Paint()..color = palette.fill);

    // Watermark: 233×178 polygon, bottom-right, clipped by the mast shape.
    canvas.save();
    canvas.clipPath(shape);
    const mw = 233.0;
    const mh = 178.0;
    final ox = w - mw;
    final oy = h - mh;
    Offset pt(double fx, double fy) => Offset(ox + fx * mw, oy + fy * mh);
    final motif = Path()
      ..moveTo(pt(0, 0.13).dx, pt(0, 0.13).dy)
      ..lineTo(pt(1, 0).dx, pt(1, 0).dy)
      ..lineTo(pt(1, 1).dx, pt(1, 1).dy)
      ..lineTo(pt(0.66, 1).dx, pt(0.66, 1).dy)
      ..lineTo(pt(0.66, 0.46).dx, pt(0.66, 0.46).dy)
      ..lineTo(pt(0.36, 0.46).dx, pt(0.36, 0.46).dy)
      ..lineTo(pt(0.36, 1).dx, pt(0.36, 1).dy)
      ..lineTo(pt(0, 1).dx, pt(0, 1).dy)
      ..close();
    canvas.drawPath(motif, Paint()..color = palette.motif);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MastPainter old) =>
      old.palette != palette || old.overlap != overlap;
}

/// A mast plus the card that overlaps it by [overlap] (34), as real scroll
/// content: build the [mast] with the same `overlap` so it paints that far
/// below its layout box; the card then occupies actual layout space (no
/// Stack-only height, nothing clipped or overflowing) and stays tappable.
/// Use as the first child of a scroll view with zero padding.
class AyreMastScaffold extends StatelessWidget {
  const AyreMastScaffold({super.key, required this.mast, this.overlapChild});

  /// An [AyreMasthead] built with `overlap: AppShape.mastOverlap` when
  /// [overlapChild] is set.
  final Widget mast;

  /// First card, laid out directly after the mast and painted over it.
  final Widget? overlapChild;

  @override
  Widget build(BuildContext context) {
    if (overlapChild == null) return mast;
    final gutter = AppSpace.gutterOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mast,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: overlapChild,
        ),
      ],
    );
  }
}

/// Header icon plate on a mast: 44×44, radius 13, glass fill, ≥48 hit area.
class MastIconButton extends StatelessWidget {
  const MastIconButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.palette,
    this.tone = AyreMastTone.standard,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final MastPalette? palette;
  final AyreMastTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = palette ?? tone.paletteOf(t);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: AppSpace.minTarget,
            height: AppSpace.minTarget,
            child: Center(
              child: Container(
                width: AppShape.iconTileSize,
                height: AppShape.iconTileSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.glass,
                  borderRadius: AppShape.field,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: p.ink),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
