import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ayre_avatar.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_page_header.dart';
import 'home_shell.dart' show initialsFor;

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
    if (_saving || !_dirty || !_valid) return;
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
    final verified = AuthService.instance.currentUser?.emailVerified;
    void save() {
      HapticFeedback.mediumImpact();
      _save();
    }

    return AyrePageScaffold(
      title: 'Edit profile',
      backEnabled: !_saving,
      children: [
        Row(
          children: [
            AyreAvatar(
              initials: initialsFor(_initial),
              size: 55,
              fontSize: 17,
              square: true,
            ),
            const SizedBox(width: AppSpace.s13),
            Expanded(child: Text(_initial, style: AppTypo.sectionTitle(t))),
          ],
        ),
        const SizedBox(height: AppSpace.s21),
        AyreCard(
          child: AuthField(
            label: 'Display name',
            controller: _name,
            hint: 'How the app should address you',
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            errorText: _dirty && !_valid ? _problem : _saveError,
            onSubmitted: canSave ? (_) => save() : null,
          ),
        ),
        if (widget.handle case final email? when email.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s21),
          RowGroup(
            children: [
              SettingRow(
                glyph: AyreGlyph.lock,
                title: 'Sign-in email',
                subtitle: email,
                trailing: verified == null
                    ? null
                    : AyreChip(
                        label: verified ? 'Verified' : 'Unverified',
                        tone: verified ? ChipTone.success : ChipTone.attention,
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            'Your email identifies the account and cannot be changed here.',
            style: AppTypo.caption(t),
          ),
        ],
        const SizedBox(height: AppSpace.s21),
        AyreButton(
          label: 'Save',
          busy: _saving,
          onPressed: canSave ? save : null,
        ),
        const SizedBox(height: AppSpace.s13),
        AyreButton(
          label: 'Cancel',
          kind: AyreButtonKind.outline,
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
