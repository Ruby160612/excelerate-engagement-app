enum UserRole { learner, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.learner,
    this.profileCompleted = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool profileCompleted;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        // Only the server can assign an administrator role.
        role: json['role'] == 'admin' ? UserRole.admin : UserRole.learner,
        profileCompleted: json['profile_completed'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'profile_completed': profileCompleted,
      };
}
