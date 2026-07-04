import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PressableScale extends StatelessWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadius.lg,
    this.scale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Material(
      color: AppTheme.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}