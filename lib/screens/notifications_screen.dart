import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/figure.dart';
import '../widgets/state_views.dart';

/// The destination behind Home's bell: a reverse-chronological list of what the
/// app has actually recorded, gated by the switches in Settings. An untouched
/// install shows the empty state, which is the honest reading.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the list is what marks it read, so the bell's dot clears.
    NotificationLog.instance.markAllSeen();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('Alerts'),
      ),
      body: ContentWidth(
        child: ListenableBuilder(
          listenable: NotificationLog.instance,
          builder: (context, _) {
            final entries = NotificationLog.instance.entries;
            if (entries.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpace.lg),
                children: [
                  StatePanel.empty(
                    headline: 'Nothing recorded yet',
                    message: SettingsStore.instance.inAppAlerts
                        ? 'New scanner picks and delayed-data warnings appear '
                              'here as they happen.'
                        : 'In-app alerts are switched off in Settings, so '
                              'nothing is being recorded.',
                    pullToRefreshHint: false,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.xxl,
              ),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
              itemBuilder: (context, index) =>
                  _NoticeCard(notice: entries[index]),
            );
          },
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Delayed data is time-sensitive attention, which is Ember's job.
    final (glyph, tone) = switch (notice.kind) {
      NoticeKind.staleData => (AyreGlyph.delayed, t.caution),
      NoticeKind.signal => (AyreGlyph.alerts, t.accentInk),
    };

    return AyreCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AyreIcon(glyph, size: 17, color: tone),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(notice.title, style: AppTypo.rowLabel(t)),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Figure.static(
                      formatClockShort(notice.at),
                      fontSize: 11,
                      color: t.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(notice.body, style: AppTypo.body(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
