import 'package:ayre_scanner/onboarding/onboarding_content.dart';
import 'package:ayre_scanner/onboarding/tour_content.dart';
import 'package:flutter_test/flutter_test.dart';

final _banned = RegExp(
  r'\b(guarantee[ds]?|profits?|best|sure|returns?|win rate|accuracy)\b',
  caseSensitive: false,
);

int _words(String s) => s.trim().split(RegExp(r'\s+')).length;

void main() {
  group('welcome pages', () {
    List<String> allCopy() => [
      for (final s in kOnboardingSteps) ...[
        s.eyebrow,
        s.title,
        if (s.body != null) s.body!,
        if (s.notice != null) s.notice!,
      ],
      ...kOnboardingIndexNames,
      for (final f in kOnboardingFeatures) ...[f.title, f.subtitle, f.location],
    ];

    test('are exactly two, in order', () {
      expect(kOnboardingSteps, hasLength(2));
      expect(kOnboardingSteps.map((s) => s.kind), [
        OnboardingStepKind.orientation,
        OnboardingStepKind.tour,
      ]);
    });

    test('are short', () {
      expect(_words(kOnboardingSteps[0].body!), lessThanOrEqualTo(14));
      expect(kOnboardingSteps[1].body, isNull);
    });

    test('make no performance claims', () {
      for (final text in allCopy()) {
        expect(_banned.hasMatch(text), isFalse, reason: 'Banned word in: $text');
      }
    });

    test('both pages carry a notice without legal links', () {
      for (final s in kOnboardingSteps) {
        final n = s.notice ?? '';
        expect(n, isNotEmpty);
        expect(n.toLowerCase(), isNot(contains('terms')));
        expect(n.toLowerCase(), isNot(contains('privacy')));
        expect(n.toLowerCase(), isNot(contains('http')));
      }
    });

    test('weekly report line stays within "reported results"', () {
      final weekly = kOnboardingFeatures.firstWhere(
        (f) => f.title == 'Weekly Report',
      );
      expect(weekly.subtitle, contains('reported results'));
      expect(
        RegExp(r'\b(all|every|winning)\b', caseSensitive: false)
            .hasMatch(weekly.subtitle),
        isFalse,
      );
    });

    test('three index names and three feature rows', () {
      expect(kOnboardingIndexNames, ['NIFTY 50', 'SENSEX', 'BANK NIFTY']);
      expect(kOnboardingFeatures, hasLength(3));
    });

    test('labels', () {
      expect(OnboardingLabels.step(2, 2), 'Step 2 of 2');
      expect(OnboardingLabels.getStarted, 'Get started');
    });
  });

  group('app tutorial', () {
    final steps = buildAppTourSteps();

    test('covers all five tabs plus the two Home header controls', () {
      expect(steps, hasLength(7));
      expect(steps.map((s) => s.tab).toSet(), {0, 1, 2, 3, 4});
      expect(steps.map((s) => s.target), contains(TourKeys.homeTheme));
      expect(steps.map((s) => s.target), contains(TourKeys.homeAlerts));
    });

    test('targets are unique', () {
      expect(steps.map((s) => s.target).toSet(), hasLength(steps.length));
    });

    test('copy is brief and makes no performance claims', () {
      for (final s in steps) {
        expect(_words(s.body), lessThanOrEqualTo(26), reason: s.title);
        expect(_banned.hasMatch('${s.title} ${s.body}'), isFalse);
      }
    });
  });

  group('settings tutorial', () {
    test('has one step per group with unique targets', () {
      expect(kSettingsTourSteps, hasLength(5));
      expect(
        kSettingsTourSteps.map((s) => s.target).toSet(),
        hasLength(kSettingsTourSteps.length),
      );
    });

    test('only the account step needs a signed-in user', () {
      expect(
        kSettingsTourSteps.where((s) => s.needsAccount).map((s) => s.title),
        ['Account'],
      );
    });

    test('copy is brief', () {
      for (final s in kSettingsTourSteps) {
        expect(_words(s.body), lessThanOrEqualTo(24), reason: s.title);
      }
    });
  });
}
