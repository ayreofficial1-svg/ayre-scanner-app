import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/subscription_models.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import '../widgets/paywall_widgets.dart';
import '../widgets/state_views.dart';
import 'subscription_status_screen.dart';

enum _Attempt { purchase, restore }

/// The paywall: benefits, the plans the store returns, Subscribe, Restore
/// purchases and the renewal disclosure. Opened full-screen on the root
/// navigator so the dock is covered; Back simply closes it.
///
/// Someone who is already subscribed sees the status screen instead.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  /// Opens the paywall above everything, including the dock.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      terminalRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _service = SubscriptionService.instance;

  String? _selectedId;
  bool _openedActive = false;
  bool _loadedOnce = false;
  bool _restoreIntent = false;
  String? _confirmation;
  _Attempt? _failedAttempt;
  String? _message;

  @override
  void initState() {
    super.initState();
    _openedActive = _service.entitlement == EntitlementState.active;
    _service.addListener(_onService);
    if (!_openedActive) {
      // After the first frame so listeners elsewhere are not notified while
      // the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onService);
    super.dispose();
  }

  /// A purchase that completes while this screen is open (including one that
  /// was waiting for approval) is confirmed here.
  void _onService() {
    if (!mounted || _openedActive || _confirmation != null) return;
    if (_service.entitlement == EntitlementState.active) {
      _confirm(_restoreIntent ? 'Subscription restored.' : "You're subscribed.");
    }
  }

  void _confirm(String text) {
    if (_confirmation != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _confirmation = text);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _loadPlans() async {
    await _service.loadPlans();
    if (mounted) setState(() => _loadedOnce = true);
  }

  SubscriptionPlan? get _selectedPlan {
    final plans = _service.plans;
    if (plans.isEmpty) return null;
    for (final plan in plans) {
      if (plan.productId == _selectedId) return plan;
    }
    return plans.first;
  }

  Future<void> _purchase() async {
    final plan = _selectedPlan;
    if (plan == null || _service.busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _failedAttempt = null;
      _message = null;
      _restoreIntent = false;
    });
    final outcome = await _service.purchase(plan);
    if (!mounted) return;
    if (outcome.kind == SubscriptionOutcomeKind.failed &&
        outcome.failure?.silent != true) {
      setState(() {
        _failedAttempt = _Attempt.purchase;
        _message =
            outcome.failure?.message ?? 'Something went wrong. Try again.';
      });
    }
  }

  Future<void> _restore() async {
    if (_service.busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _failedAttempt = null;
      _message = null;
      _restoreIntent = true;
    });
    final outcome = await _service.restore();
    if (!mounted) return;
    switch (outcome.kind) {
      case SubscriptionOutcomeKind.success:
        _confirm('Subscription restored.');
      case SubscriptionOutcomeKind.nothingFound:
        setState(() {
          _restoreIntent = false;
          _message = restoreOutcomeMessage(outcome);
        });
      case SubscriptionOutcomeKind.failed:
        setState(() {
          _restoreIntent = false;
          if (outcome.failure?.silent != true) {
            _failedAttempt = _Attempt.restore;
            _message = restoreOutcomeMessage(outcome);
          }
        });
      case SubscriptionOutcomeKind.pending:
      case SubscriptionOutcomeKind.cancelled:
      case SubscriptionOutcomeKind.ignored:
        setState(() => _restoreIntent = false);
    }
  }

  void _tryAgain() {
    switch (_failedAttempt) {
      case _Attempt.purchase:
        _purchase();
      case _Attempt.restore:
        _restore();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_openedActive) return const SubscriptionStatusScreen();
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final t = context.tokens;
        if (_confirmation != null) {
          return AyrePageScaffold(
            title: 'Unlock recommendations',
            children: [
              Semantics(
                container: true,
                liveRegion: true,
                child: AyreCard(
                  featured: true,
                  notch: true,
                  child: Column(
                    children: [
                      Container(
                        width: AppShape.prominentTileSize,
                        height: AppShape.prominentTileSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.surfaceRaised,
                          borderRadius: AppShape.field,
                        ),
                        child: AyreIcon(
                          AyreGlyph.check,
                          size: 24,
                          color: t.accentInk,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s13),
                      Text(
                        _confirmation!,
                        textAlign: TextAlign.center,
                        style: AppTypo.sectionTitle(t),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final plans = _service.plans;
        final failure = _service.lastFailure;
        final operation = _service.operation;
        final pending = _service.entitlement == EntitlementState.pending;
        final selected = _selectedPlan;
        final busy = _service.busy;
        final storeUnavailable =
            plans.isEmpty &&
            failure?.kind == SubscriptionFailureKind.storeUnavailable;
        final loadingPlans =
            plans.isEmpty &&
            (operation == SubscriptionOperation.loadingPlans ||
                (!_loadedOnce && failure == null));

        return AyrePageScaffold(
          title: 'Unlock recommendations',
          children: [
            // Hero
            AyreCard(
              featured: true,
              notch: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppShape.prominentTileSize,
                    height: AppShape.prominentTileSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surfaceRaised,
                      borderRadius: AppShape.field,
                    ),
                    child: AyreIcon(
                      AyreGlyph.lock,
                      size: 24,
                      color: t.foregroundMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s13),
                  Semantics(
                    header: true,
                    child: Text(
                      'Unlock recommendations',
                      style: AppTypo.sectionTitle(t),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    "Get the analyst's entry, exit and stop-loss levels and "
                    'the reasoning behind each pick.',
                    style: AppTypo.body(t),
                  ),
                ],
              ),
            ),

            // Benefits
            const SizedBox(height: AppSpace.sectionGap),
            const SectionLabel(
              label: 'What you get',
              eyebrow: true,
              padding: EdgeInsets.only(bottom: AppSpace.s8),
            ),
            const AyreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PaywallBenefitRow(
                    'Entry, exit and stop-loss levels for every recommendation',
                  ),
                  PaywallBenefitRow("The analyst's reasoning behind each pick"),
                  PaywallBenefitRow(
                    'Alerts when picks are added or updated',
                  ),
                ],
              ),
            ),

            // Pending approval
            if (pending) ...[
              const SizedBox(height: AppSpace.sectionGap),
              const PaywallNotice(
                glyph: AyreGlyph.delayed,
                message:
                    'Your purchase is waiting for approval. Recommendations '
                    'unlock when it completes.',
              ),
            ],

            // Plans
            const SizedBox(height: AppSpace.sectionGap),
            const SectionLabel(
              label: 'Choose a plan',
              eyebrow: true,
              padding: EdgeInsets.only(bottom: AppSpace.s8),
            ),
            if (loadingPlans)
              Semantics(
                label: 'Loading plans',
                liveRegion: true,
                child: const Column(
                  children: [
                    _PlanSkeleton(),
                    SizedBox(height: AppSpace.cardGap),
                    _PlanSkeleton(),
                  ],
                ),
              )
            else if (plans.isNotEmpty)
              Column(
                children: [
                  for (var i = 0; i < plans.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpace.cardGap),
                    PaywallPlanTile(
                      plan: plans[i],
                      selected: plans[i].productId == selected?.productId,
                      enabled: !busy && !pending,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedId = plans[i].productId);
                      },
                    ),
                  ],
                ],
              )
            else if (storeUnavailable)
              StatePanel.permanent(
                headline: 'Purchases unavailable',
                message: failure!.message,
              )
            else if (failure?.kind == SubscriptionFailureKind.offline)
              StatePanel.offline(
                message: 'Connect to the internet to see the plans.',
                onRetry: _loadPlans,
              )
            else
              StatePanel.failed(
                headline: "Plans couldn't load",
                message: 'Check your connection and try again.',
                onRetry: _loadPlans,
              ),

            // Failure or "nothing found" from the last action
            if (_message != null) ...[
              const SizedBox(height: AppSpace.cardGap),
              PaywallNotice(
                message: _message!,
                actionLabel: _failedAttempt == null ? null : 'Try again',
                onAction: _failedAttempt == null ? null : _tryAgain,
              ),
            ],

            // Actions
            if (plans.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s21),
              AyreButton(
                label: 'Subscribe',
                busy: operation == SubscriptionOperation.purchasing,
                onPressed: (busy || pending || selected == null)
                    ? null
                    : _purchase,
              ),
            ],
            if (!storeUnavailable) ...[
              const SizedBox(height: AppSpace.xs),
              PaywallTextAction(
                label: 'Restore purchases',
                busy: operation == SubscriptionOperation.restoring,
                onTap: busy ? null : _restore,
              ),
            ],

            // Footer
            const SizedBox(height: AppSpace.md),
            PaywallFooter(plan: selected),
          ],
        );
      },
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AyreCard(
      child: Row(
        children: [
          SkeletonBlock(width: 24, height: 24),
          SizedBox(width: AppSpace.s13),
          Expanded(child: SkeletonBlock(height: 14)),
          SizedBox(width: AppSpace.s13),
          SkeletonBlock(width: 56, height: 14),
        ],
      ),
    );
  }
}
