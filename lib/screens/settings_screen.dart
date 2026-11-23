import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../onboarding/tour_content.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import '../widgets/clear_alert_history.dart';
import '../widgets/spotlight_tour.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'support_screen.dart' show kAppVersion, kAppBuild;
// TEMPORARY (paywall test toggle) — remove before production
import 'testing/paywall_toggle_row.dart';

/// Settings — what you can change, grouped by what you are trying to change:
///
/// 1. Appearance — theme and text size
/// 2. Notifications — where alerts reach you, and which ones
/// 3. Account — password and deletion (only while signed in)
/// 4. About — version and credits (not part of the Settings tutorial)
///
/// Identity, email verification, help (including the tutorials), legal and
/// sign out live on Profile, so
/// nothing is listed in both places. Every row is backed by working behaviour;
/// a plausible setting with nothing behind it is left out rather than shipped
/// inert.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.startTour = false});

  /// Start the Settings tutorial as soon as the screen has arrived (used by
  /// Help and support).
  final bool startTour;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _deviceSettings = MethodChannel('investee/device_settings');

  static final Uri _logoCreditUrl = Uri.parse(
    'https://www.allinvestview.com/tools/ticker-logos/',
  );

  static final Uri _logoDesignerAppUri = Uri.parse(
    'instagram://user?username=guricreates',
  );
  static final Uri _logoDesignerWebUri = Uri.parse(
    'https://www.instagram.com/guricreates/',
  );

  /// True while this screen's own tutorial is showing, so only that one is
  /// dismissed when the screen goes away.
  bool _ownsTour = false;

  @override
  void initState() {
    super.initState();
    if (widget.startTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Let the push transition finish so targets are laid out.
        if (!mounted) return;
        if (!MediaQuery.disableAnimationsOf(context)) {
          await Future<void>.delayed(AppMotion.pageTransition);
        }
        if (mounted) _startSettingsTour();
      });
    }
  }

  @override
  void dispose() {
    if (_ownsTour) SpotlightTour.dismiss();
    super.dispose();
  }

  void _startSettingsTour() {
    if (SpotlightTour.isActive) return;
    HapticFeedback.selectionClick();
    _ownsTour = true;
    SpotlightTour.show(
      context,
      steps: [
        for (final s in kSettingsTourSteps)
          if (!s.needsAccount || _user != null)
            SpotlightStep(target: s.target, title: s.title, body: s.body),
      ],
      onClosed: (_) => _ownsTour = false,
    );
  }

  AuthUser? get _user => AuthService.instance.currentUser;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePassword() async {
    HapticFeedback.selectionClick();
    final changed = await Navigator.of(
      context,
    ).push<bool>(terminalRoute(builder: (_) => const ChangePasswordScreen()));
    if (changed == true && mounted) _toast('Password updated');
  }

  Future<void> _clearAlertHistory() async {
    if (await confirmClearAlertHistory(context) && mounted) {
      _toast('Alert history cleared');
    }
  }

  Future<void> _openNotificationSettings() async {
    HapticFeedback.selectionClick();
    try {
      final opened = await _deviceSettings.invokeMethod<bool>(
        'openNotificationSettings',
      );
      if (opened == true) {
        return;
      }
    } on PlatformException {
      // The device may restrict access to Settings.
    } on MissingPluginException {
      // Older host builds may not register the channel.
    }
    if (mounted) {
      _toast('Open Info or Settings for Investee to allow notifications.');
    }
  }

  Future<void> _openLogoCredit() async {
    HapticFeedback.selectionClick();
    try {
      await launchUrl(_logoCreditUrl, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// Opens the logo designer's Instagram profile: the Instagram app when it is
  /// installed, otherwise the profile page in the browser.
  Future<void> _openLogoDesigner() async {
    HapticFeedback.selectionClick();
    try {
      final opened = await launchUrl(
        _logoDesignerAppUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (_) {}
    try {
      await launchUrl(
        _logoDesignerWebUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = SettingsStore.instance;
    final theme = AppThemeController.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([settings, AuthService.instance.user]),
      builder: (context, _) => AyrePageScaffold(
        title: 'Settings',
        children: [
          // ── Appearance ───────────────────────────────────────────────
          const _SettingsGroupLabel('Appearance'),
          KeyedSubtree(
            key: TourKeys.settingsAppearance,
            child: AyreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: AppTypo.rowLabel(t)),
                  const SizedBox(height: AppSpace.sm),
                  AyreSegmented<ThemeMode>(
                    segments: const [
                      AyreSegment(value: ThemeMode.system, label: 'System'),
                      AyreSegment(value: ThemeMode.light, label: 'Light'),
                      AyreSegment(value: ThemeMode.dark, label: 'Dark'),
                    ],
                    value: theme.themeMode,
                    onChanged: (mode) {
                      if (mode == theme.themeMode) return;
                      HapticFeedback.selectionClick();
                      theme.setThemeMode(mode);
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(switch (theme.themeMode) {
                    ThemeMode.system =>
                      'Follows your device’s light or dark setting.',
                    ThemeMode.light => 'Investee always uses the light theme.',
                    ThemeMode.dark => 'Investee always uses the dark theme.',
                  }, style: AppTypo.caption(t)),
                  const SizedBox(height: AppSpace.s21),
                  Text('Text size', style: AppTypo.rowLabel(t)),
                  const SizedBox(height: AppSpace.s8),
                  AyreSegmented<AppTextSize>(
                    segments: [
                      for (final size in AppTextSize.values)
                        AyreSegment(value: size, label: size.label),
                    ],
                    value: settings.textSize,
                    onChanged: (size) {
                      if (size == settings.textSize) return;
                      HapticFeedback.selectionClick();
                      settings.setTextSize(size);
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Applies everywhere in the app straight away.',
                    style: AppTypo.caption(t),
                  ),
                ],
              ),
            ),
          ),

          // ── Notifications ────────────────────────────────────────────
          const SizedBox(height: AppSpace.sectionGap),
          const _SettingsGroupLabel('Notifications'),
          KeyedSubtree(
            key: TourKeys.settingsNotifications,
            child: ListenableBuilder(
              // Push availability and permission can change after this
              // screen opens (the OS prompt resolves asynchronously), and
              // the saved-alert count changes as alerts arrive.
              listenable: Listenable.merge([
                PushService.instance,
                NotificationLog.instance,
              ]),
              builder: (context, _) {
                final push = PushService.instance;
                final saved = NotificationLog.instance.entries.length;
                final pushBlocked =
                    push.permissionDenied && settings.pushEnabled;
                final anyChannel =
                    settings.inAppAlerts ||
                    (push.available && settings.pushEnabled);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RowGroup(
                      children: [
                        // Only offered on builds that can actually receive
                        // push (Android/iOS with Firebase configured) — a
                        // switch that changes nothing is worse than none.
                        if (push.available)
                          _SwitchRow(
                            glyph: AyreGlyph.bell,
                            title: 'Push notifications',
                            subtitle: pushBlocked
                                ? 'Blocked by your device. Allow notifications '
                                      'for Investee in your device settings.'
                                : 'Get alerts on this device, even when the '
                                      'app is closed.',
                            value: settings.pushEnabled,
                            onChanged: settings.setPushEnabled,
                          ),
                        if (push.available && pushBlocked)
                          SettingRow(
                            glyph: AyreGlyph.sliders,
                            title: 'Open device settings',
                            subtitle:
                                'Reopen Investee after changing notification access.',
                            onTap: _openNotificationSettings,
                          ),
                        _SwitchRow(
                          glyph: AyreGlyph.alerts,
                          title: 'In-app alerts',
                          subtitle: 'Keep a list of alerts in the app.',
                          value: settings.inAppAlerts,
                          onChanged: settings.setInAppAlerts,
                        ),
                        _SwitchRow(
                          glyph: AyreGlyph.trendUp,
                          title: 'Signal alerts',
                          subtitle: 'New signals and changes to them.',
                          value: settings.newSignalAlerts,
                          // Governs both the in-app list and push, so it
                          // stays usable while either of them is on.
                          enabled: anyChannel,
                          onChanged: settings.setNewSignalAlerts,
                        ),
                        SettingRow(
                          glyph: AyreGlyph.trash,
                          title: 'Clear alert history',
                          subtitle: saved == 0
                              ? 'No alerts saved on this device.'
                              : 'Remove $saved saved '
                                    '${saved == 1 ? 'alert' : 'alerts'} '
                                    'from this device.',
                          enabled: saved > 0,
                          onTap: saved > 0 ? _clearAlertHistory : null,
                        ),
                      ],
                    ),
                    const _GroupNote(
                      'Exit calls and messages from the team are not '
                      'affected by Signal alerts.',
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Account ──────────────────────────────────────────────────
          if (_user != null) ...[
            const SizedBox(height: AppSpace.sectionGap),
            const _SettingsGroupLabel('Account'),
            KeyedSubtree(
              key: TourKeys.settingsAccount,
              child: RowGroup(
                children: [
                  SettingRow(
                    glyph: AyreGlyph.lock,
                    title: 'Change password',
                    subtitle: 'Enter your current password and a new one.',
                    onTap: _changePassword,
                  ),
                  SettingRow(
                    glyph: AyreGlyph.trash,
                    title: 'Delete account',
                    subtitle: 'Permanently remove your account.',
                    danger: true,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        terminalRoute(
                          builder: (_) => const DeleteAccountScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            _GroupNote('Signed in as ${_user!.email}.'),
          ],

          // TEMPORARY (paywall test toggle) — remove before production
          const PaywallTestingGroup(),

          // ── About ────────────────────────────────────────────────────
          const SizedBox(height: AppSpace.sectionGap),
          const _SettingsGroupLabel('About'),
          RowGroup(
            children: [
              SettingRow(
                glyph: AyreGlyph.about,
                title: 'Version',
                subtitle: 'Include this when you contact support.',
                trailing: Text(
                  '$kAppVersion ($kAppBuild)',
                  style: AppTypo.num(
                    fontSize: AppTextScale.hint,
                    color: t.foregroundMuted,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              SettingRow(
                glyph: AyreGlyph.account,
                title: 'App logo',
                subtitle: 'Designed by @guricreates on Instagram.',
                onTap: _openLogoDesigner,
              ),
              SettingRow(
                glyph: AyreGlyph.equity,
                title: 'Logo credits',
                subtitle: 'Ticker logos by AllInvestView.',
                onTap: _openLogoCredit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => SectionLabel(
    label: label,
    eyebrow: true,
    padding: const EdgeInsets.only(bottom: AppSpace.s8),
  );
}

/// A short explanation under a group — the iOS "group footer".
class _GroupNote extends StatelessWidget {
  const _GroupNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
        0,
      ),
      child: Text(text, style: AppTypo.caption(context.tokens)),
    );
  }
}

/// Every toggle carries a one-line description of what it changes, and a switch
/// as its disclosure affordance. Confirmation-weight haptic on the completed
/// change, not the press.
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

  /// A dependent switch reads as inactive when nothing can deliver it, rather
  /// than vanishing.
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
      toggled: value && enabled,
      onTap: enabled ? () => toggle(!value) : null,
      trailing: ExcludeFocus(
        child: IgnorePointer(
          child: AyreSwitch(
            value: value && enabled,
            onChanged: enabled ? toggle : null,
          ),
        ),
      ),
    );
  }
}
