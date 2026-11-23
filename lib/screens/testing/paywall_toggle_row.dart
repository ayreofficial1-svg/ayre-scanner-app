// TEMPORARY (paywall test toggle) — remove before production.
//
// Removal: delete this file and `lib/services/paywall_test_switch.dart`, then
// delete the import and the single `const PaywallTestingGroup()` line in
// `settings_screen.dart`. See `paywall_test_switch.dart` for the other places.
//
// The "Testing" group in Settings with one switch that turns the paywall ON
// or OFF on this device.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/paywall_test_switch.dart';
import '../../services/subscription_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ayre_components.dart';
import '../../widgets/ayre_icons.dart';

class PaywallTestingGroup extends StatelessWidget {
  const PaywallTestingGroup({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kShowPaywallTestToggle) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.sectionGap),
        const SectionLabel(
          label: 'Testing',
          eyebrow: true,
          padding: EdgeInsets.only(bottom: AppSpace.s8),
        ),
        ListenableBuilder(
          listenable: PaywallTestSwitch.instance,
          builder: (context, _) {
            final value = PaywallTestSwitch.instance.enabled;
            void toggle(bool next) {
              HapticFeedback.mediumImpact();
              PaywallTestSwitch.instance.set(next);
            }

            return RowGroup(
              children: [
                SettingRow(
                  glyph: AyreGlyph.lock,
                  title: 'Paywall',
                  subtitle:
                      'Testing only. ON locks recommendations without a '
                      'subscription. OFF shows them to everyone.',
                  toggled: value,
                  onTap: () => toggle(!value),
                  trailing: ExcludeFocus(
                    child: IgnorePointer(
                      child: AyreSwitch(value: value, onChanged: toggle),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
