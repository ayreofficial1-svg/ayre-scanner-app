import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';
import '../widgets/ayre_logo.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _submitted = true;
      _error = null;
    });

    final success = await ApiService.login(
      _username.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      await Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => HomeShell()));
    } else {
      setState(() => _error = 'Invalid username or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final missingUser = _submitted && _username.text.trim().isEmpty;
    final missingPass = _submitted && _password.text.isEmpty;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A secondary placement: the mark heads the form once, and is
                  // not repeated anywhere else in the flow.
                  const Center(child: LogoMark(placement: LogoPlacement.auth)),
                  const SizedBox(height: AppSpace.md),
                  Text('Sign in', style: AppTypo.pageTitle(t)),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    'Continue to your market terminal.',
                    style: AppTypo.body(t),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  const SectionLabel(label: 'Username'),
                  TextField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    style: AppTypo.bodyStrong(t),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Your username',
                      errorText: missingUser ? 'Enter your username' : null,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const SectionLabel(label: 'Password'),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    style: AppTypo.bodyStrong(t),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: 'Your password',
                      errorText: missingPass ? 'Enter your password' : null,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpace.lg),
                    _LoginError(message: _error!),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  AyreButton(
                    label: 'Sign in',
                    busy: _loading,
                    onPressed: _loading ? null : _handleLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: t.lossSoft,
        border: Border.all(color: t.loss.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          AyreIcon(AyreGlyph.disconnected, size: 15, color: t.loss),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(message, style: AppTypo.bodyStrong(t, color: t.loss)),
          ),
        ],
      ),
    );
  }
}
