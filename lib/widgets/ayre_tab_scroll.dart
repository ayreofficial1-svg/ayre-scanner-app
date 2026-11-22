import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ayre_components.dart' show ContentWidth;
import 'ayre_nav_metrics.dart';
import 'ayre_tab_host.dart';

/// The shared scroll frame of the five tabs: pull-to-refresh, a centred
/// reading measure, theme-aware gutters and a bottom padding that always
/// clears the dock and system insets.
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
    this.header,
  });

  /// Full-bleed header (a masthead block) laid out as the first scroll item
  /// with no side gutter; the [children] keep the gutter. Lets a mast bleed to
  /// the screen edges without per-screen negative offsets.
  final Widget? header;

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
  ///
  /// The dock clearance already includes the system inset, so the two are
  /// never added together.
  static double bottomPaddingOf(BuildContext context) =>
      math.max(
        MediaQuery.paddingOf(context).bottom,
        AyreTabHost.maybeClearanceOf(context) ??
            AyreNavMetrics.clearanceOf(context),
      ) +
      AppSpace.s13;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gutter = AppSpace.gutterOf(context);

    final hasHeader = header != null;
    final padding = EdgeInsetsDirectional.fromSTEB(
      0,
      hasHeader ? 0 : AppSpace.pageTop,
      0,
      bottomPaddingOf(context),
    );
    final physics = onRefresh == null
        ? null
        : const AlwaysScrollableScrollPhysics();

    // With a full-bleed header the reading measure applies per child, so the
    // mast still reaches both screen edges on wide windows.
    Widget gutterWrap(Widget child) {
      final padded = Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: child,
      );
      return hasHeader
          ? SafeArea(
              top: false,
              bottom: false,
              child: ContentWidth(maxWidth: maxWidth, child: padded),
            )
          : padded;
    }

    final Widget list = eager
        ? SingleChildScrollView(
            controller: controller,
            physics: physics,
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [?header, for (final c in children) gutterWrap(c)],
            ),
          )
        : ListView(
            controller: controller,
            physics: physics,
            padding: padding,
            children: [?header, for (final c in children) gutterWrap(c)],
          );

    final body = hasHeader
        ? list
        : ContentWidth(maxWidth: maxWidth, child: list);
    if (onRefresh == null) return body;

    return RefreshIndicator(
      color: t.accent,
      backgroundColor: t.surface,
      onRefresh: onRefresh!,
      edgeOffset: MediaQuery.paddingOf(context).top + AppSpace.xl,
      child: body,
    );
  }
}
