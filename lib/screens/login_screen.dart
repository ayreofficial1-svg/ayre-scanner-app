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
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  AnimatedEntrance(child: _LoginHero(tokens: tokens)),
                  const SizedBox(height: 18),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 100),
                    child: PremiumCard(
                      radius: 44,
                      padding: const EdgeInsets.all(22),
                      gradient: AppGradients.surfaceGlass(tokens),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to continue your scanner workspace.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: tokens.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 22),
                          _LoginTextField(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.person_rounded,
                            submitted: _submitted,
                          ),
                          const SizedBox(height: 12),
                          _LoginTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            obscure: true,
                            submitted: _submitted,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            _LoginError(message: _error!),
                          ],
                          const SizedBox(height: 20),
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
      radius: 48,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          tokens.primary,
          Color.lerp(tokens.primary, tokens.accentCool, 0.55)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: tokens.primary.withValues(alpha: 0.28),
      child: SizedBox(
        height: 244,
        child: Stack(
          children: [
            Positioned(
              top: -46,
              right: -26,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 22,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: tokens.neutralBlock,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Ayre Scanner',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tokens.onNeutralBlock,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 28,
              top: 62,
              child: FloatingOrb(
                child: Container(
                  height: 106,
                  width: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 142,
              bottom: 24,
              child: Text(
                'Market intelligence with calm execution.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tokens.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
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
      duration: AppMotion.medium,
      curve: AppMotion.ease,
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: invalid
              ? tokens.negative
              : _focused
              ? tokens.primary
              : Colors.white.withValues(alpha: 0.38),
        ),
        boxShadow: [
          if (_focused)
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.obscure,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon,
            color: invalid ? tokens.negative : tokens.primary,
          ),
          suffixIcon: invalid
              ? Icon(Icons.error_rounded, color: tokens.negative)
              : null,
          labelText: widget.label,
          labelStyle: TextStyle(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w800,
          ),
          floatingLabelStyle: TextStyle(
            color: invalid ? tokens.negative : tokens.primary,
            fontWeight: FontWeight.w900,
          ),
          filled: true,
          fillColor: AppTheme.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
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
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.negative.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tokens.negative, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.negative,
                fontWeight: FontWeight.w900,
              ),
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
      borderRadius: AppRadius.pill,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryShifted(tokens),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.34),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Log In',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}
