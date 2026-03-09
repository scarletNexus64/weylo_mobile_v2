import 'package:get/get.dart';
import 'package:weylo/app/data/services/chat_service.dart';
import 'package:weylo/app/data/models/chat_message_model.dart';
import 'package:weylo/app/data/models/conversation_model.dart';
import 'package:weylo/app/data/services/auth_service.dart';

class ChatDetailController extends GetxController {
  final String contactName;
  final String contactId;

  ChatDetailController({required this.contactName, required this.contactId});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // États
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Données
  final messages = <ChatMessageModel>[].obs;
  final conversation = Rx<ConversationModel?>(null);
  int? conversationId;
  int? currentUserId;

  // Pagination
  int currentPage = 1;
  int lastPage = 1;
  final canLoadMore = false.obs;

  // UI States
  final messageText = ''.obs;
  final isRecording = false.obs;
  final showGiftPicker = false.obs;
  final selectedGiftCategory = 'Romance'.obs;
  final isAnimatingGift = false.obs;
  final animatedGift = Rx<Map<String, dynamic>?>(null);

  final giftCategories = {
    'Romance': [
      {'name': 'Rose', 'icon': '🌹', 'description': 'Rose rouge', 'price': 500},
      {'name': 'Coeur', 'icon': '❤️', 'description': 'Coeur d\'amour', 'price': 1000},
      {'name': 'Bouquet', 'icon': '💐', 'description': 'Bouquet de fleurs', 'price': 2500},
      {'name': 'Bague', 'icon': '💍', 'description': 'Bague de fiançailles', 'price': 50000},
    ],
    'Nourriture': [
      {'name': 'Chocolat', 'icon': '🍫', 'description': 'Barre de chocolat', 'price': 300},
      {'name': 'Gâteau', 'icon': '🍰', 'description': 'Gâteau délicieux', 'price': 1500},
      {'name': 'Pizza', 'icon': '🍕', 'description': 'Pizza chaude', 'price': 3000},
      {'name': 'Champagne', 'icon': '🍾', 'description': 'Bouteille de champagne', 'price': 8000},
    ],
    'Boissons': [
      {'name': 'Café', 'icon': '☕', 'description': 'Café chaud', 'price': 500},
      {'name': 'Jus', 'icon': '🧃', 'description': 'Jus de fruits', 'price': 800},
      {'name': 'Vin Rouge', 'icon': '🍷', 'description': 'Bouteille de vin', 'price': 5000},
      {'name': 'Cocktail', 'icon': '🍹', 'description': 'Cocktail tropical', 'price': 2500},
    ],
    'Luxe': [
      {'name': 'Diamant', 'icon': '💎', 'description': 'Diamant précieux', 'price': 100000},
      {'name': 'Couronne', 'icon': '👑', 'description': 'Couronne royale', 'price': 75000},
      {'name': 'Montre', 'icon': '⌚', 'description': 'Montre de luxe', 'price': 150000},
      {'name': 'Voiture', 'icon': '🚗', 'description': 'Voiture de luxe', 'price': 5000000},
    ],
    'Fun': [
      {'name': 'Cadeau', 'icon': '🎁', 'description': 'Cadeau surprise', 'price': 1000},
      {'name': 'Ballon', 'icon': '🎈', 'description': 'Ballon festif', 'price': 200},
      {'name': 'Feu d\'artifice', 'icon': '🎆', 'description': 'Feu d\'artifice', 'price': 10000},
      {'name': 'Trophée', 'icon': '🏆', 'description': 'Trophée gagnant', 'price': 5000},
    ],
  };

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// Initialiser le contrôleur
  Future<void> _initializeController() async {
    try {
      // Récupérer l'ID de l'utilisateur actuel
      final user = await _authService.getCurrentUser();
      currentUserId = user?.id;

      // Récupérer l'ID de la conversation depuis les arguments
      final args = Get.arguments;
      if (args != null && args['conversationId'] != null) {
        conversationId = args['conversationId'];
        await loadMessages();
      }
    } catch (e) {
      print('Error initializing chat detail: $e');
      hasError.value = true;
      errorMessage.value = 'Impossible de charger la conversation';
    }
  }

  /// Charger les messages depuis l'API
  Future<void> loadMessages({bool refresh = false}) async {
    if (conversationId == null) return;

    if (refresh) {
      currentPage = 1;
      messages.clear();
    }

    if (isLoading.value || isLoadingMore.value) return;

    refresh ? isLoading.value = true : isLoadingMore.value = true;
    hasError.value = false;

    try {
      final response = await _chatService.getMessages(
        conversationId: conversationId!,
        page: currentPage,
        perPage: 50,
      );

      if (refresh) {
        messages.value = response.messages.reversed.toList();
      } else {
        messages.insertAll(0, response.messages.reversed.toList());
      }

      currentPage = response.meta.currentPage;
      lastPage = response.meta.lastPage;
      canLoadMore.value = response.meta.hasMorePages;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error loading messages: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Charger plus de messages (pagination)
  Future<void> loadMoreMessages() async {
    if (canLoadMore.value && !isLoadingMore.value) {
      currentPage++;
      await loadMessages();
    }
  }

  /// Rafraîchir les messages
  Future<void> refreshMessages() async {
    await loadMessages(refresh: true);
  }

  /// Vérifier si un message a été envoyé par moi
  bool isSentByMe(ChatMessageModel message) {
    return message.senderId == currentUserId;
  }

  void selectGiftCategory(String category) {
    selectedGiftCategory.value = category;
  }

  void toggleRecording() {
    isRecording.value = !isRecording.value;
  }

  void toggleGiftPicker() {
    showGiftPicker.value = !showGiftPicker.value;
  }
}
