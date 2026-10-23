import 'dart:async';
import 'dart:convert';

import 'package:excelerate_talent_hub/models/program.dart';
import 'package:excelerate_talent_hub/models/program_registration.dart';
import 'package:excelerate_talent_hub/models/program_responses.dart';
import 'package:excelerate_talent_hub/services/api_program_service.dart';
import 'package:excelerate_talent_hub/services/api_service.dart';
import 'package:excelerate_talent_hub/services/firebase_program_service.dart';
import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:excelerate_talent_hub/services/mock_data.dart';
import 'package:excelerate_talent_hub/services/mock_program_service.dart';
import 'package:excelerate_talent_hub/services/program_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

TypeMatcher<ProgramException> failure(ProgramErrorCode code,
        {required bool retryable}) =>
    isA<ProgramException>()
        .having((error) => error.code, 'code', code)
        .having((error) => error.retryable, 'retryable', retryable);

void main() {
  late List<Map<String, dynamic>> fixtures;
  setUpAll(() async => fixtures = await loadMockPrograms());

  group('typed responses', () {
    test('list and detail JSON round trip with string IDs and UTC dates', () {
      final list =
          ProgramListResponse.fromJson({'items': fixtures, 'skipped': 0});
      expect(list.programs, hasLength(8));
      expect(
          ProgramListResponse.fromJson(list.toJson()).toJson(), list.toJson());
      final detail = ProgramDetailResponse(list.programs.first);
      expect(ProgramDetailResponse.fromJson(detail.toJson()).toJson(),
          detail.toJson());
      expect(list.programs.first.toJson()['id'], isA<String>());
      expect(list.programs.first.toJson()['start_date'], endsWith('Z'));
      expect(() => list.programs.clear(), throwsUnsupportedError);
    });

    test('missing or invalid IDs are rejected and broken records counted', () {
      for (final id in [null, '', '  ', true, <String, dynamic>{}]) {
        expect(() => Program.fromJson({...fixtures.first, 'id': id}),
            throwsFormatException);
      }
      final list = ProgramListResponse.fromJson({
        'items': [
          fixtures.first,
          {'id': 'broken'},
          null
        ],
        'skipped': 1,
      });
      expect(list.programs, hasLength(1));
      expect(list.skipped, 3);
      expect(() => ProgramListResponse.fromJson({'items': {}, 'skipped': 0}),
          throwsFormatException);
    });

    test('registration relationships round trip without inventing metadata',
        () {
      final registration = ProgramRegistration.fromJson({
        'id': 'registration-1',
        'programId': 'prog-001',
        'learnerId': 'learner-1',
        'status': 'registered',
        'registeredAt': '2026-10-23T12:00:00.000Z',
      });
      expect(ProgramRegistration.fromJson(registration.toJson()).toJson(),
          registration.toJson());
      expect(registration.registeredAt.isUtc, isTrue);
      final program =
          Program.fromJson(fixtures.first).copyWith(isRegistered: true);
      final response =
          ProgramRegistrationResponse(program, registration: registration);
      expect(ProgramRegistrationResponse.fromJson(response.toJson()).toJson(),
          response.toJson());
      final legacy =
          ProgramRegistrationResponse.fromJson({'program': program.toJson()});
      expect(legacy.registration, isNull);
      expect(legacy.toJson().containsKey('registration'), isFalse);
      for (final overrides in [
        {'programId': 'other'},
        {'status': 'cancelled'},
        {'status': 'unknown'},
        {'learnerId': 123},
        {'registeredAt': 'invalid'},
      ]) {
        expect(
            () => ProgramRegistrationResponse.fromJson({
                  'program': program.toJson(),
                  'registration': {...registration.toJson(), ...overrides},
                }),
            throwsFormatException);
      }
      expect(
          () =>
              ProgramRegistrationResponse.fromJson({'program': fixtures.first}),
          throwsFormatException);
    });
  });

  group('mock program service', () {
    late MockApi mock;
    late ApiService api;
    late ProgramService service;

    Future<void> signIn(String account) async {
      final session = await api.post('/auth/login', {
        'email': '$account@example.com',
        'password': '${account}123',
      }) as Map;
      api.sessionToken = session['token'] as String;
    }

    setUp(() async {
      mock =
          MockApi(latency: Duration.zero, programLoader: () async => fixtures);
      api = ApiService(baseUrl: MockApi.baseUrl, client: mock.client);
      addTearDown(api.dispose);
      service = MockProgramService(api);
      await signIn('member');
    });

    test('list and ID lookup reuse the existing catalogue', () async {
      final list = await service.getPrograms();
      expect(list.programs.map((program) => program.id),
          fixtures.map((json) => json['id']));
      expect((await service.getProgramById('prog-005')).program.category,
          'webinar');
      await expectLater(service.getProgramById('missing'),
          throwsA(failure(ProgramErrorCode.notFound, retryable: false)));
    });

    test('search combines title/description substrings and category filters',
        () async {
      expect(
          (await service.getPrograms(search: '  DIGITAL  '))
              .programs
              .map((p) => p.id),
          ['prog-001']);
      expect(
          (await service.getPrograms(
                  search: 'recruiters', category: ' WORKSHOP '))
              .programs
              .map((p) => p.id),
          ['prog-003']);
      expect(
          (await service.getPrograms(category: 'webinar'))
              .programs
              .map((p) => p.id),
          ['prog-005', 'prog-006']);
      expect(
          (await service.getPrograms(search: 'digital', category: 'webinar'))
              .programs,
          isEmpty);
      expect((await service.getPrograms(search: '  ', category: '')).programs,
          hasLength(8));
      expect(
          (await service.getPrograms(category: 'unknown')).programs, isEmpty);
    });

    test(
        'registration updates list, detail and repository; duplicate is rejected',
        () async {
      final response = await service.registerForProgram('prog-001');
      expect(response.program.isRegistered, isTrue);
      expect(response.registration!.programId, 'prog-001');
      expect(response.registration!.learnerId, 'u-member');
      expect(response.registration!.id, isA<String>());
      expect(
          response.registration!.status, ProgramRegistrationStatus.registered);
      expect(
          (await service.getPrograms()).programs.where((p) => p.isRegistered),
          hasLength(2));
      final repository = ServiceProgramRepository(service);
      expect((await repository.fetchProgram('prog-001')).isRegistered, isTrue);
      await expectLater(
          service.registerForProgram('prog-001'),
          throwsA(
              failure(ProgramErrorCode.alreadyRegistered, retryable: false)));
      expect(
          (await service.getPrograms()).programs.where((p) => p.isRegistered),
          hasLength(2));
      await signIn('learner');
      expect((await service.getProgramById('prog-001')).program.isRegistered,
          isFalse);
      await signIn('member');
      expect((await service.getProgramById('prog-001')).program.isRegistered,
          isTrue);
    });

    test('concurrent registration creates only one enrollment', () async {
      final outcomes = await Future.wait(List.generate(2, (_) async {
        try {
          await service.registerForProgram('prog-002');
          return 'registered';
        } on ProgramException catch (error) {
          return error.code.name;
        }
      }));
      expect(outcomes, unorderedEquals(['registered', 'alreadyRegistered']));
      expect(
          (await service.getPrograms())
              .programs
              .where((p) => p.id == 'prog-002' && p.isRegistered),
          hasLength(1));
    });

    test('admin writes and unauthenticated reads are denied', () async {
      await signIn('admin');
      await expectLater(
          service.registerForProgram('prog-001'),
          throwsA(
              failure(ProgramErrorCode.permissionDenied, retryable: false)));
      api.sessionToken = null;
      await expectLater(service.getPrograms(),
          throwsA(failure(ProgramErrorCode.unauthenticated, retryable: false)));
    });

    test('empty catalogue stays empty', () async {
      final emptyApi = ApiService(
          baseUrl: MockApi.baseUrl,
          client: MockApi(latency: Duration.zero, programLoader: () async => [])
              .client);
      addTearDown(emptyApi.dispose);
      final session = await emptyApi.post('/auth/login',
          {'email': 'member@example.com', 'password': 'member123'}) as Map;
      emptyApi.sessionToken = session['token'] as String;
      expect(
          (await MockProgramService(emptyApi).getPrograms()).programs, isEmpty);
    });
  });

  group('safe error mapping', () {
    ProgramService adapter(
        Future<http.Response> Function(http.Request) handler) {
      final api = ApiService(
          baseUrl: 'https://example.com/api', client: MockClient(handler));
      addTearDown(api.dispose);
      return ApiProgramService(api);
    }

    for (final entry in {
      400: ProgramErrorCode.invalidData,
      401: ProgramErrorCode.unauthenticated,
      403: ProgramErrorCode.permissionDenied,
      404: ProgramErrorCode.notFound,
      409: ProgramErrorCode.alreadyRegistered,
      500: ProgramErrorCode.unexpectedBackendFailure,
      503: ProgramErrorCode.unexpectedBackendFailure,
      504: ProgramErrorCode.timeout,
    }.entries) {
      test(
          'HTTP ${entry.key} becomes ${entry.value.name}, without automatic retry',
          () async {
        var requests = 0;
        final service = adapter((_) async {
          requests++;
          return http.Response(
              jsonEncode({'message': 'private backend diagnostic'}), entry.key);
        });
        await expectLater(
            service.registerForProgram('prog-001'),
            throwsA(failure(entry.value, retryable: entry.key >= 500).having(
                (error) => error.message,
                'safe message',
                isNot(contains('private')))));
        expect(requests, 1);
      });
    }

    test('network failure and timeout expose distinct retryable errors',
        () async {
      final offline =
          adapter((_) async => throw http.ClientException('socket detail'));
      await expectLater(
          offline.getPrograms(),
          throwsA(
              failure(ProgramErrorCode.networkUnavailable, retryable: true)));
      final timeout =
          adapter((_) async => throw TimeoutException('transport detail'));
      await expectLater(timeout.getPrograms(),
          throwsA(failure(ProgramErrorCode.timeout, retryable: true)));
    });

    test(
        'malformed registration success is invalid, not a successful enrollment',
        () async {
      final service = adapter((request) async {
        expect(jsonDecode(request.body),
            isEmpty); // No client-owned identity/status/time.
        return http.Response(jsonEncode(fixtures.first), 200);
      });
      await expectLater(service.registerForProgram('prog-001'),
          throwsA(failure(ProgramErrorCode.invalidData, retryable: false)));
    });

    test(
        'Firebase placeholder is substitutable and reports not configured safely',
        () async {
      final ProgramService firebase = FirebaseProgramService();
      final repository = ServiceProgramRepository(firebase);
      for (final operation in [
        repository.fetchPrograms,
        () => repository.fetchProgram('prog-001'),
        () => repository.register('prog-001')
      ]) {
        await expectLater(operation(),
            throwsA(failure(ProgramErrorCode.notConfigured, retryable: false)));
      }
    });
  });
}
