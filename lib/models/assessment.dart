class Assessment {
  const Assessment({
    required this.id,
    required this.title,
    required this.durationMinutes,
    this.completed = false,
    this.score,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final bool completed;
  final double? score;

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        id: json['id'].toString(),
        title: json['title'] as String,
        durationMinutes: (json['duration_minutes'] as num).toInt(),
        completed: json['completed'] == true,
        score: (json['score'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration_minutes': durationMinutes,
        'completed': completed,
        'score': score,
      };
}
