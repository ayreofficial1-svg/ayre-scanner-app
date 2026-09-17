import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── "v4" — calm, editorial, premium ───────────────────────────────────────
//
// The base hue family is deliberately WARM: off-white paper and soft charcoal
// surfaces, not the previous identity's cool graphite/ink. One accent —
// clay/terracotta — shifts warmer and darker in light mode rather than
// staying fixed across themes. Sage (positive), rose (negative) and gold
// (neutral/attention) sit alongside it as a fixed four-colour semantic set;
// there is no separate "info" role and no highlight-fill card pattern —
// emphasis comes from an accent-tinted border on a card, never a solid tint
// fill behind it.
//
// Two structural surfaces sit either side of `surface`, not three ascending
// steps plus a separate "terminal readout" panel: `surfaceRaised` (a tile
// lifted slightly off the card) and `surfaceSunken` (an inset track/fill
// recessed into the card). Unlike the previous identity, v4 re-introduces
// soft, two-layer shadows for elevation — flat/no-shadow was a rule of the
// identity this replaces, not a rule of this one.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.onAccent,
    required this.positive,
    required this.positiveSoft,
    required this.negative,
    required this.negativeSoft,
    required this.neutral,
    required this.neutralSoft,
    required this.textPrimary,
    required this.foregroundMuted,
    required this.foregroundSubtle,
    required this.textDisabled,
    required this.hairline,
    required this.navHairline,
    required this.shadowColor,
    required this.navBg,
    required this.skeleton,
  });

  /// App canvas: warm off-white paper in light, soft near-black charcoal in
  /// dark.
  final Color background;

  /// The default card/panel fill, one step off [background].
  final Color surface;

  /// A tile lifted slightly off its parent surface (e.g. a nested tonal
  /// block, an icon tile). Not a ladder step — a sibling of [surfaceSunken],
  /// chosen by the element's job, not by how "elevated" it should look.
  final Color surfaceRaised;

  /// A tonal fill recessed into its parent surface (e.g. a track, an inset
  /// readout region). Sibling of [surfaceRaised] — see that field's note.
  final Color surfaceSunken;

  /// The single brand/identity accent: clay/terracotta. No longer
  /// theme-invariant — it shifts warmer and darker in light mode. Used for
  /// the primary control, selected states, and featured-card accent edges.
  final Color accent;

  /// A darkened accent variant for small type-weight use (links, selected
  /// labels, small icons) where the raw [accent] value doesn't clear 4.5:1 as
  /// text on its theme's surfaces. See the Phase 0 contrast pass in
  /// `AYRE_REDESIGN_V4_PLAN.md` §7 item 5 — this is only populated where the
  /// raw accent actually fails; where it already passes, this equals
  /// [accent].
  final Color accentInk;

  /// Accent held back for large, low-emphasis fills.
  final Color accentSoft;

  /// Text on an [accent] fill. The accent sits at a mid lightness in both
  /// themes, so a dark ink — not inverted white — clears contrast; verified
  /// numerically, not assumed.
  final Color onAccent;

  /// Positive/gain. Sage — muted, not a saturated market green.
  final Color positive;
  final Color positiveSoft;

  /// Negative/loss. Muted rose — never the previous identity's bright red.
  final Color negative;
  final Color negativeSoft;

  /// Neutral/attention. Muted gold — the LIVE dot, delayed/stale chips,
  /// offline notices. Never a button fill, never navigation, never brand.
  final Color neutral;
  final Color neutralSoft;

  /// Primary reading text. Clears 4.5:1 on [background] and [surface] in
  /// both themes.
  final Color textPrimary;

  /// Secondary text — captions, timestamps, supporting copy. Body copy must
  /// never drop to [foregroundSubtle]; only true micro-copy may.
  final Color foregroundMuted;

  /// Tertiary text — eyebrows, micro-labels only. See [foregroundMuted]'s
  /// discipline note.
  final Color foregroundSubtle;

  /// Disabled text. The Spec has no explicit disabled-text token, so this is
  /// derived from [foregroundSubtle] at reduced opacity rather than a
  /// standalone authored value.
  final Color textDisabled;

  /// 1px structure: the card edge and divider hairline.
  final Color hairline;

  /// A slightly stronger hairline reserved for the bottom-nav's top edge,
  /// which needs to read against a blurred, semi-transparent bar rather than
  /// a flat surface.
  final Color navHairline;

  /// New in v4 — the previous identity had no shadows at all. Used for the
  /// two-layer soft card shadow.
  final Color shadowColor;

  /// Base fill for the glass bottom nav, composited with alpha + blur at the
  /// call site (see `AyreBottomNav`, Phase 2) rather than baked in here.
  final Color navBg;

  /// Base tone for the shimmer sweep on loading skeletons. Retinted to a
  /// soft foreground-tinted gradient at the widget (Phase 4); this is the
  /// base fill, not the highlight.
  final Color skeleton;

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? onAccent,
    Color? positive,
    Color? positiveSoft,
    Color? negative,
    Color? negativeSoft,
    Color? neutral,
    Color? neutralSoft,
    Color? textPrimary,
    Color? foregroundMuted,
    Color? foregroundSubtle,
    Color? textDisabled,
    Color? hairline,
    Color? navHairline,
    Color? shadowColor,
    Color? navBg,
    Color? skeleton,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      positive: positive ?? this.positive,
      positiveSoft: positiveSoft ?? this.positiveSoft,
      negative: negative ?? this.negative,
      negativeSoft: negativeSoft ?? this.negativeSoft,
      neutral: neutral ?? this.neutral,
      neutralSoft: neutralSoft ?? this.neutralSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      foregroundMuted: foregroundMuted ?? this.foregroundMuted,
      foregroundSubtle: foregroundSubtle ?? this.foregroundSubtle,
      textDisabled: textDisabled ?? this.textDisabled,
      hairline: hairline ?? this.hairline,
      navHairline: navHairline ?? this.navHairline,
      shadowColor: shadowColor ?? this.shadowColor,
      navBg: navBg ?? this.navBg,
      skeleton: skeleton ?? this.skeleton,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeTokens(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      accent: c(accent, other.accent),
      accentInk: c(accentInk, other.accentInk),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccent: c(onAccent, other.onAccent),
      positive: c(positive, other.positive),
      positiveSoft: c(positiveSoft, other.positiveSoft),
      negative: c(negative, other.negative),
      negativeSoft: c(negativeSoft, other.negativeSoft),
      neutral: c(neutral, other.neutral),
      neutralSoft: c(neutralSoft, other.neutralSoft),
      textPrimary: c(textPrimary, other.textPrimary),
      foregroundMuted: c(foregroundMuted, other.foregroundMuted),
      foregroundSubtle: c(foregroundSubtle, other.foregroundSubtle),
      textDisabled: c(textDisabled, other.textDisabled),
      hairline: c(hairline, other.hairline),
      navHairline: c(navHairline, other.navHairline),
      shadowColor: c(shadowColor, other.shadowColor),
      navBg: c(navBg, other.navBg),
      skeleton: c(skeleton, other.skeleton),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

// ─── Radii ─────────────────────────────────────────────────────────────────
// Smaller and flatter than the previous identity's "chunky, generous" 20–26px
// cards: 18px reads as rounded-not-bubbly per the Spec's own reasoning (24px+
// starts to read toy-like). Inner elements (chips, insets, icon tiles) step
// down to 12px. Circles are reserved for avatars and the toggle knob only —
// icon tiles are rounded squares, never circles.
abstract final class AppRadius {
  static const double card = 18;
  static const double chip = 12;
  static const double inset = 12;
  static const double control = 12;

  /// Rounded-square icon tiles sit in a 12–16px band; this is the default —
  /// individual call sites may pick within the band deliberately, not
  /// arbitrarily.
  static const double iconTile = 14;

  /// Not respecified by the Spec; kept from the previous identity unless
  /// visual QA against the new 18px card radius says otherwise (flagged for
  /// Phase 5).
  static const double sheet = 28;

  static const double pill = 999;
  static const double circle = 999;
  static const double button = pill;
}

// ─── Motion ────────────────────────────────────────────────────────────────
// The Spec's easing is a specific cubic-bezier, not a generic ease-out —
// implemented as an explicit `Cubic`, not `Curves.easeOutCubic`. Springs are
// reintroduced (the previous identity was critically damped everywhere, no
// bounce anywhere) but only for the nav pill, segmented control and toggle,
// and are still non-bouncy — "glides smoothly" per the Spec, not elastic.
abstract final class AppMotion {
  /// `cubic-bezier(0.22, 1, 0.36, 1)` — used for almost everything.
  static const Curve ease = Cubic(0.22, 1, 0.36, 1);
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;

  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration pageTransition = Duration(milliseconds: 280);
  static const Duration overlaySlide = Duration(milliseconds: 340);
  static const Duration cardEntrance = Duration(milliseconds: 450);
  static const Duration entranceStagger = Duration(milliseconds: 55);
  static const Duration entranceDelay = Duration(milliseconds: 30);
  static const Duration countUp = Duration(milliseconds: 900);
  static const Duration refreshRotation = Duration(milliseconds: 900);

  /// Chart draw-on. The Spec gives a 1.1–1.4s range; this is the midpoint —
  /// individual charts may pick within the range deliberately (Phase 3).
  static const Duration chartDraw = Duration(milliseconds: 1200);

  /// One cycle of the LIVE dot's pulse. Unchanged by v4 — nothing in the Spec
  /// retires this concept.
  static const Duration livePulse = Duration(milliseconds: 1600);

  // `traceDraw` (620ms) lived here as `TickerTrace`'s own pre-v4 draw-on,
  // pending Phase 3's decision on whether the line and radial families need
  // separate timings. They don't: Phase 3 confirmed one parametrized painter
  // serves Sparkline and AreaTrend, and every chart in the app now draws on
  // over [chartDraw]. Two chart durations would only have meant two places to
  // drift. Deleted rather than aliased — 620ms was the previous identity's
  // "feed ticking in" pace and is not a v4 value worth keeping reachable.

  /// Generic fallback duration, unchanged from before v4 — kept for call
  /// sites not yet reconciled against a named v4 duration above.
  static const Duration slow = Duration(milliseconds: 400);

  /// A changed figure settling to its new value. Retired as the *hero*-metric
  /// animation (superseded by [countUp], Spec §12.3/§15.2) but kept as a
  /// duration in case digit-roll survives for live-updating secondary
  /// tickers per plan §4 — resolve in Phase 3/5 whether any such ticker
  /// exists.
  static const Duration digitRoll = Duration(milliseconds: 420);

  /// Retained aliases so components not yet migrated in Phase 0 still resolve
  /// a duration; callers should move onto the named constants above during
  /// their own phase rather than relying on these.
  static const Duration fast = buttonPress;
  static const Duration medium = pageTransition;
  static const Duration entrance = cardEntrance;
  static const Duration stagger = entranceStagger;

  // Plan §7 open decision #9: Phase 0 put a literal carry-over of the Spec's
  // nav/toggle spring numbers here; Phase 1 numerically verified the same
  // values and moved the checked, documented version onto `AppSpring.navPill`
  // / `AppSpring.toggleKnob` in `spring.dart` (which is what `AyreSwitch` and,
  // as of this phase, `AyreBottomNav` actually animate with). Consolidated on
  // that single location now that both call sites exist — the copies that
  // used to live here (`navSpring`/`toggleSpring`) are deleted rather than
  // kept as unused duplicates.
}

/// The type scale.
///
/// A straight legibility-tuned scale, not a derived one — the previous
/// identity's φ/Fibonacci rationale doesn't carry forward: v4's step sizes
/// (hero 34–44, page 26–28, card title 17–20, body 13.5–15.5) don't land on
/// φ multiples of a 14px base, so keeping that doc comment next to new
/// numbers would be actively misleading. Each named constant below picks one
/// value from the Spec's given range; where the Spec gives a range rather
/// than a single figure, the choice is noted so a later pass can special-case
/// within the range deliberately rather than treating the pick as fixed.
abstract final class AppTextScale {
  /// Nav label. New in v4 — the previous nav had no labels.
  static const double navLabel = 10;

  /// Eyebrow/label — uppercase micro-heading.
  static const double eyebrow = 11;

  /// List-row hint / secondary micro-copy.
  static const double hint = 12.5;

  /// Body / subtitle. Spec range 13.5–15.5; this is the base body size.
  static const double body = 13.5;

  /// List row label.
  static const double rowLabel = 15;

  /// Card title. Spec range 17–20; this is the default — featured cards may
  /// pick higher in the range deliberately.
  static const double cardTitle = 18;

  /// Featured headline (e.g. the Insights featured article). No direct
  /// equivalent existed before v4.
  static const double featuredHeadline = 22;

  /// Page title. Spec range 26–28.
  static const double page = 28;

  /// Hero metric. Spec range 34–44; this is the base — [heroXL] takes the top
  /// of the range for the single largest reading on a screen.
  static const double hero = 40;
  static const double heroXL = 44;
}

/// The spacing scale.
///
/// A plain 4px base grid (Spec §6.1), replacing the previous identity's
/// Fibonacci steps outright — the two scales diverge at almost every step
/// (13/21/34 vs. 12/16/20/24), so this is a full scale replacement, not a
/// value-for-value substitution into layouts tuned for the old ratios. Named
/// spacing roles below map directly to the Spec's own named quantities;
/// `xxs`–`xxl` are the generic 4px-grid ladder for anything not named.
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Page horizontal padding.
  static const double pageHorizontal = 20;

  /// Page top padding.
  static const double pageTop = 12;

  /// Gap between major sections on a screen. Spec range 16–24; this is the
  /// default.
  static const double sectionGap = 20;

  /// Gap between sibling cards.
  static const double cardGap = 12;

  /// Card internal padding. Spec range 16–20; this is the default — hero/
  /// featured cards may pick higher in the range deliberately.
  static const double cardPadding = 16;

  /// Gap between elements inside a card. Spec range 12–16; this is the
  /// default.
  static const double inCardGap = 12;

  /// Vertical padding for a hairline-divided list row.
  static const double hairlineRowPadding = 14;

  /// Retained alias for call sites (`ayre_components.dart`'s `TickerRow`/
  /// `SkeletonTickerRow`) not yet migrated onto the named constant above —
  /// identical to [hairlineRowPadding].
  static const double row = hairlineRowPadding;

  /// The minimum tappable dimension. Already at/above the Apple HIG 44pt
  /// floor the Spec's own button/chip minimums fall under — kept unchanged
  /// (44pt+ enforcement across buttons/chips is a Phase 7 whole-app pass, not
  /// a token change).
  static const double minTarget = 48;
}

// ─── Typography ────────────────────────────────────────────────────────────
// Two faces, not three: Hanken Grotesk carries body, heading and UI text —
// replacing both Manrope (UI) and Space Grotesk's previous heading job.
// Space Grotesk survives, but its job narrows to numbers and display
// headings only. JetBrains Mono is dropped entirely.
abstract final class AppTypo {
  /// Converts the Spec's CSS `em` tracking values (relative to font size)
  /// into Flutter's absolute logical-pixel `letterSpacing`. Must be used for
  /// every tracking value carried over from the Spec — copying an `em`
  /// number as if it were already pixels reads either cramped or absurdly
  /// wide depending on the size it's applied at.
  static double tracking(double fontSize, double em) => em * fontSize;

  /// Body, heading and UI text — one face, replacing Manrope + Space
  /// Grotesk's previous heading role.
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.hankenGrotesk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing ?? -0.4,
  );

  static TextStyle ui({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.hankenGrotesk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Every numeric market value, without exception — tabular figures so a
  /// live value never reflows its neighbours when it updates. Space Grotesk
  /// replaces JetBrains Mono; the tabular-figures discipline is unchanged.
  static TextStyle num({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing ?? -0.3,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Retained alias for call sites (`figure.dart`) not yet migrated off the
  /// old name in Phase 0 — identical to [num]. Migrate callers to [num]
  /// directly in the phase that touches them, then delete this.
  static TextStyle ticker({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => num(
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

  static TextStyle featuredHeadline(AppThemeTokens t, {Color? color}) =>
      display(
        fontSize: AppTextScale.featuredHeadline,
        fontWeight: FontWeight.w700,
        color: color ?? t.textPrimary,
        height: 1.22,
        letterSpacing: -0.4,
      );

  /// No separate section-title size is given by the Spec; this reuses
  /// [AppTextScale.featuredHeadline] deliberately (flag if visual QA in
  /// Phase 5 wants a distinct step).
  static TextStyle sectionTitle(AppThemeTokens t, {Color? color}) =>
      featuredHeadline(t, color: color);

  static TextStyle cardTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: AppTextScale.cardTitle,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // ── Numeric roles ────────────────────────────────────────────────────────

  /// The largest data text in the app — index and equity levels.
  static TextStyle heroValue(AppThemeTokens t, {Color? color}) => num(
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
  }) => num(fontSize: fontSize, fontWeight: FontWeight.w500, color: color ?? t.textPrimary);

  static TextStyle valueSmall(AppThemeTokens t, {Color? color}) => num(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: color ?? t.foregroundSubtle,
    letterSpacing: 0,
  );

  // ── UI roles ─────────────────────────────────────────────────────────────

  static TextStyle body(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.body,
    fontWeight: FontWeight.w400,
    color: color ?? t.foregroundMuted,
    height: 1.45,
  );

  static TextStyle bodyStrong(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.body,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    height: 1.4,
  );

  static TextStyle rowLabel(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.rowLabel,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
    letterSpacing: -0.1,
  );

  /// List-row hint / secondary micro-copy.
  static TextStyle hint(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.hint,
    fontWeight: FontWeight.w400,
    color: color ?? t.foregroundSubtle,
    height: 1.35,
  );

  /// Retained name for existing call sites; identical to [hint].
  static TextStyle caption(AppThemeTokens t, {Color? color}) =>
      hint(t, color: color);

  /// Eyebrow: small, uppercase, wide-tracked, subtle. Sits above every data
  /// value and heads every section. Tracking is the Spec's "+0.08em"
  /// converted via [tracking] at this role's own font size, not a raw number
  /// carried over from a different size.
  static TextStyle label(
    AppThemeTokens t, {
    Color? color,
    double fontSize = AppTextScale.eyebrow,
  }) => ui(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color ?? t.foregroundSubtle,
    letterSpacing: tracking(fontSize, 0.08),
  );

  /// Bottom-nav label. New in v4. Tracking is the Spec's "+0.01em" at 10px.
  static TextStyle navLabel(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.navLabel,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: tracking(AppTextScale.navLabel, 0.01),
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

  // Dark — `#100F14` canvas, warm off-white text. Not a re-tint of the
  // previous cool "Slate" dark theme; every surface, text and accent value
  // below is authored fresh from the Spec.
  static const _dark = AppThemeTokens(
    background: Color(0xFF100F14),
    surface: Color(0xFF17161D),
    surfaceRaised: Color(0xFF211F28),
    surfaceSunken: Color(0xFF0B0A0F),
    accent: Color(0xFFD26A4C),
    // Raw accent already clears 4.5:1 as small text on both `background` and
    // `surface` in dark mode (~5.3–5.9:1 numerically) — no separate ink
    // variant needed here; see the light-theme value below for the case
    // where one is.
    accentInk: Color(0xFFD26A4C),
    accentSoft: Color(0xFFE09A82),
    // Deliberately dark: the accent sits at a mid lightness, so inverted
    // white button text under-performs (~3.5:1) where a dark warm ink clears
    // ~5.9:1.
    onAccent: Color(0xFF1F0F08),
    positive: Color(0xFF93B59A),
    positiveSoft: Color(0xFFA9C7B0),
    negative: Color(0xFFC97E72),
    negativeSoft: Color(0xFFD7A299),
    neutral: Color(0xFFD9C79A),
    neutralSoft: Color(0x24D9C79A),
    textPrimary: Color(0xFFF3ECE0),
    foregroundMuted: Color(0xFF9495A3),
    foregroundSubtle: Color(0xFF6A6B78),
    textDisabled: Color(0x806A6B78),
    hairline: Color(0x0FFFFFFF),
    navHairline: Color(0x14FFFFFF),
    shadowColor: Color(0xFF030305),
    navBg: Color(0xFF13121A),
    skeleton: Color(0xFF211F28),
  );

  // Light — `#F6F0E6` warm paper canvas. Not a re-tint of the previous cool
  // "Fogpaper" light theme; every surface, text and accent value below is
  // authored fresh from the Spec.
  static const _light = AppThemeTokens(
    background: Color(0xFFF6F0E6),
    surface: Color(0xFFFEFCF7),
    surfaceRaised: Color(0xFFF1EADD),
    surfaceSunken: Color(0xFFECE3D4),
    accent: Color(0xFFC75F43),
    // Raw accent measures ~3.8:1 as small text on the light surfaces — fails
    // AA. This is a darkened variant of the same hue (same ~13° hue / ~54%
    // saturation, lightness pulled down) that clears ~6.7:1. Numerically
    // derived for Phase 0; treat as provisional pending visual QA against
    // the actual design tool value in Phase 1.
    accentInk: Color(0xFF954329),
    accentSoft: Color(0xFFD88A6E),
    onAccent: Color(0xFF1F0F08),
    positive: Color(0xFF5E8A66),
    positiveSoft: Color(0xFF7FA885),
    negative: Color(0xFFB05A4C),
    negativeSoft: Color(0xFFC97E72),
    neutral: Color(0xFF9A883E),
    neutralSoft: Color(0x249A883E),
    textPrimary: Color(0xFF1A1A22),
    foregroundMuted: Color(0xFF5F606B),
    foregroundSubtle: Color(0xFF8A8B95),
    textDisabled: Color(0x808A8B95),
    hairline: Color(0x0F1A1A22),
    navHairline: Color(0x141A1A22),
    shadowColor: Color(0xFFB39980),
    navBg: Color(0xFFFEFCF7),
    skeleton: Color(0xFFF1EADD),
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
      secondary: t.neutral,
      onSecondary: isDark ? t.background : const Color(0xFFFFFFFF),
      tertiary: t.neutral,
      onTertiary: isDark ? t.background : const Color(0xFFFFFFFF),
      error: t.negative,
      onError: isDark ? t.background : const Color(0xFFFFFFFF),
      surface: t.surface,
      onSurface: t.textPrimary,
    );

    // Headings and body share the display/UI face (Hanken Grotesk); numerals
    // never come from the TextTheme — they route through `Figure` so the
    // Space Grotesk tabular-numeral rule cannot be bypassed.
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
      bodySmall: AppTypo.hint(t),
      labelLarge: AppTypo.button(t, color: t.textPrimary),
      labelMedium: AppTypo.ui(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: t.foregroundMuted,
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
          side: BorderSide(color: t.hairline),
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
        fillColor: t.surfaceSunken,
        hintStyle: AppTypo.body(t, color: t.foregroundSubtle),
        labelStyle: AppTypo.body(t),
        floatingLabelStyle: AppTypo.body(t, color: t.accentInk),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.lg,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.accentInk, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.negative),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: t.negative, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accentInk,
        circularTrackColor: t.surfaceSunken,
        linearTrackColor: t.surfaceSunken,
        linearMinHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surfaceRaised,
        contentTextStyle: AppTypo.bodyStrong(t),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: t.hairline),
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

/// Route-level push/pop transition, used for overlay pushes (Settings, the
/// state gallery, detail screens) at [AppMotion.overlaySlide]. Tab-to-tab
/// switches inside the bottom-nav shell do NOT use this — per Spec §15.4
/// they're a fade+shift living in `home_shell.dart`, not a `Navigator` push
/// (Phase 2). The name is retained from the previous identity for now;
/// consider renaming once the nav rewrite lands in Phase 2 so it no longer
/// reads as "terminal"-branded.
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