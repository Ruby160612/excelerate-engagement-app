import 'dart:async';

import 'package:excelerate_talent_hub/state/submission_controller.dart';
import 'package:flutter_test/flutter_test.dart';

String? _required(String value) =>
    value.trim().isEmpty ? 'This field is required' : null;

SubmissionController _form() => SubmissionController(
      validators: {'name': _required, 'email': _required},
    );

void main() {
  test('starts idle with empty values', () {
    final form = _form();
    expect(form.status, SubmissionStatus.idle);
    expect(form.valueOf('name'), '');
    expect(form.message, isNull);
    expect(form.canSubmit, isTrue);
  });

  test('success path: idle -> validating -> submitting -> success', () async {
    final form = _form()
      ..setValue('name', 'Ama')
      ..setValue('email', 'ama@example.com');
    final seen = <SubmissionStatus>[];
    form.addListener(() => seen.add(form.status));

    final ok = await form.submit((_) async {});

    expect(ok, isTrue);
    expect(seen, [
      SubmissionStatus.validating,
      SubmissionStatus.submitting,
      SubmissionStatus.success,
    ]);
    expect(form.isSuccess, isTrue);
    expect(form.message, isNull);
  });

  test('validation failure: idle -> validating -> error, action not run',
      () async {
    final form = _form()..setValue('name', 'Ama');
    var ran = false;

    final ok = await form.submit((_) async => ran = true);

    expect(ok, isFalse);
    expect(ran, isFalse);
    expect(form.status, SubmissionStatus.error);
    expect(form.errorOf('email'), 'This field is required');
    expect(form.errorOf('name'), isNull);
    expect(form.message, 'Please fix the highlighted fields.');
  });

  test('editing a field clears its error and the stuck error state', () async {
    final form = _form();
    await form.submit((_) async {});
    expect(form.status, SubmissionStatus.error);

    form.setValue('email', 'ama@example.com');

    expect(form.errorOf('email'), isNull);
    expect(form.status, SubmissionStatus.idle);
    expect(form.message, isNull);
  });

  test('request failure shows the message, and a retry can succeed', () async {
    final form = _form()
      ..setValue('name', 'Ama')
      ..setValue('email', 'ama@example.com');

    final failed = await form.submit((_) async => throw Exception('Offline'));
    expect(failed, isFalse);
    expect(form.status, SubmissionStatus.error);
    expect(form.message, contains('Offline'));

    final retried = await form.submit((_) async {});
    expect(retried, isTrue);
    expect(form.status, SubmissionStatus.success);
    expect(form.message, isNull, reason: 'the old error must not linger');
  });

  test('repeated taps while submitting send only one request', () async {
    final form = _form()
      ..setValue('name', 'Ama')
      ..setValue('email', 'ama@example.com');
    final gate = Completer<void>();
    var calls = 0;

    final first = form.submit((_) {
      calls++;
      return gate.future;
    });
    final second = await form.submit((_) async => calls++);

    expect(second, isFalse);
    expect(form.isSubmitting, isTrue);
    expect(form.canSubmit, isFalse);

    gate.complete();
    expect(await first, isTrue);
    expect(calls, 1);
  });

  test('submitting again after success is ignored until reset', () async {
    final form = _form()
      ..setValue('name', 'Ama')
      ..setValue('email', 'ama@example.com');
    var calls = 0;
    await form.submit((_) async => calls++);

    expect(await form.submit((_) async => calls++), isFalse);
    expect(calls, 1);

    form.reset();
    expect(form.status, SubmissionStatus.idle);
    expect(form.valueOf('name'), '');
    expect(form.canSubmit, isTrue);
  });

  test('reset(keepValues: true) clears errors but keeps what was typed',
      () async {
    final form = _form()..setValue('name', 'Ama');
    await form.submit((_) async {});
    form.reset(keepValues: true);

    expect(form.valueOf('name'), 'Ama');
    expect(form.fieldErrors, isEmpty);
    expect(form.status, SubmissionStatus.idle);
  });

  test('values cannot change while a request is running', () async {
    final form = _form()
      ..setValue('name', 'Ama')
      ..setValue('email', 'ama@example.com');
    final gate = Completer<void>();
    final pending = form.submit((_) => gate.future);

    form.setValue('name', 'Changed');
    expect(form.valueOf('name'), 'Ama');

    gate.complete();
    await pending;
  });

  test('does not notify after dispose', () async {
    final form = _form()
      ..setValue('name', 'Ama')
      ..setValue('email', 'ama@example.com');
    final gate = Completer<void>();
    final pending = form.submit((_) => gate.future);
    form.dispose();
    gate.complete();
    await pending; // would throw if it tried to notify a disposed notifier
  });
}
