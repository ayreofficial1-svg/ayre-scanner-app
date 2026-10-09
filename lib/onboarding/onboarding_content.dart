import '../widgets/ayre_icons.dart';

/// Which illustration a step uses. The screen maps each kind to a widget, so
/// this file stays free of layout and holds copy only.
enum OnboardingStepKind { orientation, tour }

/// One onboarding page. Immutable so the list below can be `const`.
class OnboardingStep {
  const OnboardingStep({
    required this.kind,
    required this.eyebrow,
    required this.title,
    this.body,
    this.notice,
  });

  final OnboardingStepKind kind;

  /// Uppercase micro-heading above the title.
  final String eyebrow;
  final String title;

  /// Lead line. Null on the second page, where the rows carry the content.
  final String? body;

  /// One-line caption under the illustration. Restates wording the app already
  /// carries elsewhere (FAQ, Risk Disclosure); it never links to legal text.
  final String? notice;
}

/// A row on the second page: where a feature lives.
class OnboardingFeature {
  const OnboardingFeature({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.location,
  });

  final AyreGlyph glyph;
  final String title;
  final String subtitle;

  /// Text of the neutral chip saying which tab holds the feature.
  final String location;
}

/// The two first-run pages. The detailed, element-by-element explanation lives
/// in the spotlight tutorial (`tour_content.dart`), so these stay deliberately
/// short.
///
/// Wording rules: no returns, accuracy or win-rate claims; no legal text; the
/// Weekly Report line says "reported results" and nothing broader until
/// `kWeeklyReportScope` is filled in.
const List<OnboardingStep> kOnboardingSteps = [
  OnboardingStep(
    kind: OnboardingStepKind.orientation,
    eyebrow: 'WELCOME',
    title: 'Your market, at a glance.',
    body: 'Index levels, research signals and lessons in one place.',
    notice: 'Signals are general research, not personal advice.',
  ),
  OnboardingStep(
    kind: OnboardingStepKind.tour,
    eyebrow: 'TRACK AND LEARN',
    title: 'See the record. Learn the market.',
    notice:
        'Past results are not an indication of future performance. You can '
        'change alerts any time in Settings.',
  ),
];

/// Index names shown as pills on the first page. Names only: no numbers or
/// arrows, so nothing reads as live data.
const List<String> kOnboardingIndexNames = ['NIFTY 50', 'SENSEX', 'BANK NIFTY'];

/// The second page's rows.
const List<OnboardingFeature> kOnboardingFeatures = [
  OnboardingFeature(
    glyph: AyreGlyph.trendUp,
    title: 'Weekly Report',
    subtitle: 'Picks from past weeks and their reported results.',
    location: 'Reports tab',
  ),
  OnboardingFeature(
    glyph: AyreGlyph.insights,
    title: 'Insights',
    subtitle: 'Gainers, losers, volume and momentum, explained simply.',
    location: 'Insights tab',
  ),
  OnboardingFeature(
    glyph: AyreGlyph.learn,
    title: 'Learn',
    subtitle: 'Short lessons to understand the stock market better.',
    location: 'Learn tab',
  ),
];

/// Control labels. Tooltips and semantics reuse these so they cannot drift.
abstract final class OnboardingLabels {
  static const String next = 'Next';
  static const String back = 'Back';
  static const String skip = 'Skip';
  static const String getStarted = 'Get started';

  /// Page indicator semantics, 1-based: "Step 2 of 2".
  static String step(int page, int total) => 'Step $page of $total';
}
