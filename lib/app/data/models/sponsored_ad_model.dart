class SponsoredAdModel {
  final int id;
  final String mediaType; // text|image|video
  final String? textContent;
  final String? mediaUrl;
  final int ownerId;
  final String ownerUsername;
  final String ownerFullName;
  final String? ownerAvatarUrl;
  final DateTime? endsAt;
  final int deliveredCount;
  final int targetReach;

  SponsoredAdModel({
    required this.id,
    required this.mediaType,
    required this.textContent,
    required this.mediaUrl,
    required this.ownerId,
    required this.ownerUsername,
    required this.ownerFullName,
    required this.ownerAvatarUrl,
    required this.endsAt,
    required this.deliveredCount,
    required this.targetReach,
  });

  factory SponsoredAdModel.fromJson(Map<String, dynamic> json) {
    final owner = (json['owner'] as Map<String, dynamic>?) ?? {};
    return SponsoredAdModel(
      id: json['id'] ?? 0,
      mediaType: json['media_type'] ?? 'text',
      textContent: json['text_content'],
      mediaUrl: json['media_url'],
      ownerId: owner['id'] ?? (json['user_id'] ?? 0),
      ownerUsername: owner['username'] ?? '',
      ownerFullName: owner['full_name'] ?? owner['first_name'] ?? '',
      ownerAvatarUrl: owner['avatar_url'],
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'] as String)
          : null,
      deliveredCount: (json['delivered_count'] ?? 0) as int,
      targetReach: (json['target_reach'] ?? 0) as int,
    );
  }
}
