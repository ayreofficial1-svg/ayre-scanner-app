import 'package:ayre_scanner/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App theme exposes design tokens', (tester) async {
    AppThemeTokens? tokens;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            tokens = context.tokens;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    expect(tokens, isNotNull);
    expect(tokens!.primary, const Color(0xFF2FE27E));
    expect(tokens!.neutralBlock, const Color(0xFF111312));
  });
}
