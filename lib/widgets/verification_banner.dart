import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/email_verification.dart';
import '../theme/app_theme.dart';
import 'ayre_icons.dart';

/// Shows a dismissible "verify your email" banner above [child] while the
/// account is unverified. Nothing is blocked.
///
/// The tree shape never changes whether or not the banner is showing, so the
/// tabs below keep their state when it appears or goes away.
class VerificationBannerHost extends StatelessWidget {
  const VerificationBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final service = EmailVerificationService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final visible = service.bannerVisible;
        return Column(
          children: [
            if (visible)
              SafeArea(bottom: false, child: const _VerificationBanner())
            else
              const SizedBox.shrink(),
            Expanded(
              // The banner already cleared the status bar, so the tabs below
              // must not pad for it a second time.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: visible,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs "Resend" with the shared cooldown and tells the user what happened.
Future<void> resendVerification(BuildContext context) async {
  final service = EmailVerificationService.instance;
  if (!service.canResend) return;
  HapticFeedback.selectionClick();
  final failure = await service.resend();
  if (!context.mounted) return;
  _toast(
    context,
    failure == null
        ? 'Verification email sent. Check your inbox and spam folder.'
        : failure.message,
  );
}

/// Runs "I've verified" and tells the user what happened.
Future<void> checkVerification(BuildContext context) async {
  final service = EmailVerificationService.instance;
  if (service.checking) return;
  HapticFeedback.selectionClick();
  final result = await service.recheck();
  if (!context.mounted) return;
  _toast(
    context,
    switch (result) {
      VerifyCheck.verified => 'Your email is verified. Thank you.',
      VerifyCheck.notYet =>
        "Not verified yet. Open the link in the email, then try again.",
      VerifyCheck.failed =>
        "Couldn't check right now. Check your connection and try again.",
    },
  );
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final service = EmailVerificationService.instance;
    final email = AuthService.instance.currentUser?.email ?? '';
    final isRequired = service.isRequired;

    final resendLabel = service.sending
        ? 'Sending…'
        : (service.cooldown > 0
              ? 'Resend in ${service.cooldown}s'
              : 'Resend email');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.pageHorizontal,
        AppSpace.xs,
        AppSpace.pageHorizontal,
        AppSpace.xs,
      ),
      child: Material(
        color: t.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: t.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.sm,
            AppSpace.xs,
            AppSpace.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AyreIcon(
                  AyreGlyph.account,
                  size: 16,
                  color: t.foregroundMuted,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRequired
                          ? 'Verify your email to continue'
                          : 'Verify your email',
                      style: AppTypo.bodyStrong(t, color: t.textPrimary),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      email.isEmpty
                          ? 'Open the link we emailed you.'
                          : 'We sent a link to $email.',
                      style: AppTypo.caption(t),
                    ),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: service.canResend
                              ? () => resendVerification(context)
                              : null,
                          child: Text(resendLabel),
                        ),
                        TextButton(
                          onPressed: service.checking
                              ? null
                              : () => checkVerification(context),
                          child: Text(
                            service.checking ? 'Checking…' : "I've verified",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isRequired)
                IconButton(
                  tooltip: 'Dismiss',
                  icon: AyreIcon(
                    AyreGlyph.close,
                    size: 16,
                    color: t.foregroundMuted,
                  ),
                  onPressed: service.dismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
