import 'package:ayre_scanner/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = AuthUser(
    uid: 'u1',
    email: 'raghav@example.com',
    displayName: 'Raghav',
    emailVerified: false,
  );

  test('shownName prefers the account name, then the email prefix', () {
    expect(base.shownName, 'Raghav');
    const noName = AuthUser(
      uid: 'u1',
      email: 'raghav@example.com',
      displayName: ' ',
      emailVerified: false,
    );
    expect(noName.shownName, 'raghav');
  });

  test('equality tracks every field, so listeners fire only on change', () {
    const same = AuthUser(
      uid: 'u1',
      email: 'raghav@example.com',
      displayName: 'Raghav',
      emailVerified: false,
    );
    const verified = AuthUser(
      uid: 'u1',
      email: 'raghav@example.com',
      displayName: 'Raghav',
      emailVerified: true,
    );
    expect(base, same);
    expect(base, isNot(verified));
  });
}
