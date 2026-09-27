import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A rounded-square monogram "logo" tile for a tradeable instrument — the
/// leading element of the shared "tile + two text lines + trailing
/// value/delta" row grammar (redesign plan §2.2), and now the app-wide stand-
/// in for a company logo wherever a stock's symbol/name is shown.
///
/// **No real company logos.** Neither the backend nor NSE's own public data
/// gives this app reliable company imagery (no ISIN, no logo CDN reachable
/// without a paid, keyed third-party API), so every free option would add a
/// network dependency that can silently break or rate-limit. This tile is
/// the reliable substitute: a deterministic, offline monogram built only
/// from the symbol string that is already flowing through every screen, so
/// it never fails to render and needs no new data plumbing. It is a neutral
/// tonal fill (`surfaceRaised`, `foregroundMuted` ink), never
/// direction-tinted: gain/loss color belongs to the figures at the trailing
/// edge, and a green tile in a Top Losers list would contradict them. It is
/// also not an identity accent — that role is [AyreAvatar]'s and is reserved
/// for people.
///
/// Rounded square by design ([AppRadius.iconTile]); the circular treatment is
/// the Home index-card icon tile's one deliberate exception (§2A) and does not
/// carry over here.
///
/// Used by the Insights movers lists, `index_detail_screen.dart`'s constituent
/// rows, `equity_detail_screen.dart`'s header, `signals_tab.dart`'s featured
/// and compact rows, the Volume Surge leaderboard, and the Weekly Report card
/// header — every place a stock's symbol/name appears in the app.
class AyreInstrumentTile extends StatelessWidget {
  const AyreInstrumentTile({
    super.key,
    required this.symbol,
    this.size = defaultSize,
  });

  /// The tile's default edge length. Public so a list can size its divider
  /// indent from the same number (`RowGroup.indent`).
  static const double defaultSize = 40;

  final String symbol;
  final double size;

  /// Up to two letters/digits of [symbol], upper-cased: `RELIANCE` → `RE`,
  /// `M&M` → `MM`. Falls back to an em dash when nothing usable remains, so the
  /// tile is never blank.
  static String monogram(String symbol) {
    final cleaned = symbol.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.isEmpty) return '—';
    final take = cleaned.length < 2 ? cleaned.length : 2;
    return cleaned.substring(0, take).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // Decorative: the ticker is spelled out in text beside the tile, so a
    // screen reader gains nothing from hearing the monogram as well.
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.iconTile),
        ),
        // Scales down rather than overflowing the tile at large accessibility
        // text sizes.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            monogram(symbol),
            style: AppTypo.ui(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: t.foregroundMuted,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
