import 'program.dart';
import 'program_registration.dart';

class ProgramListResponse {
  ProgramListResponse(List<Program> programs, {this.skipped = 0})
      : programs = List.unmodifiable(programs);

  final List<Program> programs;
  final int skipped;

  factory ProgramListResponse.fromJson(Map<String, dynamic> json) {
    final skipped = json['skipped'] ?? 0;
    if (skipped is! int || skipped < 0) {
      throw const FormatException('Invalid skipped-record count.');
    }
    final parsed = ProgramListResponse.fromLegacyJson(json['items']);
    return ProgramListResponse(parsed.programs,
        skipped: skipped + parsed.skipped);
  }

  /// The existing HTTP endpoint returns a bare array. Bad records remain counted.
  factory ProgramListResponse.fromLegacyJson(Object? data) {
    if (data is! List) throw const FormatException('Expected a program list.');
    final programs = <Program>[];
    var skipped = 0;
    for (final item in data) {
      try {
        if (item is! Map) throw const FormatException('Expected a program.');
        programs.add(Program.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        skipped++;
      }
    }
    return ProgramListResponse(programs, skipped: skipped);
  }

  Map<String, dynamic> toJson() => {
        'items': [for (final program in programs) program.toJson()],
        'skipped': skipped,
      };
}

class ProgramDetailResponse {
  const ProgramDetailResponse(this.program);

  final Program program;

  factory ProgramDetailResponse.fromJson(Map<String, dynamic> json) =>
      ProgramDetailResponse(
          Program.fromJson(Map<String, dynamic>.from(json['program'] as Map)));

  Map<String, dynamic> toJson() => {'program': program.toJson()};
}

class ProgramRegistrationResponse {
  const ProgramRegistrationResponse(this.program, {this.registration});

  final Program program;

  /// Older HTTP backends return only the updated program. Never invent metadata.
  final ProgramRegistration? registration;

  factory ProgramRegistrationResponse.fromJson(Map<String, dynamic> json) {
    final program = ProgramDetailResponse.fromJson(json).program;
    final data = json['registration'];
    final registration = data == null
        ? null
        : ProgramRegistration.fromJson(Map<String, dynamic>.from(data as Map));
    if (!program.isRegistered ||
        (registration != null &&
            (registration.programId != program.id ||
                registration.status != ProgramRegistrationStatus.registered))) {
      throw const FormatException('Inconsistent registration response.');
    }
    return ProgramRegistrationResponse(program, registration: registration);
  }

  Map<String, dynamic> toJson() => {
        'program': program.toJson(),
        if (registration != null) 'registration': registration!.toJson(),
      };
}
