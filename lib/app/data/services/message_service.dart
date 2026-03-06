import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/anonymous_message_model.dart';

class MessageService {
  final _api = ApiService();

  /// Get received anonymous messages with pagination
  Future<MessageListResponse> getReceivedMessages({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.messages,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final data = response.data;
      final messages = (data['messages'] as List)
          .map((json) => AnonymousMessageModel.fromJson(json))
          .toList();

      final meta = MessagePaginationMeta.fromJson(data['meta']);

      return MessageListResponse(messages: messages, meta: meta);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's share link
  Future<UserShareLink> getUserShareLink() async {
    try {
      final response = await _api.get(ApiConfig.shareLink);
      return UserShareLink.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get sent messages
  Future<MessageListResponse> getSentMessages({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.sentMessages,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final data = response.data;
      final messages = (data['messages'] as List)
          .map((json) => AnonymousMessageModel.fromJson(json))
          .toList();

      final meta = MessagePaginationMeta.fromJson(data['meta']);

      return MessageListResponse(messages: messages, meta: meta);
    } catch (e) {
      rethrow;
    }
  }

  /// Send a message to a user
  Future<AnonymousMessageModel> sendMessage({
    required String username,
    required String content,
    int? replyToMessageId,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.sendMessage(username),
        data: {
          'content': content,
          'reply_to_message_id': replyToMessageId,
        },
      );

      return AnonymousMessageModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      await _api.delete('${ApiConfig.messages}/$messageId');
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<AnonymousMessageModel> markAsRead(int messageId) async {
    try {
      final response = await _api.get('${ApiConfig.messages}/$messageId');
      return AnonymousMessageModel.fromJson(response.data['message']);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all messages as read
  Future<void> markAllAsRead() async {
    try {
      await _api.post('${ApiConfig.messages}/read-all');
    } catch (e) {
      rethrow;
    }
  }

  /// Get message statistics
  Future<MessageStats> getMessageStats() async {
    try {
      final response = await _api.get(ApiConfig.messageStats);
      return MessageStats.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

/// Response wrapper for message list with pagination
class MessageListResponse {
  final List<AnonymousMessageModel> messages;
  final MessagePaginationMeta meta;

  MessageListResponse({
    required this.messages,
    required this.meta,
  });
}

/// Message statistics
class MessageStats {
  final int receivedCount;
  final int sentCount;
  final int unreadCount;
  final int revealedCount;

  MessageStats({
    required this.receivedCount,
    required this.sentCount,
    required this.unreadCount,
    required this.revealedCount,
  });

  factory MessageStats.fromJson(Map<String, dynamic> json) {
    return MessageStats(
      receivedCount: json['received_count'] ?? 0,
      sentCount: json['sent_count'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      revealedCount: json['revealed_count'] ?? 0,
    );
  }
}
