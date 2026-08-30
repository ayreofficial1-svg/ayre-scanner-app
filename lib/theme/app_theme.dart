import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── "Cinder & Citrine" ─────────────────────────────────────────────────────
//
// A market-terminal identity: cool ink/graphite/paper surfaces, one ownable
// brand hue (Citrine), and market data rendered as terminal readouts.
//
// The base hue family is deliberately COOL. Nothing warm-neutral, cream, brown,
// brass or bronze appears anywhere. There are no gradients, no glows, no
// translucency and no drop shadows — elevation reads through a tight lightness
// scale plus 1px hairlines.
//
// Three greens exist and they never trade jobs:
//   • Citrine — brand only. Warm, mineral, yellow-leaning. Never attached to a
//     numeric market value, never carries a +/− sign.
//   • Jade    — gain only. Cool, blue-leaning, saturated. Always with + and an
//     up-glyph on a numeric value.
//   • Garnet  — loss only. Deep and wine-toned. Always with − and a down-glyph.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.background,
    required this.backgroundTint,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.inkPanel,
    required this.onInkPanel,
    required this.citrine,
    required this.citrineInk,
    required this.citrineMuted,
    required this.onCitrine,
    required this.jade,
    required this.garnet,
    required this.ember,
    required this.slateViolet,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.borderSubtle,
    required this.hairline,
    required this.positiveBg,
    required this.negativeBg,
    required this.emberBg,
    required this.chartGrid,
    required this.chartLine,
    required this.skeleton,
  });

  /// App canvas. Fogpaper (cool off-white, graphite undertone) in light;
  /// Cinder (true near-black graphite) in dark.
  final Color background;

  /// A half-step off [background] for banded or grouped regions.
  final Color backgroundTint;

  /// Elevation scale — a tight ascending series kept close together for calm,
  /// low-glare reading. Never paired with a shadow.
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceRaised;

  /// The "terminal readout" panel embedded in a card: the one deliberately
  /// near-black surface in light mode, and a cooler inset panel in dark.
  final Color inkPanel;
  final Color onInkPanel;

  /// The brand hue as a solid fill. Identity only: the Fold's focal control,
  /// primary buttons, selected states, the hero card's accent edge.
  final Color citrine;

  /// Citrine dark enough to be text or a thin line. The light-mode fill tone is
  /// too light to clear 4.5:1 as small text, so anything type-weight — links,
  /// selected labels, small icons — uses this instead.
  final Color citrineInk;

  /// Citrine held back for large, low-emphasis fills.
  final Color citrineMuted;

  /// Ink text on a Citrine fill. Citrine is light, so inverted white text would
  /// under-perform; this is deliberately dark.
  final Color onCitrine;

  /// Gain. Cool and blue-leaning so it never reads as Citrine.
  final Color jade;

  /// Loss. Deep and wine-toned rather than a flat alert red.
  final Color garnet;

  /// Attention: the LIVE dot, delayed/stale chips, offline notices. Never a
  /// button fill, never navigation, never the brand.
  final Color ember;

  /// Informational secondary. Small-area only — a "NEW" tag, a category label.
  /// Never a large fill, never navigation, never a button.
  final Color slateViolet;

  /// Cool graphite through muted grey. All clear 4.5:1 on their surfaces.
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  /// 1px structure. [hairline] is the visible card and divider edge.
  final Color border;
  final Color borderSubtle;
  final Color hairline;

  /// Faint tint fields behind movers rows and semantic badges.
  final Color positiveBg;
  final Color negativeBg;
  final Color emberBg;

  /// Near-invisible chart grid; neutral trace for non-featured charts.
  final Color chartGrid;
  final Color chartLine;

  final Color skeleton;

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? backgroundTint,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceRaised,
    Color? inkPanel,
    Color? onInkPanel,
    Color? citrine,
    Color? citrineInk,
    Color? citrineMuted,
    Color? onCitrine,
    Color? jade,
    Color? garnet,
    Color? ember,
    Color? slateViolet,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
    Color? hairline,
    Color? positiveBg,
    Color? negativeBg,
    Color? emberBg,
    Color? chartGrid,
    Color? chartLine,
    Color? skeleton,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      backgroundTint: backgroundTint ?? this.backgroundTint,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      inkPanel: inkPanel ?? this.inkPanel,
      onInkPanel: onInkPanel ?? this.onInkPanel,
      citrine: citrine ?? this.citrine,
      citrineInk: citrineInk ?? this.citrineInk,
      citrineMuted: citrineMuted ?? this.citrineMuted,
      onCitrine: onCitrine ?? this.onCitrine,
      jade: jade ?? this.jade,
      garnet: garnet ?? this.garnet,
      ember: ember ?? this.ember,
      slateViolet: slateViolet ?? this.slateViolet,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      hairline: hairline ?? this.hairline,
      positiveBg: positiveBg ?? this.positiveBg,
      negativeBg: negativeBg ?? this.negativeBg,
      emberBg: emberBg ?? this.emberBg,
      chartGrid: chartGrid ?? this.chartGrid,
      chartLine: chartLine ?? this.chartLine,
      skeleton: skeleton ?? this.skeleton,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeTokens(
      background: c(background, other.background),
      backgroundTint: c(backgroundTint, other.backgroundTint),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      inkPanel: c(inkPanel, other.inkPanel),
      onInkPanel: c(onInkPanel, other.onInkPanel),
      citrine: c(citrine, other.citrine),
      citrineInk: c(citrineInk, other.citrineInk),
      citrineMuted: c(citrineMuted, other.citrineMuted),
      onCitrine: c(onCitrine, other.onCitrine),
      jade: c(jade, other.jade),
      garnet: c(garnet, other.garnet),
      ember: c(ember, other.ember),
      slateViolet: c(slateViolet, other.slateViolet),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textDisabled: c(textDisabled, other.textDisabled),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      hairline: c(hairline, other.hairline),
      positiveBg: c(positiveBg, other.positiveBg),
      negativeBg: c(negativeBg, other.negativeBg),
      emberBg: c(emberBg, other.emberBg),
      chartGrid: c(chartGrid, other.chartGrid),
      chartLine: c(chartLine, other.chartLine),
      skeleton: c(skeleton, other.skeleton),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

// ─── Spacing (8pt grid, retained as a system) ───────────────────────────────
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

  /// Terminal-row vertical padding — dense and scannable by design.
  static const double row = 10;
}

// ─── Radii ─────────────────────────────────────────────────────────────────
// Crisper than the previous identity: a terminal card, not a soft app card.
// The full capsule is not a default anywhere — it survives only for genuinely
// circular controls and small status chips.
abstract final class AppRadius {
  static const double chip = 3;
  static const double panel = 4;
  static const double card = 6;
  static const double button = 6;
  static const double control = 8;
  static const double sheet = 12;

  /// The Fold's expanded tray.
  static const double dock = 20;

  static const double circle = 999;
}

// ─── Motion ────────────────────────────────────────────────────────────────
// No bounce, no overshoot, ever. Springs are critically damped (ratio 1.0):
// they resolve straight to target and re-target smoothly when interrupted.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 170);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 400);

  /// The Fold's unfold/fold shape transition.
  static const Duration fold = Duration(milliseconds: 320);

  /// How long the expanded dock waits before folding itself away again.
  static const Duration foldIdle = Duration(seconds: 4);

  /// A changed figure settling to its new value.
  static const Duration digitRoll = Duration(milliseconds: 420);

  /// A ticker trace drawing itself on.
  static const Duration traceDraw = Duration(milliseconds: 620);

  /// One cycle of the LIVE dot's pulse.
  static const Duration livePulse = Duration(milliseconds: 1600);

  static const Duration entrance = Duration(milliseconds: 380);
  static const Duration stagger = Duration(milliseconds: 40);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
}

// ─── Typography ────────────────────────────────────────────────────────────
// Three faces, three jobs, no overlap:
//   • Space Grotesk — display. Screen titles, index names, course titles.
//   • JetBrains Mono — ticker. EVERY numeric market value, without exception.
//   • Manrope — UI. Body copy, labels, buttons, settings rows.
abstract final class AppTypo {
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing ?? -0.4,
  );

  /// Tabular figures mean columns of numbers align and a live value never
  /// reflows its neighbours when it updates.
  static TextStyle ticker({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing ?? -0.3,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle ui({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  // ── Display roles ────────────────────────────────────────────────────────

  static TextStyle pageTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
    height: 1.14,
    letterSpacing: -0.7,
  );

  static TextStyle sectionTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
    height: 1.22,
    letterSpacing: -0.4,
  );

  static TextStyle cardTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // ── Ticker roles ─────────────────────────────────────────────────────────

  /// The largest data text in the app — index and equity levels. Deliberately
  /// larger than any heading.
  static TextStyle heroValue(AppThemeTokens t, {Color? color}) => ticker(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    height: 1.0,
    letterSpacing: -1.2,
  );

  static TextStyle value(
    AppThemeTokens t, {
    Color? color,
    double fontSize = 14,
  }) => ticker(
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
    color: color ?? t.textPrimary,
  );

  static TextStyle valueSmall(AppThemeTokens t, {Color? color}) => ticker(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: color ?? t.textTertiary,
    letterSpacing: 0,
  );

  // ── UI roles ─────────────────────────────────────────────────────────────

  static TextStyle body(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: color ?? t.textSecondary,
    height: 1.45,
  );

  static TextStyle bodyStrong(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    height: 1.4,
  );

  static TextStyle rowLabel(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    letterSpacing: -0.1,
  );

  static TextStyle caption(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? t.textTertiary,
    height: 1.35,
  );

  /// The terminal-label convention: small, uppercase, wide-tracked, tertiary.
  /// Sits above every data value and heads every section.
  static TextStyle label(
    AppThemeTokens t, {
    Color? color,
    double fontSize = 10,
  }) => ui(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color ?? t.textTertiary,
    letterSpacing: 1.1,
  );

  static TextStyle button(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.1,
  );
}

// ─── Theme builder ─────────────────────────────────────────────────────────
abstract final class AppTheme {
  static const Color transparent = Color(0x00000000);

  // Fogpaper — cool off-white with a graphite undertone. Not cream, not stark.
  static const _light = AppThemeTokens(
    background: Color(0xFFF4F5F7),
    backgroundTint: Color(0xFFEBEDF1),
    surface: Color(0xFFFBFBFD),
    surfaceAlt: Color(0xFFEFF1F4),
    surfaceRaised: Color(0xFFFFFFFF),
    inkPanel: Color(0xFF12151A),
    onInkPanel: Color(0xFFEDEFF2),
    citrine: Color(0xFFBFCB2E),
    citrineInk: Color(0xFF65700C),
    citrineMuted: Color(0xFFE4E9A8),
    onCitrine: Color(0xFF141712),
    jade: Color(0xFF0F7F5B),
    garnet: Color(0xFFA32036),
    ember: Color(0xFFA85B12),
    slateViolet: Color(0xFF5B5488),
    textPrimary: Color(0xFF14171C),
    textSecondary: Color(0xFF565E6B),
    textTertiary: Color(0xFF666E7A),
    textDisabled: Color(0xFFA0A7B1),
    border: Color(0x1F14171C),
    borderSubtle: Color(0x1214171C),
    hairline: Color(0x2E14171C),
    positiveBg: Color(0x140F7F5B),
    negativeBg: Color(0x14A32036),
    emberBg: Color(0x16A85B12),
    chartGrid: Color(0x1214171C),
    chartLine: Color(0xFF565E6B),
    skeleton: Color(0xFFE4E7EC),
  );

  // Cinder — a trading desk at night. True near-black, no warm undertone.
  static const _dark = AppThemeTokens(
    background: Color(0xFF0B0C0E),
    backgroundTint: Color(0xFF101216),
    surface: Color(0xFF14171B),
    surfaceAlt: Color(0xFF1A1E23),
    surfaceRaised: Color(0xFF22262C),
    inkPanel: Color(0xFF0A0D11),
    onInkPanel: Color(0xFFEDEFF2),
    citrine: Color(0xFFC9D137),
    citrineInk: Color(0xFFC9D137),
    citrineMuted: Color(0xFF5C6220),
    onCitrine: Color(0xFF0B0C0E),
    jade: Color(0xFF22C58A),
    garnet: Color(0xFFDE5B6A),
    ember: Color(0xFFE08A3C),
    slateViolet: Color(0xFF9A93C4),
    textPrimary: Color(0xFFEDEFF2),
    textSecondary: Color(0xFFA2A9B4),
    textTertiary: Color(0xFF868E9A),
    textDisabled: Color(0xFF4E545E),
    border: Color(0x1FFFFFFF),
    borderSubtle: Color(0x12FFFFFF),
    hairline: Color(0x2EFFFFFF),
    positiveBg: Color(0x1F22C58A),
    negativeBg: Color(0x1FDE5B6A),
    emberBg: Color(0x1FE08A3C),
    chartGrid: Color(0x12FFFFFF),
    chartLine: Color(0xFFA2A9B4),
    skeleton: Color(0xFF1E2228),
  );

  static AppThemeTokens get lightTokens => _light;
  static AppThemeTokens get darkTokens => _dark;

  static ThemeData get light => _build(Brightness.light, _light);
  static ThemeData get dark => _build(Brightness.dark, _dark);

  static ThemeData _build(Brightness brightness, AppThemeTokens t) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.citrine,
      onPrimary: t.onCitrine,
      secondary: t.slateViolet,
      onSecondary: isDark ? t.background : const Color(0xFFFFFFFF),
      tertiary: t.ember,
      onTertiary: isDark ? t.background : const Color(0xFFFFFFFF),
      error: t.garnet,
      onError: isDark ? t.background : const Color(0xFFFFFFFF),
      surface: t.surface,
      onSurface: t.textPrimary,
    );

    // Headings take the display face; body and chrome take the UI face.
    // Numerals never come from the TextTheme — they route through `Figure`
    // so the monospace rule cannot be bypassed.
    final text = TextTheme(
      displayLarge: AppTypo.display(fontSize: 34, color: t.textPrimary, letterSpacing: -1.0),
      displayMedium: AppTypo.display(fontSize: 29, color: t.textPrimary, letterSpacing: -0.8),
      displaySmall: AppTypo.display(fontSize: 26, color: t.textPrimary, letterSpacing: -0.7),
      headlineLarge: AppTypo.display(fontSize: 22, color: t.textPrimary, letterSpacing: -0.5),
      headlineMedium: AppTypo.display(fontSize: 19, color: t.textPrimary, letterSpacing: -0.4),
      headlineSmall: AppTypo.display(fontSize: 17, color: t.textPrimary, letterSpacing: -0.3),
      titleLarge: AppTypo.display(fontSize: 16, color: t.textPrimary, letterSpacing: -0.2),
      titleMedium: AppTypo.ui(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary),
      titleSmall: AppTypo.ui(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary),
      bodyLarge: AppTypo.ui(fontSize: 15, color: t.textPrimary, height: 1.5),
      bodyMedium: AppTypo.body(t),
      bodySmall: AppTypo.caption(t),
      labelLarge: AppTypo.button(t, color: t.textPrimary),
      labelMedium: AppTypo.ui(fontSize: 12, fontWeight: FontWeight.w600, color: t.textSecondary),
      labelSmall: AppTypo.label(t),
    );

    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [t],
      scaffoldBackgroundColor: t.background,
    );

    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      dividerColor: t.hairline,
      dividerTheme: DividerThemeData(color: t.hairline, thickness: 1, space: 1),
      cardColor: t.surface,
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        shadowColor: transparent,
        surfaceTintColor: transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: t.borderSubtle),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.sm,
        titleTextStyle: AppTypo.sectionTitle(t),
        surfaceTintColor: transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceAlt,
        hintStyle: AppTypo.body(t, color: t.textTertiary),
        labelStyle: AppTypo.body(t),
        floatingLabelStyle: AppTypo.body(t, color: t.citrineInk),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.citrineInk, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.garnet),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.garnet, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.citrineInk,
        circularTrackColor: t.surfaceAlt,
        linearTrackColor: t.surfaceAlt,
        linearMinHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surfaceRaised,
        contentTextStyle: AppTypo.bodyStrong(t),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: t.border),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.citrineInk,
        selectionColor: t.citrine.withValues(alpha: 0.3),
        selectionHandleColor: t.citrineInk,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: TerminalPageTransitions(),
          TargetPlatform.iOS: TerminalPageTransitions(),
          TargetPlatform.macOS: TerminalPageTransitions(),
          TargetPlatform.windows: TerminalPageTransitions(),
          TargetPlatform.linux: TerminalPageTransitions(),
          TargetPlatform.fuchsia: TerminalPageTransitions(),
        },
      ),
    );
  }
}

/// Direction-aware push/pop with no overshoot. The detail screen slides in over
/// the list it came from and the list drifts back slightly, so
/// Home → Index Detail → Equity Detail reads as one continuous drill-down
/// rather than three unrelated screens appearing.
class TerminalPageTransitions extends PageTransitionsBuilder {
  const TerminalPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppMotion.ease,
      reverseCurve: AppMotion.easeIn,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.ease,
      reverseCurve: AppMotion.easeIn,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.16, 0),
      ).animate(outgoing),
      child: FadeTransition(
        opacity: incoming,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(incoming),
          child: child,
        ),
      ),
    );
  }
}
