import 'package:flutter/cupertino.dart'
    show CupertinoPageRoute, NoDefaultCupertinoThemeData;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/ayre_tab_host.dart';

// ─── Investee design system — the HTML "Visual Overhaul" is the source ────
//
// Semantic roles map 1:1 to the reference CSS variables (`.L` light, `.D`
// dark):
//   --bg → background · --card → surface · --ink → textPrimary
//   --brand → accent · --mut → foregroundMuted · --line → hairline
//   --soft → surfaceRaised/surfaceSunken · --gs → positiveSoft
//   --up → positive · --dn → negative
//   --mb/--mi/--mm/--gb/--gh → [AppThemeTokens.mast] (sage mast palette)
// Saffron `#FF9933` is the notch / logo / unread cue only: never gain/loss,
// never body text on ivory (use `highlightText`).
//
// Surface model: `background` → `surface` (cards) → `surfaceRaised` (tiles,
// segmented tracks) → `surfaceSunken` (tracks, skeletons). Cards are flat and
// opaque-bordered; shadows appear only on the explicitly raised hero surfaces.

/// One mast variant: fill plus the ink, muted ink, translucent glass plate and
/// watermark-motif colours that sit on it.
@immutable
class MastPalette {
  const MastPalette({
    required this.fill,
    required this.ink,
    required this.muted,
    required this.glass,
    required this.motif,
  });

  const MastPalette._lightTab(this.fill)
    : ink = const Color(0xFFF7F5EF),
      muted = const Color(0xFFDEE8E1),
      glass = const Color(0x1AF7F5EF),
      motif = const Color(0x0DF7F5EF);

  const MastPalette._darkTab(this.fill, this.muted)
    : ink = const Color(0xFFF2EFE6),
      glass = const Color(0x1AF2EFE6),
      motif = const Color(0x0DF2EFE6);

  /// `--mb` — the mast backdrop.
  final Color fill;

  /// `--mi` — title ink.
  final Color ink;

  /// `--mm` — secondary text on the mast.
  final Color muted;

  /// `--gb` — header icon plates and pills.
  final Color glass;

  /// `--gh` — the decorative block watermark.
  final Color motif;

  MastPalette copyWith({
    Color? fill,
    Color? ink,
    Color? muted,
    Color? glass,
    Color? motif,
  }) => MastPalette(
    fill: fill ?? this.fill,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    glass: glass ?? this.glass,
    motif: motif ?? this.motif,
  );

  static MastPalette lerp(MastPalette a, MastPalette b, double t) =>
      MastPalette(
        fill: Color.lerp(a.fill, b.fill, t)!,
        ink: Color.lerp(a.ink, b.ink, t)!,
        muted: Color.lerp(a.muted, b.muted, t)!,
        glass: Color.lerp(a.glass, b.glass, t)!,
        motif: Color.lerp(a.motif, b.motif, t)!,
      );

  /// Whether text/icons drawn *over* [fill] should be light (the fill is dark).
  bool get isDark => fill.computeLuminance() < 0.4;
}

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
    required this.mast,
    required this.mastChampagne,
    required this.mastHome,
    required this.mastReports,
    required this.mastLearn,
    required this.mastProfile,
    required this.notch,
    required this.homeAvatarFill,
    required this.homeAvatarInk,
    required this.focusRing,
    required this.scrim,
    required this.splashTrack,
  });

  /// `--bg` — page canvas / scaffold.
  final Color background;

  /// `--card` — cards, dialogs, sheets, the dock, input fields.
  final Color surface;

  /// `--soft` — icon tiles, insets, segmented tracks, subordinate data.
  final Color surfaceRaised;

  /// A tonal fill recessed into its parent (progress tracks, skeletons).
  final Color surfaceSunken;

  /// `--brand` — primary fills, selected nav / segments, switches.
  final Color accent;

  /// Brand colour for small text and glyphs (links, selected labels).
  final Color accentInk;

  /// Low-emphasis brand wash.
  final Color accentSoft;

  /// Content on an [accent] fill: the page background of the same theme
  /// (ivory on deep green, near-black on leaf).
  final Color onAccent;

  /// `--up` — gain fills, bars and glyphs.
  final Color positive;

  /// `--gs` — success chip / verification background.
  final Color positiveSoft;

  /// `--dn` — loss and destructive actions only.
  final Color negative;

  /// Outcome / destructive tint (12% negative over the card in light).
  final Color negativeSoft;

  /// Stale / attention foreground: subdued amber-brown. Never market red.
  final Color neutral;

  /// Champagne fill behind [neutral] text (stale plate, offline banner).
  final Color neutralSoft;

  /// `--ink` — primary text and default icon colour.
  final Color textPrimary;

  /// `--mut` — captions and secondary copy.
  final Color foregroundMuted;

  /// Tertiary text. The reference defines no lighter tier, so this equals
  /// [foregroundMuted]; information must never rely on anything fainter.
  final Color foregroundSubtle;

  /// Disabled text: muted at 60% over the surface.
  final Color textDisabled;

  /// `--line` — opaque 1px card/field/divider border.
  final Color hairline;

  /// The dock's top edge (same opaque line).
  final Color navHairline;

  /// Base colour for the reference shadows (alpha applied at use).
  final Color shadowColor;

  /// Dock / rail fill (the card colour).
  final Color navBg;

  /// Skeleton base fill (`--soft`).
  final Color skeleton;

  /// Profile identity tile fill (`--soft`).
  final Color avatarFill;

  /// Initials on [avatarFill].
  final Color avatarInk;

  /// Gain text and glyphs (`--up`).
  final Color positiveText;

  /// Loss text and glyphs (`--dn`).
  final Color negativeText;

  /// Stale / attention text on [neutralSoft].
  final Color neutralText;

  /// Saffron `#FF9933` — logo, notch, unread dot, active-tab cue.
  final Color highlight;

  /// Content on a [highlight] fill (the reference NEW badge `#2B1600`).
  final Color onHighlight;

  /// Low-emphasis saffron tint.
  final Color highlightSoft;

  /// Saffron-family text that clears 4.5:1 on its theme's surfaces.
  final Color highlightText;

  /// Default sage or dark-green mast.
  final MastPalette mast;

  /// Champagne mast for Create account.
  final MastPalette mastChampagne;

  /// Home mast in the two app themes.
  final MastPalette mastHome;

  /// The remaining tab mastheads, in order of increasing lightness after Home.
  final MastPalette mastReports;
  final MastPalette mastLearn;
  final MastPalette mastProfile;

  /// The saffron card notch / dock marker (same as [highlight], kept as its
  /// own role so it can diverge from text uses of saffron).
  final Color notch;

  /// Home account-initials circle fill (ivory in both themes).
  final Color homeAvatarFill;

  /// Initials on [homeAvatarFill] (deep green in both themes).
  final Color homeAvatarInk;

  /// Focus outline for keyboard / pointer focus.
  final Color focusRing;

  /// Modal barrier (ink / black at 50–60%).
  final Color scrim;

  /// Splash indicator track.
  final Color splashTrack;

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
    MastPalette? mast,
    MastPalette? mastChampagne,
    MastPalette? mastHome,
    MastPalette? mastReports,
    MastPalette? mastLearn,
    MastPalette? mastProfile,
    Color? notch,
    Color? homeAvatarFill,
    Color? homeAvatarInk,
    Color? focusRing,
    Color? scrim,
    Color? splashTrack,
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
      mast: mast ?? this.mast,
      mastChampagne: mastChampagne ?? this.mastChampagne,
      mastHome: mastHome ?? this.mastHome,
      mastReports: mastReports ?? this.mastReports,
      mastLearn: mastLearn ?? this.mastLearn,
      mastProfile: mastProfile ?? this.mastProfile,
      notch: notch ?? this.notch,
      homeAvatarFill: homeAvatarFill ?? this.homeAvatarFill,
      homeAvatarInk: homeAvatarInk ?? this.homeAvatarInk,
      focusRing: focusRing ?? this.focusRing,
      scrim: scrim ?? this.scrim,
      splashTrack: splashTrack ?? this.splashTrack,
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
      mast: MastPalette.lerp(mast, other.mast, t),
      mastChampagne: MastPalette.lerp(mastChampagne, other.mastChampagne, t),
      mastHome: MastPalette.lerp(mastHome, other.mastHome, t),
      mastReports: MastPalette.lerp(mastReports, other.mastReports, t),
      mastLearn: MastPalette.lerp(mastLearn, other.mastLearn, t),
      mastProfile: MastPalette.lerp(mastProfile, other.mastProfile, t),
      notch: c(notch, other.notch),
      homeAvatarFill: c(homeAvatarFill, other.homeAvatarFill),
      homeAvatarInk: c(homeAvatarInk, other.homeAvatarInk),
      focusRing: c(focusRing, other.focusRing),
      scrim: c(scrim, other.scrim),
      splashTrack: c(splashTrack, other.splashTrack),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

// ─── Radii ─────────────────────────────────────────────────────────────────
// The scalar constants remain for existing consumers (and now carry the new
// values); the asymmetric card/button silhouettes live in [AppShape].
abstract final class AppRadius {
  /// Large corner of the card silhouette (the small TL corner is [small]).
  static const double card = 26;

  /// The small top-left corner shared by cards and buttons.
  static const double small = 8;

  /// Large corners of the button silhouette.
  static const double buttonLarge = 28;

  /// Chips, fields, segments, tiles and compact icon controls.
  static const double chip = 13;
  static const double inset = 13;
  static const double control = 13;
  static const double iconTile = 13;

  /// Selected segment inside a segmented track.
  static const double segmentSelected = 10;

  /// Sheet top corners.
  static const double sheet = 26;

  static const double pill = 999;
  static const double circle = 999;

  /// Retained scalar for legacy `BorderRadius.circular(AppRadius.button)`
  /// call sites: [buttonLarge] (visually a pill at the 55px height).
  static const double button = buttonLarge;
}

/// Asymmetric silhouettes and geometry from the reference. A single scalar
/// radius cannot express them, so shapes are encoded explicitly.
abstract final class AppShape {
  /// Card: TL 8, TR/BR/BL 26.
  static const BorderRadius card = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.small),
    topRight: Radius.circular(AppRadius.card),
    bottomRight: Radius.circular(AppRadius.card),
    bottomLeft: Radius.circular(AppRadius.card),
  );

  /// Button: TL 8, TR/BR/BL 28.
  static const BorderRadius button = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.small),
    topRight: Radius.circular(AppRadius.buttonLarge),
    bottomRight: Radius.circular(AppRadius.buttonLarge),
    bottomLeft: Radius.circular(AppRadius.buttonLarge),
  );

  /// Fields, segments, tiles, compact icon controls.
  static const BorderRadius field = BorderRadius.all(
    Radius.circular(AppRadius.control),
  );

  /// Selected segment inside the soft track.
  static const BorderRadius segmentSelected = BorderRadius.all(
    Radius.circular(AppRadius.segmentSelected),
  );

  /// Bottom sheet and dock top corners.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(AppRadius.sheet),
  );

  /// Saffron notch: 21 from the card's left edge, y = −1, 21×5, bottom
  /// corners 2.
  static const double notchInset = 21;
  static const double notchWidth = 21;
  static const double notchHeight = 5;
  static const double notchOffsetY = -1;
  static const BorderRadius notch = BorderRadius.vertical(
    bottom: Radius.circular(2),
  );

  /// Minimum visual height of buttons and inputs.
  static const double controlHeight = 55;

  /// Standard icon tile edge (44) and prominent tile edge (55).
  static const double iconTileSize = 44;
  static const double prominentTileSize = 55;

  /// Switch track 44×26, thumb 20, inset 3.
  static const double switchWidth = 44;
  static const double switchHeight = 26;
  static const double switchThumb = 20;
  static const double switchInset = 3;

  /// Minimum mast heights and the rise at the right edge.
  static const double mastHome = 214;
  static const double mastTab = 146;
  static const double mastLogin = 322;
  static const double mastRegister = 233;
  static const double mastDiagonal = 55;
  static const double tabMastDiagonal = 34;

  /// Summary / identity cards overlap the mast bottom by this much.
  static const double mastOverlap = 21;

  /// A card surface: fill, opaque 1px line and the asymmetric radius.
  static BoxDecoration cardDecoration(
    AppThemeTokens t, {
    Color? color,
    List<BoxShadow>? shadows,
    BorderRadius radius = card,
  }) => BoxDecoration(
    color: color ?? t.surface,
    borderRadius: radius,
    border: Border.all(color: t.hairline),
    boxShadow: shadows,
  );

  /// The same silhouette as a [ShapeBorder] (Material `shape:` slots).
  static RoundedRectangleBorder cardBorder(
    AppThemeTokens t, {
    BorderRadius radius = card,
  }) => RoundedRectangleBorder(
    borderRadius: radius,
    side: BorderSide(color: t.hairline),
  );
}

// ─── Motion ────────────────────────────────────────────────────────────────
// Calm and non-bouncy: cards rise 13px and fade with a 55ms stagger, the dock
// marker slides 233ms, the range draws 377ms once, figures count up once.
abstract final class AppMotion {
  /// `cubic-bezier(0.22, 1, 0.36, 1)` — an ease-out with no overshoot.
  static const Curve ease = Cubic(0.22, 1, 0.36, 1);
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Press feedback (opacity / scale).
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration pageTransition = Duration(milliseconds: 280);

  /// Tab-to-tab content fade in the shell.
  static const Duration tabFade = Duration(milliseconds: 200);

  /// Sheets and modals (280–340ms).
  static const Duration overlaySlide = Duration(milliseconds: 340);

  /// Card entrance: [entranceRise] px up + fade.
  static const Duration cardEntrance = Duration(milliseconds: 280);
  static const double entranceRise = 13;
  static const Duration entranceStagger = Duration(milliseconds: 55);
  static const Duration entranceDelay = Duration(milliseconds: 30);

  /// Count-up on first real data only.
  static const Duration countUp = Duration(milliseconds: 400);
  static const Duration refreshRotation = Duration(milliseconds: 900);

  /// The selected-destination marker glides between item centres.
  static const Duration navMarker = Duration(milliseconds: 233);

  /// Theme switch interpolation.
  static const Duration themeSwitch = Duration(milliseconds: 233);

  /// Recommendation range reveal, once per new valid content.
  static const Duration rangeDraw = Duration(milliseconds: 377);

  /// Chart draw-on; shares the range timing.
  static const Duration chartDraw = rangeDraw;

  /// Expand / fold / filter size changes (150–280ms).
  static const Duration expand = Duration(milliseconds: 233);

  /// Generic fallback for call sites not yet reconciled.
  static const Duration slow = Duration(milliseconds: 400);

  /// Retained for the one existing digit-settle call site.
  static const Duration digitRoll = Duration(milliseconds: 420);

  // Retained aliases for components not yet migrated.
  static const Duration fast = buttonPress;
  static const Duration medium = pageTransition;
  static const Duration entrance = cardEntrance;
  static const Duration stagger = entranceStagger;
}

/// The type scale (logical px at the 390 reference).
abstract final class AppTextScale {
  /// Dock label.
  static const double navLabel = 11;
  static const double navLabelApple = 11;

  /// Eyebrow / section label / chip.
  static const double eyebrow = 11;
  static const double chip = 11;

  /// Field label, date/detail, notice, secondary caption.
  static const double fieldLabel = 12;
  static const double notice = 12;

  /// Hint / body copy.
  static const double hint = 13;
  static const double body = 13;

  /// Subtitle, greeting.
  static const double subtitle = 15;

  /// Row label, button, auth field content.
  static const double rowLabel = 15;
  static const double button = 15;

  /// Small heading, profit/share.
  static const double sectionHeading = 17;

  /// Signal level price.
  static const double levelPrice = 20;

  /// Section title / card ticker.
  static const double cardTitle = 21;
  static const double featuredHeadline = 21;

  /// Main title / stat count / report percentage.
  static const double page = 34;
  static const double stat = 34;

  /// Reference Home greeting (15) and name (40). Used by the new `homeName` /
  /// subtitle roles in Phase 4.
  static const double homeGreeting = 15;
  static const double homeName = 40;

  /// Legacy salutation sizes, retained unchanged for the current Home and
  /// onboarding call sites until their phases migrate them.
  static const double greeting = 34;
  static const double greetingName = 24;

  /// Sign-in title.
  static const double signInTitle = 44;

  /// Display financial hero.
  static const double hero = 55;
  static const double heroXL = 55;
}

/// Spacing: golden-ratio-inspired sequence (8, 13, 21, 34, 55, 89) for named
/// roles, with the 4px ladder retained for micro-spacing and existing call
/// sites.
abstract final class AppSpace {
  // The reference sequence.
  static const double s8 = 8;
  static const double s13 = 13;
  static const double s21 = 21;
  static const double s26 = 26;
  static const double s34 = 34;
  static const double s55 = 55;
  static const double s89 = 89;

  // Micro / generic ladder.
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Page horizontal padding / gutter at the reference width.
  static const double pageHorizontal = 21;

  /// Page top padding for headerless pages.
  static const double pageTop = 13;

  /// Gutter by viewport width: 21 from 360 up, 16 below, 13 on very narrow
  /// windows.
  static double gutterOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 340) return 13;
    if (w < 360) return 16;
    return pageHorizontal;
  }

  /// Gap above a section label / between major sections.
  static const double sectionGap = md;

  /// Gap between sibling cards and rows.
  static const double cardGap = 13;

  /// Card internal padding.
  static const double cardPadding = 21;
  static const double cardVerticalPadding = s13;

  /// Gap between elements inside a card.
  static const double inCardGap = 13;

  /// Vertical padding of a hairline-divided row.
  static const double hairlineRowPadding = s8;
  static const double row = hairlineRowPadding;

  /// Section label gap below.
  static const double sectionLabelBelow = 6;

  /// Minimum tappable dimension.
  static const double minTarget = 48;
}

// ─── Typography: Manrope everywhere ────────────────────────────────────────
// Bundled static weights 500/600/700/800 (assets/fonts, SIL OFL). No network
// at first launch. Glyphs Manrope lacks (e.g. Devanagari) fall back to the
// platform font via Flutter's normal fallback.
abstract final class AppTypo {
  static const String family = 'Manrope';

  /// Converts a CSS `em` tracking value into Flutter's absolute px.
  static double tracking(double fontSize, double em) => em * fontSize;

  static TextStyle _m({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  /// Headings and display text (default 800, tight tracking).
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _m(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing ?? -0.3,
  );

  /// Body and UI text.
  static TextStyle ui({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _m(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Every financial figure, date and count: Manrope with tabular figures so
  /// values never reflow. Signed minus, ₹ and Indian grouping are formatting
  /// concerns of the callers and render from the bundled glyphs.
  static TextStyle num({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _m(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    tabular: true,
  );

  /// Retained alias of [num] for existing call sites.
  static TextStyle ticker({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
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

  /// Main title / stat count: 34 / 800 / 1.1 / −0.8.
  static TextStyle pageTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: AppTextScale.page,
    color: color ?? t.textPrimary,
    height: 1.1,
    letterSpacing: -0.8,
  );

  /// Sign-in title: 44 / 800 / 1.1 / −0.8.
  static TextStyle signInTitle(AppThemeTokens t, {Color? color}) => display(
    fontSize: AppTextScale.signInTitle,
    color: color ?? t.textPrimary,
    height: 1.1,
    letterSpacing: -0.8,
  );

  /// Home name: 40 / 800 / 1.1 / −0.8.
  static TextStyle homeName(AppThemeTokens t, {Color? color}) => display(
    fontSize: AppTextScale.homeName,
    color: color ?? t.textPrimary,
    height: 1.1,
    letterSpacing: -0.8,
  );

  /// Stat count: 34 / 800 / 1.1 / −0.8, tabular.
  static TextStyle stat(AppThemeTokens t, {Color? color}) => num(
    fontSize: AppTextScale.stat,
    fontWeight: FontWeight.w800,
    color: color ?? t.textPrimary,
    height: 1.1,
    letterSpacing: -0.8,
  );

  /// Report percentage: 34 / 800 / 1.0 / −0.8, tabular.
  static TextStyle reportPercent(AppThemeTokens t, {Color? color}) => num(
    fontSize: AppTextScale.stat,
    fontWeight: FontWeight.w800,
    color: color ?? t.textPrimary,
    height: 1.0,
    letterSpacing: -0.8,
  );

  /// Section title / card ticker: 21 / 800 / 1.2 / −0.3.
  static TextStyle featuredHeadline(AppThemeTokens t, {Color? color}) =>
      display(
        fontSize: AppTextScale.featuredHeadline,
        color: color ?? t.textPrimary,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle sectionTitle(AppThemeTokens t, {Color? color}) =>
      featuredHeadline(t, color: color);

  static TextStyle cardTitle(AppThemeTokens t, {Color? color}) =>
      featuredHeadline(t, color: color);

  // ── Numeric roles ────────────────────────────────────────────────────────

  /// Display financial hero: 55 / 800 / 1.0 / −1.5.
  static TextStyle heroValue(AppThemeTokens t, {Color? color}) => num(
    fontSize: AppTextScale.hero,
    fontWeight: FontWeight.w800,
    color: color ?? t.textPrimary,
    height: 1.0,
    letterSpacing: -1.5,
  );

  /// Signal level price: 20 / 800 / −0.4, tabular.
  static TextStyle levelPrice(AppThemeTokens t, {Color? color}) => num(
    fontSize: AppTextScale.levelPrice,
    fontWeight: FontWeight.w800,
    color: color ?? t.textPrimary,
    letterSpacing: -0.4,
  );

  static TextStyle value(
    AppThemeTokens t, {
    Color? color,
    double fontSize = 14,
  }) => num(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
  );

  static TextStyle valueSmall(AppThemeTokens t, {Color? color}) => num(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color ?? t.foregroundMuted,
    letterSpacing: 0,
  );

  // ── UI roles ─────────────────────────────────────────────────────────────

  /// Body: 13 / 500 / 1.4.
  static TextStyle body(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.body,
    fontWeight: FontWeight.w500,
    color: color ?? t.foregroundMuted,
    height: 1.4,
  );

  /// Emphasised body / subtitle strong: 14 / 700.
  static TextStyle bodyStrong(AppThemeTokens t, {Color? color}) => ui(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
    height: 1.4,
  );

  /// Subtitle / greeting: 15 / 500 / 1.4, muted.
  static TextStyle subtitle(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.subtitle,
    fontWeight: FontWeight.w500,
    color: color ?? t.foregroundMuted,
    height: 1.4,
  );

  /// Reading copy (legal, lessons, notes): 15 / 500 / 1.55.
  static TextStyle reading(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.subtitle,
    fontWeight: FontWeight.w500,
    color: color ?? t.textPrimary,
    height: 1.55,
  );

  /// Row label: 15 / 700.
  static TextStyle rowLabel(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.rowLabel,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
  );

  /// Hint / secondary line: 13 / 500 / 1.4, muted.
  static TextStyle hint(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.hint,
    fontWeight: FontWeight.w500,
    color: color ?? t.foregroundMuted,
    height: 1.4,
  );

  static TextStyle caption(AppThemeTokens t, {Color? color}) =>
      hint(t, color: color);

  /// Eyebrow / section label: 11 / 800 / +1.2 tracking (px). Callers apply
  /// upper-casing.
  static TextStyle label(
    AppThemeTokens t, {
    Color? color,
    double fontSize = AppTextScale.eyebrow,
  }) => ui(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: color ?? t.foregroundMuted,
    letterSpacing: 1.2,
  );

  /// Field label: 12 / 700.
  static TextStyle fieldLabel(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.fieldLabel,
    fontWeight: FontWeight.w700,
    color: color ?? t.textPrimary,
  );

  /// Auth field content: 15 / 600.
  static TextStyle fieldValue(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.rowLabel,
    fontWeight: FontWeight.w600,
    color: color ?? t.textPrimary,
  );

  /// Chip: 11 / 800.
  static TextStyle chip(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.chip,
    fontWeight: FontWeight.w800,
    color: color ?? t.textPrimary,
  );

  /// Small heading / profit per share: 17 / 800.
  static TextStyle sectionHeading(AppThemeTokens t, {Color? color}) => display(
    fontSize: AppTextScale.sectionHeading,
    color: color ?? t.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// Supporting metadata / notice: 12 / 500 / 1.4, muted.
  static TextStyle meta(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.notice,
    fontWeight: FontWeight.w500,
    color: color ?? t.foregroundMuted,
    height: 1.4,
  );

  /// Dock label: 11 / 700 on every platform, constant weight so selection
  /// never changes the width.
  static TextStyle navLabel(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.navLabel,
    fontWeight: FontWeight.w700,
    color: color,
  );

  /// Button: 15 / 800.
  static TextStyle button(AppThemeTokens t, {Color? color}) => ui(
    fontSize: AppTextScale.button,
    fontWeight: FontWeight.w800,
    color: color,
  );
}

// ─── Elevation ─────────────────────────────────────────────────────────────
/// Most cards are flat with a border. Shadows appear only on the explicitly
/// raised hero surfaces (Home card; report summary / profile identity at a
/// slightly stronger alpha).
abstract final class AppElevation {
  static const List<BoxShadow> flat = <BoxShadow>[];

  /// Reference: offset (0, 13), blur 34, `rgba(7,34,25,.10)`.
  static List<BoxShadow> raised(AppThemeTokens t, Brightness brightness) => [
    BoxShadow(
      color: t.shadowColor.withValues(
        alpha: brightness == Brightness.dark ? 0.32 : 0.10,
      ),
      blurRadius: 34,
      offset: const Offset(0, 13),
    ),
  ];

  /// Report summary / profile identity: `.13`.
  static List<BoxShadow> raisedStrong(
    AppThemeTokens t,
    Brightness brightness,
  ) => [
    BoxShadow(
      color: t.shadowColor.withValues(
        alpha: brightness == Brightness.dark ? 0.40 : 0.13,
      ),
      blurRadius: 34,
      offset: const Offset(0, 13),
    ),
  ];

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

  /// System-bar style for [brightness] (the *effective* theme brightness):
  /// transparent status bar with icons contrasting the page canvas; the
  /// Android navigation bar takes the dock/page colour so the dock meets the
  /// window edge without a seam.
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final t = dark ? _dark : _light;
    return SystemUiOverlayStyle(
      statusBarColor: transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: t.navBg,
      systemNavigationBarDividerColor: transparent,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  /// Like [overlayStyle], but status-bar icons contrast [statusSurface] (a
  /// mast fill, e.g. light icons over the deep-green Home mast).
  static SystemUiOverlayStyle overlayStyleOver(
    Color statusSurface,
    Brightness brightness,
  ) {
    final base = overlayStyle(brightness);
    final darkSurface = statusSurface.computeLuminance() < 0.4;
    return base.copyWith(
      statusBarIconBrightness: darkSurface ? Brightness.light : Brightness.dark,
      statusBarBrightness: darkSurface ? Brightness.dark : Brightness.light,
    );
  }

  static const _darkStandardMast = MastPalette._darkTab(
    Color(0xFF1B2B22),
    Color(0xFFB3C0B8),
  );

  static const _darkChampagneMast = MastPalette(
    fill: Color(0xFF2C2819),
    ink: Color(0xFFF2EFE6),
    muted: Color(0xFFCFC6A4),
    glass: Color(0x1AF2EFE6),
    motif: Color(0x0DF2EFE6),
  );

  // Dark — near-black green canvas, charcoal-green cards, leaf accent.
  static const _dark = AppThemeTokens(
    background: Color(0xFF0F1512),
    surface: Color(0xFF18211C),
    surfaceRaised: Color(0xFF202C26),
    surfaceSunken: Color(0xFF202C26),
    accent: Color(0xFF3FAE7C),
    accentInk: Color(0xFF3FAE7C),
    accentSoft: Color(0xFF202C26),
    // The reference page background: near-black on leaf.
    onAccent: Color(0xFF0F1512),
    positive: Color(0xFF5FD39A),
    positiveSoft: Color(0xFF1C3B2D),
    negative: Color(0xFFF08A77),
    // 16% of the dark negative over the card (the literal 12% is too faint).
    negativeSoft: Color(0x29F08A77),
    // Stale / attention: champagne foreground on the dark champagne fill.
    neutral: Color(0xFFCFC6A4),
    neutralSoft: Color(0xFF2C2819),
    textPrimary: Color(0xFFF2EFE6),
    foregroundMuted: Color(0xFFA3B0A8),
    foregroundSubtle: Color(0xFFA3B0A8),
    // Muted at 60% over the surface.
    textDisabled: Color(0x99A3B0A8),
    hairline: Color(0xFF27342D),
    navHairline: Color(0xFF27342D),
    shadowColor: Color(0xFF000000),
    navBg: Color(0xFF18211C),
    skeleton: Color(0xFF202C26),
    avatarFill: Color(0xFF202C26),
    avatarInk: Color(0xFFF2EFE6),
    positiveText: Color(0xFF5FD39A),
    negativeText: Color(0xFFF08A77),
    neutralText: Color(0xFFCFC6A4),
    highlight: Color(0xFFFF9933),
    // Filled NEW badge foreground, as shown in the reference.
    onHighlight: Color(0xFF2B1600),
    highlightSoft: Color(0x33FF9933),
    highlightText: Color(0xFFFF9933),
    mast: _darkStandardMast,
    mastChampagne: _darkChampagneMast,
    // The standard green starts the progression from Home to Profile.
    mastHome: _darkStandardMast,
    mastReports: MastPalette._darkTab(Color(0xFF24382D), Color(0xFFB9C6BE)),
    mastLearn: MastPalette._darkTab(Color(0xFF2D4538), Color(0xFFBFCCC4)),
    mastProfile: MastPalette._darkTab(Color(0xFF365243), Color(0xFFC5D2CA)),
    notch: Color(0xFFFF9933),
    homeAvatarFill: Color(0xFFF7F5EF),
    homeAvatarInk: Color(0xFF0F3D2E),
    focusRing: Color(0xFF3FAE7C),
    // Black at 60%.
    scrim: Color(0x99000000),
    splashTrack: Color(0xFF27342D),
  );

  // Light — ivory canvas, white cards, deep-green brand.
  static const _light = AppThemeTokens(
    background: Color(0xFFF7F5EF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFECF1E6),
    surfaceSunken: Color(0xFFECF1E6),
    accent: Color(0xFF0F3D2E),
    accentInk: Color(0xFF0F3D2E),
    accentSoft: Color(0xFFECF1E6),
    onAccent: Color(0xFFF7F5EF),
    positive: Color(0xFF1B7A4E),
    positiveSoft: Color(0xFFDDEBDD),
    negative: Color(0xFFB23A2A),
    // `rgba(178,58,42,.12)` over the card, as in the reference outcome pill.
    negativeSoft: Color(0x1FB23A2A),
    // Stale / attention: `#6B6130` on the champagne fill.
    neutral: Color(0xFF6B6130),
    neutralSoft: Color(0xFFF0E6C8),
    textPrimary: Color(0xFF15211B),
    foregroundMuted: Color(0xFF5A6660),
    foregroundSubtle: Color(0xFF5A6660),
    textDisabled: Color(0x995A6660),
    hairline: Color(0xFFE3E3D6),
    navHairline: Color(0xFFE3E3D6),
    // `rgba(7,34,25,…)` base for the reference shadows.
    shadowColor: Color(0xFF072219),
    navBg: Color(0xFFFFFFFF),
    skeleton: Color(0xFFECF1E6),
    avatarFill: Color(0xFFECF1E6),
    avatarInk: Color(0xFF0F3D2E),
    positiveText: Color(0xFF1B7A4E),
    negativeText: Color(0xFFB23A2A),
    neutralText: Color(0xFF6B6130),
    // Saffron is accent-only on ivory (graphics, notch, dots).
    highlight: Color(0xFFFF9933),
    onHighlight: Color(0xFF2B1600),
    highlightSoft: Color(0x29FF9933),
    highlightText: Color(0xFF8A4500),
    // `.L` default mast.
    mast: MastPalette(
      fill: Color(0xFFDDE7D5),
      ink: Color(0xFF0F3D2E),
      muted: Color(0xFF4A6A57),
      glass: Color(0x140F3D2E),
      motif: Color(0x120F3D2E),
    ),
    // `.L.t2` champagne.
    mastChampagne: MastPalette(
      fill: Color(0xFFF0E6C8),
      ink: Color(0xFF0F3D2E),
      muted: Color(0xFF6B6130),
      glass: Color(0x142B2A12),
      motif: Color(0x120F3D2E),
    ),
    // `.L.hg` deep-green Home mast.
    mastHome: MastPalette(
      fill: Color(0xFF0F3D2E),
      ink: Color(0xFFF7F5EF),
      muted: Color(0xFFA9C2B3),
      glass: Color(0x1FF7F5EF),
      motif: Color(0x12F7F5EF),
    ),
    // Home green blended toward ivory at 7%, 14%, and 21%.
    mastReports: MastPalette._lightTab(Color(0xFF1F4A3C)),
    mastLearn: MastPalette._lightTab(Color(0xFF2F5749)),
    mastProfile: MastPalette._lightTab(Color(0xFF406457)),
    notch: Color(0xFFFF9933),
    homeAvatarFill: Color(0xFFF7F5EF),
    homeAvatarInk: Color(0xFF0F3D2E),
    focusRing: Color(0xFF0F3D2E),
    // Ink at 50%.
    scrim: Color(0x8015211B),
    splashTrack: Color(0xFFE4E0D4),
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
      secondary: t.accentSoft,
      onSecondary: t.accentInk,
      tertiary: t.highlight,
      onTertiary: t.onHighlight,
      error: t.negativeText,
      onError: isDark ? t.background : const Color(0xFFFFFFFF),
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.foregroundMuted,
      outline: t.hairline,
      outlineVariant: t.navHairline,
      shadow: t.shadowColor,
      scrim: t.scrim,
      surfaceTint: transparent,
      surfaceDim: t.background,
      surfaceBright: t.surface,
      surfaceContainerLowest: t.background,
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

    final text = TextTheme(
      displayLarge: AppTypo.display(
        fontSize: 44,
        color: t.textPrimary,
        height: 1.1,
        letterSpacing: -0.8,
      ),
      displayMedium: AppTypo.display(
        fontSize: 40,
        color: t.textPrimary,
        height: 1.1,
        letterSpacing: -0.8,
      ),
      displaySmall: AppTypo.display(
        fontSize: 34,
        color: t.textPrimary,
        height: 1.1,
        letterSpacing: -0.8,
      ),
      headlineLarge: AppTypo.display(
        fontSize: 21,
        color: t.textPrimary,
        height: 1.2,
      ),
      headlineMedium: AppTypo.display(
        fontSize: 21,
        color: t.textPrimary,
        height: 1.2,
      ),
      headlineSmall: AppTypo.display(
        fontSize: 17,
        color: t.textPrimary,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      titleLarge: AppTypo.display(
        fontSize: 17,
        color: t.textPrimary,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      titleMedium: AppTypo.rowLabel(t),
      titleSmall: AppTypo.ui(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: t.textPrimary,
      ),
      bodyLarge: AppTypo.reading(t),
      bodyMedium: AppTypo.body(t),
      bodySmall: AppTypo.hint(t),
      labelLarge: AppTypo.button(t, color: t.textPrimary),
      labelMedium: AppTypo.fieldLabel(t, color: t.foregroundMuted),
      labelSmall: AppTypo.label(t),
    );

    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [t],
      scaffoldBackgroundColor: t.background,
      fontFamily: AppTypo.family,
    );

    const buttonShape = RoundedRectangleBorder(borderRadius: AppShape.button);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpace.s21,
      vertical: AppSpace.sm,
    );
    const buttonMin = Size(64, AppShape.controlHeight);

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
        shape: AppShape.cardBorder(t),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpace.s13,
        titleTextStyle: AppTypo.sectionTitle(t),
        surfaceTintColor: transparent,
        systemOverlayStyle: overlayStyle(brightness),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        modalElevation: 0,
        modalBackgroundColor: t.surface,
        modalBarrierColor: t.scrim,
        dragHandleColor: t.foregroundMuted,
        dragHandleSize: const Size(34, 4),
        shape: const RoundedRectangleBorder(borderRadius: AppShape.sheetTop),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        hintStyle: AppTypo.fieldValue(t, color: t.foregroundMuted),
        labelStyle: AppTypo.fieldLabel(t),
        floatingLabelStyle: AppTypo.fieldLabel(t, color: t.accentInk),
        helperStyle: AppTypo.meta(t),
        errorStyle: AppTypo.meta(t, color: t.negativeText),
        prefixIconColor: t.foregroundMuted,
        suffixIconColor: t.foregroundMuted,
        iconColor: t.foregroundMuted,
        constraints: const BoxConstraints(minHeight: AppShape.controlHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.md,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide(color: t.hairline),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide(color: t.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide(color: t.focusRing, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide(color: t.negative),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShape.field,
          borderSide: BorderSide(color: t.negative, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: t.surfaceRaised,
          disabledForegroundColor: t.textDisabled,
          surfaceTintColor: transparent,
          elevation: 0,
          minimumSize: buttonMin,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: AppTypo.button(t),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: t.surfaceRaised,
          disabledForegroundColor: t.textDisabled,
          surfaceTintColor: transparent,
          shadowColor: transparent,
          elevation: 0,
          minimumSize: buttonMin,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: AppTypo.button(t),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          disabledForegroundColor: t.textDisabled,
          backgroundColor: transparent,
          surfaceTintColor: transparent,
          elevation: 0,
          minimumSize: buttonMin,
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: t.textPrimary, width: 1.5),
          textStyle: AppTypo.button(t),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accentInk,
          disabledForegroundColor: t.textDisabled,
          surfaceTintColor: transparent,
          minimumSize: const Size(AppSpace.minTarget, AppSpace.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          shape: const RoundedRectangleBorder(borderRadius: AppShape.field),
          textStyle: AppTypo.ui(fontSize: 13, fontWeight: FontWeight.w800),
        ).copyWith(side: _buttonFocusEdge(t)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpace.minTarget),
        ).copyWith(side: _buttonFocusEdge(t)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceRaised,
        selectedColor: t.accent,
        disabledColor: t.surfaceRaised,
        surfaceTintColor: transparent,
        labelStyle: AppTypo.chip(t),
        secondaryLabelStyle: AppTypo.chip(t, color: t.onAccent),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: AppShape.field,
          side: BorderSide(color: t.hairline),
        ),
        side: BorderSide(color: t.hairline),
        checkmarkColor: t.onAccent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        circularTrackColor: t.surfaceRaised,
        linearTrackColor: t.surfaceRaised,
        refreshBackgroundColor: t.surface,
        linearMinHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surface,
        contentTextStyle: AppTypo.bodyStrong(t),
        actionTextColor: t.accentInk,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: AppShape.cardBorder(t, radius: AppShape.field),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accentInk,
        selectionColor: t.accent.withValues(alpha: 0.24),
        selectionHandleColor: t.accentInk,
      ),
      splashFactory: NoSplash.splashFactory,
      splashColor: t.accent.withValues(alpha: 0.06),
      highlightColor: t.accent.withValues(alpha: 0.04),
      hoverColor: t.accent.withValues(alpha: 0.05),
      focusColor: t.focusRing.withValues(alpha: 0.14),
      iconTheme: IconThemeData(color: t.textPrimary),
      primaryIconTheme: IconThemeData(color: t.textPrimary),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        shadowColor: transparent,
        barrierColor: t.scrim,
        titleTextStyle: AppTypo.sectionTitle(t),
        contentTextStyle: AppTypo.body(t),
        shape: AppShape.cardBorder(t),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        shadowColor: transparent,
        textStyle: AppTypo.bodyStrong(t),
        shape: AppShape.cardBorder(t, radius: AppShape.field),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surface),
          surfaceTintColor: const WidgetStatePropertyAll(transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            AppShape.cardBorder(t, radius: AppShape.field),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppShape.field,
          border: Border.all(color: t.hairline),
        ),
        textStyle: AppTypo.ui(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.onAccent
              : t.foregroundMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.accent
              : t.surfaceRaised,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? transparent : t.hairline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? t.accent : transparent,
        ),
        checkColor: WidgetStatePropertyAll(t.onAccent),
        side: BorderSide(color: t.foregroundMuted, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.accent
              : t.foregroundMuted,
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
          t.foregroundMuted.withValues(alpha: 0.5),
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

  static WidgetStateProperty<BorderSide?> _buttonFocusEdge(AppThemeTokens t) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: t.focusRing, width: 2)
            : null,
      );
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
  Duration get transitionDuration => AppMotion.pageTransition;

  @override
  Duration get reverseTransitionDuration => AppMotion.pageTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

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
  bool fullscreenDialog = false,
}) {
  // Inside a tab navigator (A3) the page ends above the floating dock;
  // anywhere else `AyreDockClearance` does nothing.
  Widget wrapped(BuildContext context) =>
      AyreDockClearance(child: builder(context));
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => _AyreCupertinoRoute<T>(
      builder: wrapped,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    ),
    _ => _AyreMaterialRoute<T>(
      builder: wrapped,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    ),
  };
}

Duration _routeDuration(NavigatorState? navigator) {
  final context = navigator?.context;
  final reduce = context
      ?.getInheritedWidgetOfExactType<MediaQuery>()
      ?.data
      .disableAnimations;
  return reduce == true ? Duration.zero : AppMotion.pageTransition;
}

class _AyreMaterialRoute<T> extends MaterialPageRoute<T> {
  _AyreMaterialRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => _routeDuration(navigator);

  @override
  Duration get reverseTransitionDuration => _routeDuration(navigator);
}

class _AyreCupertinoRoute<T> extends CupertinoPageRoute<T> {
  _AyreCupertinoRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => _routeDuration(navigator);

  @override
  Duration get reverseTransitionDuration => _routeDuration(navigator);
}
