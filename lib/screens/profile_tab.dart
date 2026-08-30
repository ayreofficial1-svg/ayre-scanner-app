import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import 'edit_profile_screen.dart';
import 'home_shell.dart' show initialsFor;
import 'login_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';

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
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(displayName: _name, handle: _handle),
      ),
    );
    if (updated == null || !mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          120,
        ),
        children: [
          SafeArea(
            bottom: false,
            child: Entrance(child: _IdentityBlock(name: _name, handle: _handle, tier: _tier)),
          ),
          const SizedBox(height: AppSpacing.xl),
          Entrance(
            index: 1,
            child: RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.edit,
                  title: 'Edit profile',
                  subtitle: 'Change the name shown across the app',
                  onTap: _editProfile,
                ),
                SettingRow(
                  glyph: AyreGlyph.appearance,
                  title: 'Settings',
                  subtitle: 'Alerts, appearance and account details',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
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
                // A "Saved / Watchlist" row belongs here once there's a
                // watchlist feature to open. There isn't, so it isn't shown.
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Entrance(index: 2, child: const SectionLabel(label: 'Session')),
          Entrance(
            index: 3,
            child: RowGroup(
              color: t.backgroundTint,
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
                            color: t.garnet,
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

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.name,
    required this.handle,
    required this.tier,
  });

  final String name;
  final String? handle;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // A flat header block, not a bordered card.
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.citrine,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: t.textPrimary.withValues(alpha: 0.18)),
          ),
          child: Text(
            initialsFor(name),
            style: AppTypo.ui(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: t.onCitrine,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypo.pageTitle(t).copyWith(fontSize: 21),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  if (handle != null && handle!.isNotEmpty)
                    Flexible(
                      child: Text(
                        '@$handle',
                        style: AppTypo.caption(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (tier != null && tier!.isNotEmpty) ...[
                    if (handle != null && handle!.isNotEmpty)
                      const SizedBox(width: AppSpacing.sm),
                    AyreChip(label: tier!, tone: ChipTone.info),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Destructive confirmation. Cancel is the visually primary action; Sign out
/// carries the Garnet weight.
class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign out?', style: AppTypo.sectionTitle(t)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You will need your username and password to sign back in on this '
            'device.',
            style: AppTypo.body(t),
          ),
          const SizedBox(height: AppSpacing.xl),
          AyreButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: AppSpacing.sm),
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
