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
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_masthead.dart';
import '../widgets/ayre_sheet.dart';
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
    final confirmed = await showAyreSheet<bool>(
      context: context,
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
    final p = t.mast;
    final auth = AuthService.instance;
    final verification = EmailVerificationService.instance;

    return AyreTabScroll(
      controller: widget.scrollController,
      eager: true,
      header: AyreMastScaffold(
        mast: AyreMasthead(
          overlap: AppShape.mastOverlap,
          constrainContent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Profile',
                  style: AppTypo.pageTitle(t, color: p.ink),
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                'Your account, alerts and help.',
                style: AppTypo.subtitle(t, color: p.muted),
              ),
            ],
          ),
        ),
        overlapChild: ListenableBuilder(
          listenable: auth.user,
          builder: (context, _) => _IdentityCard(
            key: TourKeys.profileIdentity,
            name: _name,
            email: _email,
            verified: auth.currentUser?.emailVerified,
            onTap: auth.currentUser == null ? null : _editProfile,
          ),
        ),
      ),
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([auth.user, verification]),
          builder: (context, _) {
            final user = auth.currentUser;
            if (user == null || user.emailVerified) {
              return const SizedBox.shrink();
            }
            final resendTitle = verification.sending
                ? 'Sending…'
                : (verification.cooldown > 0
                      ? 'Resend in ${verification.cooldown}s'
                      : 'Resend verification email');
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.s13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel(
                    label: 'Verify your email',
                    subtitle: 'Nothing is blocked while you wait.',
                    info:
                        'Open the verification link sent to your sign-in email, then check again here.',
                  ),
                  RowGroup(
                    key: TourKeys.profileVerify,
                    children: [
                      SettingRow(
                        glyph: AyreGlyph.mail,
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
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpace.s13),
        ListenableBuilder(
          listenable: NotificationLog.instance,
          builder: (context, _) {
            final unread = NotificationLog.instance.hasUnread;
            return RowGroup(
              children: [
                SettingRow(
                  key: TourKeys.profileAlerts,
                  glyph: AyreGlyph.bell,
                  title: 'Alerts',
                  subtitle: 'New signals, updates and exit calls',
                  status: unread ? 'New' : null,
                  trailing: unread
                      ? const AyreChip(label: 'New', tone: ChipTone.badge)
                      : null,
                  onTap: () => _push(const NotificationsScreen()),
                ),
                SettingRow(
                  key: TourKeys.profileSettings,
                  glyph: AyreGlyph.sliders,
                  title: 'Settings',
                  subtitle: 'Appearance, notifications and account',
                  onTap: () => _push(const SettingsScreen()),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const SectionLabel(
          label: 'Help',
          eyebrow: true,
          padding: EdgeInsets.only(bottom: AppSpace.s8),
        ),
        RowGroup(
          children: [
            SettingRow(
              key: TourKeys.profileSupport,
              glyph: AyreGlyph.support,
              title: 'Help and support',
              subtitle: 'Contact the team and replay tutorials',
              onTap: () => _push(const SupportScreen()),
            ),
            SettingRow(
              key: TourKeys.profileFaq,
              glyph: AyreGlyph.about,
              title: 'FAQ',
              subtitle: 'Answers to common questions',
              onTap: () => _push(const FaqScreen()),
            ),
            SettingRow(
              key: TourKeys.profileGrievance,
              glyph: AyreGlyph.insights,
              title: 'Grievance redressal',
              subtitle: 'Raise a complaint or concern',
              onTap: () => _push(const GrievanceScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s13),
        RowGroup(
          children: [
            SettingRow(
              key: TourKeys.profileLegal,
              glyph: AyreGlyph.shield,
              title: 'Legal and disclosures',
              subtitle: 'Terms, privacy, risk and analyst information',
              onTap: () => _push(LegalHubScreen(marketData: widget.marketData)),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s13),
        RowGroup(
          children: [
            SettingRow(
              key: TourKeys.profileSignOut,
              glyph: AyreGlyph.signOut,
              title: 'Sign out',
              subtitle: 'End this session on this device',
              enabled: !_signingOut,
              trailing: _signingOut
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.accent,
                      ),
                    )
                  : null,
              onTap: _signingOut ? null : _confirmSignOut,
            ),
          ],
        ),
      ],
    );
  }
}

/// The identity row: avatar, name, email and verification state. The whole
/// card is the "Edit profile" control, so there is no separate button.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    super.key,
    required this.name,
    required this.email,
    required this.verified,
    required this.onTap,
  });

  final String name;
  final String? email;

  /// Null when nobody is signed in, so no verification state is shown.
  final bool? verified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Semantics(
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      label: [
        if (onTap != null) 'Edit profile',
        name,
        ?email,
        if (verified != null)
          verified! ? 'Email verified' : 'Email not verified',
      ].join(', '),
      child: AyreCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpace.s21),
        strongShadow: true,
        notch: true,
        child: Row(
          children: [
            AyreAvatar(
              initials: initialsFor(name),
              size: 55,
              fontSize: 17,
              square: true,
            ),
            const SizedBox(width: AppSpace.s13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: AppTypo.cardTitle(t)),
                  if (email != null) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(email!, style: AppTypo.caption(t)),
                  ],
                  if (verified != null) ...[
                    const SizedBox(height: AppSpace.s8),
                    AyreChip(
                      label: verified! ? 'Verified' : 'Unverified',
                      tone: verified! ? ChipTone.success : ChipTone.attention,
                      glyph: verified! ? AyreGlyph.check : null,
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpace.s8),
              AyreIcon(AyreGlyph.forward, size: 18, color: t.foregroundMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet();

  @override
  Widget build(BuildContext context) {
    return AyreSheet(
      title: 'Sign out?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You will need your email and password to sign back in on this device.',
            style: AppTypo.reading(context.tokens),
          ),
          const SizedBox(height: AppSpace.s21),
          AyreButton(
            label: 'Cancel',
            kind: AyreButtonKind.outline,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: AppSpace.s13),
          AyreButton(
            label: 'Sign out',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
