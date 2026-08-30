import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'premium_widgets.dart';

/// One shared template for every empty and error state in the app.
///
/// The register is Insights': a failed fetch is a normal, low-stakes state, not
/// an alarm. Calm neutral surface, a flat icon in a simple bordered circle, a
/// heading in the display serif, one line of supporting copy — and no entrance
/// animation, because stillness reads as composed here.
class AppStateMessage extends StatelessWidget {
  const AppStateMessage({
    super.key,
    required this.icon,
    required this.heading,
    required this.message,
    this.tone,
    this.compact = false,
    this.action,
  });

  final IconData icon;
  final String heading;
  final String message;

  /// Defaults to the ink tone. Errors pass `negative`; nothing else should
  /// need to override it.
  final Color? tone;

  /// Section-level states (a single market-mover section failing) sit inside a
  /// taller list and use tighter padding than a whole-tab state.
  final bool compact;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = tone ?? tokens.textTertiary;
    final iconSize = compact ? 22.0 : 28.0;
    final circle = compact ? 48.0 : 64.0;

    return PremiumCard(
      radius: AppRadius.card,
      padding: EdgeInsets.all(compact ? AppSpacing.xl : AppSpacing.xxxl),
      color: tokens.surface,
      child: Column(
        children: [
          Container(
            height: circle,
            width: circle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: accent, size: iconSize),
          ),
          SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: compact
                ? AppTypo.sectionTitle(tokens).copyWith(fontSize: 16)
                : AppTypo.sectionTitle(tokens),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypo.body(tokens),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Shape-matched skeleton row for the market-mover sections, which use
/// skeletons from their first shipped version because their real-world load
/// depends on an upstream provider. Deliberately still — a pulsing shimmer
/// would read as data arriving.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key, this.height = 56});

  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          _Block(width: 68, height: 12, color: tokens.shimmer),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _Block(width: null, height: 10, color: tokens.shimmer)),
          const SizedBox(width: AppSpacing.md),
          _Block(width: 76, height: 12, color: tokens.shimmer),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.width, required this.height, required this.color});

  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }
}

/// The one success-confirmation pattern: a short inline banner that confirms
/// without celebrating. Use the inline checkmark swap for a single preference
/// change instead.
class ConfirmationBanner extends StatelessWidget {
  const ConfirmationBanner({super.key, required this.message});

  final String message;

  static void show(BuildContext context, String message) {
    final tokens = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.surfaceRaised,
        elevation: 0,
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: tokens.border),
        ),
        content: Row(
          children: [
            Icon(Icons.check_rounded, size: 16, color: tokens.positive),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypo.bodyMedium(tokens, color: tokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Icon(Icons.check_rounded, size: 16, color: tokens.positive),
        const SizedBox(width: AppSpacing.sm),
        Text(message, style: AppTypo.bodyMedium(tokens)),
      ],
    );
  }
}
