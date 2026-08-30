import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_states.dart';
import '../widgets/numeral.dart';
import '../widgets/premium_widgets.dart';

/// The destination behind Home's notification bell: a reverse-chronological
/// list of what the app has actually recorded, gated by the switches in
/// Settings. Nothing here is sample data — an untouched install shows the empty
/// state, which is the honest reading.
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
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(title: const Text('Alerts')),
      body: ContentWidth(
        child: ListenableBuilder(
          listenable: NotificationLog.instance,
          builder: (context, _) {
            final entries = NotificationLog.instance.entries;
            if (entries.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  AppStateMessage(
                    icon: Icons.notifications_none_rounded,
                    heading: 'Nothing recorded yet',
                    message: SettingsStore.instance.inAppAlerts
                        ? 'New scanner picks and delayed-data warnings will '
                              'appear here as they happen.'
                        : 'In-app alerts are switched off in Settings, so '
                              'nothing is being recorded.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _NoticeCard(notice: entries[index]),
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
    final tokens = context.tokens;
    final (icon, tone) = switch (notice.kind) {
      // Delayed data is a time-sensitive, attention-needed state: one of the
      // sanctioned ember uses.
      NoticeKind.staleData => (Icons.schedule_rounded, tokens.accentWarm),
      NoticeKind.signal => (Icons.add_chart_rounded, tokens.primary),
    };

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: AppTypo.cardTitle(tokens).copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Numeral.static(
                      formatClock(notice.at),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: tokens.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(notice.body, style: AppTypo.body(tokens)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
