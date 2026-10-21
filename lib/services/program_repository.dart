import '../models/program.dart';
import 'api_service.dart';

enum ProgramFailure { notFound, invalidData, unavailable }

class ProgramException implements Exception {
  const ProgramException(this.kind, this.message);

  final ProgramFailure kind;
  final String message;

  @override
  String toString() => message;
}

class ProgramListResult {
  const ProgramListResult(this.programs, {this.skipped = 0});

  final List<Program> programs;
  final int skipped;
}

/// The only way screens read or change program data, so the source can change.
abstract class ProgramRepository {
  Future<ProgramListResult> fetchPrograms();
  Future<Program> fetchProgram(String id);
  Future<Program> register(String id);
}

class ApiProgramRepository implements ProgramRepository {
  ApiProgramRepository(this._api);

  final ApiService _api;

  // Mirrors the message ApiService throws when a success body is not JSON.
  static const _invalidResponse = 'The service returned an invalid response.';

  @override
  Future<ProgramListResult> fetchPrograms() async {
    final data = await _send(
      () => _api.get('/programs'),
      notFound: 'No programs were found.',
      unavailable: 'Unable to load this page. Please try again.',
      invalid: 'The programs data is invalid.',
    );
    if (data is! List) {
      throw const ProgramException(
          ProgramFailure.invalidData, 'The programs data is invalid.');
    }
    final programs = <Program>[];
    var skipped = 0;
    for (final item in data) {
      final program = _tryParse(item);
      if (program == null) {
        skipped++;
      } else {
        programs.add(program);
      }
    }
    return ProgramListResult(programs, skipped: skipped);
  }

  @override
  Future<Program> fetchProgram(String id) async {
    final data = await _send(
      () => _api.get('/programs/${Uri.encodeComponent(id)}'),
      notFound: 'This program could not be found.',
      unavailable: 'Unable to load this program. Please try again.',
      invalid: _invalidProgram,
    );
    return _requireProgram(data, id, _invalidProgram);
  }

  @override
  Future<Program> register(String id) async {
    const failed = 'Unable to register. Please try again.';
    final data = await _send(
      () => _api.post('/programs/${Uri.encodeComponent(id)}/register', {}),
      notFound: 'This program is no longer available.',
      unavailable: failed,
      invalid: failed,
    );
    return _requireProgram(data, id, failed);
  }

  static const _invalidProgram =
      "This program's information is incomplete or invalid.";

  Future<dynamic> _send(
    Future<dynamic> Function() request, {
    required String notFound,
    required String unavailable,
    required String invalid,
  }) async {
    try {
      return await request();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        throw ProgramException(ProgramFailure.notFound, notFound);
      }
      if (error.statusCode == null && error.message == _invalidResponse) {
        throw ProgramException(ProgramFailure.invalidData, invalid);
      }
      throw ProgramException(ProgramFailure.unavailable, unavailable);
    } on Exception {
      throw ProgramException(ProgramFailure.unavailable, unavailable);
    }
  }

  Program _requireProgram(Object? data, String id, String message) {
    final program = _tryParse(data);
    if (program == null || program.id != id) {
      throw ProgramException(ProgramFailure.invalidData, message);
    }
    return program;
  }

  Program? _tryParse(Object? item) {
    if (item is! Map) return null;
    final id = item['id'];
    if (id == null || id.toString().isEmpty) return null;
    try {
      return Program.fromJson(Map<String, dynamic>.from(item));
    } catch (_) {
      return null;
    }
  }
}
