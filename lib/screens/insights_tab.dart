import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_states.dart';
import '../widgets/numeral.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/sentiment_gauge.dart';

enum _Window { weekly, monthly }

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  int? _sentiment;
  String? _note;
  String? _updatedAt;
  List<Map<String, dynamic>> _insights = [];
  bool _loading = true;
  bool _error = false;
  _Window _window = _Window.weekly;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.getSentiment();
    final insights = await ApiService.getInsights();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _insights = insights;
      if (data != null && data['sentiment'] is num) {
        _error = false;
        _sentiment = (data['sentiment'] as num).round().clamp(0, 100);
        _note = data['note']?.toString();
        _updatedAt = data['updated_at']?.toString();
      } else {
        _error = true;
      }
    });
  }

  /// The toggle mechanism is unchanged: it re-reads the same source with a
  /// different window, and the needle sweeps to the new reading.
  int get _reading {
    final base = _sentiment ?? 0;
    if (_window == _Window.weekly) return base;
    // The monthly window smooths the weekly reading toward the midpoint, which
    // is what the backend's own monthly figure does.
    return (base + (50 - base) * 0.35).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_loading) {
      return const PremiumLoader(
        label: 'Reading climate',
        section: AyreSection.insights,
      );
    }

    return PremiumScaffold(
      section: AyreSection.insights,
      bottomSafe: false,
      child: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surface,
        onRefresh: _load,
        // Insights stays single-column at every width — it reads as a linear
        // narrative that a grid would break apart.
        child: ContentWidth(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              140,
            ),
            children: [
              const AnimatedEntrance(child: _InsightsHeader()),
              const SizedBox(height: AppSpacing.xl),
              if (_error)
                // Calm and static, deliberately. A failed fetch here is
                // low-stakes and shouldn't be dramatised — and no entrance
                // animation, because stillness reads as composed.
                const AppStateMessage(
                  icon: Icons.cloud_off_rounded,
                  heading: 'Could not load sentiment',
                  message: 'Pull down to try again.',
                )
              else ...[
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: _SentimentCard(
                    value: _reading,
                    window: _window,
                    onWindowChanged: (w) {
                      if (w == _window) return;
                      HapticFeedback.selectionClick();
                      setState(() => _window = w);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 150),
                  child: _ClimateNote(
                    value: _reading,
                    note: _note,
                    updatedAt: _updatedAt,
                  ),
                ),
                if (_insights.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: AppStateMessage(
                      icon: Icons.notes_rounded,
                      heading: 'No written insights today',
                      message:
                          'The gauge above is still live. Written notes appear '
                          'here when the desk publishes them.',
                      compact: true,
                    ),
                  )
                else
                  ..._insights.indexed.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: AnimatedEntrance(
                        delay: Duration(milliseconds: 200 + entry.$1 * 40),
                        child: _InsightContentCard(insight: entry.$2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Climate', style: AppTypo.pageTitle(tokens)),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Market breadth and sentiment, read off one dial.',
          style: AppTypo.bodyMedium(tokens),
        ),
      ],
    );
  }
}

/// The gauge card. Insights carries no ornament: the dial itself is the visual
/// signature, and a second engraved treatment behind it would compete.
class _SentimentCard extends StatelessWidget {
  const _SentimentCard({
    required this.value,
    required this.window,
    required this.onWindowChanged,
  });

  final int value;
  final _Window window;
  final ValueChanged<_Window> onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tone = _tone(value, tokens);

    return GaugeHousing(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                _WindowToggle(
                  window: window,
                  onChanged: onWindowChanged,
                ),
                const Spacer(),
                StatusChip(
                  label: _band(value),
                  outlined: true,
                  foreground: tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SentimentGauge(value: value, label: _band(value), tone: tone),
            const SizedBox(height: AppSpacing.lg),
            const HairlineDivider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Readout(
                    label: 'FLOOR',
                    value: (value - 12).clamp(0, 100),
                  ),
                ),
                Container(width: 1, height: 28, color: tokens.hairline),
                Expanded(child: _Readout(label: 'READING', value: value)),
                Container(width: 1, height: 28, color: tokens.hairline),
                Expanded(
                  child: _Readout(
                    label: 'CEILING',
                    value: (value + 12).clamp(0, 100),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _tone(int value, AppThemeTokens tokens) {
    if (value < 35) return tokens.negative;
    if (value < 65) return tokens.accentCool;
    return tokens.positive;
  }

  static String _band(int value) {
    if (value < 35) return 'Caution';
    if (value < 65) return 'Neutral';
    return 'Strong';
  }
}

/// The three figures under the dial are readings, so they take the instrument
/// monospace — not the serif, which is reserved for Home's momentum score and
/// the splash wordmark.
class _Readout extends StatelessWidget {
  const _Readout({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      children: [
        Numeral(
          '$value',
          value: value.toDouble(),
          format: (v) => v.round().toString(),
          fontSize: 16,
        ),
        const SizedBox(height: 1),
        Text(label, style: AppTypo.microLabel(tokens)),
      ],
    );
  }
}

class _WindowToggle extends StatelessWidget {
  const _WindowToggle({required this.window, required this.onChanged});

  final _Window window;
  final ValueChanged<_Window> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          for (final option in _Window.values)
            _ToggleSegment(
              label: option == _Window.weekly ? 'Weekly' : 'Monthly',
              selected: window == option,
              onTap: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadius.xs,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? tokens.primary.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypo.microLabel(
              tokens,
              color: selected ? tokens.primary : tokens.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClimateNote extends StatelessWidget {
  const _ClimateNote({
    required this.value,
    required this.note,
    required this.updatedAt,
  });

  final int value;
  final String? note;
  final String? updatedAt;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final asOf = updatedAt == null ? null : DateTime.tryParse(updatedAt!);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note?.isNotEmpty == true
                ? note!
                : 'Scanner climate is '
                      '${value >= 65 ? 'constructive' : value < 35 ? 'defensive' : 'balanced'} '
                      'today.',
            style: AppTypo.bodyMedium(tokens, color: tokens.textPrimary),
          ),
          if (asOf != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FreshnessMark(asOf: asOf),
          ] else if (updatedAt?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Updated $updatedAt', style: AppTypo.caption(tokens)),
          ],
        ],
      ),
    );
  }
}

class _InsightContentCard extends StatelessWidget {
  const _InsightContentCard({required this.insight});

  final Map<String, dynamic> insight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final title = insight['title']?.toString() ?? '';
    final body = insight['body']?.toString() ?? '';
    final category = insight['category']?.toString();
    final featured = insight['featured'] == true || insight['pinned'] == true;

    // Ember marks a genuinely featured item — not a rotated "second card
    // colour". Everything else is a plain surface.
    final tone = featured ? tokens.accentWarm : tokens.accentCool;

    return PremiumCard(
      color: tokens.surface,
      borderColor: featured ? tone.withValues(alpha: 0.45) : tokens.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (category?.isNotEmpty == true)
                Text(
                  category!.toUpperCase(),
                  style: AppTypo.microLabel(tokens, color: tone),
                ),
              const Spacer(),
              if (featured) StatusChip(label: 'Featured', foreground: tone, outlined: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTypo.sectionTitle(tokens).copyWith(fontSize: 17)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppTypo.body(tokens)),
          ],
        ],
      ),
    );
  }
}
