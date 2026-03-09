import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final _api = ApiService();

  /// Get conversations with pagination
  Future<ConversationListResponse> getConversations({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.conversations,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final data = response.data;
      final conversations = (data['conversations'] as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      final meta = ConversationPaginationMeta.fromJson(data['meta']);

      return ConversationListResponse(
        conversations: conversations,
        meta: meta,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages for a specific conversation with pagination
  Future<ChatMessageListResponse> getMessages({
    required int conversationId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _api.get(
        '${ApiConfig.conversations}/$conversationId/messages',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final data = response.data;
      final messages = (data['messages'] as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();

      final meta = ChatMessagePaginationMeta.fromJson(data['meta']);

      return ChatMessageListResponse(
        messages: messages,
        meta: meta,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get conversation details
  Future<ConversationModel> getConversation(int conversationId) async {
    try {
      final response = await _api.get(
        '${ApiConfig.conversations}/$conversationId',
      );

      return ConversationModel.fromJson(response.data['conversation']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get chat statistics
  Future<ChatStats> getChatStats() async {
    try {
      final response = await _api.get(ApiConfig.chatStats);
      return ChatStats.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(int conversationId) async {
    try {
      await _api.post('${ApiConfig.conversations}/$conversationId/read');
    } catch (e) {
      rethrow;
    }
  }
}

/// Response wrapper for conversation list with pagination
class ConversationListResponse {
  final List<ConversationModel> conversations;
  final ConversationPaginationMeta meta;

  ConversationListResponse({
    required this.conversations,
    required this.meta,
  });
}

/// Response wrapper for message list with pagination
class ChatMessageListResponse {
  final List<ChatMessageModel> messages;
  final ChatMessagePaginationMeta meta;

  ChatMessageListResponse({
    required this.messages,
    required this.meta,
  });
}

/// Chat statistics
class ChatStats {
  final int totalConversations;
  final int unreadConversations;
  final int totalMessages;

  ChatStats({
    required this.totalConversations,
    required this.unreadConversations,
    required this.totalMessages,
  });

  factory ChatStats.fromJson(Map<String, dynamic> json) {
    return ChatStats(
      totalConversations: json['total_conversations'] ?? 0,
      unreadConversations: json['unread_conversations'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
    );
  }
}
