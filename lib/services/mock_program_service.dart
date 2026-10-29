import '../models/program_responses.dart';
import 'api_program_service.dart';
import 'api_service.dart';
import 'program_service.dart';

/// Reuses MockApi's asset loader, latency, authentication and per-learner state.
/// Supply the same MockApi-backed ApiService used by the rest of the app.
class MockProgramService implements ProgramService {
  MockProgramService(ApiService api) : _delegate = ApiProgramService(api);
  final ProgramService _delegate;

  @override
  Future<ProgramListResponse> getPrograms({String? search, String? category}) =>
      _delegate.getPrograms(search: search, category: category);
  @override
  Future<ProgramDetailResponse> getProgramById(String id) =>
      _delegate.getProgramById(id);
  @override
  Future<ProgramRegistrationResponse> registerForProgram(String id) =>
      _delegate.registerForProgram(id);
}
