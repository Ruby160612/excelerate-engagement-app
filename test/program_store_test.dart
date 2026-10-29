import 'dart:async';

import 'package:excelerate_talent_hub/models/program.dart';
import 'package:excelerate_talent_hub/services/program_repository.dart';
import 'package:excelerate_talent_hub/state/program_store.dart';
import 'package:excelerate_talent_hub/state/submission_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Program _program(String id, {bool registered = false}) => Program(
      id: id,
      title: 'Program $id',
      description: 'About $id',
      startDate: DateTime.utc(2026, 11, 2),
      schedule: 'Weekdays',
      category: 'workshop',
      isRegistered: registered,
    );

class _FakeRepository implements ProgramRepository {
  List<Program> programs = [_program('1'), _program('2')];
  Object? listError;
  Object? registerError;
  Completer<Program>? registerGate;
  Completer<Program>? fetchGate;
  int registerCalls = 0;
  int fetchCalls = 0;

  @override
  Future<ProgramListResult> fetchPrograms() async {
    final error = listError;
    if (error != null) throw error;
    return ProgramListResult(List.of(programs), skipped: 1);
  }

  @override
  Future<Program> fetchProgram(String id) {
    fetchCalls++;
    final gate = fetchGate;
    if (gate != null) return gate.future;
    final match = programs.where((p) => p.id == id);
    if (match.isEmpty) {
      throw const ProgramException(
          ProgramFailure.notFound, 'This program could not be found.');
    }
    return Future.value(match.first);
  }

  @override
  Future<Program> register(String id) {
    registerCalls++;
    final error = registerError;
    if (error != null) return Future.error(error);
    final gate = registerGate;
    if (gate != null) return gate.future;
    return Future.value(_program(id, registered: true));
  }
}

void main() {
  late _FakeRepository repo;
  late ProgramStore store;

  setUp(() {
    repo = _FakeRepository();
    store = ProgramStore(repo);
  });

  test('loads the program list: loading -> loaded', () async {
    final seen = <LoadStatus>[];
    store.addListener(() => seen.add(store.listStatus));

    await store.loadPrograms();

    expect(seen, [LoadStatus.loading, LoadStatus.loaded]);
    expect(store.programs.map((p) => p.id), ['1', '2']);
    expect(store.skipped, 1);
  });

  test('a list failure is kept and a retry clears it', () async {
    repo.listError = const ProgramException(
        ProgramFailure.unavailable, 'Unable to load this page.');
    await store.loadPrograms();
    expect(store.listStatus, LoadStatus.error);
    expect(store.listError, 'Unable to load this page.');

    repo.listError = null;
    await store.loadPrograms();
    expect(store.listStatus, LoadStatus.loaded);
    expect(store.listError, isNull, reason: 'error must not stick after retry');
  });

  test('selecting a program already in the list shows it immediately',
      () async {
    await store.loadPrograms();
    repo.fetchGate = Completer<Program>();

    final pending = store.selectProgram('2');

    expect(store.selected?.id, '2');
    expect(store.selectedStatus, LoadStatus.loaded);

    repo.fetchGate!.complete(_program('2'));
    await pending;
    expect(store.selected?.id, '2');
  });

  test('selecting an unknown program loads it, or reports not found', () async {
    final pending = store.selectProgram('1');
    expect(store.selectedStatus, LoadStatus.loading);
    await pending;
    expect(store.selected?.id, '1');

    await store.selectProgram('99');
    expect(store.selectedStatus, LoadStatus.error);
    expect(store.selectedFailure?.kind, ProgramFailure.notFound);
    expect(store.selected, isNull);
  });

  test('a stale response for a previous selection is ignored', () async {
    final slow = Completer<Program>();
    repo.fetchGate = slow;
    final first = store.selectProgram('1');

    repo.fetchGate = null;
    await store.selectProgram('2');
    slow.complete(_program('1'));
    await first;

    expect(store.selected?.id, '2');
  });

  test('registering updates the list and the selected program together',
      () async {
    await store.loadPrograms();
    await store.selectProgram('1');

    await store.register('1');

    expect(store.programById('1')!.isRegistered, isTrue);
    expect(store.selected!.isRegistered, isTrue);
    expect(store.programById('2')!.isRegistered, isFalse);
    expect(store.isRegistering('1'), isFalse);
  });

  test('a second register call while one is running is ignored', () async {
    await store.loadPrograms();
    repo.registerGate = Completer<Program>();

    final first = store.register('1');
    expect(store.isRegistering('1'), isTrue);
    await store.register('1');
    expect(repo.registerCalls, 1);

    repo.registerGate!.complete(_program('1', registered: true));
    await first;
    expect(store.isRegistering('1'), isFalse);
  });

  test('duplicate registration reconciles the list and selected program',
      () async {
    await store.loadPrograms();
    await store.selectProgram('1');
    const duplicate = ProgramException(ProgramFailure.unavailable,
        'You are already registered for this program.',
        code: ProgramErrorCode.alreadyRegistered);
    repo.registerError = duplicate;

    await expectLater(store.register('1'), throwsA(same(duplicate)));

    expect(store.programById('1')!.isRegistered, isTrue);
    expect(store.selected!.isRegistered, isTrue);
    expect(store.isRegistering('1'), isFalse);
    expect(repo.registerCalls, 1);
  });

  test(
      'duplicate registration on a direct detail route reads the existing enrollment',
      () async {
    const duplicate = ProgramException(ProgramFailure.unavailable,
        'You are already registered for this program.',
        code: ProgramErrorCode.alreadyRegistered);
    repo.registerError = duplicate;
    repo.programs = [_program('1', registered: true)];

    await expectLater(store.register('1'), throwsA(same(duplicate)));

    expect(store.lookup('1')!.isRegistered, isTrue);
    expect(repo.fetchCalls, 1);
    expect(repo.registerCalls, 1);
    expect(store.isRegistering('1'), isFalse);
  });

  test('a failed duplicate reconciliation preserves the original error',
      () async {
    const duplicate = ProgramException(ProgramFailure.unavailable,
        'You are already registered for this program.',
        code: ProgramErrorCode.alreadyRegistered);
    repo.registerError = duplicate;
    repo.programs = [];

    await expectLater(store.register('1'), throwsA(same(duplicate)));

    expect(store.lookup('1'), isNull);
    expect(store.isRegistering('1'), isFalse);
    expect(repo.registerCalls, 1);
  });

  test('registration flow: failure shows an error, retry then succeeds',
      () async {
    await store.loadPrograms();
    final flow = SubmissionController();

    repo.registerError = const ProgramException(
        ProgramFailure.unavailable, 'Unable to register. Please try again.');
    expect(await flow.submit((_) => store.register('1')), isFalse);
    expect(flow.status, SubmissionStatus.error);
    expect(flow.message, 'Unable to register. Please try again.');
    expect(store.programById('1')!.isRegistered, isFalse);
    expect(store.isRegistering('1'), isFalse);

    repo.registerError = null;
    expect(await flow.submit((_) => store.register('1')), isTrue);
    expect(flow.status, SubmissionStatus.success);
    expect(flow.message, isNull);
    expect(store.programById('1')!.isRegistered, isTrue);
  });

  test('a quiet refresh keeps the list when the server fails', () async {
    await store.loadPrograms();
    repo.listError = const ProgramException(
        ProgramFailure.unavailable, 'Unable to load this page.');

    await store.loadPrograms(silent: true);

    expect(store.listStatus, LoadStatus.loaded);
    expect(store.listError, isNull);
    expect(store.programs, hasLength(2));
  });

  test('lookup finds a program registered without ever loading the list',
      () async {
    expect(store.lookup('1'), isNull);

    await store.register('1');

    expect(store.lookup('1')!.isRegistered, isTrue);
  });
}
