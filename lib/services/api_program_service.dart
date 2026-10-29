import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/program.dart';
import '../models/program_query.dart';
import '../models/program_responses.dart';
import 'api_service.dart';
import 'program_service.dart';

/// Adapts the existing bare-array/flat-program HTTP API to typed responses.
class ApiProgramService implements ProgramService {
  ApiProgramService(this._api);
  final ApiService _api;

  @override
  Future<ProgramListResponse> getPrograms({String? search, String? category}) =>
      _request(() async {
        final response =
            ProgramListResponse.fromLegacyJson(await _api.get('/programs'));
        return ProgramListResponse(
          ProgramQuery(search: search, category: category)
              .apply(response.programs),
          skipped: response.skipped,
        );
      },
          notFound: 'No programs were found.',
          unavailable: 'Unable to load this page. Please try again.',
          invalid: 'The programs data is invalid.');

  @override
  Future<ProgramDetailResponse> getProgramById(String id) => _request(() async {
        final data = await _api.get('/programs/${Uri.encodeComponent(id)}');
        return ProgramDetailResponse(_program(data, id));
      },
          notFound: 'This program could not be found.',
          unavailable: 'Unable to load this program. Please try again.',
          invalid: "This program's information is incomplete or invalid.");

  @override
  Future<ProgramRegistrationResponse> registerForProgram(String id) =>
      _request(() async {
        final data = await _api
            .post('/programs/${Uri.encodeComponent(id)}/register', {});
        final program = _program(data, id);
        return ProgramRegistrationResponse.fromJson({
          'program': program.toJson(),
          if ((data as Map)['registration'] != null)
            'registration': data['registration'],
        });
      },
          notFound: 'This program is no longer available.',
          unavailable: 'Unable to register. Please try again.',
          invalid: 'Unable to register. Please try again.');

  Program _program(Object? data, String id) {
    if (data is! Map) throw const FormatException('Expected a program.');
    final program = Program.fromJson(Map<String, dynamic>.from(data));
    if (program.id != id) throw const FormatException('Program ID mismatch.');
    return program;
  }

  Future<T> _request<T>(
    Future<T> Function() request, {
    required String notFound,
    required String unavailable,
    required String invalid,
  }) async {
    try {
      return await request();
    } on ProgramException {
      rethrow;
    } on ApiException catch (error) {
      switch (error.statusCode) {
        case 400:
        case 422:
          throw ProgramException(ProgramFailure.invalidData, invalid);
        case 404:
          throw ProgramException(ProgramFailure.notFound, notFound);
        case 409:
          throw const ProgramException(ProgramFailure.unavailable,
              'You are already registered for this program.',
              code: ProgramErrorCode.alreadyRegistered);
        case 401:
          throw const ProgramException(
              ProgramFailure.unavailable, 'Please sign in again.',
              code: ProgramErrorCode.unauthenticated);
        case 403:
          throw const ProgramException(ProgramFailure.unavailable,
              'You do not have permission to perform this action.',
              code: ProgramErrorCode.permissionDenied);
        case 408:
        case 504:
          throw ProgramException(ProgramFailure.unavailable, unavailable,
              code: ProgramErrorCode.timeout);
      }
      if (error.message == 'The service returned an invalid response.') {
        throw ProgramException(ProgramFailure.invalidData, invalid);
      }
      if (error.message ==
          'The service is not configured. Please contact your administrator.') {
        throw const ProgramException(ProgramFailure.unavailable,
            'The program service is not configured.',
            code: ProgramErrorCode.notConfigured);
      }
      throw ProgramException(ProgramFailure.unavailable, unavailable,
          code: ProgramErrorCode.unexpectedBackendFailure);
    } on TimeoutException {
      throw ProgramException(ProgramFailure.unavailable, unavailable,
          code: ProgramErrorCode.timeout);
    } on http.ClientException {
      throw ProgramException(ProgramFailure.unavailable, unavailable,
          code: ProgramErrorCode.networkUnavailable);
    } on FormatException {
      throw ProgramException(ProgramFailure.invalidData, invalid);
    } on TypeError {
      throw ProgramException(ProgramFailure.invalidData, invalid);
    } on Exception {
      throw ProgramException(ProgramFailure.unavailable, unavailable,
          code: ProgramErrorCode.unexpectedBackendFailure);
    }
  }
}
