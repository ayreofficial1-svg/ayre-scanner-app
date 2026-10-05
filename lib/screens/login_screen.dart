import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_logo.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Email + password sign in. Success needs no navigation: the startup gate
/// listens to the auth state and swaps to the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    AuthService.instance.clearNotice();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (AuthValidators.email(_email.text) != null || _password.text.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(
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

  void _open(Widget screen) {
    AuthService.instance.clearNotice();
    Navigator.of(context).push(terminalRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final emailError = _submitted ? AuthValidators.email(_email.text) : null;
    final passError = _submitted && _password.text.isEmpty
        ? 'Enter your password'
        : null;

    return AuthScaffold(
      children: [
        const Center(child: LogoMark(placement: LogoPlacement.auth)),
        const SizedBox(height: AppSpace.md),
        Text('Sign in', style: AppTypo.pageTitle(t)),
        const SizedBox(height: AppSpace.xxs),
        Text('Continue to your market terminal.', style: AppTypo.body(t)),
        const SizedBox(height: AppSpace.xl),
        ValueListenableBuilder<String?>(
          valueListenable: AuthService.instance.notice,
          builder: (context, notice, _) => notice == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  child: AuthMessage(message: notice),
                ),
        ),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                errorText: emailError,
                enabled: !_loading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.lg),
              AuthField(
                label: 'Password',
                controller: _password,
                hint: 'Your password',
                password: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                errorText: passError,
                enabled: !_loading,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _signIn(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading
                ? null
                : () => _open(ForgotPasswordScreen(initialEmail: _email.text)),
            child: const Text('Forgot password?'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.xs),
          AuthMessage(message: _error!),
        ],
        const SizedBox(height: AppSpace.lg),
        AyreButton(
          label: 'Sign in',
          busy: _loading,
          onPressed: _loading ? null : _signIn,
        ),
        const SizedBox(height: AppSpace.md),
        AyreButton(
          label: 'Create account',
          kind: AyreButtonKind.outline,
          onPressed: _loading ? null : () => _open(const RegisterScreen()),
        ),
      ],
    );
  }
}
