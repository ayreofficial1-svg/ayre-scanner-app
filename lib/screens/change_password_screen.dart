import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// Sets a new password for the signed-in account.
///
/// Reached from Settings → Account. The current password is asked for first,
/// and the new one is typed twice; nothing is sent until both new entries
/// match and meet the same policy as Create account. Pops with `true` once the
/// password has changed, so the caller can confirm it.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _submitted = false;
  bool _confirmTouched = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _email => AuthService.instance.currentUser?.email ?? '';

  PasswordCheck get _check => PasswordCheck(_password.text, _email);

  String? get _currentError =>
      _current.text.isEmpty ? 'Enter your current password' : null;

  String? get _newError {
    if (_password.text.isNotEmpty && _password.text == _current.text) {
      return 'Choose a password different from your current one';
    }
    return null;
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    final ok =
        _currentError == null &&
        _check.valid &&
        _newError == null &&
        AuthValidators.confirm(_password.text, _confirm.text) == null;
    if (!ok) return;

    setState(() => _busy = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: _current.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final confirmError = (_submitted || _confirmTouched)
        ? AuthValidators.confirm(_password.text, _confirm.text)
        : null;
    final matches = _confirm.text.isNotEmpty && _confirm.text == _password.text;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('Change password'),
      ),
      body: ContentWidth(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.pageHorizontal,
            AppSpace.sm,
            AppSpace.pageHorizontal,
            AppSpace.xxl,
          ),
          children: [
            Text('Set a new password', style: AppTypo.pageTitle(t)),
            const SizedBox(height: AppSpace.xxs),
            Text(
              'Enter your current password, then your new one twice.',
              style: AppTypo.body(t),
            ),
            const SizedBox(height: AppSpace.xl),
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthField(
                    label: 'Current password',
                    controller: _current,
                    hint: 'Your current password',
                    password: true,
                    autofillHints: const [AutofillHints.password],
                    errorText: _submitted ? _currentError : null,
                    enabled: !_busy,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AuthField(
                    label: 'New password',
                    controller: _password,
                    hint: 'Create a new password',
                    password: true,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: _submitted ? _newError : null,
                    enabled: !_busy,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  PasswordChecklist(check: _check),
                  const SizedBox(height: AppSpace.lg),
                  AuthField(
                    label: 'Confirm new password',
                    controller: _confirm,
                    hint: 'Re-enter your new password',
                    password: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: confirmError,
                    enabled: !_busy,
                    onChanged: (_) => setState(() {
                      _confirmTouched = true;
                      _error = null;
                    }),
                    onSubmitted: (_) => _busy ? null : _submit(),
                  ),
                  if (matches) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Passwords match',
                      style: AppTypo.caption(t, color: t.accentInk),
                    ),
                  ],
                ],
              ),
            ),
            if (_submitted && !_check.valid) ...[
              const SizedBox(height: AppSpace.md),
              const AuthMessage(
                message: 'Your new password does not meet the requirements '
                    'above.',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpace.md),
              AuthMessage(message: _error!),
            ],
            const SizedBox(height: AppSpace.xl),
            AyreButton(
              label: 'Update password',
              busy: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: AppSpace.sm),
            AyreButton(
              label: 'Cancel',
              kind: AyreButtonKind.outline,
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
