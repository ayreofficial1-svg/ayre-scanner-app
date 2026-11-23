import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import '../widgets/clear_alert_history.dart';
import '../widgets/figure.dart';
import '../widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationLog.instance.markAllSeen();
  }

  Future<void> _clear() async {
    if (!await confirmClearAlertHistory(context) || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert history cleared')),
      snackBarAnimationStyle: AppMotion.snackBarStyleOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        NotificationLog.instance,
        SettingsStore.instance,
      ]),
      builder: (context, _) {
        final entries = NotificationLog.instance.entries;
        final today = <Notice>[];
        final earlier = <Notice>[];
        final date = DateUtils.dateOnly(DateTime.now());
        for (final notice in entries) {
          (DateUtils.isSameDay(notice.at.toLocal(), date) ? today : earlier)
              .add(notice);
        }

        return AyrePageScaffold(
          title: 'Alerts',
          trailing: entries.isEmpty
              ? null
              : TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(
                    foregroundColor: context.tokens.foregroundMuted,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s8,
                    ),
                  ),
                  child: const Text('Clear all', textAlign: TextAlign.center),
                ),
          children: [
            if (entries.isEmpty)
              StatePanel.empty(
                headline: 'Nothing recorded yet',
                message: SettingsStore.instance.inAppAlerts
                    ? 'New picks, updates and exit alerts appear here as they happen.'
                    : 'In-app alerts are switched off in Settings, so nothing is being recorded.',
                glyph: AyreGlyph.bell,
                pullToRefreshHint: false,
              ),
            if (today.isNotEmpty)
              _NoticeGroup(
                label: 'Today',
                notices: today,
                today: date,
                isToday: true,
              ),
            if (today.isNotEmpty && earlier.isNotEmpty)
              const SizedBox(height: AppSpace.sectionGap),
            if (earlier.isNotEmpty)
              _NoticeGroup(label: 'Earlier', notices: earlier, today: date),
          ],
        );
      },
    );
  }
}

class _NoticeGroup extends StatelessWidget {
  const _NoticeGroup({
    required this.label,
    required this.notices,
    required this.today,
    this.isToday = false,
  });

  final String label;
  final List<Notice> notices;
  final DateTime today;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final day = DateTime.utc(today.year, today.month, today.day);

    String timeLabel(DateTime timestamp) {
      if (isToday) return formatClockShort(timestamp);
      final local = timestamp.toLocal();
      final elapsed = day
          .difference(DateTime.utc(local.year, local.month, local.day))
          .inDays;
      return elapsed < 7
          ? localizations.formatMediumDate(local)
          : localizations.formatShortDate(local);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          label: label,
          eyebrow: true,
          padding: const EdgeInsets.only(bottom: AppSpace.s8),
        ),
        RowGroup(
          notch: isToday,
          children: [
            for (final notice in notices)
              _NoticeRow(notice: notice, time: timeLabel(notice.at)),
          ],
        ),
      ],
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice, required this.time});

  final Notice notice;
  final String time;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final glyph = switch (notice.kind) {
      NoticeKind.signal || NoticeKind.general => AyreGlyph.bell,
      NoticeKind.revised => AyreGlyph.refresh,
      NoticeKind.exit => AyreGlyph.about,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s21,
        vertical: AppSpace.hairlineRowPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppShape.iconTileSize,
            height: AppShape.iconTileSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surfaceRaised,
              borderRadius: AppShape.field,
            ),
            child: AyreIcon(glyph, size: 22, color: t.accentInk),
          ),
          const SizedBox(width: AppSpace.s13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpace.s8,
                  runSpacing: 3,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(notice.title, style: AppTypo.rowLabel(t)),
                    Text(
                      time,
                      style: AppTypo.num(
                        fontSize: 12,
                        color: t.foregroundMuted,
                      ),
                    ),
                  ],
                ),
                if (notice.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notice.body,
                    style: AppTypo.body(t, color: t.foregroundMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
