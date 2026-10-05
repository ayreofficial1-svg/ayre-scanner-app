import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ayre_components.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

/// Creates the account. Success needs no navigation: the startup gate listens
/// to the auth state, closes this page and opens the app.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;
  bool _loading = false;
  bool _submitted = false;
  bool _confirmTouched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => Navigator.of(
        context,
      ).push(terminalRoute(builder: (_) => const TermsScreen()));
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => Navigator.of(
        context,
      ).push(terminalRoute(builder: (_) => const PrivacyPolicyScreen()));
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  PasswordCheck get _check => PasswordCheck(_password.text, _email.text);

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    final ok =
        AuthValidators.name(_name.text) == null &&
        AuthValidators.email(_email.text) == null &&
        _check.valid &&
        AuthValidators.confirm(_password.text, _confirm.text) == null;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      TextInput.finishAutofillContext();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
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
    final matches =
        _confirm.text.isNotEmpty && _confirm.text == _password.text;

    return AuthScaffold(
      showBack: true,
      children: [
        Text('Create account', style: AppTypo.pageTitle(t)),
        const SizedBox(height: AppSpace.xxs),
        Text('Set up your Ayre Scanner account.', style: AppTypo.body(t)),
        const SizedBox(height: AppSpace.xl),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Name',
                controller: _name,
                hint: 'Your name',
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                errorText: _submitted ? AuthValidators.name(_name.text) : null,
                enabled: !_loading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.lg),
              AuthField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                errorText: _submitted
                    ? AuthValidators.email(_email.text)
                    : null,
                enabled: !_loading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.lg),
              AuthField(
                label: 'Password',
                controller: _password,
                hint: 'Create a password',
                password: true,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_loading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.sm),
              PasswordChecklist(check: _check),
              const SizedBox(height: AppSpace.lg),
              AuthField(
                label: 'Confirm password',
                controller: _confirm,
                hint: 'Re-enter your password',
                password: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                errorText: confirmError,
                enabled: !_loading,
                onChanged: (_) => setState(() => _confirmTouched = true),
                onSubmitted: (_) => _submit(),
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
            message: 'Your password does not meet the requirements above.',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.md),
          AuthMessage(message: _error!),
        ],
        const SizedBox(height: AppSpace.xl),
        AyreButton(
          label: 'Create account',
          busy: _loading,
          onPressed: _loading ? null : _submit,
        ),
        const SizedBox(height: AppSpace.md),
        Text.rich(
          TextSpan(
            style: AppTypo.caption(t),
            children: [
              const TextSpan(text: 'By creating an account you agree to the '),
              TextSpan(
                text: 'Terms',
                recognizer: _termsTap,
                style: AppTypo.caption(
                  t,
                  color: t.accentInk,
                ).copyWith(decoration: TextDecoration.underline),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                recognizer: _privacyTap,
                style: AppTypo.caption(
                  t,
                  color: t.accentInk,
                ).copyWith(decoration: TextDecoration.underline),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
