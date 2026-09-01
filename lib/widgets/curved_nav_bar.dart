import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';

/// A navigation destination. The label is no longer rendered, but it is still the
/// accessibility name, so a screen reader announces the destination even though
/// sighted users get the glyph alone.
class NavDestination {
  const NavDestination({required this.label, required this.glyph});

  final String label;
  final AyreGlyph glyph;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(label: 'Home', glyph: AyreGlyph.home),
  NavDestination(label: 'Signals', glyph: AyreGlyph.signals),
  NavDestination(label: 'Insights', glyph: AyreGlyph.insights),
  NavDestination(label: 'Learn', glyph: AyreGlyph.learn),
  NavDestination(label: 'Profile', glyph: AyreGlyph.profile),
];

/// A stable handle on a destination, since there is no label text to find it by.
Key navDestinationKey(String label) => ValueKey('nav-destination-$label');

/// The always-visible bottom navigation.
///
/// The selected destination is a filled circle that rises above the bar's top
/// edge, and the bar's own silhouette curves concavely around it so the circle
/// reads as fused into the bar rather than floating on top. Icons only — no
/// labels in either state.
///
/// **Performance:** the bar, its concave notch and the raised circle are one
/// [CustomPaint] driven by a single animated double, wrapped in a
/// [RepaintBoundary]. Nothing in the widget tree rebuilds as the notch slides;
/// only that one layer repaints. This control is on screen for effectively the
/// whole session, so it has to be cheap.
///
/// **Accessibility trade-off, stated openly:** usability research (Nielsen Norman
/// Group) finds icon-only navigation genuinely harder to comprehend and
/// recommends always-visible labels. Labels are removed here by explicit product
/// direction. The mitigations are: semantic labels for screen readers, long-press
/// tooltips, conventional glyph shapes, and 48dp touch targets.
class CurvedNavBar extends StatefulWidget {
  const CurvedNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Height of the bar itself, excluding the part of the circle that rises above.
  static const double barHeight = 60;

  /// Diameter of the raised circle. Restrained on purpose — a larger circle tips
  /// the control from elegant into goofy.
  static const double circleDiameter = 52;

  /// How far the circle's centre sits above the bar's top edge.
  static const double lift = 16;

  /// Total vertical space the control occupies.
  static double get totalHeight => barHeight + lift + circleDiameter / 2 - 8;

  @override
  State<CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<CurvedNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = widget.selectedIndex.toDouble();
    _to = _from;
    _controller = AnimationController(vsync: this, duration: AppMotion.medium)
      ..value = 1.0;
    // easeOutCubic: the notch and circle decelerate into place together, no
    // overshoot, so the shape never looks springy or playful.
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(CurvedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _from = widget.selectedIndex.toDouble();
      _to = _from;
      _controller.value = 1.0;
      return;
    }
    // Re-target from wherever the notch currently is, so a fast second tap
    // continues the slide rather than jumping back to the previous tab.
    _from = _position;
    _to = widget.selectedIndex.toDouble();
    _controller.forward(from: 0);
  }

  /// The notch's current position, as a fractional destination index.
  double get _position => _from + (_to - _from) * _slide.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding
    // The bar floats clear of the screen edges and above the home indicator.
    (
      padding: EdgeInsets.only(
        left: AppSpace.md,
        right: AppSpace.md,
        bottom: AppSpace.md + bottomInset * 0.5,
      ),
      child: SizedBox(
        height: CurvedNavBar.totalHeight,
        child: Stack(
          children: [
            // One painted layer for the whole silhouette. Isolated so the slide
            // never repaints the icons above it.
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (context, _) => CustomPaint(
                    painter: _NavShapePainter(
                      position: _position,
                      count: kNavDestinations.length,
                      barColor: t.surfaceRaised,
                      circleColor: t.accent,
                      edgeColor: t.border,
                    ),
                  ),
                ),
              ),
            ),
            // The icon row sits above the painted shape and does not animate.
            Positioned.fill(
              child: Row(
                children: [
                  for (var i = 0; i < kNavDestinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        key: navDestinationKey(kNavDestinations[i].label),
                        destination: kNavDestinations[i],
                        selected: i == widget.selectedIndex,
                        onTap: () {
                          if (i == widget.selectedIndex) return;
                          HapticFeedback.selectionClick();
                          widget.onSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the bar, the concave notch and the raised circle as a single path pair.
class _NavShapePainter extends CustomPainter {
  const _NavShapePainter({
    required this.position,
    required this.count,
    required this.barColor,
    required this.circleColor,
    required this.edgeColor,
  });

  /// Fractional destination index the notch is centred on.
  final double position;
  final int count;
  final Color barColor;
  final Color circleColor;
  final Color edgeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;

    const r = CurvedNavBar.circleDiameter / 2;
    final barTop = size.height - CurvedNavBar.barHeight;
    final slotWidth = size.width / count;
    final cx = slotWidth * (position + 0.5);
    // The circle's centre rides above the bar's top edge.
    final cy = barTop - CurvedNavBar.lift + r - 8;

    // How wide the concave dip is. Wider than the circle so the curve eases into
    // the bar's edge rather than meeting it at a corner.
    final dip = r * 1.85;
    final depth = r + CurvedNavBar.lift - 14;

    final bar = Path()..moveTo(0, barTop + AppRadius.dock);
    // Leading rounded end.
    bar.quadraticBezierTo(0, barTop, AppRadius.dock, barTop);

    // Flat run up to the dip, then a symmetric concave sweep under the circle.
    bar.lineTo(cx - dip, barTop);
    bar.cubicTo(
      cx - dip * 0.42,
      barTop,
      cx - dip * 0.60,
      barTop + depth,
      cx,
      barTop + depth,
    );
    bar.cubicTo(
      cx + dip * 0.60,
      barTop + depth,
      cx + dip * 0.42,
      barTop,
      cx + dip,
      barTop,
    );

    // Trailing rounded end and the bar's body.
    bar.lineTo(size.width - AppRadius.dock, barTop);
    bar.quadraticBezierTo(
      size.width,
      barTop,
      size.width,
      barTop + AppRadius.dock,
    );
    bar.lineTo(size.width, size.height - AppRadius.dock);
    bar.quadraticBezierTo(
      size.width,
      size.height,
      size.width - AppRadius.dock,
      size.height,
    );
    bar.lineTo(AppRadius.dock, size.height);
    bar.quadraticBezierTo(0, size.height, 0, size.height - AppRadius.dock);
    bar.close();

    canvas.drawPath(bar, Paint()..color = barColor);
    canvas.drawPath(
      bar,
      Paint()
        ..color = edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // The raised circle, drawn last so it sits over the notch's lip.
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = circleColor);
  }

  @override
  bool shouldRepaint(covariant _NavShapePainter old) {
    return old.position != position ||
        old.count != count ||
        old.barColor != barColor ||
        old.circleColor != circleColor ||
        old.edgeColor != edgeColor;
  }
}

/// One destination's tap target and glyph. Deliberately stateless and cheap: the
/// notch animation happens entirely in the painted layer underneath.
class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const r = CurvedNavBar.circleDiameter / 2;
    final barTop = CurvedNavBar.totalHeight - CurvedNavBar.barHeight;
    // Match the painter, so the glyph lands in the circle when selected and in
    // the bar's centre when not.
    final selectedCentre = barTop - CurvedNavBar.lift + r - 8;
    final restingCentre = barTop + CurvedNavBar.barHeight / 2;

    return Semantics(
      button: true,
      selected: selected,
      // The label is gone from the screen but not from the accessibility tree.
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        preferBelow: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            children: [
              // A full-height target: the glyph is ~22pt but the tappable area
              // comfortably clears the 48dp minimum in both dimensions.
              const Positioned.fill(child: SizedBox.expand()),
              Positioned(
                left: 0,
                right: 0,
                top: (selected ? selectedCentre : restingCentre) - 12,
                child: Center(
                  child: AyreIcon(
                    destination.glyph,
                    size: 22,
                    // Filled on select, line at rest — the one icon state rule.
                    filled: selected,
                    color: selected ? t.onAccent : t.textTertiary,
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
