# Ayre Scanner — Redesign & Stabilization Brief (v3)

**Repository (primary scope):** `ayre_scanner_app` (Flutter application) — https://github.com/ayreofficial1-svg/ayre-scanner-app

**Backend repository (read-only reference):** `ayre_scanner` — https://github.com/ayreofficial1-svg/ayre-scanner

This is the **third redesign pass** on this app — the repository already reflects two prior redesign passes (referenced in Section 2 below as "Cinder" and "Cinder & Citrine"). This document is the complete, standalone implementation brief for this v3 pass. It contains requirements, design direction, and process instructions only. It does not contain design research, code, or backend analysis — those are explicitly separate steps described below and must be produced by whoever executes this brief, not assumed in advance.

**Note on reference images:** the product owner supplied five reference images alongside this brief, but they are not attached here and will not be visible to whoever implements this work. Section 3.1 below gives a full written description of each reference's relevant design characteristics — including which characteristics to adopt and which to intentionally leave behind — so the visual direction can be recreated without seeing the originals.

**Note on the logo:** the product owner is also providing a finished logo asset, `final_logo.png`, which will be placed directly in the Flutter repository — unlike the reference images, this file will be physically available to whoever implements this work, so it should be used as-is rather than recreated. Section 3.3 describes its visual content for context and gives placement/usage guidance.

---

## 0. Ground rules

1. **Scope order:** Work on the Flutter app first, completely. Only after the Flutter app is functionally and visually complete should the backend/API gap-analysis (Section 9) be produced.
2. **Backend is strictly read-only.** The backend lives in the separate `ayre_scanner` repository. It may be read, traced, and referenced to understand real API shapes, models, and data flow — but not one line of it may be modified, added, deleted, renamed, or moved.
3. **Admin `frontend` folder inside the backend repo is strictly read-only** for the same reasons. It is a separate admin website, not the user-facing app. Inspect and report on it if relevant; do not touch it.
4. **Do not fix backend or admin-frontend issues yourself**, even trivial ones. Document them in the Section 9 report and let the product owner decide.
5. **This is a full visual overhaul, not a recolor.** A user familiar with the current app should immediately recognize that the visual identity has been replaced — design language, color, typography, navigation, components, surfaces, states, and overall personality.
6. **Preserve everything that currently works functionally.** This is a redesign of presentation and interaction, and a fix of defects — not a rewrite of business logic, data contracts, or working features.

---

## 1. Required first step: design research (do this before making design decisions)

Before finalizing any visual or interaction decisions, research and internalize:

- **Apple's Human Interface Guidelines**, particularly the principles of simplicity, clarity, visual hierarchy, accessibility, motion, feedback, familiarity, craft, and delight. Treat this as an actual working reference, not a formality — decisions in Sections 2–6 below should be traceable back to specific HIG principles where relevant.
- **Professional mobile micro-interactions and animation patterns**: subtle screen/state transitions, navigation movement, feedback on tap/press, loading-to-content transitions, button press states, list/content transitions, and other small interaction details that make an app feel polished without feeling busy or gimmicky.
- **How professional UI/UX designers apply the Golden Ratio (1:1.618)** in real product work — e.g. to card/image aspect ratios, spacing scales, type scales, and layout proportioning — so it can be applied with genuine judgment per Section 3.2, rather than mechanically.
- **Common professional practices for app logo placement and sizing** — e.g. typical treatment on splash/launch screens, app icon vs. in-app usage, header/wordmark sizing conventions, and appropriate minimum clear space — so the logo introduced in Section 3.3 is placed the way a professional brand implementation would, not just dropped in wherever convenient.
- **How to identify when an app or UI looks obviously AI-generated** — the common visual patterns, design defaults, overused components, styling choices, layouts, typography, colors, spacing, card treatments, shadow usage, and glassmorphism usage that make interfaces read as generic/AI-generated rather than intentionally designed. Use multiple credible sources for this (design-critique articles, UX practitioner write-ups, designer commentary on generic "AI dashboard" aesthetics, etc.) and actually analyze and synthesize the findings — do not settle for a single generic checklist of "AI-looking" traits.

This research must genuinely inform Sections 2–8. Do not treat it as a checkbox — the final rationale for each major visual decision (palette, nav bar behavior, motion choices, card treatments, etc) should be able to reference a concrete design principle or precedent, not just aesthetic preference.

**Applying the "avoid looking AI-generated" research specifically:** the findings from that research must actively shape the design decisions made throughout this brief (Section 3 in particular), but must not be applied as a blunt ban list. Elements like glassmorphism, rounded cards, gradients, and other modern UI conventions are explicitly still wanted (see Section 3's "Requirements" and Section 3.1's synthesis) — they are not inherently AI-generated-looking, and are only a problem when used as an unconsidered default, repeated uniformly across every surface, or combined together indiscriminately. Use the research to find the middle ground: keep whichever of these patterns genuinely make a specific component more attractive, legible, or polished in that specific spot, while deliberately avoiding the excessive repetition, generic component defaults, and predictable pattern-combinations that the research identifies as the actual tells of an obviously AI-generated interface. The end result should read as intentional, distinctive, cohesive, and human-designed — not as a generic AI-generated template — while still retaining the modern visual elements that genuinely improve the UI.

---

## 2. Current-state findings (context for the redesign, not implementation instructions)

The repository has already been through two prior redesign passes (see `REDESIGN_CHANGES.md`, `REDESIGN_V2_CHANGES.md`, `ayrescan_final.md`, `ayrescan_redesign_v2.md` in the repo root — read these for history before starting). Relevant current state to be aware of:

- **Theme system:** `lib/theme/app_theme.dart` implements a token-based theme ("Cinder & Citrine") with a deliberately flat, glow-free, gradient-free, shadow-free cool palette (one brand hue "Citrine", gains in "Jade", losses in "Garnet"). This is the direct predecessor of the theme being redesigned now — read it fully before proposing the new palette so the new system is a genuine evolution, not a random restart.
- **Navigation bar today does not match the target behavior.** The current bottom navigation (`lib/widgets/fold_nav.dart`, "The Fold") is a **collapsing** control: at rest it shows a single small circular icon above a short hairline tray, and only expands into the full five-destination bar on tap, idle-timeout, or scroll — and in its expanded state it currently renders a visible text label (`Text(destination.label)`) under/beside each icon. **This directly conflicts with two new requirements: the navigation bar must always remain visible (never collapse), and it must show icons only with no visible text labels (Section 4).** This widget needs to be replaced with the always-visible, icon-only, curved/concave design described in Section 4, not adjusted incrementally. Each destination's existing `label` string (`'Home'`, `'Signals'`, `'Insights'`, `'Learn'`, `'Profile'`) should be preserved and reused as the accessibility/semantic label per Section 4, even though it's no longer shown visually.
- **Advances/Declines data already exists in the app and its data layer.** `Sentiment` (`lib/services/market_models.dart`) already has `advances`/`declines` fields sourced from the API via `MarketDataService.getSentiment()`. The Home tab's `_ScannerSummary` widget (`lib/screens/home_tab.dart`) currently displays a **`Sentiment` score number** as the leading figure, with Advances and Declines shown alongside it. The redesign in Section 5 must lead with Advances/Declines as the primary figures in that card and should not hardcode any values — continue sourcing from `MarketDataService.getSentiment()`.
- **Settings currently offers System/Light/Dark** via `ThemeMode` in `lib/screens/settings_screen.dart` (`AyreSegmented<ThemeMode>` with a `ThemeMode.system` option) and there is **no font-size preference** anywhere in `settings_store.dart` or the settings screen today. Section 6 below must remove the System option and add the font-size control from scratch, including its persistence.
- **State/failure handling is already architected, and should be extended, not replaced at the architecture level.** `lib/services/market_data_service.dart` already returns a `DataResult<T>` (`ready` / `empty` / `failed`, with a `stale` flag) from every data method, and `lib/services/fault_injection.dart` provides a `FaultInjector` specifically for simulating failure/empty/malformed/timeout scenarios in testing. `lib/widgets/state_views.dart` currently holds the shared loading/empty/failed UI (`StatePanel`, etc.). **Reuse the `DataResult`/`FaultInjector` data-layer pattern as-is** — the work in Section 7 is to redesign the *visual components* that render these states (new visuals, new copy, new recovery actions), not to invent a new data-result architecture.


---

## 3. Visual theme overhaul (applies to the entire app)

**Direction:** unique, fun, professional, aesthetically pleasing. Restrained — not colourful, flashy, futuristic, or saturated — but with enough personality to be distinctive and memorable, not generic. It must not look AI-generated or like a template dashboard. It must look intentionally designed by a professional product designer.

### 3.1 Reference visual language (described — source images are not attached)

The product owner supplied five reference images from other finance/dashboard apps. These images are **not included with this brief and will not be available to the designer/implementer.** What follows is a written description of the specific design characteristics worth studying in each, and — critically — a note on which characteristics to actually adopt versus which to treat only as structural inspiration, given that this app's direction is deliberately more restrained than most of these references.

**Reference A — "Financial Dashboard" concept (three-screen flow: balance overview, a limit/usage screen, a deposit/contact screen).**
- Bold, flat color-blocking across whole card surfaces: one card is solid warm yellow, one is solid near-black, one is white — no gradients or textures on these particular blocks, just confident flat color as the differentiator between cards.
- Large, heavy, geometric sans-serif display type for hero numbers (e.g. a balance figure) and headlines — noticeably bigger and bolder than typical dashboard type, used sparingly (one hero number per screen, not everywhere).
- Very generous corner radii on every card and button — soft, chunky rounded rectangles rather than sharp or barely-rounded corners.
- A circular radial gauge/progress meter (a speedometer-style arc filled with a green gradient) used to show a "monthly limit used" style metric — a good structural precedent for the kind of at-a-glance circular meter this app could use for a bounded metric (e.g. a sentiment/breadth band), but note this exact bright-green-on-black gauge is more saturated than this app's target palette; if a circular meter is adopted, restrained tones should replace the vivid gradient.
- Pill-shaped primary buttons with high-contrast fill (black button on yellow card, white circular icon buttons on dark cards).
- Small circular user/avatar photos used for transaction and contact rows, with a small green "verified" checkmark badge overlapping the avatar's edge.
- Takeaway to adopt: confident flat card color-blocking as a hierarchy tool, oversized display type for one hero metric per screen, chunky consistent corner radii, pill buttons. Takeaway to leave behind: the literal bright yellow/pure-black high-saturation palette and the vivid green gradient gauge — this app's palette should stay restrained per Section 3 below.

**Reference B — "Homebar" concept (the navigation bar reference — this is the most literally-adopted reference; see Section 4 for the full functional spec).**
- A black, fully rounded (pill-shaped) horizontal bar containing four to five simple, thin, single-weight line icons, evenly spaced.
- The active tab is shown as a solid white filled circle, larger than the bar's own height, positioned so it overlaps and rises above the top edge of the bar rather than sitting flush inside it.
- The bar's top edge is not a straight line where the circle sits — it curves inward/downward on both sides of the circle, forming a smooth concave "notch" that hugs the circle's lower half, so the circle reads as fused into the bar's silhouette rather than floating independently on top of it.
- The icon for the active tab sits inside the raised white circle (rendered in dark on the light circle, versus light-on-dark for the inactive icons in the bar itself).
- Everything else about this reference is intentionally plain: no color beyond black/white, no labels, no shadows or glow — the entire visual interest of this component comes purely from that one curved silhouette plus the raised circle, not from decoration. This restraint is exactly the tone to carry into this app's version (see Section 4's requirement to keep the final result "elegant" and "not exaggerated or goofy").

**Reference C — dark dashboard with pastel accent cards (three-screen flow: sales overview, monthly profit ring chart, account/balance with transaction list).**
- A dark charcoal/near-black base canvas throughout, with individual cards picked out in soft, low-saturation pastel fills (a muted mint/sage green, a dusty pink, a pale butter yellow) — the pastels sit on the dark background as gentle highlight blocks, not as a saturated or neon accent.
- A ring/donut chart used to break a total figure down into two or three weighted segments, each in one of those same soft pastel tones, with the total figure set large in the donut's empty center.
- Transaction/activity list rows built from: a small circular avatar photo on the left, name and relative timestamp stacked in the middle, and a right-aligned signed amount (colored to indicate positive/negative) — a clean, repeatable row pattern used consistently across screens.
- A small icon-only bottom navigation bar, rounded and low-contrast, sitting quietly at the bottom without competing with the card content above it.
- Takeaway to adopt: the idea of a dark neutral canvas punctuated by a small number of *soft, muted* accent-color card fills (not one loud brand color used everywhere), the ring/donut chart pattern for weighted breakdowns, and the avatar + name/time + signed-amount transaction row pattern. Takeaway to leave behind: nothing further needs softening here — this reference is already closer to the restrained tone this app wants than References A, D, and E.

**References D and E — green/lime "fintech-neon" dashboards (a card-transfer flow with a metallic green gradient card and a "Sending Money" screen; and a portfolio app with lime-green accents on an olive/black canvas).**
- Both use a single saturated accent hue (a bright, almost neon green/lime) applied heavily and repeatedly: gradient-filled hero cards with a diagonal metallic-looking sheen, solid-green pill buttons, green-filled line/area charts, green text for positive figures, and a green-filled active state in the bottom nav.
- Both also use pill-shaped bottom navigation bars with a solid-filled circular or capsule active-state highlight, which is structurally consistent with Reference B, just executed in a saturated brand color rather than plain black/white.
- Donut/ring charts appear again here too, reinforcing that this is a common, well-established pattern for breakdown metrics in this genre of app.
- Takeaway to adopt: pill-shaped controls and a filled circular/capsule active-state highlight are a recurring, proven pattern (further reinforcing Section 4's nav bar spec) — and the general idea of one clearly ownable accent hue used consistently for "positive"/brand moments is worth keeping. Takeaway to explicitly leave behind: the saturation level, the neon lime-on-black intensity, the heavy gradient/metallic card sheens, and using that one bright hue on nearly every surface — this is precisely the "colourful, flashy, saturated" territory this app's direction (start of Section 3) is meant to avoid. If this app keeps a single ownable accent hue (as its current "Citrine" token already does — see Section 2), it should stay muted/mineral rather than neon, and should be reserved for a small number of true brand/selection moments rather than applied broadly.

**Overall synthesis for the designer:** take structural and compositional ideas from all five references — flat confident card color-blocking, oversized single hero numbers, circular/ring data visualizations, avatar-led transaction rows, pill-shaped controls, and above all the concave-notch nav bar from Reference B — but execute them in the muted, low-saturation, mostly-neutral palette this brief calls for, closer in *intensity* to Reference C than to A, D, or E. The goal is the layout confidence and structural personality of these references without their saturation or neon-fintech color intensity.

**Requirements:**

- Apply the new theme across the **entire app**, not isolated screens. Every screen listed in Section 10 ("Testing / verification coverage") must reflect the new visual language.
- Design **both a dark theme and a light/white theme**, each deliberately crafted — the light theme must not simply be an inverted dark theme. Both must hold up to the same standard of polish.
- Rounded containers, gradients, glowing elements, glassmorphism, and animation are **allowed and encouraged where they earn their place** — this is not a flat/brutalist minimalism brief. But each use must be a deliberate, justified decision tied to what it does for legibility, hierarchy, or delight in that specific spot — not a default applied uniformly to every card, button, and panel. Overusing these techniques everywhere is exactly the "generic AI dashboard" look to avoid.
- Use the reference visual language described in Section 3.1 above, together with the current repository, as the design/context foundation. These descriptions are references for tone, density, and the navigation interaction — not a literal skin to copy wholesale (avoid, for example, directly reusing another product's exact card layout or color story).
- Typography, iconography (`lib/widgets/ayre_icons.dart`), spacing/radius tokens, elevation treatment, and motion should all be considered part of this system — not just color.
- Motion/micro-interactions (informed by Section 1 research) should be used for: navigation tab switching, button/press feedback, loading → content transitions, and state changes — kept subtle, purposeful, and consistently timed/eased across the app, not one-off per screen.

### 3.2 Golden Ratio guidance (apply intelligently, not mechanically)

The goal of this pass is to make the app **as aesthetically pleasing and polished as possible** while staying professional, clean, modern, and highly usable — the Golden Ratio (1:1.618) is one tool toward that goal, not a mandate.

- Wherever it is a natural fit and genuinely improves the result, consider using 1:1.618 (or its inverse, ~0.618) to guide: card/image/media aspect ratios, the proportion between a hero element and its supporting content, spacing/sizing scales (e.g. deriving a small set of spacing or radius tokens where each step relates to the previous by roughly the golden ratio, rather than arbitrary round numbers), type-scale steps between heading/body/caption sizes, and major layout proportioning (e.g. the split between a primary content area and a secondary panel, where a layout has two such regions).
- This is explicitly **not a strict requirement**. Do not force a golden-ratio dimension where it would hurt usability, responsiveness across different screen sizes, readability, touch-target sizing, or the overall design — practical constraints (minimum tap target sizes, safe-area insets, existing content density, accessibility text scaling from Section 6) always take priority over hitting an exact ratio.
- Where it's used, it should be applied with visible intent (e.g. as a documented basis for the app's spacing/type-scale tokens in Section 3's design system) rather than invisibly baked into one-off measurements that nobody could point to.
- Use the Section 1 research on professional Golden Ratio usage to decide where it earns its place versus where a simpler, more conventional proportion (e.g. an 8-point grid) is the more usable choice — the two approaches aren't mutually exclusive and can be combined (e.g. an 8-point-aligned spacing scale whose step multiplier is chosen close to 1.618).

### 3.3 Logo usage

The product owner has provided a finished app logo, `final_logo.png`, which will be placed in the same Flutter repository (exact path to be confirmed once uploaded — locate it in the repo before starting rather than assuming a path). Because the actual file will be available directly in the repository, use it as the authoritative asset rather than a recreation — the description below is only to give context to whoever plans logo placement before opening the file.

**What the logo looks like:** a rounded, thick-stroke letterform built from the letter "A" — drawn as a circular ring (echoing an "O"/"Q" shape) with a diagonal stroke crossing through its lower-right area to complete the "A", rendered in off-white on a black/near-black background. Inside the ring sits a small ascending candlestick chart (four candles trending upward, left to right) in a green gradient, and the diagonal stroke of the "A" is rendered as a green gradient ribbon/leaf shape rather than a plain straight bar. Below the mark sits the wordmark "ayre" in a lowercase, rounded, geometric sans-serif, in the same off-white as the ring. The overall mark is confident, rounded, and minimal, combining the brand's green accent with a neutral dark/light-neutral mark color — it should read clearly as this app's identity at both large sizes (splash screen) and very small sizes (nav/header icon).

**Where to use it:**
- **Splash/launch screen:** the primary, most prominent placement — centered, generously sized, without being oversized or filling the whole screen; leave clear breathing room around it consistent with standard splash-screen practice.
- **Onboarding/auth screens** (e.g. login/first-run), if present: a smaller, secondary placement — e.g. as a header mark above the primary content, not repeated on every step.
- **Empty states** introduced/redesigned in Section 9 (loading/empty/error): only where it genuinely reinforces brand identity in a moment with otherwise-blank canvas (e.g. a true first-run empty state) — do not use the logo as generic decoration inside every empty/error card, since that would be excessive rather than intentional.
- **In-app header/app-bar branding**, if the current information architecture has a natural spot for a small wordmark or mark (e.g. a top-level Home header) — sized small and unobtrusively, consistent with how the current header treats identity today; do not add a persistent large logo that competes with live content.
- Do **not** place the logo on every screen, inside ordinary content cards, or anywhere it would compete with real data for attention. The bar to use it should be "does this specific spot benefit from reinforcing brand identity," not "is there space here."
- Respect a sensible minimum clear-space margin around the mark wherever it's placed (informed by the Section 1 research on professional logo placement), and never stretch, recolor, rotate, or otherwise distort the asset — use it at consistent, appropriately scaled sizes suited to each placement (e.g. one larger splash size, one smaller header/mark size), not arbitrary ad hoc dimensions per screen.
- The logo's existing green must be treated as (or reconciled with) this app's one ownable accent hue from Section 3.1's synthesis — if the new theme's accent color differs from the green in this asset, resolve that inconsistency deliberately (most likely by aligning the theme's accent to this green, since the logo is the fixed brand asset) rather than shipping two different "brand greens" side by side.

---

## 4. Bottom navigation bar redesign

Reference: see Reference B in Section 3.1 above (the "Homebar" concept — a five-tab minimal dark pill bar where the active tab is a raised white circle sitting above the bar, with the bar curving concavely around it).

**Hard requirements:**

- **Five tabs total**, matching the app's current destinations (Home, Signals, Insights, Learn, Profile) — do not add, remove, or reorder destinations as part of this visual change.
- The navigation bar **must always remain visible**. It must never collapse into a single icon, disappear, auto-hide on scroll/idle, or switch to any other collapsed pattern. This is a direct, explicit change from the current `FoldNav`/"The Fold" behavior described in Section 2, which collapses to one circular control at rest — that collapsing behavior must be removed entirely, not tuned.
- Preserve the distinctive **active-tab interaction**: the selected tab renders as a circular element that rises slightly above the top edge of the bar, and the bar itself forms a smooth concave (U-shaped) curve around that raised circle, so the raised circle reads as integrated into the bar rather than a separate floating button on top of it.
- Refine this concept so it feels **professional, elegant, minimal (but not too minimal), and intentional** — not exaggerated, oversized, or "goofy." Use clean geometry, smooth curves, consistent iconography (reuse/extend `ayre_icons.dart`), balanced spacing between the five tabs, and restrained proportions (avoid an overly large raised circle or an overly deep concave cutout).
- The active-tab state must be immediately understandable at a glance (icon + raised position + curve is enough; avoid adding redundant labels/badges that clutter it) and must **transition smoothly** when switching between any of the five tabs — the raised circle and the concave curve should animate together, not pop or jump.
- **Remove all visible text labels from the bottom navigation bar — icons only**, across all five tabs, in both the resting and active states. The raised-circle + concave-curve treatment above must be sufficient on its own to make the selected tab clearly distinguishable without a text label; if any single icon is ambiguous without a label, redesign or swap that icon (via `ayre_icons.dart`) rather than reintroducing text.
- Maintain accessibility and usability despite removing visible labels: each tab must still expose a proper semantic/accessibility label (e.g. via Flutter's `Semantics`/`tooltip` support) so screen readers announce the destination name, and each tab's tappable area must meet standard minimum touch-target sizing (44×44pt / ~48×48dp) even though the icon glyph itself is smaller.
- This nav bar must be implemented consistently across both the light and dark themes established in Section 3, and must remain performant (see Section 7) — no jank when switching tabs, no dropped frames during the curve/circle transition.
- Where feasible, avoid a hand-rolled morph animation that's expensive to rebuild every frame; prefer a solution (e.g. a single custom-painted bar shape driven by an animated value, rather than multiple overlapping widgets recomposing) that keeps this control cheap to repaint, since it is present on virtually every screen.

---

## 5. Home page: market overview change

- In the Home page's market overview area (currently the `_ScannerSummary` card in `lib/screens/home_tab.dart`, which today leads with a numeric `Sentiment` score), **replace the leading number with Advances and Declines** as the primary figures shown.
- This data must continue to be sourced live from the existing data source — `MarketDataService.getSentiment()` / the `Sentiment` model's `advances` and `declines` fields — and must **not be hardcoded**. Values must update correctly whenever the underlying market data refreshes, including on pull-to-refresh and any existing polling/live-update behavior.
- Decide, as part of the redesign (not left ambiguous in the shipped UI), whether the raw sentiment score is dropped entirely, demoted to a secondary/supporting figure, or moved elsewhere (e.g. into Insights, where advances/declines are also already shown) — but the Home page's primary overview figures the user sees first must be Advances and Declines.
- This card must also carry the new loading/empty/stale/failed states from Section 7 — it already has its own skeleton and failed-state branches today; those must be redesigned to match the new system, not left in their current visual style.

---

## 6. Settings screen changes

- **Appearance:** Remove the `System` option entirely from the theme/appearance control (`lib/screens/settings_screen.dart`, currently built with `AyreSegmented<ThemeMode>` including `ThemeMode.system`). The user must only be able to choose between **Light** and **Dark**. Update whatever persists/reads the current theme mode (`ThemeController`/theme persistence) so it never resolves to or stores "system" going forward, and so existing users currently on "System" are migrated to a sensible explicit default (e.g. the device's current effective brightness at first load) rather than crashing or silently defaulting incorrectly.
- **Font size preference:** Add a new font-size control to Settings (there is currently no such control or stored preference anywhere in `settings_store.dart`). Requirements:
  - Offer a small number of discrete sizes (e.g. Small / Default / Large, or similar — pick a scale consistent with the rest of the settings' visual language).
  - Include a **small live or representative preview** in the control itself, showing what each size will look like (e.g. sample text rendered at each size, or a live-updating sample as the user picks) *before* they commit to a selection.
  - The chosen size must actually apply across the app's text scale (via the theme's typography tokens/`AppTypo`, or Flutter's text scaling mechanism applied consistently) — not just visually preview and then do nothing.
  - Persist the choice the same way other settings are persisted, and apply it immediately without requiring an app restart.

---

## 7. Settings & Profile section redesign (structural, not just visual)

Both `lib/screens/settings_screen.dart` and `lib/screens/profile_tab.dart` (plus `edit_profile_screen.dart`) currently feel too basic/placeholder-like. Expand and redesign them so they read as fully realized, production-quality sections:

- Improve **information hierarchy**: clear section groupings (e.g. Account, Appearance, Notifications, Security/Session, About/Support), sensible ordering, and visual weight that matches importance.
- Improve **grouping and spacing** consistent with the new design system from Section 3 — related controls visually grouped, unrelated controls clearly separated, consistent use of section headers/labels.
- Add **useful controls/content** appropriate to a finished product where currently thin — e.g. account details, session/security info, notification preferences, help/support access, app version/build info — using only data and actions the current app and backend already support (do not invent settings that have no backing functionality; if a desired setting has no backend support, note it in the Section 9 report instead of building a dead control).
- Keep both sections fully consistent with the rest of the app's new visual language — same card/surface treatment, same typography scale, same motion language — so they read as native parts of the product rather than a bolted-on placeholder screen.

---

## 8. Performance

The app has become noticeably laggier than the previous version. Performance must be treated as a first-class requirement of this work, not a side effect of the redesign:

- Audit and remove unnecessary rebuilds, expensive widget trees, unthrottled animations, and any rendering work happening off-screen or redundantly (especially around the navigation bar per Section 4, list-heavy screens like Signals/Insights/Learn, and any live/ticking market-data displays like `ticker_trace.dart`).
- Avoid animations, effects, or interactions (including glassmorphism/blur, gradients, and glow effects introduced under Section 3) that noticeably cost frame time; where an effect is worth keeping visually, implement it in the cheapest form that achieves the same look (e.g. precomputed/static gradients over expensive per-frame blur where a static look suffices).
- The end result should feel fast, responsive, and smooth on typical devices — no jank on tab switches, list scrolling, screen transitions, or live data updates.
- Verify performance specifically on: navigation bar transitions (Section 4), Home page live data refresh (Section 5), and any list/chart-heavy screens (Signals, Insights, index constituents, equity detail).

---

## 9. Error, loading, empty, and failure states — full redesign

**Principle:** every state — loading, empty, unavailable-data, success, offline, and failure — is an intentional, designed part of the new system, not an afterthought. **Do not reuse the current failure/empty/loading cards, icons, colors, or components** (today centralized in `lib/widgets/state_views.dart`, e.g. `StatePanel`) as-is — redesign their visuals so they clearly belong to the new visual language from Section 3, while keeping (and extending, if needed) the existing `DataResult`-based data flow described in Section 2.

**Scenarios that must be explicitly designed for, app-wide:**
- API/network failures and timeouts
- No network connection / offline
- Authentication/session failures and session expiration
- Stale or delayed market data (the app already tracks a `stale` flag on `DataResult` — surface this meaningfully rather than silently)
- Empty responses (e.g. no signals today, no notes, no courses)
- Malformed/unexpected API responses
- Failed loading specifically for: signals, sentiment, index/company data, equity detail, course/learn content, notifications

**Requirements for each state's UI:**
- No raw technical errors and no generic messages like "Something went wrong." Every failure/empty state must clearly explain, in plain language, what happened and whether the user needs to do anything.
- Provide an appropriate recovery action wherever one exists and makes sense for that situation — retry, refresh/pull-to-refresh, reconnect, re-authenticate/sign in again, etc. Not every state needs an action (e.g. a genuinely empty list may just need a clear empty message), but don't omit an action where one is obviously appropriate.
- Keep these states visually and tonally consistent with the rest of the new design system — same typography, color use (including how the palette signals "attention"/failure without reverting to a generic red-alert look that clashes with the new palette), spacing, and motion language.

**Verification requirement — do this before considering the work done:**
Use the existing `FaultInjector` (`lib/services/fault_injection.dart`) and/or equivalent test scaffolding already in the repo (`test/fault_states_test.dart` is a relevant existing reference) to intentionally simulate failures, empty responses, malformed responses, disconnection, timeouts, stale data, and authentication failures, and confirm the correct new fallback UI, error state, retry behavior, and recovery flow actually appear — across at minimum:

- Home market data (index board, `_ScannerSummary` advances/declines card)
- NIFTY 50, SENSEX, BANK NIFTY (index detail screens)
- Individual index constituents
- Equity details
- Signals
- Insights
- Gainers, Losers, Most Active
- Learn (courses/lessons)
- Profile
- Settings
- Authentication/session behavior (login, session expiry mid-use)
- Live-data updates / refresh behavior

Do not assume the redesigned states "will just work" because the underlying `DataResult` plumbing already exists — each surface above must be checked against its failure/empty/stale paths, not just its happy path.

---

## 10. Flutter compile/analysis error cleanup

- Before doing anything else in this section, run `flutter pub get` and a full `flutter analyze` against the current repository and treat the actual current output as the authoritative list of problems — see the Section 2 note that several previously-reported symptoms (a `profile_menu_sheet.dart` file, `premium_widgets.dart`, `AnimatedEntrance`, `GlassCircleButton`, `PremiumCard`) do not currently exist in this codebase and may already be resolved from prior redesign passes.
- For whatever errors/warnings *do* surface (including, if still present anywhere: missing theme tokens such as `accentMint`, `accentWarm`, `accentCool`, `onNeutralBlock`, `negative`, `primary`, `shadowLg`, `onPrimary`; missing radius tokens `pill`/`xl`; missing identifiers such as `AppGradients`/`AyreSection`; missing typography such as `AppTypo.eyebrow`), trace each one back to its actual cause rather than papering over it — e.g. if a screen references a theme token that doesn't exist, decide deliberately whether that token belongs in the new `AppThemeTokens` design system from Section 3 and add it properly there (with a value that fits the new palette), rather than stubbing a throwaway constant just to compile.
- Do not suppress warnings, delete functionality, comment out problem code, or add placeholder/no-op implementations purely to make errors disappear.
- After resolving the direct errors, re-run `flutter analyze` again to catch anything the fixes newly exposed elsewhere in the app, and resolve those too.
- Finish with a clean `flutter analyze` (or an explicitly justified, minimal remaining-warnings list) and confirm the app actually builds and runs.

---

## 11. Final review before calling the Flutter work complete

Before moving to the backend analysis in Section 12, explicitly check the app for:
- Compile errors, analyzer errors, broken imports, undefined references, missing components
- API/data-flow issues introduced by the redesign
- Runtime failures and navigation problems (including deep interaction with the new nav bar from Section 4)
- Visual inconsistencies or leftover old-design elements anywhere in the app (colors, components, spacing, icons, copy) that don't match the new system from Section 3
- That every screen listed in Section 9's verification list has been visually redesigned, not just the ones explicitly called out elsewhere in this brief (Home, Settings, Profile, nav bar)

---

## 12. Backend & admin-frontend analysis (separate step, after Section 11 is done)

Once the Flutter app work above is complete, perform a **read-only** analysis of the backend (`ayre_scanner` repo) and its admin `frontend` folder, using them purely as reference — no code changes to either. Produce a report that:

- Identifies everything in the Flutter app that currently has **no corresponding backend support** — missing endpoints, missing fields, incompatible/mismatched request or response models, missing data the redesigned UI now depends on (e.g. confirm the advances/declines fields used in Section 5 are reliably populated by the backend, and flag it if they're sometimes absent/null in practice).
- Identifies backend-side **bugs, broken endpoints, inconsistent models, incorrect data handling, security issues, outdated logic, or missing fields** discovered while cross-referencing the app's needs against the backend's actual implementation.
- Identifies any issues, bugs, or integration mismatches found while inspecting the separate admin `frontend` folder inside the backend repo, if relevant to how the Flutter app and backend interact.
- Clearly separates findings into two buckets: **(a) issues that can/should be fixed in the Flutter app**, and **(b) issues that live in the backend or admin frontend and require the product owner's decision** — do not fix bucket (b) items yourself, per Section 0.
- Is explicit and concrete about what is missing, what is broken, what is mismatched, and what currently cannot work end-to-end because the backend doesn't support it yet.

This backend analysis and its report are the final deliverable of this brief, after the Flutter app itself is complete.