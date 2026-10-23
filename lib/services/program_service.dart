import '../models/program_responses.dart';

// Presentation categories kept stable for existing repository consumers.
enum ProgramFailure { notFound, invalidData, unavailable }

enum ProgramErrorCode {
  networkUnavailable,
  timeout,
  notFound,
  alreadyRegistered,
  permissionDenied,
  unauthenticated,
  invalidData,
  unexpectedBackendFailure,
  notConfigured,
}

class ProgramException implements Exception {
  const ProgramException(this.kind, this.message, {ProgramErrorCode? code})
      : _code = code;

  final ProgramFailure kind;
  final String message;
  final ProgramErrorCode? _code;

  ProgramErrorCode get code =>
      _code ??
      switch (kind) {
        ProgramFailure.notFound => ProgramErrorCode.notFound,
        ProgramFailure.invalidData => ProgramErrorCode.invalidData,
        ProgramFailure.unavailable => ProgramErrorCode.unexpectedBackendFailure,
      };

  /// Allows an explicit user retry. Implementations never automatically retry writes.
  bool get retryable => switch (code) {
        ProgramErrorCode.networkUnavailable ||
        ProgramErrorCode.timeout ||
        ProgramErrorCode.unexpectedBackendFailure =>
          true,
        _ => false,
      };

  @override
  String toString() => message;
}

/// No transport objects, Firebase snapshots or backend-generated write fields.
abstract interface class ProgramService {
  Future<ProgramListResponse> getPrograms({String? search, String? category});
  Future<ProgramDetailResponse> getProgramById(String id);
  Future<ProgramRegistrationResponse> registerForProgram(String id);
}
