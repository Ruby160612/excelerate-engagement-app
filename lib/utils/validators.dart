/// Form rules shared by Login and Sign Up, so both screens check input the
/// same way and show the same messages.
abstract final class Validators {
  /// Minimum length for a new password (applied when creating an account).
  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Empty and badly formed addresses show the same message.
  static String? email(String? value) =>
      value != null && _email.hasMatch(value.trim())
          ? null
          : 'Enter a valid email';

  /// Login only needs a value, so accounts created under an older rule can
  /// still sign in. Pass [checkLength] when the user is choosing a password.
  static String? password(String? value, {bool checkLength = false}) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (checkLength && value.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    return null;
  }

  /// A text field that must not be blank, with the message to show.
  static String? required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;
}
