import 'story_user_model.dart';

/// Represents a story feed item (grouped by user)
class StoryFeedItemModel {
  final StoryUserModel user;
  final int realUserId; // Always available to load stories
  final bool isAnonymous;
  final bool isOwner;
  final StoryPreviewModel preview;
  final int storiesCount;
  final DateTime latestStoryAt;
  final bool allViewed;
  final bool hasNew;

  StoryFeedItemModel({
    required this.user,
    required this.realUserId,
    required this.isAnonymous,
    required this.isOwner,
    required this.preview,
    required this.storiesCount,
    required this.latestStoryAt,
    required this.allViewed,
    required this.hasNew,
  });

  factory StoryFeedItemModel.fromJson(Map<String, dynamic> json) {
    return StoryFeedItemModel(
      user: StoryUserModel.fromJson(json['user']),
      realUserId: json['real_user_id'],
      isAnonymous: json['is_anonymous'] ?? false,
      isOwner: json['is_owner'] ?? false,
      preview: StoryPreviewModel.fromJson(json['preview']),
      storiesCount: json['stories_count'] ?? 0,
      latestStoryAt: DateTime.parse(json['latest_story_at']),
      allViewed: json['all_viewed'] ?? false,
      hasNew: json['has_new'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'real_user_id': realUserId,
      'is_anonymous': isAnonymous,
      'is_owner': isOwner,
      'preview': preview.toJson(),
      'stories_count': storiesCount,
      'latest_story_at': latestStoryAt.toIso8601String(),
      'all_viewed': allViewed,
      'has_new': hasNew,
    };
  }
}

/// Represents a preview of a story
class StoryPreviewModel {
  final String type; // 'image', 'video', 'text'
  final String? mediaUrl;
  final String? thumbnailUrl; // For video previews
  final String? content;
  final String? backgroundColor;

  StoryPreviewModel({
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    this.content,
    this.backgroundColor,
  });

  factory StoryPreviewModel.fromJson(Map<String, dynamic> json) {
    return StoryPreviewModel(
      type: json['type'],
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      content: json['content'],
      backgroundColor: json['background_color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'content': content,
      'background_color': backgroundColor,
    };
  }

  bool get isImageType => type == 'image';
  bool get isVideoType => type == 'video';
  bool get isTextType => type == 'text';
}
