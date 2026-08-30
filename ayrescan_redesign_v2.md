# Ayre Scanner — Visual Redesign v2 Specification
### "Cinder & Citrine" — an original, brand-led market-terminal identity, replacing the brass/parchment "instrument" system in full

---

## 0. How to use this document

This is an implementation brief for a **second, total redesign** of the Ayre Scanner Flutter app (`ayre-scanner-app`). The current build already went through one full redesign (documented in `ayrescan_final.md` / `REDESIGN_CHANGES.md`), which produced the warm brass, parchment/ink, "precision instrument" identity now shipping — the cream-and-brown Home/Signals/Climate/Learn/Profile screens described in the current build. **That identity is being fully retired, in full, again.** This is a complete visual overhaul, not a refinement, recolor, or incremental pass on the first redesign. Nothing about the current design language — palette, ornament vocabulary, gauge/needle motif, card material, typography pairing, iconography, or the current floating pill's shape and finish — carries forward. The required **functionality and information structure** (screen inventory, what each screen does, what data it shows) is preserved; the **entire visual execution, identity, and feel** is rethought from zero. Treat this exactly as the first redesign treated the version before it: a functional skeleton only, described for reference, not for visual continuity.

This document assumes the reader can open the codebase (`lib/theme/app_theme.dart`, `lib/screens/*`, `lib/widgets/*`, `lib/services/*`) for exact current behavior. It does not restate implementation code. It specifies **design intent** — palette and roles, type system, layout, component behavior, states — at a level a design or engineering team can implement without further creative decisions on direction, while leaving exact hex/spacing/motion values to be finalized in-tool against the actual grid.

**Research basis.** Before finalizing direction, the brief calls for grounding this in real research into modern fintech, trading/financial-terminal, and premium mobile app design — specifically to avoid the two failure modes most redesigns of this kind fall into: looking AI-generated/templated, and defaulting to the same handful of "generic fintech" visual tropes (soft glassmorphism, a default trust-blue or mint-green, rounded pill-everything, stock icon sets). The strongest current fintech and premium-app work increasingly wins on **strong, ownable brand identity and clear data hierarchy** rather than on following a visual trend — a distinctive color system, a considered type pairing, and a signature interaction detail (like a navigation mechanic nobody else has) read as "real product" in a way that a well-executed but generic template never does, regardless of polish. That is the standard this document is written to.

**Reference material reviewed for this pass.** Seven consumer-app references were reviewed across two rounds, for composition, brand personality, and interaction ideas only — **not for their colors**, which are addressed directly in §2:
- A purple/gold digital-wallet concept, a lime-green/black neobank concept, and an orange/black ride-and-wallet app (round 1) — used for hero-card composition, oversized balance/value typography, and quick-action row layout.
- A near-black neobank ("Spendly") with a saturated acid-green brand color used consistently across onboarding, balance, and transaction-entry screens — used as one data point on how far a financial product can lean into a single, confident, unconventional brand hue on a near-black base and still read as trustworthy rather than novelty.
- A dark study-app promo screen mixing near-black with acid-green plus punchy secondary blocks (coral, sky, lavender) for category tiles — used only for the observation that a disciplined neutral base can support **one saturated signature hue plus a small number of clearly-secondary accent hues** without reading as chaotic, provided the secondary hues are used narrowly and never for brand-carrying elements.
- A lavender-branded wellness app with a floating bottom navigation that pairs a rounded bar with a raised, off-axis circular control — this is the specific reference behind the new navigation concept in §5: an "expand/contract triggered by a small floating control" mechanic, taken as a structural/interaction idea only and rebuilt into something that does not resemble it visually (see §5 for exactly what is reused as a *concept* versus rebuilt).

None of these references' literal palettes, layouts, or component shapes are reused. Ayre Scanner's own identity, described below, is built specifically for a **market intelligence / trading terminal** context, is meant to be recognizable as *this app's* color system rather than a member of a generic fintech-blue/fintech-green/fintech-purple category, and is deliberately more restrained and professional than the more consumer/lifestyle-leaning references above.

---

## 1. Executive summary & direction

**The organizing idea: Ayre Scanner is a terminal, not an app.** The previous identity treated the product as a physical measuring instrument (gauges, engraved ticks, brass). This redesign treats it as a **professional trading terminal reimagined for mobile** — the visual language of a Bloomberg/Refinitiv-class desk tool, translated into a modern, touch-first product rather than a literal skeuomorphic terminal pastiche, and carrying a brand identity confident enough to be recognizable at a glance. Every decision below serves that idea:

- **A near-black, ink-and-slate base in both themes**, with light mode reading as "paper under terminal glass" (cool white, not cream) rather than a bright consumer app, and dark mode reading as an actual trading desk at night (true near-black, not warm brown). This is the single biggest structural break from the current build: **the base hue family moves from warm brown/cream to cool ink/graphite/paper.**
- **An original, ownable brand accent — Citrine** — a warm, mineral, gold-edged acid-green, deliberately tuned to be distinctive and premium rather than a default fintech blue, mint, or violet (see §2 for exactly how it's differentiated from both "generic fintech green" and the app's own gain-color, so it never gets confused with market data). This is the palette's single biggest personality decision and the thing that should make the app recognizable in a screenshot with no chrome around it.
- **Data rendered in a dedicated monospaced "ticker" face**, set in tight, tabular, terminal-style rows — every index, price, and percentage in the app reads like it came off a real feed, not a decorative dashboard number.
- **A hero market card treated as a physical trading card/badge**, not a soft gradient tile — flat color, hard-edged data blocks, a distinct dark "readout" panel for the live figures, echoing the card-like hero treatments in the references but rebuilt in the new palette.
- **A new floating navigation with an expand/contract mechanic**: not a pill, not a static bar — a compact floating control that a small, distinct trigger element can unfold into the full five-destination dock and fold back down again, replacing both the old brand's brass pill and the references' static rounded nav bars with an interaction that has not appeared in this app before (see §5 — inspired by, but visually and mechanically distinct from, the reference that introduced this idea).
- **Insights becomes the app's "market intelligence desk"** — sentiment, breadth, and all three mover lists (Gainers/Losers/Most Active) live there as one continuous, data-dense feed, not three stacked cards.
- **Home becomes a live index gateway**: NIFTY 50 / SENSEX / BANK NIFTY are the three primary tappable instruments, each opening into a constituent list and onward into individual equities.
- **A complete, first-class failure-state system**, designed as terminal-style status readouts (a "feed offline" panel, not a generic error card), specified with exact triggers, a test/simulation matrix, and a mandatory pre-ship verification pass (§9.4) so failure design isn't treated as an afterthought.

**What is kept from the current engineering foundation (not the visual system):** the token-extension architecture (`AppThemeTokens` as the single override point), the 8pt-grid spacing scale, the `IndexedStack` tab-preservation mechanism, `PressableScale` press feedback, the disciplined "no bounce" motion policy, and the existing screen/route inventory. Only the **values and roles inside those systems** change, plus the specific new screens/routes called out below (Index Detail, Equity Detail, redesigned Insights).

---

## 2. Color system — "Cinder & Citrine"

### 2.1 Why this direction, and what it deliberately avoids

The brief is explicit that a generic fintech palette is a failure condition here, not an acceptable outcome — and that the previous draft of this document (a blue-on-cool-neutral "Signal Blue" system) was itself still too close to the fintech-blue default to count as a real identity. The replacement below is built around one rule: **the app should have exactly one hue nobody else in this category is using in this way, used consistently and confidently enough to become recognizable as Ayre Scanner's own.**

Rather than defaulting to the three families every trading/finance app reaches for (institutional blue, mint/emerald "money green," or trust-signaling violet), the new brand hue is **Citrine** — a warm, mineral, gold-edged yellow-green, closer to a cut gemstone or aged brass-under-glass than to a highlighter or a neon accent. It takes its starting cue from the acid-green energy seen across the green/black references reviewed (a hue family that reads current and confident rather than institutional-boring), but is deliberately **detuned toward something warmer, denser, and more mineral** — less "app accent color," more "the one color this brand owns" — specifically so it reads as premium and intentional rather than as a copy of any one reference or as "the usual fintech green."

**The brand-color / gain-color collision problem, solved explicitly.** Because Citrine sits in the green family and this is a market app where green also means "price went up," the two are given clearly separate identities rather than sharing one hue at different opacities (a mistake worth naming and avoiding directly):
- **Citrine** (brand) is warm, yellow-leaning, slightly muted/mineral — it never appears attached to a numeric gain/loss figure, and never carries a `+`/`−` sign or directional glyph. Its job is exclusively identity: the nav's focal control, primary buttons, the hero card's signature edge/accent, selected states, links.
- **Jade** (gain) is cooler and blue-leaning within the green family, fully saturated where Citrine is muted, and *only* ever appears paired with a `+` sign and an up-glyph on a numeric market value.
- Side by side the two are clearly distinguishable (warm/muted vs. cool/saturated), and because their *roles never overlap* — one is never used for the other's job — there is no scenario in the app where a user has to guess whether a green element means "this is Ayre Scanner's brand" or "this security is up."

### 2.2 Palette roles

| Role | Name | Direction | Where it appears |
|---|---|---|---|
| Base (light) | Fogpaper | A cool, slightly warm-neutral-free off-white with a faint graphite undertone — not cream, not stark white | `background` |
| Base (dark) | Cinder | A true near-black, warm-brown-free graphite | `background` |
| Brand accent | **Citrine** | Warm, mineral, gold-edged yellow-green; muted relative to a highlighter, saturated enough to be unmistakable | Nav focal control, primary buttons, selected states, links, the hero card's signature accent edge, the brand mark |
| Brand accent (held back) | Citrine Muted | Citrine desaturated/darkened for large low-emphasis fills | Selected-but-quiet backgrounds, large fills where full Citrine would overpower |
| Gain | **Jade** | Cool, blue-leaning, fully saturated green — visually distinct from Citrine at a glance | Always paired with `+` and an up-glyph; never used for brand/UI chrome |
| Loss | **Garnet** | Deep, ink-toned red with a slight wine undertone rather than a flat alert-red | Always paired with `−` and a down-glyph |
| Attention / live / stale | **Ember** | A warm copper-amber, distinct from both Citrine and Garnet | "LIVE" dot, delayed-data banners, stale-data chips, at most one or two instances per screen |
| Informational secondary | **Slate Violet** | A single, narrowly-used cool violet-grey — not a brand color, used only for informational badges/secondary chips where neither gain/loss nor brand meaning applies (e.g., a "NEW" tag, a category label in Learn) | Small-area use only; never a large fill, never the nav, never a button |
| Text | Ink scale | Cool graphite-black through muted grey, warm-neutral-free in both themes | `textPrimary/Secondary/Tertiary/Disabled` — all clear 4.5:1 against their surface |
| Structure | Hairline / border / borderSubtle | Cool neutral, 1px hairline standard | Card edges, dividers, nav top edge |
| Data backgrounds | `positiveBg` / `negativeBg` | Faint Jade/Garnet tint fields | Movers-list rows, badge fills |
| Charts | `chartGrid` / `chartLine` | Near-invisible neutral grid; trace line in ink (neutral instruments) or Citrine (only where a line is explicitly a "this is the brand's featured metric" moment, e.g. a single hero sparkline) | See §8 |

**Ember and Slate Violet exist specifically because the research references showed that a disciplined base can support one saturated signature hue plus a small number of clearly-secondary accents without reading as chaotic — provided those secondary hues are used narrowly and never compete with the brand hue for the "identity" job.** Neither is ever used as a button fill, a nav element, or anywhere that could be mistaken for the brand accent.

### 2.3 Dark theme (Cinder)

- `background`: true near-black graphite — the "trading floor at night" base, cooler and darker than the previous theme's dark brown.
- `surface`/`surfaceAlt`/`surfaceRaised`: a tight ascending scale of dark cool greys, kept close together for a calm, low-glare reading.
- Citrine brightens slightly for dark-surface legibility but keeps its warm/mineral character — it must never shift toward a flat neon lime; the goal is "a citrine gem under gallery light," not "a highlighter under blacklight."
- Jade and Garnet both lift slightly for contrast while staying ink-toned rather than neon — this should never read like a casino or a crypto-speculation app.
- The hero card's dark "readout" panel becomes a slightly *raised, cooler* panel against the already-dark card body, keeping the "terminal-inside-a-card" idea legible in both themes.

### 2.4 Light theme (Fogpaper)

- `background`: cool Fogpaper white, distinctly not cream and not stark/clinical white.
- Citrine holds its full mineral saturation against Fogpaper — it should be the single most saturated thing on the screen in light mode, by design.
- The hero card's dark readout panel becomes the one deliberately near-black surface in light mode, exactly as in the prior draft — this "dark panel inside a light card" idea is kept because it is a genuinely useful terminal-inside-a-card device, independent of which hues fill it.

### 2.5 What must never reappear, and what must never happen

- Cream or warm-undertone backgrounds; brown surfaces of any kind; brass/gold/bronze as a literal metallic hue; any gradient or glow fill; any translucent/frosted material; drop shadows as an elevation device.
- **A default, unconsidered fintech blue, mint, or violet used as the primary brand hue** — if at any point in implementation the "easy" choice of a generic institutional blue creeps back in as the actual primary color (rather than Citrine), that is a regression against this brief, not a simplification of it.
- Citrine and Jade must never be allowed to visually drift toward each other through careless tinting/shading in implementation — they are two intentionally distinct greens with two distinct jobs, and any component that makes them hard to tell apart at a glance has failed this spec.

---

## 3. Typography system

A three-role system, structurally similar in spirit to "one display face, one data face, one UI face" but with entirely new faces/personality and new rules for where each applies — nothing about the previous serif/brass pairing carries over.

1. **Display / heading face** — a confident, slightly condensed grotesque-sans (not a serif this time — the previous identity was serif-led; this identity is terminal/sans-led to feel current and precise rather than editorial). Used only for: screen titles ("Home" logic — i.e. the "Hi, [Name]" line and page titles), the index name headers on Index Detail, and Learn's course titles. Not used for body copy or data.
2. **Ticker / data face** — a monospaced, tabular-figure face, used for **every single numeric market value in the app without exception**: index levels, price, change, %, volume, P/E, portfolio-style figures, version numbers in Settings, timestamps. This is the non-negotiable rule carried forward as a *principle* (numbers must be monospaced and tabular so columns of figures align and don't jitter on update) — the specific face itself is new and distinct from the prior instrument-readout face.
3. **UI / body face** — a clean, highly legible grotesque-sans for body copy, descriptions, settings rows, button labels, navigation labels. Distinct from the display face (different weight/width personality) so the two sans faces don't blur together — the display face should be identifiable at a glance as "headline," the UI face as "content."

**Hierarchy rules:**
- Index/price values on Home and Index Detail are the largest data-face text in the app — larger than any heading.
- Percentage change is always set smaller than the absolute value it modifies, but always colored (Jade/Garnet) and always signed.
- Labels above data values (e.g. "NIFTY 50," "Vol") are small, uppercase or small-caps, wide letter-spacing, tertiary text color — a clear "terminal label" convention applied consistently everywhere data appears.

---

## 4. Iconography system (redesigned in full, everywhere — including the nav bar)

Every icon in the app is being replaced, without exception. This includes the bottom navigation's icon set, every screen's header/action icons (bell, avatar/menu, back arrow, chevrons), every empty/error-state glyph, every settings-row leading icon, every category/status badge glyph, and every icon used inside cards (trend arrows, live dots, sort/filter controls). None of the current build's icon shapes should survive, even where the same concept (bell, home, chevron) still applies.

### 4.1 Icon direction

- **One custom, single-weight line-icon set**, drawn specifically for this identity rather than pulled unmodified from a generic default icon library — a small, disciplined vocabulary is part of what makes a product feel designed rather than assembled from defaults. If a stock icon library is used as a technical starting point, every icon actually shipped must be adjusted to a consistent stroke weight, corner rounding, and optical size so the set reads as one family rather than as mixed-provenance defaults, which is one of the most common tells of an AI-generated or templated app.
- **Stroke-based, not filled**, at rest — flat line icons at a single consistent stroke weight across the entire app, matching the flat/matte, no-gradient, no-glow surface language established in §2. A small number of icons switch to a filled/solid version specifically to indicate an *active/selected* state (most visibly in navigation, §5) — filled-on-select, line-at-rest is the one state-change rule used consistently everywhere an icon has a selected/unselected condition.
- **Geometric and precise**, built on a consistent grid (e.g., a 24pt keyline grid, matched to whatever base grid the rest of the type/spacing system uses) so icons of different concepts still feel like they were cut from the same die — sharp, terminal-appropriate corner rounding rather than the soft, rounded-blob icon style common to consumer wallet apps.
- **No duotone, no gradient fills, no illustrative/mascot-style icons anywhere** — this includes replacing any current open-book, cloud, or scanner/target illustration-style glyph with a plain, flat, geometric line equivalent.
- **Color usage**: icons are ink-toned (`textPrimary`/`textSecondary`/`textTertiary`) by default; Citrine is reserved for the same narrow "identity/active" role described in §2 — an icon should not turn Citrine just for decoration, only when it is genuinely marking the active/selected/brand-carrying element (the collapsed nav control, a selected settings option, a primary button's icon). Jade/Garnet are reserved exclusively for directional/market glyphs (up/down arrows on price changes) and are never used for a generic UI icon.

### 4.2 Where icons must be rebuilt (non-exhaustive checklist)

- **Bottom navigation icon set** — all five destination glyphs (Home, Signals, Insights, Learn, Profile) redrawn from zero in the new line-icon language, with a filled variant for the active/collapsed-control state described in §5.
- **Header controls** — notification bell, avatar/menu affordance, back arrows, search/sort/filter glyphs.
- **Empty and failure-state glyphs** — the shared empty-state template's icon (§8) and the distinct "disconnected" failure glyph (§9.2), both newly drawn, with no reuse of the current gauge/cloud/scanner/book motifs.
- **Settings row leading icons** — alerts, appearance, account, about, and every toggle row's leading glyph.
- **Market/data glyphs** — up/down directional arrows on price changes, the "LIVE" status dot, sort/filter icons on Index Detail's constituent list, the signal-strength tick indicator on Signals (§6.2).
- **Learn iconography** — course/lesson/progress glyphs, replacing the current open-book motif entirely.

### 4.3 Verification note

As with color (§9.4), the new icon set should be checked as a *set*, not icon-by-icon — lay every icon used in the app out together at final size before sign-off, and confirm consistent stroke weight, consistent corner treatment, and consistent optical sizing. An icon set that is individually well-drawn but inconsistent as a family will still read as templated.

---

## 5. Navigation — "the Fold": an expanding/contracting floating dock

Explicitly **not a static pill** (the prior identity's floating pill, in either its original or brass-rebuilt form, is retired in silhouette, material, and behavior). The concept below is inspired by one specific structural idea from the reference material — a floating nav that pairs a compact bar with a small, visually distinct, off-axis circular control — but the mechanic, shape, and material are rebuilt from zero rather than restyled. Where the reference's circular control is a static decorative/action element, here it becomes **the trigger for the nav's own expand/contract behavior**, which is the genuinely new idea and the one the brief specifically asked to be explored.

**Two states, one control:**

- **Collapsed (default) state.** Most of the time, the nav is a small, compact floating capsule — deliberately smaller and quieter than a full five-item bar — showing only the **current section's icon** inside a solid Citrine-filled circular control, slightly raised/detached above a short hairline tray. This is the resting state for maybe 90% of a session: unobtrusive, identity-carrying (it's the one place Citrine sits permanently on screen), and clearly tappable.
- **Expanded state.** Tapping the collapsed control **unfolds it horizontally** into the full five-destination dock — Home, Signals, Insights, Learn, Profile — each shown with icon and label, laid out on a solid `surfaceRaised` tray with a single hairline top edge. The item that was already active stays visually anchored to where the collapsed control was, so the unfold reads as "the one control became five," not as a new element appearing from nowhere.
- **Returning to collapsed.** Selecting a destination (including re-selecting the current one) folds the dock back down to the compact single-icon control, now showing the newly active section's icon. The dock can also fold back on its own after a short idle period or on scroll, so it stays out of the way of content by default and is only ever "big" when the person is actually navigating.

**Why this satisfies the brief without copying the reference:** the reference's floating nav is a static bar with a fixed, always-present circular action button. This concept has **no static five-item bar at all in its default state** — the entire resting nav *is* the small circular control, and the full bar only exists transiently, summoned on demand. That is a materially different interaction model (state-changing, single-control-led) built around a structural cue (bar + distinct off-axis circle) taken only as a starting idea, not a shape to reskin.

**Material and detail:**
- Both states are fully flat/matte — solid `surfaceRaised` tray, solid Citrine control, no translucency, no blur, no glow.
- The collapsed control is the one place in the whole app where Citrine appears as a large solid fill by default and permanently — reinforcing it as the app's signature mark, visible on every screen even before the person interacts with navigation at all.
- Inactive items in the expanded state use muted ink icon+label, no individual pill/background fills — contrast still comes from the one Citrine-filled active/trigger element, now sitting inline within the expanded row rather than detached above it.
- The unfold/fold shape change itself (compact circle → full labeled bar, and back) is the specified behavior; its exact choreography (timing, easing, sequencing) is specified in §12.

---

## 6. Screen-by-screen redesign

### 6.1 Home — "the market gateway"

- Header: **"Hi, [Account Name]"** pulled live from the user's profile/account data (replacing the current "Scanner plan" title entirely) — small `textSecondary` greeting line, then the name set in the display face. Notification bell and avatar/menu control retained functionally, restyled to the new flat/hairline icon system (no circular soft-fill backgrounds carried over).
- **Primary hero: a three-instrument index board**, not a single momentum score card. NIFTY 50, SENSEX, and BANK NIFTY are rendered as three stacked or carousel-swipeable **instrument cards**, each a physical-card-like block (flat fill, hard corner radius, an embedded dark `inkPanel` readout strip) containing:
  - Index name (display face, small)
  - Current level (data face, large, tabular)
  - Change value + % (data face, colored, signed)
  - A compact **live ticker trace** — a thin real-time line/sparkline rendered in the ticker style described in §8, not a filled area chart
  - A small **Ember** "LIVE" dot + timestamp label communicating freshness explicitly, replacing the old "LIVE MARKET" pill motif with a smaller, terminal-style status glyph
  - The entire card is tappable → **Index Detail** (§7.1)
- Below the index board: retained "scanner/checkpoint" summary content, restyled into the new flat card system — no longer visually anchored around a circular momentum ring/gauge (that motif belonged to the previous instrument identity and is retired); replaced with a simple horizontal readout row (e.g., breadth counts, session status) styled consistently with the ticker system.
- **Top Gainers / Top Losers are removed from Home entirely** and relocated to Insights (§6.3). Home's job is now exclusively: greet, show the three live indices, show one high-level scanner summary, and route onward.
- Failure state for the index board (feed unavailable): see §8.

### 6.2 Signals — "the signal board"

- Header restyled to the new flat system: small uppercase "LIVE SCANNER" label (ticker-label style, not a pill/badge), "Signal board" as the display-face title, supporting description in body face.
- Each signal renders as a **row-card**, not a soft brass card: equity/instrument name and a compact rationale line in body face; entry/level figures in the data face; a **signal-strength indicator** rendered as a small set of filled/unfilled terminal-style ticks (echoing "signal bars," not a circular gauge) rather than any dial motif; a direction glyph + Jade/Garnet coloring for the setup's bias.
- Populated list uses tight terminal-row spacing (dense, scannable) rather than the previous generous card spacing — this is a data-desk screen, not an editorial one.
- Empty state ("No fresh setups") redesigned per §9's shared empty-state template — no scanner/target icon carried over; new iconography built from the same flat line-icon set used app-wide.

### 6.3 Insights — "the market intelligence desk" (replaces Climate)

- Tab label and route renamed **Insights** everywhere (nav, header, internal routing) — "Climate" is fully retired as a name and as a concept-icon (cloud/slash motif retired).
- Header: title "Insights," subtitle repositioned to describe the whole desk ("Breadth, sentiment, and the day's movers, in one feed") rather than only sentiment.
- **Section 1 — Market sentiment/breadth**: the sentiment reading is kept functionally (a breadth/sentiment score) but rendered as a **compact horizontal meter/bar readout** in the ticker style — a filled bar against a labeled scale with a numeric readout in the data face — rather than a circular dial or any gauge/needle motif (that belonged to the prior identity). Weekly/Monthly window toggle retained as a small segmented control in the new component style (§8).
- **Section 2 — Top Gainers**, **Section 3 — Top Losers**, **Section 4 — Most Active** (all newly relocated here from Home): each rendered as a horizontally scrollable or vertically stacked **ranked ticker list** — rank number, ticker/name, last price, %, in tight monospaced rows, each row tappable → **Equity Detail** (§7.2). These three lists are visually unified with the sentiment section as one continuous "desk feed" (consistent row height, consistent hairline dividers, consistent label typography) rather than three independently-styled cards bolted together — this fulfills the brief's requirement that Insights feel like an integrated market-intelligence experience, not a relocation of old cards.
- Failure/empty states per section per §9 (sentiment can fail independently of movers data; each must degrade independently, not take the whole screen down).

### 6.4 Learn

- Header retains "TRADING LIBRARY" concept as a small ticker-style label, "My courses" as display-face title, subject/lesson counters rendered in the data face (still numeric, still deserves tabular figures) rather than the old counter-pill style.
- Course rows: flat list rows with a small progress readout (e.g., a thin horizontal progress bar in Citrine, plus "3/12 lessons" in data face) — no open-book icon/illustration carried over; new iconography from the shared flat icon set.
- Empty state ("No lessons yet") uses the shared template (§9) — same visual family as every other empty state in the app, reinforcing one system rather than a bespoke look per screen.

### 6.5 Profile

- Full re-layout, not a recolor: account identity block (avatar/initials + name + a small account-status line) as a flat header block, not a bordered card; "Edit profile" and "Settings" as two flat list rows with leading icon, label, and a trailing chevron — visually consistent with Learn/Insights row conventions rather than a distinct "card" treatment.
- "Sign out" kept as a clearly separated, danger-colored (rust/`negative`) action at the bottom, in its own lightly separated section — destructive-action isolation is good practice and is kept, restyled flat.

### 6.6 Settings

- Same information architecture (Alerts / Appearance / Account / About), fully restyled: section headers as small ticker-style labels; toggle rows restyled with a new flat switch component (see §8) replacing the current green pill-toggle look — the "on" state uses Citrine, deliberately not Jade, so a toggle switching "on" is never visually confusable with a security going up.
- Appearance section keeps System/Light/Dark selection, restyled as a compact three-way segmented control (shared component, also used for Insights' Weekly/Monthly toggle) rather than a stacked radio list, if space allows — otherwise a restyled stacked list consistent with the rest of Settings' row system.
- Version/About rows: plain flat rows, version number rendered in the data face (numbers stay tabular even here, for system consistency).

---

## 7. New flows: Index Detail and Equity Detail

These are new screens required by the brief and do not exist in the current build.

### 7.1 Index Detail (NIFTY 50 / SENSEX / BANK NIFTY)

- Reached by tapping any Home index card.
- Header: index name (display face), current level + change (data face, large — same visual weight as the Home hero, so the transition feels continuous), a fuller ticker trace (larger version of the Home sparkline) as the hero visual for this screen.
- Below: a **constituent list** — every company in that index, each row showing name, last price, and % change in the standard ticker-row format used across Insights' movers lists (shared component, not a new one-off design).
- Each constituent row is tappable → **Equity Detail**.
- Sort/filter affordance (e.g., by % change, by name) as a small flat control at the top of the constituent list — optional but recommended given the brief's emphasis on this being a genuine gateway into live market data, not a static list.
- Failure/loading/empty states per §9 (index metadata can succeed while constituents fail, and vice versa — design for that independently).

### 7.2 Equity Detail

- Reached from: Index Detail constituent rows, and every row in Insights' Gainers/Losers/Most Active lists.
- Header: company name + ticker symbol, current price + change (data face, hero-weight), a ticker trace for the equity.
- Key stats block: a small grid of labeled data-face figures (e.g., day range, volume, prior close) — using the same "label above value, tabular figures" convention as everywhere else in the app.
- If the equity belongs to a signal in Signals, surface a small linked reference back to that signal (optional enhancement, not required, but keeps the "gateway" feeling coherent).
- Failure/loading/empty states per §8.

---

## 8. Shared component library (redesigned from zero)

Every component below must be rebuilt — none inherit the previous identity's shapes/materials with only new colors applied.

- **Cards**: flat fill, hard-ish corner radius (smaller/crisper than the previous identity's soft rounded cards — reinforcing the "terminal card," not "soft app card," feeling), 1px hairline border, no shadow.
- **Buttons**: solid Citrine-fill primary buttons with dark/ink text for contrast (Citrine is light enough that inverted-white text would under-perform — verify this at implementation time, see §9.4); outline buttons using a hairline/ink border with ink text; both flat, no gradient, no pill-shaped default (rounded-rect, not full-capsule, in keeping with the dock's more rectangular language).
- **Toggles/switches**: a new flat switch design, Citrine for "on" (never Jade — Jade is reserved for gain/positive market semantics only, so it is never reused for a UI toggle, exactly as described in §2.1).
- **Segmented control**: new compact three/two-way control used for theme selection and time-window toggles — one shared component, not bespoke per screen.
- **Badges/status chips**: small, flat, label-in-caps chips for states like "LIVE," "DELAYED," "CLOSED" — using Ember for delayed/attention, Citrine or neutral ink for live/informational, Slate Violet only for non-market informational tags (e.g. "NEW"), never brass/gold.
- **Ticker rows**: the single shared row component used across Signals, Insights' movers lists, Index Detail's constituents, and Equity Detail's related lists — name/label left, tabular figures right, hairline divider between rows. Building this once as a shared component (rather than per-screen bespoke rows) is what makes Insights read as "one integrated desk" rather than "three relocated cards."
- **Charts/sparklines**: hairline trace only — no filled/gradient area fills anywhere in the app (this principle is kept from the prior identity, restated here because it must survive the total palette change). Grid lines, if present, are extremely faint and never compete with the data line.
- **Empty state template**: one shared layout — a small flat line-icon (new icon set, no motif reused from before), a short bold headline naming what's missing, one line of plain-language explanation, and a "Pull to refresh" or explicit retry action. Used identically in structure across Home's index board, Signals, Insights (per-section), and Learn — only the icon and copy change per context.
- **Loading state**: skeleton blocks matching the exact shape of the real content (index cards, ticker rows, etc.) in a subtly pulsing neutral tone — not spinners as the primary loading affordance for list/card content (a small inline spinner is acceptable only for button-level or short async actions).

---

## 9. Error, empty, offline, and stale-data states

The brief requires this to be treated as a first-class part of the redesign, not an afterthought. All states below share the empty-state template from §8 but are triggered and worded distinctly.

### 9.1 Failure taxonomy and required copy pattern

Every failure state must answer three things in plain language: **what failed**, **whether the user needs to do anything**, and **what they can do next**. No raw exceptions, status codes, or generic "Something went wrong" text anywhere in the shipped UI.

| Condition | Where it can occur | Example user-facing framing |
|---|---|---|
| API/network failure fetching index data | Home hero, Index Detail header | "Index feed unavailable right now — pull down to try again." |
| API/network failure fetching constituents | Index Detail list | "Couldn't load the constituent list. Retry below." |
| API/network failure fetching a specific equity | Equity Detail | "This company's data didn't come through — try again." |
| Signals load failure | Signals | "The scanner couldn't refresh. Pull down to sweep again." |
| Sentiment/breadth load failure | Insights §1 | "Sentiment reading unavailable — pull down to retry." |
| Gainers/Losers/Most Active load failure (independent per list) | Insights §2–4 | Each list fails and retries independently, e.g. "Top Gainers didn't load — retry." |
| Empty results (e.g., no constituents returned, no signals currently) | Any list-driven screen | Distinct from failure — "No fresh setups right now" vs. "Couldn't load setups" must read differently and use different iconography emphasis (empty = calm/neutral icon; failure = a small "disconnected" glyph). |
| Course/lesson load failure | Learn | "Your library didn't load — pull down to check again." |
| Network disconnected entirely | App-wide banner | A slim, dismissable top banner: "You're offline — showing the last saved data," rather than blocking every screen. |
| Request timeout | Any live-data fetch | Treated identically to a generic network failure from the user's perspective, with the same retry affordance — no technical distinction shown in copy. |
| Stale/delayed market data | Home hero, Index Detail, Equity Detail | A small Ember "DELAYED" chip next to the timestamp, plus a one-line note ("Data may be delayed during high volume") — this is a *degraded-but-shown* state, not a blocking error. |
| Authentication/session failure | App-wide (any authenticated call) | Route to a clear, non-alarming re-authentication prompt: "Your session's expired — sign in again to continue," not a raw 401 or crash. |

### 9.2 Visual language for failure states

- A distinct **"disconnected" icon variant** (e.g., a broken/interrupted line-glyph) distinguishes true failures from empty-but-successful states, which use a calmer/neutral glyph from the same icon family — this distinction did not exist clearly in the prior identity's shared error/empty template and should be made explicit here.
- Failure states never use Garnet (loss-red) as their dominant color — that hue is reserved for market-direction semantics. Failure/empty states use neutral ink tones, with Ember reserved for the "attention but not broken" tier (stale data, delayed feed) and a distinct muted ink/status tone for outright failures — keeping color meaning consistent app-wide (red always means "the market went down," never "the app broke").
- Retry actions are a single, clearly tappable line or button ("Pull down to try again" as inline text where pull-to-refresh is the mechanism; an explicit "Retry" button where the failure occurred inside a pushed detail screen without a natural pull-to-refresh gesture, e.g. Equity Detail).

### 9.3 Testing and simulation requirements

For every major data-driven feature, the implementation must support **intentionally forcing** each of the following, so the correct UI can be verified without waiting for a real backend failure:

- Forced API failure (simulate a non-2xx/error response)
- Forced empty response (valid response, zero items)
- Forced malformed response (valid HTTP response, unexpected/missing fields)
- Forced network failure (no connectivity)
- Forced timeout (artificially delayed/never-resolving response)
- Forced stale-data flag (simulate a timestamp older than the freshness threshold)
- Forced authentication/session failure (simulate an expired/invalid session on an authenticated call)

**Coverage required across:** Home market data (index board), NIFTY 50/SENSEX/BANK NIFTY index detail, index constituents, equity detail, Signals, Insights sentiment, Insights Gainers, Insights Losers, Insights Most Active, Learn course/lesson loading, Profile/Settings account data, authentication/session behavior, and live-data update/refresh behavior generally.

Recommended mechanism: a debug-only "state simulation" hook in the existing service layer (`ApiService`, `MarketMoversService`) that can be toggled per-endpoint to return one of the seven conditions above instead of a real call, so QA can walk every screen through every state deterministically. This does not require shipping any test UI to end users — it is a development/QA-time capability only.

### 9.4 Mandatory pre-ship verification pass

Error/empty/loading design is not considered finished when it looks correct in one screenshot — it must be **actively checked**, not assumed, before being signed off as final. Before any failure-state (or general visual) work from this document is treated as done, verify:

- Every condition in the §9.1 taxonomy has been triggered (via the §9.3 simulation hooks) and visually inspected — not just designed on paper — for every listed screen/section, in **both** Light and Dark theme.
- Every state has been checked with **realistic content lengths**, not just short placeholder text — long company names, large numeric values, long error copy — to confirm nothing truncates awkwardly or breaks layout.
- No two distinct conditions (e.g., "empty" vs. "failed," "stale" vs. "offline") have been left visually identical or easily confusable — each must be distinguishable at a glance, per §9.2.
- Contrast ratios are re-checked against the **actual final palette values** (not the directional descriptions in §2) in both themes, since real hex values inevitably drift slightly from a written brief during implementation.
- Citrine, Jade, and Garnet are re-checked side by side in context (not in isolation) to confirm the brand/gain/loss separation described in §2.1 still reads clearly once real UI is in front of a viewer, on both a small and a large device size.
- The new navigation's collapsed and expanded states have both been checked on the smallest supported screen width to confirm five labeled destinations fit legibly when expanded.

This pass should be treated as a required gate before calling any screen "done," not an optional nice-to-have — the brief's emphasis on properly designed, testable failure states is only met if the states are actually verified against real conditions, in real theme/content/size combinations, rather than only against the written spec.

---

## 10. Accessibility and consistency checkpoints

- All text-color/background pairings re-verified at 4.5:1 minimum under the new palette in both themes (this must be re-run from zero — the previous redesign's contrast fixes were specific to brass/parchment values that no longer exist, and this redesign's own values must be checked fresh per §9.4, not assumed from the directional descriptions in §2).
- Color is never the sole signal for gain/loss, live/delayed, or success/failure — every such state pairs color with a sign, glyph, or explicit label, consistent with the principle already established in the current codebase and explicitly re-affirmed here for the new palette.
- Citrine (brand) and Jade (gain) are treated as a specific, named accessibility/clarity risk (§2.1) precisely because they share a hue family — this pairing gets its own explicit check in §9.4 rather than being folded into generic contrast testing.
- One shared icon set across the entire app — no per-screen bespoke iconography (this was a discipline the prior identity followed and must be followed again from scratch with all-new glyphs, since none of the old icon shapes should read as recognizable holdovers).
- Tabular/monospaced numerals used without exception anywhere a figure can change live, so nothing visually jitters or reflows on update.

---

## 11. Animation & motion system

Motion was previously scoped out of this document ("handled separately"). Per the latest update, it is now part of this spec. The direction below extends the current codebase's existing motion discipline — critically-damped springs, no bounce/overshoot, restrained single-play entrances, selective haptics — rather than replacing it, because that discipline is sound engineering; what's new is applying it deliberately to every new surface introduced in this redesign, and being explicit about exactly where and how motion should be used rather than leaving it implicit.

### 11.1 Principles

- **No bounce, no overshoot, ever.** This rule carries forward unchanged from the current build and applies to every new animated element introduced here (the Fold, the ticker traces, the digit-roll on live numbers). A terminal-inspired product should feel precise and mechanical, not playful or elastic.
- **Motion should explain state, not decorate it.** Every animation in this system exists to answer "what just changed and why," not to add visual flourish. If an animation can be removed without the user losing information about what happened, it's a candidate for a shorter/quieter treatment.
- **Physically-based, not linear.** Prefer critically-damped springs and eased curves consistent with the current `AppMotion`-style approach over simple linear tweens, so movement feels weighted and intentional.
- **One consistent "live data" signature.** Exactly one visual treatment communicates "this number just updated from a live feed" everywhere it happens (Home, Index Detail, Equity Detail, Insights' movers lists) — not a different flourish per screen.
- **Respect reduced-motion settings.** Every animation described below needs a reduced/no-motion fallback (an instant or near-instant cross-fade) for accessibility, consistent with platform-level reduce-motion settings.

### 11.2 Specific animated moments to design

| Moment | Where | Direction |
|---|---|---|
| Nav fold/unfold | The Fold (§5) | The compact circular control's shape-morph into the full labeled bar, and back — a single continuous shape transition, not a fade-out/fade-in of two separate elements. This is the signature interaction of the whole redesign and deserves the most deliberate motion design in the app. |
| Digit-roll on live values | Home hero, Index Detail, Equity Detail, Insights movers | When a tracked numeric value changes, only the digits that actually changed roll/transition to their new value — carried forward as a principle from the current build's numeral-handling approach, now applied consistently across every new live-data surface introduced here. |
| Ticker trace draw-in | Home hero cards, Index Detail, Equity Detail | The hairline sparkline trace draws on from left to right on first load, rather than appearing instantly fully formed — communicates "this is live, not static," reinforcing the brief's requirement that live data feel obviously live. |
| Live/on-air pulse | The Ember "LIVE" dot | One reusable, subtle pulse signature (not a hard blink) — same treatment everywhere a "live" status is shown. |
| Card/list entrance | Home index board, Signals list, Insights' feed, Learn's course list | A restrained, single-play, index-delayed staggered entrance (carried forward from the current build's `AnimatedEntrance` pattern) — plays once per screen visit, does not replay on tab re-visit or minor re-render. |
| Pull-to-refresh | Every list/feed screen | One consistent refresh affordance and completion signature app-wide — never two competing refresh indicators on the same screen (a problem explicitly fixed in the current build and one this redesign must not reintroduce). |
| Skeleton loading | Any list/card while data loads | A subtle, slow pulse on skeleton blocks shaped like the real content — calm, not attention-grabbing. |
| Toggle/switch | Settings | A short, crisp slide with no overshoot when switching state. |
| Button/row press feedback | App-wide | Kept exactly as the current build's `PressableScale` (0.97 scale, no overshoot) — extended to every tappable surface introduced by this redesign (index cards, ticker rows, the Fold's expanded items) that doesn't already have it. |
| Screen transitions | Home → Index Detail → Equity Detail, and other pushed routes | A consistent, direction-aware push/pop transition — the detail screen's hero value should feel like it continues from the card that was tapped, reinforcing the "gateway" structure described in §6 and §7, rather than an unrelated screen simply appearing. |
| Error/empty state entry | Any failure/empty state (§9) | Deliberately calm and static, consistent with the current build's existing restraint around error states — a failed fetch is low-stakes and should never be animated in a way that reads as alarming. |

### 11.3 What this section is not

This section specifies **what should animate and why**, and the general character (springy-but-controlled, no bounce) the motion should have. It does not prescribe exact durations, easing-curve constants, or spring parameters — those are implementation-level decisions that should be tuned in-tool against real devices and, per §13, against dedicated motion-design research rather than guessed at in a text document.

---

## 12. Summary of what changes vs. what is structurally retained

**Fully replaced (visual):** color palette (base hue family, brand accent, all semantic colors) in both themes; typography faces and pairing logic; card material and corner language; the gauge/needle/dial motif (retired entirely, replaced by bar/meter readouts); the sparkline's specific rendering style (kept as hairline-only in principle, restyled in exact treatment); the floating navigation's shape, material, **and behavior** (a static pill/dock replaced by an expand/contract single-control mechanic); all iconography; all empty/error/loading visual dressing; the Climate tab's identity (renamed and reconceived as Insights).

**Structurally retained (architecture/behavior, not appearance):** token-extension pattern as the styling mechanism; 8pt spacing grid as a system (values may change, the systematic approach doesn't); tab-based navigation with state preservation (now expressed through the Fold's collapsed/expanded states rather than a static bar); press-feedback and haptic discipline; the "no bounce" motion rule; the existing screen/route inventory plus the two new required routes (Index Detail, Equity Detail); the principle of dedicated, independently-failing states per data section rather than one whole-screen failure flag; the requirement that every such state be actually verified, not just designed, before sign-off (§9.4).

**Net result:** a user familiar with the current cream/brown/brass build should recognize *what* the app does (market overview → indices → signals → market intelligence → education → account) while seeing an entirely different, distinctly branded product — cool ink-and-paper surfaces, one confident and ownable Citrine accent used nowhere else in this category in quite this way, a fully redrawn icon language, terminal-style tabular data throughout, a new expand/contract navigation mechanic with a considered motion system behind it, and a properly designed, independently-testable, and independently-verified failure-state system across every data-driven surface.

---

## 13. Recommended further research before final sign-off

This document sets direction, roles, and specific required behaviors, but it is not a substitute for hands-on platform and motion-design research at implementation time. Before finalizing exact values (spacing, icon grid, corner radii, contrast ratios, spring/easing constants) and before treating any screen as fully done, it's worth researching directly, online, rather than relying solely on this brief:

- **Apple's Human Interface Guidelines** (and, if an Android build is in scope, Google's Material Design guidelines) for current platform-native conventions on navigation patterns, icon grids and sizing, minimum touch targets, safe-area handling, dark-mode contrast recommendations, and accessibility/reduced-motion settings — to make sure the new Fold navigation, icon set, and type scale feel native and correct on-device, not just correct on paper.
- **Additional modern design-system references** beyond what was reviewed for this brief (e.g., established design systems from well-regarded fintech, trading, and data-dense products) for further inspiration on data-table density, chart legibility, and how other serious financial products balance "distinctive brand" against "instantly readable numbers" — the two priorities this whole redesign is built around.
- **Platform-specific motion/animation guidance** — Apple's guidance on motion and its recommended spring/curve behavior, and general native-mobile animation best practice — to properly tune the spring constants, timing, and easing curves for the moments specified in §11 (the nav fold/unfold in particular deserves real prototyping, not just a written description).
- **Current accessibility guidance on color and motion** (contrast ratios, reduced-motion handling, minimum tap-target sizing) to confirm the specifics in §2, §4, and §10–§11 are checked against up-to-date standards rather than only against the directional language in this document.

None of this changes the direction set in this document — it's the step that turns a well-reasoned brief into a set of exact, defensible, platform-correct values.
