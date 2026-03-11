import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/conversation_state_service.dart';
import 'package:weylo/app/data/models/conversation_model.dart';

enum ChatFilter { all, unread, read }

/// ChatController simplifié - utilise ConversationStateService comme source de vérité
class ChatController extends GetxController {
  // Référence au service global
  ConversationStateService? _conversationStateService;

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
  }

  @override
  void onReady() {
    super.onReady();
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
  int get totalUnreadMessagesCount {
    return _conversationStateService?.totalUnreadCount.value ?? 0;
  }

  /// Rafraîchir les conversations (force refresh depuis API)
  Future<void> refreshConversations() async {
    print('🔄 [ChatController] Force refresh demandé');
    await _conversationStateService?.refreshConversations();
  }

  /// Supprimer une conversation (masquer)
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

      // Appeler l'API pour supprimer/masquer
      // TODO: Implémenter la suppression via ConversationStateService

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
