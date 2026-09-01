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
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.onAccent,
    required this.gain,
    required this.loss,
    required this.caution,
    required this.info,
    required this.fillMint,
    required this.fillClay,
    required this.fillSand,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.borderSubtle,
    required this.hairline,
    required this.gainSoft,
    required this.lossSoft,
    required this.cautionSoft,
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
  final Color accent;

  /// Citrine dark enough to be text or a thin line. The light-mode fill tone is
  /// too light to clear 4.5:1 as small text, so anything type-weight — links,
  /// selected labels, small icons — uses this instead.
  final Color accentInk;

  /// Citrine held back for large, low-emphasis fills.
  final Color accentSoft;

  /// Ink text on a Citrine fill. Citrine is light, so inverted white text would
  /// under-perform; this is deliberately dark.
  final Color onAccent;

  /// Gain. Cool and blue-leaning so it never reads as Citrine.
  final Color gain;

  /// Loss. Deep and wine-toned rather than a flat alert red.
  final Color loss;

  /// Attention: the LIVE dot, delayed/stale chips, offline notices. Never a
  /// button fill, never navigation, never the brand.
  final Color caution;

  /// Informational secondary. Small-area only — a "NEW" tag, a category label.
  /// Never a large fill, never navigation, never a button.
  final Color info;

  /// Three soft, low-saturation card fills. Used to pick out a small number of
  /// cards as gentle highlight blocks against the neutral canvas — the one place
  /// colour does hierarchy work. Never more than two on a screen, and never for
  /// a control, a chip, or anything semantic.
  final Color fillMint;
  final Color fillClay;
  final Color fillSand;

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
  final Color gainSoft;
  final Color lossSoft;
  final Color cautionSoft;

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
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? onAccent,
    Color? gain,
    Color? loss,
    Color? caution,
    Color? info,
    Color? fillMint,
    Color? fillClay,
    Color? fillSand,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderSubtle,
    Color? hairline,
    Color? gainSoft,
    Color? lossSoft,
    Color? cautionSoft,
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
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      gain: gain ?? this.gain,
      loss: loss ?? this.loss,
      caution: caution ?? this.caution,
      info: info ?? this.info,
      fillMint: fillMint ?? this.fillMint,
      fillClay: fillClay ?? this.fillClay,
      fillSand: fillSand ?? this.fillSand,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      hairline: hairline ?? this.hairline,
      gainSoft: gainSoft ?? this.gainSoft,
      lossSoft: lossSoft ?? this.lossSoft,
      cautionSoft: cautionSoft ?? this.cautionSoft,
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
      accent: c(accent, other.accent),
      accentInk: c(accentInk, other.accentInk),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccent: c(onAccent, other.onAccent),
      gain: c(gain, other.gain),
      loss: c(loss, other.loss),
      caution: c(caution, other.caution),
      info: c(info, other.info),
      fillMint: c(fillMint, other.fillMint),
      fillClay: c(fillClay, other.fillClay),
      fillSand: c(fillSand, other.fillSand),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textDisabled: c(textDisabled, other.textDisabled),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      hairline: c(hairline, other.hairline),
      gainSoft: c(gainSoft, other.gainSoft),
      lossSoft: c(lossSoft, other.lossSoft),
      cautionSoft: c(cautionSoft, other.cautionSoft),
      chartGrid: c(chartGrid, other.chartGrid),
      chartLine: c(chartLine, other.chartLine),
      skeleton: c(skeleton, other.skeleton),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

// ─── Radii ─────────────────────────────────────────────────────────────────
// Crisper than the previous identity: a terminal card, not a soft app card.
// The full capsule is not a default anywhere — it survives only for genuinely
// circular controls and small status chips.
abstract final class AppRadius {
  /// Chunky, generous corners — soft rounded rectangles rather than crisp ones.
  /// A deliberate reversal of the previous identity's machined 4–6pt radii.
  static const double chip = 10;
  static const double panel = 14;
  static const double control = 14;
  static const double card = 20;
  static const double hero = 26;
  static const double sheet = 28;

  /// Pill-shaped controls are a recurring pattern across the references, so the
  /// capsule is a sanctioned button shape here rather than a retired one.
  static const double pill = 999;
  static const double circle = 999;

  /// Retained aliases so existing call sites keep their intent.
  static const double button = pill;
  static const double dock = 30;
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

/// The type scale.
///
/// φ (1.6180339887…) sets the two relationships that carry the hierarchy:
/// body → section heading is one φ step (14 × φ ≈ 22.7 → 22), and body → hero
/// figure is two (14 × φ² ≈ 36.6 → 38, nudged up so one oversized hero number
/// per screen reads as genuinely oversized).
///
/// The intermediate sizes are chosen for legibility rather than derived, because
/// a strict geometric run at this range produces steps too far apart to be
/// usable. The golden ratio is a tool here, not a mandate — its design
/// applications are partly documented and partly disputed, so it earns its place
/// where it visibly helps and is set aside where it would hurt.
abstract final class AppTextScale {
  static const double phi = 1.6180339887;

  static const double micro = 11;
  static const double caption = 12;

  /// The base size every other step is reasoned from.
  static const double body = 14;

  static const double rowLabel = 15;
  static const double cardTitle = 17;

  /// body × φ
  static const double section = 22;
  static const double page = 28;

  /// ≈ body × φ²
  static const double hero = 38;
  static const double heroXL = 46;
}

/// The spacing scale.
///
/// Fibonacci steps, whose ratio converges on φ, chosen because they land on or
/// near 8pt-grid values (8, 34) rather than fighting it. Touch targets and
/// safe-area insets use the 8pt values directly.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 5;
  static const double sm = 8;
  static const double md = 13;
  static const double lg = 21;
  static const double xl = 34;
  static const double xxl = 55;

  /// Terminal-row vertical padding — dense and scannable by design.
  static const double row = 10;

  /// The minimum tappable dimension. 48 rather than a Fibonacci step, because
  /// accessibility floors are not negotiable against a ratio.
  static const double minTarget = 48;
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
    fontSize: AppTextScale.page,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
    height: 1.14,
    letterSpacing: -0.7,
  );

  static TextStyle sectionTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: AppTextScale.section,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
    height: 1.22,
    letterSpacing: -0.4,
  );

  static TextStyle cardTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: AppTextScale.cardTitle,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // ── Ticker roles ─────────────────────────────────────────────────────────

  /// The largest data text in the app — index and equity levels. Deliberately
  /// larger than any heading.
  static TextStyle heroValue(AppThemeTokens t, {Color? color}) => ticker(
    fontSize: AppTextScale.hero,
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

  // Paper — a cool, deliberately-crafted light theme, not an inverted dark one.
  static const _light = AppThemeTokens(
    background: Color(0xFFF5F6F8),
    backgroundTint: Color(0xFFEBEEF2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F2F5),
    surfaceRaised: Color(0xFFFFFFFF),
    inkPanel: Color(0xFF0F1318),
    onInkPanel: Color(0xFFE5E7EB),
    accent: Color(0xFF07C58F),
    accentInk: Color(0xFF046B4E),
    accentSoft: Color(0xFFD6F3E8),
    onAccent: Color(0xFF04241A),
    gain: Color(0xFF0A7A5A),
    loss: Color(0xFFA82633),
    caution: Color(0xFF9A5A0F),
    info: Color(0xFF4C5B72),
    fillMint: Color(0xFFDFF1E9),
    fillClay: Color(0xFFF7E4E8),
    fillSand: Color(0xFFF7EEDC),
    textPrimary: Color(0xFF111418),
    textSecondary: Color(0xFF4E5661),
    textTertiary: Color(0xFF646D79),
    textDisabled: Color(0xFFA8B0BA),
    border: Color(0x1F111418),
    borderSubtle: Color(0x14111418),
    hairline: Color(0x2E111418),
    gainSoft: Color(0x140A7A5A),
    lossSoft: Color(0x14A82633),
    cautionSoft: Color(0x169A5A0F),
    chartGrid: Color(0x12111418),
    chartLine: Color(0xFF4E5661),
    skeleton: Color(0xFFE4E7EC),
  );

  // Slate — the logo's own canvas, extended into a full dark theme.
  static const _dark = AppThemeTokens(
    background: Color(0xFF0A0C10),
    backgroundTint: Color(0xFF0F1216),
    surface: Color(0xFF14181D),
    surfaceAlt: Color(0xFF1B2027),
    surfaceRaised: Color(0xFF232932),
    inkPanel: Color(0xFF07090C),
    onInkPanel: Color(0xFFE5E7EB),
    accent: Color(0xFF07C58F),
    accentInk: Color(0xFF0FD79C),
    accentSoft: Color(0xFF0B3D30),
    onAccent: Color(0xFF04120D),
    gain: Color(0xFF12CE95),
    loss: Color(0xFFDE6B73),
    caution: Color(0xFFE0A03C),
    info: Color(0xFF8FA8C4),
    fillMint: Color(0xFF16302A),
    fillClay: Color(0xFF33222A),
    fillSand: Color(0xFF302A1B),
    textPrimary: Color(0xFFE5E7EB),
    textSecondary: Color(0xFFA3ACB9),
    textTertiary: Color(0xFF8A93A0),
    textDisabled: Color(0xFF525A66),
    border: Color(0x1FE5E7EB),
    borderSubtle: Color(0x14E5E7EB),
    hairline: Color(0x2EE5E7EB),
    gainSoft: Color(0x1F12CE95),
    lossSoft: Color(0x1FDE6B73),
    cautionSoft: Color(0x1FE0A03C),
    chartGrid: Color(0x12E5E7EB),
    chartLine: Color(0xFFA3ACB9),
    skeleton: Color(0xFF1D232B),
  );

  static AppThemeTokens get lightTokens => _light;
  static AppThemeTokens get darkTokens => _dark;

  static ThemeData get light => _build(Brightness.light, _light);
  static ThemeData get dark => _build(Brightness.dark, _dark);

  static ThemeData _build(Brightness brightness, AppThemeTokens t) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      secondary: t.info,
      onSecondary: isDark ? t.background : const Color(0xFFFFFFFF),
      tertiary: t.caution,
      onTertiary: isDark ? t.background : const Color(0xFFFFFFFF),
      error: t.loss,
      onError: isDark ? t.background : const Color(0xFFFFFFFF),
      surface: t.surface,
      onSurface: t.textPrimary,
    );

    // Headings take the display face; body and chrome take the UI face.
    // Numerals never come from the TextTheme — they route through `Figure`
    // so the monospace rule cannot be bypassed.
    final text = TextTheme(
      displayLarge: AppTypo.display(
        fontSize: 34,
        color: t.textPrimary,
        letterSpacing: -1.0,
      ),
      displayMedium: AppTypo.display(
        fontSize: 29,
        color: t.textPrimary,
        letterSpacing: -0.8,
      ),
      displaySmall: AppTypo.display(
        fontSize: 26,
        color: t.textPrimary,
        letterSpacing: -0.7,
      ),
      headlineLarge: AppTypo.display(
        fontSize: 22,
        color: t.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: AppTypo.display(
        fontSize: 19,
        color: t.textPrimary,
        letterSpacing: -0.4,
      ),
      headlineSmall: AppTypo.display(
        fontSize: 17,
        color: t.textPrimary,
        letterSpacing: -0.3,
      ),
      titleLarge: AppTypo.display(
        fontSize: 16,
        color: t.textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: AppTypo.ui(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: t.textPrimary,
      ),
      titleSmall: AppTypo.ui(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: t.textPrimary,
      ),
      bodyLarge: AppTypo.ui(fontSize: 15, color: t.textPrimary, height: 1.5),
      bodyMedium: AppTypo.body(t),
      bodySmall: AppTypo.caption(t),
      labelLarge: AppTypo.button(t, color: t.textPrimary),
      labelMedium: AppTypo.ui(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: t.textSecondary,
      ),
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
        titleSpacing: AppSpace.sm,
        titleTextStyle: AppTypo.sectionTitle(t),
        surfaceTintColor: transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
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
        floatingLabelStyle: AppTypo.body(t, color: t.accentInk),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.lg,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.accentInk, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.loss),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.loss, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accentInk,
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
        cursorColor: t.accentInk,
        selectionColor: t.accent.withValues(alpha: 0.3),
        selectionHandleColor: t.accentInk,
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
