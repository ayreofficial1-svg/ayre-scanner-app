import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Where the brand lockup is being used. Each placement has one fixed visible
/// size (at the 390 reference), so the logo never appears at an ad-hoc
/// dimension invented per screen.
enum LogoPlacement {
  /// Splash: ~208×52 visible lockup.
  splash,

  /// Auth / onboarding header: 96×24.
  auth,

  /// Top-level headers: 104×26.
  header,

  /// Home mast: 104×26.
  home,
}

/// The approved Investee mark, cropped tightly to the artwork.
///
/// Brand-asset decision (plan D01): the HTML's flat-topped block "in" is *not*
/// geometrically identical to the approved asset, so it is never traced. The
/// approved sloped mark is used exactly as supplied. Only opaque variants
/// exist (`assets/brand/ayre_logo*.png`, deep-green and ivory fields baked
/// in), so the mark is shown on its own matching field as a rounded tile —
/// never stretched, recoloured or isolated without permission. When a
/// transparent approved variant is supplied, only [LogoGlyph] needs to change.
///
/// The source is 2048×2048 with the mark occupying x 436–1612 / y 592–1456.
/// The crop below adds 120px of field on every side and is centred on the
/// image (centre 1024,1024), so it is a plain centred window.
class LogoGlyph extends StatelessWidget {
  const LogoGlyph({super.key, required this.height});

  /// Rendered tile height; the width follows the crop's aspect ratio.
  final double height;

  static const String assetPathDark = 'assets/brand/ayre_logo.png';
  static const String assetPathLight = 'assets/brand/ayre_logo_light.png';

  static const double _source = 2048;
  static const double _cropW = 1416; // 1176 mark + 2×120 field
  static const double _cropH = 1104; // 864 mark + 2×120 field

  /// Tile width/height ratio.
  static const double aspect = _cropW / _cropH;

  double get width => height * aspect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = dark ? assetPathDark : assetPathLight;
    // The artwork carries its own field: brand deep green in the dark variant
    // and brand ivory in the light one, so a matching ColoredBox keeps
    // anti-aliased corners free of any other tone.
    final field = dark ? const Color(0xFF0F3D2E) : const Color(0xFFF7F5EF);
    final side = height * (_source / _cropH);
    final w = width;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (height * 0.3).clamp(4.0, AppRadius.inset),
        ),
        child: ColoredBox(
          color: field,
          child: SizedBox(
            width: w,
            height: height,
            child: OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: side,
              maxHeight: side,
              child: Image.asset(
                assetPath,
                width: side,
                height: side,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                cacheWidth:
                    (side * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (context, _, _) => SizedBox(
                  width: w,
                  height: height,
                  child: Center(
                    child: Text(
                      'in',
                      style: AppTypo.display(
                        fontSize: height * 0.6,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Investee brand lockup: approved mark + Manrope 800 `investee`
/// wordmark, laid out at the placement's fixed visible size. Sized with a
/// scale-down fit so the text is never clipped, and independent of the OS /
/// in-app text scale (a logo does not reflow with reading size).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.placement = LogoPlacement.header, this.color});

  final LogoPlacement placement;

  /// Wordmark colour; defaults to the primary ink.
  final Color? color;

  static const String assetPathDark = LogoGlyph.assetPathDark;
  static const String assetPathLight = LogoGlyph.assetPathLight;

  /// Visible lockup size for each placement.
  Size get size => switch (placement) {
    LogoPlacement.splash => const Size(208, 52),
    LogoPlacement.auth => const Size(96, 24),
    LogoPlacement.header => const Size(104, 26),
    LogoPlacement.home => const Size(104, 26),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = size;
    final h = s.height;
    return Semantics(
      label: 'Investee',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: s.width,
          height: h,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LogoGlyph(height: h),
                SizedBox(width: h * 0.3),
                Text(
                  'investee',
                  textScaler: TextScaler.noScaling,
                  softWrap: false,
                  style: AppTypo.display(
                    fontSize: h * 0.64,
                    color: color ?? t.textPrimary,
                    height: 1.0,
                    letterSpacing: -h * 0.02,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The wordmark alone, for places where the full lockup would be too heavy —
/// a header beside live content, for instance. Manrope 800.
class LogoWordmark extends StatelessWidget {
  const LogoWordmark({super.key, this.fontSize = 19, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Investee',
      child: ExcludeSemantics(
        child: Text(
          'investee',
          softWrap: false,
          style: AppTypo.display(
            fontSize: fontSize,
            color: color ?? t.textPrimary,
            height: 1.1,
            letterSpacing: -fontSize * 0.03,
          ),
        ),
      ),
    );
  }
}
