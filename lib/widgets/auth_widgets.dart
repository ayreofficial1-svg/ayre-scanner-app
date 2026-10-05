import 'package:flutter/material.dart';

import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import 'ayre_components.dart';
import 'ayre_icons.dart';

/// A labelled text field for the sign-in flow. Password fields are obscured by
/// default with a show/hide toggle, and never autocorrect.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.password = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label: widget.label),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.password && _hidden,
          enableSuggestions: !widget.password,
          autocorrect: false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          style: AppTypo.bodyStrong(t),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            suffixIcon: widget.password
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: t.foregroundMuted,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// A calm message block (ink-toned, never red — an auth failure is the app
/// declining a credential, not a market move).
class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, required this.message, this.glyph});

  final String message;
  final AyreGlyph? glyph;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        border: Border.all(color: t.hairline),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          AyreIcon(
            glyph ?? AyreGlyph.disconnected,
            size: 15,
            color: t.foregroundMuted,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypo.bodyStrong(t, color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live password checklist with ticks.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.check});

  final PasswordCheck check;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(
          ok: check.length,
          text: '${PasswordCheck.minLength}–${PasswordCheck.maxLength} characters',
        ),
        _Row(ok: check.upper, text: 'One uppercase letter'),
        _Row(ok: check.lower, text: 'One lowercase letter'),
        _Row(ok: check.number, text: 'One number'),
        _Row(ok: check.notEmail, text: 'Different from your email'),
        _Row(ok: check.special, text: 'A special character (recommended)'),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xxs),
      child: Semantics(
        label: '$text, ${ok ? 'met' : 'not met'}',
        excludeSemantics: true,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: ok
                  ? AyreIcon(AyreGlyph.check, size: 14, color: t.accentInk)
                  : Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.foregroundSubtle,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                text,
                style: AppTypo.caption(
                  t,
                  color: ok ? t.textPrimary : t.foregroundMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared page frame for the sign-in screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children, this.showBack = false});

  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      appBar: showBack
          ? AppBar(
              leading: IconButton(
                icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
