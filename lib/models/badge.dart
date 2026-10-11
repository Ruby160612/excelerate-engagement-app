class TalentBadge {
  const TalentBadge({
    required this.id,
    required this.name,
    required this.description,
    this.earnedAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime? earnedAt;

  factory TalentBadge.fromJson(Map<String, dynamic> json) => TalentBadge(
        id: json['id'].toString(),
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        earnedAt: json['earned_at'] == null
            ? null
            : DateTime.parse(json['earned_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'earned_at': earnedAt?.toUtc().toIso8601String(),
      };
}
