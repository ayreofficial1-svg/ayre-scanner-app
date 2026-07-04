import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';

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
          color: tokens.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl + 8),
          ),
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: tokens.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ProfileHero(name: name),
            const SizedBox(height: AppSpacing.md),
            _MenuGroup(
              title: 'Account',
              children: [
                _MenuActionRow(
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  subtitle: 'Trading identity and account details',
                  onTap: () {},
                ),
                _MenuActionRow(
                  icon: Icons.tune_rounded,
                  title: 'Settings',
                  subtitle: 'Scanner preferences and saved defaults',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _MenuGroup(
              title: 'Notifications',
              children: [
                _MenuSwitchRow(
                  icon: Icons.notifications_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Setup alerts and important scanner updates',
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
                  subtitle: 'A calm summary before the next trading week',
                  value: _weeklyDigest,
                  onChanged: (v) => setState(() => _weeklyDigest = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _MenuGroup(
              title: 'Appearance',
              children: [
                _MenuSwitchRow(
                  icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  title: 'Night Mode',
                  subtitle: isDark ? 'Dark canvas enabled' : 'Light canvas enabled',
                  value: isDark,
                  onChanged: (v) {
                    themeController.setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _MenuGroup(
              title: 'Library',
              children: [
                _MenuActionRow(
                  icon: Icons.bookmark_rounded,
                  title: 'Saved Screens',
                  subtitle: 'Pinned boards and scanner views',
                  onTap: () {},
                ),
                _MenuActionRow(
                  icon: Icons.help_rounded,
                  title: 'Help',
                  subtitle: 'Guides, support, and scanner basics',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _MenuGroup(
              title: 'Session',
              children: [
                _MenuActionRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Keep auth disabled for now; flow can return later',
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tokens.neutralBlock,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _AvatarBadge(name: name, size: 60),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.onNeutralBlock,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ayre Scanner',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.onNeutralBlock.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: tokens.onNeutralBlock.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: tokens.border),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
    final color = destructive ? tokens.negative : tokens.primary;

    return _MenuRowFrame(
      onTap: onTap,
      leading: _IconBubble(icon: icon, color: color),
      title: title,
      subtitle: subtitle,
      titleColor: destructive ? tokens.negative : null,
      trailing: Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
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
      onTap: () => onChanged(!value),
      leading: _IconBubble(icon: icon, color: tokens.primary),
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class _MenuRowFrame extends StatefulWidget {
  const _MenuRowFrame({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.titleColor,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  State<_MenuRowFrame> createState() => _MenuRowFrameState();
}

class _MenuRowFrameState extends State<_MenuRowFrame> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: _hovering ? tokens.primary.withValues(alpha: 0.06) : AppTheme.transparent,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: widget.titleColor ?? tokens.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 20),
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
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
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