import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

/// A pushed route, not a tab. The bottom nav is hidden for its duration: a
/// plain top app bar with Cancel on the left and Save on the right, disabled
/// until a field actually changes.
///
/// Only the display name is editable, because that is all the backend supports
/// — it exposes session identity but no profile-update endpoint, so the name is
/// stored on the device and the username is shown read-only rather than as a
/// field that would silently fail to save.
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
    final tokens = context.tokens;
    final canSave = _dirty && _valid && !_saving;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTypo.bodyMedium(tokens, color: tokens.textSecondary),
          ),
        ),
        leadingWidth: 84,
        title: const Text('Edit profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: canSave
                  ? () {
                      HapticFeedback.mediumImpact();
                      _save();
                    }
                  : null,
              child: Text(
                'Save',
                style: AppTypo.bodyMedium(
                  tokens,
                  color: canSave ? tokens.primary : tokens.textDisabled,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Text('DISPLAY NAME', style: AppTypo.microLabel(tokens)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: AppTypo.bodyMedium(tokens, color: tokens.textPrimary),
              decoration: InputDecoration(
                hintText: 'How the app should address you',
                hintStyle: AppTypo.body(tokens, color: tokens.textTertiary),
                errorText: _dirty && !_valid ? 'Enter a name' : null,
              ),
              onSubmitted: canSave ? (_) => _save() : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (widget.handle != null && widget.handle!.isNotEmpty) ...[
              Text('SIGN-IN USERNAME', style: AppTypo.microLabel(tokens)),
              const SizedBox(height: AppSpacing.sm),
              PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                color: tokens.surfaceAlt,
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: tokens.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.handle!,
                        style: AppTypo.bodyMedium(
                          tokens,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your username identifies the account and cannot be changed '
                'here.',
                style: AppTypo.caption(tokens),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
