import 'package:flutter/material.dart';

import '../services/stock_logo_service.dart';
import '../theme/app_theme.dart';

/// A rounded-square tile for a tradeable instrument — the leading element of
/// the shared "tile + two text lines + trailing value/delta" row grammar
/// (redesign plan §2.2), and the app-wide stand-in for a company logo
/// wherever a stock's symbol/name is shown.
///
/// **Shows a real company logo when one can be found, its monogram
/// otherwise.** Neither the backend nor NSE's own public data gives this app
/// company imagery directly, so [StockLogoService] resolves one from a fixed
/// set of logo images bundled with the app (`assets/logos/`, see that
/// class's doc). Whenever nothing is found — the stock isn't in the bundled
/// set, or a bundled asset somehow fails to load — this tile falls back to
/// the same deterministic, offline monogram it always drew:
/// a neutral tonal fill (`surfaceRaised`, `foregroundMuted` ink), never
/// direction-tinted (gain/loss color belongs to the figures at the trailing
/// edge, and a green tile in a Top Losers list would contradict them), and
/// never an identity accent (that role is `AyreAvatar`'s, reserved for
/// people). The tile never blocks its row on a network call and never shows
/// a broken image — a logo either loads or the monogram remains.
///
/// Rounded square by design ([AppRadius.iconTile]); the circular treatment is
/// the Home index-card icon tile's one deliberate exception (§2A) and does not
/// carry over here.
///
/// Used by the Insights movers lists, `index_detail_screen.dart`'s constituent
/// rows, `equity_detail_screen.dart`'s header, `ayre_signals_section.dart`'s
/// signal cards, and the Weekly Report card
/// header — every place a stock's symbol/name appears in the app. Passing
/// [name] wherever the caller has it (most call sites do) sharply improves
/// logo match confidence; it is optional and never required.
class AyreInstrumentTile extends StatefulWidget {
  const AyreInstrumentTile({
    super.key,
    required this.symbol,
    this.size = defaultSize,
    this.name,
  });

  /// The tile's default edge length. Public so a list can size its divider
  /// indent from the same number (`RowGroup.indent`).
  static const double defaultSize = 40;

  final String symbol;
  final double size;

  /// The company name, when the caller has it (e.g. `Quote.name`,
  /// `Signal.name`). Used only to disambiguate the logo lookup — never
  /// displayed by this tile itself.
  final String? name;

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
  State<AyreInstrumentTile> createState() => _AyreInstrumentTileState();
}

class _AyreInstrumentTileState extends State<AyreInstrumentTile> {
  /// Backing for transparent logos. Logos are drawn for a white page, so the
  /// plate is white in both light and dark mode; the few light-on-transparent
  /// marks get a dark plate instead. These are image backings, not UI
  /// surfaces, so they deliberately do not follow the theme.
  static const Color _lightPlate = Color(0xFFFFFFFF);
  static const Color _darkPlate = Color(0xFF111614);

  /// `null` = not yet resolved this session (monogram shown meanwhile), `''`
  /// = confidently no logo, anything else = a display URL.
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AyreInstrumentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _logoUrl = StockLogoService.peek(widget.symbol);
      _load();
    }
  }

  void _load() {
    final cached = StockLogoService.peek(widget.symbol);
    if (cached != null) {
      _logoUrl = cached;
      return;
    }
    // Not yet resolved this session: kick off resolution and swap the
    // monogram for the logo when (and only if) one is found, without ever
    // showing a loading state — the monogram is a perfectly good interim
    // and permanent-fallback appearance.
    final requestedFor = _key;
    StockLogoService.resolve(widget.symbol, name: widget.name).then((url) {
      if (!mounted || _key != requestedFor) return;
      if (url.isNotEmpty) setState(() => _logoUrl = url);
    });
  }

  String get _key => widget.symbol.trim().toUpperCase();

  void _onLoadFailed() {
    StockLogoService.reportBroken(widget.symbol);
    if (mounted) setState(() => _logoUrl = '');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = widget.size;
    final logoUrl = _logoUrl;
    final showLogo = logoUrl != null && logoUrl.isNotEmpty;

    // Decorative: the ticker is spelled out in text beside the tile, so a
    // screen reader gains nothing from hearing the monogram/logo as well.
    if (!showLogo) {
      return ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.iconTile),
          ),
          child: _Monogram(symbol: widget.symbol, size: size, t: t),
        ),
      );
    }

    // The logo *is* the tile. Every bundled file is a square artboard, and
    // many are full-bleed (a coloured or black background running to the
    // edge), so the image fills the frame exactly: no inner padding and no
    // second surface behind it, which is what used to leave a visible ring
    // of tile colour around the artwork. The plate behind it is only what
    // shows through a transparent logo, and is chosen so the artwork stays
    // legible (see [StockLogoService.needsDarkPlate]).
    final dark = StockLogoService.needsDarkPlate(widget.symbol);
    final radius = BorderRadius.circular(AppRadius.iconTile);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            // Hairline edge so a white logo plate doesn't dissolve into a
            // light card, and so every logo shares one outline.
            border: Border.all(color: t.hairline),
          ),
          child: ClipRRect(
            // Clip to the radius minus the 1 px edge so the artwork meets
            // the hairline with no gap.
            borderRadius: BorderRadius.circular(AppRadius.iconTile - 1),
            child: ColoredBox(
              color: dark ? _darkPlate : _lightPlate,
              child: Image.asset(
                logoUrl,
                key: ValueKey(logoUrl),
                width: double.infinity,
                height: double.infinity,
                // Aspect ratio is always preserved. For the square artwork
                // shipped today `contain` fills the frame exactly; a future
                // wide or tall logo is letterboxed on the plate instead of
                // being stretched or cropped.
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
                // A bundled logo that somehow fails to decode reports
                // itself broken and this build falls through to the
                // monogram on the next frame — never a broken-image icon.
                errorBuilder: (_, _, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _onLoadFailed();
                  });
                  return _Monogram(symbol: widget.symbol, size: size, t: t);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.symbol, required this.size, required this.t});

  final String symbol;
  final double size;
  final AppThemeTokens t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(size * 0.12),
      // Scales down rather than overflowing the tile at large accessibility
      // text sizes.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          AyreInstrumentTile.monogram(symbol),
          style: AppTypo.ui(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: t.foregroundMuted,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}