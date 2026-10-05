import 'package:flutter/material.dart';

import '../legal/legal_content.dart';
import 'legal_document_screen.dart';

/// Risk Disclosure ([kRiskDocument]).
class RiskDisclosureScreen extends StatelessWidget {
  const RiskDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      LegalDocumentScreen(document: kRiskDocument);
}

/// Most Important Terms and Conditions ([kMitcDocument]).
class MitcScreen extends StatelessWidget {
  const MitcScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      LegalDocumentScreen(document: kMitcDocument);
}

/// Investor Charter for Research Analysts ([kInvestorCharterDocument]).
class InvestorCharterScreen extends StatelessWidget {
  const InvestorCharterScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      LegalDocumentScreen(document: kInvestorCharterDocument);
}
