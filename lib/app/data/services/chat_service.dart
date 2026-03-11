import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import 'message_cache_service.dart';

class ChatService {
  final _api = ApiService();
  final _cacheService = MessageCacheService();

  /// Get conversations with pagination
  Future<ConversationListResponse> getConversations({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      print('🔄 [ChatService] Fetching conversations - page: $page, perPage: $perPage');

      final response = await _api.get(
        ApiConfig.conversations,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      print('✅ [ChatService] Got response: ${response.statusCode}');

      final data = response.data;
      print('📦 [ChatService] Response data keys: ${data.keys}');
      print('📦 [ChatService] Conversations count: ${(data['conversations'] as List).length}');

      final conversations = (data['conversations'] as List)
          .map((json) {
            try {
              return ConversationModel.fromJson(json);
            } catch (e) {
              print('❌ [ChatService] Error parsing conversation: $e');
              print('📄 [ChatService] Conversation JSON: $json');
              rethrow;
            }
          })
          .toList();

      final meta = ConversationPaginationMeta.fromJson(data['meta']);

      print('✅ [ChatService] Successfully parsed ${conversations.length} conversations');

      return ConversationListResponse(
        conversations: conversations,
        meta: meta,
      );
    } catch (e) {
      print('❌ [ChatService] Error loading conversations: $e');
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

  /// Send a message in a conversation
  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    String? content,
    String type = 'text',
    File? audioFile,
    File? imageFile,
    File? videoFile,
    String? voiceType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Si on a un fichier, utiliser multipart/form-data
      if (audioFile != null || imageFile != null || videoFile != null) {
        final formData = FormData();

        // Ajouter les champs texte
        if (content != null && content.isNotEmpty) {
          formData.fields.add(MapEntry('content', content));
        }
        formData.fields.add(MapEntry('type', type));

        // Ajouter le voice_type si fourni
        if (voiceType != null && voiceType.isNotEmpty) {
          formData.fields.add(MapEntry('voice_type', voiceType));
        }

        // Ajouter les metadata si fournis
        if (metadata != null) {
          // FormData nécessite des strings, donc encoder en JSON
          formData.fields.add(MapEntry('metadata', jsonEncode(metadata)));
        }

        // Ajouter le fichier
        if (audioFile != null) {
          formData.files.add(MapEntry(
            'media',
            await MultipartFile.fromFile(
              audioFile.path,
              filename: audioFile.path.split('/').last,
            ),
          ));
        } else if (imageFile != null) {
          formData.files.add(MapEntry(
            'media',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ));
        } else if (videoFile != null) {
          formData.files.add(MapEntry(
            'media',
            await MultipartFile.fromFile(
              videoFile.path,
              filename: videoFile.path.split('/').last,
            ),
          ));
        }

        final response = await _api.post(
          '${ApiConfig.conversations}/$conversationId/messages',
          data: formData,
        );

        return ChatMessageModel.fromJson(response.data['message']);
      } else {
        // Sinon, utiliser JSON classique
        final response = await _api.post(
          '${ApiConfig.conversations}/$conversationId/messages',
          data: {
            'content': content,
            'type': type,
            if (metadata != null) 'metadata': metadata,
          },
        );

        return ChatMessageModel.fromJson(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update/Edit a message
  Future<ChatMessageModel> updateMessage({
    required int conversationId,
    required int messageId,
    required String content,
  }) async {
    try {
      print('✏️ [ChatService] Updating message $messageId in conversation $conversationId');

      final response = await _api.patch(
        '${ApiConfig.conversations}/$conversationId/messages/$messageId',
        data: {'content': content},
      );

      print('✅ [ChatService] Message updated successfully');
      return ChatMessageModel.fromJson(response.data['message']);
    } catch (e) {
      print('❌ [ChatService] Error updating message: $e');
      rethrow;
    }
  }

  /// Delete a message
  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
  }) async {
    try {
      print('🗑️ [ChatService] Deleting message $messageId from conversation $conversationId');

      await _api.delete(
        '${ApiConfig.conversations}/$conversationId/messages/$messageId',
      );

      print('✅ [ChatService] Message deleted successfully');
    } catch (e) {
      print('❌ [ChatService] Error deleting message: $e');
      rethrow;
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(int conversationId) async {
    try {
      print('⌨️ [ChatService] Sending typing indicator for conversation $conversationId');

      await _api.post('${ApiConfig.conversations}/$conversationId/typing');

      print('✅ [ChatService] Typing indicator sent');
    } catch (e) {
      // Fail silently - typing indicator n'est pas critique
      print('⚠️ [ChatService] Typing indicator failed (non-critical): $e');
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(int conversationId) async {
    try {
      print('🗑️ [ChatService] Deleting conversation $conversationId');

      await _api.delete('${ApiConfig.conversations}/$conversationId');

      // Invalider le cache des messages de cette conversation
      await _cacheService.invalidateConversationCache(conversationId);

      // Invalider aussi le cache de la liste des conversations
      await _cacheService.invalidateAllConversationsCache();

      print('✅ [ChatService] Conversation deleted and cache invalidated');
    } catch (e) {
      print('❌ [ChatService] Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Get total unread message count across all conversations
  Future<int> getTotalUnreadCount() async {
    try {
      print('📊 [ChatService] Fetching total unread count');

      final response = await _api.get('/chat/unread-count');

      print('✅ [ChatService] Total unread count: ${response.data['total_unread_count']}');

      return response.data['total_unread_count'] ?? 0;
    } catch (e) {
      print('❌ [ChatService] Error fetching total unread count: $e');
      return 0; // Return 0 on error instead of throwing
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
