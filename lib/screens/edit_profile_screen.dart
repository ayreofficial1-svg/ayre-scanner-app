import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// A pushed route, not a tab. Cancel on the left, Save on the right, disabled
/// until a field actually changes.
///
/// Only the display name is editable. It is saved on the account itself, so it
/// follows the person to a new phone or a reinstall. The email is read-only.
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
  String? _saveError;

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
  String? get _problem => AuthValidators.name(_name.text);
  bool get _valid => _problem == null;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await AuthService.instance.updateDisplayName(_name.text);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = e.message;
      });
      return;
    }
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
            padding: const EdgeInsets.only(right: AppSpace.md),
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
                  color: canSave ? t.accentInk : t.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.xxl,
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
                errorText: _dirty && !_valid ? _problem : _saveError,
              ),
              onSubmitted: canSave ? (_) => _save() : null,
            ),
            if (widget.handle != null && widget.handle!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              const SectionLabel(label: 'Sign-in email'),
              AyreCard(
                // Sunken, not raised: this reads as a locked, inactive
                // field, so it takes the same tonal fill a disabled text
                // field would (InputDecorationTheme.fillColor) rather than
                // a lifted tile.
                color: t.surfaceSunken,
                padding: const EdgeInsets.all(AppSpace.md),
                child: Row(
                  children: [
                    AyreIcon(
                      AyreGlyph.lock,
                      size: 16,
                      color: t.foregroundSubtle,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        widget.handle!,
                        style: AppTypo.bodyStrong(t, color: t.foregroundMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Your email identifies the account and cannot be changed here.',
                style: AppTypo.caption(t),
              ),
            ],
          ],
        ),
      ),
    );
  }
}