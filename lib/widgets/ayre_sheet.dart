import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Opens an [AyreSheet] as a modal bottom sheet (D-11). Every bottom sheet in
/// the app goes through this so drag handle, radius, insets and dismissal
/// behave identically.
Future<T?> showAyreSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    showDragHandle: false,
    builder: builder,
  );
}

/// The one bottom-sheet scaffold: drag handle, `AppRadius.sheet` top corners
/// (from the theme's `bottomSheetTheme`), keyboard and safe-area insets, and
/// scrolling when large text makes the content taller than the sheet allows.
class AyreSheet extends StatelessWidget {
  const AyreSheet({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.xs,
      AppSpace.lg,
      AppSpace.xl,
    ),
  });

  /// Optional heading, set in the card-title role.
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Drag handle',
                excludeSemantics: true,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: AppSpace.sm,
                      bottom: AppSpace.sm,
                    ),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.foregroundSubtle.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null) ...[
                      Semantics(
                        header: true,
                        child: Text(title!, style: AppTypo.sectionTitle(t)),
                      ),
                      const SizedBox(height: AppSpace.sm),
                    ],
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
