import '../app_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
    this.score = 0,
    this.title = 'Rookie',
  });

  final String id;
  final String username;
  final String displayName;
  final AppRole role;
  final bool isActive;
  final int score;
  final String title;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ??
          (json['username'] as String?) ??
          '',
      role: (json['role'] as String?) == 'admin' ? AppRole.admin : AppRole.agent,
      isActive: (json['is_active'] as bool?) ?? true,
      score: (json['score'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Rookie',
    );
  }
}
