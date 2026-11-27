import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_masthead.dart';
import '../widgets/finance_icons.dart';
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
      title: 'Create account',
      subtitle: 'Set up your Investee account.',
      tone: AyreMastTone.champagne,
      mastHeight: AppShape.mastRegister,
      bodyTop: AppSpace.s8,
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Full name',
                controller: _name,
                hint: 'Your name',
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                errorText: _submitted ? AuthValidators.name(_name.text) : null,
                enabled: !_loading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.s13),
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
              const SizedBox(height: AppSpace.s13),
              AuthField(
                label: 'Password',
                controller: _password,
                hint: 'Create a password',
                password: true,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_loading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.s8),
              PasswordChecklist(check: _check),
              const SizedBox(height: AppSpace.s13),
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
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      FinanceIcon(
                        FinanceGlyph.check,
                        size: 14,
                        color: t.positiveText,
                        strokeWidth: 2,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Flexible(
                        child: Text(
                          'Passwords match',
                          style: AppTypo.caption(t, color: t.positiveText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_submitted && !_check.valid) ...[
          const SizedBox(height: AppSpace.s13),
          const AuthMessage(
            message: 'Your password does not meet the requirements above.',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.s13),
          AuthMessage(message: _error!),
        ],
        const SizedBox(height: AppSpace.s21),
        Text.rich(
          TextSpan(
            style: AppTypo.meta(t),
            children: [
              const TextSpan(text: 'By creating an account you agree to the '),
              TextSpan(
                text: 'Terms',
                recognizer: _termsTap,
                style: AppTypo.meta(
                  t,
                  color: t.positiveText,
                ).copyWith(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                recognizer: _privacyTap,
                style: AppTypo.meta(
                  t,
                  color: t.positiveText,
                ).copyWith(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s13),
        AyreButton(
          label: 'Create account',
          busy: _loading,
          onPressed: _loading ? null : _submit,
        ),
        const SizedBox(height: AppSpace.s13),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account?', style: AppTypo.meta(t)),
              AuthTextLink(
                label: 'Sign in',
                onTap: _loading ? null : () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
