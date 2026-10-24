import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

/// Where a form submission is right now.
///
/// idle -> validating -> submitting -> success
///                   \-> error (validation failed or the request failed)
enum SubmissionStatus { idle, validating, submitting, success, error }

/// Returns an error message for [value], or null when it is valid.
typedef FieldValidator = String? Function(String value);

/// One state source for a form: field values, validation results and the
/// loading / submitting / success / error state.
///
/// The Registration and Feedback forms each own one controller, and their
/// screens only read from it (via `ListenableBuilder` or Provider), so the
/// button, the field errors and the message always come from the same place.
class SubmissionController extends ChangeNotifier {
  SubmissionController({
    Map<String, String> initialValues = const {},
    Map<String, FieldValidator> validators = const {},
  })  : _values = Map.of(initialValues),
        _validators = Map.of(validators);

  final Map<String, String> _values;
  final Map<String, FieldValidator> _validators;
  final Map<String, String> _errors = {};

  SubmissionStatus _status = SubmissionStatus.idle;
  String? _message;
  Object? _rawError;
  Future<void> Function(Map<String, String> values)? _lastAction;
  bool _disposed = false;

  SubmissionStatus get status => _status;

  /// Form-level message: the failure reason, or null.
  String? get message => _message;

  /// Preserved raw exception for diagnostics / debugging.
  Object? get rawError => _rawError;

  Map<String, String> get values => Map.unmodifiable(_values);
  Map<String, String> get fieldErrors => Map.unmodifiable(_errors);

  bool get isIdle => _status == SubmissionStatus.idle;
  bool get isValidating => _status == SubmissionStatus.validating;
  bool get isSubmitting => _status == SubmissionStatus.submitting;
  bool get isSuccess => _status == SubmissionStatus.success;
  bool get isError => _status == SubmissionStatus.error;

  /// False while a request is running or after it succeeded, so a repeated tap
  /// cannot send the same submission twice.
  bool get canSubmit => !isSubmitting && !isSuccess;

  /// Whether a previous failed action can be retried.
  bool get canRetry => _lastAction != null && canSubmit;

  String valueOf(String key) => _values[key] ?? '';
  String? errorOf(String key) => _errors[key];

  /// Updates one field. Its own error is cleared, and a form left in the error
  /// state returns to idle, so a failed attempt never stays stuck on screen.
  void setValue(String key, String value) {
    if (isSubmitting) return; // values are frozen while the request runs
    _values[key] = value;
    _errors.remove(key);
    if (_status == SubmissionStatus.error ||
        _status == SubmissionStatus.success) {
      _status = SubmissionStatus.idle;
      _message = null;
    }
    _notify();
  }

  /// Clears active errors and restores the controller to [SubmissionStatus.idle]
  /// without clearing entered field values.
  void clearError() {
    if (_status == SubmissionStatus.error) {
      _status = SubmissionStatus.idle;
      _message = null;
      _errors.clear();
      _notify();
    }
  }

  /// Validates, then runs [action] with the current values.
  ///
  /// Returns true only when the action completed. Calls made while a request is
  /// running, or after success, are ignored and return false.
  Future<bool> submit(
    Future<void> Function(Map<String, String> values) action,
  ) async {
    if (!canSubmit) return false;
    _lastAction = action;

    _status = SubmissionStatus.validating;
    _message = null;
    _rawError = null;
    _errors.clear();
    _notify();

    final problems = <String, String>{};
    _validators.forEach((key, validate) {
      final problem = validate(valueOf(key));
      if (problem != null) problems[key] = problem;
    });
    if (problems.isNotEmpty) {
      _errors.addAll(problems);
      _status = SubmissionStatus.error;
      _message = 'Please fix the highlighted fields.';
      _notify();
      return false;
    }

    _status = SubmissionStatus.submitting;
    _notify();
    try {
      await action(values);
      _status = SubmissionStatus.success;
      _message = null;
      _rawError = null;
      _notify();
      return true;
    } catch (error) {
      _rawError = error;
      _status = SubmissionStatus.error;
      _message = describe(error);
      _notify();
      return false;
    }
  }

  /// Retries the last attempted submission action if available.
  Future<bool> retry() async {
    if (_lastAction != null && canSubmit) {
      return submit(_lastAction!);
    }
    return false;
  }

  /// Back to a clean idle form. Values are cleared unless [keepValues] is set.
  void reset({bool keepValues = false}) {
    if (isSubmitting) return;
    if (!keepValues) _values.clear();
    _errors.clear();
    _message = null;
    _rawError = null;
    _lastAction = null;
    _status = SubmissionStatus.idle;
    _notify();
  }

  /// Translates an error into a user-friendly message without exposing sensitive technical details.
  static String describe(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final text = error.toString().trim();
    if (text.isEmpty ||
        text.startsWith('Instance of') ||
        text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('TimeoutException') ||
        text.contains('HttpException')) {
      return 'Unable to connect to the service. Please check your connection and try again.';
    }
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
