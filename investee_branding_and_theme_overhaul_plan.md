# Investee: Branding & Theme Overhaul: Implementation Plan

> **Document status:** PLAN ONLY. No phase has been implemented by this document.
> **Living document:** after every phase this file is updated (phase marked ✅, actual changes recorded, remaining phases revised) and shipped inside that phase's ZIP.
> **Scope:** Flutter app (`ayre-scanner-app-main`). Backend (`ayre-scanner-main`) is analysed only to protect push notifications; no backend code changes are planned.

---

## 0. Progress tracker

| Phase | Title | Status | ZIP delivered | Plan revised after |
|---|---|---|---|---|
| 0 | Logo & icon image assets + wiring (done before this plan) | ✅ COMPLETED (pre-plan) | n/a | n/a |
| 1 | Theme core: tokens, palettes, `ThemeData`, system appearance | ✅ COMPLETED 2026-11-22 | `investee_phase1.zip` | Phase 1 |
| 2 | Shared components, navigation, overlays | ✅ COMPLETED 2026-11-22 | `investee_phase2.zip` | Phase 2 |
| 3 | Screens, feature widgets, data-viz, splash/auth composition | ✅ COMPLETED 2026-11-22 | `investee_phase3_4.zip` | Phase 3 |
| 4 | Rename in Dart: copy, legal, wordmark, accessibility labels | ✅ COMPLETED 2026-11-22 | `investee_phase3_4.zip` | Phase 4 |
| 5 | Native/web identity, notification visuals, a11y audit, final sweep | ✅ COMPLETED 2026-11-22 | `investee_phase5.zip` | n/a (final) |

*(Implementer: change the row and append to §12 "Phase completion log" at the end of each phase.)*

---

## 1. Owner working rules (apply to every phase)

These are standing preferences of the project owner and override anything below that conflicts:

1. **Complete files only.** Deliver the full updated file, never diffs or partial snippets.
2. **Do not build or run the project. Do not write, edit, or run tests.** Do not add test infrastructure. (There is no `test/` folder in the repo; keep it that way. `lib/screens/testing/replay_onboarding_row.dart` is a temporary in-app test row, so only restyle it if a token change forces it, never remove or alter its behaviour.)
3. **Do not troubleshoot local environment setup.** Write code only.
4. **Do not change behaviour or navigation.** This is a visual + naming change.
5. **Terse communication.** No filler or concluding summaries. Per phase, report: file list with destination paths + the ZIP.
6. **Phase delivery protocol (§11)** is mandatory. Do not start phase N+1 until phase N's ZIP, file list, install script and revised plan have been delivered.

---

## 2. Absolute do-not-touch list (push notifications & Firebase safety)

Nothing below may be edited, renamed, regenerated or re-pointed in any phase:

| Item | Where | Why it must stay |
|---|---|---|
| Firebase config & bootstrap | `lib/services/firebase_bootstrap.dart`, any `google-services.json` / `GoogleService-Info.plist`, `firebase_options*` if present, `pubspec.yaml` Firebase deps | Project identity |
| Push logic | `lib/services/push_service.dart`, `lib/services/notification_copy.dart`, `lib/services/auth_service.dart`, `lib/services/email_verification.dart` | Behaviour |
| **Android notification channel ID `ayre_signals`** | `AndroidManifest.xml` (`default_notification_channel_id`), `MainActivity.kt` (`PUSH_CHANNEL_ID`), **backend** `config/settings.py` (`PUSH_ANDROID_CHANNEL_ID`) used in `alerts/push.py` | Backend names this channel in every FCM message. Changing it on only one side silently breaks delivery sound/importance |
| Manifest meta-data **resource names** `@drawable/ic_stat_ayre`, `@color/ayre_notification_accent` | `AndroidManifest.xml`, `res/drawable-*/ic_stat_ayre.png`, `res/values/colors.xml` | Names are references. Only the **hex value** of the colour may change (Phase 5) |
| Application / bundle identifiers | `applicationId`/`namespace` `com.example.ayre_scanner` (`android/app/build.gradle.kts`), Kotlin package path `com/example/ayre_scanner/`, `PRODUCT_BUNDLE_IDENTIFIER` `com.example.ayreScanner` (iOS/macOS), Linux `APPLICATION_ID`, `BINARY_NAME`, pubspec `name: ayre_scanner` | Changing breaks Firebase registration, installs/updates, imports |
| Backend identifiers | `APP_NAME = "ayre-push"` (`alerts/push.py`, `auth/firebase_app.py`), API base URL `https://ayre-scanner-production.up.railway.app` (`lib/services/api_service.dart:32`) | Infrastructure |
| Persisted storage keys | `theme_mode` (SharedPreferences), any `ayre.*` key (also backend web dashboard `localStorage` keys `ayre.tradeReadyTimes.v1`, `ayre.entryHits.*`) | Renaming wipes user state |
| Dart identifiers | Classes/files named `Ayre*` / `ayre_*.dart` (≈ 25 classes, 179 `AyreGlyph` uses) | Internal names, invisible to users. **Do not rename**: it creates huge import churn with zero user benefit |
| Native launch backgrounds & iOS launch assets | `drawable*/launch_background.xml`, `LaunchScreen.storyboard`, `LaunchImage*.png` (1×1 transparent) | Keep unless the optional item N1 in Phase 5 is explicitly approved |
| Generated image assets | Everything under §3 | Already produced. Do not regenerate or redesign |

---

## 3. WORK ALREADY COMPLETED (preserve exactly)

### 3.1 Image assets (final, do not regenerate)
Brand: deep green `#0F3D2E`, saffron `#FF9933`, ivory `#F7F5EF`.

| Area | Files |
|---|---|
| In-app logo | `assets/brand/ayre_logo.png` = **dark** variant (green tile, ivory mark), 2048². `assets/brand/ayre_logo_light.png` = **light** variant (ivory tile, green mark), 2048². `final_logo.png` (repo root) = 4096² master |
| Android launcher | `res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` (legacy, rounded) · `ic_launcher_foreground.png` · `ic_launcher_monochrome.png` · `res/mipmap-anydpi-v26/ic_launcher.xml` (adaptive; background literal `#0F3D2E`, foreground + monochrome layers) |
| Android notification small icon | `res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_stat_ayre.png`: white silhouette; overrides the old vector `res/drawable/ic_stat_ayre.xml` (that XML may be deleted but is harmless) |
| iOS | `AppIcon.appiconset`: all `Icon-App-*.png` = light (ivory tile) default; `Icon-App-1024x1024@1x-dark.png` = dark appearance |
| macOS | `app_icon_{16,32,64,128,256,512,1024}.png` (rounded, transparent padding) |
| Windows | `windows/runner/resources/app_icon.ico` (16–256 multi-size) |
| Web | `web/favicon.png` (dark fallback), `favicon-light.png`, `favicon-dark.png`, `icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png` |

### 3.2 Code/config edits already applied (preserve)
1. `lib/widgets/ayre_logo.dart`: `LogoMark` has `assetPathDark` / `assetPathLight`, chosen by `Theme.of(context).brightness == Brightness.dark`. Everything else in the file unchanged (still has `Semantics(label: 'Ayre')`, `_Fallback` text `'ayre'`, and `LogoWordmark` rendering text `'ayre'`).
2. `pubspec.yaml`: `assets/brand/ayre_logo_light.png` registered (still `name: ayre_scanner`, `description: "A new Flutter project."`).
3. `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`: dark-appearance entry added.
4. `web/index.html`: two extra `<link rel="icon">` with `prefers-color-scheme` media queries (still `<title>ayre_scanner</title>`, `apple-mobile-web-app-title="ayre_scanner"`, `meta description="A new Flutter project."`).
5. `android/.../mipmap-anydpi-v26/ic_launcher.xml`: new adaptive icon.

### 3.3 Platform behaviour (informational; set expectations)
* **iOS 18+**: app icon follows system light/dark automatically (done).
* **Android**: no native automatic dark/light launcher icon. Android 13+ "Themed icons" tint the monochrome layer (done). Android ≤ 12 shows the single green icon.
* **macOS / Windows**: single icon, no appearance variants.

---

## 4. Verified current state of the code (analysis findings)

*Findings come from reading the actual project. Re-read each file before editing; line numbers are approximate.*

### 4.1 Theme system: `lib/theme/app_theme.dart` (1151 lines)
* Header comment describes "v5 forest-green / emerald / mint-paper".
* `AppThemeTokens extends ThemeExtension` (line ~25) with these `Color` fields: `background, surface, surfaceRaised, surfaceSunken, accent, accentInk, accentSoft, onAccent, positive, positiveSoft, negative, negativeSoft, neutral, neutralSoft, textPrimary, foregroundMuted, foregroundSubtle, textDisabled, hairline, navHairline, shadowColor, navBg, skeleton, avatarFill, avatarInk, positiveText, negativeText, neutralText`. It has `copyWith` and `lerp`. Access via `context.tokens` (`AppThemeContext` extension, line ~275).
* Palettes: `AppTheme._dark` (line ~768) and `_light` (~819). Old values: dark `background 0xFF0B120D`, `accent 0xFF3FCB7A`; light `background 0xFFF1F7F1`, `accent 0xFF1E8749`, `onAccent 0xFFFFFFFF` (≈ 4.38:1, a known sub-AA pairing noted in a doc comment).
* `AppTheme.light/dark` → `_build(brightness, tokens)` (line ~880). It maps `ColorScheme(primary: accent, onPrimary: onAccent, secondary/tertiary: neutral, error: negative, surface, onSurface: textPrimary)`, `useMaterial3: true`, `extensions: [t]`, `scaffoldBackgroundColor: background`, and configures `textTheme`, `dividerTheme`, `cardTheme`, `appBarTheme` (bg = `background`, `systemOverlayStyle: overlayStyle(brightness)`), `bottomSheetTheme` (bg = `surface`), `inputDecorationTheme` (fill `surfaceSunken`, focus border `accentInk`), `progressIndicatorTheme`, `snackBarTheme` (bg `surfaceRaised`), `textSelectionTheme`, and `pageTransitionsTheme` (`TerminalPageTransitions`).
* `AppTheme.overlayStyle(Brightness)` (line ~749): transparent status/nav bars, icon brightness inverted per mode, iOS `statusBarBrightness` handled. **Already correct; keep logic.**
* Radii (`AppRadius`: card 18, chip/inset/control 12, iconTile 14, sheet 28, pill 999), spacing (`AppSpace`, `minTarget 48`), motion (`AppMotion`), type scale sizes, `AppTypo`. Typography: **Hanken Grotesk** (display/UI) and **Space Grotesk** (numerals, tabular figures) via `google_fonts`. Numerals route through `Figure` (`lib/widgets/figure.dart`).
* Token usage footprint (outside theme file): `t.accent` 27 refs, `accentInk` 44, `accentSoft` 9, `onAccent` 21, positive* 8, neutral* 7. Heaviest `t.accent` users: `ayre_components.dart` (9), `pressable_scale.dart` (8), `onboarding_widgets.dart` (3), `settings_screen.dart` (2), `spotlight_tour.dart`, `ayre_charts.dart`, `ayre_bottom_nav.dart` (1 each).

### 4.2 Appearance mode: `lib/main.dart`
* `AyreScannerApp` state: `ThemeMode _themeMode = ThemeMode.dark;` (**default is forced dark**, comments say "unchanged so existing users see no silent shift"). Persisted under SharedPreferences key `theme_mode` as `light|dark|system`; **written only when the user picks** (`setThemeMode`). `_loadThemeMode()` returns early (stays dark) when no value is stored; unknown strings fall back to dark.
* `MaterialApp(title: 'Ayre Scanner', theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: _themeMode, themeAnimationDuration: AppMotion.medium)`.
* `builder` already computes the *effective* brightness (`ThemeMode.system → MediaQuery.platformBrightness`) and wraps everything in `AnnotatedRegion<SystemUiOverlayStyle>(AppTheme.overlayStyle(brightness))`, plus app-wide text-scale (`osFactor × SettingsStore.textSize.scale`, clamped 0.8–2.2).
* Settings → Appearance (`lib/screens/settings_screen.dart` ~160–185): `_AppearanceTiles` (System / Light / Dark) already exists, calling `theme.setThemeMode`. Caption strings contain the old name (`'Ayre always uses the light theme.'`, `'…dark theme.'`).

### 4.3 Hard-coded colours outside the theme file (must be re-based)
| File | What |
|---|---|
| `widgets/ayre_insight_carousel.dart` (~553–579) | Two `_InsightPalette`s (`light`, `dark`) with ~23 literal colours: dark-green gradients (`0xFF0F1D15→0xFF16281C` / `0xFF060B07→0xFF0D1710`), emerald bars `0xFF2E9E5B` / `0xFF4ED892`, mint eyebrow, etc. |
| `widgets/ayre_hills.dart` (30–36) | Decorative hills: light `0x…1F8A4B` at 4/8/12 % alpha, dark `0x…3FCB7A` |
| `widgets/ayre_instrument_tile.dart` (67–68) | Logo plates `_lightPlate 0xFFFFFFFF`, `_darkPlate 0xFF111614` (plates exist so white/dark company logos stay legible. **Keep that function**) |
| `widgets/ayre_bottom_nav.dart` (413–414) | Transparent literals only; fine |
| `widgets/spotlight_tour.dart` (295) | `Colors.black` scrim alpha 0.72 dark / 0.58 light |
| `widgets/ayre_icons.dart` (142) | Black fallback colour; fine |

### 4.4 Components (all in `lib/widgets/`)
* `ayre_components.dart` (1425 lines): `AyreCard`, `InkPanel`, `SectionLabel`, `SectionInfoButton`, `HairlineDivider`, `AyreButton` (`AyreButtonKind { primary, outline, danger }`; primary = solid `accent` pill), `AyreSwitch`, `AyreSegmented`, `ChipTone { neutral, attention, brand }` + `AyreChip`, `SettingRow`, `RowGroup`, `SignalStrength`, `ProgressRule`, `SkeletonBlock`, `AyreFilterChip`, `TagPill`, etc.
* `ayre_bottom_nav.dart` (576): `kNavDestinations` Home / Reports / Learn / Profile; selected = soft capsule (`accentSoft`) with glyph+label `accentInk`; has a rail variant (`AyreNavRail`) and `ayre_nav_metrics.dart`.
* `ayre_sheet.dart` (`AyreSheet`, `showAyreSheet`), `state_views.dart` (`StatePanel`, `OfflineBanner`, `FreshnessStamp`, `_RefreshDot`), `auth_widgets.dart` (`AuthField`, `AuthMessage`, `PasswordChecklist`, `AuthScaffold`), `onboarding_widgets.dart` (`OnboardingPageIndicator`, `OnboardingWash`, `OnboardingFeatureRows`), `pressable_scale.dart`, `ayre_avatar.dart` (uses `avatarFill/avatarInk`, currently **lavender**), `ayre_charts.dart`, `ayre_weekly_report.dart` (1115), `ayre_signals_section.dart`, `ayre_stat_tile.dart`, `ayre_tab_scroll.dart`, `ayre_tab_host.dart`, `figure.dart`, `spotlight_tour.dart`.
* Dialog/sheet call sites: `profile_tab.dart` (1), `settings_screen.dart` (1), `ayre_components.dart` (1), `ayre_sheet.dart` (2), `ayre_weekly_report.dart` (1). `AppBar` is used in 7 screens (grievance, insight_note, faq, research_analyst, edit_profile, lesson, delete_account) and inherits `appBarTheme`.

### 4.5 Screens
`home_shell.dart` (tab shell + nav), `home_tab.dart` (header at ~280–296: `LogoWordmark(fontSize: 15)` + `Text('SCANNER')` label), `weekly_reports_tab.dart`, `learn_tab.dart`, `profile_tab.dart`, `settings_screen.dart`, `splash_screen.dart` (`AyreSplashScreen`: `LogoMark(splash)` + `Text('MARKET TERMINAL')`, uses `t.background`), `login_screen.dart` & `onboarding_screen.dart` (`LogoMark(auth)`), `register_screen.dart`, `forgot_password_screen.dart`, `change_password_screen.dart`, `edit_profile_screen.dart`, `delete_account_screen.dart`, `notifications_screen.dart`, `faq_screen.dart`, `grievance_screen.dart`, `support_screen.dart`, `legal_hub_screen.dart`, `legal_document_screen.dart`, `terms_screen.dart`, `privacy_policy_screen.dart`, `risk_disclosure_screen.dart`, `research_analyst_screen.dart`, `insight_note_screen.dart`, `lesson_screen.dart`.

### 4.6 Every user-visible occurrence of the old name (Dart)
| File:line | Text |
|---|---|
| `main.dart:162` | `MaterialApp(title: 'Ayre Scanner')`: drives OS task-switcher title and web document title |
| `legal/legal_config.dart:20` | `const String kBrandName = 'Ayre';` (interpolated as `$kBrandName` in `legal_content.dart` lines ~57, 66, 71, 209, 687, 697) |
| `legal/legal_content.dart:70, 891, 892, 905, 942` | **Hard-coded** "Ayre" (definition clause, FAQ "What is Ayre?", "Ayre is a research service…", "No. Ayre only publishes research…", "Does Ayre use artificial intelligence?") |
| `screens/delete_account_screen.dart:96, 116` | "…deletes your Ayre account." / "To use Ayre again…" |
| `screens/legal_hub_screen.dart:53` | `SectionLabel(label: 'Using Ayre')` |
| `screens/register_screen.dart:105` | `'Set up your Ayre Scanner account.'` |
| `screens/settings_screen.dart:177, 178, 238` | Theme captions; "…for Ayre in your device settings." |
| `widgets/ayre_logo.dart:52, 118, 142, 144` | `Semantics(label:'Ayre')` ×2, fallback text `'ayre'`, wordmark text `'ayre'` |
| `screens/support_screen.dart:17` | `kSupportAddress = 'support@ayrescanner.app'` (a real mailbox/domain: **leave**, see D4) |

### 4.7 Every user-visible occurrence (native/web/backend)
| Location | Current | Visible to user as |
|---|---|---|
| `android/app/src/main/AndroidManifest.xml:6` | `android:label="ayre_scanner"` | Home-screen label |
| `android/.../MainActivity.kt` (channel) | name `"Signals and alerts"`, **description** `"New scanner picks and messages from Ayre"` | System notification settings |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` = `Ayre Scanner`, `CFBundleName` = `ayre_scanner` | Home-screen label |
| `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME = ayre_scanner` (`CFBundleName = $(PRODUCT_NAME)`) | Menu bar / bundle name |
| `windows/runner/main.cpp:30`, `Runner.rc` (FileDescription, ProductName) | `ayre_scanner` | Window title, file properties |
| `linux/runner/my_application.cc:48,52` | `"ayre_scanner"` | Window/header-bar title |
| `web/index.html` | `<title>ayre_scanner</title>`, `apple-mobile-web-app-title`, `meta description "A new Flutter project."` | Tab title, iOS web-clip name |
| `web/manifest.json` | `name`/`short_name` `ayre_scanner`, `description` "A new Flutter project.", `background_color`/`theme_color` `#0175C2` (Flutter blue) | PWA install name & splash colour |
| `pubspec.yaml` | `description: "A new Flutter project."` (invisible to users; tidy only) | – |
| `res/values/colors.xml` | `ayre_notification_accent = #1E8749` (old emerald) | Android notification accent tint |
| Backend React dashboard `frontend/index.html` `<title>Ayre.</title>`, `frontend/src/App.tsx:530,568` `<h1>Ayre.</h1>` | "Ayre." | Backend-served web dashboard (see D6) |
| Backend push payload (`alerts/push.py`, `notification_copy.dart`) | **No brand text**: titles/bodies are signal copy | n/a, no change |

---

## 5. Design specification (source of truth for all phases)

### 5.1 Brand colours
| Name | Hex | Role |
|---|---|---|
| Deep green | `#0F3D2E` | Primary brand: text/actions in light mode, **surface** in dark mode |
| Ivory | `#F7F5EF` | Light canvas; text/actions in dark mode |
| Saffron | `#FF9933` | Rare highlight only (see §5.4) |

All other colours are *derived shades* of these three (tints/shades of green, warm off-whites). Semantic data colours (gain/loss/attention) remain separate. Brand colours must never be repurposed to encode gain/loss.

### 5.2 Token palettes (replace `_light` / `_dark` values; contrast ratios computed against the stated background)

#### Light (ivory canvas)
| Token | Value | Notes / contrast |
|---|---|---|
| `background` | `#F7F5EF` | brand ivory |
| `surface` | `#FFFFFF` | cards, sheets, nav |
| `surfaceRaised` | `#EFEDE3` | 1 step off surface (chips, snackbar) |
| `surfaceSunken` | `#E7E4D8` | inputs, tracks, inset wells |
| `accent` | `#0F3D2E` | primary fills (buttons, switch on, selected) |
| `onAccent` | `#F7F5EF` | **11.15:1** on accent (fixes old 4.38:1) |
| `accentInk` | `#0F3D2E` | accent-coloured text/icons |
| `accentSoft` | `#DDE9E0` | selected capsule/tint; `accentInk` on it **9.73:1** |
| `textPrimary` | `#0F3D2E` | 11.15 on bg · 12.16 on surface · 10.36 on raised |
| `foregroundMuted` | `#3F5A4E` | 6.92 on bg · 6.43 on raised |
| `foregroundSubtle` | `#506358` | 5.90 bg · 5.48 raised · **5.05 on sunken** (the previous candidate `#5B6F65` failed on sunken at 4.22) |
| `textDisabled` | `#506358` @ 50 % alpha | disabled text (WCAG-exempt) |
| `hairline` / `navHairline` | `#0F3D2E` @ 10 % / 16 % alpha | |
| `shadowColor` | `#D2CFC0` | warm, soft |
| `navBg` | `#FFFFFF` | |
| `skeleton` | `#E9E6DA` | |
| `positive` (glyph) | `#1A7F44` | 4.63 on bg (≥ 3:1 for graphics) |
| `positiveText` | `#156B3A` | 6.03 bg · 5.60 raised |
| `positiveSoft` | `#DDEBDD` | positiveText on it 5.32 |
| `negative` (glyph) | `#D64545` | |
| `negativeText` | `#B83232` | 5.44 bg · 5.93 white · 5.05 raised |
| `negativeSoft` | `#F7DCDC` | negativeText on it 4.58 |
| `neutral` | `#A67C00` | attention/neutral. Shifted from orange-gold `#C98A2D` to a yellow-gold so it cannot be mistaken for saffron |
| `neutralText` | `#7A5A00` | 5.85 on bg |
| `neutralSoft` | `#A67C00` @ 14 % alpha | |
| `avatarFill` / `avatarInk` | `#DDE9E0` / `#0F3D2E` | replaces lavender; 9.73:1 |
| **new** `highlight` | `#FF9933` | graphics only, never text on ivory (1.95:1) |
| **new** `onHighlight` | `#0F3D2E` | 5.71:1 on saffron |
| **new** `highlightSoft` | `#FF9933` @ 16 % alpha | |
| **new** `highlightText` | `#8A4500` | 6.57 on ivory · 7.16 white · 6.05 on highlightSoft |

#### Dark (brand-green canvas: the brand green is literally the card colour)
| Token | Value | Notes / contrast |
|---|---|---|
| `background` | `#0A2A20` | deeper shade of brand green |
| `surface` | `#0F3D2E` | **exact brand green** (cards, sheets, nav) |
| `surfaceRaised` | `#174B39` | |
| `surfaceSunken` | `#061D16` | inputs, tracks |
| `accent` | `#F7F5EF` | primary fills invert to ivory |
| `onAccent` | `#0F3D2E` | 11.15:1 |
| `accentInk` | `#BFE6CF` | 8.94 on surface · 7.34 raised |
| `accentSoft` | `#1E5A45` | accentInk on it 5.93 · ivory 7.40 |
| `textPrimary` | `#F7F5EF` | 14.11 bg · 11.15 surface · 9.16 raised |
| `foregroundMuted` | `#CBD5CD` | 8.07 surface · 6.63 raised |
| `foregroundSubtle` | `#B3C3B9` | 6.61 surface · 5.43 raised (candidate `#A3B5AA` failed on raised at 4.64) |
| `textDisabled` | `#B3C3B9` @ 45 % alpha | |
| `hairline` / `navHairline` | `#F7F5EF` @ 10 % / 16 % alpha | |
| `shadowColor` | `#000000` | |
| `navBg` | `#0B3024` | slightly below surface |
| `skeleton` | `#174B39` | |
| `positive` | `#4ED892` | 6.69 surface · 5.50 raised · 5.63 on positiveSoft `#134A33` |
| `negative` | `#FF7F76` | glyph |
| `negativeText` | `#FF9C94` | 6.04 surface · 4.96 raised · 6.30 on negativeSoft `#4A2A2A` (old `#F0685F` was 3.97:1 on surface) |
| `neutral` / `neutralText` | `#E3B94F` | 6.55 surface |
| `avatarFill` / `avatarInk` | `#1E5A45` / `#D6EBDD` | 6.45 |
| `highlight` | `#FF9933` | 5.71 on surface · 4.69 raised · 7.22 bg (usable as text on dark) |
| `onHighlight` | `#0F3D2E` | |
| `highlightSoft` | `#FF9933` @ 20 % alpha | |
| `highlightText` | `#FF9933` | |

> Implementer must re-verify any value **not** listed with a ratio (≥ 4.5:1 for text ≤ 18 px / bold ≤ 14 px, ≥ 3:1 for icons, borders that carry meaning, focus indicators) and adjust within the same hue family if it fails. Record final values in §12.

### 5.3 Surface/elevation model
Flat, hairline-bordered surfaces (existing language): `background` → `surface` (cards) → `surfaceRaised` (secondary chips, snackbar) → `surfaceSunken` (inputs/tracks). **No Material 3 surface-tint** (keep `surfaceTintColor: transparent`). In dark mode depth comes from lightness steps, not shadows.

### 5.4 Saffron budget (use sparingly)
Allowed (pick only the ones that exist after reading the screen; at most **one saffron element per viewport**, excluding the logo's own dot):
1. Unread/new indicator dot or badge (e.g., notifications list, nav badge if any).
2. Spotlight-tour highlight ring / active onboarding page-indicator dot.
3. A single "New / updated" `TagPill`/`AyreChip` emphasis where an attention cue (not a data cue) is needed.
4. Android notification accent tint (Phase 5).
5. A thin progress/accent underline in one hero element if a screen has nothing else warm.

Forbidden: gain/loss/neutral data colours, body or label text on ivory (use `highlightText`), primary button fills, large fills/backgrounds, charts' primary series, anything the user must read at < 3:1.
Saffron **fills** always carry `onHighlight` (`#0F3D2E`) content, never ivory/white.

### 5.5 Typography
Keep **Hanken Grotesk** (UI/display) and **Space Grotesk** (tabular numerals via `Figure`): geometric-grotesque, a close match to the logotype, readable under Dynamic Type/Android font scaling, already scaled app-wide (0.8–2.2). No font swap. Changes limited to: colours coming from new tokens; wordmark weight/tracking tuned (Phase 4); verify heading colour `textPrimary` is not applied to long-form body where `foregroundMuted` was intended.

### 5.6 Platform conventions to honour
* **Apple HIG:** minimum 44 pt hit target (app uses 48, OK); system Dynamic Type respected; status-bar style follows effective appearance; dark mode uses elevated lighter surfaces, not pure black/gray; iOS uses light + dark app icons (done); respect Reduce Motion (splash already checks `MediaQuery.disableAnimationsOf`).
* **Material 3 / Android:** 48 dp targets; edge-to-edge with transparent system bars (already); `colorScheme` mapped from tokens; themed (monochrome) icon on 13+; notification small icon monochrome + brand accent colour; support system dark/light switching without activity loss (Flutter handles via `ThemeMode.system`).
* **Both:** WCAG 2.1 AA contrast; never encode meaning in colour alone (gain/loss already pair colour with sign/glyph; keep).

### 5.7 Open decisions: defaults the implementer should follow unless the owner overrides
| ID | Decision | Default |
|---|---|---|
| D1 | `kBrandName` & legal text name change. `legal_config.dart` notes the name must be one the RA is entitled to use as trade name; legal docs name the service | **Change** to `Investee` everywhere (owner instruction) via `kBrandName` + replace the 5 hard-coded strings with `$kBrandName`; **flag in the hand-off message** that the owner must confirm the trade-name/SEBI-disclosure implications and that placeholders in `legal_config.dart` remain unchanged |
| D2 | Existing users' stored `theme_mode` | **New installs → `ThemeMode.system`.** One-time migration for existing installs: because older builds could silently store a resolved `dark`/`light`, stored values cannot be told apart from deliberate choices. Default = **reset once to `system`** (guarded by a new SharedPreferences flag so it runs once and never overrides later choices); Settings picker unchanged. If the owner prefers zero disruption, skip the migration and keep stored values |
| D3 | Descriptor labels `SCANNER` (home header) and `MARKET TERMINAL` (splash) | **Keep** (descriptors, not the name) |
| D4 | `support@ayrescanner.app` and Railway API URL | **Leave** (real infrastructure); report to owner |
| D5 | Android notification channel *description* (`"…messages from Ayre"`) in `MainActivity.kt` | **Change the description string only** (channel ID and name untouched; Android applies updated name/description when the channel is re-created at launch). Isolated one-line edit; skip if owner objects |
| D6 | Backend web dashboard `<title>Ayre.</title>` / `<h1>Ayre.</h1>` (and built `static/`) | **Out of scope for this plan** (separate product surface; built bundle would need a rebuild the owner does). List in hand-off as optional; never touch storage keys |
| D7 | Android notification accent colour value | **`#FF9933` (saffron)**: visible on both light and dark notification shades; deep green is not. Resource *name* unchanged |
| D8 | macOS `PRODUCT_NAME` | **Leave** (renames the `.app`/executable and Xcode references). Add `CFBundleDisplayName = Investee` to `macos/Runner/Info.plist` only if the file lacks it; report that the menu-bar name still derives from `PRODUCT_NAME` |

---

## 6. PHASE 1: Theme core: tokens, palettes, `ThemeData`, system appearance

**Goal:** a complete, correct light + dark brand theme at the token/`ThemeData` level, and automatic system light/dark detection. After this phase every widget that already reads tokens re-colours automatically.

**Status:** ✅ COMPLETED 2026-11-22

**Actual changes:** `lib/theme/app_theme.dart` (header rewritten; 4 new tokens `highlight/onHighlight/highlightSoft/highlightText` in class, `copyWith`, `lerp`; `_light`/`_dark` replaced with §5.2 values; `ColorScheme` remapped incl. `surfaceContainer*`, `outline*`, `error`; added dialog/popupMenu/menu/tooltip/switch/checkbox/radio/listTile/scrollbar/icon themes, splash/highlight colours, `cupertinoOverrideTheme`; selection colour alpha 0.24). `lib/main.dart` (default `ThemeMode.system`; one-time migration flag `theme_mode_system_default_v1`; unknown stored value → `system`; stale comments updated). Overlay logic, `setThemeMode`, builder untouched.

### Existing files (read first)
`lib/theme/app_theme.dart` (all), `lib/main.dart` (lines 28–215), `lib/screens/settings_screen.dart` (Appearance block ~140–260, read only), `lib/services/settings_store.dart` (read only; confirm it does not own theme).

### Dependencies
None (first dependency-ordered phase). Uses §5.2 palettes and §5.7 D2.

### Work items
1. **Header/doc comments** in `app_theme.dart`: replace "v5 forest-green/emerald/mint-paper" narrative with the Investee identity (deep green / ivory / saffron); update the `onAccent` contrast note (now 11.15:1 / 11.15:1).
2. **Extend `AppThemeTokens`** with `highlight`, `onHighlight`, `highlightSoft`, `highlightText` (constructor `required`, fields + doc comments, `copyWith`, `lerp`). Both `_light` and `_dark` supply all new fields. This is the only structural change; no existing token is removed or renamed.
3. **Replace all values** in `_dark` and `_light` with §5.2 (verify ratios, adjust within hue if needed).
4. **`_build` mapping:**
   * `ColorScheme`: `primary: accent`, `onPrimary: onAccent`, `secondary: accentInk`-family or `highlight`? **Use** `secondary: accentSoft`, `onSecondary: accentInk`, `tertiary: highlight`, `onTertiary: onHighlight` (replaces the previous `secondary/tertiary = neutral`), `error: negative`, `onError` set to a verified ≥ 4.5:1 pair (light: `#FFFFFF` on `#D64545` fails → use `#FFFFFF` only if ≥ 4.5; otherwise `negativeText`-family), `surface`, `onSurface: textPrimary`, plus `outline: hairline`, `outlineVariant: navHairline`, `surfaceContainer*`/`surfaceTint` mapped to the surface steps so any stock Material widget (dialogs, menus, date pickers) matches. Keep `useMaterial3: true`.
   * Component themes (all colours from tokens, none hard-coded): keep `cardTheme`, `appBarTheme`, `bottomSheetTheme`, `inputDecorationTheme`, `progressIndicatorTheme`, `snackBarTheme`, `textSelectionTheme` structure; verify each against new tokens. **Add** (colour-only, no behaviour): `dialogTheme` (bg `surface`, hairline border, `AppRadius.card`), `popupMenuTheme`/`menuTheme`, `tooltipTheme` (bg `surfaceRaised`, text `textPrimary`), `switchTheme`/`checkboxTheme`/`radioTheme` (selected = `accent`, thumb/check = `onAccent`, unselected track = `surfaceSunken` + `hairline` outline), `iconTheme` (`textPrimary`), `listTileTheme`, `scrollbarTheme`, `splashColor`/`highlightColor` (low-alpha `accent`), `textSelectionTheme.selectionColor` (`accent` @ 24 % alpha), `cupertino` brightness via `cupertinoOverrideTheme` (primaryColor `accent`) so any Cupertino widget (page transitions, selection handles) matches on iOS.
5. **`AppTheme.overlayStyle`**: keep logic; confirm status-bar icon brightness is correct against `background` in both modes (ivory → dark icons; deep green → light icons). Android: keep transparent nav bar with `systemNavigationBarContrastEnforced: false`.
6. **System appearance detection (`main.dart`):**
   * Default `_themeMode` → `ThemeMode.system`.
   * `_loadThemeMode()`: when no value stored → stay `system`. Implement D2 migration with a one-time flag key (e.g., `theme_mode_system_default_v1`, new key, do not touch `theme_mode`'s name): first launch after update with an existing stored value → set `system` and persist; mark flag. Otherwise unchanged mapping (`light`/`dark`/`system`; unknown → `system`).
   * Update the stale comments ("default stays dark").
   * Do not change `setThemeMode`, `AppThemeController`, or the builder's effective-brightness logic (already correct).
   * Keep `MaterialApp.title` as-is here (Phase 4 renames it).
7. **No** changes to `settings_screen.dart` in this phase (captions change in Phase 4).

### Files expected in ZIP
`lib/theme/app_theme.dart`, `lib/main.dart`, `investee_branding_and_theme_overhaul_plan.md` (+ `install_phase1.sh/.ps1` + `FILE_LIST.md`).

### Expected outcome
App launches in the phone's current mode and switches live when the phone appearance changes (including while running). All token-driven widgets show the new palette; some bespoke colours (carousel, hills, plates) still old until Phase 3.

### Acceptance criteria (manual review only, no tests)
* Every `AppThemeTokens` field is set in both palettes; `copyWith`/`lerp` include the 4 new fields.
* No literal colours in `_build` except via tokens/`transparent`.
* `ThemeMode.system` is the default; stored explicit choices follow D2.
* Both palettes meet §5.2 contrast targets (recorded ratios).
* No other files changed; no Firebase/push code touched.

---

## 7. PHASE 2: Shared components, navigation, overlays

**Goal:** make every reusable widget express the Investee look and the saffron budget; guarantee consistent buttons, cards, chips, forms, nav, sheets, dialogs, banners.

**Status:** ✅ COMPLETED 2026-11-22

**Actual changes:** `ayre_components.dart` (AyreButton: outline = `accentInk` text + `navHairline` edge, primary edge = fill, stale 4.38:1 comment replaced; `ChipTone.brand` = `accentSoft`/`accentInk`). `ayre_sheet.dart` (scrim = `colorScheme.scrim` @55%; grabber full `foregroundSubtle`). `onboarding_widgets.dart` (active dot saffron `highlight`; new optional `activeColor` param, default saffron; wash from `accentSoft`). `spotlight_tour.dart` (scrim from `colorScheme.scrim`; ring saffron; tour card's indicator passes `accentInk` so one saffron element per viewport). `ayre_avatar.dart` (comments only). Verified with no change needed: `ayre_bottom_nav.dart`, `ayre_nav_metrics.dart`, `state_views.dart`, `auth_widgets.dart`, `pressable_scale.dart`, `verification_banner.dart`, `ayre_tab_host.dart` (all token-driven; nav has no badge; `OfflineBanner` uses `neutral*`). Dialog call sites inherit Phase 1 `dialogTheme`.

### Existing files (read first, then edit)
`widgets/ayre_components.dart`, `widgets/ayre_bottom_nav.dart`, `widgets/ayre_nav_metrics.dart`, `widgets/ayre_sheet.dart`, `widgets/state_views.dart`, `widgets/auth_widgets.dart`, `widgets/onboarding_widgets.dart`, `widgets/pressable_scale.dart`, `widgets/ayre_avatar.dart`, `widgets/spotlight_tour.dart`, `widgets/verification_banner.dart`, `widgets/ayre_tab_host.dart`.

### Dependencies
Phase 1 (new tokens + palettes).

### Work items
1. **Buttons (`AyreButton`):** primary = `accent` fill + `onAccent` label (light: green pill/ivory text; dark: ivory pill/green text); outline = `hairline`-strong border (`accentInk` text); danger = `negative` family with verified contrast (use `negativeText` on `negativeSoft` or solid `negative` with a ≥ 4.5:1 label). Update the stale doc comment about 4.38:1. Pressed/disabled states via `pressable_scale.dart` (its 8 `t.accent` refs) must still read correctly with ivory accent in dark mode (overlay/splash alpha). Never saffron.
2. **Cards/panels:** `AyreCard` (surface + hairline), `InkPanel` (the inverted/ink panel: light = deep-green panel with ivory content; dark = `surfaceRaised`/`surfaceSunken` panel; ensure content colours read ≥ 4.5:1 since `InkPanel` flips polarity), `RowGroup`, `SettingRow`, `HairlineDivider`.
3. **Chips/pills:** `ChipTone.neutral` (muted), `attention` (uses `neutral*` yellow-gold family), `brand` (`accentSoft` bg + `accentInk`), `TagPill`, `AyreFilterChip` (selected = `accent` fill/`onAccent`, or `accentSoft`; keep current choice, re-validate). Optionally add saffron emphasis through an existing tone only if §5.4 item 3 applies; do **not** add new public API unless unavoidable (if added, keep default behaviour identical).
4. **Switch/segmented/progress:** `AyreSwitch` on = `accent`, thumb `onAccent`, off = `surfaceSunken` + hairline; `AyreSegmented` selected = `accent`/`accentSoft` per existing pattern; `ProgressRule`, `SignalStrength`, `SkeletonBlock` shimmer from `skeleton`/`surfaceRaised` (dark skeleton `#174B39`).
5. **Forms:** `AuthField` (fill `surfaceSunken`, focus `accentInk`, error `negative`), `AuthMessage` (info/success/error use soft+text pairs), `PasswordChecklist`, `AuthScaffold` background = `background`. Keyboard focus ring ≥ 3:1 (`accentInk`).
6. **Navigation:** `AyreBottomNav` + `AyreNavRail`: bar bg `navBg`, top hairline `navHairline`, selected capsule `accentSoft` with `accentInk` glyph/label, unselected `foregroundSubtle`; keep blur/geometry/motion/labels/semantics untouched. If the nav shows any badge/dot, make it saffron (§5.4 item 1).
7. **Sheets/dialogs/banners:** `AyreSheet` (surface, hairline, sheet radius, grabber `foregroundSubtle`), `showAyreSheet` scrim (neutral deep-green-black at ~50–60 % alpha acceptable), the single `showDialog`-style call sites (profile_tab, settings_screen, ayre_components `_SectionInfoSheet`) inherit `dialogTheme` from Phase 1, so verify only; `OfflineBanner` (use `neutral` family, not saffron), `StatePanel`/`CalmStatePanel`/`FreshnessStamp`/`_RefreshDot` (dot may be saffron only if it is a transient attention cue and § 5.4 allows), `VerificationBanner`.
8. **Onboarding widgets:** `OnboardingPageIndicator` (active dot = saffron **or** `accent`; pick one: saffron is the §5.4 item 2 candidate), `OnboardingWash` (brand tint wash from `accentSoft`/green alpha, not emerald literals), `OnboardingFeatureRows`.
9. **Spotlight tour:** scrim stays dark-neutral (re-tint toward `#04140F` optional); highlight ring = saffron (§5.4 item 2) with `onHighlight` content on any saffron fill; tooltip card uses `surface`/`textPrimary`.
10. **Avatar:** uses new `avatarFill/avatarInk` automatically; check initials contrast.

### Files expected in ZIP
Only files actually changed among those listed above, plus the plan, install scripts, `FILE_LIST.md`.

### Expected outcome
Every shared control, bar, sheet, dialog and form looks branded and consistent in both modes with no leftover emerald; saffron appears only in the permitted spots.

### Acceptance criteria
* No `Color(0x…)` literals remain in these files except alpha-neutral/transparent ones.
* Each interactive element meets ≥ 48 dp target (unchanged) and ≥ 4.5:1 text, ≥ 3:1 graphics in both modes.
* Saffron appears ≤ once per viewport and never as text on ivory.
* Behaviour, navigation, semantics keys (`navDestinationKey`) unchanged.

---

## 8. PHASE 3: Screens, feature widgets, data-viz, splash/auth composition

**Goal:** finish visual adoption in feature-level widgets and screens, remove remaining emerald literals, and compose splash/login/onboarding/home with the new brand.

**Status:** ✅ COMPLETED 2026-11-22

**Actual changes:** `ayre_insight_carousel.dart` (both palettes rebuilt from brand greens; eyebrow mint in both variants, not saffron, because Home's bell dot is the one saffron element). `ayre_hills.dart` (light = `#0F3D2E` @ 4/8/12 %, dark = ivory @ 5/9/13 %). `ayre_instrument_tile.dart` (`_darkPlate` → `#061D16`). `ayre_logo.dart` (`LogoMark` field colour = `surface` in dark / `background` in light so the tile is seamless; no asset change). `home_tab.dart` (bell unread dot → saffron `highlight`). `splash_screen.dart` (descriptor in `foregroundMuted`). Charts, weekly report, signals, stat tile, figure, other screens: no literal colours found (grep clean); token-driven.

### Existing files (read first, then edit)
`widgets/ayre_insight_carousel.dart`, `widgets/ayre_hills.dart`, `widgets/ayre_instrument_tile.dart`, `widgets/ayre_charts.dart`, `widgets/ayre_weekly_report.dart`, `widgets/ayre_signals_section.dart`, `widgets/ayre_stat_tile.dart`, `widgets/figure.dart`, `widgets/ayre_tab_scroll.dart`, `screens/splash_screen.dart`, `screens/login_screen.dart`, `screens/onboarding_screen.dart`, `screens/home_tab.dart`, `screens/home_shell.dart`, `screens/weekly_reports_tab.dart`, `screens/learn_tab.dart`, `screens/profile_tab.dart`, `screens/settings_screen.dart`, `screens/notifications_screen.dart`, `screens/lesson_screen.dart`, `screens/faq_screen.dart`, other forms/legal screens (read; edit only if they contain literal styling). `lib/screens/testing/replay_onboarding_row.dart` (read only).

### Dependencies
Phases 1–2.

### Work items
1. **Insight carousel palettes** (`_InsightPalette.light` / `.dark`): rebuild from brand greens.
   * *light variant* (dark card on ivory page): gradient `#0F3D2E → #0A2A20`, headline/description ivory (`#F7F5EF` @ 100 % / 82 %), eyebrow saffron `#FF9933` (7.22:1 on `#0A2A20`), bars ivory-mint `#BFE6CF`, pill ivory @ 14 % alpha with ivory text, arrows/pager ivory-alpha; glow = green-alpha.
   * *dark variant*: gradient `#0A2A20 → #061D16`, 1 px border mint @ 20 %, eyebrow saffron or mint (choose one), bars `#4ED892`-family only if representing gain else mint `#BFE6CF`. Saffron here counts toward the §5.4 "one per viewport" budget for Home.
   Check all text ≥ 4.5:1.
2. **`AyreHills`:** light tints = `#0F3D2E` at 4/8/12 % alpha; dark tints = ivory/mint at 5/9/13 % alpha (keep the explicit-ARGB structure and three-layer geometry).
3. **`AyreInstrumentTile` plates:** `_lightPlate` stays `#FFFFFF`; `_darkPlate` → `#061D16` (still a dark plate for white artwork). Keep monogram fallback colours from tokens. *Do not* alter `StockLogoService` logic.
4. **Charts (`ayre_charts.dart`, `ayre_weekly_report.dart`, `ayre_signals_section.dart`, `ayre_stat_tile.dart`, `figure.dart`):** series/line/area colours from tokens; gain/loss keep `positive`/`negative` semantics; neutral/benchmark lines use `foregroundSubtle`/`accentInk`; grid/axis from `hairline`/`foregroundSubtle`. No saffron series.
5. **Splash (`AyreSplashScreen`):** background `t.background` (ivory in light, `#0A2A20` in dark); `LogoMark(splash)` (already theme-aware asset); label `'MARKET TERMINAL'` in `foregroundMuted`. Motion unchanged. Light-mode tile (ivory on ivory) is intentionally seamless: confirm the `ClipRRect`/`ColoredBox` (`surfaceSunken`) in `LogoMark` produces no visible seam: if the light tile reads as a card on `#F7F5EF` (it should be invisible), keep; if `surfaceSunken` (`#E7E4D8`) peeks at antialiased corners, the fix is to make the `ColoredBox` colour match the asset's field for that brightness (a one-line change in `ayre_logo.dart`, allowed here as a presentation tweak, **never** a different asset).
6. **Login / Onboarding / Register family:** `LogoMark(auth)` placement unchanged; backgrounds/washes via tokens; verify `OnboardingFeatureRows` icon tiles use `accentSoft`/`accentInk`.
7. **Home (`home_tab.dart`):** header region colours via tokens (wordmark replaced in Phase 4); greeting/hero emphasis; insight carousel; signals section; remove any emerald literal; verify `AyreHills` placement contrast.
8. **Reports / Learn / Profile / Settings / Notifications / Lesson / FAQ / legal screens:** token adoption only; ensure `SectionLabel`, `RowGroup`, `AyreSegmented` (Appearance tiles) look right; notifications unread indicator → saffron dot (if the screen has one; §5.4 item 1); leave all copy unchanged (Phase 4).
9. **`AppBar` screens (7):** inherit `appBarTheme`; check back-icon/title colours and status-bar icon contrast over `background`.
10. **Search-and-fix sweep:** grep `lib/` for `0xFF1E8749`, `0xFF3FCB7A`, `0xFF2E9E5B`, `0xFF4ED892`, `0xFF0B120D`, `0xFFF1F7F1`, `Colors.green`, `Colors.white`, `Colors.black` and resolve each (keep legitimate semantic `positive` uses).

### Files expected in ZIP
Only changed files among the lists above (+ plan, scripts, file list).

### Expected outcome
No old emerald/mint anywhere; Home, Reports, Learn, Profile, Settings, auth, onboarding and splash all look native to the new brand in both modes.

### Acceptance criteria
* Grep for the old hex values returns nothing outside comments/history docs.
* Carousel, hills, plates, charts, splash verified against §5.2 contrast.
* Saffron budget respected on every screen.
* No logic/navigation/data changes.

---

## 9. PHASE 4: Rename in Dart: copy, legal, wordmark, accessibility labels

**Goal:** every Dart-visible "ayre/Ayre/Ayre Scanner" becomes **Investee**, with a proper in-app wordmark, without touching identifiers or notification setup.

**Status:** ✅ COMPLETED 2026-11-22

**Actual changes:** `main.dart` (`MaterialApp.title` = Investee). `legal_config.dart` (`kBrandName = 'Investee'`). `legal_content.dart` (4 hard-coded names → `$kBrandName`, still const-valid). `delete_account_screen.dart`, `legal_hub_screen.dart`, `register_screen.dart`, `settings_screen.dart` (copy). `ayre_logo.dart` (wordmark text `investee`, semantics `Investee`, fallback `investee`). `pubspec.yaml` (description only). Home header unchanged (wordmark + SCANNER).

### Existing files (read first, then edit)
`lib/main.dart`, `lib/legal/legal_config.dart`, `lib/legal/legal_content.dart`, `lib/widgets/ayre_logo.dart`, `lib/screens/home_tab.dart`, `lib/screens/settings_screen.dart`, `lib/screens/delete_account_screen.dart`, `lib/screens/legal_hub_screen.dart`, `lib/screens/register_screen.dart`, `lib/screens/splash_screen.dart` (check only), `lib/onboarding/onboarding_content.dart`, `lib/onboarding/tour_content.dart`, `lib/screens/faq_screen.dart`, `lib/screens/support_screen.dart` (check only), `pubspec.yaml` (description only).

### Dependencies
Phases 1–3 (wordmark uses final tokens; Phase 3 touched `ayre_logo.dart`/`home_tab.dart` visually, so merge on top of the Phase 3 versions).

### Work items
1. **`main.dart`:** `MaterialApp(title: 'Investee')` (controls OS task-switcher title and web document title).
2. **Legal (D1):** `kBrandName = 'Investee'`; update the doc comment (`"Ayre" is the name used in the app…` → Investee). In `legal_content.dart` replace the five hard-coded names (lines ~70, 891, 892, 905, 942) with `$kBrandName` interpolation (convert adjacent string literals to interpolated ones; keep punctuation/curly quotes exactly). Do **not** alter any other legal wording, placeholders (`[ … ]`) or the RA identity fields. Re-scan `legal_content.dart` for `ayre` in any case/variant.
3. **User copy:** `delete_account_screen.dart` (2 strings), `legal_hub_screen.dart` (`'Using Investee'`), `register_screen.dart` (`'Set up your Investee account.'`: drop "Scanner"), `settings_screen.dart` (3 strings: theme captions → "Investee always uses the light/dark theme."; device-settings sentence → "…for Investee in your device settings."). Check `onboarding_content.dart`, `tour_content.dart`, FAQ for any brand mention (none found in analysis; confirm).
4. **Wordmark (`ayre_logo.dart` → `LogoWordmark`):** render text `'investee'` (lowercase, matching the logotype) in `textPrimary` (ivory in dark, deep green in light), Hanken Grotesk w700, letter-spacing ≈ −0.6 (existing), keep `fontSize`/`color` parameters and API. `Semantics(label: 'Investee')`. `LogoMark` semantics label → `'Investee'`; `_Fallback` text → `'investee'`. Keep `assetPathDark/Light` logic and everything from §3.2.
5. **Home header (`home_tab.dart` ~285–296):** keep `LogoWordmark` + `SCANNER` descriptor (D3). If the combined phrase "investee SCANNER" needs visual balance, adjust only spacing/colour (`foregroundMuted`).
6. **`pubspec.yaml`:** `description: "Investee: market research and signals."`. **Do not** change `name:`, `version:`, dependencies, or asset entries.
7. **Dart identifiers untouched** (no renames of `Ayre*` classes, files or imports).
8. **Accessibility labels:** all `Semantics`/`tooltip`/`semanticLabel` strings containing the old name → Investee (only the two in `ayre_logo.dart` were found; re-grep `lib/` case-insensitively for `ayre` inside string literals, excluding imports/identifiers/comments, as the final check).

### Files expected in ZIP
Changed files among the list above (+ plan, scripts, file list).

### Expected outcome
No Dart string a user can see or a screen reader can announce says Ayre; legal documents and FAQ read "Investee" consistently; wordmark shows "investee".

### Acceptance criteria
* Case-insensitive grep of string literals in `lib/` for `ayre` finds only `kSupportAddress` (`ayrescanner.app`, D4) and the API URL (`api_service.dart`), both intentional.
* `legal_config.dart` placeholders unchanged; legal text compiles with interpolation (no stray `$`).
* No changes to `push_service.dart`, `notification_copy.dart`, auth/Firebase files.
* Hand-off message lists D1 (legal/trade-name confirmation) and D4 (email domain) as owner actions.

---

## 10. PHASE 5: Native & web identity, notification visuals, accessibility audit, final sweep

**Goal:** finish user-visible naming and colours outside Dart, protect push notifications, and run the final consistency/accessibility review.

**Status:** ✅ COMPLETED 2026-11-22

**Actual changes:** Android label `Investee`; `ayre_notification_accent` value → `#FF9933` (name unchanged); channel description string → "…messages from Investee" (ID/name untouched); iOS `CFBundleDisplayName`/`CFBundleName` → `Investee`; macOS `CFBundleDisplayName = Investee` added (`PRODUCT_NAME` left, D8); Windows window title + `FileDescription`/`ProductName`; Linux both titles; web `<title>`, apple title, description, `theme-color` light/dark pair, html/body background (ivory / `#0A2A20`); manifest name/short_name/description, `theme_color #0F3D2E`, `background_color #F7F5EF`. N1 (native launch background) not applied (default OFF).

### Existing files (read first, then edit)
`android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/values/colors.xml`, `android/app/src/main/kotlin/com/example/ayre_scanner/MainActivity.kt`, `ios/Runner/Info.plist`, `macos/Runner/Info.plist` (check), `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `linux/runner/my_application.cc`, `web/index.html`, `web/manifest.json`; read-only: `drawable*/launch_background.xml`, `values*/styles.xml`, `LaunchScreen.storyboard`.

### Dependencies
Phases 1–4 (final brand strings/colours).

### Work items
1. **Android label:** `android:label="Investee"` (line 6). Do **not** touch the `<meta-data>` blocks (channel id `ayre_signals`, `@drawable/ic_stat_ayre`, `@color/ayre_notification_accent`) nor the activity/intent-filter.
2. **Notification accent (D7):** in `colors.xml` change only the **value** of `ayre_notification_accent` to `#FF9933`; keep the resource name and file structure.
3. **Notification channel description (D5):** in `MainActivity.kt` change only the string `"New scanner picks and messages from Ayre"` → `"New scanner picks and messages from Investee"`. Leave `PUSH_CHANNEL_ID`, channel name `"Signals and alerts"`, importance and package untouched. *(Skip if owner objects.)*
4. **iOS:** `CFBundleDisplayName` → `Investee`; `CFBundleName` → `Investee`. No other key. (No `UIUserInterfaceStyle` is set, so iOS follows system appearance. Leave it that way.)
5. **macOS (D8):** leave `PRODUCT_NAME`. Add `CFBundleDisplayName = Investee` to `macos/Runner/Info.plist` only if absent. Report the menu-bar limitation.
6. **Windows:** `main.cpp` window title `L"Investee"`; `Runner.rc` `FileDescription` and `ProductName` → `Investee`. Leave `InternalName`, `OriginalFilename`, binary name.
7. **Linux:** `my_application.cc` both title strings → `"Investee"`. Leave `BINARY_NAME` / `APPLICATION_ID` in `CMakeLists.txt`.
8. **Web:** `index.html`: `<title>Investee</title>`, `apple-mobile-web-app-title` → `Investee`, `meta name=description` → "Investee: market research and signals."; add `<meta name="theme-color">` pair with `media="(prefers-color-scheme: light|dark)"` → `#F7F5EF` / `#0A2A20`; keep all icon links from §3.2. `manifest.json`: `name`/`short_name` → `Investee`, description → same sentence, `theme_color` → `#0F3D2E`, `background_color` → `#F7F5EF`; keep icon entries. Also ensure the Flutter web bootstrap/body has no leftover blue/white flash colour in `index.html` (colour-only).
9. **Optional N1 (default OFF, needs owner approval):** brand-colour the Android native launch background (ivory in `values/`, `#0A2A20` in `values-night/`) to remove the white flash before the Flutter splash on dark-mode phones. Default is to keep the existing blank backgrounds.
10. **Accessibility & consistency audit (review, not tests):** walk Home, Reports, Learn, Profile, Settings, Notifications, auth, onboarding, legal, sheets/dialogs in light + dark at OS font scale 1.0 and ~1.6 and with the in-app text-size options; confirm contrast table values, targets ≥ 48 dp, screen-reader names say "Investee", Reduce-Motion honoured, no meaning conveyed by colour alone, status-bar icons legible on every screen's top background, themed icon assets present.
11. **Final grep sweep** over the whole project (excluding `.dart_tool`, build output, historic `*.md` design notes): any remaining user-visible `ayre`; old hex values; confirm the §2 do-not-touch items are byte-identical to the originals (channel id, resource names, identifiers, Firebase files, backend).
12. **Owner hand-off notes** (in the final message and in §12): D1, D2 outcome, D4, D6, D8; Android no-native-dark-icon limitation; Android ≤ 12 shows the single green icon; macOS/Windows single icon.

### Files expected in ZIP
Changed native/web files + `lib/…` fixes found by the audit + plan, scripts, file list.

### Expected outcome
Home-screen label, window titles, PWA name/colours, notification accent and channel text all say Investee / use brand colours; push notifications keep working because every identifier is unchanged.

### Acceptance criteria
* Home-screen labels (Android/iOS), web title, PWA manifest, desktop window titles read "Investee".
* `ayre_signals`, `ic_stat_ayre`, `ayre_notification_accent` names, package/bundle IDs, Firebase files and backend untouched.
* Audit checklist (item 10) complete and recorded in §12.
* Plan file marked fully complete.

---

## 11. Phase delivery protocol (every phase)

1. Implement only that phase's scope.
2. **Update this plan file:** set the phase row to ✅ with date, fill "Actual changes" under the phase heading (files touched, final token values if adjusted, deviations/decisions taken), revise later phases if reality differs, append to §12.
3. Produce **one ZIP** `investee_phaseN.zip` containing **only new/modified files**, in project-relative folders, **plus** `investee_branding_and_theme_overhaul_plan.md` at the project root, `FILE_LIST.md`, `install_phaseN.sh`, `install_phaseN.ps1`. Never include unchanged files or the whole project.
4. **`FILE_LIST.md`:** table of `ZIP path → destination path in project` for every file (identical relative paths).
5. **Install scripts** (`.sh` for macOS/Linux/Git-Bash, `.ps1` for Windows PowerShell), run **from the project root** (the one containing `pubspec.yaml`):
   * Abort with a message if `pubspec.yaml` is not in the current directory.
   * Extract the ZIP to a temp folder; copy each file to its relative destination, creating folders as needed.
   * Before overwriting, copy the existing file to `.phase_backups/phaseN_<timestamp>/<same relative path>`.
   * Only touch files that are in the ZIP; **never delete or move anything**; print each file written.
   * If any step is unreliable on the user's OS, `FILE_LIST.md` also contains manual copy instructions.
6. Hand-off message: file list with destination paths + the ZIP, nothing else (terse). **Stop.** Do not begin the next phase until the owner acknowledges.
7. No build, no tests, no code outside the phase scope.

---

## 12. Phase completion log

*(To be appended after each phase. Template:)*

```
### Phase N: ✅ completed YYYY-MM-DD
Files changed: …
Token values adjusted vs §5.2: …
Decisions taken (D#): …
Deviations from plan: …
Plan revisions made to later phases: …
```

### Phase 1: ✅ completed 2026-11-22
Files changed: `lib/theme/app_theme.dart`, `lib/main.dart`
Token values adjusted vs §5.2: none (all §5.2 values used as listed). Unlisted values chosen: dark `textDisabled` `#B3C3B9`@45%; `neutralSoft` light `#A67C00`@14%, dark `#E3B94F`@14%; dark `neutralText` = `neutral`; dark `positiveText` = `positive`; dark `highlightSoft` `#FF9933`@20%; light `highlightSoft` `#FF9933`@16%; `scrim` `#04140F`.
Decisions taken (D#): D2 implemented (reset once to `system` via `theme_mode_system_default_v1`).
Deviations from plan: `ColorScheme.error` = `negativeText` in light (white on `#D64545` is 4.38:1; white on `#B83232` is 5.93:1); dark `error` = `negative`, `onError` = dark `background` (6.26:1).
Plan revisions made to later phases: none.

### Phase 2: ✅ completed 2026-11-22
Files changed: `lib/widgets/ayre_components.dart`, `ayre_sheet.dart`, `onboarding_widgets.dart`, `spotlight_tour.dart`, `ayre_avatar.dart`
Token values adjusted vs §5.2: none.
Decisions taken: onboarding active dot = saffron (§5.4 item 2); tour ring = saffron; tour card indicator = `accentInk`.
Deviations from plan: added optional `OnboardingPageIndicator.activeColor` (default behaviour = saffron) to keep one saffron element per tour viewport.
Plan revisions made to later phases: none.

### Phase 3: ✅ completed 2026-11-22
Files changed: `lib/widgets/ayre_insight_carousel.dart`, `ayre_hills.dart`, `ayre_instrument_tile.dart`, `ayre_logo.dart`, `lib/screens/home_tab.dart`, `splash_screen.dart`
Token values adjusted vs §5.2: none.
Decisions taken: carousel eyebrow mint (not saffron) to honour one-saffron-per-viewport on Home; bell unread dot is that saffron element.
Deviations from plan: eyebrow colour above (plan §8 item 1 suggested saffron for the light variant).
Plan revisions made to later phases: none.

### Phase 4: ✅ completed 2026-11-22
Files changed: `lib/main.dart`, `lib/legal/legal_config.dart`, `lib/legal/legal_content.dart`, `lib/widgets/ayre_logo.dart`, `lib/screens/delete_account_screen.dart`, `legal_hub_screen.dart`, `register_screen.dart`, `settings_screen.dart`, `pubspec.yaml`
Decisions taken (D#): D1 applied (owner to confirm trade-name/SEBI implications; `legal_config.dart` placeholders unchanged). D3 kept. D4: `support@ayrescanner.app` and the Railway API URL left as is (owner action).
Deviations from plan: none. Final grep: remaining `ayre` string literals are only `kSupportAddress`, the API URL and asset paths.
Plan revisions made to later phases: none.

### Phase 5: ✅ completed 2026-11-22
Files changed: `android/app/src/main/AndroidManifest.xml`, `res/values/colors.xml`, `kotlin/com/example/ayre_scanner/MainActivity.kt`, `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `linux/runner/my_application.cc`, `web/index.html`, `web/manifest.json`
Decisions taken (D#): D5, D7, D8 applied as defaults; N1 skipped.
Final grep sweep (static): remaining `ayre` in non-Dart/native files are only the §2 do-not-touch items (applicationId/namespace/package, `ayre_signals`, `ic_stat_ayre`, `ayre_notification_accent`, `InternalName`/`OriginalFilename`, `PRODUCT_NAME`, bundle ID). Old hex values (`1E8749`, `3FCB7A`, `0175C2`) absent outside this plan. Dart string literals: only `kSupportAddress`, the API URL and asset paths.
Accessibility audit: static review only (contrast values per §5.2, 48 dp targets unchanged, semantics labels say Investee, Reduce-Motion paths untouched). On-device walkthrough at font scale 1.0/~1.6 in light + dark is an owner step.
Owner hand-off: D1 (confirm trade name / SEBI disclosure); D2 (theme resets once to System on update); D4 (`support@ayrescanner.app`, Railway URL unchanged); D6 (backend dashboard still says "Ayre."); D8 (macOS menu-bar name still `ayre_scanner`); Android has no automatic dark/light launcher icon (≤12 shows the single green icon, 13+ themed icon); macOS/Windows have a single icon.
