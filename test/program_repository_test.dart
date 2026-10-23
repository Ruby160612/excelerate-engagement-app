import 'dart:async';
import 'dart:convert';

import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:excelerate_talent_hub/services/mock_data.dart';
import 'package:excelerate_talent_hub/services/program_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ProgramRepository _repository(
  Future<http.Response> Function(http.Request request) handler,
) {
  final api = ApiService(
      baseUrl: 'https://example.com/api', client: MockClient(handler));
  addTearDown(api.dispose);
  return ApiProgramRepository(api);
}

http.Response _json(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

Matcher _failure(ProgramFailure kind) =>
    isA<ProgramException>().having((e) => e.kind, 'kind', kind);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Map<String, dynamic>> mockPrograms;

  setUpAll(() async => mockPrograms = await loadMockPrograms());

  group('fetchPrograms', () {
    test('returns every program when all records are valid', () async {
      final repository = _repository((_) async => _json(mockPrograms));
      final result = await repository.fetchPrograms();
      expect(result.programs.length, mockPrograms.length);
      expect(result.skipped, 0);
    });

    test('skips broken records and counts them', () async {
      const base = {
        'start_date': '2026-11-01T09:00:00Z',
        'category': 'course',
      };
      final repository = _repository((_) async => _json([
            ...mockPrograms.take(2),
            {'id': 'bad-1', ...base},
            5,
            {'title': 'No id', ...base},
            {'id': 'bad-2', 'title': 'Bad date', 'start_date': 'nope'},
          ]));
      final result = await repository.fetchPrograms();
      expect(result.programs.map((p) => p.id), ['prog-001', 'prog-002']);
      expect(result.skipped, 4);
    });

    test('a response that is not a list is invalid data', () async {
      final repository = _repository((_) async => _json({'programs': []}));
      await expectLater(repository.fetchPrograms(),
          throwsA(_failure(ProgramFailure.invalidData)));
    });

    test('a body that is not JSON is invalid data', () async {
      final repository =
          _repository((_) async => http.Response('<html></html>', 200));
      await expectLater(repository.fetchPrograms(),
          throwsA(_failure(ProgramFailure.invalidData)));
    });

    test('server errors, offline and timeouts are unavailable', () async {
      final failing = <Future<http.Response> Function(http.Request)>[
        (_) async => _json({'message': 'Down'}, 500),
        (_) async => throw http.ClientException('offline'),
        (_) async => throw TimeoutException('slow'),
      ];
      for (final handler in failing) {
        await expectLater(_repository(handler).fetchPrograms(),
            throwsA(_failure(ProgramFailure.unavailable)));
      }
    });
  });

  group('fetchProgram', () {
    test('returns the matching program', () async {
      final repository = _repository((request) async {
        expect(request.url.path, '/api/programs/prog-003');
        return _json(mockPrograms[2]);
      });
      final program = await repository.fetchProgram('prog-003');
      expect(program.title, 'CV and Interview Workshop');
    });

    test('encodes the id in the path', () async {
      final repository = _repository((request) async {
        expect(request.url.path, '/api/programs/a%2Fb%20c');
        return _json({...mockPrograms.first, 'id': 'a/b c'});
      });
      expect((await repository.fetchProgram('a/b c')).id, 'a/b c');
    });

    test('404 is not found', () async {
      final repository = _repository(
          (_) async => _json({'message': 'Program not found.'}, 404));
      await expectLater(repository.fetchProgram('missing'),
          throwsA(_failure(ProgramFailure.notFound)));
    });

    test('a record with missing fields is invalid data', () async {
      final repository = _repository((_) async => _json({'id': 'p1'}));
      await expectLater(repository.fetchProgram('p1'),
          throwsA(_failure(ProgramFailure.invalidData)));
    });

    test('a record for a different id is invalid data', () async {
      final repository = _repository((_) async => _json(mockPrograms.first));
      await expectLater(repository.fetchProgram('prog-002'),
          throwsA(_failure(ProgramFailure.invalidData)));
    });

    test('a non-object response is invalid data', () async {
      final repository = _repository((_) async => _json([1, 2]));
      await expectLater(repository.fetchProgram('prog-001'),
          throwsA(_failure(ProgramFailure.invalidData)));
    });

    test('a body that is not JSON is invalid data', () async {
      final repository = _repository((_) async => http.Response('oops', 200));
      await expectLater(repository.fetchProgram('prog-001'),
          throwsA(_failure(ProgramFailure.invalidData)));
    });

    test('server errors are unavailable', () async {
      final repository = _repository((_) async => _json({}, 503));
      await expectLater(repository.fetchProgram('prog-001'),
          throwsA(_failure(ProgramFailure.unavailable)));
    });
  });

  group('register', () {
    test('returns the updated program', () async {
      final repository = _repository((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/programs/prog-001/register');
        return _json({...mockPrograms.first, 'is_registered': true});
      });
      expect((await repository.register('prog-001')).isRegistered, isTrue);
    });

    test('maps failures to clear kinds and messages', () async {
      final notFound = _repository((_) async => _json({}, 404));
      await expectLater(
          notFound.register('x'),
          throwsA(isA<ProgramException>()
              .having((e) => e.kind, 'kind', ProgramFailure.notFound)
              .having((e) => e.message, 'message',
                  'This program is no longer available.')));
      final forbidden = _repository((_) async => _json({}, 403));
      await expectLater(
          forbidden.register('x'),
          throwsA(isA<ProgramException>()
              .having((e) => e.kind, 'kind', ProgramFailure.unavailable)
              .having((e) => e.message, 'message',
                  'You do not have permission to perform this action.')
              .having((e) => e.code, 'code', ProgramErrorCode.permissionDenied)
              .having((e) => e.retryable, 'retryable', false)));
    });
  });

  group('with the mock API', () {
    Future<ProgramRepository> signedIn(
      List<Map<String, dynamic>> data, {
      String email = 'member@example.com',
      String password = 'member123',
    }) async {
      final mock =
          MockApi(latency: Duration.zero, programLoader: () async => data);
      final api = ApiService(baseUrl: MockApi.baseUrl, client: mock.client);
      addTearDown(api.dispose);
      final session = await api
          .post('/auth/login', {'email': email, 'password': password}) as Map;
      api.sessionToken = session['token'] as String;
      return ApiProgramRepository(api);
    }

    test('lists the JSON programs and skips a broken record', () async {
      final repository = await signedIn([
        ...mockPrograms,
        {'id': 'broken', 'title': 'No date or category'},
      ]);
      final result = await repository.fetchPrograms();
      expect(result.programs.length, mockPrograms.length);
      expect(result.skipped, 1);
    });

    test('loads one program by id and reports unknown or broken ids', () async {
      final repository = await signedIn([
        ...mockPrograms,
        {'id': 'broken', 'title': 'No date or category'},
      ]);
      expect((await repository.fetchProgram('prog-005')).category, 'webinar');
      await expectLater(repository.fetchProgram('does-not-exist'),
          throwsA(_failure(ProgramFailure.notFound)));
      await expectLater(repository.fetchProgram('broken'),
          throwsA(_failure(ProgramFailure.invalidData)));
    });

    test('registration is kept per user', () async {
      final member = await signedIn(mockPrograms);
      expect((await member.register('prog-001')).isRegistered, isTrue);
      final registered = (await member.fetchPrograms())
          .programs
          .where((p) => p.isRegistered)
          .map((p) => p.id)
          .toSet();
      expect(registered, {'prog-001', 'prog-008'});

      final learner = await signedIn(mockPrograms,
          email: 'learner@example.com', password: 'learner123');
      expect((await learner.fetchProgram('prog-001')).isRegistered, isFalse);
    });

    test('admins cannot register', () async {
      final admin = await signedIn(mockPrograms,
          email: 'admin@example.com', password: 'admin123');
      await expectLater(admin.register('prog-001'),
          throwsA(_failure(ProgramFailure.unavailable)));
    });
  });
}
