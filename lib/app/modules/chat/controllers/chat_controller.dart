import 'package:get/get.dart';
import 'package:weylo/app/data/services/conversation_state_service.dart';
import 'package:weylo/app/data/services/conversation_story_service.dart';
import 'package:weylo/app/data/models/conversation_model.dart';

enum ChatFilter { all, unread, read }

/// ChatController simplifié - utilise ConversationStateService comme source de vérité
class ChatController extends GetxController {
  // Référence au service global
  ConversationStateService? _conversationStateService;
  ConversationStoryService? _storyService;

  // Filtre de messages
  final Rx<ChatFilter> selectedFilter = ChatFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    print('🚀 [ChatController] onInit called');

    // Récupérer le service global
    try {
      _conversationStateService = ConversationStateService.to;
      print('✅ [ChatController] ConversationStateService récupéré');
    } catch (e) {
      print('❌ [ChatController] ConversationStateService non disponible: $e');
    }

    // Récupérer le service de stories
    try {
      _storyService = ConversationStoryService.to;
      print('✅ [ChatController] ConversationStoryService récupéré');
    } catch (e) {
      print('⚠️ [ChatController] ConversationStoryService non disponible: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure story statuses are loaded
    _storyService?.refreshStoryStatus();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// Conversations - proviennent du service global
  List<ConversationModel> get conversations {
    return _conversationStateService?.conversations ?? [];
  }

  /// État de chargement - provient du service global
  bool get isLoading {
    return _conversationStateService?.isLoading.value ?? false;
  }

  /// Changer le filtre
  void setFilter(ChatFilter filter) {
    selectedFilter.value = filter;
  }

  /// Obtenir les conversations filtrées
  List<ConversationModel> get filteredConversations {
    final allConversations = conversations;

    switch (selectedFilter.value) {
      case ChatFilter.all:
        return allConversations;
      case ChatFilter.unread:
        return allConversations.where((c) => c.unreadCount > 0).toList();
      case ChatFilter.read:
        return allConversations.where((c) => c.unreadCount == 0).toList();
    }
  }

  /// Obtenir le nombre de conversations non lues
  int get unreadCount {
    return _conversationStateService?.unreadConversationsCount.value ?? 0;
  }

  /// Obtenir le total des messages non lus (somme de tous les unreadCount)
  /// Retourne directement la variable observable pour la réactivité avec GetX/Obx
  RxInt get totalUnreadMessagesCount {
    return _conversationStateService?.totalUnreadCount ?? 0.obs;
  }

  /// Rafraîchir les conversations (force refresh depuis API)
  Future<void> refreshConversations() async {
    print('🔄 [ChatController] Force refresh demandé');
    await _conversationStateService?.refreshConversations();
  }

  /// Supprimer une conversation (masquer)
  Future<void> deleteConversation(int conversationId) async {
    try {
      print('🗑️ [ChatController] Deleting conversation $conversationId');

      // Appeler le service global pour supprimer la conversation
      // Cela va retirer immédiatement de la liste locale et appeler l'API
      await _conversationStateService?.deleteConversation(conversationId);

      Get.snackbar(
        'Succès',
        'Conversation supprimée',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ [ChatController] Error deleting conversation: $e');

      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la conversation',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Check if a conversation participant has stories
  bool hasStories(int? userId) {
    if (_storyService == null) {
      // Access a dummy observable to make this reactive even if service is null
      conversations.length; // This makes the Obx reactive
      return false;
    }
    return _storyService!.hasStories(userId);
  }

  /// Check if a conversation participant has unviewed stories
  bool hasUnviewedStories(int? userId) {
    if (_storyService == null) {
      // Access a dummy observable to make this reactive even if service is null
      conversations.length; // This makes the Obx reactive
      return false;
    }
    return _storyService!.hasUnviewedStories(userId);
  }

  /// Get story status for a conversation participant
  ConversationStoryStatus getStoryStatus(int? userId) {
    return _storyService?.getStoryStatus(userId) ?? ConversationStoryStatus.noStories();
  }

  /// Get the count of conversations with active streaks
  int get activeStreaksCount {
    return conversations.where((c) => c.streak != null && c.streak!.hasStreak).length;
  }
}
