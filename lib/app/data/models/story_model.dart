import 'story_user_model.dart';

class StoryModel {
  final int id;
  final StoryUserModel user;
  final bool isAnonymous;
  final bool isOwner;
  final bool canReveal;
  final String type; // 'image', 'video', 'text'
  final String? mediaUrl;
  final String? content;
  final String? thumbnailUrl;
  final String? backgroundColor;
  final int duration; // in seconds
  final int viewsCount;
  final String status; // 'active', 'expired'
  final bool isExpired;
  final bool isActive;
  final int timeRemaining; // in seconds
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool? isViewed;

  // Optional viewers info (only for owner)
  final dynamic viewers;
  final int? viewersCount;
  final bool? hasViewerSubscription;

  StoryModel({
    required this.id,
    required this.user,
    required this.isAnonymous,
    required this.isOwner,
    required this.canReveal,
    required this.type,
    this.mediaUrl,
    this.content,
    this.thumbnailUrl,
    this.backgroundColor,
    required this.duration,
    required this.viewsCount,
    required this.status,
    required this.isExpired,
    required this.isActive,
    required this.timeRemaining,
    required this.expiresAt,
    required this.createdAt,
    this.isViewed,
    this.viewers,
    this.viewersCount,
    this.hasViewerSubscription,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      user: StoryUserModel.fromJson(json['user']),
      isAnonymous: json['is_anonymous'] ?? false,
      isOwner: json['is_owner'] ?? false,
      canReveal: json['can_reveal'] ?? false,
      type: json['type'],
      mediaUrl: json['media_url'],
      content: json['content'],
      thumbnailUrl: json['thumbnail_url'],
      backgroundColor: json['background_color'],
      duration: json['duration'] ?? 5,
      viewsCount: json['views_count'] ?? 0,
      status: json['status'] ?? 'active',
      isExpired: json['is_expired'] ?? false,
      isActive: json['is_active'] ?? true,
      timeRemaining: json['time_remaining'] ?? 0,
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      isViewed: json['is_viewed'],
      viewers: json['viewers'],
      viewersCount: json['viewers_count'],
      hasViewerSubscription: json['has_viewer_subscription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'is_anonymous': isAnonymous,
      'is_owner': isOwner,
      'can_reveal': canReveal,
      'type': type,
      'media_url': mediaUrl,
      'content': content,
      'thumbnail_url': thumbnailUrl,
      'background_color': backgroundColor,
      'duration': duration,
      'views_count': viewsCount,
      'status': status,
      'is_expired': isExpired,
      'is_active': isActive,
      'time_remaining': timeRemaining,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_viewed': isViewed,
      'viewers': viewers,
      'viewers_count': viewersCount,
      'has_viewer_subscription': hasViewerSubscription,
    };
  }

  bool get isImageType => type == 'image';
  bool get isVideoType => type == 'video';
  bool get isTextType => type == 'text';

  String get displayBackgroundColor => backgroundColor ?? '#6366f1';
}
