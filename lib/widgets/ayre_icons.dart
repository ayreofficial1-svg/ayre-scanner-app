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
/// that read as distinctly "terminal" against the calm/editorial v4 identity
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

  // Status
  disconnected,
  empty,
  offline,
  delayed,

  // Settings and profile
  alerts,
  appearance,
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
        // v4 redraw (plan §7 open decision #1): the v3 path drew a literal
        // terminal window (framed panel + header rule + prompt-cursor tick)
        // — the single most "terminal" glyph in the old set, and the one
        // most visible since it's the first nav item. Replaced with a plain
        // roofline pictogram (a peaked roof over a simple house body, no
        // door/window detail) to match lucide's `House` silhouette and the
        // calm/rounded reading the rest of the set already has.
        {
          final roof = Path()
            ..moveTo(3.5, 11.5)
            ..lineTo(12, 4)
            ..lineTo(20.5, 11.5);
          c.drawPath(roof, s);
          if (filled) {
            final body = Path()
              ..moveTo(6, 10.5)
              ..lineTo(6, 19.5)
              ..lineTo(18, 19.5)
              ..lineTo(18, 10.5)
              ..lineTo(12, 5.5)
              ..close();
            c.drawPath(body, f);
          } else {
            c.drawLine(const Offset(6, 10.5), const Offset(6, 19.5), s);
            c.drawLine(const Offset(18, 10.5), const Offset(18, 19.5), s);
            c.drawLine(const Offset(6, 19.5), const Offset(18, 19.5), s);
          }
        }
      case AyreGlyph.signals:
        // v4 redraw (plan §7 open decision #1): the v3 path was ascending
        // bar-chart bars — sharp, blocky, and closer to a generic analytics
        // icon than a "signal". Replaced with a soft radiating-arcs mark
        // (a dot with two concentric open arcs) matching lucide's `Radio`
        // silhouette — reads as "broadcast/pulse" rather than "chart".
        {
          c.drawCircle(const Offset(7, 17), 1.8, f);
          c.drawArc(
            Rect.fromCircle(center: const Offset(7, 17), radius: 6.2),
            math.pi * 1.05,
            math.pi * 0.9,
            false,
            s,
          );
          c.drawArc(
            Rect.fromCircle(center: const Offset(7, 17), radius: 10.4),
            math.pi * 1.12,
            math.pi * 0.76,
            false,
            s,
          );
        }
      case AyreGlyph.insights:
        // v4 redraw (plan §7 open decision #1): the v3 path was a literal
        // breadth-meter scale-with-marker — themed content (what the
        // Insights tab's data viz shows) leaking into the icon, rather than
        // a neutral pictogram for the destination. Replaced with a simple
        // four-point sparkle/spark mark, matching lucide's `Sparkles`
        // silhouette used for "insights/highlights" wayfinding.
        {
          Path sparkPath(Offset center, double r) => Path()
            ..moveTo(center.dx, center.dy - r)
            ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
            ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
            ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
            ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
            ..close();

          final big = sparkPath(const Offset(12, 11), 6.5);
          final small = sparkPath(const Offset(18.5, 18.5), 2.6);
          if (filled) {
            c.drawPath(big, f);
            c.drawPath(small, f);
          } else {
            c.drawPath(big, s);
            c.drawPath(small, s);
          }
        }
      case AyreGlyph.learn:
        // Stacked rules under a header — a document, not an open book.
        _rect(c, s, f, 5, 3, 14, 18, r: 2);
        if (!filled) {
          c.drawLine(const Offset(8.5, 8), const Offset(15.5, 8), s);
          c.drawLine(const Offset(8.5, 12), const Offset(15.5, 12), s);
          c.drawLine(const Offset(8.5, 16), const Offset(13, 16), s);
        }
      case AyreGlyph.profile:
        if (filled) {
          c.drawCircle(const Offset(12, 9), 3.6, f);
          final path = Path()
            ..moveTo(5.5, 20.5)
            ..arcToPoint(
              const Offset(18.5, 20.5),
              radius: const Radius.circular(7.5),
            )
            ..close();
          c.drawPath(path, f);
        } else {
          c.drawCircle(const Offset(12, 9), 3.6, s);
          final path = Path()
            ..moveTo(5.5, 20)
            ..cubicTo(6.5, 16, 9, 15, 12, 15)
            ..cubicTo(15, 15, 17.5, 16, 18.5, 20);
          c.drawPath(path, s);
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