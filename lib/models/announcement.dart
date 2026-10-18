import 'user.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.audience = 'all',
  });

  final String id;
  final String title;
  final String body;
  final DateTime publishedAt;
  final String audience;

  bool isVisibleTo(UserRole role) => audience == 'all' || audience == role.name;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'].toString(),
        title: json['title'] as String,
        body: json['body'] as String,
        publishedAt: DateTime.parse(json['published_at'] as String),
        audience: json['audience'] as String? ?? 'all',
      );
}
