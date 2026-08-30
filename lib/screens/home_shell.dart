import 'package:flutter/material.dart';

import '../services/market_data_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/fold_nav.dart';
import 'home_tab.dart';
import 'insights_tab.dart';
import 'learn_tab.dart';
import 'profile_tab.dart';
import 'signals_tab.dart';

/// Tab state is preserved across switches by [IndexedStack] — expressed through
/// the Fold's collapsed/expanded states rather than a static bar, but the
/// mechanism is unchanged.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.marketData = const RemoteMarketDataService()});

  /// Injected so every screen can be rendered with known data in tests.
  final MarketDataService marketData;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _accountName = '';

  /// Lets the Fold fold itself away while content is being scrolled.
  final _ScrollPulse _scrollPulse = _ScrollPulse();

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _onAccountResolved(String name) {
    if (name == _accountName) return;
    setState(() => _accountName = name);
  }

  @override
  void dispose() {
    _scrollPulse.dispose();
    super.dispose();
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
        ),
        SignalsTab(marketData: widget.marketData),
        InsightsTab(marketData: widget.marketData),
        LearnTab(marketData: widget.marketData),
        ProfileTab(accountName: name),
      ],
    );

    return Scaffold(
      backgroundColor: t.background,
      extendBody: true,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          // Only a real drag should dismiss the dock, not a settle or a bounce.
          if ((notification.scrollDelta ?? 0).abs() > 6) {
            _scrollPulse.pulse();
          }
          return false;
        },
        child: _TabFade(index: _index, child: tabs),
      ),
      bottomNavigationBar: FoldNav(
        selectedIndex: _index,
        onSelected: _select,
        initials: initialsFor(name),
        scrollNotifier: _scrollPulse,
      ),
    );
  }
}

/// A notifier the Fold can listen to without owning a ScrollController, so the
/// dock gets out of the way when content moves.
class _ScrollPulse extends ChangeNotifier {
  void pulse() => notifyListeners();
}

/// The incoming tab's already-built content fades in — opacity only, additive to
/// the Fold's own motion.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: AppMotion.fast)
      ..value = 1.0;
  }

  @override
  void didUpdateWidget(_TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = 1.0;
    } else {
      _fade.forward(from: 0.4);
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
