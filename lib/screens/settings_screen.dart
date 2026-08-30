import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';
import 'profile_tab.dart' show ProfileRow;
import 'support_screen.dart';

/// A pushed route reached from Profile's menu. The bottom nav is hidden for its
/// duration and returns on the way back.
///
/// Every row here maps to behaviour that works today. Sections that would only
/// contain placeholders — push delivery, watchlist price alerts, a weekly
/// digest, data-export or privacy controls the backend doesn't offer — are left
/// out entirely rather than shipped as controls that don't do anything.
/// Sign Out stays on Profile: it's a session action, not a preference.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _handle;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final session = await ApiService.getSession();
    if (!mounted) return;
    setState(() => _handle = session?['username']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final settings = SettingsStore.instance;
    final themeController = AppThemeController.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ContentWidth(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            children: [
              _Section(
                title: 'Alerts',
                children: [
                  _SwitchRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'In-app alerts',
                    subtitle:
                        'Keep a list of what changed while you were away, '
                        'reachable from the bell on Home.',
                    value: settings.inAppAlerts,
                    onChanged: settings.setInAppAlerts,
                  ),
                  const HairlineDivider(indent: 60),
                  _SwitchRow(
                    icon: Icons.add_chart_rounded,
                    title: 'New signal alerts',
                    subtitle:
                        'Record an entry when the scanner returns a pick you '
                        'have not seen before.',
                    value: settings.newSignalAlerts,
                    enabled: settings.inAppAlerts,
                    onChanged: settings.setNewSignalAlerts,
                  ),
                  const HairlineDivider(indent: 60),
                  _SwitchRow(
                    icon: Icons.schedule_rounded,
                    title: 'Delayed-data warnings',
                    subtitle:
                        'Record an entry when market data falls behind its '
                        'normal update interval.',
                    value: settings.staleDataWarnings,
                    enabled: settings.inAppAlerts,
                    onChanged: settings.setStaleDataWarnings,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'Appearance',
                children: [
                  _ThemeSelector(
                    mode: themeController.themeMode,
                    onChanged: (mode) {
                      HapticFeedback.selectionClick();
                      themeController.setThemeMode(mode);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'Account',
                children: [
                  ProfileRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Signed in as',
                    subtitle: _handle == null
                        ? 'Checking this device’s session'
                        : 'This is the identity the scanner uses',
                    trailing: Text(
                      _handle ?? '—',
                      style: AppTypo.bodyMedium(
                        tokens,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Section(
                title: 'About',
                children: [
                  ProfileRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help and support',
                    subtitle: 'How to reach the team',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(),
                        ),
                      );
                    },
                  ),
                  const HairlineDivider(indent: 60),
                  ProfileRow(
                    icon: Icons.tag_rounded,
                    title: 'Version',
                    trailing: Text(
                      '$kAppVersion ($kAppBuild)',
                      style: AppTypo.bodyMedium(
                        tokens,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(title.toUpperCase(), style: AppTypo.sectionEyebrow(tokens)),
        ),
        PremiumCard(padding: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }
}

/// Every toggle carries a one-line description of what it actually changes, and
/// a switch as its disclosure affordance. A confirmation-weight haptic fires on
/// completing the change, not on the press.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// A dependent switch reads as inactive when its master is off, rather than
  /// disappearing.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    void toggle(bool next) {
      if (!enabled) return;
      HapticFeedback.mediumImpact();
      onChanged(next);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: PressableScale(
        onTap: enabled ? () => toggle(!value) : null,
        borderRadius: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(icon, color: tokens.textSecondary, size: 20),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypo.cardTitle(tokens)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypo.caption(tokens)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Switch.adaptive(
                value: value && enabled,
                onChanged: enabled ? toggle : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-way appearance selector: System follows the OS, Light and Dark pin it.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const options = [
      (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
      (ThemeMode.light, 'Light', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Light and dark are tuned separately — each is designed against its '
            'own background rather than inverted from the other.',
            style: AppTypo.caption(tokens),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final (value, label, icon) in options) ...[
                if (value != options.first.$1)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ThemeOption(
                    label: label,
                    icon: icon,
                    selected: mode == value,
                    onTap: () => onChanged(value),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tone = selected ? tokens.primary : tokens.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? tokens.primary.withValues(alpha: 0.10) : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? tokens.primary : tokens.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: tone),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: AppTypo.microLabel(tokens, color: tone)),
            ],
          ),
        ),
      ),
    );
  }
}
