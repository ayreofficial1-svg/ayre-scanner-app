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
      barrierColor: const Color(0xB3000000),
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
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm + bottomPadding,
      ),
      child: PremiumCard(
        radius: AppRadius.pill,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gradient: LinearGradient(
          colors: [
            tokens.neutralBlock.withValues(alpha: 0.96),
            Color.lerp(tokens.neutralBlock, tokens.primary, 0.1)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: Colors.white.withValues(alpha: 0.08),
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
    final contentColor = selected
        ? tokens.onPrimary
        : tokens.onNeutralBlock.withValues(alpha: 0.68);

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        splashColor: tokens.primary.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.ease,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primaryShifted(tokens) : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha: 0.34),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: selected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.icon, color: contentColor, size: 20),
                    const SizedBox(width: 7),
                    Text(
                      data.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Icon(data.icon, color: contentColor, size: 23),
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
