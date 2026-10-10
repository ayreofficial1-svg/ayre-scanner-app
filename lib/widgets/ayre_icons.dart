import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ayre's icon vocabulary — drawn for this identity rather than pulled from a
/// stock library, because a mixed-provenance icon set is one of the clearest
/// tells of a templated app.
///
/// Every glyph is built on the same 24pt keyline grid with the same stroke
/// weight, the same square-ish cap treatment and the same corner radius, so the
/// set reads as one family cut from one die. Icons are line-based at rest; a
/// small number gain a solid variant used *only* to mark an active/selected
/// state (most visibly in the bottom nav — filled-on-select, line-at-rest is
/// the one state rule used everywhere an icon has a selected condition).
///
/// **v4 redraw vs. reuse (plan §7 open decision #1):** the three nav glyphs
/// that read as distinctly "terminal" against the calm/editorial identity
/// — [AyreGlyph.home] (was a literal terminal-window frame), [AyreGlyph.signals]
/// (was blocky ascending bars) and [AyreGlyph.insights] (was a literal breadth-
/// meter scale, i.e. themed screen content leaking into the icon) — were
/// redrawn to match lucide's `House`/`Radio`/`Sparkles` silhouettes.
/// [AyreGlyph.learn] and [AyreGlyph.profile] were judged close enough to
/// lucide's `BookOpen`/`CircleUserRound` already (a document face, a rounded
/// head-and-shoulders mark) and were left as-is — this was a mixed decision,
/// not an all-or-nothing set replacement. Every other glyph in this file is a
/// chrome/status/settings icon the Spec doesn't name explicitly, so those are
/// unchanged.
enum AyreGlyph {
  // Navigation
  home,
  signals,
  insights,
  learn,
  profile,

  /// A report page with three ascending bars — the Reports tab's glyph.
  /// Added with the Reports tab; [signals] stays (other surfaces use it).
  report,

  // Header and chrome
  bell,
  back,
  forward,
  close,
  search,
  sort,
  filter,
  copy,
  edit,
  lock,
  check,
  refresh,

  // Market and data
  trendUp,
  trendDown,
  live,
  instrument,
  equity,

  /// A pedimented bank facade — roofline, three columns, base. New in
  /// Phase 3: the Bank Nifty index card's glyph (v5 §2.1 / §2A index-card
  /// table); no existing glyph reads as a bank.
  bank,

  // Status
  disconnected,
  empty,
  offline,
  delayed,

  // Settings and profile
  alerts,
  appearance,

  /// The Home theme toggle's two faces (Spec §13.1). New in Phase 5 —
  /// `appearance` is a half-filled contrast disc, correct for a Settings row
  /// labelled "Appearance" but wrong for a control whose whole job is to show
  /// which mode you're in at a glance. Drawn to lucide's `Moon`/`Sun`
  /// silhouettes, matching the geometry decision recorded for the nav glyphs
  /// in plan §7 open decision #1.
  moon,
  sun,
  account,
  about,
  signOut,
  support,
  course,
}

/// Renders an [AyreGlyph] at [size] on the shared keyline grid.
class AyreIcon extends StatelessWidget {
  const AyreIcon(
    this.glyph, {
    super.key,
    this.size = 20,
    this.color,
    this.filled = false,
    this.strokeWidth,
    this.semanticLabel,
  });

  final AyreGlyph glyph;
  final double size;
  final Color? color;

  /// The solid variant, reserved for active/selected states.
  final bool filled;

  /// Defaults per Spec §10's stroke-weight rule: 1.7 for a line-at-rest
  /// (inactive) glyph, 2.1 when [filled] marks it active/selected — never
  /// mixed within one group. Pass an explicit value only to opt out of this
  /// default (e.g. a decorative one-off that isn't part of a state pair).
  final double? strokeWidth;

  final String? semanticLabel;

  /// The grid every glyph is drawn against.
  static const double grid = 24;

  /// The five navigation glyphs keep one outline weight in both states (the
  /// selected form is the same silhouette made solid); every other glyph keeps
  /// the 1.7 / 2.1 rule.
  static const double navStroke = 1.75;

  static const Set<AyreGlyph> _navGlyphs = {
    AyreGlyph.home,
    AyreGlyph.report,
    AyreGlyph.insights,
    AyreGlyph.learn,
    AyreGlyph.profile,
  };

  static double _defaultStroke(AyreGlyph glyph, bool filled) {
    if (_navGlyphs.contains(glyph)) return navStroke;
    return filled ? 2.1 : 1.7;
  }

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    final icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AyreIconPainter(
          glyph: glyph,
          color: resolved,
          filled: filled,
          strokeWidth: strokeWidth ?? _defaultStroke(glyph, filled),
        ),
      ),
    );
    if (semanticLabel == null) return icon;
    return Semantics(label: semanticLabel, child: icon);
  }
}

class _AyreIconPainter extends CustomPainter {
  const _AyreIconPainter({
    required this.glyph,
    required this.color,
    required this.filled,
    required this.strokeWidth,
  });

  final AyreGlyph glyph;
  final Color color;
  final bool filled;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw everything on the 24pt grid, then scale to the requested size, so
    // stroke weight and geometry stay proportional at every size.
    final scale = size.shortestSide / AyreIcon.grid;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    _draw(canvas, stroke, fill);
    canvas.restore();
  }

  void _draw(Canvas c, Paint s, Paint f) {
    switch (glyph) {
      // ── Navigation ─────────────────────────────────────────────────────────
      case AyreGlyph.home:
        // Rounded house with a door; selected = the same silhouette, solid,
        // door knocked out. Live area 20pt (2pt padding on the 24pt grid).
        {
          final house = _roundedPolygon(const [
            Offset(12, 3.6),
            Offset(20.4, 10.4),
            Offset(20.4, 20.4),
            Offset(3.6, 20.4),
            Offset(3.6, 10.4),
          ], 2.2);
          if (filled) {
            _solidWithKnockout(
              c,
              s,
              f,
              house,
              fills: [
                Path()..addRRect(
                  RRect.fromRectAndRadius(
                    const Rect.fromLTRB(9.4, 14.8, 14.6, 23),
                    const Radius.circular(1.6),
                  ),
                ),
              ],
            );
          } else {
            c.drawPath(house, s);
            c.drawPath(
              Path()
                ..moveTo(9.4, 20.4)
                ..lineTo(9.4, 16.4)
                ..quadraticBezierTo(9.4, 14.8, 11, 14.8)
                ..lineTo(13, 14.8)
                ..quadraticBezierTo(14.6, 14.8, 14.6, 16.4)
                ..lineTo(14.6, 20.4),
              s,
            );
          }
        }
      case AyreGlyph.signals:
        // v8 rework: replaced the radio/pulse arcs with a plain bolt. The
        // arcs were open strokes with no honest "filled" state of their own
        // (selecting the tab could only thicken them, never really light
        // up) — a closed silhouette carries the same weight every other nav
        // glyph does when active, and reads as a bolder, simpler mark, in
        // keeping with the reference bar's plain pictograms.
        {
          final bolt = Path()
            ..moveTo(13.5, 3)
            ..lineTo(7, 13)
            ..lineTo(11.3, 13)
            ..lineTo(10, 21)
            ..lineTo(17.5, 10.3)
            ..lineTo(12.6, 10.3)
            ..close();
          if (filled) {
            c.drawPath(bolt, f);
          } else {
            c.drawPath(bolt, _miterStroke(s));
          }
        }
      case AyreGlyph.insights:
        // Line chart: L-axes, a rising polyline ending in a node. Selected =
        // solid rounded square with the polyline and node knocked out.
        {
          final line = Path()
            ..moveTo(7.6, 16)
            ..lineTo(11.4, 11.6)
            ..lineTo(14.4, 14.2)
            ..lineTo(18.4, 8.2);
          if (filled) {
            _solidWithKnockout(
              c,
              s,
              f,
              Path()..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(3.6, 3.6, 20.4, 20.4),
                  const Radius.circular(3.2),
                ),
              ),
              strokes: [line],
              fills: [Path()..addOval(Rect.fromCircle(center: const Offset(18.4, 8.2), radius: 1.9))],
            );
          } else {
            c.drawPath(
              Path()
                ..moveTo(3.6, 3.6)
                ..lineTo(3.6, 18.4)
                ..quadraticBezierTo(3.6, 20.4, 5.6, 20.4)
                ..lineTo(20.4, 20.4),
              s,
            );
            c.drawPath(line, s);
            c.drawCircle(const Offset(18.4, 8.2), 1.9, f);
          }
        }
      case AyreGlyph.learn:
        // Open book: two pages and a spine. Selected = solid book, spine
        // knocked out.
        {
          final book = Path()
            ..moveTo(12, 6.6)
            ..cubicTo(9.6, 4.6, 6.6, 4.2, 3.6, 4.8)
            ..lineTo(3.6, 18.6)
            ..cubicTo(6.6, 18.1, 9.6, 18.5, 12, 20.4)
            ..cubicTo(14.4, 18.5, 17.4, 18.1, 20.4, 18.6)
            ..lineTo(20.4, 4.8)
            ..cubicTo(17.4, 4.2, 14.4, 4.6, 12, 6.6)
            ..close();
          final spine = Path()
            ..moveTo(12, 6.6)
            ..lineTo(12, 20.4);
          if (filled) {
            _solidWithKnockout(c, s, f, book, strokes: [spine]);
          } else {
            c.drawPath(book, s);
            c.drawPath(spine, s);
          }
        }
      case AyreGlyph.report:
        // Portrait sheet with three ascending bars. Selected = solid sheet,
        // bars knocked out.
        {
          final sheet = Path()..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTRB(4.6, 3.6, 19.4, 20.4),
              const Radius.circular(2.6),
            ),
          );
          final bars = Path()
            ..moveTo(9, 16.4)
            ..lineTo(9, 13.4)
            ..moveTo(12, 16.4)
            ..lineTo(12, 10.8)
            ..moveTo(15, 16.4)
            ..lineTo(15, 8);
          if (filled) {
            _solidWithKnockout(c, s, f, sheet, strokes: [bars]);
          } else {
            c.drawPath(sheet, s);
            c.drawPath(bars, s);
          }
        }
      case AyreGlyph.profile:
        // Head and shoulders, fully inside the grid (base at y = 20). Selected
        // = solid head and solid shoulders with a flat base.
        {
          const headCenter = Offset(12, 8);
          const headRadius = 3.8;
          final shoulders = Path()
            ..moveTo(4.6, 20)
            ..cubicTo(4.6, 16, 7.8, 14, 12, 14)
            ..cubicTo(16.2, 14, 19.4, 16, 19.4, 20);
          if (filled) {
            c.drawCircle(headCenter, headRadius, f);
            c.drawCircle(headCenter, headRadius, s);
            final body = Path.from(shoulders)..close();
            c.drawPath(body, f);
            c.drawPath(body, s);
          } else {
            c.drawCircle(headCenter, headRadius, s);
            c.drawPath(shoulders, s);
          }
        }

      // ── Header and chrome ──────────────────────────────────────────────────
      case AyreGlyph.bell:
        final path = Path()
          ..moveTo(6.5, 16.5)
          ..lineTo(6.5, 10.5)
          ..cubicTo(6.5, 7.2, 8.9, 5, 12, 5)
          ..cubicTo(15.1, 5, 17.5, 7.2, 17.5, 10.5)
          ..lineTo(17.5, 16.5)
          ..close();
        if (filled) {
          c.drawPath(path, f);
        } else {
          c.drawPath(path, s);
        }
        c.drawLine(const Offset(4.5, 16.5), const Offset(19.5, 16.5), s);
        c.drawLine(const Offset(10.5, 19.5), const Offset(13.5, 19.5), s);
      case AyreGlyph.back:
        _chevron(c, s, 14, -1);
      case AyreGlyph.forward:
        _chevron(c, s, 10, 1);
      case AyreGlyph.close:
        c.drawLine(const Offset(6.5, 6.5), const Offset(17.5, 17.5), s);
        c.drawLine(const Offset(17.5, 6.5), const Offset(6.5, 17.5), s);
      case AyreGlyph.search:
        c.drawCircle(const Offset(11, 11), 5.5, s);
        c.drawLine(const Offset(15.2, 15.2), const Offset(19, 19), s);
      case AyreGlyph.sort:
        c.drawLine(const Offset(5, 7), const Offset(15, 7), s);
        c.drawLine(const Offset(5, 12), const Offset(12, 12), s);
        c.drawLine(const Offset(5, 17), const Offset(9, 17), s);
        c.drawLine(const Offset(17.5, 6), const Offset(17.5, 18), s);
        c.drawPath(
          Path()
            ..moveTo(15, 15.5)
            ..lineTo(17.5, 18)
            ..lineTo(20, 15.5),
          s,
        );
      case AyreGlyph.filter:
        c.drawLine(const Offset(4.5, 7.5), const Offset(19.5, 7.5), s);
        c.drawLine(const Offset(7, 12), const Offset(17, 12), s);
        c.drawLine(const Offset(10, 16.5), const Offset(14, 16.5), s);
      case AyreGlyph.copy:
        _rect(c, s, f, 4, 4, 12, 12, r: 2, forceStroke: true);
        _rect(c, s, f, 8, 8, 12, 12, r: 2, forceStroke: true);
      case AyreGlyph.edit:
        c.drawPath(
          Path()
            ..moveTo(5, 19)
            ..lineTo(5, 15.5)
            ..lineTo(15.5, 5)
            ..lineTo(19, 8.5)
            ..lineTo(8.5, 19)
            ..close(),
          s,
        );
      case AyreGlyph.lock:
        _rect(c, s, f, 5.5, 10.5, 13, 9, r: 1.5, forceStroke: true);
        c.drawPath(
          Path()
            ..moveTo(8.5, 10.5)
            ..lineTo(8.5, 8)
            ..cubicTo(8.5, 5.8, 10, 4.5, 12, 4.5)
            ..cubicTo(14, 4.5, 15.5, 5.8, 15.5, 8)
            ..lineTo(15.5, 10.5),
          s,
        );
      case AyreGlyph.check:
        c.drawPath(
          Path()
            ..moveTo(5.5, 12.5)
            ..lineTo(10, 17)
            ..lineTo(18.5, 7.5),
          s,
        );
      case AyreGlyph.refresh:
        c.drawArc(
          Rect.fromCircle(center: const Offset(12, 12), radius: 6.8),
          -math.pi / 2,
          math.pi * 1.5,
          false,
          s,
        );
        c.drawPath(
          Path()
            ..moveTo(9.4, 3.4)
            ..lineTo(12, 5.2)
            ..lineTo(9.4, 7.6),
          s,
        );

      // ── Market and data ────────────────────────────────────────────────────
      case AyreGlyph.trendUp:
        c.drawPath(
          Path()
            ..moveTo(5, 16.5)
            ..lineTo(10, 11.5)
            ..lineTo(13.5, 15)
            ..lineTo(19, 8),
          s,
        );
        c.drawPath(
          Path()
            ..moveTo(14.5, 8)
            ..lineTo(19, 8)
            ..lineTo(19, 12.5),
          s,
        );
      case AyreGlyph.trendDown:
        c.drawPath(
          Path()
            ..moveTo(5, 7.5)
            ..lineTo(10, 12.5)
            ..lineTo(13.5, 9)
            ..lineTo(19, 16),
          s,
        );
        c.drawPath(
          Path()
            ..moveTo(14.5, 16)
            ..lineTo(19, 16)
            ..lineTo(19, 11.5),
          s,
        );
      case AyreGlyph.live:
        c.drawCircle(const Offset(12, 12), 3.4, f);
        if (!filled) c.drawCircle(const Offset(12, 12), 7.2, s);
      case AyreGlyph.instrument:
        // A composite instrument: a scale with three plotted marks.
        c.drawLine(const Offset(4, 19), const Offset(20, 19), s);
        c.drawLine(const Offset(4, 19), const Offset(4, 5), s);
        _bars(
          c,
          s,
          f,
          const [8.0, 12.5, 17.0],
          const [14.0, 9.0, 11.5],
          baseline: 19,
          width: 2.6,
          forceFill: true,
        );
      case AyreGlyph.equity:
        _rect(c, s, f, 4, 4, 16, 16, r: 2, forceStroke: true);
        c.drawPath(
          Path()
            ..moveTo(7.5, 15)
            ..lineTo(11, 11)
            ..lineTo(13.5, 13.5)
            ..lineTo(16.5, 9),
          s,
        );

      case AyreGlyph.bank:
        {
          final roof = Path()
            ..moveTo(3.5, 9.5)
            ..lineTo(12, 4.5)
            ..lineTo(20.5, 9.5)
            ..close();
          c.drawPath(roof, filled ? f : s);
        }
        for (final x in const [7.5, 12.0, 16.5]) {
          c.drawLine(Offset(x, 12.5), Offset(x, 17), s);
        }
        c.drawLine(const Offset(4, 19.5), const Offset(20, 19.5), s);

      // ── Status ─────────────────────────────────────────────────────────────
      case AyreGlyph.disconnected:
        // A broken/interrupted line — the distinct failure glyph, deliberately
        // different from the calm "empty" glyph.
        c.drawLine(const Offset(3.5, 12), const Offset(9, 12), s);
        c.drawLine(const Offset(15, 12), const Offset(20.5, 12), s);
        c.drawLine(const Offset(10.5, 7.5), const Offset(13.5, 16.5), s);
      case AyreGlyph.empty:
        // A calm, complete outline with nothing in it.
        _rect(c, s, f, 4, 6, 16, 12, r: 2, forceStroke: true);
        c.drawLine(const Offset(8, 12), const Offset(16, 12), s);
      case AyreGlyph.offline:
        c.drawArc(
          Rect.fromCircle(center: const Offset(12, 15), radius: 9),
          -math.pi * 0.85,
          math.pi * 0.7,
          false,
          s,
        );
        c.drawCircle(const Offset(12, 15), 1.8, f);
        c.drawLine(const Offset(5.5, 5.5), const Offset(18.5, 18.5), s);
      case AyreGlyph.delayed:
        c.drawCircle(const Offset(12, 12), 7.5, s);
        c.drawPath(
          Path()
            ..moveTo(12, 7.5)
            ..lineTo(12, 12)
            ..lineTo(15.5, 14),
          s,
        );

      // ── Settings and profile ───────────────────────────────────────────────
      case AyreGlyph.alerts:
        c.drawLine(const Offset(4, 12), const Offset(8, 12), s);
        c.drawPath(
          Path()
            ..moveTo(8, 12)
            ..lineTo(10.5, 6)
            ..lineTo(13.5, 18)
            ..lineTo(16, 12)
            ..lineTo(20, 12),
          s,
        );
      case AyreGlyph.appearance:
        c.drawCircle(const Offset(12, 12), 7.2, s);
        c.drawPath(
          Path()
            ..moveTo(12, 4.8)
            ..arcToPoint(
              const Offset(12, 19.2),
              radius: const Radius.circular(7.2),
            )
            ..close(),
          f,
        );
      case AyreGlyph.moon:
        // A standard crescent moon: a disc with a smaller, offset disc
        // subtracted from it — the conventional "dark mode" glyph. This
        // replaces the old two-arc lens shape, which read as a leaf/almond
        // rather than a crescent. Sized to match the sun glyph's footprint
        // (its rays reach the same ~8.6 radius) so the pair looks like one
        // consistent family.
        {
          final outer = Path()
            ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 7.6));
          final bite = Path()
            ..addOval(
              Rect.fromCircle(center: const Offset(15.4, 8.6), radius: 6.6),
            );
          final crescent = Path.combine(PathOperation.difference, outer, bite);
          c.drawPath(crescent, filled ? f : s);
        }
      case AyreGlyph.sun:
        // A plain, standard sun mark — solid core plus eight short rays
        // touching its edge — the conventional "light mode" glyph, drawn to
        // read unambiguously as a sun (not a leaf/flower) at nav/button size.
        if (filled) {
          c.drawCircle(const Offset(12, 12), 4.2, f);
        } else {
          c.drawCircle(const Offset(12, 12), 4.2, s);
        }
        // Eight rays on the cardinals and diagonals, started right at the
        // core's edge so each ray reads as connected to the sun rather than
        // as a separate petal-like mark floating beside it.
        for (var i = 0; i < 8; i++) {
          final angle = i * 3.14159265 / 4;
          final dx = math.cos(angle);
          final dy = math.sin(angle);
          c.drawLine(
            Offset(12 + dx * 5.6, 12 + dy * 5.6),
            Offset(12 + dx * 8.6, 12 + dy * 8.6),
            s,
          );
        }
      case AyreGlyph.account:
        _rect(c, s, f, 3.5, 6, 17, 12, r: 2, forceStroke: true);
        c.drawLine(const Offset(3.5, 10), const Offset(20.5, 10), s);
        c.drawLine(const Offset(7, 14.5), const Offset(11, 14.5), s);
      case AyreGlyph.about:
        c.drawCircle(const Offset(12, 12), 7.5, s);
        c.drawLine(const Offset(12, 11), const Offset(12, 16), s);
        c.drawCircle(const Offset(12, 8.2), 0.9, f);
      case AyreGlyph.signOut:
        c.drawPath(
          Path()
            ..moveTo(13, 5)
            ..lineTo(6, 5)
            ..lineTo(6, 19)
            ..lineTo(13, 19),
          s,
        );
        c.drawLine(const Offset(10.5, 12), const Offset(20, 12), s);
        c.drawPath(
          Path()
            ..moveTo(17, 8.5)
            ..lineTo(20.5, 12)
            ..lineTo(17, 15.5),
          s,
        );
      case AyreGlyph.support:
        c.drawCircle(const Offset(12, 12), 7.5, s);
        c.drawPath(
          Path()
            ..moveTo(9.5, 9.5)
            ..cubicTo(9.5, 7.6, 10.6, 6.8, 12, 6.8)
            ..cubicTo(13.6, 6.8, 14.6, 7.8, 14.6, 9.3)
            ..cubicTo(14.6, 11, 12.9, 11.4, 12.4, 12.4)
            ..lineTo(12, 13.8),
          s,
        );
        c.drawCircle(const Offset(12, 16.6), 0.9, f);
      case AyreGlyph.course:
        _rect(c, s, f, 4, 5, 16, 14, r: 2, forceStroke: true);
        c.drawLine(const Offset(4, 15.5), const Offset(20, 15.5), s);
        c.drawRect(const Rect.fromLTRB(4, 15.5, 13, 19), f);
    }
  }

  void _rect(
    Canvas c,
    Paint s,
    Paint f,
    double l,
    double t,
    double w,
    double h, {
    double r = 2,
    bool forceStroke = false,
  }) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(l, t, w, h),
      Radius.circular(r),
    );
    if (filled && !forceStroke) {
      c.drawRRect(rect, f);
    } else {
      c.drawRRect(rect, s);
    }
  }

  /// A closed polygon with every corner rounded by [radius] (quadratic
  /// corners), used by the nav glyphs so corners match across the set.
  Path _roundedPolygon(List<Offset> points, double radius) {
    final path = Path();
    final n = points.length;
    for (var i = 0; i < n; i++) {
      final prev = points[(i - 1 + n) % n];
      final cur = points[i];
      final next = points[(i + 1) % n];
      final toPrev = prev - cur;
      final toNext = next - cur;
      final r1 = math.min(radius, toPrev.distance / 2);
      final r2 = math.min(radius, toNext.distance / 2);
      final start = cur + toPrev / toPrev.distance * r1;
      final end = cur + toNext / toNext.distance * r2;
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, end.dx, end.dy);
    }
    return path..close();
  }

  /// The selected form of a nav glyph: the outline's own silhouette made solid
  /// (fill + the same stroke, so the optical size is identical to the line
  /// form), with detail [strokes] and [fills] cleared out of it.
  void _solidWithKnockout(
    Canvas c,
    Paint s,
    Paint f,
    Path body, {
    List<Path> strokes = const [],
    List<Path> fills = const [],
  }) {
    c.saveLayer(body.getBounds().inflate(4), Paint());
    c.drawPath(body, f);
    c.drawPath(body, s);
    final clearStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.clear;
    final clearFill = Paint()..blendMode = BlendMode.clear;
    for (final path in strokes) {
      c.drawPath(path, clearStroke);
    }
    for (final path in fills) {
      c.drawPath(path, clearFill);
    }
    c.restore();
  }

  /// A copy of the given stroke paint with a miter join instead of this
  /// file's default round join. Used for the handful of glyphs (the house's
  /// eave/floor corners, the sparkle's cusps) whose outline is one closed
  /// path shared with its filled twin: a round join would visibly bulge or
  /// soften those corners relative to the filled version's sharp ones, which
  /// is exactly the "shape changes on selection" artifact single-path
  /// sharing is meant to eliminate.
  Paint _miterStroke(Paint base) => Paint()
    ..color = base.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = base.strokeWidth
    ..strokeCap = base.strokeCap
    ..strokeJoin = StrokeJoin.miter
    ..strokeMiterLimit = 4;

  void _chevron(Canvas c, Paint s, double x, int direction) {
    c.drawPath(
      Path()
        ..moveTo(x, 6)
        ..lineTo(x + 5.5 * direction, 12)
        ..lineTo(x, 18),
      s,
    );
  }

  void _bars(
    Canvas c,
    Paint s,
    Paint f,
    List<double> xs,
    List<double> tops, {
    double baseline = 19,
    double width = 3.0,
    bool forceFill = false,
  }) {
    for (var i = 0; i < xs.length; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(xs[i] - width / 2, tops[i], xs[i] + width / 2, baseline),
        const Radius.circular(1),
      );
      if (filled || forceFill) {
        c.drawRRect(rect, f);
      } else {
        c.drawRRect(rect, s);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AyreIconPainter old) {
    return old.glyph != glyph ||
        old.color != color ||
        old.filled != filled ||
        old.strokeWidth != strokeWidth;
  }
}

/// Directional glyph for a signed market value. Kept as its own widget so the
/// gain/loss glyph rule (color is never the only channel) is applied in exactly
/// one place.
class DirectionGlyph extends StatelessWidget {
  const DirectionGlyph({
    super.key,
    required this.up,
    required this.color,
    this.size = 14,
    this.flat = false,
  });

  final bool up;
  final Color color;
  final double size;

  /// D-6: an unchanged reading draws a flat bar instead of a caret.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CaretPainter(up: up, color: color, flat: flat),
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter({
    required this.up,
    required this.color,
    this.flat = false,
  });

  final bool up;
  final Color color;
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (flat) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.14, h * 0.5 - h * 0.09, w * 0.72, h * 0.18),
          Radius.circular(h * 0.09),
        ),
        Paint()..color = color,
      );
      return;
    }
    final path = Path();
    if (up) {
      path
        ..moveTo(w * 0.5, h * 0.24)
        ..lineTo(w * 0.86, h * 0.72)
        ..lineTo(w * 0.14, h * 0.72)
        ..close();
    } else {
      path
        ..moveTo(w * 0.5, h * 0.76)
        ..lineTo(w * 0.86, h * 0.28)
        ..lineTo(w * 0.14, h * 0.28)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter old) =>
      old.up != up || old.color != color || old.flat != flat;
}