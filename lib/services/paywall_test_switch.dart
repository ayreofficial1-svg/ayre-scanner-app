// TEMPORARY (paywall test toggle) — remove before production.
//
// Removal: delete this file and `lib/screens/testing/paywall_toggle_row.dart`;
// delete the import and the single `const PaywallTestingGroup()` line in
// `settings_screen.dart`; delete the `PaywallTestSwitch.instance.load()` entry
// and its import in `main.dart`; in `recommendation_access.dart` change the
// private `_paywallEnforced` getter to constant `true` and delete the import;
// delete `kShowPaywallTestToggle` in `subscription_config.dart`; in
// `SettingsStore.load()` add a one-line removal of the orphaned key
// `testing_paywall_enabled`. Full steps: section 9 of the plan.
//
// A device preference: it is not cleared on sign-out or account change.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaywallTestSwitch extends ChangeNotifier {
  PaywallTestSwitch._();

  static final PaywallTestSwitch instance = PaywallTestSwitch._();

  static const _kKey = 'testing_paywall_enabled';

  /// [DECISION D-7] ON by default, so a build that ships by accident fails
  /// closed (recommendations locked).
  static const bool defaultEnabled = true;

  bool _enabled = defaultEnabled;

  /// ON locks recommendations without a subscription. OFF shows them to
  /// everyone.
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kKey) ?? defaultEnabled;
    notifyListeners();
  }

  Future<void> set(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, value);
  }
}
