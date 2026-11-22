import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/market_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import 'privacy_policy_screen.dart';
import 'research_analyst_screen.dart';
import 'risk_disclosure_screen.dart';
import 'terms_screen.dart';

/// Every legal and regulatory document in one place, so Profile carries a
/// single "Legal and disclosures" row instead of a long list.
///
/// Grouped by what the reader is looking for: the agreements that apply to
/// using the app, then the Research Analyst regulatory material. Grievance
/// redressal stays under Help on Profile, where someone with a complaint
/// will look for it.
class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key, required this.marketData});

  final MarketDataService marketData;

  void _open(BuildContext context, Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(terminalRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return AyrePageScaffold(
      title: 'Legal and disclosures',
      children: [
        const SectionLabel(label: 'Using Investee', eyebrow: true),
        RowGroup(
          children: [
            SettingRow(
              glyph: AyreGlyph.document,
              title: 'Terms and Conditions',
              subtitle: 'The terms for using this app',
              onTap: () => _open(context, const TermsScreen()),
            ),
            SettingRow(
              glyph: AyreGlyph.shield,
              title: 'Privacy Policy',
              subtitle: 'How your information is handled',
              onTap: () => _open(context, const PrivacyPolicyScreen()),
            ),
            SettingRow(
              glyph: AyreGlyph.alerts,
              title: 'Risk Disclosure',
              subtitle: 'The risks of investing in securities',
              onTap: () => _open(context, const RiskDisclosureScreen()),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sectionGap),
        const SectionLabel(label: 'Research Analyst', eyebrow: true),
        RowGroup(
          children: [
            SettingRow(
              glyph: AyreGlyph.about,
              title: 'Registration and disclosures',
              subtitle: 'Our registration details and standard disclaimer',
              onTap: () =>
                  _open(context, ResearchAnalystScreen(marketData: marketData)),
            ),
            SettingRow(
              glyph: AyreGlyph.document,
              title: 'Most Important Terms and Conditions',
              subtitle: 'The MITC for research services',
              onTap: () => _open(context, const MitcScreen()),
            ),
            SettingRow(
              glyph: AyreGlyph.check,
              title: 'Investor Charter',
              subtitle: 'Your rights and our duties as an analyst',
              onTap: () => _open(context, const InvestorCharterScreen()),
            ),
          ],
        ),
      ],
    );
  }
}
