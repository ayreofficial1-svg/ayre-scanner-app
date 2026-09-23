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
          strokeWidth: strokeWidth ?? (filled ? 2.1 : 1.7),
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
        // v8 rework: dropped the eaved roofline for a plain five-point house
        // — apex, two roof/wall shoulders, two base corners — closer to the
        // reference bar's plain, blocky house than the overhanging roof this
        // used to be. Fewer corners, one closed path, stroked with a miter
        // join so outline and fill trace exactly the same silhouette.
        {
          final house = Path()
            ..moveTo(12, 4) // apex
            ..lineTo(19, 10.5) // right shoulder — roof meets wall
            ..lineTo(19, 20) // base, right
            ..lineTo(5, 20) // base, left
            ..lineTo(5, 10.5) // left shoulder
            ..close();
          if (filled) {
            c.drawPath(house, f);
          } else {
            c.drawPath(house, _miterStroke(s));
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
        // v8 rework: dropped the small companion spark that used to sit
        // bottom-right of the main one — a single, larger four-point
        // sparkle reads cleaner at nav size and keeps this set to the
        // reference bar's one-shape-per-icon simplicity. Cusps stay stroked
        // with a miter join so the points stay sharp outline or filled.
        {
          Path sparkPath(Offset center, double r) => Path()
            ..moveTo(center.dx, center.dy - r)
            ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
            ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
            ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
            ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
            ..close();
          final star = sparkPath(const Offset(12, 12), 8.5);
          if (filled) {
            c.drawPath(star, f);
          } else {
            c.drawPath(star, _miterStroke(s));
          }
        }
      case AyreGlyph.learn:
        // v8 rework: replaced the ruled document (a rect plus three content
        // lines) with a plain folded-corner page — the universal "document"
        // mark, one dog-eared rectangle rather than a rect-plus-lines
        // composite. Bolder and simpler, and it removes the one glyph most
        // exposed to a stray misalignment between stroked lines and their
        // punched-through filled counterparts.
        {
          final page = Path()
            ..moveTo(6, 3)
            ..lineTo(15, 3)
            ..lineTo(19, 7)
            ..lineTo(19, 21)
            ..lineTo(6, 21)
            ..close();
          final crease = Path()
            ..moveTo(15, 3)
            ..lineTo(15, 7)
            ..lineTo(19, 7);
          if (filled) {
            c.saveLayer(page.getBounds().inflate(4), Paint());
            c.drawPath(page, f);
            final punch = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.miter
              ..blendMode = BlendMode.clear;
            c.drawPath(crease, punch);
            c.restore();
          } else {
            final line = _miterStroke(s);
            c.drawPath(page, line);
            c.drawPath(crease, line);
          }
        }
      case AyreGlyph.profile:
        // v8 rework: bumped the head and shoulder proportions up (bigger
        // head, wider shoulders) for a bolder mark closer to the reference
        // bar's person icon. Keeps v7's fix of sharing one path's footprint
        // between outline and filled — the outline strokes it open (no
        // floor edge), the filled state is the same path with one closing
        // edge added — so selecting the tab still never changes its extent.
        {
          const headCenter = Offset(12, 8.6);
          const headRadius = 3.9;
          final shoulders = Path()
            ..moveTo(4.8, 24)
            ..lineTo(4.8, 19.8)
            ..cubicTo(6, 15.6, 8.8, 14.4, 12, 14.4)
            ..cubicTo(15.2, 14.4, 18, 15.6, 19.2, 19.8)
            ..lineTo(19.2, 24);
          if (filled) {
            c.drawCircle(headCenter, headRadius, f);
            c.drawPath(Path.from(shoulders)..close(), f);
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
        // A crescent as one closed path: the outer disc's arc, returned along
        // a second, offset arc. Drawn rather than punched out with a
        // difference operation so it paints identically stroked or filled.
        {
          final crescent = Path()
            ..moveTo(19.2, 14.6)
            ..arcToPoint(
              const Offset(9.4, 4.8),
              radius: const Radius.circular(8.2),
              clockwise: false,
            )
            ..arcToPoint(
              const Offset(19.2, 14.6),
              radius: const Radius.circular(10.4),
              clockwise: false,
            )
            ..close();
          c.drawPath(crescent, filled ? f : s);
        }
      case AyreGlyph.sun:
        if (filled) {
          c.drawCircle(const Offset(12, 12), 4.6, f);
        } else {
          c.drawCircle(const Offset(12, 12), 4.6, s);
        }
        // Eight rays on the 45° diagonals and the cardinals, drawn from a
        // common inset so they read as one ring rather than eight lines.
        for (var i = 0; i < 8; i++) {
          final angle = i * 3.14159265 / 4;
          final dx = math.cos(angle);
          final dy = math.sin(angle);
          c.drawLine(
            Offset(12 + dx * 7.4, 12 + dy * 7.4),
            Offset(12 + dx * 9.6, 12 + dy * 9.6),
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
  });

  final bool up;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CaretPainter(up: up, color: color),
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
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
      old.up != up || old.color != color;
}