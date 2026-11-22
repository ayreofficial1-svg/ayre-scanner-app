import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_sheet.dart';

Future<bool> confirmClearAlertHistory(BuildContext context) async {
  final log = NotificationLog.instance;
  if (log.entries.isEmpty) return false;

  HapticFeedback.selectionClick();
  final confirmed = await showAyreSheet<bool>(
    context: context,
    builder: (sheetContext) => AyreSheet(
      title: 'Clear alert history?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This removes the alerts saved on this device. New alerts will '
            'still appear as they arrive.',
            style: AppTypo.reading(sheetContext.tokens),
          ),
          const SizedBox(height: AppSpace.s21),
          AyreButton(
            label: 'Cancel',
            kind: AyreButtonKind.outline,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
          const SizedBox(height: AppSpace.s13),
          AyreButton(
            label: 'Clear history',
            kind: AyreButtonKind.destructive,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted || log.entries.isEmpty) {
    return false;
  }

  HapticFeedback.mediumImpact();
  await log.clear();
  return true;
}
