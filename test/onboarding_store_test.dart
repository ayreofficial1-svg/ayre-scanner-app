import 'package:ayre_scanner/services/auth_service.dart';
import 'package:ayre_scanner/services/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'onboarding_completed';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('OnboardingStore', () {
    test('starts unloaded and not completed', () {
      final store = OnboardingStore.forTest();
      expect(store.loaded, isFalse);
      expect(store.completed, isFalse);
    });

    test('unset flag loads as not completed', () async {
      final store = OnboardingStore.forTest();
      await store.load();
      expect(store.loaded, isTrue);
      expect(store.completed, isFalse);
    });

    test('stored flag loads as completed', () async {
      SharedPreferences.setMockInitialValues({key: true});
      final store = OnboardingStore.forTest();
      await store.load();
      expect(store.loaded, isTrue);
      expect(store.completed, isTrue);
    });

    test('markCompleted persists and notifies once', () async {
      final store = OnboardingStore.forTest();
      await store.load();
      var notified = 0;
      store.addListener(() => notified++);

      await store.markCompleted();
      await store.markCompleted(); // idempotent

      expect(store.completed, isTrue);
      expect(notified, 1);
      expect((await SharedPreferences.getInstance()).getBool(key), isTrue);

      final reloaded = OnboardingStore.forTest();
      await reloaded.load();
      expect(reloaded.completed, isTrue);
    });

    test('load after an earlier markCompleted keeps true', () async {
      final store = OnboardingStore.forTest();
      await store.markCompleted(); // raced ahead of load()
      SharedPreferences.setMockInitialValues({}); // nothing stored yet
      await store.load();
      expect(store.completed, isTrue);
      expect(store.loaded, isTrue);
    });

    test('a read failure fails open: loaded and completed', () async {
      // A non-bool value makes getBool throw.
      SharedPreferences.setMockInitialValues({key: 'not a bool'});
      final store = OnboardingStore.forTest();
      await store.load();
      expect(store.loaded, isTrue);
      expect(store.completed, isTrue);
    });
  });

  group('shouldShowOnboarding', () {
    test('true only for signedOut, loaded and not completed', () {
      for (final phase in AuthPhase.values) {
        for (final loaded in [false, true]) {
          for (final completed in [false, true]) {
            final expected =
                phase == AuthPhase.signedOut && loaded && !completed;
            expect(
              shouldShowOnboarding(
                phase: phase,
                loaded: loaded,
                completed: completed,
              ),
              expected,
              reason: '$phase loaded=$loaded completed=$completed',
            );
          }
        }
      }
    });
  });
}
