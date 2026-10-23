
class FormValidators {
  static String? requiredField(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError =
        requiredField(value, 'Please enter your email');
    if (requiredError != null) return requiredError;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(value!.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? feedback(String? value) {
    final requiredError =
        requiredField(value, 'Please share some details with us');
    if (requiredError != null) return requiredError;

    if (value!.trim().length < 10) {
      return 'Please write at least 10 characters';
    }
    return null;
  }

  static String? password(String? value, {bool signup = false}) {
    final requiredError =
        requiredField(value, 'Enter your password');
    if (requiredError != null) return requiredError;

    if (signup && value!.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }
}
