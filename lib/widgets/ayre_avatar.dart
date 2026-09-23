import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The personal-identity chip (v5 §2A, "Avatar / identity chip"): a circle of ff
/// initials in a lavender/plum tone.
///
/// **A deliberate secondary accent, distinct from brand green.** It exists
/// only for personal-identity chips — the Home header avatar and (Phase 6) the
/// Profile identity circle — and must never be reused for market data,
/// buttons or navigation.
///
/// Colors come from [AppThemeTokens.avatarFill] / [AppThemeTokens.avatarInk]
/// (§2A's component-table values), so this chip and the Profile header circle
/// can never drift apart.
class AyreAvatar extends StatelessWidget {
  const AyreAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.fontSize = 13,
  });

  final String initials;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: t.avatarFill,
        shape: BoxShape.circle,
      ),
      // Scales the initials down rather than overflowing the circle at large
      // accessibility text sizes.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          initials,
          style: AppTypo.ui(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: t.avatarInk,
          ),
        ),
      ),
    );
  }
}
