import 'package:flutter/material.dart';

import '../legal/legal_content.dart';
import 'legal_document_screen.dart';

/// Terms and Conditions. The text lives in `lib/legal/legal_content.dart`
/// ([kTermsDocument]); personal details are filled in `lib/legal/legal_config.dart`.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      LegalDocumentScreen(document: kTermsDocument);
}
