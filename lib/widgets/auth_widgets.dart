import 'package:flutter/material.dart';

import '../services/auth_validators.dart';
import '../theme/app_theme.dart';
import 'ayre_icons.dart';
import 'ayre_logo.dart';
import 'ayre_masthead.dart';
import 'finance_icons.dart';

/// A labelled text field for the sign-in flow: 12/700 label, a 6 gap, then a
/// card-filled 55-high field with a 1px line, radius 13, a 20 leading glyph and
/// 15/600 content. Password fields are obscured by default with a show/hide
/// toggle and never autocorrect. Focus is a 2px brand outline; an error is a
/// negative outline with plain-language text below.
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
    this.icon,
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

  /// Leading glyph. Defaults to lock (password), mail (email keyboard) or
  /// profile.
  final FinanceGlyph? icon;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _hidden = true;

  FinanceGlyph get _glyph =>
      widget.icon ??
      (widget.password
          ? FinanceGlyph.lock
          : widget.keyboardType == TextInputType.emailAddress
          ? FinanceGlyph.mail
          : FinanceGlyph.profile);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasError = widget.errorText != null;
    final iconColor = hasError ? t.negativeText : t.foregroundMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(widget.label, style: AppTypo.fieldLabel(t)),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: widget.label,
          textField: true,
          child: TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            obscureText: widget.password && _hidden,
            enableSuggestions: !widget.password,
            autocorrect: false,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            style: AppTypo.fieldValue(t),
            cursorColor: t.accentInk,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypo.fieldValue(t, color: t.foregroundMuted),
              errorText: widget.errorText,
              errorMaxLines: 8,
              filled: true,
              fillColor: t.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.md,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpace.md,
                  end: 10,
                ),
                child: FinanceIcon(_glyph, size: 20, color: iconColor),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 46,
                minHeight: 20,
              ),
              suffixIcon: widget.password
                  ? IconButton(
                      tooltip: _hidden ? 'Show password' : 'Hide password',
                      icon: FinanceIcon(
                        _hidden ? FinanceGlyph.eye : FinanceGlyph.eyeOff,
                        size: 20,
                        color: t.foregroundMuted,
                      ),
                      onPressed: widget.enabled
                          ? () => setState(() => _hidden = !_hidden)
                          : null,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// A calm message block: a soft neutral panel with an info glyph — never red.
/// An auth failure is the app declining a credential, not a market move.
class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, required this.message, this.glyph});

  final String message;

  /// Overrides the default info glyph (for a success tick, say).
  final AyreGlyph? glyph;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          border: Border.all(color: t.hairline),
          borderRadius: AppShape.field,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: glyph == null
                  ? FinanceIcon(
                      FinanceGlyph.info,
                      size: 18,
                      color: t.foregroundMuted,
                    )
                  : AyreIcon(glyph!, size: 16, color: t.positiveText),
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
          text:
              '${PasswordCheck.minLength}–${PasswordCheck.maxLength} characters',
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
      padding: const EdgeInsets.only(top: AppSpace.xxs + 1),
      child: Semantics(
        label: '$text, ${ok ? 'met' : 'not met'}',
        excludeSemantics: true,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: ok
                  ? FinanceIcon(
                      FinanceGlyph.check,
                      size: 14,
                      color: t.positiveText,
                      strokeWidth: 2,
                    )
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

/// A plain text action (13/800 positive) with a ≥48 hit area, for the
/// "Forgot password?" and "Sign in" links.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShape.field,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpace.minTarget,
            minWidth: AppSpace.minTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              child: Text(
                label,
                style: AppTypo.ui(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: onTap == null ? t.textDisabled : t.positiveText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared page frame for the sign-in screens: a full-bleed mast carrying the
/// brand, back control, title and subtitle, over a scrollable form body.
///
/// The body keeps a centred maximum width on wide windows, dismisses the
/// keyboard on drag and never locks the form to a fixed canvas — everything
/// scrolls. While the keyboard is up the mast drops to its compact height.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.tone = AyreMastTone.standard,
    this.mastHeight = AppShape.mastRegister,
    this.largeTitle = false,
    this.titleGap = AppSpace.s55,
    this.bodyTop = AppSpace.s8,
  });

  final List<Widget> children;
  final String title;
  final String? subtitle;
  final bool showBack;
  final AyreMastTone tone;

  /// Reference mast height at 390 (322 sign in, 233 register / reset).
  final double mastHeight;

  /// 44/800 sign-in title instead of the 34/800 page title.
  final bool largeTitle;

  /// Gap between the brand row and the title (89 sign in, 55 elsewhere).
  final double titleGap;

  /// Space between the mast and the first field (21 sign in, 8 elsewhere).
  final double bodyTop;

  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final p = tone.paletteOf(t);
    final gutter = AppSpace.gutterOf(context);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom > 0;
    final compactMast = keyboard || media.size.height < 600;
    final height = compactMast ? AppShape.mastRegister : mastHeight;
    final gap = compactMast ? AppSpace.s21 : titleGap;
    final titleStyle = largeTitle
        ? AppTypo.signInTitle(t, color: p.ink)
        : AppTypo.pageTitle(t, color: p.ink);

    final mastChild = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth - 42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (showBack) ...[
                  MastIconButton(
                    palette: p,
                    semanticLabel: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                    child: AyreIcon(AyreGlyph.back, size: 20, color: p.ink),
                  ),
                  const SizedBox(width: AppSpace.xs),
                ],
                LogoMark(placement: LogoPlacement.auth, color: p.ink),
              ],
            ),
            SizedBox(height: gap),
            Semantics(header: true, child: Text(title, style: titleStyle)),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(subtitle!, style: AppTypo.subtitle(t, color: p.muted)),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: t.background,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AyreMasthead(
              palette: p,
              height: height,
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                (55 - media.padding.top) < AppSpace.s13
                    ? AppSpace.s13
                    : 55 - media.padding.top,
                gutter,
                0,
              ),
              child: mastChild,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    bodyTop,
                    gutter,
                    AppSpace.s34 + media.padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
