import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/instrument_marks.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/responsive.dart';
import '../widgets/spring.dart';
import 'home_tab.dart';
import 'insights_tab.dart';
import 'learn_tab.dart';
import 'profile_tab.dart';
import 'signals_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _displayName = '';

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _onIdentityResolved(String displayName) {
    if (displayName == _displayName) return;
    setState(() => _displayName = displayName);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) => _build(
        context,
        SettingsStore.instance.displayNameOverride ?? _displayName,
      ),
    );
  }

  Widget _build(BuildContext context, String name) {
    final tokens = context.tokens;
    final usesRail = AppBreakpoints.usesRail(context);

    // IndexedStack keeps every tab's state alive across switches, including
    // the new Profile tab. Profile is a peer destination here, not a modal and
    // not a separate navigator stack.
    final stack = IndexedStack(
      index: _index,
      children: [
        HomeTab(
          onIdentityResolved: _onIdentityResolved,
          onOpenProfile: () => _select(4),
        ),
        const SignalsTab(),
        const InsightsTab(),
        const LearnTab(),
        ProfileTab(displayName: name),
      ],
    );

    // The incoming tab's already-built content fades in — opacity only, and
    // additive to the nav's own label and needle-mark motion.
    final body = _TabCrossFade(index: _index, child: stack);

    if (usesRail) {
      return Scaffold(
        backgroundColor: tokens.background,
        body: Row(
          children: [
            _InstrumentRail(
              selectedIndex: _index,
              onSelected: _select,
              displayName: name,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.background,
      extendBody: true,
      body: body,
      bottomNavigationBar: _InstrumentNav(
        selectedIndex: _index,
        onSelected: _select,
        displayName: name,
      ),
    );
  }
}

class _TabCrossFade extends StatefulWidget {
  const _TabCrossFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabCrossFade> createState() => _TabCrossFadeState();
}

class _TabCrossFadeState extends State<_TabCrossFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: AppMotion.fast)
      ..value = 1.0;
  }

  @override
  void didUpdateWidget(_TabCrossFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _fade.value = 1.0;
      } else {
        _fade.forward(from: 0.35);
      }
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: AppMotion.ease),
      child: widget.child,
    );
  }
}

// ─── Nav item model ─────────────────────────────────────────────────────────

enum _NavKind { icon, avatar }

class _NavItemData {
  const _NavItemData(this.icon, this.label, {this.kind = _NavKind.icon});

  final IconData icon;
  final String label;
  final _NavKind kind;
}

const _navItems = [
  _NavItemData(Icons.dashboard_outlined, 'Home'),
  _NavItemData(Icons.show_chart_rounded, 'Signals'),
  _NavItemData(Icons.speed_outlined, 'Insights'),
  _NavItemData(Icons.menu_book_outlined, 'Learn'),
  _NavItemData(Icons.person_outline_rounded, 'Profile', kind: _NavKind.avatar),
];

const double _navItemHeight = 52;

/// A stable handle on a nav destination. Inactive segments are icon-only, so
/// there is no label text to address them by.
Key navSegmentKey(String label) => ValueKey('nav-segment-$label');

// ─── Bottom bar ─────────────────────────────────────────────────────────────

/// The floating pill, rebuilt.
///
/// What survives: the floating, edge-to-edge, rounded capsule silhouette, the
/// expand-on-select label reveal, the 52px touch targets, and the safe-area
/// plumbing. That silhouette is the one sanctioned use of the stadium shape.
///
/// What's new: a flat, opaque, matte instrument-panel surface instead of a
/// translucent glassy fill; a hairline top edge marked with short brass ticks
/// at every segment boundary, like a calibration strip; and a sliding brass
/// needle-mark for the active state instead of an expanding tinted fill. The
/// material and the needle are what separate this from every other floating
/// glassy capsule — not the shape, which was already right.
class _InstrumentNav extends StatelessWidget {
  const _InstrumentNav({
    required this.selectedIndex,
    required this.onSelected,
    required this.displayName,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + (bottomPadding > 0 ? bottomPadding - 10 : 0),
      ),
      child: Center(
        // At tablet widths and landscape the bar caps and centres rather than
        // stretching five segments across a much wider viewport.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.navMaxWidth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.navBar),
              border: Border.all(color: tokens.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.navBar - 1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final widths = _segmentWidths(constraints.maxWidth);
                  return SizedBox(
                    height: _navItemHeight + AppSpacing.sm * 2,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _NavTickEdge(widths: widths)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              for (var i = 0; i < _navItems.length; i++)
                                AnimatedContainer(
                                  duration: AppMotion.navExpand,
                                  curve: AppMotion.ease,
                                  width: widths[i],
                                  child: _NavSegment(
                                    key: navSegmentKey(_navItems[i].label),
                                    data: _navItems[i],
                                    selected: selectedIndex == i,
                                    displayName: displayName,
                                    onTap: () => onSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _NeedleMark(
                          axis: Axis.horizontal,
                          target: _needleCentre(widths, selectedIndex),
                          color: tokens.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The selected segment takes extra width so its label can reveal without
  /// truncating at narrow mobile widths, with five items to fit.
  List<double> _segmentWidths(double total) {
    final active = math.min(
      math.max(total * 0.30, 84.0),
      math.max(total - 4 * 44.0, 84.0),
    );
    final rest = (total - active) / (_navItems.length - 1);
    return [
      for (var i = 0; i < _navItems.length; i++)
        i == selectedIndex ? active : rest,
    ];
  }

  double _needleCentre(List<double> widths, int index) {
    var left = 0.0;
    for (var i = 0; i < index; i++) {
      left += widths[i];
    }
    return left + widths[index] / 2;
  }
}

/// The calibration strip: a hairline top edge with short brass ticks at each
/// segment boundary, giving the bar a measuring-instrument read at a glance.
class _NavTickEdge extends StatelessWidget {
  const _NavTickEdge({required this.widths});

  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return CustomPaint(
      painter: _NavTickEdgePainter(
        widths: widths,
        edgeColor: tokens.hairline,
        tickColor: tokens.primary.withValues(alpha: 0.65),
      ),
    );
  }
}

class _NavTickEdgePainter extends CustomPainter {
  const _NavTickEdgePainter({
    required this.widths,
    required this.edgeColor,
    required this.tickColor,
  });

  final List<double> widths;
  final Color edgeColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      Paint()
        ..color = edgeColor
        ..strokeWidth = 1,
    );

    final tick = Paint()
      ..color = tickColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;

    var x = 0.0;
    for (var i = 0; i < widths.length - 1; i++) {
      x += widths[i];
      canvas.drawLine(Offset(x, 0), Offset(x, 5), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _NavTickEdgePainter old) {
    return old.edgeColor != edgeColor ||
        old.tickColor != tickColor ||
        !listEquals(old.widths, widths);
  }
}

/// The active-state signature: a short, fine brass index line that slides along
/// the bar's edge to sit under the selected segment, in the same idiom as the
/// gauge needle. It confirms *where* you are; the label reveal confirms *what*.
/// The slide is spring-driven so a fast double tab-change re-targets smoothly,
/// and it begins a beat after the label reveal rather than with it.
class _NeedleMark extends StatefulWidget {
  const _NeedleMark({
    required this.axis,
    required this.target,
    required this.color,
    this.length = 22,
  });

  final Axis axis;

  /// Centre of the active segment along [axis], in pixels.
  final double target;
  final Color color;
  final double length;

  @override
  State<_NeedleMark> createState() => _NeedleMarkState();
}

class _NeedleMarkState extends State<_NeedleMark> {
  late double _target = widget.target;
  Timer? _lag;

  @override
  void didUpdateWidget(_NeedleMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target == widget.target) return;
    _lag?.cancel();
    _lag = Timer(AppMotion.needleLag, () {
      if (mounted) setState(() => _target = widget.target);
    });
  }

  @override
  void dispose() {
    _lag?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    return Positioned.fill(
      child: IgnorePointer(
        child: SpringValue(
          value: _target,
          spring: AppSpring.snappy,
          builder: (context, centre, _) {
            final offset = centre - widget.length / 2;
            final bar = Container(
              width: horizontal ? widget.length : 2,
              height: horizontal ? 2 : widget.length,
              color: widget.color,
            );
            return Stack(
              children: [
                horizontal
                    ? Positioned(bottom: 0, left: offset, child: bar)
                    : Positioned(left: 0, top: offset, child: bar),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One nav segment. Icon-only when inactive, icon + label when active, with the
/// width change animating — the mechanic that already worked, kept intact.
class _NavSegment extends StatelessWidget {
  const _NavSegment({
    super.key,
    required this.data,
    required this.selected,
    required this.displayName,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tone = selected ? tokens.primary : tokens.textTertiary;

    final Widget glyph = data.kind == _NavKind.avatar
        ? NavAvatar(name: displayName, selected: selected, size: selected ? 22 : 24)
        : Icon(data.icon, color: tone, size: selected ? 20 : 22);

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: PressableScale(
        // A re-tap on the already-active tab still gives press feedback.
        onTap: onTap,
        borderRadius: AppRadius.navBar,
        child: SizedBox(
          height: _navItemHeight,
          child: Center(
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.ease,
              switchOutCurve: AppMotion.ease,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: selected
                  ? Row(
                      key: const ValueKey('selected'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        glyph,
                        const SizedBox(width: AppSpacing.xs + 2),
                        Flexible(
                          child: Text(
                            data.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: AppTypo.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.primary,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ],
                    )
                  : KeyedSubtree(
                      key: const ValueKey('unselected'),
                      child: glyph,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Profile tab's icon is the user's own avatar — initials in a circle,
/// matching the Profile screen's identity block. It's a special case only in
/// its icon source: it gets the same label reveal and needle-mark as the rest.
class NavAvatar extends StatelessWidget {
  const NavAvatar({
    super.key,
    required this.name,
    this.selected = false,
    this.size = 24,
  });

  final String name;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tone = selected ? tokens.primary : tokens.textTertiary;
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tone, width: selected ? 1.4 : 1),
      ),
      child: Text(
        initialsFor(name),
        style: AppTypo.inter(
          fontSize: size * 0.44,
          fontWeight: FontWeight.w600,
          color: tone,
        ),
      ),
    );
  }
}

String initialsFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '—';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

// ─── Desktop / web side rail ────────────────────────────────────────────────

/// At wide window widths the bar becomes a floating left-side vertical rail
/// rather than a mobile bottom bar stretched across a desktop window. Same
/// material, same tick edge, same needle-mark logic, same avatar-as-icon —
/// items stack, the needle runs along the rail's left edge, and labels reveal
/// to the right of the icon on selection.
class _InstrumentRail extends StatelessWidget {
  const _InstrumentRail({
    required this.selectedIndex,
    required this.onSelected,
    required this.displayName,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String displayName;

  static const double _expanded = 168;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: tokens.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl - 1),
          child: SizedBox(
            width: _expanded,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 8,
                  child: TickMarks(
                    axis: Axis.vertical,
                    color: tokens.primary.withValues(alpha: 0.5),
                    count: _navItems.length * 3 + 1,
                    length: 3,
                    majorEvery: 3,
                    majorLength: 6,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _navItems.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _RailSegment(
                            key: navSegmentKey(_navItems[i].label),
                            data: _navItems[i],
                            selected: selectedIndex == i,
                            displayName: displayName,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ),
                _NeedleMark(
                  axis: Axis.vertical,
                  target: _needleCentre(selectedIndex),
                  color: tokens.primary,
                  length: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _needleCentre(int index) {
    const rowHeight = _navItemHeight + AppSpacing.xs;
    return AppSpacing.lg + rowHeight * index + _navItemHeight / 2;
  }
}

class _RailSegment extends StatelessWidget {
  const _RailSegment({
    super.key,
    required this.data,
    required this.selected,
    required this.displayName,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tone = selected ? tokens.primary : tokens.textTertiary;
    final glyph = data.kind == _NavKind.avatar
        ? NavAvatar(name: displayName, selected: selected)
        : Icon(data.icon, color: tone, size: 22);

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: SizedBox(
          height: _navItemHeight,
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.md),
              glyph,
              const SizedBox(width: AppSpacing.md),
              // Labels reveal to the right of the icon on selection.
              Expanded(
                child: AnimatedOpacity(
                  duration: AppMotion.fast,
                  curve: AppMotion.ease,
                  opacity: selected ? 1 : 0.55,
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypo.inter(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: tone,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
