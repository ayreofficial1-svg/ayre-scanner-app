import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/market_data_service.dart';
import '../services/persistent_market_data_service.dart';
import '../services/push_service.dart';
import '../services/tour_service.dart';
import '../onboarding/tour_content.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_bottom_nav.dart';
import '../widgets/ayre_nav_metrics.dart';
import '../widgets/ayre_tab_host.dart';
import '../widgets/spotlight_tour.dart';
import '../widgets/verification_banner.dart';
import 'home_tab.dart';
import 'insights_tab.dart';
import 'learn_tab.dart';
import 'notifications_screen.dart';
import 'profile_tab.dart';
import 'weekly_reports_tab.dart';

/// The signed-in shell: five destinations, each hosting **its own
/// [Navigator]** inside an [IndexedStack] (plan A3), so the dock (or rail)
/// stays visible on in-tab detail screens and every tab keeps its own back
/// stack while another tab is shown.
///
/// Stays on the **root** navigator (full screen, covers the dock): splash,
/// onboarding, the auth screens, sheets/dialogs and the spotlight tour.
///
/// Behaviour owned here:
///  * A1 — Android Back: sheets/dialogs/tour first, then the active tab's
///    stack, then Home, then the app exits.
///  * A2 — re-tapping the active tab pops it to its root, else scrolls to top.
///  * Deep links — a signal tap selects Home and its root; an exit/alert tap
///    opens Alerts on Home's navigator.
class HomeShell extends StatefulWidget {
  // Not const: the remote service holds a short-lived constituents cache, which
  // it needs because movers and breadth are derived from that data rather than
  // served by dedicated endpoints. Wrapped in `PersistentMarketDataService` so
  // every surface it serves falls back to the last on-device saved reading —
  // rather than an empty or failed state — when the market is closed longer
  // than the in-memory session remembers, the backend is unreachable, or the
  // app was relaunched after being closed. See that class's doc for exactly
  // what it changes (nothing any screen below this needs to know about).
  HomeShell({super.key, MarketDataService? marketData})
    : marketData =
          marketData ?? PersistentMarketDataService(RemoteMarketDataService());

  /// Injected so every screen can be rendered with known data in tests.
  final MarketDataService marketData;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _accountName = '';

  /// Bumped each time a signal notification asks to see Signals; Home scrolls
  /// the Signals section into view whenever it changes.
  int _signalsFocusToken = 0;

  /// One navigator per tab (A3) and the observers that tell the shell when a
  /// stack changed (Back handling depends on `canPop`).
  final List<GlobalKey<NavigatorState>> _navKeys = [
    for (final d in kNavDestinations)
      GlobalKey<NavigatorState>(debugLabel: 'tab-${d.label}'),
  ];
  late final List<_StackObserver> _observers = [
    for (var i = 0; i < kNavDestinations.length; i++)
      _StackObserver(_onStackChanged),
  ];

  /// One scroll controller per tab (A2), handed to the tab's list.
  final List<ScrollController> _scrollControllers = [
    for (var i = 0; i < kNavDestinations.length; i++) ScrollController(),
  ];

  bool get _androidBackRules => defaultTargetPlatform == TargetPlatform.android;

  bool get _activeTabCanPop => _navKeys[_index].currentState?.canPop() ?? false;

  @override
  void initState() {
    super.initState();
    final push = PushService.instance;
    // A notification tapped while the app was closed lands here on first
    // build; one tapped while it's running arrives through the notifier.
    // Signals live on Home (index 0) now, so a signal tap opens Home.
    if (push.consumePendingOpenSignals()) {
      _index = 0;
      _signalsFocusToken = 1;
    }
    push.openSignalsRequests.addListener(_onOpenSignalsRequested);
    push.openAlertsRequests.addListener(_onOpenAlertsRequested);
    // Same for an exit notification: it lands on the Alerts screen, which can
    // only be pushed once this shell has built.
    if (push.consumePendingOpenAlerts()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAlerts());
    }
    // The spotlight tutorial: once automatically after the welcome pages, and
    // whenever Settings asks for a replay.
    TourService.instance.appTourRequests.addListener(_onAppTourRequested);
    TourService.instance.profileTourRequests.addListener(
      _onProfileTourRequested,
    );
    unawaited(_startPendingTour());
  }

  @override
  void dispose() {
    // A tutorial must not outlive the shell (sign-out swaps this screen for
    // Login while the overlay would still be on top of it).
    TourService.instance.appTourRequests.removeListener(_onAppTourRequested);
    TourService.instance.profileTourRequests.removeListener(
      _onProfileTourRequested,
    );
    SpotlightTour.dismiss();
    PushService.instance.openSignalsRequests.removeListener(
      _onOpenSignalsRequested,
    );
    PushService.instance.openAlertsRequests.removeListener(
      _onOpenAlertsRequested,
    );
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onStackChanged() {
    // Observers fire during navigation (possibly mid-build): refresh the Back
    // handling once the frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onOpenAlertsRequested() {
    if (!mounted) return;
    if (PushService.instance.consumePendingOpenAlerts()) _openAlerts();
  }

  /// Alerts open on Home's navigator (A3), so the dock stays visible. Home is
  /// selected and returned to its root first so the push is what the person
  /// sees, whatever tab or depth they were at.
  void _openAlerts({bool retried = false}) {
    if (!mounted) return;
    final nav = _navKeys[0].currentState;
    if (nav == null) {
      if (!retried) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openAlerts(retried: true),
        );
      }
      return;
    }
    if (_index != 0) setState(() => _index = 0);
    nav.popUntil((route) => route.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navKeys[0].currentState?.push(
        terminalRoute(builder: (_) => const NotificationsScreen()),
      );
    });
  }

  void _onOpenSignalsRequested() {
    if (!mounted) return;
    // Signals live on Home (index 0).
    if (PushService.instance.consumePendingOpenSignals()) {
      _navKeys[0].currentState?.popUntil((route) => route.isFirst);
      setState(() {
        _index = 0;
        _signalsFocusToken++;
      });
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  /// A2: a tap on the already-selected destination. Pops that tab to its root;
  /// if it is already there, scrolls it to the top; if it is already at the
  /// top, does nothing. User taps only: tours and notifications use [_select].
  void _onReselected(int index) {
    final nav = _navKeys[index].currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
      return;
    }
    final controller = _scrollControllers[index];
    if (!controller.hasClients) return;
    final position = controller.positions.first;
    if (position.pixels <= 0.5) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpTo(0);
    } else {
      controller.animateTo(
        0,
        duration: AppMotion.pageTransition,
        curve: AppMotion.ease,
      );
    }
  }

  /// A1 (Android only): reached when system Back is not consumed by anything
  /// above the shell. Unwinds the active tab's stack, then goes Home. (When on
  /// Home with nothing to pop, [PopScope] lets the app exit.)
  void _onBack() {
    final nav = _navKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      unawaited(nav.maybePop());
      return;
    }
    if (_index != 0) _select(0);
  }

  /// Returns every tab to its root. True when something was popped, so the
  /// caller can wait for the transitions before measuring anything.
  bool _returnTabsToRoot() {
    var popped = false;
    for (final key in _navKeys) {
      final nav = key.currentState;
      if (nav != null && nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
        popped = true;
      }
    }
    return popped;
  }

  Future<void> _startPendingTour() async {
    if (await TourService.instance.takePending()) await _startAppTour();
  }

  void _onAppTourRequested() => unawaited(_startAppTour());

  void _onProfileTourRequested() => unawaited(_startProfileTour());

  /// Switches to Profile and walks every option on it, then returns to the tab
  /// the person was on. The verification step is left out once the email is
  /// confirmed, because those rows are not on screen then.
  Future<void> _startProfileTour() async {
    await Future<void>.delayed(
      AppMotion.pageTransition + const Duration(milliseconds: 150),
    );
    if (!mounted || SpotlightTour.isActive) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    // A tab can have a detail open now (A3), so return every tab to its root
    // before anything is measured.
    if (_returnTabsToRoot()) {
      await Future<void>.delayed(
        AppMotion.pageTransition + const Duration(milliseconds: 150),
      );
      if (!mounted || SpotlightTour.isActive) return;
    }
    final origin = _index;
    final verified = AuthService.instance.currentUser?.emailVerified ?? true;
    SpotlightTour.show(
      context,
      steps: [
        for (final s in kProfileTourSteps)
          if (!s.onlyWhenUnverified || !verified)
            SpotlightStep(
              target: s.target,
              title: s.title,
              body: s.body,
              onEnter: () => _select(4),
            ),
      ],
      onClosed: (_) {
        if (mounted) _select(origin);
      },
    );
  }

  /// Walks the five tabs, switching to each so its nav item (and, on Home, the
  /// header controls) can be highlighted, then returns to the tab the person
  /// was on.
  Future<void> _startAppTour() async {
    // Let first paint, or a pop back from Settings, settle before measuring.
    await Future<void>.delayed(
      AppMotion.pageTransition + const Duration(milliseconds: 150),
    );
    if (!mounted || SpotlightTour.isActive) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (_returnTabsToRoot()) {
      await Future<void>.delayed(
        AppMotion.pageTransition + const Duration(milliseconds: 150),
      );
      if (!mounted || SpotlightTour.isActive) return;
    }
    final origin = _index;
    SpotlightTour.show(
      context,
      steps: [
        for (final s in buildAppTourSteps())
          SpotlightStep(
            target: s.target,
            title: s.title,
            body: s.body,
            onEnter: () => _select(s.tab),
          ),
      ],
      onClosed: (_) {
        if (mounted) _select(origin);
      },
    );
  }

  void _onAccountResolved(String name) {
    if (name == _accountName) return;
    setState(() => _accountName = name);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance.user,
      builder: (context, _) {
        final name = AuthService.instance.currentUser?.shownName ?? _accountName;
        return _build(context, name);
      },
    );
  }

  /// The root page of one tab. Reads the shell's live values from
  /// [_ShellScope], because a route's page is built once and would otherwise
  /// never see later changes to the active tab or the account name.
  Widget _tabRoot(int index) {
    return Builder(
      builder: (context) {
        final scope = _ShellScope.of(context);
        final controller = _scrollControllers[index];
        return switch (index) {
          0 => HomeTab(
            marketData: widget.marketData,
            onAccountResolved: _onAccountResolved,
            onOpenProfile: () => _select(4),
            active: scope.index == 0,
            signalsFocusToken: scope.signalsFocusToken,
            scrollController: controller,
          ),
          1 => WeeklyReportsTab(
            marketData: widget.marketData,
            active: scope.index == 1,
            scrollController: controller,
          ),
          2 => InsightsTab(
            marketData: widget.marketData,
            active: scope.index == 2,
            scrollController: controller,
          ),
          3 => LearnTab(
            marketData: widget.marketData,
            active: scope.index == 3,
            scrollController: controller,
          ),
          _ => ProfileTab(
            accountName: scope.accountName,
            marketData: widget.marketData,
            scrollController: controller,
          ),
        };
      },
    );
  }

  Widget _tabNavigator(int index) {
    return Navigator(
      key: _navKeys[index],
      observers: [_observers[index]],
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => _tabRoot(index),
      ),
    );
  }

  Widget _build(BuildContext context, String name) {
    final t = context.tokens;
    final media = MediaQuery.of(context);

    // Below the pivot the floating dock; at/above it a side rail. The dock is
    // hidden while the keyboard is open so it never rides above it.
    final wide = AyreNavMetrics.usesRail(media.size.width);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final showDock = !wide && !keyboardOpen;
    final clearance = showDock ? AyreNavMetrics.clearanceOf(context) : 0.0;

    // Every visible live quote carries its own repeating AnimationController
    // (LivePulseDot's breathing dot). IndexedStack keeps all five tabs mounted
    // for the life of the app, and TickerMode mutes every ticker in an
    // inactive tab's subtree (detail screens included) without touching the
    // widgets that own them.
    Widget tickered(int index, Widget child) =>
        TickerMode(enabled: index == _index, child: child);

    final tabs = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < kNavDestinations.length; i++)
          tickered(i, _tabNavigator(i)),
      ],
    );

    final body = _ShellScope(
      index: _index,
      accountName: name,
      signalsFocusToken: _signalsFocusToken,
      child: AyreTabHost(
        clearance: clearance,
        child: wide
            ? Row(
                children: [
                  AyreNavRail(
                    selectedIndex: _index,
                    onSelected: _select,
                    onReselected: _onReselected,
                  ),
                  Expanded(
                    child: VerificationBannerHost(
                      child: _TabFade(index: _index, child: tabs),
                    ),
                  ),
                ],
              )
            : VerificationBannerHost(
                child: _TabFade(index: _index, child: tabs),
              ),
      ),
    );

    return PopScope(
      // Android only: Back may leave the app only from Home with nothing to
      // pop; otherwise `_onBack` unwinds the tab, then goes Home.
      canPop: !_androidBackRules || (_index == 0 && !_activeTabCanPop),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: t.background,
        extendBody: !wide,
        // Pushed screens own their keyboard handling; the shell must not also
        // lift the dock.
        resizeToAvoidBottomInset: false,
        body: body,
        bottomNavigationBar: showDock
            ? AyreBottomNav(
                selectedIndex: _index,
                onSelected: _select,
                onReselected: _onReselected,
              )
            : null,
      ),
    );
  }
}

/// Live shell values for the tab root pages (see [_HomeShellState._tabRoot]).
class _ShellScope extends InheritedWidget {
  const _ShellScope({
    required this.index,
    required this.accountName,
    required this.signalsFocusToken,
    required super.child,
  });

  final int index;
  final String accountName;
  final int signalsFocusToken;

  static _ShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShellScope>()!;

  @override
  bool updateShouldNotify(_ShellScope old) =>
      old.index != index ||
      old.accountName != accountName ||
      old.signalsFocusToken != signalsFocusToken;
}

/// Reports every change to a tab navigator's stack.
class _StackObserver extends NavigatorObserver {
  _StackObserver(this._onChanged);

  final VoidCallback _onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _onChanged();
}

/// The incoming tab's already-built content fades **and shifts** in — per
/// Spec §15.4, tab-to-tab switches inside this shell are a fade+shift, not
/// the route-level slide `TerminalPageTransitions` uses for overlay pushes
/// (Settings, detail screens). A small upward settle (8px, [AppSpace.xs])
/// reads as "the new content arrives" rather than a hard cut, without the
/// directional left/right implication a full slide would give two
/// same-level tabs.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.tabFade,
    )..value = 1.0;
    _curved = CurvedAnimation(parent: _controller, curve: AppMotion.ease);
  }

  @override
  void didUpdateWidget(_TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder, not a bare read of `_curved.value` inside a
    // `FadeTransition`'s child. The child subtree of a transition is built
    // once and reused every frame, so the previous version sampled the curve
    // a single time and the 8px shift §15.4 asks for never actually
    // happened — the tab only ever cross-faded. Caught in Phase 5 while
    // rebuilding the screens this transition carries.
    return AnimatedBuilder(
      animation: _curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curved.value) * AppSpace.xs),
          child: child,
        ),
      ),
    );
  }
}

/// Initials for the account, used by the Fold's Profile slot and Profile's own
/// identity block so both read as the same person.
String initialsFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '—';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}