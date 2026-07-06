import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          color: tokens.surfaceAlt, // Use a solid elevated color for the sheet
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: tokens.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedEntrance(child: _ProfileHero(name: name)),
            const SizedBox(height: AppSpacing.lg),
            _MenuGrid(
              items: [
                _GridItem(Icons.person_rounded, 'Profile', tokens.accentMint),
                _GridItem(Icons.tune_rounded, 'Settings', tokens.accentWarm),
                _GridItem(Icons.bookmark_rounded, 'Saved', tokens.accentCool),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _MenuSection(
              title: 'Notifications',
              children: [
                _MenuSwitchRow(
                  icon: Icons.notifications_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Setup alerts and scanner updates',
                  value: _pushNotifications,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _pushNotifications = v);
                  },
                ),
                const _MenuDivider(),
                _MenuSwitchRow(
                  icon: Icons.add_alert_rounded,
                  title: 'Price Alerts',
                  subtitle: 'Watchlist moves and trigger levels',
                  value: _priceAlerts,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _priceAlerts = v);
                  },
                ),
                const _MenuDivider(),
                _MenuSwitchRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Weekly Digest',
                  subtitle: 'A calm summary before Monday',
                  value: _weeklyDigest,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _weeklyDigest = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
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
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    themeController.setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _MenuSection(
              title: 'Session',
              children: [
                _MenuActionRow(
                  icon: Icons.help_rounded,
                  title: 'Help',
                  subtitle: 'Guides, support, and scanner basics',
                  onTap: () {
                    HapticFeedback.selectionClick();
                  },
                ),
                const _MenuDivider(),
                _MenuActionRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Keep auth disabled for now',
                  destructive: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                  },
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
      radius: AppRadius.xl,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          tokens.neutralBlock,
          Color.lerp(tokens.neutralBlock, tokens.primary, 0.2)!
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -60,
              child: Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  _AvatarBadge(name: name, size: 76),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypo.sectionTitle(tokens, color: tokens.onNeutralBlock),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Ayre Scanner workspace',
                          style: AppTypo.body(tokens, color: tokens.onNeutralBlock.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  GlassCircleButton(
                    icon: Icons.arrow_forward_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
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
          if (i > 0) const SizedBox(width: AppSpacing.md),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Softer backgrounds
    final bg = isDark ? item.color.withValues(alpha: 0.15) : item.color.withValues(alpha: 0.1);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: PremiumCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
        color: bg,
        borderColor: item.color.withValues(alpha: 0.2),
        shadowColor: item.color.withValues(alpha: 0.1),
        child: Column(
          children: [
            Icon(item.icon, color: item.color, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypo.eyebrow(tokens, color: item.color),
            ),
          ],
        ),
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: AppTypo.eyebrow(tokens),
          ),
        ),
        PremiumCard(
          radius: AppRadius.card,
          padding: EdgeInsets.zero,
          color: tokens.surface,
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
      trailing: Icon(Icons.chevron_right_rounded, color: tokens.textTertiary),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypo.cardTitle(tokens, color: titleColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypo.body(tokens),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 80, // Align with text
      color: context.tokens.borderSubtle,
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
            color: tokens.shadowLg,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypo.sectionTitle(tokens, color: tokens.onPrimary).copyWith(fontSize: size * 0.4),
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
