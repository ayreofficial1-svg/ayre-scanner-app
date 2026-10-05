import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// Sends a password-reset email. The confirmation is the same whether or not
/// an account exists for the address.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _cooldownSeconds = 60;

  late final TextEditingController _email;
  Timer? _timer;
  bool _loading = false;
  bool _submitted = false;
  bool _sent = false;
  int _cooldown = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (AuthValidators.email(_email.text) != null) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
      _startCooldown();
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
    final emailError = _submitted ? AuthValidators.email(_email.text) : null;
    final canSend = !_loading && _cooldown <= 0;

    return AuthScaffold(
      showBack: true,
      children: [
        Text('Reset password', style: AppTypo.pageTitle(t)),
        const SizedBox(height: AppSpace.xxs),
        Text(
          "Enter your email and we'll send you a link to set a new password.",
          style: AppTypo.body(t),
        ),
        const SizedBox(height: AppSpace.xl),
        AuthField(
          label: 'Email',
          controller: _email,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          errorText: emailError,
          enabled: !_loading,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => canSend ? _send() : null,
        ),
        if (_sent) ...[
          const SizedBox(height: AppSpace.lg),
          const AuthMessage(
            glyph: AyreGlyph.check,
            message:
                "If an account exists for this email, we've sent a reset link. "
                'Check your inbox and spam folder.',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.lg),
          AuthMessage(message: _error!),
        ],
        const SizedBox(height: AppSpace.xl),
        AyreButton(
          label: _cooldown > 0
              ? 'Resend in ${_cooldown}s'
              : (_sent ? 'Resend link' : 'Send reset link'),
          busy: _loading,
          onPressed: canSend ? _send : null,
        ),
        const SizedBox(height: AppSpace.md),
        AyreButton(
          label: 'Back to sign in',
          kind: AyreButtonKind.outline,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
