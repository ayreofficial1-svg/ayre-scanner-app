import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The personal-identity chip (v5 §2A, "Avatar / identity chip"): a circle of
/// initials in a lavender/plum tone.
///
/// **A deliberate secondary accent, distinct from brand green.** It exists
/// only for personal-identity chips — the Home header avatar and (Phase 6) the
/// Profile identity circle — and must never be reused for market data,
/// buttons or navigation.
///
/// The four values are §2A's literal component-table colors; they are not
/// [AppThemeTokens] fields (Phase 0 forbids adding any), so they live here,
/// next to the only widget that consumes them.
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

  static const Color _lightFill = Color(0xFFE1DDF5);
  static const Color _lightInk = Color(0xFF4B3F73);
  static const Color _darkFill = Color(0xFF241F38);
  static const Color _darkInk = Color(0xFFC9BFEA);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: dark ? _darkFill : _lightFill,
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
            color: dark ? _darkInk : _lightInk,
          ),
        ),
      ),
    );
  }
}
