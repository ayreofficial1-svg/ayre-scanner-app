import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/account_session.dart';
import '../services/auth_service.dart';
import '../services/email_verification.dart';
import '../services/market_data_service.dart';
import '../onboarding/tour_content.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_avatar.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_hills.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_tab_scroll.dart';
import '../widgets/verification_banner.dart'
    show resendVerification, checkVerification;
import 'edit_profile_screen.dart';
import 'faq_screen.dart';
import 'grievance_screen.dart';
import 'home_shell.dart' show initialsFor;
import 'legal_hub_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart' show SupportScreen;

/// Profile — who you are, what the app has told you, where to get help, and
/// how to leave.
///
/// Laid out as inset groups in the order people reach for them:
///
/// 1. Identity (tap to edit — the only way into Edit profile)
/// 2. Email verification, only while the address is unconfirmed
/// 3. Alerts and Settings
/// 4. Help
/// 5. Legal and disclosures
/// 6. Sign out, alone at the bottom
///
/// Preferences, account security, version and credits live in Settings, so
/// nothing is listed in both places.
class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.accountName,
    required this.marketData,
    this.scrollController,
  });

  final String accountName;
  final MarketDataService marketData;

  /// Optional controller for the tab's scroll view (A2: re-tap scrolls to
  /// top). Null keeps the previous behaviour.
  final ScrollController? scrollController;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _signingOut = false;

  String? get _email {
    final email = AuthService.instance.currentUser?.email;
    return (email == null || email.isEmpty) ? null : email;
  }

  /// The shell resolves the saved name over the session's, so what it hands
  /// down wins; the session value only covers the moment before it has one.
  String get _name {
    final resolved = widget.accountName.trim().isNotEmpty
        ? widget.accountName.trim()
        : (AuthService.instance.currentUser?.displayName.trim() ?? '');
    return resolved.isEmpty ? 'Your account' : resolved;
  }

  void _push(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(terminalRoute(builder: (_) => screen));
  }

  Future<void> _editProfile() async {
    HapticFeedback.selectionClick();
    final updated = await Navigator.of(context).push<String>(
      terminalRoute(
        builder: (_) => EditProfileScreen(displayName: _name, handle: _email),
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
    // The startup gate returns to Sign in by itself once the account signs
    // out, and clears the navigation stack.
    await AccountSession.signOut();
    if (!mounted) return;
    setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // `eager`: a plain Column so every row exists at once and the Profile
    // tutorial can find and scroll to any of them. The list is short.
    return AyreTabScroll(
      controller: widget.scrollController,
      eager: true,
      children: [
          // Same soft layered shape as Home's header, bled to the top-right
          // corner behind the title. Decorative, not part of the layout.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -AppSpace.pageTop,
                right: -AppSpace.gutterOf(context),
                child: AyreHills(),
              ),
              SafeArea(
                bottom: false,
                child: Entrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profile', style: AppTypo.pageTitle(t)),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        'Your account, alerts and help.',
                        style: AppTypo.body(t),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sectionGap),

          // ── Identity ─────────────────────────────────────────────────────
          Entrance(
            index: 1,
            child: ListenableBuilder(
              listenable: AuthService.instance.user,
              builder: (context, _) => KeyedSubtree(
 key: TourKeys.profileIdentity,
 child: _IdentityCard(
                name: _name,
                email: _email,
                verified: AuthService.instance.currentUser?.emailVerified,
                onTap: _editProfile,
              ),
 ),
            ),
          ),

          // ── Email verification (only while it is outstanding) ────────────
          ListenableBuilder(
            listenable: Listenable.merge([
              AuthService.instance.user,
              EmailVerificationService.instance,
            ]),
            builder: (context, _) {
              final user = AuthService.instance.currentUser;
              if (user == null || user.emailVerified) {
                return const SizedBox.shrink();
              }
              final verification = EmailVerificationService.instance;
              final resendTitle = verification.sending
                  ? 'Sending…'
                  : (verification.cooldown > 0
                        ? 'Resend in ${verification.cooldown}s'
                        : 'Resend verification email');
              return Padding(
                padding: const EdgeInsets.only(top: AppSpace.sectionGap),
                child: Entrance(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel(
                        label: 'Verify your email',
                        subtitle: 'Nothing is blocked while you wait.',
                      ),
                      KeyedSubtree(
 key: TourKeys.profileVerify,
 child: RowGroup(
                        children: [
                          SettingRow(
                            glyph: AyreGlyph.refresh,
                            title: resendTitle,
                            subtitle: 'Sends a new link to your inbox',
                            enabled: verification.canResend,
                            onTap: verification.canResend
                                ? () => resendVerification(context)
                                : null,
                          ),
                          SettingRow(
                            glyph: AyreGlyph.check,
                            title: verification.checking
                                ? 'Checking…'
                                : 'I’ve verified my email',
                            subtitle: 'Tap after opening the link',
                            enabled: !verification.checking,
                            onTap: verification.checking
                                ? null
                                : () => checkVerification(context),
                          ),
                        ],
                      ),
 ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Alerts and Settings ──────────────────────────────────────────
          const SizedBox(height: AppSpace.sectionGap),
          Entrance(
            index: 3,
            child: ListenableBuilder(
              listenable: NotificationLog.instance,
              builder: (context, _) => RowGroup(
                children: [
                  KeyedSubtree(
 key: TourKeys.profileAlerts,
 child: SettingRow(
                    glyph: AyreGlyph.bell,
                    title: 'Alerts',
                    subtitle: 'New signals, updates and exit calls',
                    trailing: NotificationLog.instance.hasUnread
                        ? const AyreChip(label: 'New', tone: ChipTone.brand)
                        : null,
                    onTap: () => _push(const NotificationsScreen()),
                  ),
 ),
                  KeyedSubtree(
 key: TourKeys.profileSettings,
 child: SettingRow(
                    glyph: AyreGlyph.appearance,
                    title: 'Settings',
                    subtitle: 'Appearance, notifications and account',
                    onTap: () => _push(const SettingsScreen()),
                  ),
 ),
                ],
              ),
            ),
          ),

          // ── Help ─────────────────────────────────────────────────────────
          const SizedBox(height: AppSpace.sectionGap),
          Entrance(
            index: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(label: 'Help'),
                RowGroup(
                  children: [
                    KeyedSubtree(
 key: TourKeys.profileSupport,
 child: SettingRow(
                      glyph: AyreGlyph.support,
                      title: 'Help and support',
                      subtitle: 'Contact the team and replay tutorials',
                      onTap: () => _push(const SupportScreen()),
                    ),
 ),
                    KeyedSubtree(
 key: TourKeys.profileFaq,
 child: SettingRow(
                      glyph: AyreGlyph.about,
                      title: 'FAQ',
                      subtitle: 'Answers to common questions',
                      onTap: () => _push(const FaqScreen()),
                    ),
 ),
                    KeyedSubtree(
 key: TourKeys.profileGrievance,
 child: SettingRow(
                      glyph: AyreGlyph.alerts,
                      title: 'Grievance redressal',
                      subtitle: 'Raise a complaint or concern',
                      onTap: () => _push(const GrievanceScreen()),
                    ),
 ),
                  ],
                ),
              ],
            ),
          ),

          // ── Legal ────────────────────────────────────────────────────────
          const SizedBox(height: AppSpace.sectionGap),
          Entrance(
            index: 5,
            child: RowGroup(
              children: [
                KeyedSubtree(
 key: TourKeys.profileLegal,
 child: SettingRow(
                  glyph: AyreGlyph.lock,
                  title: 'Legal and disclosures',
                  subtitle: 'Terms, privacy, risk and analyst information',
                  onTap: () =>
                      _push(LegalHubScreen(marketData: widget.marketData)),
                ),
 ),
              ],
            ),
          ),

          // ── Sign out ─────────────────────────────────────────────────────
          const SizedBox(height: AppSpace.xl),
          Entrance(
            index: 6,
            child: RowGroup(
              children: [
                KeyedSubtree(
 key: TourKeys.profileSignOut,
 child: SettingRow(
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
 ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The identity row: avatar, name, email and verification state. The whole
/// card is the "Edit profile" control, so there is no separate button.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.verified,
    required this.onTap,
  });

  final String name;
  final String? email;

  /// Null when nobody is signed in, so no verification state is shown.
  final bool? verified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: [
        'Edit profile',
        name,
        ?email,
        if (verified != null) verified! ? 'Email verified' : 'Email not verified',
      ].join(', '),
      child: AyreCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            AyreAvatar(initials: initialsFor(name), size: 56, fontSize: 20),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTypo.cardTitle(t),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email != null) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      email!,
                      style: AppTypo.caption(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (verified != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    AyreChip(
                      label: verified! ? 'Verified' : 'Unverified',
                      tone: verified! ? ChipTone.brand : ChipTone.attention,
                      glyph: verified! ? AyreGlyph.check : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            AyreIcon(AyreGlyph.forward, size: 16, color: t.foregroundSubtle),
          ],
        ),
      ),
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
            'You will need your email and password to sign back in on this '
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