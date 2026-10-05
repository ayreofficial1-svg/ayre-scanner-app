/// Client-side guidance rules (3.6). The server-side policy is the source of
/// truth; these exist to help the reader get it right first time.
class AuthValidators {
  const AuthValidators._();

  static final RegExp _name = RegExp(
    r"^[\p{L}\p{M}][\p{L}\p{M} .'’-]*$",
    unicode: true,
  );
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? name(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Enter your name';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 60) return 'Name must be 60 characters or fewer';
    if (!_name.hasMatch(v)) {
      return 'Use letters, spaces, apostrophes, hyphens or dots only';
    }
    return null;
  }

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Enter your email address';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? confirm(String password, String confirm) {
    if (confirm.isEmpty) return 'Re-enter your password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }
}

/// Live result of checking a password against the policy.
class PasswordCheck {
  PasswordCheck(String password, String email)
    : length = password.length >= minLength && password.length <= maxLength,
      upper = RegExp(r'\p{Lu}', unicode: true).hasMatch(password),
      lower = RegExp(r'\p{Ll}', unicode: true).hasMatch(password),
      number = RegExp(r'\d').hasMatch(password),
      special = RegExp(r'[^\p{L}\p{N}\s]', unicode: true).hasMatch(password),
      notEmail =
          password.isEmpty ||
          email.trim().isEmpty ||
          password.toLowerCase() != email.trim().toLowerCase();

  static const int minLength = 8;
  static const int maxLength = 128;

  final bool length;
  final bool upper;
  final bool lower;
  final bool number;

  /// Recommended, not required.
  final bool special;
  final bool notEmail;

  bool get valid => length && upper && lower && number && notEmail;
}
