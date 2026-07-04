import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
      barrierColor: const Color(0xB3000000),
      builder: (_) => ProfileMenuSheet(displayName: _displayName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm + bottomPadding,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: tokens.shadowLg,
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
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
    final contentColor = selected ? tokens.primary : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        splashColor: tokens.primary.withValues(alpha: 0.12),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tokens.primary.withValues(alpha: 0.12) : AppTheme.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: selected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.icon, color: contentColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      data.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: contentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                    ),
                  ],
                )
              : Icon(data.icon, color: contentColor, size: 22),
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