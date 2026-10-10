import 'package:flutter/widgets.dart';

/// Published by `HomeShell` above its per-tab navigators (plan A3). It tells
/// pushed in-tab screens how much of the bottom of the viewport the floating
/// dock occupies, so they end above it instead of scrolling under it.
///
/// `clearance` is `0` when the rail is shown, when the keyboard is open (the
/// dock is hidden then) and anywhere outside the shell.
class AyreTabHost extends InheritedWidget {
  const AyreTabHost({super.key, required this.clearance, required super.child});

  final double clearance;

  static double clearanceOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AyreTabHost>()?.clearance ??
      0;

  @override
  bool updateShouldNotify(AyreTabHost oldWidget) =>
      oldWidget.clearance != clearance;
}

/// Wraps a pushed route's page. Inside a tab navigator it reserves the dock's
/// height at the bottom and removes the (now covered) bottom padding from the
/// page's `MediaQuery`, so a nested `SafeArea` or `ListView` does not count the
/// inset twice. Anywhere else it is a no-op.
class AyreDockClearance extends StatelessWidget {
  const AyreDockClearance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clearance = AyreTabHost.clearanceOf(context);
    if (clearance <= 0) return child;
    return Padding(
      padding: EdgeInsets.only(bottom: clearance),
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }
}
