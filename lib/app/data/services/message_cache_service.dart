import 'dart:convert';
import 'package:weylo/app/data/services/storage_service.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';

/// Service de cache local pour les conversations et messages
/// Gère le cache persistant avec expiration de 24h
/// Pattern basé sur CacheService (stories/confessions)
class MessageCacheService {
  static final MessageCacheService _instance = MessageCacheService._internal();
  factory MessageCacheService() => _instance;
  MessageCacheService._internal();

  final _storage = StorageService();

  // Cache keys
  static const String _conversationsCacheKey = 'conversations_cache';
  static const String _conversationsTimestampKey = 'conversations_cache_timestamp';
  static const String _conversationsPageKey = 'conversations_cache_page';

  // Messages par conversation: messages_{convId}_cache
  static String _messagesCacheKey(int convId) => 'messages_${convId}_cache';
  static String _messagesTimestampKey(int convId) => 'messages_${convId}_timestamp';
  static String _messagesPageKey(int convId) => 'messages_${convId}_page';

  // Durée de validité du cache: 24 heures
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  // Limites de cache (memory management)
  static const int _maxConversationsInCache = 100;
  static const int _maxMessagesPerConversation = 500;

  /// Vérifie si le cache est encore valide (< 24h)
  bool _isCacheValid(String timestampKey) {
    final timestamp = _storage.read<int>(timestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    final isValid = difference < _cacheValidityDuration;

    if (!isValid) {
      print('⏰ [MESSAGE_CACHE] Cache expiré: ${difference.inHours}h (max: ${_cacheValidityDuration.inHours}h)');
    } else {
      print('✅ [MESSAGE_CACHE] Cache valide: ${difference.inHours}h/${_cacheValidityDuration.inHours}h');
    }

    return isValid;
  }

  // ========== CONVERSATIONS CACHE ==========

  /// Sauvegarde les conversations en cache
  Future<void> saveConversationsCache(List<ConversationModel> conversations, {int page = 1}) async {
    try {
      // Limiter le nombre de conversations en cache
      final limitedConversations = conversations.take(_maxConversationsInCache).toList();

      final jsonList = limitedConversations.map((c) => c.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await _storage.write(_conversationsCacheKey, jsonString);
      await _storage.write(_conversationsTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await _storage.write(_conversationsPageKey, page);

      print('💾 [MESSAGE_CACHE] Conversations sauvegardées: ${limitedConversations.length} items, page $page');
    } catch (e) {
      print('❌ [MESSAGE_CACHE] Erreur sauvegarde conversations: $e');
    }
  }

  /// Récupère les conversations du cache
  List<ConversationModel>? getConversationsCache() {
    try {
      if (!_isCacheValid(_conversationsTimestampKey)) {
        print('⏰ [MESSAGE_CACHE] Cache conversations expiré');
        return null;
      }

      final jsonString = _storage.read<String>(_conversationsCacheKey);
      if (jsonString == null) {
        print('📭 [MESSAGE_CACHE] Aucun cache conversations trouvé');
        return null;
      }

      final jsonList = json.decode(jsonString) as List;
      final conversations = jsonList
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final page = _storage.read<int>(_conversationsPageKey) ?? 1;
      print('📦 [MESSAGE_CACHE] Conversations récupérées du cache: ${conversations.length} items, page $page');

      return conversations;
    } catch (e) {
      print('❌ [MESSAGE_CACHE] Erreur lecture cache conversations: $e');
      return null;
    }
  }

  /// Récupère la page actuelle du cache conversations
  int getConversationsCachedPage() {
    return _storage.read<int>(_conversationsPageKey) ?? 1;
  }

  /// Vérifie si le cache conversations est valide
  bool isConversationsCacheValid() {
    return _isCacheValid(_conversationsTimestampKey);
  }

  /// Supprime le cache des conversations
  Future<void> clearConversationsCache() async {
    await _storage.remove(_conversationsCacheKey);
    await _storage.remove(_conversationsTimestampKey);
    await _storage.remove(_conversationsPageKey);
    print('🗑️ [MESSAGE_CACHE] Cache conversations supprimé');
  }

  // ========== MESSAGES CACHE (par conversation) ==========

  /// Sauvegarde les messages d'une conversation en cache
  Future<void> saveMessagesCache(int convId, List<ChatMessageModel> messages, {int page = 1}) async {
    try {
      // Limiter le nombre de messages en cache
      final limitedMessages = messages.take(_maxMessagesPerConversation).toList();

      final jsonList = limitedMessages.map((m) => m.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await _storage.write(_messagesCacheKey(convId), jsonString);
      await _storage.write(_messagesTimestampKey(convId), DateTime.now().millisecondsSinceEpoch);
      await _storage.write(_messagesPageKey(convId), page);

      print('💾 [MESSAGE_CACHE] Messages conv_$convId sauvegardés: ${limitedMessages.length} items, page $page');
    } catch (e) {
      print('❌ [MESSAGE_CACHE] Erreur sauvegarde messages conv_$convId: $e');
    }
  }

  /// Récupère les messages d'une conversation du cache
  List<ChatMessageModel>? getMessagesCache(int convId) {
    try {
      if (!_isCacheValid(_messagesTimestampKey(convId))) {
        print('⏰ [MESSAGE_CACHE] Cache messages conv_$convId expiré');
        return null;
      }

      final jsonString = _storage.read<String>(_messagesCacheKey(convId));
      if (jsonString == null) {
        print('📭 [MESSAGE_CACHE] Aucun cache messages conv_$convId trouvé');
        return null;
      }

      final jsonList = json.decode(jsonString) as List;
      final messages = jsonList
          .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final page = _storage.read<int>(_messagesPageKey(convId)) ?? 1;
      print('📦 [MESSAGE_CACHE] Messages conv_$convId récupérés du cache: ${messages.length} items, page $page');

      return messages;
    } catch (e) {
      print('❌ [MESSAGE_CACHE] Erreur lecture cache messages conv_$convId: $e');
      return null;
    }
  }

  /// Récupère la page actuelle du cache messages
  int getMessagesCachedPage(int convId) {
    return _storage.read<int>(_messagesPageKey(convId)) ?? 1;
  }

  /// Vérifie si le cache messages est valide
  bool isMessagesCacheValid(int convId) {
    return _isCacheValid(_messagesTimestampKey(convId));
  }

  /// Invalide le cache d'une conversation spécifique
  /// Appelé après nouveau message, édition, suppression
  Future<void> invalidateConversationCache(int convId) async {
    await _storage.remove(_messagesCacheKey(convId));
    await _storage.remove(_messagesTimestampKey(convId));
    await _storage.remove(_messagesPageKey(convId));
    print('🗑️ [MESSAGE_CACHE] Cache messages conv_$convId invalidé');
  }

  /// Invalide également le cache de la liste des conversations
  Future<void> invalidateAllConversationsCache() async {
    await clearConversationsCache();
    print('🗑️ [MESSAGE_CACHE] Cache liste conversations invalidé');
  }

  // ========== NETTOYAGE GÉNÉRAL ==========

  /// Supprime tous les caches (logout/refresh)
  Future<void> invalidateAllCaches() async {
    await clearConversationsCache();
    print('🗑️ [MESSAGE_CACHE] Tous les caches de conversations invalidés');
  }

  /// Nettoie les caches expirés (appelé périodiquement ou au démarrage)
  Future<void> cleanExpiredCaches() async {
    if (!_isCacheValid(_conversationsTimestampKey)) {
      print('🗑️ [MESSAGE_CACHE] Nettoyage du cache conversations expiré');
      await clearConversationsCache();
    }
    print('✅ [MESSAGE_CACHE] Nettoyage des caches expirés terminé');
  }

  /// Mode dégradé: Récupérer le cache même si expiré (en cas d'erreur API)
  List<ConversationModel>? getConversationsCacheExpired() {
    try {
      final jsonString = _storage.read<String>(_conversationsCacheKey);
      if (jsonString == null) {
        print('📭 [MESSAGE_CACHE] Aucun cache conversations trouvé (mode dégradé)');
        return null;
      }

      final jsonList = json.decode(jsonString) as List;
      final conversations = jsonList
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('⚠️ [MESSAGE_CACHE] Mode dégradé: ${conversations.length} conversations récupérées (cache expiré)');
      return conversations;
    } catch (e) {
      print('❌ [MESSAGE_CACHE] Erreur mode dégradé: $e');
      return null;
    }
  }

  /// Mode dégradé: Récupérer les messages même si expiré (en cas d'erreur API)
  List<ChatMessageModel>? getMessagesCacheExpired(int convId) {
    try {
      final jsonString = _storage.read<String>(_messagesCacheKey(convId));
      if (jsonString == null) {
        print('📭 [MESSAGE_CACHE] Aucun cache messages conv_$convId trouvé (mode dégradé)');
        return null;
      }

      final jsonList = json.decode(jsonString) as List;
      final messages = jsonList
          .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('⚠️ [MESSAGE_CACHE] Mode dégradé: ${messages.length} messages conv_$convId récupérés (cache expiré)');
      return messages;
    } catch (e) {
      print('❌ [MESSAGE_CACHE] Erreur mode dégradé: $e');
      return null;
    }
  }
}
