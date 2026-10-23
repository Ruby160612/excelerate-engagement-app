enum ProgramRegistrationStatus { registered, cancelled }

/// A registration read from the backend, never a client-authored write request.
class ProgramRegistration {
  const ProgramRegistration({
    required this.id,
    required this.programId,
    required this.learnerId,
    required this.status,
    required this.registeredAt,
  });

  final String id;
  final String programId;
  final String learnerId;
  final ProgramRegistrationStatus status;
  final DateTime registeredAt;

  factory ProgramRegistration.fromJson(Map<String, dynamic> json) =>
      ProgramRegistration(
        id: _stringId(json['id']),
        programId: _stringId(json['programId']),
        learnerId: _stringId(json['learnerId']),
        status: _status(json['status']),
        registeredAt: DateTime.parse(json['registeredAt'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'programId': programId,
        'learnerId': learnerId,
        'status': status.name,
        'registeredAt': registeredAt.toUtc().toIso8601String(),
      };

  static ProgramRegistrationStatus _status(Object? value) =>
      ProgramRegistrationStatus.values
          .where((status) => status.name == value)
          .firstOrNull ??
      (throw const FormatException('Unknown program registration status.'));

  static String _stringId(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw const FormatException('Registration IDs must be non-empty strings.');
  }
}
