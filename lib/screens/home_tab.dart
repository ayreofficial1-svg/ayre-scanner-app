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
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_insight_carousel.dart';
import '../widgets/ayre_masthead.dart';
import '../widgets/ayre_signals_section.dart';
import '../widgets/ayre_tab_scroll.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/state_views.dart';
import 'home_shell.dart' show initialsFor;
import 'insight_note_screen.dart';
import 'notifications_screen.dart';

/// Home.
///
/// Order: masthead with the account greeting →
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSignals());
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
      eager: true,
      header: AyreMasthead.tab(
        tone: AyreMastTone.home,
        height: AppShape.mastHome,
        contentBottomClearance: AppSpace.s26,
        child: _Header(name: displayName, onOpenProfile: widget.onOpenProfile),
      ),
      // One network pass per surface; the signals reload is silent.
      onRefresh: () =>
          Future.wait([_load(), _signalsController.reload(silent: true)]),
      children: [
        const SizedBox(height: AppSpace.s13),
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
    Navigator.of(
      context,
    ).push(terminalRoute(builder: (_) => InsightNoteScreen(note: note)));
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

String _dateFor(DateTime now) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onOpenProfile});

  final String name;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final mast = t.mastHome;
    final resolved = name.trim();
    final now = DateTime.now();
    final date = _dateFor(now);
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ThemeToggle(key: TourKeys.homeTheme),
        const SizedBox(width: AppSpace.xxs),
        ListenableBuilder(
          key: TourKeys.homeAlerts,
          listenable: NotificationLog.instance,
          builder: (context, _) {
            final unread = NotificationLog.instance.hasUnread;
            return MastIconButton(
              tone: AyreMastTone.home,
              semanticLabel: unread ? 'Alerts, unread' : 'Alerts',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  terminalRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const AyreIcon(AyreGlyph.bell, size: 20),
                    if (unread)
                      PositionedDirectional(
                        top: 9,
                        end: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.highlight,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 9),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpace.xxs),
        _AccountControl(name: resolved, onTap: onOpenProfile),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/brand/investee_mark_on_dark.png',
                        width: 23,
                        height: 17,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: AppSpace.s8),
                      Text(
                        'investee',
                        semanticsLabel: 'Investee',
                        textScaler: TextScaler.noScaling,
                        style: AppTypo.display(
                          fontSize: 22,
                          height: 1,
                          color: mast.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            controls,
          ],
        ),
        const SizedBox(height: AppSpace.s13),
        Text(_greetingFor(now), style: AppTypo.subtitle(t, color: mast.muted)),
        if (resolved.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(resolved, style: AppTypo.homeName(t, color: mast.ink)),
        ],
        SizedBox(height: resolved.isNotEmpty ? AppSpace.s8 : AppSpace.xxs),
        FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 0.72,
          child: Text(
            date,
            style: AppTypo.ui(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: mast.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeController.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MastIconButton(
      tone: AyreMastTone.home,
      semanticLabel: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      onTap: () {
        HapticFeedback.selectionClick();
        controller.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
      },
      child: AyreIcon(isDark ? AyreGlyph.sun : AyreGlyph.moon, size: 20),
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
      enabled: onTap != null,
      label: 'Profile',
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.circle,
        focusColor: context.tokens.mastHome.ink,
        child: SizedBox.square(
          dimension: AppSpace.minTarget,
          child: Center(
            child: AyreAvatar(initials: initialsFor(name), home: true),
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
    if (r == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(label: 'Market insight'),
          AyreInsightSkeleton(),
        ],
      );
    }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(label: 'Market insight'),
        AyreInsightCarousel(notes: notes, onReadMore: onReadMore),
      ],
    );
  }
}
