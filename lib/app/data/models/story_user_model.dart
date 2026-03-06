class StoryUserModel {
  final int? id;
  final String username;
  final String fullName;
  final String avatarUrl;

  StoryUserModel({
    this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
  });

  factory StoryUserModel.fromJson(Map<String, dynamic> json) {
    // Clean avatar URL - fix malformed ui-avatars URLs
    String avatarUrl = json['avatar_url'] ?? '';

    // If avatar URL is empty or malformed, generate a proper one
    if (avatarUrl.isEmpty || avatarUrl.contains('name=+') || avatarUrl.contains('name= ')) {
      final name = (json['username'] ?? 'User').replaceAll(' ', '+');
      avatarUrl = 'https://ui-avatars.com/api/?name=$name&background=667eea&color=fff&bold=true';
    }

    return StoryUserModel(
      id: json['id'],
      username: json['username'] ?? 'Anonyme',
      fullName: json['full_name'] ?? 'Utilisateur Anonyme',
      avatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }

  bool get isAnonymous => id == null;
}
