import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/models/anonymous_message_model.dart';
import 'package:weylo/app/data/services/message_service.dart';
import 'package:weylo/app/data/services/storage_service.dart';

class AnonymepageController extends GetxController {
  final _messageService = MessageService();
  final _storage = StorageService();

  // State variables
  final messages = <AnonymousMessageModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // User share link
  final userShareLink = Rxn<UserShareLink>();
  final isLoadingShareLink = false.obs;

  // Pagination
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final totalMessages = 0.obs;
  final perPage = 20;

  // Stats
  final unreadCount = 0.obs;

  // ScrollController for pagination
  late ScrollController scrollController;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);

    // Load initial data only if user is authenticated
    if (_storage.getToken() != null) {
      fetchMessages();
      fetchUserShareLink();
      fetchMessageStats();
    } else {
      print('⚠️ [ANONYMEPAGE] Pas de token, pas de chargement de données');
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Scroll listener for pagination
  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.8 &&
        !isLoadingMore.value &&
        currentPage.value < lastPage.value) {
      loadMoreMessages();
    }
  }

  /// Fetch messages (initial load)
  Future<void> fetchMessages() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      currentPage.value = 1;

      final response = await _messageService.getReceivedMessages(
        page: currentPage.value,
        perPage: perPage,
      );

      messages.value = response.messages;
      currentPage.value = response.meta.currentPage;
      lastPage.value = response.meta.lastPage;
      totalMessages.value = response.meta.total;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erreur',
        'Impossible de charger les messages: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (currentPage.value >= lastPage.value) return;

    try {
      isLoadingMore.value = true;

      final response = await _messageService.getReceivedMessages(
        page: currentPage.value + 1,
        perPage: perPage,
      );

      messages.addAll(response.messages);
      currentPage.value = response.meta.currentPage;
      lastPage.value = response.meta.lastPage;
      totalMessages.value = response.meta.total;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger plus de messages: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Refresh messages (pull to refresh)
  Future<void> refreshMessages() async {
    currentPage.value = 1;
    await fetchMessages();
    await fetchMessageStats();
  }

  /// Fetch user share link
  Future<void> fetchUserShareLink() async {
    try {
      isLoadingShareLink.value = true;
      final link = await _messageService.getUserShareLink();
      userShareLink.value = link;
    } catch (e) {
      // Si l'endpoint échoue, créer le lien côté client avec les infos du user stockées
      print('Erreur lors du chargement du lien: $e');

      // Fallback: créer le lien avec les données locales
      final user = _storage.getUser();
      if (user != null) {
        userShareLink.value = UserShareLink(
          link: 'weylo.app/u/${user.username}',
          username: user.username,
          shareText: 'Écris-moi un message anonyme 👇',
          shareOptions: ShareOptions(
            whatsapp: 'https://wa.me/?text=${Uri.encodeComponent("Écris-moi un message anonyme 👇 weylo.app/u/${user.username}")}',
            facebook: 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent("weylo.app/u/${user.username}")}',
            twitter: 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent("Écris-moi un message anonyme 👇 weylo.app/u/${user.username}")}',
          ),
        );
      } else {
        userShareLink.value = null;
      }
    } finally {
      isLoadingShareLink.value = false;
    }
  }

  /// Fetch message statistics
  Future<void> fetchMessageStats() async {
    try {
      final stats = await _messageService.getMessageStats();
      unreadCount.value = stats.unreadCount;
    } catch (e) {
      print('Error fetching message stats: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      messages.removeWhere((msg) => msg.id == messageId);
      totalMessages.value--;

      Get.snackbar(
        'Succès',
        'Message supprimé',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      final updatedMessage = await _messageService.markAsRead(messageId);
      final index = messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        messages[index] = updatedMessage;
        if (!updatedMessage.isRead && unreadCount.value > 0) {
          unreadCount.value--;
        }
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// Check if there are messages
  bool get hasMessages => messages.isNotEmpty;

  /// Check if there are more pages to load
  bool get hasMorePages => currentPage.value < lastPage.value;
}
