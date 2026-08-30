import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/instrument_marks.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pressable_scale.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      setState(() => _error = 'Invalid username or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      body: PremiumScaffold(
        section: AyreSection.home,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            // The constrained max-width column this screen already got right,
            // now the model for every scrollable surface in the app.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  const AnimatedEntrance(child: _LoginMark()),
                  const SizedBox(height: AppSpacing.xxl),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 100),
                    child: PremiumCard(
                      radius: AppRadius.heroCard,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Welcome back', style: AppTypo.pageTitle(tokens)),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Sign in to continue to your workspace.',
                            style: AppTypo.body(tokens),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _LoginTextField(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.person_outline_rounded,
                            submitted: _submitted,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _LoginTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            submitted: _submitted,
                            onSubmit: _handleLogin,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _LoginError(message: _error!),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          _LoginButton(
                            loading: _loading,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
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

/// Login and Splash share the bearing mark — both are one-time, sequential
/// screens, so they carry the same brand motif. Static here: nothing on this
/// screen is loading, so nothing should be moving.
class _LoginMark extends StatelessWidget {
  const _LoginMark();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      children: [
        BearingMark(
          color: tokens.engraved,
          size: 108,
          needleColor: tokens.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ayre Scanner',
          style: AppTypo.serif(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('MARKET INTELLIGENCE', style: AppTypo.microLabel(tokens)),
      ],
    );
  }
}

class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.submitted,
    this.obscure = false,
    this.onSubmit,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool submitted;
  final bool obscure;
  final VoidCallback? onSubmit;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _focused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final invalid = widget.submitted && widget.controller.text.isEmpty;

    // Focus and blur stay instantaneous — a text field taking on a border is
    // not an animation the user asked for.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: invalid
              ? tokens.negative
              : _focused
              ? tokens.primary
              : tokens.border,
          width: _focused || invalid ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.obscure,
        textInputAction: widget.obscure
            ? TextInputAction.done
            : TextInputAction.next,
        onSubmitted: widget.onSubmit == null ? null : (_) => widget.onSubmit!(),
        style: AppTypo.bodyMedium(tokens, color: tokens.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon,
            size: 18,
            color: invalid
                ? tokens.negative
                : (_focused ? tokens.primary : tokens.textSecondary),
          ),
          suffixIcon: invalid
              ? Icon(Icons.error_outline_rounded, size: 18, color: tokens.negative)
              : null,
          labelText: widget.label,
          labelStyle: AppTypo.body(tokens),
          floatingLabelStyle: AppTypo.bodyMedium(
            tokens,
            color: invalid ? tokens.negative : tokens.primary,
          ),
          filled: true,
          fillColor: AppTheme.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
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
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tokens.negativeBg,
        border: Border.all(color: tokens.negative.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tokens.negative, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypo.caption(tokens, color: tokens.negative),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PressableScale(
      onTap: loading ? null : onPressed,
      borderRadius: AppRadius.md,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: loading ? tokens.primaryMuted : tokens.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: tokens.onPrimary,
                  ),
                )
              : Text(
                  'Sign in',
                  style: AppTypo.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.onPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
