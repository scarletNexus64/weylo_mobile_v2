import 'package:get/get.dart';

enum ChatFilter { all, unread, read }

class ChatController extends GetxController {
  //TODO: Implement ChatController

  final count = 0.obs;

  // Filtre de messages
  final Rx<ChatFilter> selectedFilter = ChatFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;

  void setFilter(ChatFilter filter) {
    selectedFilter.value = filter;
  }

  // Helper pour vérifier si un chat devrait être affiché selon le filtre
  bool shouldShowChat(bool isRead) {
    switch (selectedFilter.value) {
      case ChatFilter.all:
        return true;
      case ChatFilter.unread:
        return !isRead;
      case ChatFilter.read:
        return isRead;
    }
  }
}
