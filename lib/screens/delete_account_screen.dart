import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/account_session.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/ayre_components.dart';
import '../widgets/ayre_icons.dart';

/// Permanently deletes the signed-in account.
///
/// Reached from Settings → Account. The password is asked for again so a
/// borrowed, unlocked phone can't remove an account with one stray tap. When
/// deletion succeeds the account signs out by itself, the startup gate returns
/// to Sign in and clears the navigation stack, so there is nothing to pop here.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _canDelete => _password.text.isNotEmpty && !_busy;

  Future<void> _delete() async {
    if (!_canDelete) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.heavyImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountSession.deleteAccount(password: _password.text);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      return;
    }
    if (!mounted) return;
    // Normally the gate has already replaced this screen. If the sign-out
    // event is slow, don't leave a spinner running.
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final email = AuthService.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AyreIcon(AyreGlyph.back, size: 20, color: t.textPrimary),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('Delete account'),
      ),
      body: ContentWidth(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.pageHorizontal,
            AppSpace.sm,
            AppSpace.pageHorizontal,
            AppSpace.xxl,
          ),
          children: [
            Text('Delete your account?', style: AppTypo.pageTitle(t)),
            const SizedBox(height: AppSpace.sm),
            Text(
              email.isEmpty
                  ? 'This permanently deletes your Ayre account.'
                  : 'This permanently deletes the account for $email.',
              style: AppTypo.body(t),
            ),
            const SizedBox(height: AppSpace.lg),
            RowGroup(
              children: const [
                _Consequence(
                  glyph: AyreGlyph.account,
                  title: 'Your sign-in is removed',
                  subtitle: 'Your name, email and password are deleted.',
                ),
                _Consequence(
                  glyph: AyreGlyph.bell,
                  title: 'Alerts stop on this device',
                  subtitle: 'Saved alerts are cleared from this phone.',
                ),
                _Consequence(
                  glyph: AyreGlyph.close,
                  title: 'This can’t be undone',
                  subtitle: 'To use Ayre again you will need to create a new '
                      'account.',
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            AuthField(
              label: 'Confirm your password',
              controller: _password,
              password: true,
              enabled: !_busy,
              hint: 'Your current password',
              errorText: _error,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _delete(),
            ),
            const SizedBox(height: AppSpace.xl),
            AyreButton(
              label: 'Delete account',
              kind: AyreButtonKind.danger,
              glyph: AyreGlyph.signOut,
              busy: _busy,
              onPressed: _canDelete ? _delete : null,
            ),
            const SizedBox(height: AppSpace.sm),
            AyreButton(
              label: 'Keep my account',
              kind: AyreButtonKind.outline,
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line in the "what happens" list. Not tappable, so no chevron.
class _Consequence extends StatelessWidget {
  const _Consequence({
    required this.glyph,
    required this.title,
    required this.subtitle,
  });

  final AyreGlyph glyph;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) =>
      SettingRow(glyph: glyph, title: title, subtitle: subtitle);
}
