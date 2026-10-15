class Program {
  const Program({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.schedule,
    this.eligibility = const [],
    this.outcomes = const [],
    required this.category,
    this.imageUrl,
    this.isRegistered = false,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String schedule;
  final List<String> eligibility;
  final List<String> outcomes;
  final String category;
  final String? imageUrl;
  final bool isRegistered;

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'].toString(),
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] == null
            ? null
            : DateTime.parse(json['end_date'] as String),
        schedule: json['schedule'] as String? ?? '',
        eligibility: _stringList(json['eligibility']),
        outcomes: _stringList(json['outcomes']),
        category: json['category'] as String,
        imageUrl: json['image_url'] as String?,
        isRegistered: json['is_registered'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'start_date': startDate.toUtc().toIso8601String(),
        'end_date': endDate?.toUtc().toIso8601String(),
        'schedule': schedule,
        'eligibility': eligibility,
        'outcomes': outcomes,
        'category': category,
        'image_url': imageUrl,
        'is_registered': isRegistered,
      };

  Program copyWith({bool? isRegistered}) => Program(
        id: id,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        schedule: schedule,
        eligibility: eligibility,
        outcomes: outcomes,
        category: category,
        imageUrl: imageUrl,
        isRegistered: isRegistered ?? this.isRegistered,
      );

  static List<String> _stringList(Object? value) =>
      value is List ? value.map((item) => item.toString()).toList() : const [];
}
