import 'package:flutter/material.dart';

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
    required this.textDisabled,
    required this.border,
    required this.shadow,
    required this.shadowLg,
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
  final Color textDisabled;
  final Color border;
  final Color shadow;
  final Color shadowLg;

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? backgroundTint,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceRaised,
    Color? primary,
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
    Color? textDisabled,
    Color? border,
    Color? shadow,
    Color? shadowLg,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      backgroundTint: backgroundTint ?? this.backgroundTint,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      primary: primary ?? this.primary,
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
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      shadowLg: shadowLg ?? this.shadowLg,
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
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowLg: Color.lerp(shadowLg, other.shadowLg, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 28;
  static const double xl = 36;
  static const double pill = 999;
}

abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration splash = Duration(milliseconds: 1400);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve elastic = Curves.elasticOut;
  static const Curve bounce = Curves.easeOutBack;
}

abstract final class AppGradients {
  static LinearGradient primaryShifted(AppThemeTokens tokens) => LinearGradient(
        colors: [tokens.primary, tokens.accentCool],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient positiveShifted(AppThemeTokens tokens) => LinearGradient(
        colors: [tokens.positive, tokens.accentMint],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient warmShifted(AppThemeTokens tokens) => LinearGradient(
        colors: [tokens.accentWarm, tokens.accentMint],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient surfaceGlass(AppThemeTokens tokens) => LinearGradient(
        colors: [tokens.surface, tokens.surfaceAlt],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

abstract final class AppTheme {
  static const Color transparent = Color(0x00000000);

  static const _darkTokens = AppThemeTokens(
    background: Color(0xFF0E110F),
    backgroundTint: Color(0xFF151A18),
    surface: Color(0xFF1D2422),
    surfaceAlt: Color(0xFF252C2A),
    surfaceRaised: Color(0xFF222926),
    primary: Color(0xFF38D686),
    positive: Color(0xFF2AC573),
    negative: Color(0xFFF75A55),
    accentWarm: Color(0xFFF9B84E),
    accentCool: Color(0xFF5AC8FA),
    accentMint: Color(0xFF4CD9A5),
    neutralBlock: Color(0xFF111815),
    onPrimary: Color(0xFF02180D),
    onPositive: Color(0xFFFFFFFF),
    onNegative: Color(0xFFFFFFFF),
    onAccentWarm: Color(0xFF1A1208),
    onAccentCool: Color(0xFF0A1A24),
    onAccentMint: Color(0xFF0A1E18),
    onNeutralBlock: Color(0xFFF4F0E6),
    textPrimary: Color(0xFFF4F0E6),
    textSecondary: Color(0xFFB8B2A8),
    textDisabled: Color(0xFF6E716D),
    border: Color(0xFF333B37),
    shadow: Color(0x44000000),
    shadowLg: Color(0x66000000),
  );

  static const _lightTokens = AppThemeTokens(
    background: Color(0xFFFCF8F2),
    backgroundTint: Color(0xFFF7F1E8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2EBE2),
    surfaceRaised: Color(0xFFFAF5EF),
    primary: Color(0xFF2CB366),
    positive: Color(0xFF36B366),
    negative: Color(0xFFFF6B60),
    accentWarm: Color(0xFFF7AD39),
    accentCool: Color(0xFF57B5D6),
    accentMint: Color(0xFF48D197),
    neutralBlock: Color(0xFF232A26),
    onPrimary: Color(0xFFFFFFFF),
    onPositive: Color(0xFFFFFFFF),
    onNegative: Color(0xFF150A09),
    onAccentWarm: Color(0xFF1A1208),
    onAccentCool: Color(0xFF0A1A24),
    onAccentMint: Color(0xFF051A12),
    onNeutralBlock: Color(0xFFF4F0E6),
    textPrimary: Color(0xFF1D1F1C),
    textSecondary: Color(0xFF6E716D),
    textDisabled: Color(0xFFA8ACA6),
    border: Color(0xFFE2D9CB),
    shadow: Color(0x28171716),
    shadowLg: Color(0x44171716),
  );

  static ThemeData get dark => _build(Brightness.dark, _darkTokens);

  static ThemeData get light => _build(Brightness.light, _lightTokens);

  static ThemeData _build(Brightness brightness, AppThemeTokens tokens) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: tokens.accentWarm,
      onSecondary: tokens.onAccentWarm,
      tertiary: tokens.accentCool,
      onTertiary: tokens.onAccentCool,
      error: tokens.negative,
      onError: Color(0xFFFFFFFF),
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
    );

    final base = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.background,
      fontFamily: 'Roboto',
    );

    final textTheme = base.textTheme.apply(
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: tokens.border,
      cardColor: tokens.surface,
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: brightness == Brightness.dark ? 0 : 1,
        shadowColor: tokens.shadow,
        surfaceTintColor: AppTheme.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: tokens.textPrimary,
        ),
        surfaceTintColor: AppTheme.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: AppTheme.transparent,
        surfaceTintColor: AppTheme.transparent,
        shadowColor: tokens.shadow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? tokens.primary : tokens.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.primary : tokens.textSecondary,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceAlt,
        labelStyle: TextStyle(color: tokens.textSecondary),
        floatingLabelStyle: TextStyle(
          color: tokens.primary,
          fontWeight: FontWeight.w700,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.2,
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
              ? tokens.primary
              : tokens.textSecondary.withValues(alpha: 0.7);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.primary.withValues(alpha: 0.35)
              : tokens.surfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.all(tokens.border),
      ),
    );
  }
}