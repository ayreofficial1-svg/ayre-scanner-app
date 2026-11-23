import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/subscription_config.dart';
import '../services/subscription_models.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import '../widgets/paywall_widgets.dart';

/// What a subscriber sees: the status, the plan, a link to manage it in the
/// store, and Restore purchases.
class SubscriptionStatusScreen extends StatefulWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  State<SubscriptionStatusScreen> createState() =>
      _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final SubscriptionService _service = SubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    // Plans are only needed to turn the product ID into the store's plan name.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _service.plans.isEmpty && !_service.busy) {
        _service.loadPlans();
      }
    });
  }

  String? get _planName {
    final id = _service.activeProductId;
    if (id == null) return null;
    for (final plan in _service.plans) {
      if (plan.productId == id) return plan.title;
    }
    return null;
  }

  String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
        snackBarAnimationStyle: AppMotion.snackBarStyleOf(context),
      );
  }

  Future<void> _manage() async {
    HapticFeedback.selectionClick();
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? kIosManageSubscriptionsUrl
        : kAndroidManageSubscriptionsUrl;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // The device may not be able to open the store page.
    }
  }

  Future<void> _restore() async {
    if (_service.busy) return;
    HapticFeedback.selectionClick();
    final outcome = await _service.restore();
    if (!mounted) return;
    if (outcome.kind == SubscriptionOutcomeKind.success) {
      HapticFeedback.mediumImpact();
    }
    final message = restoreOutcomeMessage(outcome);
    if (message != null) _toast(message);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final t = context.tokens;
        final entitlement = _service.entitlement;
        final planName = _planName;
        final expiresAt = _service.expiresAt;
        final restoring =
            _service.operation == SubscriptionOperation.restoring;
        return AyrePageScaffold(
          title: 'Subscription',
          children: [
            AyreCard(
              featured: true,
              notch: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  switch (entitlement) {
                    EntitlementState.active => const AyreChip(
                      label: 'Active',
                      tone: ChipTone.success,
                      dot: true,
                    ),
                    EntitlementState.pending => const AyreChip(
                      label: 'Pending approval',
                      tone: ChipTone.attention,
                    ),
                    _ => const AyreChip(label: 'Not subscribed'),
                  },
                  if (planName != null) ...[
                    const SizedBox(height: AppSpace.s13),
                    Text(planName, style: AppTypo.sectionTitle(t)),
                  ],
                  // Only when the platform reports it reliably.
                  if (expiresAt != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Current period ends ${_date(expiresAt)}',
                      style: AppTypo.hint(t),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sectionGap),
            RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.sliders,
                  title: 'Manage subscription',
                  subtitle: 'Change or cancel it in your store account.',
                  onTap: _manage,
                ),
                SettingRow(
                  glyph: AyreGlyph.refresh,
                  title: 'Restore purchases',
                  subtitle: restoring
                      ? 'Restoring…'
                      : 'Get back a subscription you already bought.',
                  enabled: !_service.busy,
                  onTap: _service.busy ? null : _restore,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
