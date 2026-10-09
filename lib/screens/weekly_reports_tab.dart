import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_lifecycle.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_weekly_report.dart';
import '../widgets/state_views.dart';

/// Reports — the admin-entered Weekly Report (§A.3), as a tab of its own.
///
/// Owns the `GET /api/weekly-report` fetch. [WeeklyReportCard] draws its own
/// "Weekly Report" heading, week switcher and stock cards, so this tab adds
/// only the frame, pull-to-refresh and the loading / failed / empty states.
class WeeklyReportsTab extends StatefulWidget {
  const WeeklyReportsTab({
    super.key,
    required this.marketData,
    this.active = true,
  });

  final MarketDataService marketData;

  /// Whether this is the tab currently showing in the shell's
  /// [IndexedStack]; loading is deferred until it is first selected.
  final bool active;

  @override
  State<WeeklyReportsTab> createState() => _WeeklyReportsTabState();
}

class _WeeklyReportsTabState extends State<WeeklyReportsTab> {
  DataResult<List<WeeklyReport>>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load(initial: true);
    AppLifecycleService.instance.addListener(_onAppResumed);
  }

  /// Reloads silently if the app was away long enough for the report to be
  /// out of date.
  void _onAppResumed() {
    if (!mounted || !widget.active || _result == null) return;
    if (AppLifecycleService.instance.lastAway < const Duration(seconds: 30)) {
      return;
    }
    _load(initial: true);
  }

  @override
  void dispose() {
    AppLifecycleService.instance.removeListener(_onAppResumed);
    super.dispose();
  }

  @override
  void didUpdateWidget(WeeklyReportsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && _result == null) {
      _load(initial: true);
    }
  }

  Future<void> _load({bool initial = false}) async {
    final result = (await widget.marketData.getWeeklyReports())
        .keepingLastGood(_result);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
    // A refresh that lands new data confirms itself; opening the tab doesn't.
    if (!initial) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return RefreshIndicator(
      color: t.accentInk,
      backgroundColor: t.surface,
      onRefresh: _load,
      edgeOffset: 72,
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.pageHorizontal,
            AppSpace.pageTop,
            AppSpace.pageHorizontal,
            120,
          ),
          children: [
            SafeArea(bottom: false, child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const WeeklyReportSkeleton();

    final result = _result!;
    if (result.isFailed) {
      return StatePanel.failed(
        headline: "Weekly report didn't load",
        message: 'Pull down or try again in a moment.',
        onRetry: _load,
      );
    }

    final reports = result.value;
    if (result.isEmpty || reports == null || reports.isEmpty) {
      return const StatePanel.empty(
        headline: 'No weekly reports yet',
        message: 'Pull down to check again once a report is published.',
      );
    }

    return Entrance(child: WeeklyReportCard(reports: reports));
  }
}
