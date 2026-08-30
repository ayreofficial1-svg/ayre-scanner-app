# Ayre Scanner v2 — "Cinder & Citrine" Implementation Report

Implementation of `ayrescan_redesign_v2.md`. The warm brass/parchment "instrument"
identity from v1 is fully retired; functionality and information structure are
preserved, the entire visual execution is rebuilt.

**Verification:** `flutter analyze` → 0 issues · `flutter test` → **416/416 pass**
(Flutter 3.44.9 / Dart 3.12.2). 32 library files, 10.5k lines including tests.

---

## 1. UI bugs found and fixed

You said the v1 build had "a lot of UI bugs". Rather than guess, I built a layout
stress harness that renders every screen across **4 device widths × 2 themes ×
3 accessibility text scales × 4 data phases** and fails on any overflow or paint
exception. It found real bugs immediately — in the old build *and* in my own new
code as I wrote it.

### Bugs in the v1 build

| Bug | Where | Effect |
|---|---|---|
| Figures column had no width bound | movers rows | Overflowed 120–166px at ≥1.5× text |
| Header row unbounded | Lesson screen | Overflowed 11–81px at 2× text |
| `usesTwoColumn` excluded the widest tier | `responsive.dart` | Desktop silently fell back to **one** column — the opposite of the intent |
| Fixed `mainAxisExtent` grid tiles | Signals, Learn | Guaranteed overflow at large text |
| Nav segment width maths could go negative | old pill nav | Broken layout on narrow screens |
| Rail needle position hard-coded to padding constants | old side rail | Marker drifted off the active item |
| Fabricated data | Home sparkline, monthly sentiment | Invented a trace shape and a "monthly" reading the feed never sent |

### Bugs I introduced and caught before shipping

| Bug | Cause |
|---|---|
| `TickerTrace` crashed on build | Two `AnimationController`s on `SingleTickerProviderStateMixin` |
| Card accent edge forced infinite height | `CrossAxisAlignment.stretch` inside a list |
| Index board forced infinite height | Same `stretch` mistake in the multi-column path |
| `borderRadius` + non-uniform border assertion | First attempt at the accent edge |
| Segmented control's `Expanded` blew up | A non-flex `Row` child receives **unbounded** width |
| `Entrance` leaked a timer past disposal | `Future.delayed` isn't cancellable |
| Dark `textTertiary` at 4.375:1 on `surfaceAlt` | Below AA — caught by the contrast test, not by eye |
| "DELAYED" chip / clock / sort control overflowed | Non-flex trailing children at 2× text |

**A harness bug worth calling out:** my first matrix built `MediaQueryData(textScaler: …)`
from scratch, which **drops the viewport size** — so every responsive branch fell
to single-column and was never tested. Fixed to `copyWith`, which immediately
exposed two more real bugs. Worth knowing if you write similar tests.

The durable fix for the whole overflow class is one shared widget,
`ShrinkTrailing`, plus the rule it documents: *a non-flexible child of a `Row` is
laid out with unbounded width*.

---

## 2. Identity

**Colour — Cinder & Citrine.** The base hue family moves from warm brown/cream to
**cool ink/graphite/paper**: Fogpaper (cool off-white, graphite undertone) in
light, Cinder (true near-black, no warm undertone) in dark. A test asserts every
base step is cool so cream cannot creep back.

Three greens, three jobs, enforced by test:

| Token | Hue | Job |
|---|---|---|
| **Citrine** | ~64° yellow-green, mineral | Brand only. Never on a numeric value, never with a sign |
| **Jade** | ~158° blue-leaning, saturated | Gain only. Always with `+` and an up-caret |
| **Garnet** | ~350° wine-toned | Loss only. Always with `−` and a down-caret |

Also: **Ember** (copper-amber — LIVE dot, delayed chips, offline) and **Slate
Violet** (small informational tags only). A test asserts Citrine and Jade stay
>60° apart and that Jade is the more saturated of the two, so they can't drift
together through careless tinting.

`citrineInk` exists as a separate token because the light-mode Citrine *fill* is
too light to clear 4.5:1 as small text. Fills use `citrine`, type and thin lines
use `citrineInk`.

**Typography — three new faces.** Space Grotesk (display: titles, index names,
course titles) · **JetBrains Mono** (ticker: every numeric market value, tabular)
· Manrope (UI: body, labels, buttons). All three are new; nothing from the v1
serif/Inter pairing survives. A test asserts the numeral face is monospace with
tabular figures and that the two sans faces are genuinely different.

**Iconography — drawn, not imported.** 33 glyphs in `ayre_icons.dart`, each hand-
drawn as a painter on a shared 24pt keyline grid at one stroke weight, with solid
variants for selected states (filled-on-select, line-at-rest). No Material glyph
appears anywhere in the app. The set is checked as a set, per §4.3.

---

## 3. The Fold

Navigation is no longer a bar. At rest the **entire** navigation is one small
Citrine circle showing the current section's icon — the only place Citrine sits
permanently on screen, which is what makes it the signature mark. Tapping it
unfolds that single control into the five-destination dock; picking a destination
folds it back showing the new icon. It also folds on scroll and after 4s idle.

Spring-driven (critically damped, no overshoot), and tested at 320pt across all
three text scales to confirm five labelled destinations fit legibly — the specific
check §9.4 asks for. Destination labels use `FittedBox` so they shrink rather than
truncate.

---

## 4. Screens

- **Home** — greeting from account data, three tappable index instrument cards
  (NIFTY 50 / SENSEX / BANK NIFTY) each with an embedded ink readout panel and a
  hairline trace, plus one scanner summary row. Movers moved out.
- **Insights** (was Climate) — the market intelligence desk: a horizontal breadth
  **meter** (the dial/needle motif is retired) plus all three movers lists as one
  continuous feed sharing `TickerRow`, hairlines and label typography.
- **Signals** — dense terminal row-cards with signal-strength **ticks**, entry/
  target/stop levels, and a bias glyph alongside the colour.
- **Learn** — flat rows with a Citrine progress rule; counters in the ticker face.
- **Profile / Settings** — flat header block and shared row grammar; three-way
  System/Light/Dark segmented selector.
- **Index Detail** (new) — header at the same visual weight as the card tapped, a
  larger trace, and a sortable constituent list.
- **Equity Detail** (new) — reached from constituents, every movers row, and
  Signals. Key stats grid, explicit Retry (no pull-to-refresh at that depth).

---

## 5. Failure states as a first-class system

`DataResult` gives every section its own phase, so **sections fail independently**
— a test proves a failed Gainers list leaves Most Active and the sentiment reading
untouched, and that constituents can fail while the index reading stays current.

- **Empty vs failed are visually distinct**: a calm complete-outline glyph vs a
  broken-line "disconnected" glyph — tested, so they can't collapse into one look.
- **Failures are never Garnet.** Red means the market went down, never that the
  app broke. Tested.
- **Stale is degraded-but-shown**: last-known values stay, flagged with Ember.
- **Offline** is a slim dismissable app-wide banner, not a screen takeover.
- **Session expiry** routes to one calm prompt with a single action.
- A test asserts no `Exception`, `DataFailure`, status code or "Something went
  wrong" can reach shipped copy.

**Fault injection (§9.3)** — `FaultInjector` can force all seven required
conditions per surface, gated on `kDebugMode` *and* an explicit opt-in so nothing
can fire in release. This is what makes §9.4 an actual gate rather than a wish.

---

## 6. Things I did beyond the brief

1. **The layout matrix itself.** The brief asks for a manual verification pass; a
   416-test sweep is the version that keeps working after this handover.
2. **Injectable data layer.** `MarketDataService` is a parameter on every screen.
   That's what lets the matrix render **populated** states — where overflow bugs
   actually live — instead of only empty/failure states.
3. **`ShrinkTrailing`** as a named, documented fix for the recurring unbounded-
   trailing-child bug, rather than patching each site silently.
4. **Contrast enforced as a test** against final token values, not eyeballed. It
   caught one real AA failure.
5. **Version alignment** — `pubspec.yaml` bumped to 2.0.0+1 to match the in-app
   version constant, which had drifted.

---

## 7. What still needs your input

1. **The backend is a separate package and its endpoints don't exist yet.** The
   contract the app expects is declared in one place, `RemoteMarketDataService`:
   `/api/market`, `/api/market/indices/{id}`, `/api/market/indices/{id}/constituents`,
   `/api/market/equities/{symbol}`, `/api/market/gainers`, `/losers`,
   `/most-active`, `/api/sentiment?window=`, `/api/signals`, `/api/learn`,
   `/api/insights`. Until they exist the screens render their designed failure
   states, which is why those states are tested. Wire-shape parsing is tolerant
   (multiple key aliases, seconds or millis epochs).
2. **Traces only draw when the feed sends samples.** No trace is invented. If the
   backend won't return intraday series, tell me and I'll add a dedicated
   endpoint call rather than fabricate a shape.
3. **Settings ships three real alert toggles**, not the original three — push
   delivery, watchlist price alerts and a weekly digest have nothing behind them.
   Same reasoning as v1; reversible if the backend gains those features.
4. **APCA re-verification** (§9.4) is not done — WCAG AA is enforced by test in
   both themes, but APCA needs tooling this repo doesn't have.

---

## 8. Test suites

| File | Covers |
|---|---|
| `test/layout_matrix_test.dart` | 4 widths × 2 themes × 3 text scales × ready/empty/failed/stale, plus the Fold at 320pt |
| `test/identity_test.dart` | Cool base, Citrine hue, Citrine/Jade/Garnet separation, all contrast pairs at final values, the three type roles, formatters, the icon set as a family |
| `test/fault_states_test.dart` | All seven fault kinds, per-surface independence, empty-vs-failed distinctness, failure-never-red, copy discipline |
| `test/support/fake_market_data.dart` | Deterministic service double with per-surface phase overrides, long company names and large figures |
