import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../onboarding/onboarding_content.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_logo.dart';
import '../widgets/onboarding_widgets.dart';
import '../widgets/pressable_scale.dart';

/// The two first-run pages: what Ayre is, and where the rest lives. The
/// element-by-element explanation is the spotlight tutorial that follows
/// sign-in.
///
/// It knows nothing about persistence. Skip and Get started both call
/// [onFinished]; `startTour` is true only for Get started, so the caller can
/// offer the tutorial to people who asked for it and leave the rest alone.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final void Function({required bool startTour}) onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  /// Set once Skip/Get started has fired, so a double tap finishes once.
  bool _finishing = false;

  /// Drives the fade-out on finish.
  double _opacity = 1;

  static final int _last = kOnboardingSteps.length - 1;

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (_finishing || page < 0 || page > _last) return;
    HapticFeedback.selectionClick();
    if (_reduce) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: AppMotion.pageTransition,
        curve: AppMotion.easeInOut,
      );
    }
  }

  Future<void> _finish({required bool startTour}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    if (!_reduce) {
      setState(() => _opacity = 0);
      await Future<void>.delayed(AppMotion.pageTransition);
    }
    if (mounted) widget.onFinished(startTour: startTour);
  }

  void _primary() {
    if (_page == _last) {
      HapticFeedback.mediumImpact();
      _finish(startTour: true);
    } else {
      _goTo(_page + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return PopScope(
      // Page 0 keeps the default back behaviour; later pages step back first.
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_page - 1);
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _goTo(_page + 1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _goTo(_page - 1),
          // Esc mirrors the visible Skip, which is hidden on the last page.
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_page < _last) _finish(startTour: false);
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: t.background,
            body: AnimatedOpacity(
              opacity: _opacity,
              duration: _reduce ? Duration.zero : AppMotion.pageTransition,
              curve: AppMotion.easeInOut,
              child: SafeArea(
                child: ContentWidth(
                  maxWidth: 480,
                  child: Column(
                    children: [
                      // Reference top is y = 55 including the safe inset.
                      SizedBox(
                        height: (55 - MediaQuery.paddingOf(context).top).clamp(
                          AppSpace.s13,
                          AppSpace.s55,
                        ),
                      ),
                      _TopBar(
                        showBack: _page > 0,
                        showExit: _page < _last,
                        onBack: () => _goTo(_page - 1),
                        onExit: () => _finish(startTour: false),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: kOnboardingSteps.length,
                          onPageChanged: (p) => setState(() => _page = p),
                          itemBuilder: (context, i) =>
                              _OnboardingPage(step: kOnboardingSteps[i]),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpace.gutterOf(context),
                          AppSpace.s21,
                          AppSpace.gutterOf(context),
                          AppSpace.s34,
                        ),
                        child: Row(
                          children: [
                            OnboardingPageIndicator(
                              page: _page,
                              total: kOnboardingSteps.length,
                            ),
                            const SizedBox(width: AppSpace.s13),
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: _page == _last ? 178 : 144,
                                  ),
                                  child: AyreButton(
                                    expand: false,
                                    label: _page == _last
                                        ? OnboardingLabels.getStarted
                                        : OnboardingLabels.next,
                                    onPressed: _finishing ? null : _primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.showExit,
    required this.onBack,
    required this.onExit,
  });

  final bool showBack;
  final bool showExit;
  final VoidCallback onBack;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpace.gutterOf(context)),
        child: Row(
          children: [
            const LogoMark(placement: LogoPlacement.auth),
            const Spacer(),
            if (showBack)
              Semantics(
                button: true,
                label: OnboardingLabels.back,
                onTap: onBack,
                excludeSemantics: true,
                child: Tooltip(
                  message: OnboardingLabels.back,
                  child: PressableScale(
                    onTap: onBack,
                    borderRadius: AppRadius.control,
                    child: SizedBox(
                      width: AppSpace.minTarget,
                      height: AppSpace.minTarget,
                      child: Center(
                        child: Container(
                          width: AppShape.iconTileSize,
                          height: AppShape.iconTileSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: AppShape.field,
                            border: Border.all(color: t.hairline),
                          ),
                          child: AyreIcon(
                            AyreGlyph.back,
                            size: 20,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (showExit)
              Flexible(
                child: TextButton(
                  onPressed: onExit,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppSpace.minTarget,
                      AppSpace.minTarget,
                    ),
                    foregroundColor: t.foregroundMuted,
                  ),
                  child: Text(
                    OnboardingLabels.skip,
                    style: AppTypo.button(t, color: t.foregroundMuted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gutter = AppSpace.gutterOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(15) / 15;
    final tour = step.kind == OnboardingStepKind.tour;

    final eyebrowAndTitle = Entrance(
      index: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.eyebrow, style: AppTypo.label(t, color: t.positiveText)),
          const SizedBox(height: AppSpace.s8),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(step.title, style: AppTypo.pageTitle(t)),
          ),
        ],
      ),
    );

    final notice = step.notice == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: AppSpace.s21),
            child: Text(step.notice!, style: AppTypo.meta(t)),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget top;
        final Widget bottom;

        if (tour) {
          top = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eyebrowAndTitle,
              const SizedBox(height: AppSpace.s34),
              const Entrance(index: 1, child: OnboardingFeatureRows()),
              const SizedBox(height: AppSpace.s13),
              const Entrance(index: 2, child: OnboardingLocationPills()),
            ],
          );
          bottom = notice ?? const SizedBox.shrink();
        } else {
          // The decorative bars take whatever height the copy leaves, scaled
          // down as a whole, and drop out on short windows or large text.
          final copyEstimate = 250 * textScale.clamp(1.0, 2.0);
          final leftover = constraints.maxHeight - copyEstimate;
          final barsHeight = (leftover - AppSpace.s34).clamp(0.0, 246.0);
          final showBars = textScale <= 1.4 && barsHeight >= 89;
          top = showBars
              ? Padding(
                  padding: EdgeInsets.only(top: (leftover - barsHeight) / 2),
                  child: Center(
                    child: Entrance(
                      index: 2,
                      child: OnboardingBars(height: barsHeight),
                    ),
                  ),
                )
              : const SizedBox.shrink();
          bottom = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eyebrowAndTitle,
              if (step.body != null) ...[
                const SizedBox(height: AppSpace.s13),
                Entrance(
                  index: 1,
                  child: Text(
                    step.body!,
                    style: AppTypo.ui(
                      fontSize: AppTextScale.rowLabel,
                      fontWeight: FontWeight.w500,
                      color: t.foregroundMuted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              ?notice,
            ],
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: AppSpace.s13,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 2 * AppSpace.s13).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [top, bottom],
            ),
          ),
        );
      },
    );
  }
}
