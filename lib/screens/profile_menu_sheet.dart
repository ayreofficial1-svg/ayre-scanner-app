import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class ProfileMenuSheet extends StatefulWidget {
  const ProfileMenuSheet({super.key, required this.displayName});

  final String displayName;

  @override
  State<ProfileMenuSheet> createState() => _ProfileMenuSheetState();
}

class _ProfileMenuSheetState extends State<ProfileMenuSheet> {
  bool _pushNotifications = true;
  bool _priceAlerts = true;
  bool _weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final themeController = AppThemeController.of(context);
    final isDark = themeController.themeMode == ThemeMode.dark;
    final name = widget.displayName.isEmpty ? 'Raghav' : widget.displayName;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tokens.background, tokens.backgroundTint],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(46)),
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: tokens.textSecondary.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedEntrance(child: _ProfileHero(name: name)),
            const SizedBox(height: 14),
            _MenuGrid(
              items: [
                _GridItem(Icons.person_rounded, 'Profile', tokens.accentMint),
                _GridItem(Icons.tune_rounded, 'Settings', tokens.accentWarm),
                _GridItem(Icons.bookmark_rounded, 'Saved', tokens.accentCool),
              ],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              title: 'Notifications',
              children: [
                _MenuSwitchRow(
                  icon: Icons.notifications_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Setup alerts and scanner updates',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                _MenuSwitchRow(
                  icon: Icons.add_alert_rounded,
                  title: 'Price Alerts',
                  subtitle: 'Watchlist moves and trigger levels',
                  value: _priceAlerts,
                  onChanged: (v) => setState(() => _priceAlerts = v),
                ),
                _MenuSwitchRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Weekly Digest',
                  subtitle: 'A calm summary before Monday',
                  value: _weeklyDigest,
                  onChanged: (v) => setState(() => _weeklyDigest = v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              title: 'Appearance',
              children: [
                _MenuSwitchRow(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: 'Night Mode',
                  subtitle: isDark
                      ? 'Dark premium canvas enabled'
                      : 'Light premium canvas enabled',
                  value: isDark,
                  onChanged: (v) => themeController.setThemeMode(
                    v ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              title: 'Session',
              children: [
                _MenuActionRow(
                  icon: Icons.help_rounded,
                  title: 'Help',
                  subtitle: 'Guides, support, and scanner basics',
                  onTap: () {},
                ),
                _MenuActionRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Keep auth disabled for now',
                  destructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: 42,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          tokens.neutralBlock,
          Color.lerp(tokens.neutralBlock, tokens.primary, 0.16)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: SizedBox(
        height: 142,
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -48,
              child: Container(
                height: 154,
                width: 154,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _AvatarBadge(name: name, size: 70),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: tokens.onNeutralBlock,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ayre Scanner workspace',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: tokens.onNeutralBlock.withValues(
                                  alpha: 0.68,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  GlassCircleButton(
                    icon: Icons.arrow_forward_rounded,
                    size: 46,
                    color: Colors.white.withValues(alpha: 0.12),
                    iconColor: tokens.onNeutralBlock,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});

  final List<_GridItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _MenuGridTile(item: items[i])),
        ],
      ],
    );
  }
}

class _MenuGridTile extends StatelessWidget {
  const _MenuGridTile({required this.item});

  final _GridItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      color: item.color,
      shadowColor: item.color.withValues(alpha: 0.22),
      child: Column(
        children: [
          Icon(item.icon, color: tokens.neutralBlock, size: 26),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tokens.neutralBlock,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        PremiumCard(
          radius: 32,
          padding: EdgeInsets.zero,
          gradient: AppGradients.surfaceGlass(tokens),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuActionRow extends StatelessWidget {
  const _MenuActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _MenuRowFrame(
      icon: icon,
      iconColor: destructive ? tokens.negative : tokens.primary,
      title: title,
      subtitle: subtitle,
      titleColor: destructive ? tokens.negative : null,
      trailing: Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
      onTap: onTap,
    );
  }
}

class _MenuSwitchRow extends StatelessWidget {
  const _MenuSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _MenuRowFrame(
      icon: icon,
      iconColor: tokens.primary,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}

class _MenuRowFrame extends StatelessWidget {
  const _MenuRowFrame({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: titleColor ?? tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final initial = name.trim().isEmpty ? 'R' : name.trim()[0].toUpperCase();
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryShifted(tokens),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(alpha: 0.34),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: tokens.onPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GridItem {
  const _GridItem(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}
