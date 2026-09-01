# Ayre Scanner v3 — Redesign & Stabilization Report

Implementation of `ayre_scanner_redesign_v3.md`. Third redesign pass; the
"Cinder & Citrine" identity from v2 is retired.

**Verification:** `flutter analyze` → 0 issues · `flutter test` → **434/434 pass**
· `flutter build web --release` → succeeds. Flutter 3.44.9 / Dart 3.12.2.

---

## 1. Research findings that changed decisions (§1)

Two of these are inconvenient, so they're stated plainly rather than buried.

**Icon-only navigation is against usability research.** Nielsen Norman Group's
icon research concludes that most icons are ambiguous without text, that "a text
label must be present alongside an icon," that labels "should be visible at all
times," and that "for navigation specifically, labels are particularly critical."
§4 requires icon-only navigation with labels removed, twice over. **I built it as
specified** — it's your explicit product decision — and mitigated it as far as
the spec allows: semantic labels for screen readers, long-press tooltips,
conventional glyph shapes (home is one of the few icons NN/g found near-universal),
and 48dp targets. A test asserts the labels are absent visually *and* present in
the accessibility tree. You should know the trade-off is real and measured, not
theoretical.

**The golden ratio's design pedigree is partly disputed.** The source itself flags
that φ has been applied "based on dubious fits to data," naming financial markets
specifically, and that the common claim about Pacioli recommending it traces to an
1799 error. That's why §3.2's "intelligently, not mechanically" is the right
instruction, and why I used φ for the two type-scale relationships that carry
hierarchy and left touch targets and safe areas on the 8pt grid.

**Apple HIG and Material could not be fetched** — both are JavaScript-rendered and
returned title-only. Rather than cite pages I couldn't read, I applied the
well-established 44pt/48dp minimum target figure and noted the gap here.

---

## 2. The palette is derived from the logo, not guessed

I decoded `final_logo.png` and sampled its actual pixels rather than eyeballing
the description:

| Sampled | Value | Used as |
|---|---|---|
| Brand green | **`#07C58F`** | `accent` in **both** themes, unchanged |
| Mark off-white | `#E5E7EB` | `textPrimary` (dark), `onInkPanel` |
| Logo canvas | `#090B0E` | the basis for the dark `background` |

A test asserts `accent == 0xFF07C58F` in both themes, so a second "brand green"
can't drift in later.

**This forced a deliberate reversal of a v2 rule.** v2 kept brand (Citrine,
yellow-green) and gain (Jade, blue-green) as two provably separate hues. The logo's
green is *itself* a cool blue-green, and §3.3 says to reconcile the theme to the
asset. So in v3 the accent and the gain colour are one family, exactly as §3.1's
synthesis asks ("one clearly ownable accent hue used consistently for
'positive'/brand moments"). What still holds, and is still tested, is that gain and
loss stay >90° apart in hue.

Token names moved from hue-based (`citrine`, `jade`, `garnet`, `ember`) to semantic
(`accent`, `gain`, `loss`, `caution`, `info`) across 36 files, because after this
change hue names would actively mislead.

**Both themes are crafted separately.** Paper (light) is cool white with graphite
undertone; Slate (dark) extends the logo's own canvas. Three soft muted card fills
(`fillMint`/`fillClay`/`fillSand`) let colour do hierarchy work on a small number
of surfaces — the Reference C move — without the neon intensity of D and E.

---

## 3. Scales, informed by φ (§3.2)

- **Type:** body 14 → section 22 (`14 × φ`) → hero 38 (`≈14 × φ²`). Those two
  steps are the ones that carry hierarchy, so those are the ones φ governs. The
  in-between sizes are chosen for legibility, because a strict geometric run at
  this range produces steps too far apart to use.
- **Spacing:** Fibonacci (2, 5, 8, 13, 21, 34, 55) — its ratio converges on φ and
  it lands on or near 8pt values rather than fighting them.
- **Touch targets:** 48dp flat. Not negotiable against a ratio, and documented as
  such in the code.
- **Radii went up, deliberately:** card 6 → 20, hero 12 → 26, and pill buttons are
  back. This is the most visible break from v2's machined 4–6pt corners, and it's
  the Reference A "chunky, generous" note.

Also removed: v2's `AppSpacing` and v3's `AppSpace` briefly coexisted. Two names
for one concept is exactly the leftover inconsistency §11 asks you to find, so
`AppSpacing` is gone and every call site migrated.

---

## 4. Navigation (§4)

`fold_nav.dart` is deleted, not tuned. `curved_nav_bar.dart` replaces it:

- **Always visible.** No collapse, no auto-hide, no idle timer, no scroll
  listener — all of that plumbing is removed from the shell too.
- **Raised circle + concave notch**, animated together as one shape.
- **Icons only**, filled-on-select / line-at-rest.
- **One `CustomPaint` driven by a single animated double, inside a
  `RepaintBoundary`.** The icon row above it does not rebuild or repaint as the
  notch slides. §4 explicitly asked for this rather than a widget morph, since the
  control is on screen for effectively the whole session.
- A fast second tap **re-targets** from the notch's current position rather than
  restarting — tested.

---

## 5. Home (§5)

`_ScannerSummary` now leads with **Advances and Declines** as the two primary
figures, sourced live from `MarketDataService.getSentiment()` — nothing hardcoded,
and it refreshes with pull-to-refresh like everything else.

The composite sentiment score is **demoted, not dropped**: it sits in the
supporting row beneath, and Insights remains its fuller home. §5 asked for that
decision to be made explicitly rather than left ambiguous.

The advance/decline split also renders as a ring with the traded count in the
centre — the one place a proportion reads better as a shape than as two numbers,
and the ring/donut pattern References A, C, D and E all converge on.

If the feed returns a score but no counts, the card says so plainly rather than
rendering zeroes as though they were real.

---

## 6. Settings and Profile (§6, §7)

**System theme removed.** Light/Dark only. Existing users stored on `system` are
migrated on first load to whichever mode their device is actually showing, so the
app looks unchanged to them across the upgrade — and the new value is written back
so the migration happens once.

**Font size added**, from scratch: three named steps (Small/Default/Large) with a
**live preview card** rendering a real index readout at the chosen size before you
commit. It composes over the OS text setting rather than replacing it.

> A bug I introduced and caught here: my first implementation used
> `TextScaler.clamp`, which would have silently ignored the *Small* setting
> whenever the OS scale already sat in range. It now multiplies and then clamps.

**Both sections restructured**, not recoloured: Settings is Appearance → Alerts →
Account and session → About; Profile is Account → Preferences → Support → Session,
with sign-out still isolated at the bottom. New rows show real session state. No
control was invented without backing behaviour.

---

## 7. States (§9) and performance (§8)

`StatePanel`'s visuals are redesigned — soft tinted glyph plate, chunky radii, pill
retry — while the `DataResult`/`FaultInjector` architecture is reused untouched, as
§2 instructed.

**Verification is a test suite, not a claim.** Every surface §9 lists is walked
through its failed *and* empty phase, plus every `FaultKind` except `timeout` (which
by design never resolves inside a test clock, and is covered by the injector's own
unit tests). Also asserted: failures are never dominated by the loss colour, empty
and failed use visibly different glyphs, and no `Exception`/`DataFailure`/status
code/"Something went wrong" can reach shipped copy.

**Performance:** every continuously-animating or per-frame-repainting layer is now
inside a `RepaintBoundary` — the nav shape, the ticker trace, the breadth ring, the
skeleton pulse, and the live dot. The nav in particular repaints one isolated layer
and rebuilds nothing.

---

## 8. Logo placement (§3.3)

Asset copied to `assets/brand/ayre_logo.png` and declared in `pubspec.yaml`. Used
at exactly three fixed sizes via `LogoMark`: splash (200pt, primary), auth header
(104pt), in-app header (34pt) — plus a wordmark-only variant for Home's header,
sized to sit beneath live content. Never stretched, recoloured or rotated, with
proportional clear space, and deliberately **not** placed in empty/error cards.

The splash screen's previous hand-drawn bar mark is gone: there is a real logo now.

---

## 9. UI bugs found and fixed this pass

The layout matrix from v2 caught each of these before they shipped:

| Bug | Cause |
|---|---|
| Header brand row overflowed at 1.5×/2× | New wordmark row had no width bound |
| Ring centre label overflowed the ring | Fixed 76pt box vs scaling text |
| Text-size preference ignored *Small* | `TextScaler.clamp` instead of multiply |
| Two spacing scales coexisting | `AppSpacing` left over from v2 |
| Semantics handle leaked in a test | `addTearDown` runs after the framework check |

Two test expectations were **updated rather than bent**: the v2 "Citrine is
yellow-green" and "Citrine ≠ Jade" rules are genuinely superseded by the logo-
derived palette, so they were rewritten to assert the v3 rules; and one Insights
assertion now scrolls, because the taller v3 layout pushes that section below the
fold where a lazy list hasn't built it yet.

---

## 10. §12 — Backend cross-reference (completed)

The backend was cloned read-only and cross-referenced against the app: 8,692
lines of Python, 27 Flask routes. Nothing in it was modified — its `git status`
is clean. **Full report: [BACKEND_ANALYSIS.md](BACKEND_ANALYSIS.md).**

### 10.1 The finding that mattered most

**§5 was not achievable as briefed.** `/api/sentiment` returns only
`{sentiment, updated_at, note}` — there are no `advances`/`declines` fields and
no code path that would produce them. `data/app_sentiment.py` says so itself:
the advance/decline formula is *"planned for later."*

The v3 brief's §2 stated this data "already exists in the app and its data
layer… sourced from the API." The *model* has the fields; nothing fills them.
Believed at face value, Home's new headline figures would have shown
"unavailable" permanently.

**Resolved without a backend change:** `/api/market/{key}/constituents` returns
50 stocks each carrying `change_pct`, so counting positives against negatives
across the three indices *is* market breadth — computed from real per-stock data
rather than invented. If the backend ever computes breadth itself, the app
prefers the API's own values.

### 10.2 App-side defects the cross-reference exposed (all fixed)

| Defect | Why it mattered |
|---|---|
| `change` and `points` read the wrong way round | `/api/market` puts the **percentage** in `change` and the **absolute** in `points`. The app would have shown `+0.45` as the rupee move, then derived a nonsense percentage from it. |
| Market key `banknifty` vs real `bank_nifty` | Bank Nifty would have silently vanished from the board and had no constituents. |
| An unauthenticated session counted as signed in | `/api/auth/session` answers **200 with `authenticated: false`**; the app treated any 200 as valid, so the startup gate would have admitted anyone. |
| Weekly/monthly toggle was a dead control | The backend accepts no `window` parameter, so both options returned identical data. Removed. |

Also newly working with no backend change, because no endpoint exists for any of
them: **Index Detail**, **Equity Detail**, and all three **movers** lists — each
resolved from the constituents data, cached 45s so one screen is one fetch.

### 10.3 Backend items left for you (untouched, per §0)

Ordered by what I would fix first:

1. **Sensex constituents return the wrong index.** `main.py:196` sets
   `nse_index_param` to `"NIFTY NEXT 50"`. The Sensex level is right; its stock
   list is not — and it skews the derived movers and breadth.
2. **No admin UI for the content the app displays.** The admin frontend calls
   only auth/results/rescan/backtest. There is no way to author signals,
   insights, learn articles or sentiment, despite write endpoints existing — so
   those tabs stay empty unless someone hand-edits JSON on the server. This is
   the largest gap between "the app works" and "the app has content."
3. **Sessions break on restart and across workers.** `app.secret_key` falls back
   to `os.urandom(32)`, so it is random per process.
4. **Cookie auth cannot work from Flutter web** as configured — no
   `supports_credentials`, and `SameSite=Lax`. Mobile is unaffected.
5. **Security:** `SESSION_COOKIE_SECURE` defaults off; credentials are plaintext
   in env vars with no login rate limiting; and any authenticated user can write
   admin content while `SCANNER_ADMIN_USERS` is unset.
6. **No intraday series endpoint**, so ticker traces never draw. The app refuses
   to invent a shape. `data/candles.py` already reaches this data internally — it
   just isn't exposed.
7. **The `"fallback"` market source returns hardcoded index levels.** If NSE,
   Fyers and Yahoo all fail, the app is served stale fiction it cannot tell from
   real data. An error would let the designed failure state do its job.
8. `frontend/node_modules` (62 MB) is committed to git.

### 10.4 Still open

**APCA contrast re-verification** (§9.4). WCAG AA is enforced by test in both
themes; APCA needs tooling this repo doesn't have.
