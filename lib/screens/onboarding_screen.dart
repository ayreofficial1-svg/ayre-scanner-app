import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../onboarding/onboarding_content.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_hills.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_logo.dart';
import '../widgets/onboarding_widgets.dart';
import '../widgets/responsive.dart';

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
        curve: AppMotion.ease,
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
              curve: AppMotion.ease,
              child: Stack(
                children: [
                  const Positioned(
                    top: -AppSpace.pageTop,
                    right: -AppSpace.pageHorizontal,
                    child: AyreHills(),
                  ),
                  SafeArea(
                    child: ContentWidth(
                      maxWidth: 480,
                      child: Column(
                        children: [
                          _TopBar(
                            showBack: _page > 0,
                            // Space is reserved on the last page so nothing
                            // shifts; the control is hidden there.
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
                            padding: const EdgeInsets.fromLTRB(
                              AppSpace.xl,
                              AppSpace.sm,
                              AppSpace.xl,
                              AppSpace.xl,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AyreButton(
                                  label: _page == _last
                                      ? OnboardingLabels.getStarted
                                      : OnboardingLabels.next,
                                  onPressed: _primary,
                                ),
                                const SizedBox(height: AppSpace.lg),
                                OnboardingPageIndicator(
                                  page: _page,
                                  total: kOnboardingSteps.length,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

    return SizedBox(
      height: AppSpace.minTarget + AppSpace.xs,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        child: Row(
          children: [
            SizedBox(
              width: AppSpace.minTarget,
              height: AppSpace.minTarget,
              child: showBack
                  ? IconButton(
                      tooltip: OnboardingLabels.back,
                      onPressed: onBack,
                      icon: AyreIcon(
                        AyreGlyph.back,
                        size: 20,
                        color: t.textPrimary,
                      ),
                    )
                  : null,
            ),
            const Spacer(),
            SizedBox(
              height: AppSpace.minTarget,
              child: showExit
                  ? TextButton(
                      onPressed: onExit,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          AppSpace.minTarget,
                          AppSpace.minTarget,
                        ),
                        foregroundColor: t.foregroundMuted,
                      ),
                      child: Text(OnboardingLabels.skip, style: AppTypo.button(t)),
                    )
                  : null,
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
    final compact = AppBreakpoints.isCompact(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Short viewports and large text drop the decorative illustration on
        // page 1; page 2's rows are the content, so they stay.
        final roomy = constraints.maxHeight >= 420 && textScale <= 1.4;

        final Widget? illustration = switch (step.kind) {
          OnboardingStepKind.orientation =>
            roomy ? _Orientation(compact: compact) : null,
          OnboardingStepKind.tour => const OnboardingFeatureRows(),
        };
        // On the tour page the rows follow the heading; elsewhere the
        // illustration leads and the text follows it.
        final illustrationFirst = step.kind != OnboardingStepKind.tour;

        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Entrance(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.eyebrow,
                    style: AppTypo.label(t, color: t.accentInk),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      step.title,
                      style: AppTypo.display(
                        fontSize: compact
                            ? AppTextScale.page
                            : AppTextScale.greeting,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (step.body != null) ...[
              const SizedBox(height: AppSpace.sm),
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
          ],
        );

        final notice = step.notice == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: AppSpace.md),
                child: Text(
                  step.notice!,
                  style: AppTypo.caption(t, color: t.foregroundMuted),
                ),
              );

        final wrappedIllustration = illustration == null
            ? null
            : Entrance(index: 2, child: illustration);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.xs,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (illustrationFirst && wrappedIllustration != null) ...[
                  wrappedIllustration,
                  const SizedBox(height: AppSpace.xl),
                ],
                text,
                if (!illustrationFirst && wrappedIllustration != null) ...[
                  const SizedBox(height: AppSpace.xl),
                  wrappedIllustration,
                ],
                ?notice,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Screen 1's illustration: wash, logo and index pills. The logo appears only
/// here, per the brand rule that it is not repeated on every step.
class _Orientation extends StatelessWidget {
  const _Orientation({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        alignment: Alignment.center,
        children: [
          OnboardingWash(size: compact ? 240 : 300),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LogoMark(placement: LogoPlacement.auth),
              SizedBox(height: AppSpace.md),
              OnboardingIndexPills(),
            ],
          ),
        ],
      ),
    );
  }
}
