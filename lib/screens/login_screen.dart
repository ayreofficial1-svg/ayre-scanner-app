import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
  String? _error;
  bool _submitted = false;

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
      _error = null;
      _submitted = true;
    });

    final success = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, secAnim) => const HomeShell(),
          transitionsBuilder: (ctx, anim, secAnim, child) {
            final slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: AppMotion.ease));
            return SlideTransition(position: slide, child: child);
          },
          transitionDuration: AppMotion.medium,
        ),
      );
    } else {
      setState(() => _error = 'Invalid username or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tokens.background, tokens.backgroundTint],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),
                    _LoginLogo(tokens: tokens),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to access market intelligence.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 40),
                    _LoginTextField(
                      controller: _usernameController,
                      label: 'Username',
                      submitted: _submitted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _LoginTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscure: true,
                      submitted: _submitted,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _LoginError(message: _error!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _LoginButton(loading: _loading, onPressed: _handleLogin),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo({required this.tokens});
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.primaryShifted(tokens),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.4),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(Icons.radar_rounded, color: tokens.onPrimary, size: 42),
      ),
    );
  }
}

class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    this.obscure = false,
    required this.submitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool submitted;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  bool _focused = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasValue = widget.controller.text.isNotEmpty;
    final error = widget.submitted && !hasValue;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: error
              ? tokens.negative
              : _focused
                  ? tokens.primary
                  : tokens.border,
          width: error ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: _focused ? 0.4 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.obscure,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
          floatingLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w800,
              ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          filled: true,
          fillColor: AppTheme.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          suffixIcon: error
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: Icon(Icons.error_outline_rounded,
                      color: tokens.negative, size: 20),
                )
              : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.negative.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tokens.negative, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.negative,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryShifted(tokens),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Log In',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                ),
        ),
      ),
    );
  }
}