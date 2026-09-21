# Ayre v5 — Redesign Changes

Visual redesign only. App name, package, IDs and all `Ayre*` names unchanged.
v5 replaces v4's clay/rose/gold identity with **forest-green / emerald**:
mint-paper light theme, near-black-green dark theme. Spec: `INVESTY_IMPLEMENTATION_PLAN.md` §2A.

## Identity

| | Light | Dark |
|---|---|---|
| Canvas | `#F1F7F1` mint-white | `#0B120D` near-black green |
| Accent | `#1F8A4B` | `#3FCB7A` |
| Positive / Negative | `#1F8A4B` / `#D64545` | `#4ED892` / `#F0685F` |
| Neutral (attention) | `#C98A2D` gold | `#E0B563` gold |
| Ink | `#16211B` | `#EDF5EE` |

- Fonts (Hanken Grotesk + Space Grotesk), radii, spacing, type scale: unchanged.
- Gain/loss colours are reserved for figures and glyphs; card tints are identity only.
- Avatar/identity chip uses a deliberate lavender/plum secondary accent (never brand green).

## What changed, by area

### Theme — `lib/theme/app_theme.dart`
- `_light` / `_dark` token values replaced with §2A (23 fields × 2 themes, verified).
- New tokens: `avatarFill`, `avatarInk`.
- New `AppIndexTints` / `AppIndexTint` / `AppIndexId`: per-index identity tints (NIFTY 50 sage, SENSEX coral, BANK NIFTY powder-blue).

### Shared components
- **Bottom nav** — floating pill (12px margin, full-perimeter hairline, two-layer shadow); solid active pill (`textPrimary` light / `accent` dark).
- **LIVE chip** — `positive` on `positiveSoft`.
- **Switch** — off-track `surfaceSunken`.
- **Sparkline** — area fill alpha 0.30 light / 0.35 dark → 0.
- **Sentiment gauge** — solid end-cap, pill band label.
- New shared widgets: `AyreHills`, `AyreAvatar`, `AyreIndexIdentity` / `AyreIndexIconTile` / `AyreIndexFlourish`, `AyreInsightCarousel`, `AyreInstrumentTile`, `AyreStatTile`, `CalmStatePanel`.

### Home
- Time-of-day greeting over bold name, subhead "Discipline today. A better tomorrow.", decorative hills behind header.
- Flat 44pt circular header buttons (theme toggle, bell with `negative` unread dot), lavender avatar.
- **Market Sentiment card** — bucket word + arrow (`<35` Bearish · `35–64` Neutral · `≥65` Bullish). Description: API `note` → "X of Y stocks advancing" → generic line. Nothing invented.
- **Index cards** — identity-tinted, circular radial-gradient icon tile, exchange sub-label, LIVE chip (omitted when stale).
- **Graph slot** — no fake data. Decorative flourish when `trace` is empty; real sparkline takes over automatically when the backend supplies `trace`.
- **Market Insight carousel** — dark hero card paging real notes from `GET /api/insights`, pager ‹ 01/0N ›, "Read more" → `InsightNoteScreen`, decorative bar art.
- Breadth donut kept in its own card (Nifty-500 source).

### Insights
- Gauge beside the desk's real note + breadth line; stacks on narrow width / large text.
- Movers rows: monogram tile + symbol/name + price/delta. No per-row sparkline (no backend series).
- "See all" expands 5 → all in place (44pt target).

### Learn
- Eyebrow / title / subhead header; two `AyreStatTile`s (Subjects, Courses).
- Filter pills built from the library's real categories; hidden with <2 subjects.
- Calm centred empty/failed state with circular refresh; static footer info card.

### Profile & Settings
- Profile header: lavender avatar, hills, tier pill top-right, tagline, "Edit Profile" button; stat tiles reuse `AyreStatTile`.
- Settings: Light/Dark and Small/Default/Large as big tappable tiles (glyph/"Aa" + label + checkmark). Logic untouched.

### Secondary screens
- `index_detail_screen.dart` wears the Home card identity; constituent rows use `AyreInstrumentTile`.
- All other screens recolour through tokens (no hardcoded palette colours outside component-specific §2A literals).

### "Delayed" removal
- Chips removed from Home / Equity / Index cards; `FreshnessStamp` always shows "AS OF hh:mm"; `StaleNotice` copy → "Showing the last values received".
- Kept on purpose: "Delayed-data warnings" setting, `AyreGlyph.delayed`, Home footer disclaimer ("Levels are indicative and may be delayed…").

### Auth bypass
- `kEnableAuthStartupGate = false` in `lib/main.dart` (single switch to restore the gate). `LoginScreen`, `ApiService.login/logout/getSession`, `SessionExpiredScreen` intact.
- Backend `_require_authentication` is an active `@app.before_request` hook, so the client flag alone still ends in `SessionExpiredScreen`. `main.py` now has an opt-in `AUTH_REQUIRED` env var (default `true` = unchanged). `AUTH_REQUIRED=false` allows anonymous **GET/HEAD** only; writes, `/api/rescan`, backtests still need a session.

## Known open items
- Light `onAccent` on `accent`: 4.38:1 (AA needs 4.5). Spec value kept; flagged for design review.
- Light delta figures on identity tints ≈ 3.7–3.8:1; Neutral word on the sentiment gradient ≈ 2.4–2.6:1.
- Placeholder copy: Learn subhead, Learn footer ("For learning, not advice"), Profile tagline.
- Nothing was compiled or run in the authoring sandbox (no Flutter SDK). Run `flutter test`.
