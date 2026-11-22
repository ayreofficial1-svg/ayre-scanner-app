import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'figure.dart';

/// A compact stat tile: a bold figure over a muted label (redesign plan §2.3 /
/// §2.4).
///
/// **One component for two screens.** Learn uses it icon-less ("3 Subjects",
/// "12 Courses"); Profile (Phase 6) passes a [glyph] for its "icon + number +
/// label" tiles. Building it once here is the plan's instruction — Profile
/// must not grow a second, near-identical tile.
///
/// The figure goes through [Figure.static] (the readout face, like every other
/// number in the app) and scales down instead of overflowing at large text
/// sizes. Label and figure merge into a single semantics node, so a screen
/// reader hears "3 Subjects" rather than two unrelated fragments.
class AyreStatTile extends StatelessWidget {
  const AyreStatTile({
    super.key,
    required this.value,
    required this.label,
    this.glyph,
  });

  /// Already formatted by the caller — `'—'` is a valid value while a count is
  /// still unknown.
  final String value;
  final String label;

  /// Optional leading glyph, set in a rounded-square `surfaceRaised` tile.
  /// Omit for the icon-less Learn variant.
  final AyreGlyph? glyph;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return AyreCard(
      padding: const EdgeInsets.all(AppSpace.s21),
      child: MergeSemantics(
        child: Row(
          children: [
            if (glyph != null) ...[
              Container(
                width: AppShape.iconTileSize,
                height: AppShape.iconTileSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.surfaceRaised,
                  borderRadius: AppShape.field,
                ),
                child: AyreIcon(glyph!, size: 22, color: t.textPrimary),
              ),
              const SizedBox(width: AppSpace.s13),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hero-style numeral: truncating it would hide data, so it
                  // keeps a FittedBox (documented D-9 exception).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Figure.static(
                      value,
                      fontSize: AppTextScale.stat,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    label,
                    style: AppTypo.body(t, color: t.foregroundMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
