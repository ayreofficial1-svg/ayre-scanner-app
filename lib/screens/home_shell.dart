import 'package:flutter/material.dart';

import '../services/market_data_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_bottom_nav.dart';
import 'home_tab.dart';
import 'insights_tab.dart';
import 'learn_tab.dart';
import 'profile_tab.dart';
import 'signals_tab.dart';

/// Tab state is preserved across switches by [IndexedStack] — expressed through
/// the Fold's collapsed/expanded states rather than a static bar, but the
/// mechanism is unchanged.
class HomeShell extends StatefulWidget {
  // Not const: the remote service holds a short-lived constituents cache, which
  // it needs because movers and breadth are derived from that data rather than
  // served by dedicated endpoints.
  HomeShell({super.key, MarketDataService? marketData})
    : marketData = marketData ?? RemoteMarketDataService();

  /// Injected so every screen can be rendered with known data in tests.
  final MarketDataService marketData;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _accountName = '';

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _onAccountResolved(String name) {
    if (name == _accountName) return;
    setState(() => _accountName = name);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final name = SettingsStore.instance.displayNameOverride ?? _accountName;
        return _build(context, name);
      },
    );
  }

  Widget _build(BuildContext context, String name) {
    final t = context.tokens;

    final tabs = IndexedStack(
      index: _index,
      children: [
        HomeTab(
          marketData: widget.marketData,
          onAccountResolved: _onAccountResolved,
          onOpenProfile: () => _select(4),
          active: _index == 0,
        ),
        SignalsTab(marketData: widget.marketData),
        InsightsTab(marketData: widget.marketData, active: _index == 2),
        LearnTab(marketData: widget.marketData),
        ProfileTab(accountName: name),
      ],
    );

    return Scaffold(
      backgroundColor: t.background,
      extendBody: true,
      body: _TabFade(index: _index, child: tabs),
      // Always visible: no scroll listener, no idle timer, no collapsed state.
      bottomNavigationBar: AyreBottomNav(
        selectedIndex: _index,
        onSelected: _select,
      ),
    );
  }
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
      duration: AppMotion.pageTransition,
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