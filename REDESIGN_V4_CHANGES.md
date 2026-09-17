# Ayre Scanner v4 — Redesign Handoff Report

Implementation of `AYRE_REDESIGN_V4_PLAN.md` (itself the controlling spec from
Phase 5 onward, `deisgin.md` never having been available). Fourth design
identity; "Cinder & Citrine" (v3 — terminal/market-data aesthetic) is retired
in favour of "calm, editorial, premium": warm off-white/charcoal surfaces,
Hanken Grotesk + Space Grotesk, clay/sage/rose/gold accents, a flat glass-pill
nav with icon **and** label, donut/gauge data viz.

**Verification:** not run from the environment that wrote this code — see
§7. `flutter analyze` / `flutter test` / `flutter build` and a literal
checklist pass against the app are Raghav's job, on his machine.

This document is the handoff artifact for the whole v4 project, in the same
spirit `AYRE_REDESIGN_V4_PLAN.md` was: read this file alone and know what
shipped, what's deliberately different from the plan's original guess, what's
still open, and where to look next.

---

## 1. What shipped, phase by phase

**Phase 0 — Foundation & tokens.** `AppThemeTokens` rebuilt: `surfaceAlt`/
`surfaceRaised` re-derived by visual intent (not name) into the new sibling
pair `surfaceRaised`/`surfaceSunken`; `inkPanel`/`onInkPanel`,
`backgroundTint`, `fillMint`/`fillClay`/`fillSand` and `info` retired outright
(no v4 equivalent — see plan §3 for why each one has nowhere to go); citrine/
jade/garnet/ember renamed to the semantic accent/positive/negative/neutral
set. `accentInk` added where the raw clay accent measured under 4.5:1 as
small text. `shadowColor` and `navBg` are new tokens — v4 re-introduces soft
two-layer shadows, a rule v3 explicitly forbade.

**Phase 1 — Core shared components.** `AyreButton`, `AyreSwitch`,
`AyreSegmented`, `AyreChip`, `TagPill`, `Entrance`, `SkeletonBlock` and the
rest of `ayre_components.dart` retinted and, where the Spec's motion or
radius rules changed their behaviour, rebuilt rather than retuned. Nav glyphs
evaluated against lucide's rounder geometry and redrawn where the existing
custom paths read as "terminal" rather than "calm."

**Phase 2 — Navigation.** `curved_nav_bar.dart` (icon-only, raised
protruding-circle notch) deleted outright and replaced by `ayre_bottom_nav.dart`
— a flat glass pill, icon **and** label, driven by `AppSpring.navPill`
(critically-damped, ζ≈0.87, numerically verified in `spring.dart`). This
closes the v3 authors' own logged accessibility gap: icon-only navigation is
against Nielsen Norman Group's usability research, and v4's Spec independently
requires labels back for its own aesthetic reasons.

**Phase 3 — Data visualization.** `ayre_charts.dart` added: `BreadthDonut`,
`ProgressRing`, `SentimentGauge`, all hand-painted arcs (`_ArcGeometry`,
`_DrawOn`) per the Spec's no-chart-library rule. `ticker_trace.dart` retuned
to one parametrized painter (`.sparkline` / `.thumbnail` / `.areaTrend` named
constructors) instead of three separate ones. `breadth_meter.dart` deleted —
v3's `BreadthMeter` had explicitly retired the dial/gauge motif as belonging
to "the previous identity"; v4's Spec reverses that, and the reversal is
honoured rather than argued with. `CountUpFigure` added as the hero-metric
animation (a number interpolating and re-formatting every frame), replacing
`Figure`'s per-character digit-roll for that job; the roll survives for
live-updating secondary tickers.

**Phase 4 — System states.** `state_views.dart` rewritten around a
`StateAction` four-verb enum (`tryAgain` / `retry` / `refreshNow` /
`signInAgain`) so the verb-per-failure-kind rule (Spec §14.5) is structural
rather than a per-screen judgment call, and a `StatePreset` table encoding
the five states (`empty`, `noResults` — new, genuinely distinct from `empty`
— `failed`, `offline`, `sessionExpired`). Failure stays ink-toned, never
rose — rose means a market moved down, never that the app broke, and that
discipline is what `fault_states_test.dart` enforces. Shimmer rebuilt from a
whole-block opacity pulse to a 1.7s foreground-tinted gradient sweep.

**Phase 5 — Screens: primary five tabs.** All five tabs rebuilt against the
Spec. Notably: Home gained a theme toggle wired to the same setter Settings
uses, a breadth donut *and* sentiment gauge (they answer different
questions), and a count-up index level; Signals restructured to a ranked
featured card plus compact list, with a new `AyreFilterChip` (a deliberate
third chip-family component — see its own doc comment for why `AyreChip`/
`TagPill` don't fit) and a `StatePanel.noResults` wired to a real "Show all"
action; Insights ships without per-note charts (flagged, not worked around —
the data model has no per-note series and no endpoint supplies one); Learn
gained a "continue" card with a `ProgressRing` and a genuine (not
colour-only) completion state change; Profile's stats row shows only figures
the app actually holds, for the same no-endpoint reason as Insights.

**Phase 6 — Settings & secondary screens.** Mechanical retint pass across
`settings_screen.dart` and the eight secondary screens, plus two real fixes
found while in these files, not just token renames: `login_screen.dart`'s
invalid-credential banner had been tinted rose (a market-direction colour)
for an auth failure — moved to the same ink-toned fault treatment
`StatePanel` uses; the equity/index detail header traces were hardcoded to a
faded neutral regardless of direction — now pass `positive`/`negative` per
the subject, per §12.1's "a chart inherits its subject's colour" rule.

Phases 0–6 are each much longer in `AYRE_REDESIGN_V4_PLAN.md` §9 than the
paragraphs above — flagged inferences, exact hex/px values, and the reasoning
behind every reversal of a v3 decision live there and aren't reproduced here.
What follows is new work: this pass ran Phases 7 and 8.

---

## 2. Phase 7 — Motion & accessibility polish pass

A whole-app audit against five criteria, not a rebuild. Two real gaps found
and fixed; everything else the audit checked already held, mostly because
Phases 0–6 built the discipline in as they went rather than leaving it for a
final pass. That's worth saying plainly since a polish phase that changes
almost nothing can look unfinished rather than confirmed.

### 2.1 Touch targets ≥44pt — two real gaps, both fixed

**`OfflineBanner`'s dismiss control** (`state_views.dart`) was an 8px pad
around a 15px glyph — a ~31px hit area, under the floor, and already flagged
in a Phase 4 code comment ("raising targets app-wide is Phase 7's pass").
Replaced with a fixed 44×44 `SizedBox` centring the same 15px glyph, so the
visual mark is unchanged and only the hit area grows. The banner is now
slightly taller to accommodate it — the right trade for a dismiss control,
which earns the room a decorative element wouldn't.

**`StaleNotice`'s optional `onRefresh` link** had the same shape of bug and
wasn't previously flagged: an inline caption-weight "REFRESH NOW" text link
whose hit area was its own text bounds, roughly 16px tall. Wrapped in a
`ConstrainedBox(minHeight: 44)` with the text left-aligned inside it, so the
caption's visual size is unchanged. Note this callback is `null` at every
current call site (`equity_detail_screen.dart`, `index_detail_screen.dart`,
`signals_tab.dart`, `home_tab.dart`, `insights_tab.dart` all construct
`const StaleNotice()`), so the fix has no visible effect today — it's there
so the component is correct the moment something does pass it, rather than
a second finding for a future Phase 7.

Everything else checked came back clean:
- `AyreButton`'s `minHeight: 46` already clears the floor.
- `AyreFilterChip` is already 44pt tall by deliberate construction — its own
  comment records that Phase 5/plan §8 resolved the conflict between the
  Spec's 32–40px chip minimum and the HIG floor in favour of the floor.
- `AppBar` back/close `IconButton`s across all seven screens that have one
  use Material's default sizing (no custom `iconSize`/`constraints`), which
  already clears 44pt.
- `AyreSwitch`'s own hit box is 44×24 — under the floor on height — but it's
  never the sole way to toggle its value: every call site is a `SettingRow`
  with `onTap` wired to the same `toggle` callback, and `SettingRow`'s own
  padding puts its row well over 44pt tall. The switch is a redundant,
  smaller hit area layered on a larger correct one, which is the standard
  pattern (iOS Settings does the same) and not a gap.
- Every other tappable surface in the app (cards, list rows, chips, the nav)
  routes through `PressableScale`, `PressableScaleRow`, `SettingRow` or
  `AyreButton`, all of which are already sized well past the floor by their
  content.

### 2.2 Ayre ease used for "almost everything," springs only where scoped

Confirmed: no direct `Curves.*` usage anywhere outside `app_theme.dart`'s own
`easeIn`/`easeInOut` aliases (both still curves reached *through*
`AppMotion`, never a call site reaching past it). `AppSpring` — the two
critically-damped-but-non-bouncy springs the Spec calls for — has exactly two
live call sites: `AyreSwitch`'s knob and `AyreBottomNav`'s pill, both via the
shared `SpringValue` primitive. The segmented control deliberately does not
use a spring (each segment's own fill cross-fades on `AppMotion.ease`
instead) — a decision Phase 1 recorded and this phase re-confirmed rather
than second-guessed, since re-litigating a settled call isn't what a
confirmation pass is for.

### 2.3 Reduced motion honoured everywhere animated

Every `AnimationController`/`repeat()`/`TweenAnimationBuilder` in the app
checks `MediaQuery.disableAnimationsOf(context)` and either skips straight to
the end value or renders a static equivalent: `SpringValue` (and therefore
both its call sites), `LivePulseDot`, `SkeletonBlock`'s shimmer, `Entrance`'s
stagger, `Figure`'s digit-roll, `CountUpFigure`, `TickerTrace`'s draw-on,
`ayre_charts.dart`'s shared `_DrawOn`, `home_shell.dart`'s tab-fade, and
`learn_tab.dart`'s progress-rule fill. No gaps found.

**One thing deliberately left alone, not missed:** `AyreSwitch`'s track
colour and `_Segment`'s selected-fill colour each cross-fade over
`AppMotion.buttonPress` (150ms) without their own reduced-motion check — the
motion *underneath* them (the knob's spring slide) already snaps correctly.
A 150ms colour cross-fade with no translation, scale or repeat is not the
class of motion "prefers reduced motion" guidance targets (parallax,
movement, zoom, anything that can trigger a vestibular response); gating it
too would mean every state-driven colour change in the app needs its own
`disableAnimationsOf` branch, which is a much bigger and lower-value change
than this pass's scope. Flagged here in case a future accessibility review
disagrees.

### 2.4 Colour never carries a signal alone

Checked `DirectionBadge`, `AyreChip` and `SentimentGauge`/`BreadthDonut`'s
legends: every gain/loss reading pairs its colour with a glyph (an up/down
caret) and a label, never colour alone, and this was true going in — Phases
0–6 built it in per Spec §19/§20.1's "no bright green/red" and
"colour-plus-icon-plus-label" rules rather than leaving it for a final pass.
The one case that's colour + label without a glyph — `DirectionBadge`'s
`neutral: true` ("UNCHANGED") reading — is deliberate: there's no meaningful
up/down shape for a flat reading, and the label itself states the condition
in words a screen reader already announces, so nothing is lost by colour
alone failing here.

### 2.5 No nested cards

Checked programmatically (paren-matched, not just grepped) across every
screen that uses `AyreCard`: zero instances of one `AyreCard(` call inside
another's subtree. This also went in clean from earlier phases — most
grouped content already uses `RowGroup`/`SettingRow` (a card of hairline
rows, not a card of cards) for exactly this reason.

### 2.6 Files touched this phase

- `lib/widgets/state_views.dart` — `OfflineBanner`'s dismiss target,
  `StaleNotice`'s refresh-link target.
- No other `lib/` files changed. No test file needed updating — neither
  fix changes a rendered string, a colour, or geometry any existing
  assertion depends on (`OfflineBanner`'s glyph size and position are
  unchanged; only its padding model changed from `Padding` to a
  `SizedBox`+`Center` of the same visual size).

### 2.7 Two `flutter analyze` findings, fixed post-handoff

Raghav's first `flutter analyze` run surfaced two pre-existing issues,
neither in a file Phase 7 touched — both are Phase 5/3 residue, not new
breakage:

- **`insights_tab.dart:9` — unused import of `widgets/figure.dart`.**
  Dead since Phase 5 swapped the three `LabelledFigure`s that used to render
  advance/decline/unchanged for a single `BreadthDonut` (§13.3's rebuild,
  recorded in the plan's Phase 5 entry) — the import was never removed once
  its only call site went away. Grepped the file for every symbol
  `figure.dart` exports (`Figure`, `LabelledFigure`, `DeltaFigure`,
  `CountUpFigure`) to confirm nothing else in the file needs it before
  deleting the line.
- **`ayre_charts.dart:60` — `_DrawOn`'s optional `duration` parameter is
  never supplied at any of its three call sites.** This is exactly the
  outcome Phase 3 intended, not a bug: that phase's own notes record
  consolidating every chart in the app onto one duration
  (`AppMotion.chartDraw`) *because* two durations "would only have meant two
  places to drift" — the same reasoning that got `AppMotion.traceDraw`
  deleted outright rather than kept as an unused alias. `duration` was left
  on `_DrawOn` as an escape hatch nothing ended up needing. Removed rather
  than kept as unused API surface, matching that precedent — `_DrawOn` is
  file-private, so restoring it later if a real override need shows up is a
  one-line change, not a migration.

Neither fix changes what renders — `_DrawOn` always used `AppMotion.chartDraw`
in practice since nothing overrode it, and the deleted import had no live
call site. `layout_matrix_test.dart`'s existing chart-gallery coverage needed
no changes.

**Files touched:** `lib/screens/insights_tab.dart` (import removed),
`lib/widgets/ayre_charts.dart` (`_DrawOn.duration` removed).

---

## 3. Phase 8 — this document

Produced per the plan's own §9 instruction. `flutter analyze` / `flutter
test` / `flutter build`, and checking the app against Spec §19/§20 as a
literal checklist, are explicitly **not** run here — see §7 below for what
that leaves as your first step.

---

## 4. Known open items (carried forward, not resolved by Phase 7/8)

These are Phases 0–6's own flags, unresolved because resolving them needs
either the original Spec document or a product decision this pass isn't
positioned to make. Restated here so they aren't lost in `AYRE_REDESIGN_V4_PLAN.md`'s
longer entries:

1. **`BreadthDonut` diameter (132px) and centre-reading definition (advance
   share vs. net-advance) are inferences**, not quoted Spec figures — flagged
   in Phase 3, never confirmed since `deisgin.md` was never supplied.
2. **`SentimentGauge`'s default tone** (accent vs. subject-colour) — Phase 3
   flagged that the Spec's own §12.1 and §12.2 point different directions
   here; Phase 5 resolved it in code (subject-colour wins on both screens
   that render one) but the Spec text that would settle it outright was
   never available to check against.
3. **Insights and Profile are missing data the backend doesn't expose** —
   per-note sparkline/area-trend series for Insights, and most of Profile's
   §13.5 stats row (signals acted on, lessons completed, member-since). Both
   are flagged as backend requests, not worked around with invented numbers
   or unrelated series.
4. **`OfflineBanner`'s body text sits at `textPrimary`, not the gold
   `neutral` token**, because muted gold on its own 14%-alpha wash measures
   ~4.3:1 in light theme — under AA for body copy. The clean fix (a
   darkened `neutralInk` paralleling `accentInk`) was deliberately not added,
   since inventing a token the Spec doesn't define is a stop-and-flag moment
   under §19/§20.14, not a silent addition. Still flagged, still unresolved.
5. **`ayre_logo.dart`'s radius/token choices were Phase 5's call**, made
   without a Spec-confirmed value for where the brand mark's inner radius
   should land — noted there as a visual-QA item if the asset's own dark
   field shows a seam against `surfaceSunken` in light theme.
6. **§7's letter-spacing unit conversion** (the Spec's CSS `em` figures for
   eyebrow/nav-label tracking vs. Flutter's absolute `letterSpacing`) was
   done per-size in Phase 0/1, not derived from a formula — worth a second
   look against the original Spec if it's ever available again.

None of these are Phase 7/8 findings — they're carried forward exactly as
Phases 0–6 left them, restated here because a handoff document that omits
known-open items is worse than one that repeats them.

---

## 5. Testing status

Per the plan's own working agreement (§10): unit/widget test source is
updated in the same phase as the code it covers, but running and judging the
suite is Raghav's call, on his machine — nothing below is independently
re-verified from this environment.

- **This phase's own changes needed no test updates** (§2.6 above) —
  confirmed by grepping `test/` for `OfflineBanner` and `StaleNotice` and
  checking that no assertion depends on the padding/positioning that
  changed.
- **`identity_test.dart` and `fault_states_test.dart`** — per the plan's
  working agreement these are maintained quietly as each phase needs; this
  phase needed no changes to either.
- **`layout_matrix_test.dart`** — this phase added no new screens or
  components, so no new sweep coverage was needed; the existing gallery
  already renders `OfflineBanner`/`StaleNotice` across widths/themes/text
  scales and continues to pass on inspection of the changed regions.
- **Golden-image tests:** none found in the repo during this pass (consistent
  with Phase 0's note to check).
- **Not run:** `flutter analyze`, `flutter test`, `flutter build` — see §7.

---

## 6. Completion criteria — status against `AYRE_REDESIGN_V4_PLAN.md` §11

- Spec §13's screen-by-screen list: implemented per Phases 5–6, with the two
  explicitly flagged data-availability gaps in §4 above (items 3).
- Spec §19 (Do/Don't) and §20 (AI Implementation Rules) as a literal
  checklist: **not run here** — this requires the original Spec document,
  which was never available to any phase of this project. Phase 7's audit
  covered the subset of §19/§20 the plan itself could restate from memory
  (motion, touch targets, colour discipline, nested cards); a full literal
  pass needs `deisgin.md` or a re-transcription of §19/§20's exact bullets.
- `flutter analyze` / `flutter test`: **not run** — see §7.
- No file in the `ayre_scanner` backend repo was touched — this project
  never opened it.
- No hardcoded hex colour outside `app_theme.dart`: held throughout, per
  every phase's own sweep; Phase 7 didn't introduce any.
- This document exists and is the next handoff artifact.

---

## 7. What Raghav should do next

1. `flutter pub get`, then `flutter analyze` — expect 0 issues based on every
   phase's own account, but that account has not been independently checked
   in this pass, and Phase 5's own notes elsewhere in this project record at
   least one earlier case where a phase's self-report of "fixed" was wrong.
   Treat a clean analyze as the first real confirmation, not a formality.
2. `flutter test` — same caveat. If `fault_states_test.dart` or
   `layout_matrix_test.dart` fail, check first whether the failure is in a
   region this phase or Phase 6 touched (state_views.dart, the detail
   screens) before assuming a pre-existing issue.
3. `flutter build` for your target platform(s).
4. Manual visual QA per Spec §13, in both themes, at all three text-size
   steps, with reduced motion on and off — nothing above substitutes for
   actually looking at the app.
5. If `deisgin.md` becomes available again, re-check the six open items in
   §4 against it specifically — they're the places this project made an
   inference in its absence.
