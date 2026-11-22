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
/// The count and label share one semantics node.
class AyreStatTile extends StatelessWidget {
  const AyreStatTile({
    super.key,
    required this.value,
    required this.label,
    this.glyph,
    this.animate = true,
  });

  /// Already formatted by the caller — `'—'` is a valid value while a count is
  /// still unknown.
  final String value;
  final String label;

  /// Optional leading glyph, set in a rounded-square `surfaceRaised` tile.
  /// Omit for the icon-less Learn variant.
  final AyreGlyph? glyph;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final count = int.tryParse(value);

    return AyreCard(
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
                  if (count != null)
                    CountUpFigure(
                      value: count.toDouble(),
                      from: animate ? 0 : count.toDouble(),
                      format: (number) => number.round().toString(),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    )
                  else
                    Text(
                      value,
                      style: AppTypo.num(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(label, style: AppTypo.body(t, color: t.foregroundMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
