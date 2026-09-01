# §12 — Backend & Admin-Frontend Analysis

Read-only cross-reference of the Flutter app against `ayre_scanner`
(github.com/ayreofficial1-svg/ayre-scanner), cloned to a scratch directory so
there was no path by which it could be modified. **No backend or admin-frontend
file was changed, added, deleted, renamed or moved.**

Backend surveyed: 8,692 lines of Python, 27 Flask routes in `main.py` (2,130
lines), plus `data/`, `scanner/`, `auth/`, `indicators/` and the admin `frontend/`.

---

## 1. Headline finding

**§5 of the v3 brief cannot be satisfied by the backend as written.**

`/api/sentiment` returns exactly this:

```json
{ "sentiment": 65, "updated_at": "…", "note": "…" }
```

There are **no `advances` or `declines` fields, and no code path that would ever
produce them.** `data/app_sentiment.py` says so in its own header: *"No scoring
logic lives here yet — see master prompt §5 for the real formula (NSE
advance/decline, VIX, etc.) planned for later."* The value is a single number a
human edits.

The v3 brief's §2 states that "Advances/Declines data already exists in the app
and its data layer… sourced from the API." That is **half true and misleading**:
the `Sentiment` *model* has the fields, but nothing ever fills them. Had I taken
that at face value, Home's new headline figures would have shown "unavailable"
permanently.

**What I did about it (app-side, no backend change):** advances and declines are
now *counted from real per-stock data* — the `/api/market/{key}/constituents`
endpoint returns 50 stocks each with `change_pct`, so counting positives against
negatives across all three indices *is* market breadth, computed correctly rather
than fabricated. Home works end to end today. If the backend later computes
breadth properly, the app prefers the API's own values.

---

## 2. Endpoint reality vs. what the app expected

| App expected (v3, pre-analysis) | Backend actually has | Status |
|---|---|---|
| `/api/market` | ✅ exists | **Shape wrong** — see §3 |
| `/api/market/indices/{id}` | ❌ no such route | Fixed: read from the board |
| `/api/market/indices/{id}/constituents` | `/api/market/{key}/constituents` | Fixed: path + root key |
| `/api/market/equities/{symbol}` | ❌ no such route | Fixed: resolved from constituents |
| `/api/market/gainers` | ❌ **not implemented anywhere** | Fixed: derived |
| `/api/market/losers` | ❌ **not implemented anywhere** | Fixed: derived |
| `/api/market/most-active` | ❌ **not implemented anywhere** | Fixed: derived |
| `/api/sentiment?window=` | `/api/sentiment` (no window param) | Fixed: toggle removed |
| `/api/signals` | ✅ exists, shape compatible | OK |
| `/api/learn` | ✅ exists, `articles` | OK |
| `/api/insights` | ✅ exists, `insights` | OK |
| `/api/auth/session\|login\|logout` | ✅ exist | **Contract misread** — see §3 |

Backend routes the app does not use: `/api/results`, `/api/rescan`,
`/api/backtest/scan`, `/api/debug/scan`, `/api/backtest/status/<id>`,
`/api/status`, `/api/quotes`, `/api/uploads`, and the admin write endpoints.

---

## 3. Bucket (a) — fixed in the Flutter app

These were app-side defects revealed by reading the real contract. All are fixed,
and the suite still passes 434/434.

### 3.1 `change` vs `points` were inverted — a data-correctness bug

`/api/market` sets `"change"` to the **percentage** and `"points"` to the
**absolute** move. Confirmed at the source, in `_fetch_market_from_nse`:

```python
"value" : item.get("last",          0),
"change": item.get("percentChange", 0),   # ← percentage
"points": item.get("change",        0),   # ← absolute
```

The app's generic parser read `change` as the absolute move, so the index board
would have shown e.g. `+0.45` as the rupee change and then derived a nonsense
percentage from it. Now parsed explicitly, with the inversion documented so a
generic parser can't reintroduce it.

Constituent rows use a third naming again — `change_pct` and `change_points` —
which the parser now understands.

### 3.2 Market keys didn't match

The app used `banknifty`; the backend's key is `bank_nifty`. Bank Nifty would have
silently gone missing from the board and had no constituents.

### 3.3 An unauthenticated session was treated as signed in

`/api/auth/session` answers **HTTP 200 with `{"authenticated": false}`** when
there is no session. `ApiService.getSession()` treated any 200 as a valid session,
so the startup gate would have admitted an unauthenticated user. It now requires
`authenticated == true`.

### 3.4 Movers, index detail and equity detail now work without a backend change

Derived from the constituents endpoint, cached 45s so one screen is one fetch.
Ranked across all three indices, de-duplicated by symbol.

### 3.5 A dead control removed

The Insights weekly/monthly toggle sent a `window` parameter the backend ignores,
so both options returned identical data. Removed, with a note to reinstate it when
the endpoint genuinely supports a window.

---

## 4. Bucket (b) — backend / admin-frontend, your call

Not touched, per §0.

### 4.1 Sensex constituents return the wrong index — bug

`main.py:196`, in the `MARKETS` table:

```python
"market_key"        : "sensex",
"nse_allindices_key": "SENSEX",
"nse_index_param"   : "NIFTY NEXT 50",   # ← wrong index
```

`GET /api/market/sensex/constituents` will return **Nifty Next 50** stocks. The
level shown on the Sensex card is correct; its constituent list is not. This also
skews the derived movers and breadth, since Sensex contributes the wrong universe.

### 4.2 Sessions break on restart and across workers — bug

```python
app.secret_key = os.environ.get("FLASK_SECRET_KEY") or os.environ.get("SESSION_SECRET") or os.urandom(32)
```

With neither env var set, the key is random **per process**. Every redeploy or
restart silently invalidates all sessions, and under more than one worker each
worker signs cookies differently, so users get logged out at random depending on
which worker answers. Set one of those variables in Railway.

### 4.3 Cookie auth cannot work from Flutter web as configured

- `CORS(app, resources={r"/api/*": {"origins": "*"}})` — no
  `supports_credentials=True`, so `Access-Control-Allow-Credentials` is never
  sent and the browser will not attach the session cookie cross-origin.
- `SESSION_COOKIE_SAMESITE="Lax"` also blocks the cookie on cross-site requests.
  Web needs `None` **plus** `Secure`.
- Wildcard `origins: "*"` is separately worth tightening; it cannot legally be
  combined with credentialed requests anyway.

Mobile builds are unaffected — the app stores and replays the cookie itself.

### 4.4 `SESSION_COOKIE_SECURE` defaults to off — security

```python
SESSION_COOKIE_SECURE=os.environ.get("SESSION_COOKIE_SECURE", "").lower() in {"1","true","yes"}
```

Unset means the session cookie may travel over plain HTTP. Should default to on
in production.

### 4.5 Credentials are plaintext in environment variables — security

`SCANNER_USERS=alice:password1,bob:password2`. Comparison uses
`hmac.compare_digest` (good — no timing leak), but the passwords themselves are
stored and transported in clear text, visible to anyone with dashboard access.
There is also **no rate limiting or lockout** on `/api/auth/login`, so it is open
to unlimited credential guessing.

### 4.6 Any authenticated user can write admin content — security

`_is_admin()` returns true for *any* authenticated session when
`SCANNER_ADMIN_USERS` is unset — the docstring says so explicitly. In that state
any app user who can log in can POST/DELETE signals, insights, learn articles and
the sentiment value. Set `SCANNER_ADMIN_USERS`.

### 4.7 The admin frontend cannot author the content the app displays — gap

`frontend/src/App.tsx` calls only `/api/auth/*`, `/api/results`, `/api/rescan`
and `/api/backtest/scan`. There is **no admin UI for signals, insights, learn
articles or sentiment**, even though the backend exposes write endpoints for all
four. In practice that means the app's Signals, Insights notes and Learn tabs will
be **empty unless someone edits JSON files on the server by hand** — and Home's
sentiment number likewise. This is the single biggest gap between "the app works"
and "the app has content."

### 4.8 `frontend/node_modules` is committed — repo hygiene

62 MB of dependencies are tracked in git. Should be `.gitignore`d.

### 4.9 No intraday series anywhere — feature gap

Nothing returns a time series, so the app's ticker traces never draw. The app
deliberately does not invent a shape. `data/candles.py` exists and the scanner
uses historical candles internally, so the data is reachable — it just isn't
exposed. A `GET /api/market/{key}/series` (or per-equity equivalent) would light
up the traces on Home, Index Detail and Equity Detail.

### 4.10 Smaller mismatches, non-blocking

- **Learn** has no lesson-count fields, so the progress rule never renders. The
  app degrades cleanly; add `lessons`/`completed` if progress is wanted.
- **Signals** carry no `entry`/`target`/`stop`/`strength`, so those rows stay
  hidden. The app supports them the moment they appear.
- **Sensex level** comes from NSE's `allIndices` under key `SENSEX`; NSE is a
  BSE-index-free feed, so this may be absent in practice and fall through to the
  Fyers/Yahoo fallbacks. Worth verifying against live data.
- `_get_market_snapshot` has a `"fallback"` source with **hardcoded index levels**
  (`main.py:1600`). If NSE, Fyers and Yahoo all fail, the app is served stale
  fiction that it cannot distinguish from real data. It would be better to return
  an error so the app's designed failure state can do its job.

---

## 5. What now works end to end

With the bucket (a) fixes, against the real backend:

| Surface | Status |
|---|---|
| Index board (Nifty/Sensex/Bank Nifty) | ✅ correct values and percentages |
| Index Detail + constituents | ✅ (Sensex list wrong — 4.1, backend) |
| Equity Detail + key stats | ✅ resolved from constituents |
| Insights: gainers / losers / most active | ✅ derived |
| Home: advances / declines | ✅ counted from real per-stock changes |
| Sentiment score | ✅ (single hand-edited value — 4.7) |
| Signals / Learn / Insights notes | ✅ wiring correct, **content empty** — 4.7 |
| Auth: login, session, logout, expiry | ✅ (web blocked by 4.3) |
| Ticker traces | ❌ no series endpoint — 4.9 |

**Recommended order for you:** 4.1 (wrong index — visibly wrong data), 4.7 (no
content authoring — the app looks empty), 4.2 (random logouts), then 4.3–4.6
before any public release.
