import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../legal/legal_config.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';

/// Grievance Redressal.
///
/// Sets out the three-step route SEBI prescribes for investors of Research
/// Analysts (the Research Analyst, then SCORES, then SMART ODR), the contact
/// details, and the monthly complaint-data table SEBI requires Research
/// Analysts to publish.
///
/// Update [_complaintMonth] and [_complaintRows] every month. The figures are
/// placeholders until you enter them; they are deliberately not pre-filled.
class GrievanceScreen extends StatelessWidget {
  const GrievanceScreen({super.key});

  static const String _scoresUrl = 'https://scores.sebi.gov.in';
  static const String _smartOdrUrl = 'https://smartodr.in';
  static const String _sebiTollFree = '1800 22 7575 / 1800 266 7575';
  static const String _sebiAddress =
      'Office of Investor Assistance and Education, Securities and Exchange '
      'Board of India, SEBI Bhavan, Plot No. C4-A, G Block, Bandra-Kurla '
      'Complex, Bandra (East), Mumbai – 400 051';

  /// Month the complaint table below covers.
  static const String _complaintMonth = '[MONTH YYYY]';

  /// Monthly complaint data. Replace each value with the real number.
  static const List<(String, String)> _complaintRows = [
    ('Complaints pending at the start of the month', '[0]'),
    ('Complaints received during the month', '[0]'),
    ('Complaints resolved during the month', '[0]'),
    ('Complaints pending at the end of the month', '[0]'),
    ('Of which pending for more than 3 months', '[0]'),
    ('Average time taken to resolve (days)', '[0]'),
  ];

  Future<void> _open(String url) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copy(BuildContext context, String value) async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AyrePageScaffold(
      title: 'Grievance redressal',
      children: [
        Text(
          'If you have a complaint about the research service, follow these '
          'steps in order. You do not have to pay to complain.',
          style: AppTypo.reading(t),
        ),
        const SizedBox(height: AppSpace.xl),

        Text('Step 1: the Research Analyst', style: AppTypo.sectionTitle(t)),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Write or call first. The Research Analyst will strive to resolve '
          'the complaint immediately and not later than 21 days from '
          'receiving it. Please include the e-mail address of your account, what happened and '
          'what you would like done.',
          style: AppTypo.reading(t),
        ),
        const SizedBox(height: AppSpace.md),
        RowGroup(
          children: [
            SettingRow(
              glyph: AyreGlyph.mail,
              title: kGrievanceEmail,
              subtitle: 'Complaints e-mail. Tap to copy.',
              trailing: AyreIcon(
                AyreGlyph.copy,
                size: 16,
                color: t.foregroundMuted,
              ),
              onTap: () => _copy(context, kGrievanceEmail),
            ),
            SettingRow(
              glyph: AyreGlyph.account,
              title: kGrievancePhone,
              subtitle: 'Complaints phone. Tap to copy.',
              trailing: AyreIcon(
                AyreGlyph.copy,
                size: 16,
                color: t.foregroundMuted,
              ),
              onTap: () => _copy(context, kGrievancePhone),
            ),
            SettingRow(
              glyph: AyreGlyph.about,
              title: kRaName,
              subtitle: kRaAddress,
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xl),
        Text('Step 2: SEBI SCORES', style: AppTypo.sectionTitle(t)),
        const SizedBox(height: AppSpace.sm),
        Text(
          'If you are not satisfied, or have had no reply in 21 days, '
          'lodge the complaint on SEBI’s SCORES portal (SCORES 2.0). '
          'SCORES first routes a complaint about a Research Analyst to '
          'RAASB for review, and then to SEBI if still unresolved. You can '
          'also write to RAASB at $kRaasbComplaintEmail.',
          style: AppTypo.reading(t),
        ),
        const SizedBox(height: AppSpace.md),
        RowGroup(
          children: [
            SettingRow(
              glyph: AyreGlyph.document,
              title: 'scores.sebi.gov.in',
              subtitle: 'Open the SCORES portal',
              onTap: () => _open(_scoresUrl),
            ),
            SettingRow(
              glyph: AyreGlyph.support,
              title: _sebiTollFree,
              subtitle: 'SEBI investor helpline. Tap to copy.',
              trailing: AyreIcon(
                AyreGlyph.copy,
                size: 16,
                color: t.foregroundMuted,
              ),
              onTap: () => _copy(context, _sebiTollFree),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xl),
        Text('Step 3: SMART ODR', style: AppTypo.sectionTitle(t)),
        const SizedBox(height: AppSpace.sm),
        Text(
          'If the matter is still not resolved, you can use the SMART ODR '
          '(Online Dispute Resolution) portal for online conciliation or '
          'arbitration.',
          style: AppTypo.reading(t),
        ),
        const SizedBox(height: AppSpace.md),
        RowGroup(
          children: [
            SettingRow(
              glyph: AyreGlyph.document,
              title: 'smartodr.in',
              subtitle: 'Open the SMART ODR portal',
              onTap: () => _open(_smartOdrUrl),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xl),
        Text('Write to SEBI', style: AppTypo.sectionTitle(t)),
        const SizedBox(height: AppSpace.sm),
        SelectableText(_sebiAddress, style: AppTypo.reading(t)),

        const SizedBox(height: AppSpace.xl),
        Text('Complaints about personal data', style: AppTypo.sectionTitle(t)),
        const SizedBox(height: AppSpace.sm),
        Text(
          'For privacy requests and complaints about your personal data, '
          'write to $kPrivacyContactName at $kPrivacyEmail. See the '
          'Privacy Policy for your rights and for further complaint routes.',
          style: AppTypo.reading(t),
        ),

        const SizedBox(height: AppSpace.xl),
        Text(
          'Complaint data: $_complaintMonth',
          style: AppTypo.sectionTitle(t),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Complaints received about this Research Analyst, as SEBI '
          'requires to be published each month.',
          style: AppTypo.caption(t),
        ),
        const SizedBox(height: AppSpace.md),
        RowGroup(
          children: [
            for (final row in _complaintRows)
              SettingRow(
                glyph: AyreGlyph.about,
                title: row.$1,
                trailing: Text(
                  row.$2,
                  style: AppTypo.bodyStrong(t, color: t.foregroundMuted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
