class Profile {
  const Profile({
    required this.userId,
    required this.headline,
    required this.bio,
    required this.skills,
    this.cvUrl,
  });

  final String userId;
  final String headline;
  final String bio;
  final List<String> skills;
  final String? cvUrl;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: json['user_id'].toString(),
        headline: json['headline'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        skills: List<String>.from(json['skills'] as List? ?? const []),
        cvUrl: json['cv_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'headline': headline,
        'bio': bio,
        'skills': skills,
        'cv_url': cvUrl,
      };
}
