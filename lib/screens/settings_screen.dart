import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/pressable_scale.dart';
import 'support_screen.dart';

/// Settings — grouped by what the user is actually trying to change, with the
/// most-adjusted groups first and the account/session facts last.
///
/// Every row is backed by working behaviour. Where a plausible setting has no
/// backing capability it is absent rather than shipped inert.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _session;
  bool _loadingSession = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await ApiService.getSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _loadingSession = false;
    });
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
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              AppSpace.xxl,
            ),
            children: [
              // ── Appearance ─────────────────────────────────────────────────
              const SectionLabel(label: 'Appearance'),
              AyreCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THEME', style: AppTypo.label(t)),
                    const SizedBox(height: AppSpace.sm),
                    // Phase 1A (HIG alignment): System restored as a third
                    // tile alongside Light/Dark. Big tappable tiles (redesign
                    // plan §2.4 / Phase 6 step 4), not the thin segmented bar
                    // — the underlying selection logic is untouched, just
                    // widened to a third value.
                    _AppearanceTiles(
                      value: theme.themeMode,
                      onChanged: (mode) {
                        HapticFeedback.selectionClick();
                        theme.setThemeMode(mode);
                      },
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Light and dark are designed separately — each is tuned '
                      'against its own background rather than inverted.',
                      style: AppTypo.caption(t),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              _TextSizeCard(
                value: settings.textSize,
                onChanged: (size) {
                  HapticFeedback.selectionClick();
                  settings.setTextSize(size);
                },
              ),

              // ── Alerts ─────────────────────────────────────────────────────
              const SizedBox(height: AppSpace.lg),
              const SectionLabel(label: 'Alerts'),
              RowGroup(
                children: [
                  _SwitchRow(
                    glyph: AyreGlyph.bell,
                    title: 'In-app alerts',
                    subtitle:
                        'Keep a list of what changed while you were away, '
                        'reachable from the bell on Home.',
                    value: settings.inAppAlerts,
                    onChanged: settings.setInAppAlerts,
                  ),
                  _SwitchRow(
                    glyph: AyreGlyph.alerts,
                    title: 'New signal alerts',
                    subtitle:
                        'Record an entry when the scanner returns a pick '
                        'you have not seen before.',
                    value: settings.newSignalAlerts,
                    enabled: settings.inAppAlerts,
                    onChanged: settings.setNewSignalAlerts,
                  ),
                  _SwitchRow(
                    glyph: AyreGlyph.delayed,
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

              // ── Account & session ──────────────────────────────────────────
              const SizedBox(height: AppSpace.lg),
              const SectionLabel(label: 'Account and session'),
              RowGroup(
                children: [
                  SettingRow(
                    glyph: AyreGlyph.account,
                    title: 'Signed in as',
                    subtitle: _loadingSession
                        ? "Checking this device's session"
                        : 'The identity the scanner uses',
                    trailing: _loadingSession
                        ? const SkeletonBlock(width: 72, height: 11)
                        : Text(
                            _session?['username']?.toString() ??
                                'Not signed in',
                            style: AppTypo.bodyStrong(
                              t,
                              color: t.foregroundMuted,
                            ),
                          ),
                  ),
                  SettingRow(
                    glyph: AyreGlyph.lock,
                    title: 'Session',
                    subtitle: _session == null
                        ? 'No active session on this device'
                        : 'Signed in on this device only',
                    trailing: AyreChip(
                      label: _session == null ? 'Inactive' : 'Active',
                      tone: _session == null
                          ? ChipTone.neutral
                          : ChipTone.brand,
                    ),
                  ),
                ],
              ),

              // ── About ──────────────────────────────────────────────────────
              const SizedBox(height: AppSpace.lg),
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
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(),
                        ),
                      );
                    },
                  ),
                  SettingRow(
                    glyph: AyreGlyph.about,
                    title: 'Version',
                    subtitle: 'Include this when you report a problem',
                    trailing: Figure.static(
                      '$kAppVersion ($kAppBuild)',
                      fontSize: AppTextScale.hint,
                      color: t.foregroundMuted,
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

/// The font-size control, with a live preview above the picker so the effect is
/// visible before committing rather than only after.
class _TextSizeCard extends StatelessWidget {
  const _TextSizeCard({required this.value, required this.onChanged});

  final AppTextSize value;
  final ValueChanged<AppTextSize> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return AyreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEXT SIZE', style: AppTypo.label(t)),
          const SizedBox(height: AppSpace.sm),
          // The preview renders at the *selected* scale specifically, rather
          // than inheriting the app scale, so it still previews correctly at the
          // moment of choosing.
          _Preview(scale: value.scale),
          const SizedBox(height: AppSpace.md),
          // Three-up "big tappable tile" selector (redesign plan §2.4 /
          // Phase 6 step 4): each tile shows "Aa" at its own scale plus a
          // checkmark on the selected tile, replacing the thinner segmented
          // bar. `onChanged` wiring is unchanged.
          _TextSizeTiles(value: value, onChanged: onChanged),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Applies across the app straight away, on top of your device’s own '
            'text-size setting.',
            style: AppTypo.caption(t),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: t.hairline),
      ),
      // A fixed scale for the sample, so the card demonstrates the choice rather
      // than reflecting whatever is already applied.
      child: MediaQuery.withNoTextScaling(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NIFTY 50',
                style: AppTypo.label(t).copyWith(fontSize: 10 * scale),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                '24,518.40',
                style: AppTypo.num(
                  fontSize: AppTextScale.cardTitle * scale,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                'Breadth is constructive across large-cap financials.',
                style: AppTypo.body(
                  t,
                ).copyWith(fontSize: AppTextScale.body * scale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Appearance & text-size tile selectors ─────────────────────────────────
// Phase 6 step 4: both selectors render as a row of big tappable tiles
// (glyph/sample + label + checkmark on the selected tile) rather than
// `AyreSegmented`'s thinner bar. `AyreSegmented` itself is left untouched —
// it's shared with the Insights time-window toggle, which keeps the bar
// style. These two widgets are local to this screen.

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
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: _BigTile(
            selected: value == ThemeMode.system,
            label: 'System',
            onTap: () => onChanged(ThemeMode.system),
            // Reuses the half-filled contrast disc already drawn for the
            // Profile "Appearance" row glyph — a sun/moon composite is
            // exactly what "follows the device" should look like here.
            child: _TileGlyph(
              glyph: AyreGlyph.appearance,
              selected: value == ThemeMode.system,
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

/// One tile shared by both selectors: a sample/glyph, a label, and a
/// checkmark badge in the corner when selected. Fill/content colors follow
/// §2A's "Theme/text-size selector tiles" component-table row exactly:
/// selected tiles fill `accent` with `onAccent` content; unselected tiles
/// stay on `surfaceRaised` with `foregroundMuted` content.
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
            border: Border.all(
              color: selected ? t.accent : t.hairline,
            ),
          ),
          child: Stack(
            children: [
              Column(
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
/// default since this is the tile's whole visual identity, not a leading
/// icon beside text.
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

/// Text-size tile's sample — "Aa" rendered at the size's own scale so the
/// tile previews the choice, same idea as `_Preview` above but compact
/// enough to sit inside a tile.
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