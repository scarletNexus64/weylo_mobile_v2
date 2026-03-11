import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/chat_service.dart';
import 'package:weylo/app/data/services/message_cache_service.dart';
import 'package:weylo/app/data/services/realtime_service.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';

enum ChatFilter { all, unread, read }

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();
  final MessageCacheService _cacheService = MessageCacheService();
  final AuthService _authService = AuthService();
  RealtimeService? _realtimeService;

  // Canaux WebSocket souscrits
  final List<String> _subscribedChannels = [];

  // États
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final isLoadedFromCache = false.obs;

  // Données
  final conversations = <ConversationModel>[].obs;

  // Pagination
  int currentPage = 1;
  int lastPage = 1;
  final canLoadMore = false.obs;

  // Filtre de messages
  final Rx<ChatFilter> selectedFilter = ChatFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    print('🚀 [ChatController] onInit called - Starting to load conversations...');

    // Nettoyer les caches expirés au démarrage
    _cacheService.cleanExpiredCaches();

    // Initialiser le WebSocket
    _initializeWebSocket();

    loadConversations();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    // Se désabonner de tous les canaux WebSocket
    _unsubscribeFromAllChannels();
    super.onClose();
  }

  /// Initialiser la connexion WebSocket
  void _initializeWebSocket() async {
    try {
      print('🔌 [ChatController] Initializing WebSocket...');

      // Récupérer ou créer le RealtimeService
      if (!Get.isRegistered<RealtimeService>()) {
        Get.put(RealtimeService());
      }
      _realtimeService = Get.find<RealtimeService>();

      print('✅ [ChatController] WebSocket initialized');
    } catch (e) {
      print('❌ [ChatController] Error initializing WebSocket: $e');
    }
  }

  /// S'abonner aux canaux WebSocket des conversations
  Future<void> _subscribeToConversationChannels() async {
    if (_realtimeService == null || conversations.isEmpty) {
      print('⚠️ [ChatController] Cannot subscribe: RealtimeService or conversations not available');
      return;
    }

    try {
      print('🔔 [ChatController] Subscribing to conversation channels...');

      // S'abonner aux 20 premières conversations (les plus actives)
      final conversationsToSubscribe = conversations.take(20).toList();

      for (final conversation in conversationsToSubscribe) {
        final channelName = 'private-conversation.${conversation.id}';

        // Vérifier si on est déjà abonné
        if (_subscribedChannels.contains(channelName)) {
          continue;
        }

        print('📡 [ChatController] Subscribing to $channelName');

        await _realtimeService!.subscribeToPrivateChannel(
          channelName: channelName,
          onEvent: (eventData) => _handleConversationEvent(conversation.id, eventData),
        );

        _subscribedChannels.add(channelName);
      }

      print('✅ [ChatController] Subscribed to ${_subscribedChannels.length} channels');
    } catch (e) {
      print('❌ [ChatController] Error subscribing to channels: $e');
    }
  }

  /// Gérer les événements WebSocket d'une conversation
  void _handleConversationEvent(int conversationId, Map<String, dynamic> eventData) {
    try {
      print('📨 [ChatController] Received event for conversation $conversationId');
      print('📨 [ChatController] Event data: $eventData');

      final event = eventData['_event'] as String?;
      print('🎯 [ChatController] Event type: $event');

      if (event == 'message.sent') {
        // Récupérer l'utilisateur actuel
        final currentUser = _authService.getCurrentUser();
        final senderId = eventData['sender_id'] as int?;

        // Ignorer si c'est notre propre message (déjà ajouté localement)
        if (senderId == currentUser?.id) {
          print('⚠️ [ChatController] Ignoring own message');
          return;
        }

        // Trouver la conversation dans la liste
        final index = conversations.indexWhere((c) => c.id == conversationId);
        if (index == -1) {
          print('⚠️ [ChatController] Conversation $conversationId not found in list');
          return;
        }

        final conversation = conversations[index];

        // Créer un ChatMessageModel depuis les données de l'événement
        final newMessage = ChatMessageModel.fromJson(eventData);

        // Mettre à jour la conversation avec une nouvelle instance
        final updatedConversation = ConversationModel(
          id: conversation.id,
          participantOneId: conversation.participantOneId,
          participantTwoId: conversation.participantTwoId,
          otherParticipant: conversation.otherParticipant,
          lastMessage: newMessage,
          unreadCount: conversation.unreadCount + 1,
          hasPremium: conversation.hasPremium,
          isAnonymous: conversation.isAnonymous,
          identityRevealed: conversation.identityRevealed,
          canInitiateReveal: conversation.canInitiateReveal,
          anonymousMessageId: conversation.anonymousMessageId,
          createdAt: conversation.createdAt,
          updatedAt: conversation.updatedAt,
          lastMessageAt: DateTime.now(),
        );

        // Remplacer la conversation dans la liste
        conversations[index] = updatedConversation;

        // Déplacer la conversation en haut de la liste
        conversations.removeAt(index);
        conversations.insert(0, updatedConversation);

        print('✅ [ChatController] Conversation updated and moved to top');
        print('📊 [ChatController] New unread count: ${updatedConversation.unreadCount}');
      }
    } catch (e) {
      print('❌ [ChatController] Error handling conversation event: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Se désabonner de tous les canaux
  Future<void> _unsubscribeFromAllChannels() async {
    if (_realtimeService == null || _subscribedChannels.isEmpty) {
      return;
    }

    try {
      print('🔕 [ChatController] Unsubscribing from all channels...');

      for (final channelName in _subscribedChannels) {
        await _realtimeService!.unsubscribeFromChannel(channelName);
      }

      _subscribedChannels.clear();
      print('✅ [ChatController] Unsubscribed from all channels');
    } catch (e) {
      print('❌ [ChatController] Error unsubscribing from channels: $e');
    }
  }

  /// Charger les conversations depuis l'API ou le cache
  Future<void> loadConversations({bool refresh = false}) async {
    print('🔄 [ChatController] loadConversations called - refresh: $refresh');

    if (refresh) {
      currentPage = 1;
      conversations.clear();
      isLoadedFromCache.value = false;
      print('🔄 [ChatController] Cleared conversations list');
    }

    if (isLoading.value || isLoadingMore.value) {
      print('⚠️ [ChatController] Already loading, skipping...');
      return;
    }

    // NOUVEAU: Tentative de chargement depuis le cache si pas de refresh
    if (!refresh && _cacheService.isConversationsCacheValid()) {
      final cachedConversations = _cacheService.getConversationsCache();
      if (cachedConversations != null && cachedConversations.isNotEmpty) {
        conversations.value = cachedConversations;
        currentPage = _cacheService.getConversationsCachedPage();
        isLoadedFromCache.value = true;
        print('📦 [ChatController] ✅ Chargé depuis CACHE: ${cachedConversations.length} conversations');

        // S'abonner aux canaux WebSocket après chargement depuis cache
        await _subscribeToConversationChannels();

        return; // Sortir immédiatement, pas besoin d'appeler l'API
      }
    }

    // Si pas de cache valide ou refresh demandé: Fetch depuis API
    refresh ? isLoading.value = true : isLoadingMore.value = true;
    hasError.value = false;
    isLoadedFromCache.value = false;

    try {
      print('📡 [ChatController] Calling ChatService.getConversations (API)...');
      final response = await _chatService.getConversations(
        page: currentPage,
        perPage: 20,
      );

      print('✅ [ChatController] Got ${response.conversations.length} conversations from API');

      if (refresh) {
        conversations.value = response.conversations;
      } else {
        conversations.addAll(response.conversations);
      }

      currentPage = response.meta.currentPage;
      lastPage = response.meta.lastPage;
      canLoadMore.value = response.meta.hasMorePages;

      // NOUVEAU: Sauvegarder dans le cache après fetch API
      await _cacheService.saveConversationsCache(conversations, page: currentPage);

      print('📊 [ChatController] Total conversations: ${conversations.length}');
      print('📊 [ChatController] Current page: $currentPage, Last page: $lastPage');

      // S'abonner aux canaux WebSocket après le premier chargement
      if (currentPage == 1) {
        await _subscribeToConversationChannels();
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ [ChatController] Error loading conversations: $e');

      // NOUVEAU: Mode dégradé - Afficher le cache expiré si disponible
      if (!refresh) {
        final expiredCache = _cacheService.getConversationsCacheExpired();
        if (expiredCache != null && expiredCache.isNotEmpty) {
          conversations.value = expiredCache;
          isLoadedFromCache.value = true;
          print('⚠️ [ChatController] Mode hors ligne: ${expiredCache.length} conversations depuis cache expiré');

          // Toast pour informer l'utilisateur
          Get.snackbar(
            'Mode hors ligne',
            'Affichage des conversations en cache',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      print('✅ [ChatController] Loading completed');
    }
  }

  /// Charger plus de conversations (pagination)
  Future<void> loadMoreConversations() async {
    if (canLoadMore.value && !isLoadingMore.value) {
      currentPage++;
      await loadConversations();
    }
  }

  /// Rafraîchir les conversations (force refresh depuis API)
  Future<void> refreshConversations() async {
    print('🔄 [ChatController] Force refresh - invalidating cache...');
    await _cacheService.invalidateAllConversationsCache();
    await loadConversations(refresh: true);
  }

  /// Changer le filtre
  void setFilter(ChatFilter filter) {
    selectedFilter.value = filter;
  }

  /// Obtenir les conversations filtrées
  List<ConversationModel> get filteredConversations {
    switch (selectedFilter.value) {
      case ChatFilter.all:
        return conversations;
      case ChatFilter.unread:
        return conversations.where((c) => c.unreadCount > 0).toList();
      case ChatFilter.read:
        return conversations.where((c) => c.unreadCount == 0).toList();
    }
  }

  /// Obtenir le nombre de conversations non lues
  int get unreadCount {
    return conversations.where((c) => c.unreadCount > 0).length;
  }

  /// Obtenir le total des messages non lus (somme de tous les unreadCount)
  int get totalUnreadMessagesCount {
    return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  }

  /// Supprimer une conversation
  Future<void> deleteConversation(int conversationId) async {
    // Afficher le loader
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      print('🗑️ [ChatController] Deleting conversation $conversationId');

      // Supprimer via l'API
      await _chatService.deleteConversation(conversationId);

      // Retirer de la liste locale
      conversations.removeWhere((c) => c.id == conversationId);

      // Invalider le cache
      await _cacheService.invalidateAllConversationsCache();

      print('✅ [ChatController] Conversation deleted successfully');

      // Fermer le loader
      Get.back();

      Get.snackbar(
        'Succès',
        'Conversation supprimée',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [ChatController] Error deleting conversation: $e');

      // Fermer le loader
      Get.back();

      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la conversation',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
