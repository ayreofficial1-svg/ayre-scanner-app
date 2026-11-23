import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/privacy_policy_screen.dart';
import '../screens/terms_screen.dart';
import '../services/subscription_models.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';
import 'pressable_scale.dart';

/// The app's existing general-research line (same wording as the first-run
/// page in `onboarding_content.dart`).
const String kPaywallResearchNotice =
    'Signals are general research, not personal advice.';

/// What to tell the person after a restore, or null when nothing should be
/// said (cancelled, or another operation was already running).
String? restoreOutcomeMessage(SubscriptionOutcome outcome) {
  return switch (outcome.kind) {
    SubscriptionOutcomeKind.success => 'Subscription restored.',
    SubscriptionOutcomeKind.nothingFound =>
      'No active subscription was found for this store account.',
    SubscriptionOutcomeKind.pending =>
      'Your purchase is waiting for approval.',
    SubscriptionOutcomeKind.failed =>
      outcome.failure?.silent == true
          ? null
          : (outcome.failure?.message ?? 'Something went wrong. Try again.'),
    SubscriptionOutcomeKind.cancelled ||
    SubscriptionOutcomeKind.ignored => null,
  };
}

/// One selectable plan. Every word and number comes from the store's product
/// data; a missing field is simply left out.
class PaywallPlanTile extends StatelessWidget {
  const PaywallPlanTile({
    super.key,
    required this.plan,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final detail = [?plan.period, ?plan.trial].join(' · ');
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      checked: selected,
      button: true,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      label: [
        plan.title,
        plan.price,
        if (detail.isNotEmpty) detail,
      ].join(', '),
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: AyreCard(
          onTap: enabled ? onTap : null,
          accentEdge: selected,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? t.accent : AppTheme.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: selected ? t.accent : t.foregroundSubtle,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? AyreIcon(AyreGlyph.check, size: 14, color: t.onAccent)
                    : null,
              ),
              const SizedBox(width: AppSpace.s13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: AppTypo.rowLabel(t)),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(detail, style: AppTypo.hint(t)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Flexible(
                child: Text(
                  plan.price,
                  textAlign: TextAlign.end,
                  style: AppTypo.rowLabel(t),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A line in the "what you get" list.
class PaywallBenefitRow extends StatelessWidget {
  const PaywallBenefitRow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AyreIcon(AyreGlyph.check, size: 16, color: t.accentInk),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(text, style: AppTypo.body(t))),
        ],
      ),
    );
  }
}

/// A calm inline message with an optional single action. Never red.
class PaywallNotice extends StatelessWidget {
  const PaywallNotice({
    super.key,
    required this.message,
    this.glyph = AyreGlyph.about,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AyreGlyph glyph;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      liveRegion: true,
      child: AyreCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppShape.iconTileSize,
                  height: AppShape.iconTileSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surfaceRaised,
                    borderRadius: AppShape.field,
                  ),
                  child: AyreIcon(glyph, size: 22, color: t.foregroundMuted),
                ),
                const SizedBox(width: AppSpace.s13),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Text(message, style: AppTypo.bodyStrong(t)),
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.s13),
              AyreButton(
                label: actionLabel!,
                kind: AyreButtonKind.outline,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A text-style action row (Restore purchases).
class PaywallTextAction extends StatelessWidget {
  const PaywallTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: busy ? '$label, in progress' : label,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: PressableScale(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
          child: Center(
            child: Text(
              busy ? '$label…' : label,
              textAlign: TextAlign.center,
              style: AppTypo.rowLabel(
                t,
                color: enabled ? t.accentInk : t.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The auto-renewal disclosure, Terms and Privacy links, and the general
/// research line. The selected plan's price comes from the store.
class PaywallFooter extends StatelessWidget {
  const PaywallFooter({super.key, this.plan});

  final SubscriptionPlan? plan;

  String get _disclosure => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS =>
      'Payment is charged to your Apple ID account when you confirm the '
          'purchase. The subscription renews automatically unless it is '
          'cancelled at least 24 hours before the end of the current period. '
          'Your account is charged for renewal within 24 hours before the end '
          'of the current period. You can manage or cancel it in your Apple '
          'ID account settings.',
    TargetPlatform.android =>
      'Payment is charged to your Google Play account. The subscription '
          'renews automatically until you cancel it. You can manage or cancel '
          'it at any time in Google Play, under Subscriptions.',
    _ =>
      'The subscription renews automatically until you cancel it. You can '
          'manage or cancel it in your store account.',
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final selected = plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected != null) ...[
          Text(
            [selected.title, selected.price, ?selected.period].join(' · '),
            style: AppTypo.caption(t, color: t.textPrimary),
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        Text(_disclosure, style: AppTypo.caption(t)),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.md,
          children: [
            _FooterLink(
              label: 'Terms',
              onTap: () => _open(context, (_) => const TermsScreen()),
            ),
            _FooterLink(
              label: 'Privacy Policy',
              onTap: () => _open(context, (_) => const PrivacyPolicyScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(kPaywallResearchNotice, style: AppTypo.caption(t)),
      ],
    );
  }

  void _open(BuildContext context, WidgetBuilder builder) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(terminalRoute<void>(builder: builder));
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
          child: Align(
            widthFactor: 1,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: AppTypo.rowLabel(t, color: t.accentInk),
            ),
          ),
        ),
      ),
    );
  }
}
