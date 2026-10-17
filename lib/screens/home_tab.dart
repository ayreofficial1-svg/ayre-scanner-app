import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show AppThemeController;
import '../services/auth_service.dart';
import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/settings_store.dart';
import '../services/market_models.dart';
import '../onboarding/tour_content.dart' show TourKeys;
import '../theme/app_theme.dart';
import '../widgets/ayre_avatar.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_hills.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_insight_carousel.dart';
import '../widgets/ayre_logo.dart';
import '../widgets/ayre_signals_section.dart';
import '../widgets/ayre_tab_scroll.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/state_views.dart';
import 'home_shell.dart' show initialsFor;
import 'insight_note_screen.dart';
import 'notifications_screen.dart';

/// Home.
///
/// Order: greeting header (with the decorative hill ornament behind it) →
/// **Recommendations** (the analyst's published signals) → **Market Insight
/// carousel** (the analyst's hand-written desk notes). Sections are separated
/// by `sectionGap` alone. The Weekly Report has its own Reports tab.
///
/// Nothing on this screen is sourced from an exchange or market-data feed.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.marketData,
    this.onAccountResolved,
    this.onOpenProfile,
    this.active = true,
    this.signalsFocusToken = 0,
    this.scrollController,
  });

  final MarketDataService marketData;
  final ValueChanged<String>? onAccountResolved;
  final VoidCallback? onOpenProfile;

  /// Whether this tab is the one currently showing in the shell's
  /// [IndexedStack]. The tab stays mounted (and its state preserved) while on
  /// another tab; the Recommendations section uses this to skip reloads while
  /// off screen.
  final bool active;

  /// Changes whenever something (a signal notification) asks Home to bring the
  /// Signals section into view. Zero means no request.
  final int signalsFocusToken;

  /// Optional controller for the tab's scroll view (A2: re-tap scrolls to
  /// top). Null keeps the previous behaviour.
  final ScrollController? scrollController;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // The Market Insight carousel's source: the admin-curated desk notes
  // (`/api/insights`). Editorial content that changes a few times a day at
  // most, so it loads in `_load` and on resume after a long absence.
  DataResult<List<InsightNote>>? _notes;
  // The signals section owns its own fetch (see [SignalsSection]); Home only
  // holds a controller so pull-to-refresh can reload it.
  final SignalsSectionController _signalsController =
      SignalsSectionController();
  final GlobalKey _signalsKey = GlobalKey();
  // True from a focus request until the page has finished loading, so a layout
  // shift above the Signals section re-anchors it.
  bool _focusPending = false;
  String _accountName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.signalsFocusToken > 0) _requestSignalsFocus();
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  /// Fired once, shortly after the app returns to the foreground. If the app
  /// was away long enough, the desk notes are reloaded.
  void _onAppResumed() {
    if (!mounted || !widget.active) return;
    if (AppLifecycleService.instance.lastAway > const Duration(minutes: 5)) {
      _load();
    }
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signalsFocusToken != widget.signalsFocusToken &&
        widget.signalsFocusToken > 0) {
      _requestSignalsFocus();
    }
  }

  void _requestSignalsFocus() {
    _focusPending = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSignals(retry: true),
    );
  }

  /// Brings the Signals section into view. Safe to call repeatedly. If the
  /// section isn't built yet it retries once on the next frame, then gives up
  /// silently.
  void _scrollToSignals({bool retry = false}) {
    if (!mounted || !_focusPending || !widget.active) return;
    final target = _signalsKey.currentContext;
    if (target == null) {
      if (retry) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToSignals(),
        );
      }
      return;
    }
    // Keep the request alive until loading has finished, then stop.
    if (!_loading) _focusPending = false;
    Scrollable.ensureVisible(
      target,
      alignment: 0.05,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.pageTransition,
      curve: AppMotion.ease,
    );
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    super.dispose();
  }

  Future<void> _load() async {
    final notes = await widget.marketData.getInsightNotes();
    if (!mounted) return;

    final name = AuthService.instance.currentUser?.shownName ?? '';

    setState(() {
      _accountName = name;
      _notes = notes.keepingLastGood(_notes);
      _loading = false;
    });
    widget.onAccountResolved?.call(name);
    // The page above Signals has settled; re-anchor a pending focus request.
    if (_focusPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSignals());
    }
    // A5: no completion haptic after a refresh.
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        AuthService.instance.currentUser?.shownName ?? _accountName;

    return AyreTabScroll(
      controller: widget.scrollController,
      // One network pass per surface; the signals reload is silent.
      onRefresh: () => Future.wait([
        _load(),
        _signalsController.reload(silent: true),
      ]),
      children: [
        // The hills are the header's backdrop, not part of its layout:
        // positioned to the page's top-right corner (past the list
        // padding, so they bleed to the viewport edge) and painted first.
        // `Stack` sizes to the SafeArea child alone.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -AppSpace.pageTop,
              right: -AppSpace.gutterOf(context),
              child: AyreHills(),
            ),
            SafeArea(
              bottom: false,
              child: Entrance(
                child: _Header(
                  name: displayName,
                  onOpenProfile: widget.onOpenProfile,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sectionGap),
        KeyedSubtree(
          key: _signalsKey,
          child: Entrance(
            index: 1,
            child: SignalsSection(
              marketData: widget.marketData,
              active: widget.active,
              controller: _signalsController,
              forceColumns: 1,
            ),
          ),
        ),
        // An empty desk omits the card *and* its gap, so Home doesn't end
        // in a hole; loading and failed still show their own states.
        if (_showsInsights) ...[
          const SizedBox(height: AppSpace.sectionGap),
          Entrance(
            index: 2,
            child: _InsightSection(
              result: _loading ? null : _notes,
              onReadMore: _openInsight,
              onRetry: _load,
            ),
          ),
        ],
      ],
    );
  }

  /// False only when the desk answered with nothing to show.
  bool get _showsInsights {
    if (_loading) return true;
    final notes = _notes;
    if (notes == null || notes.isFailed) return true;
    return notes.isReady && notes.value!.isNotEmpty;
  }

  void _openInsight(InsightNote note) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      terminalRoute(builder: (_) => InsightNoteScreen(note: note)),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

/// Time-of-day salutation from the device clock. Local time, three buckets —
/// there's no server-side notion of the user's morning to defer to.
String _greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onOpenProfile});

  final String name;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final resolved = name.trim();
    final greeting = _greetingFor(DateTime.now());

    // Two stacked bands. The wordmark and the three controls share the top
    // band, so the salutation below gets the page's full width. Nothing here
    // shrinks to fit: the wordmark wraps, the greeting and name wrap to two
    // lines (G-2).
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              // The only in-app brand placement: a small wordmark, sized to
              // sit beneath the page content rather than compete with it.
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpace.xs,
                children: [
                  const LogoWordmark(fontSize: 15),
                  Text(
                    'SCANNER',
                    style: AppTypo.label(t, color: t.foregroundMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            const KeyedSubtree(key: TourKeys.homeTheme, child: _ThemeToggle()),
            const SizedBox(width: AppSpace.xs),
            KeyedSubtree(
              key: TourKeys.homeAlerts,
              child: ListenableBuilder(
                listenable: NotificationLog.instance,
                builder: (context, _) => _HeaderControl(
                  glyph: AyreGlyph.bell,
                  label: 'Alerts',
                  badge: NotificationLog.instance.hasUnread,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      terminalRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            _AccountControl(name: resolved, onTap: onOpenProfile),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        // The salutation is the header's largest text; the name sits on its
        // own line directly beneath it, a step down and heavier-set so the
        // pair still reads as one greeting. Both wrap (up to two lines)
        // instead of scaling down.
        Text(
          greeting,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypo.display(
            fontSize: AppTextScale.greeting,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
            height: 1.1,
            letterSpacing: -1.0,
          ),
        ),
        // With no name yet the salutation stands alone — no empty line, no
        // dangling gap under it.
        if (resolved.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(
            resolved,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypo.display(
              fontSize: AppTextScale.greetingName,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// The Home theme toggle (§13.1).
///
/// Writes to the same `setThemeMode` the Settings tiles do, so the two can
/// never disagree — there is one setter, on `AppThemeController`, and both
/// call it. Phase 1A restored `System` as a Settings option; this toggle
/// still only moves between explicit Light/Dark, matching a single-button
/// toggle's "shows the mode you're about to move to" convention — tapping
/// it while on `System` pins the theme to the opposite of whatever `System`
/// is currently resolving to, same as picking a tile in Settings would.
///
/// Icon-only, so unlike the nav it genuinely needs a semantic label — and the
/// label states what tapping *does*, not what mode you're in, since "Dark" as
/// a button name is ambiguous about direction.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HeaderControl(
      // Shows the mode you are about to move to, which is the convention that
      // makes a single-button toggle legible.
      glyph: isDark ? AyreGlyph.sun : AyreGlyph.moon,
      label: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      onTap: () {
        HapticFeedback.selectionClick();
        controller.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }
}

/// Header controls (v5 §2A, "Circular header icon buttons"): flat 40pt
/// circles inside a 48pt hit area — `surface` (white) in light, `surfaceRaised` in dark — with a
/// `textPrimary` glyph and, for the bell, a `negative` unread dot. A circle
/// is the spec'd exception to the rounded-square icon-tile rule here;
/// no gradient, no shadow.
class _HeaderControl extends StatelessWidget {
  const _HeaderControl({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.badge = false,
  });

  final AyreGlyph glyph;
  final String label;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? t.surfaceRaised : t.surface;
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.circle,
        child: SizedBox(
          height: AppSpace.minTarget,
          width: AppSpace.minTarget,
          child: Center(
            child: Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: t.hairline),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AyreIcon(glyph, size: 18, color: t.textPrimary),
              if (badge)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      // An unread marker is an alert: the true-red `negative`
                      // token, ringed in the button's own fill so it reads as
                      // a dot sitting on the circle.
                      color: t.negative,
                      shape: BoxShape.circle,
                      border: Border.all(color: fill, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountControl extends StatelessWidget {
  const _AccountControl({required this.name, required this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profile',
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.circle,
        // The identity-accent chip (lavender/plum), never brand green; 40pt
        // visual in a 48pt hit area.
        child: SizedBox(
          height: AppSpace.minTarget,
          width: AppSpace.minTarget,
          child: Center(
            child: AyreAvatar(initials: initialsFor(name), size: 40),
          ),
        ),
      ),
    );
  }
}

// ─── Market Insight ────────────────────────────────────────────────────────

/// The carousel's loading / failed / ready states. An empty desk never gets
/// here — `HomeTab` omits the whole section instead.
class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.result,
    required this.onReadMore,
    required this.onRetry,
  });

  final DataResult<List<InsightNote>>? result;
  final ValueChanged<InsightNote> onReadMore;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) return const AyreInsightSkeleton();

    if (r.isFailed) {
      return StatePanel.failed(
        headline: "Market insight didn't load",
        message: 'The rest of the page is unaffected.',
        compact: true,
        onRetry: onRetry,
      );
    }

    final notes = r.value;
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();
    return AyreInsightCarousel(notes: notes, onReadMore: onReadMore);
  }
}
