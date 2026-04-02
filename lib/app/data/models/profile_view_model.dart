class ProfileViewModel {
  final int id;
  final ProfileViewerModel viewer;
  final DateTime viewedAt;
  final String formattedTime;

  ProfileViewModel({
    required this.id,
    required this.viewer,
    required this.viewedAt,
    required this.formattedTime,
  });

  factory ProfileViewModel.fromJson(Map<String, dynamic> json) {
    return ProfileViewModel(
      id: json['id'] as int,
      viewer: ProfileViewerModel.fromJson(json['viewer'] as Map<String, dynamic>),
      viewedAt: DateTime.parse(json['viewed_at'] as String),
      formattedTime: json['formatted_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'viewer': viewer.toJson(),
      'viewed_at': viewedAt.toIso8601String(),
      'formatted_time': formattedTime,
    };
  }
}

class ProfileViewerModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? avatar;
  final bool isVerified;
  final bool isAnonymous;

  ProfileViewerModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.avatar,
    required this.isVerified,
    this.isAnonymous = false,
  });

  factory ProfileViewerModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String;
    final isAnonymous = firstName == 'Anonyme';

    return ProfileViewerModel(
      id: json['id'] as int?,
      firstName: firstName,
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isAnonymous: isAnonymous,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'avatar': avatar,
      'is_verified': isVerified,
    };
  }

  String get fullName => '$firstName ${lastName}'.trim();

  bool get hasRealAvatar => avatar != null && avatar!.isNotEmpty && !isAnonymous;
}
