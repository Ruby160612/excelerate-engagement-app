import '../models/program_responses.dart';
import 'program_service.dart';

/// Future Firestore adapter. Intentionally performs no backend reads or writes.
/// See docs/PROGRAM_API_CONTRACT.md for collection mapping, authenticated learner
/// scoping, atomic duplicate checks and server-owned fields.
class FirebaseProgramService implements ProgramService {
  Never _unfinished() => throw const ProgramException(
      ProgramFailure.unavailable,
      'The Firebase program service is not configured.',
      code: ProgramErrorCode.notConfigured);
  @override
  Future<ProgramListResponse> getPrograms(
          {String? search, String? category}) async =>
      _unfinished();
  @override
  Future<ProgramDetailResponse> getProgramById(String id) async =>
      _unfinished();
  @override
  Future<ProgramRegistrationResponse> registerForProgram(String id) async =>
      _unfinished();
}
