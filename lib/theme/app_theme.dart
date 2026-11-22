import 'package:flutter/cupertino.dart'
    show CupertinoPageRoute, NoDefaultCupertinoThemeData;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/ayre_tab_host.dart';

// ─── Investee identity — deep green, ivory, saffron ────────────────────────
//
// Three brand colours: deep green `#0F3D2E`, ivory `#F7F5EF`, saffron
// `#FF9933`. Every other colour is a derived tint/shade of those three.
// Light: ivory canvas, deep-green ink and actions. Dark: the brand green is
// literally the card colour (`surface`), the canvas a deeper shade of it, and
// primary fills invert to ivory.
//
// Saffron is a rare highlight (`highlight*` tokens): graphics and attention
// cues only, never gain/loss, never body text on ivory (use `highlightText`),
// never a primary button fill. Saffron fills always carry `onHighlight`.
// Positive (gain) / negative (loss) / neutral (attention, a yellow-gold that
// cannot be mistaken for saffron) stay separate semantic data colours.
//
// Surface model: `background` → `surface` (cards) → `surfaceRaised` (chips,
// snackbar) → `surfaceSunken` (inputs, tracks). Flat, hairline-bordered; no
// Material surface tint. Dark mode gets depth from lightness steps, not shadow.
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
    required this.positiveText,
    required this.negativeText,
    required this.neutralText,
    required this.highlight,
    required this.onHighlight,
    required this.highlightSoft,
    required this.highlightText,
  });

  /// App canvas: brand ivory in light; a deeper shade of the brand green in
  /// dark. Never pure white/gray (light) or pure black/gray (dark).
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

  /// The primary action/identity colour. Light: brand deep green. Dark:
  /// brand ivory (primary fills invert). Used for primary buttons, selected
  /// states, switches and active nav elements.
  final Color accent;

  /// A darkened (light theme) / lightened (dark theme) accent variant for
  /// small type-weight use (links, selected labels) where the raw [accent]
  /// value doesn't clear 4.5:1 as text on its theme's surfaces — verified
  /// numerically in the v5 Phase 0 contrast pass; only populated where the
  /// raw accent actually differs from a passing value.
  final Color accentInk;

  /// Accent held back for large, low-emphasis fills.
  final Color accentSoft;

  /// Text/icon on an [accent] fill — ivory on deep green in light, deep green
  /// on ivory in dark; 11.15:1 in both themes.
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

  /// Neutral/attention (e.g. a flat/unchanged badge). Yellow-gold, kept
  /// distinct from saffron — never a button fill, never navigation, never
  /// brand. (The LIVE
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

  /// Avatar / identity-chip fill — a brand-green tint. Used only for
  /// personal/identity chips (the Profile initials circle), never for market
  /// data.
  final Color avatarFill;

  /// Initials text on [avatarFill].
  final Color avatarInk;

  /// Gain text and glyphs. Light: a deep market green clearing 4.5:1 on every
  /// light surface. Dark: [positive]. Fills, bars, dots and chart marks keep
  /// [positive].
  final Color positiveText;

  /// Loss text and glyphs. Light: a darker red that clears 4.5:1 on every
  /// light surface; dark: the existing [negative].
  final Color negativeText;

  /// Neutral/flat text and chip text. Light: a darker yellow-gold that clears
  /// 4.5:1; dark: [neutral].
  final Color neutralText;

  /// Saffron highlight (`#FF9933`). Graphics and attention cues only — a
  /// dot, a ring, an underline. Never gain/loss, never a primary fill, and in
  /// light mode never text (1.95:1 on ivory; use [highlightText]).
  final Color highlight;

  /// Content on a [highlight] fill — deep green (5.71:1 on saffron). Never
  /// ivory/white.
  final Color onHighlight;

  /// Low-emphasis saffron tint for an attention wash behind [highlightText].
  final Color highlightSoft;

  /// Saffron-family text. Light: a dark burnt orange that clears 4.5:1 on
  /// ivory/white/[highlightSoft]; dark: saffron itself (5.71:1 on surface).
  final Color highlightText;

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
    Color? positiveText,
    Color? negativeText,
    Color? neutralText,
    Color? highlight,
    Color? onHighlight,
    Color? highlightSoft,
    Color? highlightText,
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
      positiveText: positiveText ?? this.positiveText,
      negativeText: negativeText ?? this.negativeText,
      neutralText: neutralText ?? this.neutralText,
      highlight: highlight ?? this.highlight,
      onHighlight: onHighlight ?? this.onHighlight,
      highlightSoft: highlightSoft ?? this.highlightSoft,
      highlightText: highlightText ?? this.highlightText,
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
      positiveText: c(positiveText, other.positiveText),
      negativeText: c(negativeText, other.negativeText),
      neutralText: c(neutralText, other.neutralText),
      highlight: c(highlight, other.highlight),
      onHighlight: c(onHighlight, other.onHighlight),
      highlightSoft: c(highlightSoft, other.highlightSoft),
      highlightText: c(highlightText, other.highlightText),
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

  /// Tab-to-tab fade in the shell (D-8: routine motion <= 200 ms).
  static const Duration tabFade = Duration(milliseconds: 200);
  static const Duration overlaySlide = Duration(milliseconds: 340);
  static const Duration cardEntrance = Duration(milliseconds: 450);
  static const Duration entranceStagger = Duration(milliseconds: 40);
  static const Duration entranceDelay = Duration(milliseconds: 30);
  static const Duration countUp = Duration(milliseconds: 400);
  static const Duration refreshRotation = Duration(milliseconds: 900);

  /// Chart draw-on (D-8): 700 ms, first reveal only. Reduce-motion snaps.
  static const Duration chartDraw = Duration(milliseconds: 700);

  // `traceDraw` (620ms) lived here as the line trace's own pre-v4 draw-on,
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
  /// D-8: entrance <= 280 ms; with the 4-step stagger the total stays
  /// within ~250 ms of delay.
  static const Duration entrance = Duration(milliseconds: 280);
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
  static const double navLabel = 12;

  /// Apple's minimum; used for the nav label on iOS/macOS only.
  static const double navLabelApple = 11;

  /// Eyebrow/label — uppercase micro-heading.
  static const double eyebrow = 12;

  /// List-row hint / secondary micro-copy.
  static const double hint = 13;

  /// Body / subtitle. Spec range 13.5–15.5; this is the base body size.
  static const double body = 14;

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

  /// Section heading (D-2): sits between page title and content.
  static const double sectionHeading = 17;

  /// Home's time-of-day salutation ("Good morning"). Deliberately larger than
  /// [page]: it is the first thing on the app's first screen.
  static const double greeting = 34;

  /// The user's name, on its own line under the greeting.
  static const double greetingName = 24;

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

  /// Horizontal page gutter by viewport width (D-10): 20 from 360 pt up,
  /// 16 below.
  static double gutterOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 ? 16 : pageHorizontal;

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

  /// Retained alias for call sites (`ayre_components.dart`'s
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
    fontSize: 12,
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

  /// Eyebrow / chip / badge overline: small, uppercase, subtle (D-1: 12 sp,
  /// 0.04 em tracking; no longer used for section headers — see
  /// [sectionHeading]). Sits above every data
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
    letterSpacing: tracking(fontSize, 0.04),
  );

  /// Section heading (D-2): sentence case, 17 sp, w700, primary text.
  static TextStyle sectionHeading(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.sectionHeading,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// Supporting metadata: 12 sp, muted.
  static TextStyle meta(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? t.foregroundMuted,
    height: 1.35,
  );

  /// Bottom-nav label: 12 sp (11 on iOS/macOS), constant w600 so selection
  /// never changes the width.
  static TextStyle navLabel(AppThemeTokens t, {Color? color}) {
    final size = switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS => AppTextScale.navLabelApple,
      _ => AppTextScale.navLabel,
    };
    return ui(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: tracking(size, 0.01),
    );
  }

  static TextStyle button(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.1,
  );
}

// ─── Elevation ladder (D-3) ────────────────────────────────────────────────
/// `flat` = hairline only; `raised` = hairline + one soft shadow, light theme
/// only (dark uses tone, not shadow); `overlay` = nav, sheets.
abstract final class AppElevation {
  static const List<BoxShadow> flat = <BoxShadow>[];

  static List<BoxShadow> raised(AppThemeTokens t, Brightness brightness) {
    if (brightness == Brightness.dark) return flat;
    return [
      BoxShadow(
        color: t.shadowColor.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> overlay(AppThemeTokens t, Brightness brightness) => [
    BoxShadow(
      color: t.shadowColor.withValues(
        alpha: brightness == Brightness.dark ? 0.40 : 0.18,
      ),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

// ─── Theme builder ─────────────────────────────────────────────────────────
abstract final class AppTheme {
  static const Color transparent = Color(0x00000000);

  /// System-bar style for [brightness] (the *effective* theme brightness).
  /// Bars are transparent, icons contrast with the canvas, and the nav-bar
  /// contrast scrim is off so the floating dock never sits on a scrim.
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: transparent,
      systemNavigationBarDividerColor: transparent,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  // Dark — brand-green canvas. `surface` is the exact brand green `#0F3D2E`;
  // `background` is a deeper shade of it. Primary fills invert to ivory.
  // Contrast ratios noted per token are against the stated surface.
  static const _dark = AppThemeTokens(
    background: Color(0xFF0A2A20),
    surface: Color(0xFF0F3D2E),
    surfaceRaised: Color(0xFF174B39),
    surfaceSunken: Color(0xFF061D16),
    // Ivory primary fill; `onAccent` on it is 11.15:1.
    accent: Color(0xFFF7F5EF),
    // 8.94:1 on surface, 7.34:1 on raised.
    accentInk: Color(0xFFBFE6CF),
    // `accentInk` on it 5.93:1, ivory 7.40:1.
    accentSoft: Color(0xFF1E5A45),
    onAccent: Color(0xFF0F3D2E),
    // 6.69:1 on surface, 5.50:1 on raised.
    positive: Color(0xFF4ED892),
    // `positive` on it 5.63:1.
    positiveSoft: Color(0xFF134A33),
    negative: Color(0xFFFF7F76),
    // `negativeText` on it 6.30:1.
    negativeSoft: Color(0xFF4A2A2A),
    neutral: Color(0xFFE3B94F),
    neutralSoft: Color(0x24E3B94F),
    // 14.11:1 on background, 11.15:1 on surface, 9.16:1 on raised.
    textPrimary: Color(0xFFF7F5EF),
    // 8.07:1 on surface, 6.63:1 on raised.
    foregroundMuted: Color(0xFFCBD5CD),
    // 6.61:1 on surface, 5.43:1 on raised.
    foregroundSubtle: Color(0xFFB3C3B9),
    // Deliberately dim (WCAG-exempt); must not read as enabled.
    textDisabled: Color(0x73B3C3B9),
    hairline: Color(0x1AF7F5EF),
    navHairline: Color(0x29F7F5EF),
    shadowColor: Color(0xFF000000),
    navBg: Color(0xFF0B3024),
    skeleton: Color(0xFF174B39),
    // 6.45:1.
    avatarFill: Color(0xFF1E5A45),
    avatarInk: Color(0xFFD6EBDD),
    positiveText: Color(0xFF4ED892),
    // 6.04:1 on surface, 4.96:1 on raised.
    negativeText: Color(0xFFFF9C94),
    // 6.55:1 on surface.
    neutralText: Color(0xFFE3B94F),
    // Saffron: 5.71:1 on surface, 4.69:1 on raised, 7.22:1 on background —
    // usable as text on dark.
    highlight: Color(0xFFFF9933),
    onHighlight: Color(0xFF0F3D2E),
    highlightSoft: Color(0x33FF9933),
    highlightText: Color(0xFFFF9933),
  );

  // Light — brand ivory canvas, brand deep green ink and actions.
  static const _light = AppThemeTokens(
    background: Color(0xFFF7F5EF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEFEDE3),
    surfaceSunken: Color(0xFFE7E4D8),
    accent: Color(0xFF0F3D2E),
    // Ivory on deep green: 11.15:1 (the previous emerald pairing was 4.38:1).
    onAccent: Color(0xFFF7F5EF),
    accentInk: Color(0xFF0F3D2E),
    // `accentInk` on it 9.73:1.
    accentSoft: Color(0xFFDDE9E0),
    // 4.63:1 on background (graphic use, >= 3:1).
    positive: Color(0xFF1A7F44),
    // `positiveText` on it 5.32:1.
    positiveSoft: Color(0xFFDDEBDD),
    negative: Color(0xFFD64545),
    // `negativeText` on it 4.58:1.
    negativeSoft: Color(0xFFF7DCDC),
    // Yellow-gold, shifted from orange-gold so it cannot read as saffron.
    neutral: Color(0xFFA67C00),
    neutralSoft: Color(0x24A67C00),
    // 11.15:1 on background, 12.16:1 on surface, 10.36:1 on raised.
    textPrimary: Color(0xFF0F3D2E),
    // 6.92:1 on background, 6.43:1 on raised.
    foregroundMuted: Color(0xFF3F5A4E),
    // 5.90:1 on background, 5.48:1 on raised, 5.05:1 on sunken.
    foregroundSubtle: Color(0xFF506358),
    textDisabled: Color(0x80506358),
    hairline: Color(0x1A0F3D2E),
    navHairline: Color(0x290F3D2E),
    shadowColor: Color(0xFFD2CFC0),
    navBg: Color(0xFFFFFFFF),
    skeleton: Color(0xFFE9E6DA),
    // 9.73:1.
    avatarFill: Color(0xFFDDE9E0),
    avatarInk: Color(0xFF0F3D2E),
    // 6.03:1 on background, 5.60:1 on raised.
    positiveText: Color(0xFF156B3A),
    // 5.44:1 on background, 5.93:1 on white, 5.05:1 on raised.
    negativeText: Color(0xFFB83232),
    // 5.85:1 on background.
    neutralText: Color(0xFF7A5A00),
    // Saffron is graphics-only on ivory (1.95:1); text uses `highlightText`.
    highlight: Color(0xFFFF9933),
    // 5.71:1 on saffron.
    onHighlight: Color(0xFF0F3D2E),
    highlightSoft: Color(0x29FF9933),
    // 6.57:1 on ivory, 7.16:1 on white, 6.05:1 on `highlightSoft`.
    highlightText: Color(0xFF8A4500),
  );

  static AppThemeTokens get lightTokens => _light;
  static AppThemeTokens get darkTokens => _dark;

  static ThemeData get light => _build(Brightness.light, _light);
  static ThemeData get dark => _build(Brightness.dark, _dark);

  static ThemeData _build(Brightness brightness, AppThemeTokens t) {
    final isDark = brightness == Brightness.dark;

    // `error` must carry a >= 4.5:1 `onError`: white on the light glyph red
    // (`#D64545`) is 4.38:1, so light uses the text red (5.93:1 with white).
    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      secondary: t.accentSoft,
      onSecondary: t.accentInk,
      tertiary: t.highlight,
      onTertiary: t.onHighlight,
      error: isDark ? t.negative : t.negativeText,
      onError: isDark ? t.background : const Color(0xFFFFFFFF),
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.foregroundMuted,
      outline: t.hairline,
      outlineVariant: t.navHairline,
      shadow: t.shadowColor,
      scrim: const Color(0xFF04140F),
      surfaceTint: transparent,
      surfaceDim: t.background,
      surfaceBright: t.surface,
      surfaceContainerLowest: t.surfaceSunken,
      surfaceContainerLow: t.background,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surfaceRaised,
      surfaceContainerHighest: t.surfaceRaised,
      inverseSurface: t.textPrimary,
      onInverseSurface: t.background,
      inversePrimary: t.accentInk,
      primaryContainer: t.accentSoft,
      onPrimaryContainer: t.accentInk,
      secondaryContainer: t.accentSoft,
      onSecondaryContainer: t.accentInk,
      tertiaryContainer: t.highlightSoft,
      onTertiaryContainer: t.highlightText,
      errorContainer: t.negativeSoft,
      onErrorContainer: t.negativeText,
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
        systemOverlayStyle: overlayStyle(brightness),
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
        selectionColor: t.accent.withValues(alpha: 0.24),
        selectionHandleColor: t.accentInk,
      ),
      splashColor: t.accent.withValues(alpha: 0.08),
      highlightColor: t.accent.withValues(alpha: 0.05),
      iconTheme: IconThemeData(color: t.textPrimary),
      primaryIconTheme: IconThemeData(color: t.textPrimary),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        shadowColor: transparent,
        titleTextStyle: AppTypo.sectionTitle(t),
        contentTextStyle: AppTypo.body(t),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: t.hairline),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        shadowColor: transparent,
        textStyle: AppTypo.bodyStrong(t),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: t.hairline),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surface),
          surfaceTintColor: const WidgetStatePropertyAll(transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              side: BorderSide(color: t.hairline),
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: t.hairline),
        ),
        textStyle: AppTypo.ui(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.onAccent
              : t.foregroundSubtle,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.accent
              : t.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? transparent
              : t.hairline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? t.accent : transparent,
        ),
        checkColor: WidgetStatePropertyAll(t.onAccent),
        side: BorderSide(color: t.foregroundSubtle, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.accent
              : t.foregroundSubtle,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textPrimary,
        textColor: t.textPrimary,
        tileColor: transparent,
        selectedColor: t.accentInk,
        selectedTileColor: t.accentSoft,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          t.foregroundSubtle.withValues(alpha: 0.5),
        ),
        trackColor: const WidgetStatePropertyAll(transparent),
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: t.accent,
        scaffoldBackgroundColor: t.background,
        barBackgroundColor: t.navBg,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
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

/// Phase 2C primitive: a push that keeps iOS's native swipe-to-go-back
/// gesture on iOS/macOS, where `TerminalPageTransitions` (installed as the
/// app-wide `PageTransitionsTheme` builder) otherwise loses it — a plain
/// `PageTransitionsBuilder` carries no pop-gesture recognizer unless it is
/// `CupertinoPageTransitionsBuilder`/`CupertinoRouteTransitionMixin`
/// specifically. On iOS/macOS this pushes a real `CupertinoPageRoute`,
/// which supplies the swipe gesture along with Cupertino's own parallax
/// transition (not `TerminalPageTransitions`'s slide+fade curve — the two
/// are not reconcilable without forking Cupertino's private back-gesture
/// detector, which is out of this phase's scope). Elsewhere this pushes a
/// plain `MaterialPageRoute`, unchanged, which keeps `TerminalPageTransitions`
/// via the theme as before.
///
/// Introduced as the reusable primitive this phase's finding calls for;
/// call sites in `lib/screens/*.dart` still use bare
/// `Navigator.push(MaterialPageRoute(...))` and were not individually
/// rewired onto this — those files are outside Phase 2's listed scope
/// (`app_theme.dart`, `home_shell.dart`, `ayre_bottom_nav.dart`, the tab
/// screens' breakpoint/`ContentWidth` usage), and rewiring every push site
/// app-wide is flagged here as follow-up work rather than done silently
/// alongside it.
Route<T> terminalRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  // Inside a tab navigator (A3) the page ends above the floating dock;
  // anywhere else `AyreDockClearance` does nothing.
  Widget wrapped(BuildContext context) =>
      AyreDockClearance(child: builder(context));
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS ||
    TargetPlatform.macOS => CupertinoPageRoute<T>(
      builder: wrapped,
      settings: settings,
    ),
    _ => MaterialPageRoute<T>(builder: wrapped, settings: settings),
  };
}