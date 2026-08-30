import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_states.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';
import 'edit_profile_screen.dart';
import 'home_shell.dart' show initialsFor;
import 'login_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';

/// Profile is a peer tab, reachable from anywhere via the nav bar. Because of
/// that no other tab carries its own avatar entry point, and Home's header
/// avatar simply selects this tab.
///
/// Settings and Edit Profile are pushed routes reached only from here — pushing
/// either hides the bottom nav for the duration and comes back on return.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.displayName});

  final String displayName;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _handle;
  String? _sessionName;
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
    });
  }

  /// The shell already resolves the saved display name over the session's, so
  /// what it passes down wins; the session value is only a fallback for the
  /// moment before the shell has one.
  String get _name {
    final resolved = widget.displayName.trim().isNotEmpty
        ? widget.displayName.trim()
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
    ConfirmationBanner.show(context, 'Profile updated');
  }

  Future<void> _confirmSignOut() async {
    // Warning weight on open: this sheet leads somewhere consequential.
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
    final tokens = context.tokens;

    return PremiumScaffold(
      section: AyreSection.profile,
      bottomSafe: false,
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            140,
          ),
          children: [
            AnimatedEntrance(
              child: Text('Profile', style: AppTypo.pageTitle(tokens)),
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 80),
              child: _IdentityBlock(name: _name, handle: _handle),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 120),
              child: _MenuGroup(
                children: [
                  ProfileRow(
                    icon: Icons.badge_outlined,
                    title: 'Edit profile',
                    subtitle: 'Change the name shown across the app',
                    onTap: _editProfile,
                  ),
                  const HairlineDivider(indent: 60),
                  ProfileRow(
                    icon: Icons.tune_rounded,
                    title: 'Settings',
                    subtitle: 'Alerts, appearance and account details',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  // A "Saved / Watchlist" tile used to sit here alongside these
                  // two. There is no saved-items feature in the app or the
                  // backend, so the tile is gone rather than dead.
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // The session block is visually separated from the routine menu
            // above: this is where the consequential actions live.
            AnimatedEntrance(
              delay: const Duration(milliseconds: 160),
              child: Text('SESSION', style: AppTypo.microLabel(tokens)),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 180),
              child: _MenuGroup(
                color: tokens.backgroundTint,
                children: [
                  ProfileRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help and support',
                    subtitle: 'Email the team about a problem or a question',
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
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    subtitle: 'End this session on this device',
                    destructive: true,
                    trailing: _signingOut
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: tokens.negative,
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
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.name, required this.handle});

  final String name;
  final String? handle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PremiumCard(
      radius: AppRadius.heroCard,
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: tokens.surface,
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.primary, width: 1.2),
            ),
            child: Text(
              initialsFor(name),
              style: AppTypo.serif(
                fontSize: 22,
                color: tokens.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypo.sectionTitle(tokens),
                ),
                if (handle != null && handle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text('@${handle!}', style: AppTypo.body(tokens)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children, this.color});

  final List<Widget> children;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      color: color ?? context.tokens.surface,
      child: Column(children: children),
    );
  }
}

/// A grouped-list row shared by Profile and Settings, so both screens use one
/// row grammar and one disclosure convention: a chevron where the row
/// navigates, a switch where it toggles.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Replaces the chevron — pass a switch, a value, or a spinner.
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tone = destructive ? tokens.negative : tokens.textSecondary;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 20),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypo.cardTitle(
                    tokens,
                    color: destructive ? tokens.negative : null,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypo.caption(tokens)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          trailing ??
              (onTap == null
                  ? const SizedBox.shrink()
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: tokens.textTertiary,
                      size: 20,
                    )),
        ],
      ),
    );

    if (onTap == null) return row;
    return PressableScale(onTap: onTap, borderRadius: 0, child: row);
  }
}

/// Destructive confirmation. Cancel is the visually primary action; Sign Out
/// carries the `negative` weight.
class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign out?', style: AppTypo.sectionTitle(tokens)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You will need your username and password to sign back in on this '
            'device.',
            style: AppTypo.body(tokens),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: tokens.negative,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: AppTypo.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
