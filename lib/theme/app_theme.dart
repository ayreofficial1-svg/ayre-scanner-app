import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Section identifiers ────────────────────────────────────────────────────
enum AyreSection { home, signals, insights, learn, profile }

// ─── Token extension ────────────────────────────────────────────────────────
// The palette is warm brass + warm ink. Brass (`primary`) is the sole always-on
// brand hue and doubles as "the instrument's mechanism" (gauge needle, nav
// needle-mark, sparkline trace). The base is warm at every step in both
// themes: parchment in light, warm ink/graphite — never blue-black — in dark.
//
// The legacy decorative tokens (cream/ivory/peach/coral/mint/mintDeep/teal/
// teal2/lavender/violet/sage/gold) are gone. There is no decorative palette
// any more: every color here has one semantic job, described below.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.background,
    required this.backgroundTint,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.primary,
    required this.primaryMuted,
    required this.positive,
    required this.negative,
    required this.accentWarm,
    required this.accentCool,
    required this.accentMint,
    required this.neutralBlock,
    required this.onPrimary,
    required this.onPositive,
    required this.onNegative,
    required this.onAccentWarm,
    required this.onAccentCool,
    required this.onAccentMint,
    required this.onNeutralBlock,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.borderSubtle,
    required this.hairline,
    required this.engraved,
    required this.positiveBg,
    required this.negativeBg,
    required this.shimmer,
  });

  /// App canvas. Warm parchment (light) / warm ink-graphite (dark).
  final Color background;

  /// A half-step off `background`, for banded/grouped regions on the canvas.
  final Color backgroundTint;

  /// Elevation scale. Elevation reads through lightness and warmth, never
  /// through shadow — there are no drop shadows in this system.
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceRaised;

  /// Warm brass. The one always-on brand hue: nav needle-mark, primary
  /// buttons, section accents, hero surfaces, the gauge needle, the sparkline
  /// stroke, wayfinding marks.
  final Color primary;

  /// Brass held back for large fills and hero surfaces where the full-strength
  /// hue would shout. Never used for text or thin lines.
  final Color primaryMuted;

  /// Gain / loss. Ink-toned verdigris and vermillion-rust; always paired with
  /// a sign in the number and a directional glyph, never color alone.
  final Color positive;
  final Color negative;

  /// "Ember" — the one deliberately vivid, narrowly-used hue. Doubles as the
  /// warning / stale-data / attention semantic. See the ember usage rule:
  /// notable momentum readings, at most one or two "featured" badges, and
  /// time-sensitive states. Never a decorative fill or a rotated card color.
  final Color accentWarm;

  /// Deep cartographic slate — reads as "ink", not as a second brand color.
  /// Informational badges, secondary/outline buttons, neutral trend lines.
  final Color accentCool;

  /// Small-area "new"/fresh marker only (dots, tiny badges). Deliberately
  /// outside the teal/green family so it can never drift back toward reading
  /// as a paler brand color.
  final Color accentMint;

  /// A full-strength ink block, used where a surface needs to invert.
  final Color neutralBlock;

  final Color onPrimary;
  final Color onPositive;
  final Color onNegative;
  final Color onAccentWarm;
  final Color onAccentCool;
  final Color onAccentMint;
  final Color onNeutralBlock;

  /// Text hierarchy. Warm ink / warm off-white — never pure black or white.
  /// All three clear 4.5:1 against their typical surface in both themes.
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  /// Separation. `hairline` is the visible 1px edge on cards and dividers;
  /// `border` / `borderSubtle` are the softer container edges.
  final Color border;
  final Color borderSubtle;
  final Color hairline;

  /// The engraved line-work tone: tick marks, contour lines, dial calibration.
  final Color engraved;

  final Color positiveBg;
  final Color negativeBg;

  /// Skeleton/placeholder fill.
  final Color shimmer;

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? backgroundTint,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceRaised,
    Color? primary,
    Color? primaryMuted,
    Color? positive,
    Color? negative,
    Color? accentWarm,
    Color? accentCool,
    Color? accentMint,
    Color? neutralBlock,
    Color? onPrimary,
    Color? onPositive,
    Color? onNegative,
    Color? onAccentWarm,
    Color? onAccentCool,
    Color? onAccentMint,
    Color? onNeutralBlock,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
    Color? hairline,
    Color? engraved,
    Color? positiveBg,
    Color? negativeBg,
    Color? shimmer,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      backgroundTint: backgroundTint ?? this.backgroundTint,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      primary: primary ?? this.primary,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      accentWarm: accentWarm ?? this.accentWarm,
      accentCool: accentCool ?? this.accentCool,
      accentMint: accentMint ?? this.accentMint,
      neutralBlock: neutralBlock ?? this.neutralBlock,
      onPrimary: onPrimary ?? this.onPrimary,
      onPositive: onPositive ?? this.onPositive,
      onNegative: onNegative ?? this.onNegative,
      onAccentWarm: onAccentWarm ?? this.onAccentWarm,
      onAccentCool: onAccentCool ?? this.onAccentCool,
      onAccentMint: onAccentMint ?? this.onAccentMint,
      onNeutralBlock: onNeutralBlock ?? this.onNeutralBlock,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      hairline: hairline ?? this.hairline,
      engraved: engraved ?? this.engraved,
      positiveBg: positiveBg ?? this.positiveBg,
      negativeBg: negativeBg ?? this.negativeBg,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      background: Color.lerp(background, other.background, t)!,
      backgroundTint: Color.lerp(backgroundTint, other.backgroundTint, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      accentCool: Color.lerp(accentCool, other.accentCool, t)!,
      accentMint: Color.lerp(accentMint, other.accentMint, t)!,
      neutralBlock: Color.lerp(neutralBlock, other.neutralBlock, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onPositive: Color.lerp(onPositive, other.onPositive, t)!,
      onNegative: Color.lerp(onNegative, other.onNegative, t)!,
      onAccentWarm: Color.lerp(onAccentWarm, other.onAccentWarm, t)!,
      onAccentCool: Color.lerp(onAccentCool, other.onAccentCool, t)!,
      onAccentMint: Color.lerp(onAccentMint, other.onAccentMint, t)!,
      onNeutralBlock: Color.lerp(onNeutralBlock, other.onNeutralBlock, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      engraved: Color.lerp(engraved, other.engraved, t)!,
      positiveBg: Color.lerp(positiveBg, other.positiveBg, t)!,
      negativeBg: Color.lerp(negativeBg, other.negativeBg, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

// ─── Spacing (8-pt grid — unchanged) ───────────────────────────────────────
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double screenH = 20;
}

// ─── Radii ──────────────────────────────────────────────────────────────────
// Machined, not bubbly: roughly half the pre-redesign radii. The full
// pill/stadium shape is retired as a default for cards, sheets, and larger
// badges — it survives for genuinely small discrete chips, and as the single
// sanctioned exception for the bottom navigation bar.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double card = 10;
  static const double heroCard = 12;
  static const double lg = 10;
  static const double xl = 14;

  /// Small discrete chips and status badges only.
  static const double pill = 999;

  /// The one sanctioned capsule: the floating navigation bar (§5).
  static const double navBar = 30;

  /// Chamfer depth — the flat corner cut used by instrument-coded elements.
  static const double chamfer = 12;
}

// ─── Motion ─────────────────────────────────────────────────────────────────
// No bounce, no overshoot, no elastic curves — anywhere, ever. Springs in this
// system are critically damped (ratio 1.0): they resolve directly to target
// with zero overshoot, and re-target smoothly when interrupted mid-flight.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  /// Large multi-element sequenced transitions. Sized so a 3–5 element
  /// staggered sequence completes inside ~500–650ms in total.
  static const Duration choreographed = Duration(milliseconds: 600);

  static const Duration splash = Duration(milliseconds: 1200);
  static const Duration navExpand = Duration(milliseconds: 280);
  static const Duration cardEntrance = Duration(milliseconds: 450);
  static const Duration cardStagger = Duration(milliseconds: 50);

  /// One slow single sweep marking freshly-landed live data. Plays once per
  /// update — never loops.
  static const Duration livePulse = Duration(milliseconds: 900);

  /// The needle-sweep and digit-roll settle window.
  static const Duration settle = Duration(milliseconds: 520);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve decel = Curves.decelerate;

  /// Stagger step between elements that change at the same moment (§11).
  static const Duration stagger = Duration(milliseconds: 20);

  /// The needle-mark trails the label reveal rather than firing with it.
  static const Duration needleLag = Duration(milliseconds: 18);
}

// ─── Instrument surfaces ────────────────────────────────────────────────────
// Replaces the old AppGradients. Surfaces are flat, matte and opaque; the only
// gradients left in the system either represent data or shade a dial face for
// depth, which is the one sanctioned "physical" reading (§4.5 #4).
abstract final class AppSurfaces {
  /// A hero surface's flat fill. Brass-led everywhere; Insights and Learn take
  /// a small semantic shift baked into the same base so a sentiment gauge
  /// doesn't read identically to a lesson library.
  static Color heroFill(AyreSection section, AppThemeTokens tokens) {
    return switch (section) {
      AyreSection.home || AyreSection.signals => tokens.primaryMuted,
      AyreSection.insights =>
        Color.lerp(tokens.primaryMuted, tokens.accentCool, 0.22)!,
      AyreSection.learn =>
        Color.lerp(tokens.primaryMuted, tokens.accentWarm, 0.18)!,
      AyreSection.profile => tokens.surfaceRaised,
    };
  }

  /// Foreground for content sitting on [heroFill].
  static Color onHero(AyreSection section, AppThemeTokens tokens) {
    return section == AyreSection.profile ? tokens.textPrimary : tokens.onPrimary;
  }

  /// Shading a dial face for depth — a data surface, not atmosphere.
  static LinearGradient dialFace(AppThemeTokens tokens) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.lerp(tokens.surfaceAlt, tokens.background, 0.35)!,
      tokens.surfaceAlt,
    ],
  );
}

// ─── Typography — three roles, applied without exception ────────────────────
// 1. Instrument-readout monospace: every live market figure, without exception.
// 2. Display serif: screen titles, section eyebrows and headings as a voice —
//    and a numeral in exactly two places (Home's momentum score, the splash
//    wordmark), nowhere else.
// 3. Inter: body copy, list-row labels, buttons, categorical micro-labels.
abstract final class AppTypo {
  static TextStyle inter({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// The engraved display serif. Reserved per the role rules above.
  static TextStyle serif({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.fraunces(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// The instrument readout. Tabular figures mean a live-updating number never
  /// reflows its neighbours on refresh.
  static TextStyle mono({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ── Serif roles ──────────────────────────────────────────────────────────

  /// Home's momentum score and the splash wordmark. The only two places a
  /// numeral may render in the serif.
  static TextStyle heroSerif(AppThemeTokens tokens, {Color? color}) => serif(
    fontSize: 60,
    fontWeight: FontWeight.w600,
    color: color ?? tokens.textPrimary,
    height: 1.0,
    letterSpacing: -1.6,
  );

  static TextStyle pageTitle(AppThemeTokens tokens, {Color? color}) => serif(
    fontSize: 27,
    fontWeight: FontWeight.w600,
    color: color ?? tokens.textPrimary,
    height: 1.18,
    letterSpacing: -0.4,
  );

  static TextStyle sectionTitle(AppThemeTokens tokens, {Color? color}) => serif(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: color ?? tokens.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// Section headers ("TOP GAINERS"). The serif as a structural voice.
  static TextStyle sectionEyebrow(AppThemeTokens tokens, {Color? color}) =>
      serif(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? tokens.textSecondary,
        letterSpacing: 0.7,
      );

  // ── Monospace roles ──────────────────────────────────────────────────────

  /// Every live market figure. Prefer the shared `Numeral` widget over calling
  /// this directly, so no screen can accidentally fall back to Inter.
  static TextStyle dataNum(
    AppThemeTokens tokens, {
    Color? color,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
  }) => mono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? tokens.textPrimary,
    letterSpacing: -0.2,
  );

  /// "as of 15:31" freshness markers and chart axis labels.
  static TextStyle dataMeta(AppThemeTokens tokens, {Color? color}) => mono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: color ?? tokens.textTertiary,
    letterSpacing: 0.1,
  );

  // ── Inter roles ──────────────────────────────────────────────────────────

  static TextStyle cardTitle(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? tokens.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle body(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? tokens.textSecondary,
    height: 1.45,
    letterSpacing: -0.1,
  );

  static TextStyle bodyMedium(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? tokens.textSecondary,
    height: 1.45,
    letterSpacing: -0.1,
  );

  /// All-caps categorical micro-labels ("NIFTY 50", "SUBJECTS"). Never a live
  /// figure — those go to [dataNum].
  static TextStyle microLabel(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color ?? tokens.textTertiary,
    letterSpacing: 0.7,
  );

  static TextStyle caption(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? tokens.textTertiary,
    height: 1.35,
  );
}

// ─── Theme builder ──────────────────────────────────────────────────────────
abstract final class AppTheme {
  static const Color transparent = Color(0x00000000);

  // Light — warm parchment. Tuned against its own background, not as an
  // inversion of dark: same semantic roles, same hue identity, different
  // numbers.
  static const _lightTokens = AppThemeTokens(
    background: Color(0xFFF7F3EA),
    backgroundTint: Color(0xFFF1EBDE),
    surface: Color(0xFFFDFAF3),
    surfaceAlt: Color(0xFFF2ECDF),
    surfaceRaised: Color(0xFFFFFDF7),
    primary: Color(0xFF8C6414),
    primaryMuted: Color(0xFF6E4E10),
    positive: Color(0xFF2F6B4F),
    negative: Color(0xFFA32C22),
    accentWarm: Color(0xFFB3441A),
    accentCool: Color(0xFF3F5568),
    accentMint: Color(0xFF6B4A7A),
    neutralBlock: Color(0xFF241F17),
    onPrimary: Color(0xFFFDFAF3),
    onPositive: Color(0xFFFDFAF3),
    onNegative: Color(0xFFFDFAF3),
    onAccentWarm: Color(0xFFFDFAF3),
    onAccentCool: Color(0xFFFDFAF3),
    onAccentMint: Color(0xFFFDFAF3),
    onNeutralBlock: Color(0xFFF7F3EA),
    textPrimary: Color(0xFF241F17),
    textSecondary: Color(0xFF5C5346),
    textTertiary: Color(0xFF6E6455),
    textDisabled: Color(0xFFA79C89),
    border: Color(0x24241F17),
    borderSubtle: Color(0x12241F17),
    hairline: Color(0x33241F17),
    engraved: Color(0x59241F17),
    positiveBg: Color(0x162F6B4F),
    negativeBg: Color(0x16A32C22),
    shimmer: Color(0xFFEDE6D7),
  );

  // Dark — warm ink / graphite. Never blue-tinted black.
  static const _darkTokens = AppThemeTokens(
    background: Color(0xFF100D0A),
    backgroundTint: Color(0xFF15110D),
    surface: Color(0xFF1B1710),
    surfaceAlt: Color(0xFF231E16),
    surfaceRaised: Color(0xFF2B251B),
    primary: Color(0xFFD8A73E),
    primaryMuted: Color(0xFF6B5220),
    positive: Color(0xFF5FB58C),
    negative: Color(0xFFE8705F),
    accentWarm: Color(0xFFE2703C),
    accentCool: Color(0xFF8FA6BC),
    accentMint: Color(0xFFB08AC4),
    neutralBlock: Color(0xFFF4EEE1),
    onPrimary: Color(0xFF100D0A),
    onPositive: Color(0xFF100D0A),
    onNegative: Color(0xFF100D0A),
    onAccentWarm: Color(0xFF100D0A),
    onAccentCool: Color(0xFF100D0A),
    onAccentMint: Color(0xFF100D0A),
    onNeutralBlock: Color(0xFF100D0A),
    textPrimary: Color(0xFFF4EEE1),
    textSecondary: Color(0xFFB5AB99),
    textTertiary: Color(0xFF8B8172),
    textDisabled: Color(0xFF5A5346),
    border: Color(0x24F4EEE1),
    borderSubtle: Color(0x12F4EEE1),
    hairline: Color(0x33F4EEE1),
    engraved: Color(0x66F4EEE1),
    positiveBg: Color(0x1F5FB58C),
    negativeBg: Color(0x1FE8705F),
    shimmer: Color(0xFF231E16),
  );

  static AppThemeTokens get lightTokens => _lightTokens;
  static AppThemeTokens get darkTokens => _darkTokens;

  static ThemeData get dark => _build(Brightness.dark, _darkTokens);
  static ThemeData get light => _build(Brightness.light, _lightTokens);

  static ThemeData _build(Brightness brightness, AppThemeTokens tokens) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: tokens.accentCool,
      onSecondary: tokens.onAccentCool,
      tertiary: tokens.accentWarm,
      onTertiary: tokens.onAccentWarm,
      error: tokens.negative,
      onError: tokens.onNegative,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
    );

    // Titles and headings take the serif voice; body, labels and chrome stay
    // on Inter. Numerals never come from the TextTheme — they go through the
    // `Numeral` widget so the monospace rule can't be bypassed.
    final textTheme = TextTheme(
      displayLarge: AppTypo.serif(fontSize: 38, color: tokens.textPrimary, letterSpacing: -0.9),
      displayMedium: AppTypo.serif(fontSize: 32, color: tokens.textPrimary, letterSpacing: -0.7),
      displaySmall: AppTypo.serif(fontSize: 27, color: tokens.textPrimary, letterSpacing: -0.5),
      headlineLarge: AppTypo.serif(fontSize: 23, color: tokens.textPrimary, letterSpacing: -0.4),
      headlineMedium: AppTypo.serif(fontSize: 20, color: tokens.textPrimary, letterSpacing: -0.3),
      headlineSmall: AppTypo.serif(fontSize: 18, color: tokens.textPrimary, letterSpacing: -0.2),
      titleLarge: AppTypo.serif(fontSize: 17, color: tokens.textPrimary),
      titleMedium: AppTypo.inter(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.1),
      titleSmall: AppTypo.inter(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textPrimary),
      bodyLarge: AppTypo.inter(fontSize: 16, color: tokens.textPrimary, height: 1.5),
      bodyMedium: AppTypo.inter(fontSize: 14, color: tokens.textSecondary, height: 1.45),
      bodySmall: AppTypo.inter(fontSize: 12, color: tokens.textTertiary, height: 1.4),
      labelLarge: AppTypo.inter(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textPrimary),
      labelMedium: AppTypo.inter(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textSecondary, letterSpacing: 0.2),
      labelSmall: AppTypo.microLabel(tokens),
    );

    final base = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.background,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: tokens.hairline,
      cardColor: tokens.surface,
      dividerTheme: DividerThemeData(
        color: tokens.hairline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shadowColor: transparent,
        surfaceTintColor: transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: tokens.borderSubtle),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypo.sectionTitle(tokens),
        surfaceTintColor: transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceAlt,
        labelStyle: AppTypo.body(tokens),
        floatingLabelStyle: AppTypo.bodyMedium(tokens, color: tokens.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypo.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.accentCool,
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypo.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        circularTrackColor: tokens.surfaceAlt,
        linearTrackColor: tokens.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.onPositive
              : tokens.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.positive
              : tokens.surfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppTheme.transparent
              : tokens.border;
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.windows: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.linux: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.fuchsia: _SlideFadePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Horizontal slide-in plus a subtle fade — the standing convention for every
/// pushed screen (Profile → Settings, → Edit Profile, and anything added
/// later). No overshoot.
class _SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.ease,
      reverseCurve: AppMotion.easeIn,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
