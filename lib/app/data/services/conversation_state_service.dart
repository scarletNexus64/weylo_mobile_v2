import 'dart:async';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/realtime_service.dart';
import 'package:weylo/app/data/services/auth_service.dart';
import 'package:weylo/app/data/services/chat_service.dart';
import 'package:weylo/app/data/services/message_cache_service.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';
import 'package:weylo/app/modules/anonymepage/controllers/anonymepage_controller.dart';

/// Service global pour gérer l'état des conversations en temps réel
/// Ce service est initialisé au démarrage de l'app et reste actif partout
class ConversationStateService extends GetxService {
  static ConversationStateService get to => Get.find();

  final ChatService _chatService = ChatService();
  final MessageCacheService _cacheService = MessageCacheService();
  final AuthService _authService = AuthService();
  RealtimeService? _realtimeService;

  // État global des conversations (observable)
  final conversations = <ConversationModel>[].obs;

  // Badge count global (somme de tous les unreadCount)
  final totalUnreadCount = 0.obs;

  // Nombre de conversations non lues
  final unreadConversationsCount = 0.obs;

  // ID de la conversation actuellement ouverte (pour ne pas incrémenter le badge)
  final Rx<int?> currentOpenConversationId = Rx<int?>(null);

  // Canaux WebSocket souscrits
  final List<String> _subscribedChannels = [];

  // État du chargement
  final isInitialized = false.obs;
  final isLoading = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🌟 [ConversationStateService] INITIALISATION DU SERVICE GLOBAL');
    print('═══════════════════════════════════════════════════════════');

    await _initialize();
  }

  @override
  void onClose() {
    print('🔴 [ConversationStateService] Fermeture du service');
    _unsubscribeFromAllChannels();
    super.onClose();
  }

  /// Initialiser le service
  Future<void> _initialize() async {
    try {
      print('🚀 [ConversationStateService] Démarrage de l\'initialisation...');

      // Initialiser le WebSocket
      await _initializeWebSocket();

      // Charger les conversations initiales
      await loadConversations(refresh: true);

      isInitialized.value = true;
      print('✅ [ConversationStateService] Service initialisé avec succès');
      print('📊 [ConversationStateService] ${conversations.length} conversations chargées');
      print('📊 [ConversationStateService] Badge count total: $totalUnreadCount');
      print('═══════════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur lors de l\'initialisation: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
    }
  }

  /// Initialiser la connexion WebSocket
  Future<void> _initializeWebSocket() async {
    try {
      print('🔌 [ConversationStateService] Initialisation WebSocket...');

      // Récupérer ou créer le RealtimeService
      if (!Get.isRegistered<RealtimeService>()) {
        Get.put(RealtimeService());
      }
      _realtimeService = Get.find<RealtimeService>();

      print('✅ [ConversationStateService] WebSocket initialisé');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur WebSocket: $e');
    }
  }

  /// Charger les conversations depuis l'API
  Future<void> loadConversations({bool refresh = false}) async {
    if (isLoading.value) {
      print('⚠️ [ConversationStateService] Already loading, skipping...');
      return;
    }

    try {
      isLoading.value = true;
      print('📡 [ConversationStateService] Chargement des conversations depuis l\'API...');

      final response = await _chatService.getConversations(page: 1, perPage: 50);

      conversations.value = response.conversations;
      _calculateBadgeCounts();

      print('✅ [ConversationStateService] ${conversations.length} conversations chargées');

      // S'abonner aux canaux WebSocket
      await _subscribeToConversationChannels();

      // Sauvegarder dans le cache
      await _cacheService.saveConversationsCache(conversations, page: 1);

    } catch (e) {
      print('❌ [ConversationStateService] Erreur chargement: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// S'abonner aux canaux WebSocket des conversations
  Future<void> _subscribeToConversationChannels() async {
    if (_realtimeService == null) {
      print('⚠️ [ConversationStateService] Cannot subscribe: RealtimeService not available');
      return;
    }

    try {
      print('🔔 [ConversationStateService] Abonnement aux canaux WebSocket...');

      // NOUVEAU: S'abonner au canal global de l'utilisateur
      // Ce canal reçoit TOUS les nouveaux messages de TOUTES les conversations
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        final globalChannelName = 'private-user.${currentUser.id}';

        // Vérifier si on est déjà abonné au canal global
        if (!_subscribedChannels.contains(globalChannelName)) {
          print('🌐 [ConversationStateService] Abonnement au canal global utilisateur: $globalChannelName');

          await _realtimeService!.subscribeToPrivateChannel(
            channelName: globalChannelName,
            onEvent: _handleGlobalUserEvent,
          );

          _subscribedChannels.add(globalChannelName);
          print('✅ [ConversationStateService] Abonné au canal global utilisateur');
        }
      }

      print('✅ [ConversationStateService] Abonnement aux canaux terminé');
      print('📊 [ConversationStateService] Total canaux: ${_subscribedChannels.length}');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur abonnement: $e');
    }
  }

  /// Gérer les événements du canal global utilisateur
  Future<void> _handleGlobalUserEvent(Map<String, dynamic> eventData) async {
    try {
      print('');
      print('┌─────────────────────────────────────────────────────────┐');
      print('│ 📨 [ConversationStateService] ÉVÉNEMENT CANAL GLOBAL');
      print('└─────────────────────────────────────────────────────────┘');
      print('🎯 Event: ${eventData['_event']}');
      print('📦 Data: $eventData');

      final event = eventData['_event'] as String?;

      // Message anonyme reçu
      if (event == 'message.received') {
        print('📬 [ConversationStateService] Nouveau message anonyme reçu!');
        print('📝 ID: ${eventData['id']}');
        print('📝 Preview: ${eventData['content_preview']}');

        // Recharger les conversations pour mettre à jour les badges et la liste
        // Cela permettra de détecter si une nouvelle conversation a été créée
        await loadConversations(refresh: true);

        // Notifier aussi le module AnonymousPage pour qu'il recharge ses messages
        try {
          final anonymePageController = Get.find<AnonymepageController>();
          await anonymePageController.refreshMessages();
          print('✅ [ConversationStateService] AnonymePage rechargé');

          // Recalculer le badge count APRÈS avoir rechargé les messages anonymes
          _calculateBadgeCounts();
        } catch (e) {
          print('⚠️ [ConversationStateService] AnonymepageController not found: $e');
        }

        print('✅ [ConversationStateService] Rechargement terminé');
      }
      // Message de conversation (message.sent pour les conversations existantes)
      else if (event == 'message.sent') {
        // Vérifier si c'est un message de groupe (ils ont group_id au lieu de conversation_id)
        final groupId = eventData['group_id'] as int?;
        if (groupId != null) {
          print('👥 Message de groupe (ID: $groupId) - ignoré par ConversationStateService');
          // Les messages de groupe sont gérés par GroupeDetailController, pas ici
          return;
        }

        // Extraire l'ID de la conversation depuis les données
        final conversationId = eventData['conversation_id'] as int?;
        if (conversationId != null) {
          print('💬 Message pour la conversation: $conversationId');
          _handleNewMessage(conversationId, eventData);
        } else {
          print('⚠️ conversation_id manquant dans les données (et ce n\'est pas un message de groupe)');
        }
      } else if (event == 'user.typing') {
        print('⌨️ [ConversationStateService] User typing event (not implemented yet)');
      } else {
        print('⚠️ [ConversationStateService] Événement non géré: $event');
      }

      print('└─────────────────────────────────────────────────────────┘');
      print('');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur traitement event global: $e');
    }
  }

  /// Gérer les événements WebSocket d'une conversation
  void _handleConversationEvent(int conversationId, Map<String, dynamic> eventData) {
    try {
      print('');
      print('┌─────────────────────────────────────────────────────────┐');
      print('│ 📨 [ConversationStateService] NOUVEAU MESSAGE REÇU');
      print('└─────────────────────────────────────────────────────────┘');
      print('🆔 Conversation ID: $conversationId');
      print('🎯 Event: ${eventData['_event']}');

      final event = eventData['_event'] as String?;

      if (event == 'message.sent') {
        _handleNewMessage(conversationId, eventData);
      } else if (event == 'user.typing') {
        // Gérer le typing indicator si nécessaire
        print('⌨️ [ConversationStateService] User typing event (not implemented yet)');
      }

      print('└─────────────────────────────────────────────────────────┘');
      print('');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur traitement event: $e');
    }
  }

  /// Gérer un nouveau message
  void _handleNewMessage(int conversationId, Map<String, dynamic> eventData) {
    try {
      final currentUser = _authService.getCurrentUser();
      final senderId = eventData['sender_id'] as int?;

      // Ignorer si c'est notre propre message
      if (senderId == currentUser?.id) {
        print('⚠️ [ConversationStateService] Ignoring own message');
        return;
      }

      // Trouver la conversation dans la liste
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index == -1) {
        print('⚠️ [ConversationStateService] Conversation $conversationId not found');
        return;
      }

      final conversation = conversations[index];

      // Créer le nouveau message
      final newMessage = ChatMessageModel.fromJson(eventData);

      // Vérifier si la conversation est actuellement ouverte
      final isCurrentlyOpen = currentOpenConversationId.value == conversationId;

      // Incrémenter le unreadCount seulement si la conversation n'est pas ouverte
      final newUnreadCount = isCurrentlyOpen
          ? conversation.unreadCount
          : conversation.unreadCount + 1;

      print('📊 Current unread: ${conversation.unreadCount}');
      print('📊 Is currently open: $isCurrentlyOpen');
      print('📊 New unread: $newUnreadCount');

      // Créer une nouvelle instance de conversation
      final updatedConversation = ConversationModel(
        id: conversation.id,
        participantOneId: conversation.participantOneId,
        participantTwoId: conversation.participantTwoId,
        otherParticipant: conversation.otherParticipant,
        lastMessage: newMessage,
        unreadCount: newUnreadCount,
        hasPremium: conversation.hasPremium,
        isAnonymous: conversation.isAnonymous,
        identityRevealed: conversation.identityRevealed,
        canInitiateReveal: conversation.canInitiateReveal,
        anonymousMessageId: conversation.anonymousMessageId,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt,
        lastMessageAt: DateTime.now(),
        streak: conversation.streak, // Preserve streak data
      );

      // Retirer de l'ancienne position
      conversations.removeAt(index);

      // Insérer en première position
      conversations.insert(0, updatedConversation);

      // Recalculer les badge counts
      _calculateBadgeCounts();

      // Invalider le cache
      _cacheService.invalidateConversationCache(conversationId);

      print('✅ [ConversationStateService] Conversation mise à jour');
      print('📊 Total unread count: ${totalUnreadCount.value}');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur handleNewMessage: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Marquer une conversation comme ouverte (pour ne pas incrémenter le badge)
  void markConversationAsOpen(int conversationId) {
    print('👁️ [ConversationStateService] Conversation $conversationId marquée comme ouverte');
    currentOpenConversationId.value = conversationId;
  }

  /// Marquer une conversation comme fermée
  void markConversationAsClosed() {
    print('👁️ [ConversationStateService] Conversation fermée');
    currentOpenConversationId.value = null;
  }

  /// Marquer une conversation comme lue
  Future<void> markConversationAsRead(int conversationId) async {
    try {
      print('✅ [ConversationStateService] Marquage comme lu: $conversationId');

      // Trouver la conversation dans la liste
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index == -1) {
        print('⚠️ [ConversationStateService] Conversation $conversationId not found');
        return;
      }

      final conversation = conversations[index];

      // Si déjà lu, rien à faire
      if (conversation.unreadCount == 0) {
        print('✅ [ConversationStateService] Déjà lu');
        return;
      }

      // Créer une nouvelle instance avec unreadCount = 0
      final updatedConversation = ConversationModel(
        id: conversation.id,
        participantOneId: conversation.participantOneId,
        participantTwoId: conversation.participantTwoId,
        otherParticipant: conversation.otherParticipant,
        lastMessage: conversation.lastMessage,
        unreadCount: 0, // ← Marquer comme lu
        hasPremium: conversation.hasPremium,
        isAnonymous: conversation.isAnonymous,
        identityRevealed: conversation.identityRevealed,
        canInitiateReveal: conversation.canInitiateReveal,
        anonymousMessageId: conversation.anonymousMessageId,
        createdAt: conversation.createdAt,
        updatedAt: conversation.updatedAt,
        lastMessageAt: conversation.lastMessageAt,
        streak: conversation.streak, // Preserve streak data
      );

      // Remplacer dans la liste
      conversations[index] = updatedConversation;

      // Recalculer les badge counts
      _calculateBadgeCounts();

      // Appeler l'API pour marquer comme lu côté serveur
      await _chatService.markAsRead(conversationId);

      print('✅ [ConversationStateService] Conversation marquée comme lue');
      print('📊 Total unread count: ${totalUnreadCount.value}');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur markAsRead: $e');
    }
  }

  /// Calculer les badge counts globaux
  void _calculateBadgeCounts() {
    // Compter les messages non lus dans les conversations
    final conversationUnreadCount = conversations.fold<int>(
      0,
      (sum, conversation) => sum + conversation.unreadCount,
    );

    // NOTE: totalUnreadCount est utilisé pour le badge de l'onglet Chat (HomeView).
    // Il doit refléter uniquement les conversations, pas les messages anonymes.
    totalUnreadCount.value = conversationUnreadCount;

    unreadConversationsCount.value = conversations.where(
      (conversation) => conversation.unreadCount > 0,
    ).length;

    print('📊 [ConversationStateService] Badge counts recalculés:');
    print('   - Conversation unread: $conversationUnreadCount');
    print('   - Total unread chat messages: ${totalUnreadCount.value}');
    print('   - Unread conversations: ${unreadConversationsCount.value}');
  }

  /// Se désabonner de tous les canaux
  Future<void> _unsubscribeFromAllChannels() async {
    if (_realtimeService == null || _subscribedChannels.isEmpty) {
      return;
    }

    try {
      print('🔕 [ConversationStateService] Désabonnement de tous les canaux...');

      for (final channelName in _subscribedChannels) {
        await _realtimeService!.unsubscribeFromChannel(channelName);
      }

      _subscribedChannels.clear();
      print('✅ [ConversationStateService] Désabonné de tous les canaux');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur désabonnement: $e');
    }
  }

  /// Rafraîchir les conversations (force reload depuis API)
  Future<void> refreshConversations() async {
    print('🔄 [ConversationStateService] Refresh forcé...');
    await loadConversations(refresh: true);
  }

  /// Obtenir une conversation par ID
  ConversationModel? getConversationById(int conversationId) {
    try {
      return conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  /// Supprimer une conversation (masquer côté serveur)
  Future<void> deleteConversation(int conversationId) async {
    try {
      print('🗑️ [ConversationStateService] Suppression de la conversation $conversationId');

      // Retirer immédiatement de la liste locale pour l'UI
      final index = conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        conversations.removeAt(index);
        _calculateBadgeCounts();
        print('✅ [ConversationStateService] Conversation retirée de la liste locale');
      }

      // Appeler l'API pour masquer la conversation côté serveur
      await _chatService.deleteConversation(conversationId);

      print('✅ [ConversationStateService] Conversation masquée côté serveur');
    } catch (e) {
      print('❌ [ConversationStateService] Erreur lors de la suppression: $e');

      // En cas d'erreur, recharger les conversations pour remettre à jour l'UI
      await refreshConversations();

      rethrow;
    }
  }
}
