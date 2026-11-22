import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_components.dart' show ContentWidth;
import 'ayre_icons.dart';
import 'pressable_scale.dart';

/// Standard secondary-page header on the flat page base (Settings, Alerts,
/// legal, account, lesson, insight detail): a 44 visual-square back button
/// outlined on the card (≥48 hit area), a 13 gap, a 21/800 title and an
/// optional trailing action. No mast.
///
/// Reference top is y = 55 including the safe inset; the title wraps rather
/// than truncating and the back control always stays reachable.
class AyrePageHeader extends StatelessWidget {
  const AyrePageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
    this.backLabel = 'Back',
    this.backEnabled = true,
  });

  final String title;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;
  final String backLabel;
  final bool backEnabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final top = MediaQuery.paddingOf(context).top;
    final gutter = AppSpace.gutterOf(context);
    final topPad = (55 - top) < AppSpace.s13 ? AppSpace.s13 : 55 - top;

    final VoidCallback? back = !backEnabled
        ? null
        : onBack ??
              () {
                Navigator.maybePop(context);
              };
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        top + topPad,
        gutter,
        AppSpace.s8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack) ...[
            Semantics(
              button: true,
              label: backLabel,
              onTap: back,
              enabled: backEnabled,
              excludeSemantics: true,
              child: PressableScale(
                onTap: back,
                borderRadius: AppRadius.control,
                child: SizedBox(
                  width: AppSpace.minTarget,
                  height: AppSpace.minTarget,
                  child: Center(
                    child: Container(
                      width: AppShape.iconTileSize,
                      height: AppShape.iconTileSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: AppShape.field,
                        border: Border.all(color: t.hairline),
                      ),
                      child: AyreIcon(
                        AyreGlyph.back,
                        size: 20,
                        color: backEnabled ? t.textPrimary : t.textDisabled,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s13 - 2),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTypo.sectionTitle(t)),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.s13),
            Flexible(child: trailing!),
          ],
        ],
      ),
    );
  }
}

/// A scrolling secondary route with a shared header and reading width.
class AyrePageScaffold extends StatelessWidget {
  const AyrePageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.backEnabled = true,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool backEnabled;

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpace.gutterOf(context);
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: SafeArea(
        top: false,
        child: ContentWidth(
          child: ListView(
            padding: EdgeInsets.zero,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AyrePageHeader(
                title: title,
                trailing: trailing,
                backEnabled: backEnabled,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, 13, gutter, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
