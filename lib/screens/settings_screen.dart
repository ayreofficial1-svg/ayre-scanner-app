import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../onboarding/tour_content.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';
import '../services/settings_store.dart';
import '../services/tour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/spotlight_tour.dart';
import 'delete_account_screen.dart';
import 'support_screen.dart' show kAppVersion, kAppBuild;

/// Settings — what you can change, grouped by what you are trying to change:
///
/// 1. Appearance — theme and text size
/// 2. Notifications — where alerts reach you, and which ones
/// 3. Account — password and deletion (only while signed in)
/// 4. Help and tutorials — replay the app tutorial or the Settings tutorial
/// 5. About — version and credits
///
/// Identity, email verification, help, legal and sign out live on Profile, so
/// nothing is listed in both places. Every row is backed by working behaviour;
/// a plausible setting with nothing behind it is left out rather than shipped
/// inert.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final Uri _logoCreditUrl = Uri.parse(
    'https://www.allinvestview.com/tools/ticker-logos/',
  );

  bool _sendingReset = false;

  /// True while this screen's own tutorial is showing, so only that one is
  /// dismissed when the screen goes away.
  bool _ownsTour = false;

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

  /// The app tutorial switches tabs, which only the shell can do, so go back
  /// to it and ask.
  void _replayAppTour() {
    HapticFeedback.selectionClick();
    Navigator.of(context).popUntil((route) => route.isFirst);
    TourService.instance.requestAppTour();
  }

  AuthUser? get _user => AuthService.instance.currentUser;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePassword() async {
    final email = _user?.email ?? '';
    if (email.isEmpty || _sendingReset) return;
    HapticFeedback.selectionClick();
    setState(() => _sendingReset = true);
    String message;
    try {
      await AuthService.instance.sendPasswordReset(email);
      message = 'We sent a password reset link to $email.';
    } on AuthFailure catch (e) {
      message = e.message;
    }
    if (!mounted) return;
    setState(() => _sendingReset = false);
    _toast(message);
  }

  Future<void> _clearAlertHistory() async {
    HapticFeedback.selectionClick();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _ConfirmSheet(
        title: 'Clear alert history?',
        message:
            'This removes the alerts saved on this device. New alerts will '
            'still appear as they arrive.',
        confirmLabel: 'Clear history',
      ),
    );
    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();
    await NotificationLog.instance.clear();
    if (!mounted) return;
    _toast('Alert history cleared');
  }

  Future<void> _openLogoCredit() async {
    HapticFeedback.selectionClick();
    if (await canLaunchUrl(_logoCreditUrl)) {
      await launchUrl(_logoCreditUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = SettingsStore.instance;
    final theme = AppThemeController.of(context);

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
              AppSpace.pageHorizontal,
              AppSpace.sm,
              AppSpace.pageHorizontal,
              AppSpace.xxl,
            ),
            children: [
              // ── Appearance ───────────────────────────────────────────────
              const SectionLabel(label: 'Appearance'),
              KeyedSubtree(
                key: TourKeys.settingsAppearance,
                child: AyreCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: AppTypo.rowLabel(t)),
                    const SizedBox(height: AppSpace.sm),
                    _AppearanceTiles(
                      value: theme.themeMode,
                      onChanged: (mode) {
                        HapticFeedback.selectionClick();
                        theme.setThemeMode(mode);
                      },
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      switch (theme.themeMode) {
                        ThemeMode.system =>
                          'Follows your device’s light or dark setting.',
                        ThemeMode.light => 'Ayre always uses the light theme.',
                        ThemeMode.dark => 'Ayre always uses the dark theme.',
                      },
                      style: AppTypo.caption(t),
                    ),
                    const SizedBox(height: AppSpace.md),
                    const HairlineDivider(),
                    const SizedBox(height: AppSpace.md),
                    Text('Text size', style: AppTypo.rowLabel(t)),
                    const SizedBox(height: AppSpace.sm),
                    _TextSizeTiles(
                      value: settings.textSize,
                      onChanged: (size) {
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
              const SectionLabel(label: 'Notifications'),
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
                              subtitle:
                                  push.permissionDenied && settings.pushEnabled
                                  ? 'Blocked by your device. Allow notifications '
                                        'for Ayre in your device settings.'
                                  : 'Get alerts on this device, even when the '
                                        'app is closed.',
                              value: settings.pushEnabled,
                              onChanged: settings.setPushEnabled,
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
                            subtitle:
                                'New signals, changes to them, and when a '
                                'price reaches its entry level.',
                            value: settings.newSignalAlerts,
                            // Governs both the in-app list and push, so it
                            // stays usable while either of them is on.
                            enabled: anyChannel,
                            onChanged: settings.setNewSignalAlerts,
                          ),
                          SettingRow(
                            glyph: AyreGlyph.close,
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
                const SectionLabel(label: 'Account'),
                KeyedSubtree(
                  key: TourKeys.settingsAccount,
                  child: RowGroup(
                  children: [
                    SettingRow(
                      glyph: AyreGlyph.lock,
                      title: 'Change password',
                      subtitle: 'We’ll email you a link to set a new one.',
                      enabled: !_sendingReset,
                      trailing: _sendingReset
                          ? SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.6,
                                color: t.foregroundMuted,
                              ),
                            )
                          : null,
                      onTap: _sendingReset ? null : _changePassword,
                    ),
                    SettingRow(
                      glyph: AyreGlyph.signOut,
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

              // ── Help and tutorials ───────────────────────────────────────
              const SizedBox(height: AppSpace.sectionGap),
              const SectionLabel(label: 'Help and tutorials'),
              KeyedSubtree(
                key: TourKeys.settingsHelp,
                child: RowGroup(
                  children: [
                    SettingRow(
                      glyph: AyreGlyph.course,
                      title: 'App tutorial',
                      subtitle: 'The five tabs and the Home controls.',
                      onTap: _replayAppTour,
                    ),
                    SettingRow(
                      glyph: AyreGlyph.appearance,
                      title: 'Settings tutorial',
                      subtitle: 'Where to find each option here.',
                      onTap: _startSettingsTour,
                    ),
                  ],
                ),
              ),

              // ── About ────────────────────────────────────────────────────
              const SizedBox(height: AppSpace.sectionGap),
              const SectionLabel(label: 'About'),
              KeyedSubtree(
                key: TourKeys.settingsAbout,
                child: RowGroup(
                children: [
                  SettingRow(
                    glyph: AyreGlyph.about,
                    title: 'Version',
                    subtitle: 'Include this when you contact support.',
                    trailing: Figure.static(
                      '$kAppVersion ($kAppBuild)',
                      fontSize: AppTextScale.hint,
                      color: t.foregroundMuted,
                    ),
                  ),
                  SettingRow(
                    glyph: AyreGlyph.equity,
                    title: 'Logo credits',
                    subtitle: 'Ticker logos by AllInvestView.',
                    onTap: _openLogoCredit,
                  ),
                ],
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

/// Bottom-sheet confirmation for an action the person may not want. Cancel is
/// the primary button; the confirming action is outlined in the danger tone.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypo.sectionTitle(t)),
          const SizedBox(height: AppSpace.sm),
          Text(message, style: AppTypo.body(t)),
          const SizedBox(height: AppSpace.xl),
          AyreButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: AppSpace.sm),
          AyreButton(
            label: confirmLabel,
            kind: AyreButtonKind.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

// ─── Appearance & text-size tile selectors ─────────────────────────────────
// Both selectors render as a row of big tappable tiles (glyph/sample + label +
// checkmark on the selected tile). `AyreSegmented` is left untouched — it is
// shared with the Insights time-window toggle, which keeps the bar style.

class _AppearanceTiles extends StatelessWidget {
  const _AppearanceTiles({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BigTile(
            selected: value == ThemeMode.system,
            label: 'System',
            onTap: () => onChanged(ThemeMode.system),
            // The half-filled contrast disc: a sun/moon composite is exactly
            // what "follows the device" should look like.
            child: _TileGlyph(
              glyph: AyreGlyph.appearance,
              selected: value == ThemeMode.system,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: _BigTile(
            selected: value == ThemeMode.light,
            label: 'Light',
            onTap: () => onChanged(ThemeMode.light),
            child: _TileGlyph(
              glyph: AyreGlyph.sun,
              selected: value == ThemeMode.light,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: _BigTile(
            selected: value == ThemeMode.dark,
            label: 'Dark',
            onTap: () => onChanged(ThemeMode.dark),
            child: _TileGlyph(
              glyph: AyreGlyph.moon,
              selected: value == ThemeMode.dark,
            ),
          ),
        ),
      ],
    );
  }
}

class _TextSizeTiles extends StatelessWidget {
  const _TextSizeTiles({required this.value, required this.onChanged});

  final AppTextSize value;
  final ValueChanged<AppTextSize> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final size in AppTextSize.values) ...[
          if (size != AppTextSize.values.first)
            const SizedBox(width: AppSpace.sm),
          Expanded(
            child: _BigTile(
              selected: value == size,
              label: size.label,
              onTap: () => onChanged(size),
              child: _TileAa(scale: size.scale, selected: value == size),
            ),
          ),
        ],
      ],
    );
  }
}

/// One tile shared by both selectors: a sample/glyph, a label, and a checkmark
/// badge in the corner when selected. Selected tiles fill `accent` with
/// `onAccent` content; unselected tiles stay on `surfaceRaised` with
/// `foregroundMuted` content.
class _BigTile extends StatelessWidget {
  const _BigTile({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onAccent : t.foregroundMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: AnimatedContainer(
          duration: AppMotion.buttonPress,
          curve: AppMotion.ease,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpace.md,
            horizontal: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? t.accent : t.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: selected ? t.accent : t.hairline),
          ),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child,
                    const SizedBox(height: AppSpace.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppTypo.ui(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: AyreIcon(AyreGlyph.check, size: 14, color: fg),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme tile's sample — the sun/moon glyph, sized up from the row-icon
/// default since this is the tile's whole visual identity.
class _TileGlyph extends StatelessWidget {
  const _TileGlyph({required this.glyph, required this.selected});

  final AyreGlyph glyph;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyreIcon(
      glyph,
      size: 22,
      color: selected ? t.onAccent : t.foregroundMuted,
      filled: selected,
    );
  }
}

/// Text-size tile's sample — "Aa" rendered at the size's own scale so the tile
/// previews that option, compact enough to sit inside a tile.
class _TileAa extends StatelessWidget {
  const _TileAa({required this.scale, required this.selected});

  final double scale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MediaQuery.withNoTextScaling(
      child: Text(
        'Aa',
        style: AppTypo.display(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w700,
          color: selected ? t.onAccent : t.foregroundMuted,
        ),
      ),
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
      onTap: enabled ? () => toggle(!value) : null,
      trailing: AyreSwitch(
        value: value && enabled,
        onChanged: enabled ? toggle : null,
        semanticLabel: title,
      ),
    );
  }
}
