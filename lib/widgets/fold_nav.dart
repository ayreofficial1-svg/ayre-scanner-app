import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'pressable_scale.dart';
import 'responsive.dart';
import 'spring.dart';

/// A destination in the Fold.
class FoldDestination {
  const FoldDestination({
    required this.label,
    required this.glyph,
    this.avatar = false,
  });

  final String label;
  final AyreGlyph glyph;

  /// Profile draws the account's initials instead of a glyph.
  final bool avatar;
}

const List<FoldDestination> kFoldDestinations = [
  FoldDestination(label: 'Home', glyph: AyreGlyph.home),
  FoldDestination(label: 'Signals', glyph: AyreGlyph.signals),
  FoldDestination(label: 'Insights', glyph: AyreGlyph.insights),
  FoldDestination(label: 'Learn', glyph: AyreGlyph.learn),
  FoldDestination(label: 'Profile', glyph: AyreGlyph.profile, avatar: true),
];

/// A stable handle on a destination. Collapsed, the Fold shows one icon and no
/// label text, so there is nothing else to address it by.
Key foldDestinationKey(String label) => ValueKey('fold-destination-$label');

/// The collapsed control's handle.
const Key kFoldTriggerKey = ValueKey('fold-trigger');

/// **The Fold** — Ayre's navigation.
///
/// Not a static bar and not a pill. At rest the entire navigation *is* one small
/// Citrine-filled circular control showing the current section's icon, sitting
/// above a short hairline tray. Tapping it unfolds that single control
/// horizontally into the full five-destination dock; picking a destination folds
/// it back down, now showing the newly-active icon. It also folds itself away
/// after a short idle period and on scroll, so it is only ever big while someone
/// is actually navigating.
///
/// This is the one place Citrine sits permanently on screen as a large solid
/// fill, which is what makes it the app's signature mark.
class FoldNav extends StatefulWidget {
  const FoldNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.initials,
    this.scrollNotifier,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Drawn in the Profile destination's slot.
  final String initials;

  /// Fires when content scrolls, so the dock can get out of the way.
  final Listenable? scrollNotifier;

  @override
  State<FoldNav> createState() => _FoldNavState();
}

class _FoldNavState extends State<FoldNav> {
  bool _expanded = false;
  Timer? _idle;

  static const double _height = 56;
  static const double _collapsedWidth = 56;

  @override
  void initState() {
    super.initState();
    widget.scrollNotifier?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(FoldNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollNotifier != widget.scrollNotifier) {
      oldWidget.scrollNotifier?.removeListener(_onScroll);
      widget.scrollNotifier?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    widget.scrollNotifier?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_expanded) _collapse();
  }

  void _restartIdleTimer() {
    _idle?.cancel();
    _idle = Timer(AppMotion.foldIdle, () {
      if (mounted && _expanded) _collapse();
    });
  }

  void _expand() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = true);
    _restartIdleTimer();
  }

  void _collapse() {
    _idle?.cancel();
    if (!mounted) return;
    setState(() => _expanded = false);
  }

  void _pick(int index) {
    HapticFeedback.selectionClick();
    // Re-selecting the current destination still folds — the dock's job is done
    // either way.
    if (index != widget.selectedIndex) widget.onSelected(index);
    _collapse();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg + (bottomInset > 0 ? bottomInset - 8 : 0),
      ),
      child: Align(
        // Collapsed sits to the trailing side, off the content's centre line, so
        // it reads as a control rather than a bar. Expanded centres.
        alignment: _expanded ? Alignment.bottomCenter : Alignment.bottomRight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : AppBreakpoints.dockMaxWidth;
            final expandedWidth = maxWidth.clamp(
              _collapsedWidth,
              AppBreakpoints.dockMaxWidth,
            );

            return SpringValue(
              value: _expanded ? 1 : 0,
              spring: AppSpring.fold,
              builder: (context, unfold, _) {
                final progress = unfold.clamp(0.0, 1.0);
                final width =
                    _collapsedWidth + (expandedWidth - _collapsedWidth) * progress;

                return SizedBox(
                  height: _height,
                  width: width,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The tray materialises under the control as it unfolds.
                      Positioned.fill(
                        child: Opacity(
                          opacity: progress,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: t.surfaceRaised,
                              borderRadius: BorderRadius.circular(AppRadius.dock),
                              border: Border.all(color: t.border),
                            ),
                          ),
                        ),
                      ),
                      // A single hairline top edge on the tray.
                      if (progress > 0.02)
                        Positioned(
                          left: AppRadius.dock,
                          right: AppRadius.dock,
                          top: 0,
                          child: Opacity(
                            opacity: progress,
                            child: Container(height: 1, color: t.hairline),
                          ),
                        ),
                      Positioned.fill(
                        child: progress < 0.55
                            ? _Collapsed(
                                progress: progress,
                                destination:
                                    kFoldDestinations[widget.selectedIndex],
                                initials: widget.initials,
                                onTap: _expand,
                              )
                            : _Expanded(
                                progress: progress,
                                selectedIndex: widget.selectedIndex,
                                initials: widget.initials,
                                onPick: _pick,
                                onInteract: _restartIdleTimer,
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The resting state: one Citrine circle, current section's icon, nothing else.
class _Collapsed extends StatelessWidget {
  const _Collapsed({
    required this.progress,
    required this.destination,
    required this.initials,
    required this.onTap,
  });

  final double progress;
  final FoldDestination destination;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Align(
      alignment: Alignment.centerRight,
      child: Semantics(
        button: true,
        label: 'Navigation — ${destination.label} selected. Open destinations.',
        child: PressableScale(
          key: kFoldTriggerKey,
          onTap: onTap,
          borderRadius: AppRadius.circle,
          child: Opacity(
            // Hands off to the expanded row rather than both being visible.
            opacity: (1 - progress / 0.55).clamp(0.0, 1.0),
            child: Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.citrine,
                shape: BoxShape.circle,
                border: Border.all(
                  color: t.textPrimary.withValues(alpha: 0.18),
                ),
              ),
              child: destination.avatar
                  ? Text(
                      initials,
                      style: AppTypo.ui(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: t.onCitrine,
                      ),
                    )
                  : AyreIcon(
                      destination.glyph,
                      size: 22,
                      color: t.onCitrine,
                      filled: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The transient state: five labelled destinations on a flat tray. The active
/// one keeps the Citrine fill, now inline in the row rather than detached above
/// it — no per-item pill backgrounds, so contrast still comes from that one
/// element.
class _Expanded extends StatelessWidget {
  const _Expanded({
    required this.progress,
    required this.selectedIndex,
    required this.initials,
    required this.onPick,
    required this.onInteract,
  });

  final double progress;
  final int selectedIndex;
  final String initials;
  final ValueChanged<int> onPick;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    final opacity = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            for (var i = 0; i < kFoldDestinations.length; i++)
              Expanded(
                child: _DockItem(
                  key: foldDestinationKey(kFoldDestinations[i].label),
                  destination: kFoldDestinations[i],
                  selected: i == selectedIndex,
                  initials: initials,
                  onTap: () {
                    onInteract();
                    onPick(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.initials,
    required this.onTap,
  });

  final FoldDestination destination;
  final bool selected;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onCitrine : t.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: Container(
          // Comfortably above the 44pt minimum even on the smallest width.
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.citrine : AppTheme.transparent,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (destination.avatar)
                Text(
                  initials,
                  style: AppTypo.ui(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                )
              else
                // Filled-on-select, line-at-rest — the one icon state rule.
                AyreIcon(
                  destination.glyph,
                  size: 18,
                  color: fg,
                  filled: selected,
                ),
              const SizedBox(height: 2),
              // Labels shrink rather than overflow, so five fit legibly even at
              // 320pt with a large accessibility text scale.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  style: AppTypo.ui(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.1,
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
