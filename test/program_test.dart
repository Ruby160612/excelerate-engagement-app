import 'package:excelerate_talent_hub/models/program.dart';
import 'package:excelerate_talent_hub/services/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every sample program survives a JSON round trip', () {
    for (final json in mockPrograms) {
      final program = Program.fromJson(json);
      final copy = Program.fromJson(program.toJson());
      expect(copy.id, program.id);
      expect(copy.title, program.title);
      expect(copy.startDate, program.startDate);
      expect(copy.endDate, program.endDate);
      expect(copy.eligibility, program.eligibility);
      expect(copy.outcomes, program.outcomes);
      expect(copy.category, program.category);
      expect(copy.isRegistered, program.isRegistered);
    }
  });

  test('optional fields fall back to safe defaults', () {
    final program = Program.fromJson({
      'id': 7,
      'title': 'Minimal',
      'start_date': '2026-11-01T09:00:00Z',
      'category': 'workshop',
    });
    expect(program.id, '7');
    expect(program.description, '');
    expect(program.schedule, '');
    expect(program.endDate, isNull);
    expect(program.imageUrl, isNull);
    expect(program.eligibility, isEmpty);
    expect(program.outcomes, isEmpty);
    expect(program.isRegistered, isFalse);
  });

  test('copyWith changes only the registration state', () {
    final program = Program.fromJson(mockPrograms.first);
    final registered = program.copyWith(isRegistered: true);
    expect(registered.isRegistered, isTrue);
    expect(registered.title, program.title);
    expect(program.isRegistered, isFalse);
  });

  test('sample data is complete, unique and starts after 15 October 2026', () {
    final programs = mockPrograms.map(Program.fromJson).toList();
    expect(programs.map((p) => p.id).toSet().length, programs.length);
    expect(
      programs.map((p) => p.category).toSet(),
      {'course', 'workshop', 'webinar', 'internship'},
    );
    final cutoff = DateTime.utc(2026, 10, 15);
    for (final program in programs) {
      expect(program.startDate.isAfter(cutoff), isTrue, reason: program.id);
      expect(program.description, isNotEmpty, reason: program.id);
      expect(program.schedule, isNotEmpty, reason: program.id);
      expect(program.eligibility, isNotEmpty, reason: program.id);
      expect(program.outcomes, isNotEmpty, reason: program.id);
      final end = program.endDate;
      if (end != null) {
        expect(end.isBefore(program.startDate), isFalse, reason: program.id);
      }
    }
  });
}
