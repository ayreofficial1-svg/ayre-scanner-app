import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';

/// "Explore our past recommendations" — shown under the locked panel on Home.
///
/// It only navigates: it reads no recommendation data and no subscription
/// detail, and shows no symbol, figure or count. The Weekly Report it opens is
/// the Reports tab, which stays open to everyone.
class ExploreReportsCard extends StatelessWidget {
  const ExploreReportsCard({super.key, required this.onOpen});

  /// Asks the shell to select the Reports tab.
  final VoidCallback? onOpen;

  static const String _title = 'Explore our past recommendations';
  static const String _line =
      'See picks from past weeks and their reported results in the '
      'Weekly Report.';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final open = onOpen;
    return Semantics(
      button: true,
      enabled: open != null,
      label: '$_title. Opens the Weekly Report.',
      excludeSemantics: true,
      onTap: open == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              open();
            },
      child: AyreCard(
        onTap: open == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                open();
              },
        child: Row(
          children: [
            Container(
              width: AppShape.iconTileSize,
              height: AppShape.iconTileSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.surfaceRaised,
                borderRadius: AppShape.field,
              ),
              child: AyreIcon(
                AyreGlyph.report,
                size: 22,
                color: t.foregroundMuted,
              ),
            ),
            const SizedBox(width: AppSpace.s13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: AppTypo.rowLabel(t)),
                  const SizedBox(height: AppSpace.xxs),
                  Text(_line, style: AppTypo.hint(t)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            AyreIcon(AyreGlyph.forward, size: 18, color: t.foregroundMuted),
          ],
        ),
      ),
    );
  }
}
