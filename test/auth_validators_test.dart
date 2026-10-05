import 'package:ayre_scanner/services/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('name', () {
    test('accepts letters, spaces, apostrophes, hyphens, dots', () {
      expect(AuthValidators.name("Anne-Marie O'Neil Jr."), isNull);
      expect(AuthValidators.name('राघव शर्मा'), isNull);
    });
    test('rejects empty, short, digits-only, long', () {
      expect(AuthValidators.name(' '), isNotNull);
      expect(AuthValidators.name('A'), isNotNull);
      expect(AuthValidators.name('12345'), isNotNull);
      expect(AuthValidators.name('a' * 61), isNotNull);
    });
  });

  group('email', () {
    test('format', () {
      expect(AuthValidators.email(' a@b.co '), isNull);
      expect(AuthValidators.email('a@b'), isNotNull);
      expect(AuthValidators.email(''), isNotNull);
    });
  });

  group('password', () {
    test('requires length, upper, lower, number; special optional', () {
      expect(PasswordCheck('Abcdefg1', '').valid, isTrue);
      expect(PasswordCheck('abcdefg1', '').valid, isFalse);
      expect(PasswordCheck('ABCDEFG1', '').valid, isFalse);
      expect(PasswordCheck('Abcdefgh', '').valid, isFalse);
      expect(PasswordCheck('Abc1', '').valid, isFalse);
      expect(PasswordCheck('Abcdefg1!', '').special, isTrue);
    });
    test('must not equal email', () {
      expect(PasswordCheck('Abcdefg1', 'abcdefg1').valid, isFalse);
    });
  });

  test('confirm', () {
    expect(AuthValidators.confirm('a', 'a'), isNull);
    expect(AuthValidators.confirm('a', 'b'), isNotNull);
  });
}
