import 'dart:io';
import 'package:dio/dio.dart';
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

  /// Send a message to a user (with support for audio, image, gift)
  Future<SendMessageResponse> sendMessage({
    required String username,
    String? content,
    int? replyToMessageId,
    File? mediaFile,
    String? mediaType, // 'audio' or 'image'
    String? voiceType, // 'normal', 'robot', 'alien', 'mystery', 'chipmunk'
    int? giftId,
    String? giftMessage,
    bool? revealIdentityWithGift,
  }) async {
    try {
      // Si on a un fichier média ou un gift, utiliser FormData
      if (mediaFile != null || giftId != null) {
        final formData = FormData();

        // Ajouter les champs texte
        if (content != null && content.isNotEmpty) {
          formData.fields.add(MapEntry('content', content));
        }
        if (replyToMessageId != null) {
          formData.fields.add(MapEntry('reply_to_message_id', replyToMessageId.toString()));
        }

        // Gestion du média (audio ou image)
        if (mediaFile != null && mediaType != null) {
          // Utiliser fromBytes pour éviter les problèmes de taille de fichier
          final bytes = await mediaFile.readAsBytes();
          formData.files.add(MapEntry(
            'media',
            MultipartFile.fromBytes(
              bytes,
              filename: mediaFile.path.split('/').last,
            ),
          ));
          formData.fields.add(MapEntry('media_type', mediaType));

          // Ajouter le type de voix si spécifié pour audio
          if (mediaType == 'audio' && voiceType != null) {
            formData.fields.add(MapEntry('voice_type', voiceType));
          }
        }

        // Gestion du cadeau
        if (giftId != null) {
          formData.fields.add(MapEntry('gift_id', giftId.toString()));
          if (giftMessage != null && giftMessage.isNotEmpty) {
            formData.fields.add(MapEntry('gift_message', giftMessage));
          }
          if (revealIdentityWithGift != null) {
            formData.fields.add(MapEntry('reveal_identity_with_gift', revealIdentityWithGift ? '1' : '0'));
          }
        }

        final response = await _api.post(
          ApiConfig.sendMessage(username),
          data: formData,
        );

        return SendMessageResponse.fromJson(response.data);
      } else {
        // Sinon, utiliser JSON classique (texte uniquement)
        final data = {
          'content': content ?? '',
          if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
        };

        final response = await _api.post(
          ApiConfig.sendMessage(username),
          data: data,
        );

        return SendMessageResponse.fromJson(response.data);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reply to an anonymous message (without needing the sender's username)
  /// This method is specifically for replying to anonymous messages
  Future<SendMessageResponse> sendReply({
    required int replyToMessageId,
    String? content,
    File? mediaFile,
    String? mediaType, // 'audio' or 'image'
    String? voiceType, // 'normal', 'robot', 'alien', 'mystery', 'chipmunk'
    int? giftId,
    String? giftMessage,
    bool? revealIdentity, // Révéler l'identité avec ce message
  }) async {
    try {
      // Si on a un fichier média ou un gift, utiliser FormData
      if (mediaFile != null || giftId != null) {
        final formData = FormData();

        // Ajouter les champs texte
        if (content != null && content.isNotEmpty) {
          formData.fields.add(MapEntry('content', content));
        }
        formData.fields.add(MapEntry('reply_to_message_id', replyToMessageId.toString()));

        // Gestion du média (audio ou image)
        if (mediaFile != null && mediaType != null) {
          // Utiliser fromBytes pour éviter les problèmes de taille de fichier
          final bytes = await mediaFile.readAsBytes();
          formData.files.add(MapEntry(
            'media',
            MultipartFile.fromBytes(
              bytes,
              filename: mediaFile.path.split('/').last,
            ),
          ));
          formData.fields.add(MapEntry('media_type', mediaType));

          // Ajouter le type de voix si spécifié pour audio
          if (mediaType == 'audio' && voiceType != null) {
            formData.fields.add(MapEntry('voice_type', voiceType));
          }
        }

        // Gestion du cadeau
        if (giftId != null) {
          formData.fields.add(MapEntry('gift_id', giftId.toString()));
          if (giftMessage != null && giftMessage.isNotEmpty) {
            formData.fields.add(MapEntry('gift_message', giftMessage));
          }
        }

        // Révélation d'identité (pour cadeau ou non)
        if (revealIdentity != null && revealIdentity) {
          formData.fields.add(MapEntry('reveal_identity', '1'));
          // Ajouter aussi reveal_identity_with_gift pour compatibilité avec les cadeaux
          if (giftId != null) {
            formData.fields.add(MapEntry('reveal_identity_with_gift', '1'));
          }
        }

        final response = await _api.post(
          ApiConfig.sendReply,
          data: formData,
        );

        return SendMessageResponse.fromJson(response.data);
      } else {
        // Sinon, utiliser JSON classique (texte uniquement)
        final data = {
          'content': content ?? '',
          'reply_to_message_id': replyToMessageId,
          if (revealIdentity != null && revealIdentity) 'reveal_identity': 1,
        };

        final response = await _api.post(
          ApiConfig.sendReply,
          data: data,
        );

        return SendMessageResponse.fromJson(response.data);
      }
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

/// Response for sending a message
class SendMessageResponse {
  final AnonymousMessageModel message;
  final int? conversationId; // ID de la conversation créée si c'est une réponse

  SendMessageResponse({
    required this.message,
    this.conversationId,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      message: AnonymousMessageModel.fromJson(json['data']),
      conversationId: json['conversation_id'],
    );
  }
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
