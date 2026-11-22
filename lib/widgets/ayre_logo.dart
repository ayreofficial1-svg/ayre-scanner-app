import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Where the mark is being used. Each placement has one fixed size, so the logo
/// never appears at an ad-hoc dimension invented per screen.
enum LogoPlacement {
  /// The primary placement: centred, generously sized, with clear breathing room.
  splash,

  /// A secondary header mark above auth/onboarding content.
  auth,

  /// A small, unobtrusive mark in a top-level header.
  header,
}

/// The Investee brand mark, rendered from `assets/brand/ayre_logo.png` (dark)
/// or `assets/brand/ayre_logo_light.png` (light).
///
/// The asset is authoritative and is used as-is: never recoloured, stretched,
/// rotated or otherwise distorted. Only three sizes exist, one per placement.
///
/// The source image is a square with its own field (deep green in the dark
/// variant, ivory in the light one) and generous internal padding. [LogoMark]
/// compensates for that padding so the *mark* reads at the intended size and
/// backs the artwork with the matching field colour so no seam shows.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.placement = LogoPlacement.header});

  final LogoPlacement placement;

  static const String assetPathDark = 'assets/brand/ayre_logo.png';
  static const String assetPathLight = 'assets/brand/ayre_logo_light.png';

  /// The rendered edge length for each placement.
  double get size => switch (placement) {
    LogoPlacement.splash => 200,
    LogoPlacement.auth => 104,
    LogoPlacement.header => 34,
  };

  /// Minimum clear space around the mark, kept proportional to its size rather
  /// than a fixed pixel value.
  double get clearSpace => size * 0.18;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = dark ? assetPathDark : assetPathLight;

    return Semantics(
      label: 'Investee',
      image: true,
      child: Padding(
        padding: EdgeInsets.all(clearSpace),
        child: ClipRRect(
          // A rounded field, matching the app's card language, so the mark
          // reads as a placed brand element rather than a pasted rectangle.
          //
          // Phase 5 owns this file, closing plan §7 open decision #8: it was
          // flagged unowned in Phases 1–4 because no phase's file list claimed
          // it, and Home is where the brand mark is actually placed. The old
          // `AppRadius.panel`/`hero` pair was retired in Phase 0 and has no
          // 1:1 successor — v4 has one card radius and one inner radius, so
          // the header mark takes the inner radius (it sits inline with text)
          // and a standalone placement takes the card radius.
          borderRadius: BorderRadius.circular(
            placement == LogoPlacement.header
                ? AppRadius.inset
                : AppRadius.card,
          ),
          child: ColoredBox(
            // The artwork carries its own field: brand deep green in the dark
            // variant (`surface` is that exact colour) and brand ivory in the
            // light one (`background` is that exact colour), so antialiased
            // corners never show a different tone.
            color: dark ? t.surface : t.background,
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              // The source is square with generous padding baked in; cover keeps
              // the mark centred and correctly proportioned without stretching.
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              // The asset is large; cache it at the size actually drawn so the
              // decode cost matches the placement rather than the source.
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (context, _, _) => _Fallback(size: size),
            ),
          ),
        ),
      ),
    );
  }
}

/// If the asset is ever missing from a build, show the wordmark rather than a
/// broken-image box.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'investee',
          style: AppTypo.display(
            fontSize: size * 0.26,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The wordmark alone, for places where the full mark would be too heavy — a
/// header beside live content, for instance.
class LogoWordmark extends StatelessWidget {
  const LogoWordmark({super.key, this.fontSize = 19, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Investee',
      child: Text(
        'investee',
        style: AppTypo.display(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color ?? t.textPrimary,
          letterSpacing: -0.6,
        ),
      ),
    );
  }
}