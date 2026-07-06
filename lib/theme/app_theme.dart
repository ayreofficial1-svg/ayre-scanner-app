import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Section identifiers ────────────────────────────────────────────────────
enum AyreSection { home, signals, insights, learn, profile }

// ─── Token extension ────────────────────────────────────────────────────────
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.background,
    required this.backgroundTint,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.primary,
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
    required this.shadow,
    required this.shadowLg,
    required this.cream,
    required this.ivory,
    required this.peach,
    required this.coral,
    required this.mint,
    required this.mintDeep,
    required this.teal,
    required this.teal2,
    required this.lavender,
    required this.violet,
    required this.sage,
    required this.gold,
    required this.positiveBg,
    required this.negativeBg,
    required this.paper,
    required this.paperStrong,
    required this.shimmer,
  });

  final Color background;
  final Color backgroundTint;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceRaised;
  final Color primary;
  final Color positive;
  final Color negative;
  final Color accentWarm;
  final Color accentCool;
  final Color accentMint;
  final Color neutralBlock;
  final Color onPrimary;
  final Color onPositive;
  final Color onNegative;
  final Color onAccentWarm;
  final Color onAccentCool;
  final Color onAccentMint;
  final Color onNeutralBlock;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color border;
  final Color borderSubtle;
  final Color shadow;
  final Color shadowLg;
  final Color cream;
  final Color ivory;
  final Color peach;
  final Color coral;
  final Color mint;
  final Color mintDeep;
  final Color teal;
  final Color teal2;
  final Color lavender;
  final Color violet;
  final Color sage;
  final Color gold;
  final Color positiveBg;
  final Color negativeBg;
  final Color paper;
  final Color paperStrong;
  final Color shimmer;

  @override
  AppThemeTokens copyWith({
    Color? background, Color? backgroundTint, Color? surface, Color? surfaceAlt, Color? surfaceRaised,
    Color? primary, Color? positive, Color? negative, Color? accentWarm, Color? accentCool, Color? accentMint, Color? neutralBlock,
    Color? onPrimary, Color? onPositive, Color? onNegative, Color? onAccentWarm, Color? onAccentCool, Color? onAccentMint, Color? onNeutralBlock,
    Color? textPrimary, Color? textSecondary, Color? textTertiary, Color? textDisabled,
    Color? border, Color? borderSubtle, Color? shadow, Color? shadowLg,
    Color? cream, Color? ivory, Color? peach, Color? coral, Color? mint, Color? mintDeep, Color? teal, Color? teal2, Color? lavender, Color? violet, Color? sage, Color? gold,
    Color? positiveBg, Color? negativeBg, Color? paper, Color? paperStrong, Color? shimmer,
  }) {
    return AppThemeTokens(
      background: background ?? this.background, backgroundTint: backgroundTint ?? this.backgroundTint, surface: surface ?? this.surface, surfaceAlt: surfaceAlt ?? this.surfaceAlt, surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      primary: primary ?? this.primary, positive: positive ?? this.positive, negative: negative ?? this.negative, accentWarm: accentWarm ?? this.accentWarm, accentCool: accentCool ?? this.accentCool, accentMint: accentMint ?? this.accentMint, neutralBlock: neutralBlock ?? this.neutralBlock,
      onPrimary: onPrimary ?? this.onPrimary, onPositive: onPositive ?? this.onPositive, onNegative: onNegative ?? this.onNegative, onAccentWarm: onAccentWarm ?? this.onAccentWarm, onAccentCool: onAccentCool ?? this.onAccentCool, onAccentMint: onAccentMint ?? this.onAccentMint, onNeutralBlock: onNeutralBlock ?? this.onNeutralBlock,
      textPrimary: textPrimary ?? this.textPrimary, textSecondary: textSecondary ?? this.textSecondary, textTertiary: textTertiary ?? this.textTertiary, textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border, borderSubtle: borderSubtle ?? this.borderSubtle, shadow: shadow ?? this.shadow, shadowLg: shadowLg ?? this.shadowLg,
      cream: cream ?? this.cream, ivory: ivory ?? this.ivory, peach: peach ?? this.peach, coral: coral ?? this.coral, mint: mint ?? this.mint, mintDeep: mintDeep ?? this.mintDeep, teal: teal ?? this.teal, teal2: teal2 ?? this.teal2, lavender: lavender ?? this.lavender, violet: violet ?? this.violet, sage: sage ?? this.sage, gold: gold ?? this.gold,
      positiveBg: positiveBg ?? this.positiveBg, negativeBg: negativeBg ?? this.negativeBg, paper: paper ?? this.paper, paperStrong: paperStrong ?? this.paperStrong, shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      background: Color.lerp(background, other.background, t)!, backgroundTint: Color.lerp(backgroundTint, other.backgroundTint, t)!, surface: Color.lerp(surface, other.surface, t)!, surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!, surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      primary: Color.lerp(primary, other.primary, t)!, positive: Color.lerp(positive, other.positive, t)!, negative: Color.lerp(negative, other.negative, t)!, accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!, accentCool: Color.lerp(accentCool, other.accentCool, t)!, accentMint: Color.lerp(accentMint, other.accentMint, t)!, neutralBlock: Color.lerp(neutralBlock, other.neutralBlock, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!, onPositive: Color.lerp(onPositive, other.onPositive, t)!, onNegative: Color.lerp(onNegative, other.onNegative, t)!, onAccentWarm: Color.lerp(onAccentWarm, other.onAccentWarm, t)!, onAccentCool: Color.lerp(onAccentCool, other.onAccentCool, t)!, onAccentMint: Color.lerp(onAccentMint, other.onAccentMint, t)!, onNeutralBlock: Color.lerp(onNeutralBlock, other.onNeutralBlock, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!, textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!, textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!, textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!, borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!, shadow: Color.lerp(shadow, other.shadow, t)!, shadowLg: Color.lerp(shadowLg, other.shadowLg, t)!,
      cream: Color.lerp(cream, other.cream, t)!, ivory: Color.lerp(ivory, other.ivory, t)!, peach: Color.lerp(peach, other.peach, t)!, coral: Color.lerp(coral, other.coral, t)!, mint: Color.lerp(mint, other.mint, t)!, mintDeep: Color.lerp(mintDeep, other.mintDeep, t)!, teal: Color.lerp(teal, other.teal, t)!, teal2: Color.lerp(teal2, other.teal2, t)!, lavender: Color.lerp(lavender, other.lavender, t)!, violet: Color.lerp(violet, other.violet, t)!, sage: Color.lerp(sage, other.sage, t)!, gold: Color.lerp(gold, other.gold, t)!,
      positiveBg: Color.lerp(positiveBg, other.positiveBg, t)!, negativeBg: Color.lerp(negativeBg, other.negativeBg, t)!, paper: Color.lerp(paper, other.paper, t)!, paperStrong: Color.lerp(paperStrong, other.paperStrong, t)!, shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

// ─── Spacing (Apple HIG 8-pt grid) ─────────────────────────────────────────
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
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double card = 18;
  static const double heroCard = 24;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
  static const double navBar = 32;
}

// ─── Motion ─────────────────────────────────────────────────────────────────
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration splash = Duration(milliseconds: 1200);
  static const Duration navExpand = Duration(milliseconds: 280);
  static const Duration auraPulse = Duration(seconds: 4);
  static const Duration cardEntrance = Duration(milliseconds: 450);
  static const Duration cardStagger = Duration(milliseconds: 50);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve elastic = Curves.elasticOut;
  static const Curve bounce = Curves.easeOutBack;
  static const Curve spring = Curves.easeOutBack;
  static const Curve decel = Curves.decelerate;
}

// ─── Per-section gradients ──────────────────────────────────────────────────
abstract final class AppGradients {
  static LinearGradient screenBg(AyreSection section, Brightness brightness) {
    if (brightness == Brightness.light) {
      return const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFF8F9FB), Color(0xFFF0F1F5)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF0A0A0C), Color(0xFF0F0F12)],
    );
  }

  static LinearGradient heroCard(AyreSection section, AppThemeTokens tokens) {
    return switch (section) {
      AyreSection.home => LinearGradient(
        colors: [tokens.primary, Color.lerp(tokens.primary, tokens.teal2, 0.6)!],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      AyreSection.signals => LinearGradient(
        colors: [tokens.teal, Color.lerp(tokens.teal, tokens.accentMint, 0.5)!],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      AyreSection.insights => LinearGradient(
        colors: [tokens.accentCool, Color.lerp(tokens.accentCool, tokens.lavender, 0.4)!],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      AyreSection.learn => LinearGradient(
        colors: [tokens.accentWarm, Color.lerp(tokens.accentWarm, tokens.gold, 0.5)!],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      AyreSection.profile => LinearGradient(
        colors: [tokens.neutralBlock, Color.lerp(tokens.neutralBlock, tokens.primary, 0.18)!],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    };
  }

  static LinearGradient primaryShifted(AppThemeTokens tokens) => LinearGradient(
    colors: [tokens.primary, Color.lerp(tokens.primary, tokens.teal2, 0.55)!],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient positiveShifted(AppThemeTokens tokens) => LinearGradient(
    colors: [tokens.positive, tokens.accentMint],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient warmShifted(AppThemeTokens tokens) => LinearGradient(
    colors: [tokens.accentWarm, tokens.gold],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient surfaceGlass(AppThemeTokens tokens) => LinearGradient(
    colors: [tokens.paper, tokens.paperStrong],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

// ─── Typography helpers ─────────────────────────────────────────────────────
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

  static TextStyle heroValue(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    color: color ?? tokens.textPrimary,
    height: 1.0,
    letterSpacing: -1.8,
  );

  static TextStyle pageTitle(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color ?? tokens.textPrimary,
    height: 1.15,
    letterSpacing: -0.8,
  );

  static TextStyle sectionTitle(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: color ?? tokens.textPrimary,
    height: 1.2,
    letterSpacing: -0.4,
  );

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

  static TextStyle eyebrow(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color ?? tokens.textTertiary,
    letterSpacing: 0.6,
  );

  static TextStyle dataNum(AppThemeTokens tokens, {Color? color, double fontSize = 15}) => inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: color ?? tokens.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle caption(AppThemeTokens tokens, {Color? color}) => inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color ?? tokens.textTertiary,
    letterSpacing: 0.0,
  );
}

// ─── Theme builder ──────────────────────────────────────────────────────────
abstract final class AppTheme {
  static const Color transparent = Color(0x00000000);

  // Light tokens – warm, airy, Apple-inspired
  static const _lightTokens = AppThemeTokens(
    background: Color(0xFFF8F9FB),
    backgroundTint: Color(0xFFF0F1F5),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5F5F7),
    surfaceRaised: Color(0xFFFFFFFF),
    primary: Color(0xFF0A7E8C),
    positive: Color(0xFF28A745),
    negative: Color(0xFFE53E3E),
    accentWarm: Color(0xFFF5A623),
    accentCool: Color(0xFF6366F1),
    accentMint: Color(0xFF38BDF8),
    neutralBlock: Color(0xFF1A1A1E),
    onPrimary: Color(0xFFFFFFFF),
    onPositive: Color(0xFFFFFFFF),
    onNegative: Color(0xFFFFFFFF),
    onAccentWarm: Color(0xFFFFFFFF),
    onAccentCool: Color(0xFFFFFFFF),
    onAccentMint: Color(0xFFFFFFFF),
    onNeutralBlock: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A1E),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    textDisabled: Color(0xFFD1D5DB),
    border: Color(0x12000000),
    borderSubtle: Color(0x08000000),
    shadow: Color(0x08000000),
    shadowLg: Color(0x12000000),
    cream: Color(0xFFF5F5F7),
    ivory: Color(0xFFFFFFFF),
    peach: Color(0xFFFFF0DB),
    coral: Color(0xFFF5A623),
    mint: Color(0xFFE8F8F5),
    mintDeep: Color(0xFF38BDF8),
    teal: Color(0xFF0A7E8C),
    teal2: Color(0xFF28A745),
    lavender: Color(0xFFF0EFFE),
    violet: Color(0xFF6366F1),
    sage: Color(0xFFD1E8E2),
    gold: Color(0xFFF5C842),
    positiveBg: Color(0x1428A745),
    negativeBg: Color(0x14E53E3E),
    paper: Color(0xCCFFFFFF),
    paperStrong: Color(0xE6FFFFFF),
    shimmer: Color(0xFFF0F1F5),
  );

  // Dark tokens – deep, rich, elevated surfaces
  static const _darkTokens = AppThemeTokens(
    background: Color(0xFF0A0A0C),
    backgroundTint: Color(0xFF0F0F12),
    surface: Color(0xFF18181B),
    surfaceAlt: Color(0xFF222225),
    surfaceRaised: Color(0xFF27272A),
    primary: Color(0xFF2DD4BF),
    positive: Color(0xFF34D399),
    negative: Color(0xFFF87171),
    accentWarm: Color(0xFFFBBF24),
    accentCool: Color(0xFF818CF8),
    accentMint: Color(0xFF67E8F9),
    neutralBlock: Color(0xFFF5F5F7),
    onPrimary: Color(0xFF0A0A0C),
    onPositive: Color(0xFF0A0A0C),
    onNegative: Color(0xFF0A0A0C),
    onAccentWarm: Color(0xFF0A0A0C),
    onAccentCool: Color(0xFFFFFFFF),
    onAccentMint: Color(0xFF0A0A0C),
    onNeutralBlock: Color(0xFF0A0A0C),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    textDisabled: Color(0xFF374151),
    border: Color(0x18FFFFFF),
    borderSubtle: Color(0x0AFFFFFF),
    shadow: Color(0x40000000),
    shadowLg: Color(0x60000000),
    cream: Color(0xFF18181B),
    ivory: Color(0xFF18181B),
    peach: Color(0xFF2A1F10),
    coral: Color(0xFFFBBF24),
    mint: Color(0xFF0D2926),
    mintDeep: Color(0xFF67E8F9),
    teal: Color(0xFF2DD4BF),
    teal2: Color(0xFF34D399),
    lavender: Color(0xFF1E1B36),
    violet: Color(0xFF818CF8),
    sage: Color(0xFF34D399),
    gold: Color(0xFFF5C842),
    positiveBg: Color(0x2034D399),
    negativeBg: Color(0x20F87171),
    paper: Color(0x2618181B),
    paperStrong: Color(0x4D18181B),
    shimmer: Color(0xFF222225),
  );

  static ThemeData get dark => _build(Brightness.dark, _darkTokens);
  static ThemeData get light => _build(Brightness.light, _lightTokens);

  static ThemeData _build(Brightness brightness, AppThemeTokens tokens) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: tokens.accentWarm,
      onSecondary: tokens.onAccentWarm,
      tertiary: tokens.accentCool,
      onTertiary: tokens.onAccentCool,
      error: tokens.negative,
      onError: const Color(0xFFFFFFFF),
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypo.inter(fontSize: 40, fontWeight: FontWeight.w700, color: tokens.textPrimary, letterSpacing: -1.2),
      displayMedium: AppTypo.inter(fontSize: 34, fontWeight: FontWeight.w700, color: tokens.textPrimary, letterSpacing: -0.8),
      displaySmall: AppTypo.inter(fontSize: 28, fontWeight: FontWeight.w700, color: tokens.textPrimary, letterSpacing: -0.6),
      headlineLarge: AppTypo.inter(fontSize: 24, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.5),
      headlineMedium: AppTypo.inter(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.4),
      headlineSmall: AppTypo.inter(fontSize: 18, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.3),
      titleLarge: AppTypo.inter(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.2),
      titleMedium: AppTypo.inter(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.textPrimary, letterSpacing: -0.1),
      titleSmall: AppTypo.inter(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textPrimary),
      bodyLarge: AppTypo.inter(fontSize: 16, fontWeight: FontWeight.w400, color: tokens.textPrimary, height: 1.5),
      bodyMedium: AppTypo.inter(fontSize: 14, fontWeight: FontWeight.w400, color: tokens.textSecondary, height: 1.45),
      bodySmall: AppTypo.inter(fontSize: 12, fontWeight: FontWeight.w400, color: tokens.textTertiary, height: 1.4),
      labelLarge: AppTypo.inter(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textPrimary),
      labelMedium: AppTypo.inter(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textSecondary, letterSpacing: 0.2),
      labelSmall: AppTypo.inter(fontSize: 11, fontWeight: FontWeight.w500, color: tokens.textTertiary, letterSpacing: 0.3),
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
      dividerColor: tokens.border,
      cardColor: tokens.surface,
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shadowColor: transparent,
        surfaceTintColor: transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypo.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: tokens.textPrimary,
          letterSpacing: -0.4,
        ),
        surfaceTintColor: transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: transparent,
        surfaceTintColor: transparent,
        shadowColor: tokens.shadow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypo.inter(
            color: selected ? tokens.primary : tokens.textTertiary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 11,
            letterSpacing: 0.1,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.primary : tokens.textTertiary,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceAlt,
        labelStyle: AppTypo.inter(
          color: tokens.textSecondary, fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: AppTypo.inter(
          color: tokens.primary, fontWeight: FontWeight.w600,
        ),
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
          textStyle: AppTypo.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        circularTrackColor: tokens.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.onPrimary
              : tokens.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.primary
              : tokens.surfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.transparent
              : tokens.border;
        }),
      ),
    );
  }
}
