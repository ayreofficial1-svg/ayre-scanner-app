import 'package:flutter/material.dart';

import '../legal/legal_content.dart';
import 'legal_document_screen.dart';

/// Privacy Policy. The text lives in `lib/legal/legal_content.dart`
/// ([kPrivacyDocument]); personal details are filled in `lib/legal/legal_config.dart`.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      LegalDocumentScreen(document: kPrivacyDocument);
}
