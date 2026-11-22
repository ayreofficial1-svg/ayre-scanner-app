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

/// Transparent Investee artwork with spacing before the wordmark.
class LogoGlyph extends StatelessWidget {
  const LogoGlyph({super.key, required this.height, this.wordmarkGap});

  /// Rendered height of the square image.
  final double height;
  final double? wordmarkGap;

  static const String assetPathDark = 'assets/brand/ayre_logo.png';
  static const String assetPathLight = 'assets/brand/ayre_logo_light.png';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = dark ? assetPathDark : assetPathLight;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: wordmarkGap ?? height * 0.3),
      child: Image.asset(
        assetPath,
        width: height,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        cacheWidth: (height * MediaQuery.devicePixelRatioOf(context)).round(),
        excludeFromSemantics: true,
        errorBuilder: (context, _, _) => ExcludeSemantics(
          child: SizedBox.square(
            dimension: height,
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
    );
  }
}

/// The Investee brand lockup: approved mark + Manrope 800 `investee`
/// wordmark, laid out at the placement's fixed visible size. Sized with a
/// scale-down fit so the text is never clipped, and independent of the OS /
/// in-app text scale (a logo does not reflow with reading size).
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.placement = LogoPlacement.header,
    this.color,
  });

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
    final isSplash = placement == LogoPlacement.splash;
    return Semantics(
      label: 'Investee',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: s.width,
          height: h,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: isSplash ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LogoGlyph(
                  height: h,
                  wordmarkGap: isSplash ? AppSpace.s8 : null,
                ),
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
