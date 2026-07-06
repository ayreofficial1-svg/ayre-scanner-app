import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeShell(),
          transitionDuration: AppMotion.slow,
          reverseTransitionDuration: AppMotion.medium,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.ease,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
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
      body: PremiumScaffold(
        section: AyreSection.home,
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  AnimatedEntrance(child: _LoginHero(tokens: tokens)),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 100),
                    child: PremiumCard(
                      radius: AppRadius.xl,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      gradient: AppGradients.surfaceGlass(tokens),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome back',
                            style: AppTypo.pageTitle(tokens),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Sign in to continue to your workspace.',
                            style: AppTypo.body(tokens),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          _LoginTextField(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.person_rounded,
                            submitted: _submitted,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _LoginTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            obscure: true,
                            submitted: _submitted,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _LoginError(message: _error!),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
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

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AppRadius.xl,
      padding: EdgeInsets.zero,
      gradient: AppGradients.heroCard(AyreSection.home, tokens),
      shadowColor: tokens.primary.withValues(alpha: 0.3),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: tokens.neutralBlock,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.shadow.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'AYRE SCANNER',
                  style: AppTypo.eyebrow(tokens, color: tokens.onNeutralBlock),
                ),
              ),
            ),
            Positioned(
              right: 28,
              top: 72,
              child: FloatingOrb(
                child: Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 140,
              bottom: 24,
              child: Text(
                'Market intelligence with calm execution.',
                style: AppTypo.pageTitle(tokens, color: tokens.onPrimary),
              ),
            ),
          ],
        ),
      ),
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
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool submitted;
  final bool obscure;

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
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.ease,
      decoration: BoxDecoration(
        color: tokens.surfaceAlt, // Solid subtle background instead of transparent
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: invalid
              ? tokens.negative
              : _focused
              ? tokens.primary
              : tokens.borderSubtle,
          width: _focused || invalid ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (_focused)
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.obscure,
        style: AppTypo.bodyMedium(tokens, color: tokens.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon,
            color: invalid ? tokens.negative : (_focused ? tokens.primary : tokens.textSecondary),
          ),
          suffixIcon: invalid
              ? Icon(Icons.error_rounded, color: tokens.negative)
              : null,
          labelText: widget.label,
          labelStyle: AppTypo.body(tokens, color: tokens.textSecondary),
          floatingLabelStyle: AppTypo.bodyMedium(tokens, color: invalid ? tokens.negative : tokens.primary),
          filled: true,
          fillColor: AppTheme.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.negative.withValues(alpha: 0.1),
        border: Border.all(color: tokens.negative.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tokens.negative, size: 20),
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
      child: AnimatedContainer(
        duration: AppMotion.medium,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryShifted(tokens),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Sign In',
                  style: AppTypo.cardTitle(tokens, color: tokens.onPrimary),
                ),
        ),
      ),
    );
  }
}
