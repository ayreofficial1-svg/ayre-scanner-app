import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_components.dart' show ContentWidth;
import 'ayre_nav_metrics.dart';

/// The shared scroll frame of the five tabs: pull-to-refresh, a centred
/// reading measure, theme-aware gutters and a bottom padding that always
/// clears the floating dock (plan Phase 1, task 5; replaces the hard-coded
/// `120` / `edgeOffset: 72` each tab used to carry).
///
/// [controller] lets the shell scroll a tab to the top on a re-tap (A2).
/// [onRefresh] may be null for a tab without pull-to-refresh.
class AyreTabScroll extends StatelessWidget {
  const AyreTabScroll({
    super.key,
    required this.children,
    this.onRefresh,
    this.controller,
    this.maxWidth,
    this.eager = false,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;
  final double? maxWidth;

  /// Builds every child at once (a scroll view over a plain `Column`) instead
  /// of lazily. Needed where something must find an off-screen row by key —
  /// the Profile tour.
  final bool eager;

  /// Bottom padding of the list: never less than the real system inset or the
  /// dock clearance, plus one medium step of air.
  static double bottomPaddingOf(BuildContext context) =>
      math.max(
        MediaQuery.paddingOf(context).bottom,
        AyreNavMetrics.clearanceOf(context),
      ) +
      AppSpace.md;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gutter = AppSpace.gutterOf(context);

    final padding = EdgeInsetsDirectional.fromSTEB(
      gutter,
      AppSpace.pageTop,
      gutter,
      bottomPaddingOf(context),
    );
    final physics =
        onRefresh == null ? null : const AlwaysScrollableScrollPhysics();

    final Widget list = eager
        ? SingleChildScrollView(
            controller: controller,
            physics: physics,
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        : ListView(
            controller: controller,
            physics: physics,
            padding: padding,
            children: children,
          );

    final body = ContentWidth(maxWidth: maxWidth, child: list);
    if (onRefresh == null) return body;

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: onRefresh!,
      edgeOffset: MediaQuery.paddingOf(context).top + AppSpace.xl,
      child: body,
    );
  }
}
