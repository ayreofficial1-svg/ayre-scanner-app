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

/// The shared state panel. One layout, one visual family — only the glyph and the
/// copy change per context.
///
/// Empty and failed are deliberately **not** interchangeable: empty uses a calm,
/// complete outline glyph, failed uses the broken-line "disconnected" glyph, so
/// the two are distinguishable at a glance rather than by reading the text.
///
/// Failure states never use Garnet as their dominant colour — red means "the
/// market went down", never "the app broke".
class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.headline,
    required this.message,
    this.glyph,
    this.failed = false,
    this.compact = false,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.pullToRefreshHint = false,
  });

  /// The calm, successful-but-empty variant.
  const StatePanel.empty({
    super.key,
    required this.headline,
    required this.message,
    this.glyph = AyreGlyph.empty,
    this.compact = false,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.pullToRefreshHint = true,
  }) : failed = false;

  /// The failure variant — distinct glyph, explicit retry.
  const StatePanel.failed({
    super.key,
    required this.headline,
    required this.message,
    this.glyph = AyreGlyph.disconnected,
    this.compact = false,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.pullToRefreshHint = false,
  }) : failed = true;

  final String headline;
  final String message;
  final AyreGlyph? glyph;
  final bool failed;

  /// Section-level states sit inside a longer feed and use tighter padding than
  /// a whole-screen state.
  final bool compact;

  /// An explicit retry, for pushed screens with no natural pull-to-refresh.
  final VoidCallback? onRetry;
  final String retryLabel;

  /// Inline "pull down to try again" text, where the gesture is the mechanism.
  final bool pullToRefreshHint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Failure is ink-toned, not red: red means "the market went down", never
    // "the app broke". The soft plate behind the glyph is where the palette's
    // muted fills do their one job on this surface.
    final tone = failed ? t.textSecondary : t.textTertiary;
    final plate = failed ? t.surfaceAlt : t.fillMint;

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
              color: plate,
              // A generous rounded plate, matching the card language rather
              // than the previous identity's crisp square.
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: AyreIcon(
              glyph ?? (failed ? AyreGlyph.disconnected : AyreGlyph.empty),
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
              label: retryLabel,
              glyph: AyreGlyph.refresh,
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

/// A slim, dismissable top banner for a device-level disconnection. Deliberately
/// non-blocking: the app keeps showing the last data it has rather than replacing
/// every screen with an error.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.cautionSoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              AyreIcon(AyreGlyph.offline, size: 16, color: t.caution),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  "You're offline — showing the last saved data",
                  style: AppTypo.bodyStrong(t, color: t.caution),
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
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xs),
                    child: AyreIcon(
                      AyreGlyph.close,
                      size: 15,
                      color: t.caution,
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

/// The stale-data marker: a degraded-but-shown state, never a blocking error.
/// Last-known values stay on screen and this explains why they might be behind.
class StaleNotice extends StatelessWidget {
  const StaleNotice({
    super.key,
    this.message = 'Data may be delayed during high volume',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        AyreIcon(AyreGlyph.delayed, size: 13, color: t.caution),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypo.caption(t, color: t.caution),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A freshness stamp. The clock is a figure, so it takes the ticker face.
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
