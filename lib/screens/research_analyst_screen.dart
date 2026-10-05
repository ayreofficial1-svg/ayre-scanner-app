import 'package:flutter/material.dart';

import '../legal/legal_content.dart';
import '../services/market_data_service.dart';
import '../services/market_models.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/state_views.dart';
import 'legal_document_screen.dart';

/// Research Analyst information.
///
/// The registration number and standard disclaimer come from the backend
/// (`GET /api/compliance`, driven by the `RA_REG_NUMBER` environment variable)
/// exactly as before. No placeholder is ever shown in their place: a failed
/// fetch renders [StatePanel.failed] for that block only.
///
/// Below it, the full disclosure document ([kDisclosuresDocument]) is always
/// shown from the bundled text, so the required disclosures stay available
/// offline and never depend on the network.
class ResearchAnalystScreen extends StatefulWidget {
  const ResearchAnalystScreen({super.key, required this.marketData});

  final MarketDataService marketData;

  @override
  State<ResearchAnalystScreen> createState() => _ResearchAnalystScreenState();
}

class _ResearchAnalystScreenState extends State<ResearchAnalystScreen> {
  DataResult<ComplianceInfo>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final result = await widget.marketData.getComplianceInfo();
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final info = _result?.value;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('Research Analyst information'),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          children: [
            Text(
              'The registration details for the SEBI-registered Research '
              'Analyst behind this app.',
              style: AppTypo.body(t),
            ),
            const SizedBox(height: AppSpace.xl),
            if (_loading && info == null)
              const AyreCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 160, height: 14),
                    SizedBox(height: AppSpace.md),
                    SkeletonBlock(height: 12),
                    SizedBox(height: AppSpace.xs),
                    SkeletonBlock(height: 12),
                    SizedBox(height: AppSpace.xs),
                    SkeletonBlock(width: 220, height: 12),
                  ],
                ),
              )
            else if (info == null)
              StatePanel.failed(
                headline: "Couldn't load this",
                message: "The registration details didn't come through.",
                onRetry: _load,
              )
            else
              RowGroup(
                children: [
                  SettingRow(
                    glyph: AyreGlyph.about,
                    title: 'Registration number',
                    trailing: Text(
                      info.registrationNumber,
                      style: AppTypo.bodyStrong(t, color: t.foregroundMuted),
                    ),
                  ),
                ],
              ),
            if (info != null) ...[
              const SizedBox(height: AppSpace.xl),
              Text(info.disclaimer, style: AppTypo.caption(t)),
            ],
            const SizedBox(height: AppSpace.xl),
            const HairlineDivider(),
            LegalDocumentBody(document: kDisclosuresDocument),
          ],
        ),
      ),
    );
  }
}
