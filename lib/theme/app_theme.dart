import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── "v5" — forest-green, emerald, mint-paper ──────────────────────────────
//
// v5 retires v4's warm clay/terracotta identity for a cool, deep
// forest-green ink and a bright, saturated emerald accent. The light theme's
// canvas is a pale, cool mint-white paper (never pure white/gray); the dark
// theme's canvas is near-black with a green cast (never pure black/gray).
// Positive (gain) and negative (loss) are genuine saturated green/red again
// — not v4's muted sage/rose — reserved for actual gain/loss figures and
// glyphs; neutral/attention stays a muted gold/amber, never a button fill,
// never navigation, never brand.
//
// Two structural surfaces still sit either side of `surface`: `surfaceRaised`
// (a tile lifted slightly off the card) and `surfaceSunken` (an inset
// track/fill recessed into the card). The soft, two-layer shadows v4
// introduced are kept — flat/no-shadow is not a v5 rule either.
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
    required this.avatarFill,
    required this.avatarInk,
  });

  /// App canvas: pale, cool mint-white paper in light; near-black with a
  /// green cast in dark. Never pure white/gray (light) or pure black/gray
  /// (dark).
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

  /// The primary brand/identity accent: forest-green/emerald. Not
  /// theme-invariant — brighter and more saturated in dark mode so it still
  /// reads as the loudest color against a near-black field. Used for
  /// "Bullish" text, up-arrows, the NIFTY trace, primary buttons, active nav
  /// elements, and links.
  final Color accent;

  /// A darkened (light theme) / lightened (dark theme) accent variant for
  /// small type-weight use (links, selected labels) where the raw [accent]
  /// value doesn't clear 4.5:1 as text on its theme's surfaces — verified
  /// numerically in the v5 Phase 0 contrast pass; only populated where the
  /// raw accent actually differs from a passing value.
  final Color accentInk;

  /// Accent held back for large, low-emphasis fills.
  final Color accentSoft;

  /// Text/icon on an [accent] fill — white in light (accent is mid-dark
  /// there), near-black ink in dark (accent is bright/mid-light there);
  /// verified numerically per theme, not assumed to be the same choice in
  /// both.
  final Color onAccent;

  /// Positive/gain. Same hue family as [accent] — a genuine saturated
  /// market green, kept as its own field per the token contract (a screen
  /// may want brand-accent and gain-color to diverge later), and no longer
  /// v4's muted sage.
  final Color positive;
  final Color positiveSoft;

  /// Negative/loss. A clear, saturated red — distinct from any card's own
  /// warm identity tint (e.g. the SENSEX card's coral, which is never a
  /// loss signal), and no longer v4's muted rose.
  final Color negative;
  final Color negativeSoft;

  /// Neutral/attention (e.g. a flat/unchanged badge). Muted gold/amber —
  /// never a button fill, never navigation, never brand. (The LIVE
  /// indicator itself moved to [positive] in v5 — see the LIVE-chip spec.)
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

  /// Avatar / identity-chip fill (Phase 6, §2A "Avatar / identity chip" row)
  /// — a deliberate lavender/plum secondary accent, distinct from brand
  /// green. Used only for personal/identity chips (the Profile initials
  /// circle), never for market data.
  final Color avatarFill;

  /// Initials text on [avatarFill].
  final Color avatarInk;

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
    Color? avatarFill,
    Color? avatarInk,
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
      avatarFill: avatarFill ?? this.avatarFill,
      avatarInk: avatarInk ?? this.avatarInk,
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
      avatarFill: c(avatarFill, other.avatarFill),
      avatarInk: c(avatarInk, other.avatarInk),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

// ─── Index-card identity tints ──────────────────────────────────────────────
// Not `AppThemeTokens` fields (redesign plan §2A / Phase 0 step 6): each Home
// index card — and anywhere else an index is represented as a card, e.g.
// `index_detail_screen.dart`'s header — carries its own fixed light/dark
// identity tint, independent of theme *semantics* and never a stand-in for
// gain/loss color. This is the single shared lookup; consume it from both
// `home_tab.dart` and `index_detail_screen.dart` rather than duplicating the
// table.

/// One index's identity tint pair for a single brightness. Purely
/// decorative — never swap these in for [AppThemeTokens.positive] /
/// [AppThemeTokens.negative].
@immutable
class AppIndexTint {
  const AppIndexTint({
    required this.cardBackground,
    required this.iconGradientCenter,
    required this.iconGradientEdge,
    required this.trace,
    required this.activePeriodTabFill,
  });

  /// Card background fill.
  final Color cardBackground;

  /// Icon-tile radial-gradient center stop (lighter). See
  /// [AppRadius]'s "icon-tile shape override" note — this is the one icon
  /// tile in the app that's circular rather than a rounded square.
  final Color iconGradientCenter;

  /// Icon-tile radial-gradient edge stop (darker).
  final Color iconGradientEdge;

  /// Sparkline trace / icon glyph color.
  final Color trace;

  /// Active period-tab (1D/1W/1M/1Y) pill fill, a deeper shade of the
  /// card's own tint.
  final Color activePeriodTabFill;
}

/// Which index a card represents, for [AppIndexTints] lookup. Extend with a
/// new case here — and a matching entry in [AppIndexTints.light]/[dark] —
/// if a fourth index is ever added; never reuse an existing index's tint.
enum AppIndexId { nifty50, sensex, bankNifty }

/// The fixed light/dark [AppIndexTint] pair for each [AppIndexId].
abstract final class AppIndexTints {
  static const Map<AppIndexId, AppIndexTint> light = {
    AppIndexId.nifty50: AppIndexTint(
      cardBackground: Color(0xFFE7F3E8),
      iconGradientCenter: Color(0xFFDFF0E2),
      iconGradientEdge: Color(0xFFB8DEC0),
      trace: Color(0xFF2E9E5B),
      activePeriodTabFill: Color(0xFFC9E4CE),
    ),
    AppIndexId.sensex: AppIndexTint(
      cardBackground: Color(0xFFFBEAE4),
      iconGradientCenter: Color(0xFFFAE2D8),
      iconGradientEdge: Color(0xFFEEC3AF),
      trace: Color(0xFFD97757),
      activePeriodTabFill: Color(0xFFF3D2C3),
    ),
    AppIndexId.bankNifty: AppIndexTint(
      cardBackground: Color(0xFFE6EEF7),
      iconGradientCenter: Color(0xFFDCEAF6),
      iconGradientEdge: Color(0xFFB9D3EB),
      trace: Color(0xFF4A79B5),
      activePeriodTabFill: Color(0xFFCBE0F3),
    ),
  };

  static const Map<AppIndexId, AppIndexTint> dark = {
    AppIndexId.nifty50: AppIndexTint(
      cardBackground: Color(0xFF14251A),
      iconGradientCenter: Color(0xFF25452F),
      iconGradientEdge: Color(0xFF15291C),
      trace: Color(0xFF4ED892),
      activePeriodTabFill: Color(0xFF255436),
    ),
    AppIndexId.sensex: AppIndexTint(
      cardBackground: Color(0xFF2A1B14),
      iconGradientCenter: Color(0xFF4A2E1F),
      iconGradientEdge: Color(0xFF2C1911),
      trace: Color(0xFFE08A63),
      activePeriodTabFill: Color(0xFF5A3624),
    ),
    AppIndexId.bankNifty: AppIndexTint(
      cardBackground: Color(0xFF131E2A),
      iconGradientCenter: Color(0xFF213D57),
      iconGradientEdge: Color(0xFF122333),
      trace: Color(0xFF6FA8E0),
      activePeriodTabFill: Color(0xFF29476A),
    ),
  };

  /// Look up [id]'s tint for the current [brightness]. Switches the same
  /// way the rest of the app already themes conditionally.
  static AppIndexTint of(AppIndexId id, Brightness brightness) =>
      (brightness == Brightness.dark ? dark : light)[id]!;
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

  // Dark — near-black-green canvas (`#0B120D`), soft off-white text with a
  // faint green cast. Not a re-tint of v4's warm `#100F14` dark theme; every
  // surface, text and accent value below is authored fresh from the v5 spec
  // (redesign plan §2A).
  static const _dark = AppThemeTokens(
    background: Color(0xFF0B120D),
    surface: Color(0xFF121A14),
    surfaceRaised: Color(0xFF1B261E),
    surfaceSunken: Color(0xFF080D09),
    accent: Color(0xFF3FCB7A),
    // Raw accent already clears 4.5:1 as small text on both `background`
    // and `surface` in dark mode (~10.6:1 / ~9.9:1 numerically) — no
    // contrast-driven ink swap needed; `accentInk` below is still a
    // distinct, lighter value per the spec table for link/selected-label
    // use, not a failure fix.
    accentInk: Color(0xFF59D98C),
    accentSoft: Color(0xFF1E3B29),
    // Dark ink text: accent sits at a bright/mid-light lightness in dark
    // mode, so an inverted near-black ink clears ~9.1:1 where white would
    // under-perform.
    onAccent: Color(0xFF06130A),
    positive: Color(0xFF4ED892),
    positiveSoft: Color(0xFF16301F),
    negative: Color(0xFFF0685F),
    negativeSoft: Color(0xFF3A1917),
    neutral: Color(0xFFE0B563),
    neutralSoft: Color(0x24E0B563),
    textPrimary: Color(0xFFEDF5EE),
    foregroundMuted: Color(0xFF9FB0A4),
    foregroundSubtle: Color(0xFF67766C),
    textDisabled: Color(0x8067766C),
    hairline: Color(0x14CFE8D5),
    navHairline: Color(0x1FCFE8D5),
    shadowColor: Color(0xFF000000),
    navBg: Color(0xFF101911),
    skeleton: Color(0xFF1B261E),
    // Phase 6 — deliberate lavender/plum secondary accent for the Profile
    // avatar/identity chip only; never brand green, never market data.
    avatarFill: Color(0xFF241F38),
    avatarInk: Color(0xFFC9BFEA),
  );

  // Light — pale, cool mint-white paper canvas (`#F1F7F1`), deep
  // near-black forest-green ink text. Not a re-tint of v4's warm `#F6F0E6`
  // light theme; every surface, text and accent value below is authored
  // fresh from the v5 spec (redesign plan §2A).
  static const _light = AppThemeTokens(
    background: Color(0xFFF1F7F1),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE9F2E9),
    surfaceSunken: Color(0xFFE1EDE1),
    // Phase 1B (HIG alignment): deepened from #1F8A4B by ~2% lightness
    // (same hue/saturation) after design sign-off, specifically to clear
    // the onAccent contrast floor below — was ~4.38:1 with white text,
    // now ~4.55:1. Numerically verified.
    accent: Color(0xFF1E8749),
    // Raw accent measures ~4.0:1 / ~4.4:1 as small text on
    // `background`/`surface` in light mode — fails AA. `accentInk` is a
    // darkened variant of the same hue that clears ~6.0:1 / ~6.6:1,
    // verified numerically for Phase 0. (Still holds after the Phase 1B
    // `accent` deepening — `accentInk` sits well past `accent` already.)
    accentInk: Color(0xFF166B3A),
    accentSoft: Color(0xFFCFE8D8),
    // Phase 1B (HIG alignment): white text on `accent` now measures
    // ~4.55:1, clearing the 4.5:1 AA floor for normal-size text (button
    // labels render at 14px/700, below the large-text cutoff, so the 3:1
    // allowance never applied here). Resolved by deepening `accent` above
    // rather than changing `onAccent` — white remained the max-luminance,
    // correct choice for this role. See decisions log at the bottom of
    // the HIG alignment plan for the sign-off record.
    onAccent: Color(0xFFFFFFFF),
    positive: Color(0xFF1F8A4B),
    positiveSoft: Color(0xFFDCEEE0),
    negative: Color(0xFFD64545),
    negativeSoft: Color(0xFFF7DCDC),
    neutral: Color(0xFFC98A2D),
    neutralSoft: Color(0x24C98A2D),
    textPrimary: Color(0xFF16211B),
    foregroundMuted: Color(0xFF5B6B60),
    foregroundSubtle: Color(0xFF8B968E),
    textDisabled: Color(0x808B968E),
    hairline: Color(0x141A2E22),
    navHairline: Color(0x1F1A2E22),
    shadowColor: Color(0xFFB9CBBB),
    navBg: Color(0xFFFFFFFF),
    skeleton: Color(0xFFE7EEE8),
    // Phase 6 — deliberate lavender/plum secondary accent for the Profile
    // avatar/identity chip only; never brand green, never market data.
    avatarFill: Color(0xFFE1DDF5),
    avatarInk: Color(0xFF4B3F73),
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