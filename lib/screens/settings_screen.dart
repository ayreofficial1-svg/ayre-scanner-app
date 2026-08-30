import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import 'support_screen.dart';

/// Settings — same information architecture (Alerts / Appearance / Account /
/// About), fully restyled.
///
/// Every row maps to behaviour that works today. A control with nothing behind
/// it is left out rather than shipped inert.
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
    final t = context.tokens;
    final settings = SettingsStore.instance;
    final themeController = AppThemeController.of(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('Settings'),
      ),
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
              const SectionLabel(label: 'Alerts'),
              RowGroup(
                children: [
                  _SwitchRow(
                    glyph: AyreGlyph.bell,
                    title: 'In-app alerts',
                    subtitle: 'Keep a list of what changed while you were away, '
                        'reachable from the bell on Home.',
                    value: settings.inAppAlerts,
                    onChanged: settings.setInAppAlerts,
                  ),
                  _SwitchRow(
                    glyph: AyreGlyph.alerts,
                    title: 'New signal alerts',
                    subtitle: 'Record an entry when the scanner returns a pick '
                        'you have not seen before.',
                    value: settings.newSignalAlerts,
                    enabled: settings.inAppAlerts,
                    onChanged: settings.setNewSignalAlerts,
                  ),
                  _SwitchRow(
                    glyph: AyreGlyph.delayed,
                    title: 'Delayed-data warnings',
                    subtitle: 'Record an entry when market data falls behind its '
                        'normal update interval.',
                    value: settings.staleDataWarnings,
                    enabled: settings.inAppAlerts,
                    onChanged: settings.setStaleDataWarnings,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionLabel(label: 'Appearance'),
              AyreCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AyreSegmented<ThemeMode>(
                      value: themeController.themeMode,
                      onChanged: (mode) {
                        HapticFeedback.selectionClick();
                        themeController.setThemeMode(mode);
                      },
                      segments: const [
                        AyreSegment(
                          value: ThemeMode.system,
                          label: 'System',
                          glyph: AyreGlyph.appearance,
                        ),
                        AyreSegment(
                          value: ThemeMode.light,
                          label: 'Light',
                          glyph: AyreGlyph.empty,
                        ),
                        AyreSegment(
                          value: ThemeMode.dark,
                          label: 'Dark',
                          glyph: AyreGlyph.live,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Light and dark are tuned separately — each is designed '
                      'against its own background rather than inverted from the '
                      'other.',
                      style: AppTypo.caption(t),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionLabel(label: 'Account'),
              RowGroup(
                children: [
                  SettingRow(
                    glyph: AyreGlyph.account,
                    title: 'Signed in as',
                    subtitle: _handle == null
                        ? "Checking this device's session"
                        : 'The identity the scanner uses',
                    trailing: Text(
                      _handle ?? '—',
                      style: AppTypo.bodyStrong(t, color: t.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionLabel(label: 'About'),
              RowGroup(
                children: [
                  SettingRow(
                    glyph: AyreGlyph.support,
                    title: 'Help and support',
                    subtitle: 'How to reach the team',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SupportScreen()),
                      );
                    },
                  ),
                  SettingRow(
                    glyph: AyreGlyph.about,
                    title: 'Version',
                    // Numbers stay tabular even here, for system consistency.
                    trailing: Figure.static(
                      '$kAppVersion ($kAppBuild)',
                      fontSize: 13,
                      color: t.textSecondary,
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

/// Every toggle carries a one-line description of what it changes, and a switch
/// as its disclosure affordance. Confirmation-weight haptic fires on the
/// completed change, not the press.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final AyreGlyph glyph;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// A dependent switch reads as inactive when its master is off, rather than
  /// vanishing.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    void toggle(bool next) {
      if (!enabled) return;
      HapticFeedback.mediumImpact();
      onChanged(next);
    }

    return SettingRow(
      glyph: glyph,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: enabled ? () => toggle(!value) : null,
      trailing: AyreSwitch(
        value: value && enabled,
        onChanged: enabled ? toggle : null,
        semanticLabel: title,
      ),
    );
  }
}
