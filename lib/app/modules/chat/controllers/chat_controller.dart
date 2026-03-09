import 'package:get/get.dart';
import 'package:weylo/app/data/services/chat_service.dart';
import 'package:weylo/app/data/models/conversation_model.dart';

enum ChatFilter { all, unread, read }

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();

  // États
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

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
    loadConversations();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// Charger les conversations depuis l'API
  Future<void> loadConversations({bool refresh = false}) async {
    print('🔄 [ChatController] loadConversations called - refresh: $refresh');

    if (refresh) {
      currentPage = 1;
      conversations.clear();
      print('🔄 [ChatController] Cleared conversations list');
    }

    if (isLoading.value || isLoadingMore.value) {
      print('⚠️ [ChatController] Already loading, skipping...');
      return;
    }

    refresh ? isLoading.value = true : isLoadingMore.value = true;
    hasError.value = false;

    try {
      print('📡 [ChatController] Calling ChatService.getConversations...');
      final response = await _chatService.getConversations(
        page: currentPage,
        perPage: 20,
      );

      print('✅ [ChatController] Got ${response.conversations.length} conversations');

      if (refresh) {
        conversations.value = response.conversations;
      } else {
        conversations.addAll(response.conversations);
      }

      currentPage = response.meta.currentPage;
      lastPage = response.meta.lastPage;
      canLoadMore.value = response.meta.hasMorePages;

      print('📊 [ChatController] Total conversations: ${conversations.length}');
      print('📊 [ChatController] Current page: $currentPage, Last page: $lastPage');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ [ChatController] Error loading conversations: $e');
      print('❌ [ChatController] Stack trace: ${StackTrace.current}');
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

  /// Rafraîchir les conversations
  Future<void> refreshConversations() async {
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
}
