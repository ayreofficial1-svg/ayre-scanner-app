import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// A pushed route, not a tab. Cancel on the left, Save on the right, disabled
/// until a field actually changes.
///
/// Only the display name is editable: the backend exposes session identity but no
/// profile-update endpoint, so the name is stored on the device and the username
/// is read-only rather than a field that would silently fail to save.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.displayName,
    required this.handle,
  });

  final String displayName;
  final String? handle;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final String _initial;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initial = widget.displayName;
    _name = TextEditingController(text: _initial)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _dirty => _name.text.trim() != _initial.trim();
  bool get _valid => _name.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    await SettingsStore.instance.setDisplayName(_name.text);
    if (!mounted) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final canSave = _dirty && _valid && !_saving;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.close, size: 19, color: t.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Cancel',
        ),
        title: const Text('Edit profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: canSave
                  ? () {
                      HapticFeedback.mediumImpact();
                      _save();
                    }
                  : null,
              child: Text(
                'Save',
                style: AppTypo.button(
                  t,
                  color: canSave ? t.citrineInk : t.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          children: [
            const SectionLabel(label: 'Display name'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: AppTypo.bodyStrong(t),
              decoration: InputDecoration(
                hintText: 'How the app should address you',
                errorText: _dirty && !_valid ? 'Enter a name' : null,
              ),
              onSubmitted: canSave ? (_) => _save() : null,
            ),
            if (widget.handle != null && widget.handle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const SectionLabel(label: 'Sign-in username'),
              AyreCard(
                color: t.surfaceAlt,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    AyreIcon(AyreGlyph.lock, size: 16, color: t.textTertiary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.handle!,
                        style: AppTypo.bodyStrong(t, color: t.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your username identifies the account and cannot be changed here.',
                style: AppTypo.caption(t),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
