import '../models/program.dart';
import '../models/program_responses.dart';
import 'api_program_service.dart';
import 'api_service.dart';
import 'program_service.dart';

export 'program_service.dart';

typedef ProgramListResult = ProgramListResponse;

/// Stable UI facade. The implementation depends only on ProgramService.
abstract class ProgramRepository {
  Future<ProgramListResult> fetchPrograms();
  Future<Program> fetchProgram(String id);
  Future<Program> register(String id);
}

class ServiceProgramRepository implements ProgramRepository {
  ServiceProgramRepository(this._service);
  final ProgramService _service;
  @override
  Future<ProgramListResult> fetchPrograms() => _service.getPrograms();
  @override
  Future<Program> fetchProgram(String id) async =>
      (await _service.getProgramById(id)).program;
  @override
  Future<Program> register(String id) async =>
      (await _service.registerForProgram(id)).program;
}

/// Compatibility adapter for existing HTTP callers and tests.
class ApiProgramRepository extends ServiceProgramRepository {
  ApiProgramRepository(ApiService api) : super(ApiProgramService(api));
}
