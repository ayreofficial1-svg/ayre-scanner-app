import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_hills.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_stat_tile.dart';
import '../widgets/figure.dart';
import 'edit_profile_screen.dart';
import 'home_shell.dart' show initialsFor;
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart' show SupportScreen, kAppVersion, kAppBuild;

/// Profile — a flat header block plus list rows, using the same row grammar as
/// Learn and Settings rather than a distinct card treatment.
///
/// Sign out stays here (it's a session action, not a preference) and stays
/// isolated in its own separated section.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.accountName});

  final String accountName;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _handle;
  String? _sessionName;
  String? _tier;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final session = await ApiService.getSession();
    if (!mounted || session == null) return;
    setState(() {
      _handle = session['username']?.toString();
      _sessionName = session['display_name']?.toString();
      _tier = session['tier']?.toString() ?? session['plan']?.toString();
    });
  }

  /// The shell resolves the saved name over the session's, so what it hands down
  /// wins; the session value only covers the moment before it has one.
  String get _name {
    final resolved = widget.accountName.trim().isNotEmpty
        ? widget.accountName.trim()
        : (_sessionName?.trim() ?? '');
    return resolved.isEmpty ? 'Your account' : resolved;
  }

  Future<void> _editProfile() async {
    HapticFeedback.selectionClick();
    final updated = await Navigator.of(context).push<String>(
      terminalRoute(
        builder: (_) => EditProfileScreen(displayName: _name, handle: _handle),
      ),
    );
    if (updated == null || !mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  Future<void> _confirmSignOut() async {
    // Warning weight on open: this leads somewhere consequential.
    HapticFeedback.heavyImpact();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _SignOutSheet(),
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.heavyImpact();
    setState(() => _signingOut = true);
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      terminalRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.pageHorizontal,
          AppSpace.pageTop,
          AppSpace.pageHorizontal,
          120,
        ),
        children: [
          // Same "soft layered shape" header device as Home (§2A, Phase 6
          // step 1) — bled to the top-right corner behind the identity
          // block, not part of its layout.
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                top: -AppSpace.pageTop,
                right: -AppSpace.pageHorizontal,
                child: AyreHills(),
              ),
              SafeArea(
                bottom: false,
                child: Entrance(
                  child: _IdentityBlock(
                    name: _name,
                    handle: _handle,
                    tier: _tier,
                    onEdit: _editProfile,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sectionGap),
          const Entrance(index: 1, child: _StatsRow()),
          const SizedBox(height: AppSpace.sectionGap),
          // ── Account ───────────────────────────────────────────────────────
          Entrance(index: 2, child: const SectionLabel(label: 'Account')),
          Entrance(
            index: 2,
            child: RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.edit,
                  title: 'Edit profile',
                  subtitle: 'Change the name shown across the app',
                  onTap: _editProfile,
                ),
                SettingRow(
                  glyph: AyreGlyph.account,
                  title: 'Username',
                  subtitle: 'Identifies the account and cannot be changed here',
                  trailing: Text(
                    _handle ?? '—',
                    style: AppTypo.bodyStrong(t, color: t.foregroundMuted),
                  ),
                ),
              ],
            ),
          ),

          // ── Preferences ───────────────────────────────────────────────────
          const SizedBox(height: AppSpace.lg),
          Entrance(index: 4, child: const SectionLabel(label: 'Preferences')),
          Entrance(
            index: 4,
            child: RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.appearance,
                  title: 'Settings',
                  subtitle: 'Theme, text size and alerts',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      terminalRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                SettingRow(
                  glyph: AyreGlyph.bell,
                  title: 'Alerts',
                  subtitle: 'What the app has recorded for you',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      terminalRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Support ───────────────────────────────────────────────────────
          const SizedBox(height: AppSpace.lg),
          Entrance(index: 6, child: const SectionLabel(label: 'Support')),
          Entrance(
            index: 6,
            child: RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.support,
                  title: 'Help and support',
                  subtitle: 'How to reach the team',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      terminalRoute(builder: (_) => const SupportScreen()),
                    );
                  },
                ),
                SettingRow(
                  glyph: AyreGlyph.about,
                  title: 'Version',
                  trailing: Figure.static(
                    '$kAppVersion ($kAppBuild)',
                    fontSize: AppTextScale.hint,
                    color: t.foregroundMuted,
                  ),
                ),
                // A "Saved / Watchlist" row belongs here once there is a
                // watchlist feature to open. There isn't, so it isn't shown.
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          Entrance(index: 8, child: const SectionLabel(label: 'Session')),
          Entrance(
            index: 8,
            child: RowGroup(
              // `backgroundTint` was retired in Phase 0 and has no v4
              // equivalent: emphasis comes from the row's own danger styling
              // and the confirmation sheet, never a tinted plate behind a
              // group (§8.4). The group takes the ordinary surface.
              color: null,
              children: [
                SettingRow(
                  glyph: AyreGlyph.signOut,
                  title: 'Sign out',
                  subtitle: 'End this session on this device',
                  danger: true,
                  trailing: _signingOut
                      ? SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: t.negative,
                          ),
                        )
                      : null,
                  onTap: _signingOut ? null : _confirmSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile header (redesign plan §2.4 / Phase 6 step 1): circular
/// avatar/initials in the identity-accent lavender/plum tone (never brand
/// green — §2A's "Avatar / identity chip" row is a deliberate secondary
/// accent reserved for personal identity, distinct from market data), name,
/// handle, a small pill tag top-right of the header, a muted tagline, and an
/// "Edit Profile" pill button.
class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.name,
    required this.handle,
    required this.tier,
    required this.onEdit,
  });

  final String name;
  final String? handle;
  final String? tier;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // A flat header block, not a bordered card.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.avatarFill,
                // §7 reserves circles for avatars and the toggle knob. This
                // is an avatar — it was a rounded square in v3 because that
                // identity had no such rule. Home's header control matches.
                shape: BoxShape.circle,
                border: Border.all(color: t.hairline),
              ),
              child: Text(
                initialsFor(name),
                style: AppTypo.ui(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: t.avatarInk,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypo.display(
                      fontSize: AppTextScale.featuredHeadline,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  if (handle != null && handle!.isNotEmpty)
                    Text(
                      '@$handle',
                      style: AppTypo.caption(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    'Manage your account and settings.',
                    style: AppTypo.body(t),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Top-right pill tag (§2A "Profile mood/streak tag pill" /
            // Component table: text `accentInk` on `accentSoft`). The app
            // has no streak/mood endpoint, so this reuses the real `tier`
            // the session already returns rather than inventing figures —
            // same non-market identity metadata as before, restyled onto
            // the header's corner instead of a same-line chip.
            if (tier != null && tier!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  tier!.toUpperCase(),
                  style: AppTypo.label(t, color: t.accentInk),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AyreButton(
          label: 'Edit Profile',
          glyph: AyreGlyph.edit,
          kind: AyreButtonKind.outline,
          expand: false,
          onPressed: onEdit,
        ),
      ],
    );
  }
}

/// §13.5's stats row, rebuilt (Phase 6 step 2) onto the shared
/// [AyreStatTile] from Phase 5 instead of a bespoke card — "one component
/// for two screens", per that component's own doc comment.
///
/// Built only from figures the app genuinely holds locally — alerts logged on
/// this device, and whether the notification log has anything unread. There is
/// no account-statistics endpoint, so the obvious candidates (signals acted
/// on, lessons completed, member-since) have no source. Per plan §8 that is a
/// backend request to flag, not a reason to invent a number that looks
/// authoritative; the row shows what is real and no more.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationLog.instance,
      builder: (context, _) {
        final entries = NotificationLog.instance.entries;
        final unread = NotificationLog.instance.hasUnread;
        return Row(
          children: [
            Expanded(
              child: AyreStatTile(
                glyph: AyreGlyph.bell,
                value: '${entries.length}',
                label: 'Alerts logged',
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: AyreStatTile(
                glyph: AyreGlyph.alerts,
                value: unread ? 'Yes' : 'No',
                label: 'Unread insights',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Destructive confirmation. Cancel is the visually primary action; Sign out
/// carries the negative tone — the one place in the app where that colour
/// means "this is destructive" rather than "the market went down", and it is
/// confined to an explicit confirmation sheet for exactly that reason.
class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet();

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
          Text('Sign out?', style: AppTypo.sectionTitle(t)),
          const SizedBox(height: AppSpace.sm),
          Text(
            'You will need your username and password to sign back in on this '
            'device.',
            style: AppTypo.body(t),
          ),
          const SizedBox(height: AppSpace.xl),
          AyreButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: AppSpace.sm),
          AyreButton(
            label: 'Sign out',
            kind: AyreButtonKind.danger,
            glyph: AyreGlyph.signOut,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}