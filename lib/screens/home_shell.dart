import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'home_tab.dart';
import 'insights_tab.dart';
import 'learn_tab.dart';
import 'profile_menu_sheet.dart';
import 'signals_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _displayName = '';

  void _showProfileMenu(String displayName) {
    setState(() => _displayName = displayName);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6), // Darker backdrop
      elevation: 0,
      builder: (_) => ProfileMenuSheet(displayName: _displayName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onProfileMenuRequested: _showProfileMenu),
          const SignalsTab(),
          const InsightsTab(),
          const LearnTab(),
        ],
      ),
      bottomNavigationBar: _FloatingPillNav(
        selectedIndex: _index,
        onSelected: (i) {
          if (i != _index) setState(() => _index = i);
        },
      ),
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  const _FloatingPillNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItemData(Icons.home_rounded, 'Home'),
    _NavItemData(Icons.show_chart_rounded, 'Signals'),
    _NavItemData(Icons.thermostat_rounded, 'Insights'),
    _NavItemData(Icons.school_rounded, 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + (bottomPadding > 0 ? bottomPadding - 10 : 0),
      ),
      child: PremiumCard(
        radius: AppRadius.navBar,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
        color: tokens.surface.withValues(alpha: 0.9), // Glassy Apple effect
        borderColor: tokens.borderSubtle,
        shadowColor: tokens.shadowLg,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _FloatingNavItem(
                  data: _items[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tokens.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.navBar),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.ease,
            switchOutCurve: AppMotion.ease,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: selected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    key: const ValueKey('selected'),
                    children: [
                      Icon(data.icon, color: tokens.primary, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        data.label,
                        style: AppTypo.eyebrow(tokens, color: tokens.primary).copyWith(
                          fontSize: 12, // Slightly larger for readability
                        ),
                      ),
                    ],
                  )
                : Icon(
                    data.icon,
                    key: const ValueKey('unselected'),
                    color: tokens.textTertiary,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.label);

  final IconData icon;
  final String label;
}
