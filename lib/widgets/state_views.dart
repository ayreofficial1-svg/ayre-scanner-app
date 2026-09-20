import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';

/// What a data section is currently showing. Every data-driven surface in the
/// app resolves to exactly one of these, and each section resolves its own —
/// a failed movers list never takes the sentiment reading down with it.
enum DataPhase {
  loading,
  ready,

  /// Request succeeded, zero items. Calm — this is not a failure.
  empty,

  /// Request failed, timed out, returned something unusable, or the device is
  /// offline. All of these read identically to the user; the distinction only
  /// matters for logging and retry behind the service layer.
  failed,
}

/// The four action verbs of Spec §14.5, which are **not** interchangeable.
///
/// The app used to have one `retryLabel` string that each call site filled in
/// by hand, which is exactly how a codebase ends up offering "Retry" for an
/// expired session and "Try again" for a dropped connection on adjacent
/// screens. Making the verb an enum means the choice is made once per *kind of
/// state* rather than once per screen, and a wrong one is visible in review as
/// a mismatched pair rather than a plausible-looking string.
///
/// The distinction each verb carries:
///
/// * [tryAgain] — the request failed. Repeat it. The default for [DataPhase.failed].
/// * [retry] — the connection failed, not the request. There is nothing to
///   repeat until the device is back; this re-tests that.
/// * [refreshNow] — nothing failed. The data on screen is real but behind, and
///   this fetches a newer copy.
/// * [signInAgain] — the session, not the data, is the problem. No amount of
///   refetching fixes it.
enum StateAction {
  tryAgain('Try again'),
  retry('Retry'),
  refreshNow('Refresh now'),
  signInAgain('Sign in again');

  const StateAction(this.label);

  final String label;
}

/// How a state panel reads: which glyph, which tone, and which verb its action
/// carries. One row per state in the Spec's §14.1 table.
///
/// Failure is never red-toned. Red means "the market went down", never "the
/// app broke" — a rule the app has always held, now enforced here rather than
/// per call site.
enum StatePreset {
  /// Succeeded, nothing to show. Calm and complete — not a degraded state.
  empty,

  /// Succeeded, and the user's own filters excluded everything. Distinct from
  /// [empty]: there *is* data, and the action is theirs to take, not the
  /// app's to retry.
  noResults,

  /// The request failed. Covers timeout, malformed response and server error
  /// alike — the taxonomy behind it matters for logging, never to the reader.
  failed,

  /// The device has no connection. Distinct from [failed] because the action
  /// is different: there is nothing to re-request until the device is back.
  offline,

  /// Authenticated call rejected. No status code, no crash, one clear action.
  sessionExpired;

  AyreGlyph get glyph => switch (this) {
    StatePreset.empty => AyreGlyph.empty,
    StatePreset.noResults => AyreGlyph.search,
    StatePreset.failed => AyreGlyph.disconnected,
    StatePreset.offline => AyreGlyph.offline,
    StatePreset.sessionExpired => AyreGlyph.lock,
  };

  StateAction get action => switch (this) {
    // An empty section has nothing to act on; the verb only applies if a
    // caller passes a handler anyway, and then repeating the request is the
    // honest description of what happens.
    StatePreset.empty => StateAction.tryAgain,
    StatePreset.noResults => StateAction.tryAgain,
    StatePreset.failed => StateAction.tryAgain,
    StatePreset.offline => StateAction.retry,
    StatePreset.sessionExpired => StateAction.signInAgain,
  };

  /// True where the state is the app's to recover from, which drives the
  /// weight of the glyph tone — a calm empty section shouldn't read as
  /// urgently as a broken one.
  bool get isFault => switch (this) {
    StatePreset.empty || StatePreset.noResults => false,
    StatePreset.failed ||
    StatePreset.offline ||
    StatePreset.sessionExpired => true,
  };
}

/// The shared state panel. One layout, one visual family — only the glyph, the
/// tone and the copy change per context.
///
/// Empty and failed are deliberately **not** interchangeable: empty uses a
/// calm, complete outline glyph, failed uses the broken-line "disconnected"
/// glyph, so the two are distinguishable at a glance rather than by reading
/// the text.
class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.headline,
    required this.message,
    this.preset = StatePreset.failed,
    this.glyph,
    this.compact = false,
    this.onRetry,
    this.action,
    this.retryLabel,
    this.pullToRefreshHint = false,
  });

  /// The calm, successful-but-empty variant.
  const StatePanel.empty({
    super.key,
    required this.headline,
    required this.message,
    this.glyph,
    this.compact = false,
    this.onRetry,
    this.action,
    this.retryLabel,
    this.pullToRefreshHint = true,
  }) : preset = StatePreset.empty;

  /// The user's filters excluded everything. Not a failure and not an empty
  /// feed — the data exists, the query is too narrow.
  const StatePanel.noResults({
    super.key,
    this.headline = 'Nothing matches those filters',
    this.message = 'Widen the filters to see more of the feed.',
    this.glyph,
    this.compact = false,
    this.onRetry,
    this.action,
    this.retryLabel,
    this.pullToRefreshHint = false,
  }) : preset = StatePreset.noResults;

  /// The request failed — distinct glyph, explicit "Try again".
  const StatePanel.failed({
    super.key,
    required this.headline,
    required this.message,
    this.glyph,
    this.compact = false,
    this.onRetry,
    this.action,
    this.retryLabel,
    this.pullToRefreshHint = false,
  }) : preset = StatePreset.failed;

  /// The device has no connection. "Retry" the connection, not the request.
  const StatePanel.offline({
    super.key,
    this.headline = "You're offline",
    this.message =
        'Showing the last saved data. New readings arrive once '
        "you're back on a connection.",
    this.glyph,
    this.compact = false,
    this.onRetry,
    this.action,
    this.retryLabel,
    this.pullToRefreshHint = false,
  }) : preset = StatePreset.offline;

  /// An authenticated call was rejected. Calm and plain: no status code, no
  /// crash, one clear action.
  const StatePanel.sessionExpired({
    super.key,
    this.headline = 'Session expired',
    this.message = "Your session's expired — sign in again to continue.",
    this.glyph,
    this.compact = false,
    this.onRetry,
    this.action,
    this.retryLabel,
    this.pullToRefreshHint = false,
  }) : preset = StatePreset.sessionExpired;

  final String headline;
  final String message;

  /// Which row of the §14.1 table this is. Drives the glyph, the tone and the
  /// action verb unless individually overridden.
  final StatePreset preset;

  /// Overrides [StatePreset.glyph]. Rarely right — the glyph is how a reader
  /// tells these apart without reading, so a screen-specific one breaks the
  /// pattern the rest of the app teaches.
  final AyreGlyph? glyph;

  /// Section-level states sit inside a longer feed and use tighter padding
  /// than a whole-screen state.
  final bool compact;

  /// An explicit action, for surfaces with no natural pull-to-refresh.
  final VoidCallback? onRetry;

  /// Overrides [StatePreset.action]. Use where the button genuinely does
  /// something other than what the preset implies.
  final StateAction? action;

  /// A literal label, overriding [action] and the preset both. Reserved for
  /// actions outside the §14.5 verb set — "Clear filters" on a
  /// [StatePanel.noResults], say, which is neither a retry nor a refresh.
  final String? retryLabel;

  /// Inline "pull down to try again" text, where the gesture is the mechanism.
  final bool pullToRefreshHint;

  /// The button's label, resolved through the three levels of override.
  String get resolvedActionLabel =>
      retryLabel ?? (action ?? preset.action).label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fault = preset.isFault;
    // Ink-toned, not red. The soft plate behind the glyph is a plain raised
    // fill — weight comes from the glyph's own tone, not from a coloured
    // plate behind it.
    final tone = fault ? t.foregroundMuted : t.foregroundSubtle;

    return AyreCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.md : AppSpace.lg,
        vertical: compact ? AppSpace.lg : AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 11 : 15),
            decoration: BoxDecoration(
              color: t.surfaceRaised,
              // A rounded square, not the card's own 18px radius and not a
              // circle — §7 reserves circles for avatars and the toggle knob.
              borderRadius: BorderRadius.circular(AppRadius.iconTile),
            ),
            child: AyreIcon(
              glyph ?? preset.glyph,
              size: compact ? 20 : 24,
              color: tone,
            ),
          ),
          SizedBox(height: compact ? AppSpace.md : AppSpace.lg),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: compact ? AppTypo.cardTitle(t) : AppTypo.sectionTitle(t),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(message, textAlign: TextAlign.center, style: AppTypo.body(t)),
          if (onRetry != null) ...[
            SizedBox(height: compact ? AppSpace.md : AppSpace.lg),
            AyreButton(
              label: resolvedActionLabel,
              // The refresh glyph belongs to states that re-fetch. An expired
              // session isn't refetched, so pairing it with a circular-arrow
              // would promise the wrong thing.
              glyph: preset == StatePreset.sessionExpired
                  ? AyreGlyph.lock
                  : AyreGlyph.refresh,
              kind: AyreButtonKind.outline,
              expand: false,
              onPressed: onRetry,
            ),
          ] else if (pullToRefreshHint) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'Pull down to try again',
              textAlign: TextAlign.center,
              style: AppTypo.label(t),
            ),
          ],
        ],
      ),
    );
  }
}

/// A slim, dismissable top banner for a device-level disconnection.
/// Deliberately non-blocking (§14.3): the app keeps showing the last data it
/// has rather than replacing every screen with an error.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.neutralSoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              AyreIcon(AyreGlyph.offline, size: 16, color: t.neutral),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  "You're offline — showing the last saved data",
                  // Body copy sits in `textPrimary`, not the gold. Muted gold
                  // on a 14%-alpha gold wash measures around 4.3:1 in light
                  // theme — under AA for body text. The gold still carries the
                  // state via the glyph and the wash; adding a darker
                  // `neutralInk` token to make gold text legible would be
                  // inventing a token the Spec doesn't define (§19), so the
                  // text simply doesn't use it. Flagged in the plan.
                  style: AppTypo.bodyStrong(t),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Semantics(
                button: true,
                label: 'Dismiss offline notice',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  // Phase 7: was an 8px pad around a 15px glyph (~31px,
                  // under the 44pt floor). A fixed 44x44 hit box, glyph
                  // centred, closes the gap without changing the glyph's
                  // visual size — the banner grows slightly taller to
                  // accommodate it, which is the correct trade (a
                  // dismiss control earns the room a decorative element
                  // wouldn't).
                  child: SizedBox(
                    width: AppSpace.minTarget,
                    height: AppSpace.minTarget,
                    child: Center(
                      child: AyreIcon(
                        AyreGlyph.close,
                        size: 15,
                        color: t.foregroundMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The stale-data marker (§14.3): a degraded-but-shown state, never a blocking
/// error. Last-known values stay on screen and this explains why they might be
/// behind.
///
/// Inline by construction — a [Row], not a card or a banner — so it cannot
/// accidentally become a takeover.
class StaleNotice extends StatelessWidget {
  const StaleNotice({
    super.key,
    this.message = 'Data may be delayed during high volume',
    this.onRefresh,
  });

  final String message;

  /// Optional. Nothing has failed here, so the verb is [StateAction.refreshNow]
  /// — never "Try again", which would imply the last attempt didn't work.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        AyreIcon(AyreGlyph.delayed, size: 13, color: t.neutral),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypo.caption(t, color: t.foregroundMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onRefresh != null) ...[
          const SizedBox(width: AppSpace.xs),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRefresh,
              // Phase 7: an inline caption-sized text link had a hit area of
              // its own text bounds only (~16px tall) — under the 44pt
              // floor. A minHeight box with the same left-aligned text
              // keeps the caption's visual size but gives the row itself
              // (and every StaleNotice call site, none of which pass
              // onRefresh today, per the constructor default) enough
              // height to meet the floor the moment one does.
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpace.minTarget,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    StateAction.refreshNow.label,
                    style: AppTypo.caption(t, color: t.accentInk).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A freshness stamp. The clock is a figure, so it takes the numeric face.
class FreshnessStamp extends StatelessWidget {
  const FreshnessStamp({super.key, required this.asOf, this.stale = false});

  final DateTime? asOf;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (asOf == null) return const SizedBox.shrink();
    // The stale variant needs the same shrink treatment as the stamp below —
    // "DELAYED" is wider than it looks once the text scale is turned up.
    if (stale) {
      return const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: AyreChip(label: 'Delayed', tone: ChipTone.attention),
      );
    }
    // Shrinks instead of overflowing: this sits in a narrow trailing slot, and
    // at a large text scale the stamp is wider than the slot allows.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('AS OF', style: AppTypo.label(t)),
          const SizedBox(width: AppSpace.xs),
          Text(_clock(asOf!), style: AppTypo.valueSmall(t)),
        ],
      ),
    );
  }

  static String _clock(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}